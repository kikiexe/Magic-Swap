/// Probability engine tests for Magic Swap.
/// Tests roll ranges and outcome mapping.
#[test_only]
module magic_swap::probability_tests {
    use magic_swap::probability_engine;

    #[test]
    fun test_probability_ranges() {
        // 1. Loss Range (0-549) -> 60% Refund
        let (mult, outcome) = probability_engine::calculate_outcome(0);
        assert!(mult == 60 && outcome == 0, 0);
        let (mult, outcome) = probability_engine::calculate_outcome(549);
        assert!(mult == 60 && outcome == 0, 1);

        // 2. Small Win (550-899) -> 1.05x
        let (mult, outcome) = probability_engine::calculate_outcome(550);
        assert!(mult == 105 && outcome == 1, 2);
        let (mult, outcome) = probability_engine::calculate_outcome(899);
        assert!(mult == 105 && outcome == 1, 3);

        // 3. Medium Win (900-979) -> 1.50x
        let (mult, outcome) = probability_engine::calculate_outcome(900);
        assert!(mult == 150 && outcome == 2, 4);
        let (mult, outcome) = probability_engine::calculate_outcome(979);
        assert!(mult == 150 && outcome == 2, 5);

        // 4. Jackpot (980-994) -> 6.00x
        let (mult, outcome) = probability_engine::calculate_outcome(980);
        assert!(mult == 600 && outcome == 3, 6);
        let (mult, outcome) = probability_engine::calculate_outcome(994);
        assert!(mult == 600 && outcome == 3, 7);

        // 5. Miracle (995-999) -> 9x
        let (mult, outcome) = probability_engine::calculate_outcome(999);
        assert!(mult == 900 && outcome == 4, 8);
    }
}