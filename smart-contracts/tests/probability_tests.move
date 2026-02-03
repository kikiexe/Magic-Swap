#[test_only]
module magic_swap::probability_tests {
    use magic_swap::probability_engine;

    #[test]
    fun test_probability_ranges() {
        // Test Loss Range (0-499) -> 60% Refund
        let (mult, outcome) = probability_engine::calculate_outcome(0);
        assert!(mult == 60 && outcome == 0, 0);
        let (mult, outcome) = probability_engine::calculate_outcome(499);
        assert!(mult == 60 && outcome == 0, 1);

        // Test Small Win (500-899) -> 1.05x
        let (mult, outcome) = probability_engine::calculate_outcome(500);
        assert!(mult == 105 && outcome == 1, 2);

        // Test Miracle (999) -> 50x
        let (mult, outcome) = probability_engine::calculate_outcome(999);
        assert!(mult == 5000 && outcome == 4, 3);
    }
}