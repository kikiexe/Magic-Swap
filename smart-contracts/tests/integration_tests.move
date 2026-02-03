#[test_only]
module magic_swap::integration_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::random::{Self, Random};

    // Import modul yang sudah diperbarui
    use magic_swap::game::{Self, GameHouse, AdminCap};

    // --- Helpers ---
    fun user(): address { @0xA }
    fun admin(): address { @0xB }

    /// Fungsi setup terpusat untuk inisialisasi environment game
    fun setup_game_environment(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        
        // 1. Inisialisasi kontrak (mint AdminCap)
        game::init_for_testing(ctx);
        
        // 2. Buat GameHouse (Treasury terintegrasi) sebagai Admin
        test_scenario::next_tx(scenario, admin());
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        game::create_game<SUI>(&admin_cap, test_scenario::ctx(scenario));
        test_scenario::return_to_sender(scenario, admin_cap);
        
        // 3. Inisialisasi Objek Random (Wajib dikirim oleh alamat @0x0)
        test_scenario::next_tx(scenario, @0x0); 
        random::create_for_testing(test_scenario::ctx(scenario));
    }

    #[test]
    fun test_full_game_flow_with_safety_valve() {
        let mut scenario = test_scenario::begin(admin());
        setup_game_environment(&mut scenario);

        // --- Langkah 1: Admin Mengisi Kas (Treasury) ---
        // Kita isi 1.000 SUI ke dalam GameHouse
        test_scenario::next_tx(&mut scenario, admin());
        let mut game_obj = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
        let house_fund = coin::mint_for_testing<SUI>(1000, test_scenario::ctx(&mut scenario));
        game::deposit(&mut game_obj, house_fund);

        // --- Langkah 2: User Bermain dengan Taruhan Besar ---
        // User bertaruh 500 SUI
        test_scenario::next_tx(&mut scenario, user());
        let wager = coin::mint_for_testing<SUI>(500, test_scenario::ctx(&mut scenario));
        let r_obj = test_scenario::take_shared<Random>(&scenario);
        
        // Panggil fungsi play utama
        game::play<SUI>(&mut game_obj, &r_obj, wager, test_scenario::ctx(&mut scenario));

        // --- Langkah 3: Verifikasi Safety Valve (Blueprint Bagian 3) ---
        // Skenario: Jika user menang Miracle (50x), profit idealnya 24.500 SUI.
        // Namun, Safety Valve membatasi profit maksimal 10% dari isi kas (10% dari 1.000 = 100).
        // Jadi, total payout maksimal yang boleh diterima user adalah: 500 (modal) + 100 (cap) = 600 SUI.
        test_scenario::next_tx(&mut scenario, user());
        let payout_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
        
        // Pastikan sistem melindungi kas bandar
        assert!(coin::value(&payout_coin) <= 600, 1); 

        // Cleanup
        test_scenario::return_shared(game_obj);
        test_scenario::return_shared(r_obj);
        test_scenario::return_to_sender(&scenario, payout_coin);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_admin_withdraw_logic() {
        let mut scenario = test_scenario::begin(admin());
        setup_game_environment(&mut scenario);

        // Admin deposit 100 SUI lalu coba tarik 50 SUI
        test_scenario::next_tx(&mut scenario, admin());
        let mut game_obj = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
        let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
        
        game::deposit(&mut game_obj, coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario)));
        
        test_scenario::next_tx(&mut scenario, admin());
        game::withdraw<SUI>(&admin_cap, &mut game_obj, 50, test_scenario::ctx(&mut scenario));

        // Verifikasi dana masuk ke admin
        test_scenario::next_tx(&mut scenario, admin());
        let withdrawn_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
        assert!(coin::value(&withdrawn_coin) == 50, 2);

        test_scenario::return_shared(game_obj);
        test_scenario::return_to_sender(&scenario, admin_cap);
        test_scenario::return_to_sender(&scenario, withdrawn_coin);
        test_scenario::end(scenario);
    }
}