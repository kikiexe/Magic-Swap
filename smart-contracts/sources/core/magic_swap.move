module magic_swap::game {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::random::Random;
    use sui::event;
    
    // Memanggil modul pendukung yang sudah kita buat
    use magic_swap::randomness;
    use magic_swap::probability_engine;
    use magic_swap::treasury;
    use magic_swap::emergency::{Self, EmergencyStatus};
    use magic_swap::admin::{Self, AdminCap};
    use magic_swap::fee_manager::{Self, FeeVault};
    use magic_swap::user_stats::{Self, UserStatsRegistry};
    use magic_swap::dynamic_odds;

    // --- Events ---
    public struct OutcomeEvent has copy, drop {
        player: address,
        wager: u64,
        payout: u64,
        outcome: u8,
        fee_collected: u64,
        odds_mode: u8,
    }

    // --- Objects ---
    public struct GameHouse<phantom T> has key {
        id: UID,
        house: Balance<T>,
        admin: address,
    }

    // --- Init ---
    fun init(ctx: &mut TxContext) {
        let admin_cap = admin::create_admin_cap(ctx);
        transfer::public_transfer(admin_cap, ctx.sender());

        // Initialize EmergencyStatus
        let status = emergency::create(ctx);
        emergency::share(status);

        // Initialize UserStatsRegistry
        let registry = user_stats::create_registry(ctx);
        user_stats::share_registry(registry);
    }

    // --- Admin Functions ---
    /// Create a new game house and its fee vault
    public fun create_game<T>(_: &AdminCap, ctx: &mut TxContext) {
        let game = GameHouse<T> {
            id: object::new(ctx),
            house: balance::zero(),
            admin: ctx.sender(),
        };
        transfer::share_object(game);

        // Also create and share FeeVault for this token type
        let vault = fee_manager::create_vault<T>(ctx);
        fee_manager::share_vault(vault);
    }

    public fun deposit<T>(game: &mut GameHouse<T>, coin: Coin<T>) {
        balance::join(&mut game.house, coin.into_balance());
    }

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

    // --- Core Gameplay ---
    #[allow(lint(public_entry, public_random))]
    public entry fun play<T>(
        game: &mut GameHouse<T>,
        fee_vault: &mut FeeVault<T>,
        stats_registry: &mut UserStatsRegistry,
        status: &EmergencyStatus,
        r: &Random, 
        coin: Coin<T>, 
        ctx: &mut TxContext
    ) {
        // Check emergency status
        emergency::assert_not_paused(status);

        let player = ctx.sender();
        let wager_amount = coin.value();
        let mut wager_balance = coin.into_balance();
        
        // === FEE COLLECTION ===
        // Deduct 1% fee before gameplay
        let fee_amount = fee_manager::calculate_fee(wager_amount);
        let fee_balance = balance::split(&mut wager_balance, fee_amount);
        fee_manager::collect_fee_from_balance(fee_vault, fee_balance);
        
        // Net amount after fee
        let net_wager = wager_amount - fee_amount;
        
        // Mengambil angka acak 0-999
        let mut gen = randomness::get_generator(r, ctx);
        let base_roll = randomness::roll_dice(&mut gen);

        // === DYNAMIC ODDS ADJUSTMENT ===
        // Adjust roll based on treasury level (more losses when treasury is low)
        let odds_mode = dynamic_odds::get_odds_mode(&game.house);
        let adjusted_roll = dynamic_odds::adjust_roll(&game.house, base_roll);

        // Menghitung hadiah berdasarkan Golden Math di Blueprint
        // NOTE: payout dihitung dari net_wager (setelah fee)
        let (multiplier_bps, outcome_type) = probability_engine::calculate_outcome(adjusted_roll);
        let ideal_payout = (net_wager * multiplier_bps) / 100;

        // Validasi Safety Valve 10% agar bandar tidak bangkrut
        let final_payout = treasury::check_safety_cap(&game.house, ideal_payout, net_wager);

        // Proses pembagian dana
        if (final_payout > net_wager) {
            let diff = final_payout - net_wager;
            balance::join(&mut wager_balance, balance::split(&mut game.house, diff));
        } else if (net_wager > final_payout) {
            let diff = net_wager - final_payout;
            balance::join(&mut game.house, balance::split(&mut wager_balance, diff));
        };

        // === UPDATE USER STATS ===
        user_stats::update_stats(stats_registry, player, wager_amount, final_payout, outcome_type);

        // Mengirim koin hasil permainan ke user
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

    // --- View Functions ---
    public fun get_house_balance<T>(game: &GameHouse<T>): u64 {
        balance::value(&game.house)
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}