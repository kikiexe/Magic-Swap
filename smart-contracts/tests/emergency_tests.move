/// Emergency system tests for Magic Swap.
/// Tests pause/resume functionality and play() behavior when paused.
#[test_only]
module magic_swap::emergency_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::coin;
    use sui::sui::SUI;
    use sui::random;

    use magic_swap::game::{Self, GameHouse};
    use magic_swap::admin::{AdminCap};
    use magic_swap::emergency::{Self, EmergencyStatus};
    use magic_swap::fee_manager::{FeeVault};
    use magic_swap::user_stats::{UserStatsRegistry};

    // ============ Test Addresses ============
    const ADMIN: address = @0xAD;
    const PLAYER: address = @0xA1;

    // ============ Helpers ============
    
    /// Setup full game environment with all shared objects.
    fun setup_full_environment(scenario: &mut Scenario) {
        // Step 1: Initialize contract
        ts::next_tx(scenario, ADMIN);
        game::init_for_testing(ts::ctx(scenario));
        
        // Step 2: Create GameHouse + FeeVault
        ts::next_tx(scenario, ADMIN);
        let admin_cap = ts::take_from_sender<AdminCap>(scenario);
        game::create_game<SUI>(&admin_cap, ts::ctx(scenario));
        ts::return_to_sender(scenario, admin_cap);

        // 3. Fund house
        ts::next_tx(scenario, ADMIN);
        let mut game_obj = ts::take_shared<GameHouse<SUI>>(scenario);
        // Fund with 1000 SUI (1 SUI = 1,000,000,000 MIST)
        let funding = coin::mint_for_testing<SUI>(1000_000_000_000, ts::ctx(scenario));
        game::deposit(&mut game_obj, funding);
        ts::return_shared(game_obj);

        // Step 4: Initialize Random object
        ts::next_tx(scenario, @0x0);
        random::create_for_testing(ts::ctx(scenario));
    }

    // ============ Emergency Status Tests ============

    #[test]
    fun test_emergency_status_created() {
        let mut scenario = ts::begin(ADMIN);
        
        game::init_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, ADMIN);
        {
            let status = ts::take_shared<EmergencyStatus>(&scenario);
            
            // Should start unpaused
            assert!(!emergency::is_paused(&status), 0);
            
            ts::return_shared(status);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_admin_can_pause() {
        let mut scenario = ts::begin(ADMIN);
        game::init_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
            let mut status = ts::take_shared<EmergencyStatus>(&scenario);
            
            assert!(!emergency::is_paused(&status), 0);
            
            emergency::pause(&admin_cap, &mut status);
            
            assert!(emergency::is_paused(&status), 1);
            
            ts::return_to_sender(&scenario, admin_cap);
            ts::return_shared(status);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_admin_can_resume() {
        let mut scenario = ts::begin(ADMIN);
        game::init_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
            let mut status = ts::take_shared<EmergencyStatus>(&scenario);
            
            emergency::pause(&admin_cap, &mut status);
            assert!(emergency::is_paused(&status), 0);
            
            emergency::resume(&admin_cap, &mut status);
            assert!(!emergency::is_paused(&status), 1);
            
            ts::return_to_sender(&scenario, admin_cap);
            ts::return_shared(status);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_admin_can_toggle() {
        let mut scenario = ts::begin(ADMIN);
        game::init_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
            let mut status = ts::take_shared<EmergencyStatus>(&scenario);
            
            assert!(!emergency::is_paused(&status), 0);
            
            emergency::toggle(&admin_cap, &mut status);
            assert!(emergency::is_paused(&status), 1);
            
            emergency::toggle(&admin_cap, &mut status);
            assert!(!emergency::is_paused(&status), 2);
            
            ts::return_to_sender(&scenario, admin_cap);
            ts::return_shared(status);
        };
        
        ts::end(scenario);
    }

    // ============ Play Behavior Tests ============

    #[test]
    fun test_play_succeeds_when_not_paused() {
        let mut scenario = ts::begin(ADMIN);
        setup_full_environment(&mut scenario);
        
        ts::next_tx(&mut scenario, PLAYER);
        {
            let mut game_obj = ts::take_shared<GameHouse<SUI>>(&scenario);
            let mut fee_vault = ts::take_shared<FeeVault<SUI>>(&scenario);
            let mut stats_registry = ts::take_shared<UserStatsRegistry>(&scenario);
            let status = ts::take_shared<EmergencyStatus>(&scenario);
            let random_obj = ts::take_shared<random::Random>(&scenario);
            
            // Wager 1 SUI
            let wager = coin::mint_for_testing<SUI>(1_000_000_000, ts::ctx(&mut scenario));
            
            // Should succeed (system not paused) (100)
            game::play(&mut game_obj, &mut fee_vault, &mut stats_registry, &status, &random_obj, wager, ts::ctx(&mut scenario));
            
            ts::return_shared(game_obj);
            ts::return_shared(fee_vault);
            ts::return_shared(stats_registry);
            ts::return_shared(status);
            ts::return_shared(random_obj);
        };
        
        ts::next_tx(&mut scenario, PLAYER);
        {
            let payout = ts::take_from_sender<coin::Coin<SUI>>(&scenario);
            assert!(coin::value(&payout) > 0, 0);
            ts::return_to_sender(&scenario, payout);
        };
        
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 100, location = magic_swap::emergency)]
    fun test_play_fails_when_paused() {
        let mut scenario = ts::begin(ADMIN);
        setup_full_environment(&mut scenario);
        
        // Admin pauses
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
            let mut status = ts::take_shared<EmergencyStatus>(&scenario);
            
            emergency::pause(&admin_cap, &mut status);
            
            ts::return_to_sender(&scenario, admin_cap);
            ts::return_shared(status);
        };
        
        // Player tries to play (should FAIL)
        ts::next_tx(&mut scenario, PLAYER);
        {
            let mut game_obj = ts::take_shared<GameHouse<SUI>>(&scenario);
            let mut fee_vault = ts::take_shared<FeeVault<SUI>>(&scenario);
            let mut stats_registry = ts::take_shared<UserStatsRegistry>(&scenario);
            let status = ts::take_shared<EmergencyStatus>(&scenario);
            let random_obj = ts::take_shared<random::Random>(&scenario);
            
            // Wager 1 SUI
            let wager = coin::mint_for_testing<SUI>(1_000_000_000, ts::ctx(&mut scenario));
            
            // Should abort with ESystemPaused (100)
            game::play(&mut game_obj, &mut fee_vault, &mut stats_registry, &status, &random_obj, wager, ts::ctx(&mut scenario));
            
            ts::return_shared(game_obj);
            ts::return_shared(fee_vault);
            ts::return_shared(stats_registry);
            ts::return_shared(status);
            ts::return_shared(random_obj);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_play_succeeds_after_resume() {
        let mut scenario = ts::begin(ADMIN);
        setup_full_environment(&mut scenario);
        
        // Admin pauses
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
            let mut status = ts::take_shared<EmergencyStatus>(&scenario);
            emergency::pause(&admin_cap, &mut status);
            ts::return_to_sender(&scenario, admin_cap);
            ts::return_shared(status);
        };
        
        // Admin resumes
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
            let mut status = ts::take_shared<EmergencyStatus>(&scenario);
            emergency::resume(&admin_cap, &mut status);
            ts::return_to_sender(&scenario, admin_cap);
            ts::return_shared(status);
        };
        
        // Player plays successfully
        ts::next_tx(&mut scenario, PLAYER);
        {
            let mut game_obj = ts::take_shared<GameHouse<SUI>>(&scenario);
            let mut fee_vault = ts::take_shared<FeeVault<SUI>>(&scenario);
            let mut stats_registry = ts::take_shared<UserStatsRegistry>(&scenario);
            let status = ts::take_shared<EmergencyStatus>(&scenario);
            let random_obj = ts::take_shared<random::Random>(&scenario);
            
            // Wager 1 SUI
            let wager = coin::mint_for_testing<SUI>(1_000_000_000, ts::ctx(&mut scenario));
            game::play(&mut game_obj, &mut fee_vault, &mut stats_registry, &status, &random_obj, wager, ts::ctx(&mut scenario));
            
            ts::return_shared(game_obj);
            ts::return_shared(fee_vault);
            ts::return_shared(stats_registry);
            ts::return_shared(status);
            ts::return_shared(random_obj);
        };
        
        ts::end(scenario);
    }

    #[test]
    fun test_multiple_pause_resume_cycles() {
        let mut scenario = ts::begin(ADMIN);
        game::init_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, ADMIN);
        {
            let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
            let mut status = ts::take_shared<EmergencyStatus>(&scenario);
            
            // Cycle 1
            emergency::pause(&admin_cap, &mut status);
            assert!(emergency::is_paused(&status), 0);
            emergency::resume(&admin_cap, &mut status);
            assert!(!emergency::is_paused(&status), 1);
            
            // Cycle 2
            emergency::pause(&admin_cap, &mut status);
            assert!(emergency::is_paused(&status), 2);
            emergency::resume(&admin_cap, &mut status);
            assert!(!emergency::is_paused(&status), 3);
            
            ts::return_to_sender(&scenario, admin_cap);
            ts::return_shared(status);
        };
        
        ts::end(scenario);
    }
}
