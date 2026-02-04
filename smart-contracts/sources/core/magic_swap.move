/// Core gameplay module for Magic Swap protocol.
/// Handles game initialization, player interactions, and outcome processing.
module magic_swap::game {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::random::Random;
    use sui::event;
    
    use magic_swap::randomness;
    use magic_swap::probability_engine;
    use magic_swap::treasury;
    use magic_swap::emergency::{Self, EmergencyStatus};
    
    use magic_swap::admin::{Self, AdminCap};
    use magic_swap::swap_types::{Self, SwapConfig};
    use magic_swap::fee_manager::{Self, FeeVault};
    use magic_swap::user_stats::{Self, UserStatsRegistry};
    use magic_swap::dynamic_odds;

    // ============ Events ============
    
    /// Emitted after each play() call with outcome details.
    public struct OutcomeEvent has copy, drop {
        player: address,
        wager: u64,
        payout: u64,
        outcome: u8,         // 0=Loss, 1=SmallWin, 2=MediumWin, 3=Jackpot, 4=Miracle
        fee_collected: u64,
        odds_mode: u8,       // 0=Critical, 1=Low, 2=Normal, 3=Generous
    }

    // ============ Shared Objects ============
    
    /// The main game house that holds the treasury.
    public struct GameHouse<phantom T> has key {
        id: UID,
        house: Balance<T>,
        admin: address,
        config: SwapConfig,
    }

    // ============ Initialization ============
    
    fun init(ctx: &mut TxContext) {
        // Create and transfer AdminCap to deployer
        let admin_cap = admin::create_admin_cap(ctx);
        transfer::public_transfer(admin_cap, ctx.sender());

        // Create and share EmergencyStatus
        let status = emergency::create(ctx);
        emergency::share(status);

        // Create and share UserStatsRegistry
        let registry = user_stats::create_registry(ctx);
        user_stats::share_registry(registry);
    }

    // ============ Admin Functions ============
    
    /// Create a new GameHouse and FeeVault for token type T.
    public fun create_game<T>(_: &AdminCap, ctx: &mut TxContext) {
        let game = GameHouse<T> {
            id: object::new(ctx),
            house: balance::zero(),
            admin: ctx.sender(),
             // Default config: Min 1 SUI, Max 1000 SUI (MIST units)
            config: swap_types::create(1_000_000_000, 1000_000_000_000), 
        };
        transfer::share_object(game);

        let vault = fee_manager::create_vault<T>(ctx);
        fee_manager::share_vault(vault);
    }

    public fun update_config<T>(
        _: &AdminCap,
        game: &mut GameHouse<T>,
        min: u64,
        max: u64
    ) {
        swap_types::update(&mut game.config, min, max);
    }

    /// Deposit funds into the game house treasury.
    public fun deposit<T>(game: &mut GameHouse<T>, coin: Coin<T>) {
        balance::join(&mut game.house, coin.into_balance());
    }

    /// Admin withdraws funds from game house treasury.
    #[allow(lint(self_transfer))]
    public fun withdraw<T>(
        _: &AdminCap, 
        game: &mut GameHouse<T>, 
        amount: u64, 
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&game.house) >= amount, 0); 
        let coin = coin::take(&mut game.house, amount, ctx);
        transfer::public_transfer(coin, ctx.sender());
    }

    // ============ Core Gameplay ============
    
    /// Main gameplay function. Player wagers coins and receives payout based on RNG.
    /// 
    /// Flow:
    /// 1. Check emergency pause status
    /// 2. Deduct 1% operational fee
    /// 3. Generate random roll (0-999)
    /// 4. Apply dynamic odds adjustment based on treasury level
    /// 5. Calculate payout with safety cap (max 10% of treasury)
    /// 6. Update user statistics
    /// 7. Transfer payout to player
    #[allow(lint(public_entry, public_random))]
    public entry fun play<T>(
        game: &mut GameHouse<T>,
        fee_vault: &mut FeeVault<T>,
        stats_registry: &mut UserStatsRegistry,
        status: &mut EmergencyStatus,
        r: &Random, 
        coin: Coin<T>, 
        ctx: &mut TxContext
    ) {
        // Step 1: Verify system is not paused
        emergency::assert_not_paused(status);
        
        // Emergency check: Auto-pause if treasury critically low
        let emergency_threshold = 10_000_000_000; // 10 SUI minimum
        if (balance::value(&game.house) < emergency_threshold) {
            emergency::auto_pause(status);
            abort 104 // ETreasuryTooLow
        };

        let player = ctx.sender();
        let wager_amount = coin.value();
        
        // Config Validation
        let min = swap_types::min_wager(&game.config);
        let max = swap_types::max_wager(&game.config);
        assert!(wager_amount >= min, 101); // EWagerTooSmall
        assert!(wager_amount <= max, 102); // EWagerTooLarge

        let mut wager_balance = coin.into_balance();
        
        // Step 2: Deduct 1% fee
        let fee_amount = fee_manager::calculate_fee(wager_amount);
        let fee_balance = balance::split(&mut wager_balance, fee_amount);
        fee_manager::collect_fee_from_balance(fee_vault, fee_balance);
        let net_wager = wager_amount - fee_amount;
        
        // CRITICAL: Safety cap check - prevent bets that could bankrupt house
        let house_balance_val = balance::value(&game.house);
        let max_possible_payout = net_wager * 9; // Worst case: 9x MIRACLE win
        assert!(max_possible_payout <= house_balance_val, 103); // EBetTooHighForTreasury
        
        // Step 3: Generate random roll
        let mut gen = randomness::get_generator(r, ctx);
        let base_roll = randomness::roll_dice(&mut gen);

        // Step 4: Apply dynamic odds adjustment
        let odds_mode = dynamic_odds::get_odds_mode(&game.house);
        let adjusted_roll = dynamic_odds::adjust_roll(&game.house, base_roll);

        // Step 5: Calculate payout
        let (multiplier_bps, outcome_type) = probability_engine::calculate_outcome(adjusted_roll);
        let ideal_payout = (net_wager * multiplier_bps) / 100;
        let final_payout = treasury::check_safety_cap(&game.house, ideal_payout, net_wager);

        // Process fund transfer based on outcome
        if (final_payout > net_wager) {
            let diff = final_payout - net_wager;
            balance::join(&mut wager_balance, balance::split(&mut game.house, diff));
        } else if (net_wager > final_payout) {
            let diff = net_wager - final_payout;
            balance::join(&mut game.house, balance::split(&mut wager_balance, diff));
        };

        // Step 6: Update user stats with cooldown check
        let current_epoch = ctx.epoch();
        user_stats::update_stats(stats_registry, player, wager_amount, final_payout, outcome_type, current_epoch);

        // Step 7: Transfer payout to player
        transfer::public_transfer(coin::from_balance(wager_balance, ctx), ctx.sender());

        event::emit(OutcomeEvent {
            player,
            wager: wager_amount,
            payout: final_payout,
            outcome: outcome_type,
            fee_collected: fee_amount,
            odds_mode,
        });
    }

    // ============ View Functions ============
    
    /// Get current treasury balance.
    public fun get_house_balance<T>(game: &GameHouse<T>): u64 {
        balance::value(&game.house)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}