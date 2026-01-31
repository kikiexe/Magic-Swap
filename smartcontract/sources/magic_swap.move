module magic_swap::game {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::random::{Self, Random};
    use sui::event;

    // --- Errors ---
    const EInsufficientHouseBalance: u64 = 0;
    const EInvalidAmount: u64 = 1;

    // --- Events ---
    public struct OutcomeEvent has copy, drop {
        player: address,
        wager: u64,
        payout: u64,
        outcome: u8, // 0: Loss (80%), 1: Mid, 2: High
    }

    // --- Objects ---
    public struct Game has key {
        id: UID,
        house: Balance<SUI>,
        admin: address,
    }

    public struct AdminCap has key, store {
        id: UID,
    }

    // --- Init ---
    fun init(ctx: &mut TxContext) {
        let game = Game {
            id: object::new(ctx),
            house: balance::zero(),
            admin: ctx.sender(),
        };
        transfer::share_object(game);

        let admin_cap = AdminCap {
            id: object::new(ctx),
        };
        transfer::transfer(admin_cap, ctx.sender());
    }

    // --- Admin Functions ---
    public entry fun deposit(game: &mut Game, coin: Coin<SUI>) {
        balance::join(&mut game.house, coin.into_balance());
    }

    public entry fun withdraw(
        _: &AdminCap, 
        game: &mut Game, 
        amount: u64, 
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&game.house) >= amount, EInsufficientHouseBalance);
        let coin = coin::take(&mut game.house, amount, ctx);
        transfer::public_transfer(coin, ctx.sender());
    }

    // --- Core Gameplay ---
    entry fun swap(
        game: &mut Game, 
        r: &Random, 
        coin: Coin<SUI>, 
        ctx: &mut TxContext
    ) {
        let wager_amount = coin.value();
        assert!(wager_amount > 0, EInvalidAmount);

        let mut wager_balance = coin.into_balance();
        let mut gen = random::new_generator(r, ctx);
        let roll = random::generate_u8_in_range(&mut gen, 0, 99);
        
        // Defined Probabilities
        // 0-49 (50%): Loss capped at 20% -> Return 80%
        // 50-89 (40%): Small Win -> Return 100% + 10% (1.1x)
        // 90-99 (10%): Big Win -> Return 100% + 100% (2.0x)
        
        let payout_amount = if (roll < 50) {
            // Loss: Return 80%
            (wager_amount * 80) / 100
        } else if (roll < 90) {
            // Small Win: 1.1x
            (wager_amount * 110) / 100
        } else {
            // Big Win: 2x
            (wager_amount * 200) / 100
        };

        // Safety: Check if we have enough funds
        let house_val = balance::value(&game.house);
        
        if (payout_amount > wager_amount) {
            // Player won, need to pull from house
            let diff = payout_amount - wager_amount;
            assert!(house_val >= diff, EInsufficientHouseBalance);
             // Take from house and add to wager_result
             balance::join(&mut wager_balance, balance::split(&mut game.house, diff));
        } else {
            // Player lost or break even, put difference into house
            if (wager_amount > payout_amount) {
                let diff = wager_amount - payout_amount;
                balance::join(&mut game.house, balance::split(&mut wager_balance, diff));
            }
        };

        let payout_coin = coin::from_balance(wager_balance, ctx);
        transfer::public_transfer(payout_coin, ctx.sender());

        event::emit(OutcomeEvent {
            player: ctx.sender(),
            wager: wager_amount,
            payout: payout_amount,
            outcome: if (roll < 50) { 0 } else if (roll < 90) { 1 } else { 2 }, 
        });
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
