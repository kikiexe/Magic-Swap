#[test_only]
module magic_swap::integration_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::random::{Self, Random};

    use magic_swap::game::{Self, GameHouse};
    use magic_swap::admin::{AdminCap};
    use magic_swap::emergency::{EmergencyStatus};

    // ==================== HELPERS ====================
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

        // ==================== Langkah 1: Admin Mengisi Kas (Treasury) ====================
        test_scenario::next_tx(&mut scenario, admin());
        {
            let mut game_obj = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
            let house_fund = coin::mint_for_testing<SUI>(1000, test_scenario::ctx(&mut scenario));
            game::deposit(&mut game_obj, house_fund);
            test_scenario::return_shared(game_obj);
        };

        // ==================== Langkah 2: User Bermain dengan Taruhan Besar ====================
        test_scenario::next_tx(&mut scenario, user());
        {
            let mut game_obj = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
            let status = test_scenario::take_shared<EmergencyStatus>(&scenario);
            let r_obj = test_scenario::take_shared<Random>(&scenario);
            let wager = coin::mint_for_testing<SUI>(500, test_scenario::ctx(&mut scenario));
            
            // Panggil fungsi play utama
            game::play<SUI>(&mut game_obj, &status, &r_obj, wager, test_scenario::ctx(&mut scenario));
            
            test_scenario::return_shared(game_obj);
            test_scenario::return_shared(status);
            test_scenario::return_shared(r_obj);
        };

        // ==================== Langkah 3: Verifikasi Safety Valve (Blueprint Bagian 3) ====================
        test_scenario::next_tx(&mut scenario, user());
        {
            let payout_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            // Pastikan sistem melindungi kas bandar (Max profit 10% dari 1000 = 100. Total payout 500+100=600)
            // Note: If user lost, payout is 300 (60% of 500). If won jackpot, capped at 600.
            assert!(coin::value(&payout_coin) <= 600, 1); 
            test_scenario::return_to_sender(&scenario, payout_coin);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_admin_withdraw_logic() {
        let mut scenario = test_scenario::begin(admin());
        setup_game_environment(&mut scenario);

        // ==================== Langkah 1: Admin deposit 100 SUI ====================
        test_scenario::next_tx(&mut scenario, admin());
        {
            let mut game_obj = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
            game::deposit(&mut game_obj, coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario)));
            test_scenario::return_shared(game_obj);
        };
        
        // ==================== Langkah 2: Admin withdraw 50 SUI ====================
        test_scenario::next_tx(&mut scenario, admin());
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            let mut game_obj = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
            
            game::withdraw<SUI>(&admin_cap, &mut game_obj, 50, test_scenario::ctx(&mut scenario));
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(game_obj);
        };

        // ==================== Langkah 3: Verifikasi dana masuk ke admin ====================
        test_scenario::next_tx(&mut scenario, admin());
        {
            let withdrawn_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            assert!(coin::value(&withdrawn_coin) == 50, 2);
            test_scenario::return_to_sender(&scenario, withdrawn_coin);
        };

        test_scenario::end(scenario);
    }
}