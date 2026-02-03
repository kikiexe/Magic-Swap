module magic_swap::game {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::random::Random;
    use sui::event;
    
    // Memanggil modul pendukung yang sudah kita buat
    use magic_swap::randomness;
    use magic_swap::probability_engine;
    use magic_swap::treasury;

    // --- Events ---
    public struct OutcomeEvent has copy, drop {
        player: address,
        wager: u64,
        payout: u64,
        outcome: u8,
    }

    // --- Objects ---
    public struct GameHouse<phantom T> has key {
        id: UID,
        house: Balance<T>,
        admin: address,
    }

    public struct AdminCap has key, store {
        id: UID,
    }

    // --- Init ---
    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap { id: object::new(ctx) };
        transfer::transfer(admin_cap, ctx.sender());
    }

    // --- Admin Functions ---
    public fun create_game<T>(_: &AdminCap, ctx: &mut TxContext) {
        let game = GameHouse<T> {
            id: object::new(ctx),
            house: balance::zero(),
            admin: ctx.sender(),
        };
        transfer::share_object(game);
    }

    public fun deposit<T>(game: &mut GameHouse<T>, coin: Coin<T>) {
        balance::join(&mut game.house, coin.into_balance());
    }

    // Gunakan allow(lint) hanya sekali di sini
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
    // Menggunakan Random Native Sui dengan proteksi linter
    #[allow(lint(public_entry, public_random))]
    public entry fun play<T>(
        game: &mut GameHouse<T>, 
        r: &Random, 
        coin: Coin<T>, 
        ctx: &mut TxContext
    ) {
        let wager_amount = coin.value();
        let mut wager_balance = coin.into_balance();
        
        // Mengambil angka acak 0-999
        let mut gen = randomness::get_generator(r, ctx);
        let roll = randomness::roll_dice(&mut gen);

        // Menghitung hadiah berdasarkan Golden Math di Blueprint
        let (multiplier_bps, outcome_type) = probability_engine::calculate_outcome(roll);
        let ideal_payout = (wager_amount * multiplier_bps) / 100;

        // Validasi Safety Valve 10% agar bandar tidak bangkrut
        let final_payout = treasury::check_safety_cap(&game.house, ideal_payout, wager_amount);

        // Proses pembagian dana
        if (final_payout > wager_amount) {
            let diff = final_payout - wager_amount;
            balance::join(&mut wager_balance, balance::split(&mut game.house, diff));
        } else if (wager_amount > final_payout) {
            let diff = wager_amount - final_payout;
            balance::join(&mut game.house, balance::split(&mut wager_balance, diff));
        };

        // Mengirim koin hasil permainan ke user
        transfer::public_transfer(coin::from_balance(wager_balance, ctx), ctx.sender());

        event::emit(OutcomeEvent {
            player: ctx.sender(),
            wager: wager_amount,
            payout: final_payout,
            outcome: outcome_type,
        });
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}