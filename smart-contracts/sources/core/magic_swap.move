module magic_swap::game {
    use sui::coin::{Self, Coin};
    use sui::balance;
    use sui::random::Random;
    use sui::event;
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    use magic_swap::probability_engine::{Self, Outcome};
    use magic_swap::loss_cap;
    use magic_swap::treasury;
    use magic_swap::reward_pool;

    // --- Errors ---
    const EInsufficientTreasuryBalance: u64 = 0;
    const EInvalidAmount: u64 = 1;

    // --- Events ---
    public struct OutcomeEvent has copy, drop {
        player: address,
        wager: u64,
        payout: u64,
        outcome_tier: u8, // 0: Loss, 1: Small, 2: Medium, 3: Jackpot, 4: Miracle
        multiplier: u64,
        is_capped: bool,
    }

    // --- Objects ---
    /// Lightweight game metadata object.
    /// Actual funds live in `treasury::Treasury<T>` and optional `reward_pool::RewardPool<T>`.
    public struct Game<phantom T> has key {
        id: UID,
        admin: address,
    }

    public struct AdminCap has key, store {
        id: UID,
    }

    // --- Init ---
    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };
        transfer::transfer(admin_cap, ctx.sender());
    }

    // --- Admin Functions ---
    /// Create a new game. The admin is the transaction sender.
    /// Initial funds should be placed into a separate `treasury::Treasury<T>`
    /// by calling `treasury::create_treasury` in the same PTB.
    public fun create_game<T>(
        _: &AdminCap,
        ctx: &mut TxContext
    ) {
        let game = Game<T> {
            id: object::new(ctx),
            admin: ctx.sender(),
        };
        transfer::share_object(game);
    }

    /// Convenience wrapper: deposit into a game treasury.
    public fun deposit<T>(_: &Game<T>, t: &mut treasury::Treasury<T>, coin: Coin<T>) {
        treasury::deposit(t, coin);
    }

    /// Convenience wrapper: withdraw from a game treasury via `TreasuryCap`.
    #[allow(lint(self_transfer))]
    public fun withdraw<T>(
        _: &AdminCap,
        cap: &treasury::TreasuryCap,
        t: &mut treasury::Treasury<T>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let withdrawn_coin = treasury::withdraw(cap, t, amount, ctx);
        transfer::public_transfer(withdrawn_coin, ctx.sender());
    }

    // --- Core Gameplay ---
    entry fun swap<T>(
        game: &mut Game<T>,
        t: &mut treasury::Treasury<T>,
        rp: &mut reward_pool::RewardPool<T>,
        r: &Random,
        coin: Coin<T>,
        ctx: &mut TxContext
    ) {
        // 1. Resolve Outcome
        let outcome = probability_engine::resolve(r, ctx);
        
        // 2. Execute Swap Logic
        do_swap(game, t, rp, outcome, coin, ctx);
    }

    // --- Internal Logic ---
    #[allow(lint(self_transfer))]
    fun do_swap<T>(
        _: &mut Game<T>,
        t: &mut treasury::Treasury<T>,
        rp: &mut reward_pool::RewardPool<T>,
        outcome: Outcome,
        coin: Coin<T>,
        ctx: &mut TxContext
    ) {
        let wager_amount = coin.value();
        assert!(wager_amount > 0, EInvalidAmount);

        let mut wager_balance = coin.into_balance();
        let multiplier = probability_engine::get_multiplier(&outcome);
        
        // 2. Calculate Payout
        // Multiplier is scaled by 100 (e.g. 105 = 1.05x)
        let desired_payout = (wager_amount as u128 * (multiplier as u128) / 100) as u64;

        // 3. Safety Valve Check (Loss Cap / Profit Cap) via `loss_cap` helper.
        let treasury_before = treasury::value(t);
        let (payout_amount, is_capped) =
            loss_cap::cap_payout_10_percent(treasury_before, wager_amount, desired_payout);

        // 4. Settle Funds against external treasury
        if (payout_amount > wager_amount) {
            // Player won, pull profit from treasury
            let profit = payout_amount - wager_amount;
            assert!(treasury::value(t) >= profit, EInsufficientTreasuryBalance);

            let profit_balance = treasury::take_balance(t, profit);
            balance::join(&mut wager_balance, profit_balance);
        } else {
            // Player lost (or breakeven), excess goes to treasury
            if (wager_amount > payout_amount) {
                let loss = wager_amount - payout_amount;
                let loss_balance = balance::split(&mut wager_balance, loss);
                treasury::deposit_balance(t, loss_balance);
            }
        };

        let treasury_after = treasury::value(t);
        reward_pool::record_pnl(rp, treasury_before, treasury_after, ctx);

        // 5. Transfer to User
        let payout_coin = coin::from_balance(wager_balance, ctx);
        transfer::public_transfer(payout_coin, ctx.sender());

        // 6. Emit Event
        event::emit(OutcomeEvent {
            player: ctx.sender(),
            wager: wager_amount,
            payout: payout_amount,
            outcome_tier: probability_engine::get_tier(&outcome),
            multiplier: multiplier,
            is_capped: is_capped,
        });
    }

    #[test_only]
    public fun swap_for_testing<T>(
        game: &mut Game<T>,
        t: &mut treasury::Treasury<T>,
        rp: &mut reward_pool::RewardPool<T>,
        outcome: Outcome,
        coin: Coin<T>,
        ctx: &mut TxContext
    ) {
        do_swap(game, t, rp, outcome, coin, ctx);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
