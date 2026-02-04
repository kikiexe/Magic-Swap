/// Probability engine for Magic Swap outcome calculation.
/// Implements the "Golden Math" tier system from the protocol blueprint.
module magic_swap::probability_engine {
    
    /// Calculate outcome based on random roll (0-999).
    /// 
    /// Returns: (multiplier_bps, outcome_tier)
    /// - multiplier_bps: Payout multiplier in basis points (60 = 0.60x, 105 = 1.05x)
    /// - outcome_tier: 0-4 representing the tier
    /// 
    /// Probability Distribution:
    /// - 0-499 (50.0%): LOSS      - 0.60x (60% refund)
    /// - 500-899 (40.0%): SMALL_WIN - 1.05x
    /// - 900-989 (9.0%): MEDIUM_WIN - 1.50x
    /// - 990-998 (0.9%): JACKPOT   - 8.00x
    /// - 999 (0.1%): MIRACLE    - 50.00x
    public fun calculate_outcome(roll: u16): (u64, u8) {
        if (roll < 500) {
            (60, 0)   // LOSS
        } else if (roll < 900) {
            (105, 1)  // SMALL_WIN
        } else if (roll < 990) {
            (150, 2)  // MEDIUM_WIN
        } else if (roll < 999) {
            (800, 3)  // JACKPOT
        } else {
            (5000, 4) // MIRACLE
        }
    }
}