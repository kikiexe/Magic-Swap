/// Tier outcome tests for Magic Swap probability engine.
/// Tests multipliers, payout calculations, safety cap, and tier boundaries.
#[test_only]
module magic_swap::tier_outcome_tests {
    use magic_swap::probability_engine;
    use magic_swap::treasury;
    use sui::balance::{Self};
    use sui::sui::SUI;

    // ============ Tier Multiplier Tests ============

    #[test]
    fun test_loss_tier_multiplier() {
        // LOSS: 50% (roll 0-499) -> 0.60x
        let test_rolls: vector<u16> = vector[0, 100, 250, 400, 499];
        let mut i = 0;
        while (i < 5) {
            let roll = *vector::borrow(&test_rolls, i);
            let (mult, outcome) = probability_engine::calculate_outcome(roll);
            assert!(mult == 60, 100 + i);
            assert!(outcome == 0, 200 + i);
            i = i + 1;
        };
    }

    #[test]
    fun test_small_win_tier_multiplier() {
        // SMALL WIN: 40% (roll 500-899) -> 1.05x
        let test_rolls: vector<u16> = vector[500, 600, 750, 850, 899];
        let mut i = 0;
        while (i < 5) {
            let roll = *vector::borrow(&test_rolls, i);
            let (mult, outcome) = probability_engine::calculate_outcome(roll);
            assert!(mult == 105, 300 + i);
            assert!(outcome == 1, 400 + i);
            i = i + 1;
        };
    }

    #[test]
    fun test_medium_win_tier_multiplier() {
        // MEDIUM WIN: 9% (roll 900-989) -> 1.50x
        let test_rolls: vector<u16> = vector[900, 930, 960, 980, 989];
        let mut i = 0;
        while (i < 5) {
            let roll = *vector::borrow(&test_rolls, i);
            let (mult, outcome) = probability_engine::calculate_outcome(roll);
            assert!(mult == 150, 500 + i);
            assert!(outcome == 2, 600 + i);
            i = i + 1;
        };
    }

    #[test]
    fun test_jackpot_tier_multiplier() {
        // JACKPOT: 0.9% (roll 990-998) -> 8.00x
        let test_rolls: vector<u16> = vector[990, 993, 995, 997, 998];
        let mut i = 0;
        while (i < 5) {
            let roll = *vector::borrow(&test_rolls, i);
            let (mult, outcome) = probability_engine::calculate_outcome(roll);
            assert!(mult == 800, 700 + i);
            assert!(outcome == 3, 800 + i);
            i = i + 1;
        };
    }

    #[test]
    fun test_miracle_tier_multiplier() {
        // MIRACLE: 0.1% (roll 999) -> 50.00x
        let (mult, outcome) = probability_engine::calculate_outcome(999);
        assert!(mult == 5000, 900);
        assert!(outcome == 4, 901);
    }

    // ============ Payout Calculation Tests ============

    #[test]
    fun test_loss_payout_calculation() {
        // Wager: 1000, Loss: 0.60x -> 600
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(250);
        let payout = (wager * mult) / 100;
        assert!(payout == 600, 1000);
    }

    #[test]
    fun test_small_win_payout_calculation() {
        // Wager: 1000, Small Win: 1.05x -> 1050
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(700);
        let payout = (wager * mult) / 100;
        assert!(payout == 1050, 1001);
    }

    #[test]
    fun test_medium_win_payout_calculation() {
        // Wager: 1000, Medium Win: 1.50x -> 1500
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(950);
        let payout = (wager * mult) / 100;
        assert!(payout == 1500, 1002);
    }

    #[test]
    fun test_jackpot_payout_calculation() {
        // Wager: 1000, Jackpot: 8.00x -> 8000
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(995);
        let payout = (wager * mult) / 100;
        assert!(payout == 8000, 1003);
    }

    #[test]
    fun test_miracle_payout_calculation() {
        // Wager: 1000, Miracle: 50.00x -> 50000
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(999);
        let payout = (wager * mult) / 100;
        assert!(payout == 50000, 1004);
    }

    // ============ Safety Cap Tests ============

    #[test]
    fun test_safety_cap_limits_jackpot() {
        // Treasury: 10000, Wager: 1000, Jackpot: 8000
        // Profit 7000 > 10% treasury (1000), capped to 2000
        let mut treasury_balance = balance::zero<SUI>();
        balance::join(&mut treasury_balance, balance::create_for_testing<SUI>(10000));
        
        let capped = treasury::check_safety_cap(&treasury_balance, 8000, 1000);
        assert!(capped == 2000, 2000);
        
        balance::destroy_for_testing(treasury_balance);
    }

    #[test]
    fun test_safety_cap_limits_miracle() {
        // Treasury: 10000, Wager: 1000, Miracle: 50000
        // Profit 49000 > 10% treasury (1000), capped to 2000
        let mut treasury_balance = balance::zero<SUI>();
        balance::join(&mut treasury_balance, balance::create_for_testing<SUI>(10000));
        
        let capped = treasury::check_safety_cap(&treasury_balance, 50000, 1000);
        assert!(capped == 2000, 2001);
        
        balance::destroy_for_testing(treasury_balance);
    }

    #[test]
    fun test_safety_cap_allows_small_win() {
        // Treasury: 10000, Wager: 1000, Small Win: 1050
        // Profit 50 < 10% treasury (1000), no cap
        let mut treasury_balance = balance::zero<SUI>();
        balance::join(&mut treasury_balance, balance::create_for_testing<SUI>(10000));
        
        let capped = treasury::check_safety_cap(&treasury_balance, 1050, 1000);
        assert!(capped == 1050, 2002);
        
        balance::destroy_for_testing(treasury_balance);
    }

    #[test]
    fun test_loss_no_cap_needed() {
        // Loss returns less than wager, no cap needed
        let mut treasury_balance = balance::zero<SUI>();
        balance::join(&mut treasury_balance, balance::create_for_testing<SUI>(10000));
        
        let capped = treasury::check_safety_cap(&treasury_balance, 600, 1000);
        assert!(capped == 600, 2003);
        
        balance::destroy_for_testing(treasury_balance);
    }

    // ============ Tier Boundary Tests ============

    #[test]
    fun test_tier_boundaries() {
        // 499 -> LOSS, 500 -> SMALL WIN
        let (_, outcome_499) = probability_engine::calculate_outcome(499);
        let (_, outcome_500) = probability_engine::calculate_outcome(500);
        assert!(outcome_499 == 0 && outcome_500 == 1, 3000);
        
        // 899 -> SMALL WIN, 900 -> MEDIUM WIN
        let (_, outcome_899) = probability_engine::calculate_outcome(899);
        let (_, outcome_900) = probability_engine::calculate_outcome(900);
        assert!(outcome_899 == 1 && outcome_900 == 2, 3001);
        
        // 989 -> MEDIUM WIN, 990 -> JACKPOT
        let (_, outcome_989) = probability_engine::calculate_outcome(989);
        let (_, outcome_990) = probability_engine::calculate_outcome(990);
        assert!(outcome_989 == 2 && outcome_990 == 3, 3002);
        
        // 998 -> JACKPOT, 999 -> MIRACLE
        let (_, outcome_998) = probability_engine::calculate_outcome(998);
        let (_, outcome_999) = probability_engine::calculate_outcome(999);
        assert!(outcome_998 == 3 && outcome_999 == 4, 3003);
    }
}
