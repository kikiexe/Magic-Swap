#[test_only]
module magic_swap::tier_outcome_tests {
    use magic_swap::probability_engine;
    use magic_swap::treasury;
    use sui::balance::{Self};
    use sui::sui::SUI;

    // ====== TIER MULTIPLIER TESTS ======

    #[test]
    fun test_loss_tier_multiplier() {
        // LOSS: 50% (roll 0-499) -> 0.60x (60 BPS)
        let test_rolls: vector<u16> = vector[0, 100, 250, 400, 499];
        let mut i = 0;
        while (i < 5) {
            let roll = *vector::borrow(&test_rolls, i);
            let (mult, outcome) = probability_engine::calculate_outcome(roll);
            assert!(mult == 60, 100 + i); // 60 = 0.60x
            assert!(outcome == 0, 200 + i); // outcome 0 = LOSS
            i = i + 1;
        };
    }

    #[test]
    fun test_small_win_tier_multiplier() {
        // SMALL WIN: 40% (roll 500-899) -> 1.05x (105 BPS)
        let test_rolls: vector<u16> = vector[500, 600, 750, 850, 899];
        let mut i = 0;
        while (i < 5) {
            let roll = *vector::borrow(&test_rolls, i);
            let (mult, outcome) = probability_engine::calculate_outcome(roll);
            assert!(mult == 105, 300 + i); // 105 = 1.05x
            assert!(outcome == 1, 400 + i); // outcome 1 = SMALL WIN
            i = i + 1;
        };
    }

    #[test]
    fun test_medium_win_tier_multiplier() {
        // MEDIUM WIN: 9% (roll 900-989) -> 1.50x (150 BPS)
        let test_rolls: vector<u16> = vector[900, 930, 960, 980, 989];
        let mut i = 0;
        while (i < 5) {
            let roll = *vector::borrow(&test_rolls, i);
            let (mult, outcome) = probability_engine::calculate_outcome(roll);
            assert!(mult == 150, 500 + i); // 150 = 1.50x
            assert!(outcome == 2, 600 + i); // outcome 2 = MEDIUM WIN
            i = i + 1;
        };
    }

    #[test]
    fun test_jackpot_tier_multiplier() {
        // JACKPOT: 0.9% (roll 990-998) -> 8.00x (800 BPS)
        let test_rolls: vector<u16> = vector[990, 993, 995, 997, 998];
        let mut i = 0;
        while (i < 5) {
            let roll = *vector::borrow(&test_rolls, i);
            let (mult, outcome) = probability_engine::calculate_outcome(roll);
            assert!(mult == 800, 700 + i); // 800 = 8.00x
            assert!(outcome == 3, 800 + i); // outcome 3 = JACKPOT
            i = i + 1;
        };
    }

    #[test]
    fun test_miracle_tier_multiplier() {
        // MIRACLE: 0.1% (roll 999) -> 50.00x (5000 BPS)
        let (mult, outcome) = probability_engine::calculate_outcome(999);
        assert!(mult == 5000, 900); // 5000 = 50.00x
        assert!(outcome == 4, 901); // outcome 4 = MIRACLE
    }

    // ====== PAYOUT CALCULATION TESTS ======

    #[test]
    fun test_loss_payout_calculation() {
        // Wager: 1000, Loss multiplier: 60 BPS (0.60x)
        // Expected payout: 1000 * 60 / 100 = 600
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(250); // LOSS
        let payout = (wager * mult) / 100;
        assert!(payout == 600, 1000);
    }

    #[test]
    fun test_small_win_payout_calculation() {
        // Wager: 1000, Small Win multiplier: 105 BPS (1.05x)
        // Expected payout: 1000 * 105 / 100 = 1050
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(700); // SMALL WIN
        let payout = (wager * mult) / 100;
        assert!(payout == 1050, 1001);
    }

