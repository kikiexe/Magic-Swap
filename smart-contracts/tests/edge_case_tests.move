/// Edge case tests for Magic Swap.
/// Tests safety valve limits and error conditions.
#[test_only]
module magic_swap::edge_case_tests {
    use sui::test_scenario::{Self};
    use sui::balance;
    use sui::sui::SUI;
    
    use magic_swap::game::{Self, GameHouse};
    use magic_swap::admin::{AdminCap};
    use magic_swap::treasury;

    #[test]
    fun test_safety_valve_near_empty_treasury() {
        // Treasury only has 100 SUI
        let house_balance = balance::create_for_testing<SUI>(100);
        
        // User wagers 100 SUI and wins Jackpot (ideal payout 8x = 800)
        let wager = 100;
        let ideal_payout = 800;
        
        // Cap should be: wager (100) + 10% treasury (10) = 110 SUI
        let final_payout = treasury::check_safety_cap(&house_balance, ideal_payout, wager);
        
        assert!(final_payout == 110, 0);
        balance::destroy_for_testing(house_balance);
    }

    #[test]
    #[expected_failure(abort_code = 0, location = magic_swap::game)] 
    fun test_withdraw_more_than_available() {
        let mut scenario = test_scenario::begin(@0xB);
        
        // Initialize game
        game::init_for_testing(test_scenario::ctx(&mut scenario));
        
        test_scenario::next_tx(&mut scenario, @0xB);
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            
            // Create game with empty treasury
            game::create_game<SUI>(&admin_cap, test_scenario::ctx(&mut scenario));
            
            test_scenario::next_tx(&mut scenario, @0xB);
            let mut game_house = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
            
            // Try to withdraw 1000 when treasury is 0 (should abort)
            game::withdraw<SUI>(&admin_cap, &mut game_house, 1000, test_scenario::ctx(&mut scenario));
            
            test_scenario::return_to_sender(&scenario, admin_cap);
            test_scenario::return_shared(game_house);
        };
        test_scenario::end(scenario);
    }
}