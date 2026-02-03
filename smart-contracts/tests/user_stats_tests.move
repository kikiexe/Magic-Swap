#[test_only]
module magic_swap::user_stats_tests {
    use sui::test_scenario::{Self};
    use magic_swap::user_stats::{Self};
    use magic_swap::admin::{Self, AdminCap};

    const USER_A: address = @0xA;
    const USER_B: address = @0xB;
    const ADMIN: address = @0xAD;

    // ====== REGISTRY TESTS ======

    #[test]
    fun test_registry_creation() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            let registry = user_stats::create_registry_for_testing(
                test_scenario::ctx(&mut scenario)
            );
            
            // Check initial state
            assert!(user_stats::get_total_players(&registry) == 0, 0);
            assert!(user_stats::get_total_games(&registry) == 0, 1);
            
            user_stats::destroy_registry_for_testing(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_new_user_auto_created() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            let mut registry = user_stats::create_registry_for_testing(
                test_scenario::ctx(&mut scenario)
            );
            
            // User not exists initially
            assert!(!user_stats::has_stats(&registry, USER_A), 0);
            
            // Update stats creates user
            user_stats::update_stats_for_testing(&mut registry, USER_A, 1000, 600, 0);
            
            // Now exists
            assert!(user_stats::has_stats(&registry, USER_A), 1);
            assert!(user_stats::get_total_players(&registry) == 1, 2);
            
            user_stats::destroy_registry_for_testing(registry);
        };
        test_scenario::end(scenario);
    }

    // ====== STATS UPDATE TESTS ======

    #[test]
    fun test_single_game_loss() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            let mut registry = user_stats::create_registry_for_testing(
                test_scenario::ctx(&mut scenario)
            );
            
            // User plays: wager 1000, payout 600, tier 0 (LOSS)
            user_stats::update_stats_for_testing(&mut registry, USER_A, 1000, 600, 0);
            
            let stats = user_stats::get_stats(&registry, USER_A);
            assert!(user_stats::get_total_wagered(&stats) == 1000, 0);
            assert!(user_stats::get_total_payout(&stats) == 600, 1);
            assert!(user_stats::get_games_played(&stats) == 1, 2);
            assert!(user_stats::get_loss_count(&stats) == 1, 3);
            assert!(user_stats::get_win_count(&stats) == 0, 4);
            
            // Net loss = 400
            let (net, is_profit) = user_stats::get_net_profit(&stats);
            assert!(net == 400, 5);
            assert!(!is_profit, 6);
            
            user_stats::destroy_registry_for_testing(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_single_game_small_win() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            let mut registry = user_stats::create_registry_for_testing(
                test_scenario::ctx(&mut scenario)
            );
            
            // User plays: wager 1000, payout 1050, tier 1 (SMALL WIN)
            user_stats::update_stats_for_testing(&mut registry, USER_A, 1000, 1050, 1);
            
            let stats = user_stats::get_stats(&registry, USER_A);
            assert!(user_stats::get_win_count(&stats) == 1, 0);
            assert!(user_stats::get_loss_count(&stats) == 0, 1);
            
            // Net profit = 50
            let (net, is_profit) = user_stats::get_net_profit(&stats);
            assert!(net == 50, 2);
            assert!(is_profit, 3);
            
            user_stats::destroy_registry_for_testing(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multiple_games_accumulation() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            let mut registry = user_stats::create_registry_for_testing(
                test_scenario::ctx(&mut scenario)
            );
            
            // Game 1: Loss - wager 1000, payout 600, tier 0
            user_stats::update_stats_for_testing(&mut registry, USER_A, 1000, 600, 0);
            
            // Game 2: Small Win - wager 500, payout 525, tier 1
            user_stats::update_stats_for_testing(&mut registry, USER_A, 500, 525, 1);
            
            // Game 3: Medium Win - wager 200, payout 300, tier 2
            user_stats::update_stats_for_testing(&mut registry, USER_A, 200, 300, 2);
            
            let stats = user_stats::get_stats(&registry, USER_A);
            
            // Totals
            assert!(user_stats::get_total_wagered(&stats) == 1700, 0); // 1000+500+200
            assert!(user_stats::get_total_payout(&stats) == 1425, 1);   // 600+525+300
            assert!(user_stats::get_games_played(&stats) == 3, 2);
            
            // Tier counts
            let tier_counts = user_stats::get_tier_counts(&stats);
            assert!(*vector::borrow(&tier_counts, 0) == 1, 3); // 1 loss
            assert!(*vector::borrow(&tier_counts, 1) == 1, 4); // 1 small win
            assert!(*vector::borrow(&tier_counts, 2) == 1, 5); // 1 medium win
            
            // Net loss = 1700 - 1425 = 275
            let (net, is_profit) = user_stats::get_net_profit(&stats);
            assert!(net == 275, 6);
            assert!(!is_profit, 7);
            
            user_stats::destroy_registry_for_testing(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_multiple_users() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            let mut registry = user_stats::create_registry_for_testing(
                test_scenario::ctx(&mut scenario)
            );
            
            // User A plays
            user_stats::update_stats_for_testing(&mut registry, USER_A, 1000, 600, 0);
            
            // User B plays
            user_stats::update_stats_for_testing(&mut registry, USER_B, 500, 525, 1);
            
            // Check global stats
            assert!(user_stats::get_total_players(&registry) == 2, 0);
            assert!(user_stats::get_total_games(&registry) == 2, 1);
            
            // Check individual stats
            let stats_a = user_stats::get_stats(&registry, USER_A);
            let stats_b = user_stats::get_stats(&registry, USER_B);
            
            assert!(user_stats::get_games_played(&stats_a) == 1, 2);
            assert!(user_stats::get_games_played(&stats_b) == 1, 3);
            
            user_stats::destroy_registry_for_testing(registry);
        };
        test_scenario::end(scenario);
    }

    #[test]
    fun test_all_tier_counts() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            let mut registry = user_stats::create_registry_for_testing(
                test_scenario::ctx(&mut scenario)
            );
            
            // One game per tier
            user_stats::update_stats_for_testing(&mut registry, USER_A, 100, 60, 0);  // Loss
            user_stats::update_stats_for_testing(&mut registry, USER_A, 100, 105, 1); // Small
            user_stats::update_stats_for_testing(&mut registry, USER_A, 100, 150, 2); // Medium
            user_stats::update_stats_for_testing(&mut registry, USER_A, 100, 800, 3); // Jackpot
            user_stats::update_stats_for_testing(&mut registry, USER_A, 100, 5000, 4); // Miracle
            
            let stats = user_stats::get_stats(&registry, USER_A);
            let tier_counts = user_stats::get_tier_counts(&stats);
            
            assert!(*vector::borrow(&tier_counts, 0) == 1, 0);
            assert!(*vector::borrow(&tier_counts, 1) == 1, 1);
            assert!(*vector::borrow(&tier_counts, 2) == 1, 2);
            assert!(*vector::borrow(&tier_counts, 3) == 1, 3);
            assert!(*vector::borrow(&tier_counts, 4) == 1, 4);
            
            assert!(user_stats::get_loss_count(&stats) == 1, 5);
            assert!(user_stats::get_win_count(&stats) == 4, 6);
            
            user_stats::destroy_registry_for_testing(registry);
        };
        test_scenario::end(scenario);
    }

    // ====== ADMIN TESTS ======

    #[test]
    fun test_admin_reset_stats() {
        let mut scenario = test_scenario::begin(ADMIN);
        
        // Create admin cap
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = admin::create_admin_cap(test_scenario::ctx(&mut scenario));
            transfer::public_transfer(admin_cap, ADMIN);
        };
        
        test_scenario::next_tx(&mut scenario, ADMIN);
        {
            let mut registry = user_stats::create_registry_for_testing(
                test_scenario::ctx(&mut scenario)
            );
            
            // User plays some games
            user_stats::update_stats_for_testing(&mut registry, USER_A, 1000, 600, 0);
            user_stats::update_stats_for_testing(&mut registry, USER_A, 500, 525, 1);
            
            // Verify stats exist
            let stats = user_stats::get_stats(&registry, USER_A);
            assert!(user_stats::get_games_played(&stats) == 2, 0);
            
            // Admin resets
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            user_stats::reset_user_stats(&admin_cap, &mut registry, USER_A);
            test_scenario::return_to_sender(&scenario, admin_cap);
            
            // Stats are reset
            let stats_after = user_stats::get_stats(&registry, USER_A);
            assert!(user_stats::get_games_played(&stats_after) == 0, 1);
            assert!(user_stats::get_total_wagered(&stats_after) == 0, 2);
            
            user_stats::destroy_registry_for_testing(registry);
        };
        
        test_scenario::end(scenario);
    }

    // ====== VIEW FUNCTION TESTS ======

    #[test]
    fun test_get_stats_nonexistent_user() {
        let mut scenario = test_scenario::begin(ADMIN);
        {
            let registry = user_stats::create_registry_for_testing(
                test_scenario::ctx(&mut scenario)
            );
            
            // Get stats for user that doesn't exist
            let stats = user_stats::get_stats(&registry, USER_A);
            
            // Should return default values
            assert!(user_stats::get_total_wagered(&stats) == 0, 0);
            assert!(user_stats::get_games_played(&stats) == 0, 1);
            
            user_stats::destroy_registry_for_testing(registry);
        };
        test_scenario::end(scenario);
    }
}
