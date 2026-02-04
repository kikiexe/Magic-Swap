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
        // LOSS: 55% (roll 0-549) -> 0.60x
        let test_rolls: vector<u16> = vector[0, 100, 250, 400, 549];
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
        // SMALL WIN: 35% (roll 550-899) -> 1.05x
        let test_rolls: vector<u16> = vector[550, 600, 750, 850, 899];
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
        // MEDIUM WIN: 8% (roll 900-979) -> 1.50x
        let test_rolls: vector<u16> = vector[900, 930, 960, 970, 979];
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
        // JACKPOT: 1.5% (roll 980-994) -> 6.00x
        let test_rolls: vector<u16> = vector[980, 985, 990, 992, 994];
        let mut i = 0;
        while (i < 5) {
            let roll = *vector::borrow(&test_rolls, i);
            let (mult, outcome) = probability_engine::calculate_outcome(roll);
            assert!(mult == 600, 700 + i);
            assert!(outcome == 3, 800 + i);
            i = i + 1;
        };
    }

    #[test]
    fun test_miracle_tier_multiplier() {
        // MIRACLE: 0.5% (roll 995-999) -> 9.00x
        let (mult, outcome) = probability_engine::calculate_outcome(999);
        assert!(mult == 900, 900);
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
        // Wager: 1000, Jackpot: 6.00x -> 6000
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(990);
        let payout = (wager * mult) / 100;
        assert!(payout == 6000, 1003);
    }

    #[test]
    fun test_miracle_payout_calculation() {
        // Wager: 1000, Miracle: 9.00x -> 9000
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(999);
        let payout = (wager * mult) / 100;
        assert!(payout == 9000, 1004);
    }

    // ============ Safety Cap Tests ============

    #[test]
    fun test_safety_cap_limits_jackpot() {
        // Treasury: 10000, Wager: 1000, Jackpot: 6000
        // Profit 5000 > 10% treasury (1000), capped to 2000
        let mut treasury_balance = balance::zero<SUI>();
        balance::join(&mut treasury_balance, balance::create_for_testing<SUI>(10000));
        
        let capped = treasury::check_safety_cap(&treasury_balance, 6000, 1000);
        assert!(capped == 2000, 2000);
        
        balance::destroy_for_testing(treasury_balance);
    }

    #[test]
    fun test_safety_cap_limits_miracle() {
        // Treasury: 10000, Wager: 1000, Miracle: 9000
        // Profit 8000 > 10% treasury (1000), capped to 2000
        let mut treasury_balance = balance::zero<SUI>();
        balance::join(&mut treasury_balance, balance::create_for_testing<SUI>(10000));
        
        let capped = treasury::check_safety_cap(&treasury_balance, 9000, 1000);
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
        // 549 -> LOSS, 550 -> SMALL WIN
        let (_, outcome_549) = probability_engine::calculate_outcome(549);
        let (_, outcome_550) = probability_engine::calculate_outcome(550);
        assert!(outcome_549 == 0 && outcome_550 == 1, 3000);
        
        // 899 -> SMALL WIN, 900 -> MEDIUM WIN
        let (_, outcome_899) = probability_engine::calculate_outcome(899);
        let (_, outcome_900) = probability_engine::calculate_outcome(900);
        assert!(outcome_899 == 1 && outcome_900 == 2, 3001);
        
        // 979 -> MEDIUM WIN, 980 -> JACKPOT
        let (_, outcome_979) = probability_engine::calculate_outcome(979);
        let (_, outcome_980) = probability_engine::calculate_outcome(980);
        assert!(outcome_979 == 2 && outcome_980 == 3, 3002);
        
        // 994 -> JACKPOT, 995 -> MIRACLE
        let (_, outcome_994) = probability_engine::calculate_outcome(994);
        let (_, outcome_995) = probability_engine::calculate_outcome(995);
        assert!(outcome_994 == 3 && outcome_995 == 4, 3003);
    }
}
