/// Integration tests for Magic Swap full game flow.
/// Tests deposit, play, safety valve, and admin withdrawal.
#[test_only]
module magic_swap::integration_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::random::{Self, Random};

    use magic_swap::game::{Self, GameHouse};
    use magic_swap::admin::{AdminCap};
    use magic_swap::emergency::{EmergencyStatus};
    use magic_swap::fee_manager::{FeeVault};
    use magic_swap::user_stats::{UserStatsRegistry};

    // ============ Test Addresses ============
    fun user(): address { @0xA }
    fun admin(): address { @0xB }

    /// Setup game environment with all shared objects.
    fun setup_game_environment(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        
        // Step 1: Initialize contract (creates AdminCap, EmergencyStatus, UserStatsRegistry)
        game::init_for_testing(ctx);
        
        // Step 2: Create GameHouse + FeeVault as Admin
        test_scenario::next_tx(scenario, admin());
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        game::create_game<SUI>(&admin_cap, test_scenario::ctx(scenario));
        test_scenario::return_to_sender(scenario, admin_cap);
        
        // Step 3: Initialize Random object (must be sent from @0x0)
        test_scenario::next_tx(scenario, @0x0); 
        random::create_for_testing(test_scenario::ctx(scenario));
    }

    // ============ Integration Tests ============

    #[test]
    fun test_full_game_flow_with_safety_valve() {
        let mut scenario = test_scenario::begin(admin());
        setup_game_environment(&mut scenario);

        // --- Langkah 1: Admin Mengisi Kas (Treasury) ---
        test_scenario::next_tx(&mut scenario, admin());
        {
            let mut game_obj = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
            // Fund: 1000 SUI
            let house_fund = coin::mint_for_testing<SUI>(1000_000_000_000, test_scenario::ctx(&mut scenario));
            game::deposit(&mut game_obj, house_fund);
            test_scenario::return_shared(game_obj);
        };

        // Step 2: User plays with a wager
        test_scenario::next_tx(&mut scenario, user());
        {
            let mut game_obj = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
            let mut fee_vault = test_scenario::take_shared<FeeVault<SUI>>(&scenario);
            let mut stats_registry = test_scenario::take_shared<UserStatsRegistry>(&scenario);
            let mut status = test_scenario::take_shared<EmergencyStatus>(&scenario);
            let r_obj = test_scenario::take_shared<Random>(&scenario);
            // Wager: 100 SUI (safe for 1000 SUI treasury, max payout 900 SUI)
            let wager = coin::mint_for_testing<SUI>(100_000_000_000, test_scenario::ctx(&mut scenario));
            
            game::play<SUI>(
                &mut game_obj, 
                &mut fee_vault,
                &mut stats_registry,
                &mut status, 
                &r_obj, 
                wager, 
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_shared(game_obj);
            test_scenario::return_shared(fee_vault);
            test_scenario::return_shared(stats_registry);
            test_scenario::return_shared(status);
            test_scenario::return_shared(r_obj);
        };

        // --- Langkah 3: Verifikasi Safety Valve (Blueprint Bagian 3) ---
        test_scenario::next_tx(&mut scenario, user());
        {
            let payout_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            // Skenario: 
            // Treasury: 1000 SUI
            // Wager: 100 SUI (after 1% fee = 99 SUI net)
            // Max Profit Allowed = 10% of 1000 SUI = 100 SUI
            // Max Payout = Net Wager + Max Profit = 99 + 100 = 199 SUI
            // 199 SUI = 199_000_000_000 MIST
            assert!(coin::value(&payout_coin) <= 199_000_000_000, 1); 
            test_scenario::return_to_sender(&scenario, payout_coin);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_admin_withdraw_logic() {
        let mut scenario = test_scenario::begin(admin());
        setup_game_environment(&mut scenario);

        // Step 1: Admin deposits 100 SUI
        test_scenario::next_tx(&mut scenario, admin());
        {
            let mut game_obj = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
            game::deposit(&mut game_obj, coin::mint_for_testing<SUI>(100, test_scenario::ctx(&mut scenario)));
            test_scenario::return_shared(game_obj);
        };
        
        // Step 2: Admin withdraws 50 SUI
        test_scenario::next_tx(&mut scenario, admin());
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            let mut game_obj = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
            
            game::withdraw<SUI>(&admin_cap, &mut game_obj, 50, test_scenario::ctx(&mut scenario));
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(game_obj);
        };

        // Step 3: Verify funds received by admin
        test_scenario::next_tx(&mut scenario, admin());
        {
            let withdrawn_coin = test_scenario::take_from_sender<Coin<SUI>>(&scenario);
            assert!(coin::value(&withdrawn_coin) == 50, 2);
            test_scenario::return_to_sender(&scenario, withdrawn_coin);
        };

        test_scenario::end(scenario);
    }
}