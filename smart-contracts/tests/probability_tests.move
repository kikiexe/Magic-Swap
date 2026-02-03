#[test_only]
module magic_swap::probability_tests {
    use magic_swap::probability_engine;

    #[test]
    fun test_probability_ranges() {
        // 1. Test Loss Range (0-499) -> 60% Refund
        let (mult, outcome) = probability_engine::calculate_outcome(0);
        assert!(mult == 60 && outcome == 0, 0);
        let (mult, outcome) = probability_engine::calculate_outcome(499);
        assert!(mult == 60 && outcome == 0, 1);

        // 2. Test Small Win (500-899) -> 1.05x
        let (mult, outcome) = probability_engine::calculate_outcome(500);
        assert!(mult == 105 && outcome == 1, 2);
        let (mult, outcome) = probability_engine::calculate_outcome(899);
        assert!(mult == 105 && outcome == 1, 3);

        // 3. Test Medium Win (900-989) -> 1.50x
        let (mult, outcome) = probability_engine::calculate_outcome(900);
        assert!(mult == 150 && outcome == 2, 4);
        let (mult, outcome) = probability_engine::calculate_outcome(989);
        assert!(mult == 150 && outcome == 2, 5);

        // 4. Test Jackpot (990-998) -> 8.00x
        let (mult, outcome) = probability_engine::calculate_outcome(990);
        assert!(mult == 800 && outcome == 3, 6);
        let (mult, outcome) = probability_engine::calculate_outcome(998);
        assert!(mult == 800 && outcome == 3, 7);

        // 5. Test Miracle (999) -> 50x
        let (mult, outcome) = probability_engine::calculate_outcome(999);
        assert!(mult == 5000 && outcome == 4, 8);
    }
}