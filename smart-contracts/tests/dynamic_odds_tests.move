#[test_only]
module magic_swap::dynamic_odds_tests {
    use sui::balance::{Self};
    use sui::sui::SUI;
    use magic_swap::dynamic_odds;

    // Treasury thresholds (same as in module)
    const LOW_THRESHOLD: u64 = 1_000_000_000;       // 1 SUI
    const MEDIUM_THRESHOLD: u64 = 10_000_000_000;   // 10 SUI
    const HIGH_THRESHOLD: u64 = 100_000_000_000;    // 100 SUI

    // ====== ODDS MODE TESTS ======

    #[test]
    fun test_critical_mode() {
        // Treasury < 1 SUI = Critical mode (0)
        let mut balance = balance::zero<SUI>();
        balance::join(&mut balance, balance::create_for_testing<SUI>(500_000_000)); // 0.5 SUI
        
        let mode = dynamic_odds::get_odds_mode(&balance);
        assert!(mode == 0, 0);
        assert!(dynamic_odds::is_conservative_mode(&balance), 1);
        
        balance::destroy_for_testing(balance);
    }

    #[test]
    fun test_low_mode() {
        // Treasury 1-10 SUI = Low mode (1)
        let mut balance = balance::zero<SUI>();
        balance::join(&mut balance, balance::create_for_testing<SUI>(5_000_000_000)); // 5 SUI
        
        let mode = dynamic_odds::get_odds_mode(&balance);
        assert!(mode == 1, 0);
        assert!(dynamic_odds::is_conservative_mode(&balance), 1);
        
        balance::destroy_for_testing(balance);
    }

    #[test]
    fun test_normal_mode() {
        // Treasury 10-100 SUI = Normal mode (2)
        let mut balance = balance::zero<SUI>();
        balance::join(&mut balance, balance::create_for_testing<SUI>(50_000_000_000)); // 50 SUI
        
        let mode = dynamic_odds::get_odds_mode(&balance);
        assert!(mode == 2, 0);
        assert!(!dynamic_odds::is_conservative_mode(&balance), 1);
        
        balance::destroy_for_testing(balance);
    }

    #[test]
    fun test_generous_mode() {
        // Treasury > 100 SUI = Generous mode (3)
        let mut balance = balance::zero<SUI>();
        balance::join(&mut balance, balance::create_for_testing<SUI>(200_000_000_000)); // 200 SUI
        
        let mode = dynamic_odds::get_odds_mode(&balance);
        assert!(mode == 3, 0);
        assert!(!dynamic_odds::is_conservative_mode(&balance), 1);
        
        balance::destroy_for_testing(balance);
    }

    // ====== MODE BOUNDARY TESTS ======

    #[test]
    fun test_mode_boundaries() {
        // Exactly at LOW threshold (1 SUI) = Low mode (1)
        let mut balance1 = balance::zero<SUI>();
        balance::join(&mut balance1, balance::create_for_testing<SUI>(LOW_THRESHOLD));
        assert!(dynamic_odds::get_odds_mode(&balance1) == 1, 0);
        balance::destroy_for_testing(balance1);

        // Exactly at MEDIUM threshold (10 SUI) = Normal mode (2)
        let mut balance2 = balance::zero<SUI>();
        balance::join(&mut balance2, balance::create_for_testing<SUI>(MEDIUM_THRESHOLD));
        assert!(dynamic_odds::get_odds_mode(&balance2) == 2, 1);
        balance::destroy_for_testing(balance2);

        // Exactly at HIGH threshold (100 SUI) = Generous mode (3)
        let mut balance3 = balance::zero<SUI>();
        balance::join(&mut balance3, balance::create_for_testing<SUI>(HIGH_THRESHOLD));
        assert!(dynamic_odds::get_odds_mode(&balance3) == 3, 2);
        balance::destroy_for_testing(balance3);
    }

    // ====== ROLL ADJUSTMENT TESTS ======

    #[test]
    fun test_no_adjustment_in_normal_mode() {
        // Normal/Generous mode = no adjustment
        let mut balance = balance::zero<SUI>();
        balance::join(&mut balance, balance::create_for_testing<SUI>(50_000_000_000)); // 50 SUI
        
        // Roll 520 should stay 520
        let adjusted = dynamic_odds::adjust_roll_for_testing(&balance, 520);
        assert!(adjusted == 520, 0);
        
        balance::destroy_for_testing(balance);
    }

    #[test]
    fun test_adjustment_in_critical_mode() {
        // Critical mode = adjustment of 50
        let mut balance = balance::zero<SUI>();
        balance::join(&mut balance, balance::create_for_testing<SUI>(500_000_000)); // 0.5 SUI
        
        // Roll 520 (near boundary) should be adjusted
        // 520 - 50 = 470 (pushed into loss zone)
        let adjusted = dynamic_odds::adjust_roll_for_testing(&balance, 520);
        assert!(adjusted == 470, 0);
        
        balance::destroy_for_testing(balance);
    }

    #[test]
    fun test_no_adjustment_for_clear_win() {
        // Even in critical mode, rolls above 600 are not adjusted
        let mut balance = balance::zero<SUI>();
        balance::join(&mut balance, balance::create_for_testing<SUI>(500_000_000)); // 0.5 SUI
        
        // Roll 650 is outside adjustment zone (500-600)
        let adjusted = dynamic_odds::adjust_roll_for_testing(&balance, 650);
        assert!(adjusted == 650, 0);
        
        balance::destroy_for_testing(balance);
    }

    #[test]
    fun test_no_adjustment_for_loss() {
        // Loss rolls (<500) are never adjusted
        let mut balance = balance::zero<SUI>();
        balance::join(&mut balance, balance::create_for_testing<SUI>(500_000_000)); // 0.5 SUI
        
        // Roll 400 stays 400
        let adjusted = dynamic_odds::adjust_roll_for_testing(&balance, 400);
        assert!(adjusted == 400, 0);
        
        balance::destroy_for_testing(balance);
    }

    #[test]
    fun test_low_mode_adjustment() {
        // Low mode = adjustment of 25
        let mut balance = balance::zero<SUI>();
        balance::join(&mut balance, balance::create_for_testing<SUI>(5_000_000_000)); // 5 SUI
        
        // Roll 520 - 25 = 495 (pushed into loss)
        let adjusted = dynamic_odds::adjust_roll_for_testing(&balance, 520);
        assert!(adjusted == 495, 0);
        
        balance::destroy_for_testing(balance);
    }

    // ====== THRESHOLD VIEW TESTS ======

    #[test]
    fun test_threshold_getters() {
        assert!(dynamic_odds::get_low_threshold() == LOW_THRESHOLD, 0);
        assert!(dynamic_odds::get_medium_threshold() == MEDIUM_THRESHOLD, 1);
        assert!(dynamic_odds::get_high_threshold() == HIGH_THRESHOLD, 2);
    }

    #[test]
    fun test_mode_names() {
        assert!(dynamic_odds::get_mode_name(0) == b"CRITICAL", 0);
        assert!(dynamic_odds::get_mode_name(1) == b"LOW", 1);
        assert!(dynamic_odds::get_mode_name(2) == b"NORMAL", 2);
        assert!(dynamic_odds::get_mode_name(3) == b"GENEROUS", 3);
    }
}
