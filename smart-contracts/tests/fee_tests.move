/// Fee manager tests for Magic Swap.
/// Tests fee calculation, vault operations, and admin withdrawal.
#[test_only]
module magic_swap::fee_tests {
    use sui::test_scenario::{Self};
    use sui::sui::SUI;
    use sui::balance;
    use magic_swap::fee_manager::{Self};
    use magic_swap::admin::{Self, AdminCap};

    fun admin(): address { @0xA }

    // ============ Fee Calculation Tests ============

    #[test]
    fun test_fee_calculation_1_percent() {
        // 1% fee = 100 BPS: 10000 -> 100 fee
        let fee = fee_manager::calculate_fee(10000);
        assert!(fee == 100, 0);
    }

    #[test]
    fun test_fee_calculation_small_amount() {
        // 100 -> 1 fee (rounded down)
        let fee = fee_manager::calculate_fee(100);
        assert!(fee == 1, 1);
    }

    #[test]
    fun test_fee_calculation_minimum() {
        // 50 -> 0 fee (rounded down from 0.5)
        let fee = fee_manager::calculate_fee(50);
        assert!(fee == 0, 2);
    }

    #[test]
    fun test_get_net_amount() {
        // 10000 -> (9900 net, 100 fee)
        let (net, fee) = fee_manager::get_net_amount(10000);
        assert!(net == 9900, 3);
        assert!(fee == 100, 4);
    }

    #[test]
    fun test_fee_rate_bps() {
        // Should return 100 (1%)
        let rate = fee_manager::get_fee_rate_bps();
        assert!(rate == 100, 5);
    }

    // ============ Vault Tests ============

    #[test]
    fun test_vault_creation_and_balance() {
        let mut scenario = test_scenario::begin(admin());
        {
            let vault = fee_manager::create_vault_for_testing<SUI>(
                test_scenario::ctx(&mut scenario)
            );
            
            // Initial balance should be 0
            assert!(fee_manager::get_fee_balance(&vault) == 0, 10);
            assert!(fee_manager::get_total_collected(&vault) == 0, 11);
            assert!(fee_manager::get_total_withdrawn(&vault) == 0, 12);
            
            fee_manager::destroy_vault_for_testing(vault);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_fee_collection() {
        let mut scenario = test_scenario::begin(admin());
        {
            let mut vault = fee_manager::create_vault_for_testing<SUI>(
                test_scenario::ctx(&mut scenario)
            );
            
            // Collect 100
            let fee_balance = balance::create_for_testing<SUI>(100);
            fee_manager::collect_fee_from_balance(&mut vault, fee_balance);
            
            assert!(fee_manager::get_fee_balance(&vault) == 100, 20);
            assert!(fee_manager::get_total_collected(&vault) == 100, 21);
            
            // Collect 50 more
            let more_fees = balance::create_for_testing<SUI>(50);
            fee_manager::collect_fee_from_balance(&mut vault, more_fees);
            
            assert!(fee_manager::get_fee_balance(&vault) == 150, 22);
            assert!(fee_manager::get_total_collected(&vault) == 150, 23);
            
            fee_manager::destroy_vault_for_testing(vault);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_fee_withdrawal() {
        let mut scenario = test_scenario::begin(admin());
        
        // Create AdminCap
        test_scenario::next_tx(&mut scenario, admin());
        {
            let admin_cap = admin::create_admin_cap(test_scenario::ctx(&mut scenario));
            transfer::public_transfer(admin_cap, admin());
        };
        
        // Create vault and add fees
        test_scenario::next_tx(&mut scenario, admin());
        {
            let mut vault = fee_manager::create_vault_for_testing<SUI>(
                test_scenario::ctx(&mut scenario)
            );
            
            let fees = balance::create_for_testing<SUI>(1000);
            fee_manager::collect_fee_from_balance(&mut vault, fees);
            
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            
            // Partial withdrawal (400)
            fee_manager::withdraw_fees<SUI>(
                &admin_cap,
                &mut vault,
                400,
                test_scenario::ctx(&mut scenario)
            );
            
            assert!(fee_manager::get_fee_balance(&vault) == 600, 30);
            assert!(fee_manager::get_total_withdrawn(&vault) == 400, 31);
            
            // Withdraw remaining
            fee_manager::withdraw_all_fees<SUI>(
                &admin_cap,
                &mut vault,
                test_scenario::ctx(&mut scenario)
            );
            
            assert!(fee_manager::get_fee_balance(&vault) == 0, 32);
            assert!(fee_manager::get_total_withdrawn(&vault) == 1000, 33);
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            fee_manager::destroy_vault_for_testing(vault);
        };
        
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = magic_swap::fee_manager::EInsufficientFees)]
    fun test_withdrawal_insufficient_funds() {
        let mut scenario = test_scenario::begin(admin());
        
        test_scenario::next_tx(&mut scenario, admin());
        {
            let admin_cap = admin::create_admin_cap(test_scenario::ctx(&mut scenario));
            transfer::public_transfer(admin_cap, admin());
        };
        
        test_scenario::next_tx(&mut scenario, admin());
        {
            let mut vault = fee_manager::create_vault_for_testing<SUI>(
                test_scenario::ctx(&mut scenario)
            );
            
            // Add only 100
            let fees = balance::create_for_testing<SUI>(100);
            fee_manager::collect_fee_from_balance(&mut vault, fees);
            
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            
            // Try to withdraw 200 - should fail
            fee_manager::withdraw_fees<SUI>(
                &admin_cap,
                &mut vault,
                200,
                test_scenario::ctx(&mut scenario)
            );
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            fee_manager::destroy_vault_for_testing(vault);
        };
        
        test_scenario::end(scenario);
    }

    // ============ Integration Test ============

    #[test]
    fun test_fee_deduction_from_wager() {
        // Simulates play() flow: wager 10000, fee 1% = 100, net = 9900
        let wager = 10000u64;
        let (net, fee) = fee_manager::get_net_amount(wager);
        
        assert!(net == 9900, 40);
        assert!(fee == 100, 41);
        
        // Loss payout (0.60x of net)
        let loss_payout = (net * 60) / 100;
        assert!(loss_payout == 5940, 42);
        
        // Small win payout (1.05x of net)
        let small_win_payout = (net * 105) / 100;
        assert!(small_win_payout == 10395, 43);
    }
}