    #[test]
    fun test_medium_win_payout_calculation() {
        // Wager: 1000, Medium Win multiplier: 150 BPS (1.50x)
        // Expected payout: 1000 * 150 / 100 = 1500
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(950); // MEDIUM WIN
        let payout = (wager * mult) / 100;
        assert!(payout == 1500, 1002);
    }

    #[test]
    fun test_jackpot_payout_calculation() {
        // Wager: 1000, Jackpot multiplier: 800 BPS (8.00x)
        // Expected payout: 1000 * 800 / 100 = 8000
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(995); // JACKPOT
        let payout = (wager * mult) / 100;
        assert!(payout == 8000, 1003);
    }

    #[test]
    fun test_miracle_payout_calculation() {
        // Wager: 1000, Miracle multiplier: 5000 BPS (50.00x)
        // Expected payout: 1000 * 5000 / 100 = 50000
        let wager = 1000u64;
        let (mult, _) = probability_engine::calculate_outcome(999); // MIRACLE
        let payout = (wager * mult) / 100;
        assert!(payout == 50000, 1004);
    }

    // ====== SAFETY CAP TESTS ======

    #[test]
    fun test_safety_cap_limits_jackpot() {
        // Treasury: 10000, Wager: 1000, Jackpot payout: 8000
        // Profit would be 7000, but max is 10% of treasury = 1000
        // Capped payout: 1000 + 1000 = 2000
        let mut treasury_balance = balance::zero<SUI>();
        balance::join(&mut treasury_balance, balance::create_for_testing<SUI>(10000));
        
        let wager = 1000u64;
        let ideal_payout = 8000u64; // 8x jackpot
        
        let capped = treasury::check_safety_cap(&treasury_balance, ideal_payout, wager);
        assert!(capped == 2000, 2000); // wager + 10% treasury
        
        balance::destroy_for_testing(treasury_balance);
    }

    #[test]
    fun test_safety_cap_limits_miracle() {
        // Treasury: 10000, Wager: 1000, Miracle payout: 50000
        // Profit would be 49000, but max is 10% of treasury = 1000
        // Capped payout: 1000 + 1000 = 2000
        let mut treasury_balance = balance::zero<SUI>();
        balance::join(&mut treasury_balance, balance::create_for_testing<SUI>(10000));
        
        let wager = 1000u64;
        let ideal_payout = 50000u64; // 50x miracle
        
        let capped = treasury::check_safety_cap(&treasury_balance, ideal_payout, wager);
        assert!(capped == 2000, 2001);
        
        balance::destroy_for_testing(treasury_balance);
    }

    #[test]
    fun test_safety_cap_allows_small_win() {
        // Treasury: 10000, Wager: 1000, Small win payout: 1050
        // Profit would be 50, which is < 10% of treasury (1000)
        // No cap needed
        let mut treasury_balance = balance::zero<SUI>();
        balance::join(&mut treasury_balance, balance::create_for_testing<SUI>(10000));
        
        let wager = 1000u64;
        let ideal_payout = 1050u64; // 1.05x small win
        
        let capped = treasury::check_safety_cap(&treasury_balance, ideal_payout, wager);
        assert!(capped == 1050, 2002); // No cap
        
        balance::destroy_for_testing(treasury_balance);
    }

    #[test]
    fun test_loss_no_cap_needed() {
        // Loss returns less than wager, no cap check needed
        let mut treasury_balance = balance::zero<SUI>();
        balance::join(&mut treasury_balance, balance::create_for_testing<SUI>(10000));
        
        let wager = 1000u64;
        let payout = 600u64; // 0.60x loss
        
        let capped = treasury::check_safety_cap(&treasury_balance, payout, wager);
        assert!(capped == 600, 2003); // Returns as-is
        
        balance::destroy_for_testing(treasury_balance);
    }

    // ====== BOUNDARY TESTS ======

    #[test]
    fun test_tier_boundaries() {
        // Test exact boundary values
        
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
