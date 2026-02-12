/// Probability engine for Magic Swap outcome calculation.
/// Implements the "Golden Math" tier system from the protocol blueprint.
module magic_swap::probability_engine {
    
    /// Calculate outcome based on random roll (0-999).
    /// 
    /// Returns: (multiplier_bps, outcome_tier)
    /// - multiplier_bps: Payout multiplier in basis points (60 = 0.60x, 105 = 1.05x)
    /// - outcome_tier: 0-4 representing the tier
    /// 
    /// Probability Distribution (Optimized for House Sustainability):
    /// - 0-549 (55.0%): LOSS      - 0.60x (60% refund, 40% house take)
    /// - 550-899 (35.0%): SMALL_WIN - 1.05x (5% player profit)
    /// - 900-979 (8.0%): MEDIUM_WIN - 1.50x (50% player profit)
    /// - 980-994 (1.5%): JACKPOT   - 6.00x (500% player profit)
    /// - 995-999 (0.5%): MIRACLE    - 9.00x (800% player profit)
    /// 
    /// House Edge Calculation:
    /// Expected Value = (0.55 × -0.40) + (0.35 × 0.05) + (0.08 × 0.50) + (0.015 × 5.00) + (0.005 × 8.00)
    ///                = -0.22 + 0.0175 + 0.04 + 0.075 + 0.04 = -0.0475 (~4.75% house edge)
    public fun calculate_outcome(roll: u16): (u64, u8) {
        if (roll < 550) {
            (60, 0)   // LOSS - Player gets 60% back
        } else if (roll < 900) {
            (105, 1)  // SMALL_WIN - 1.05x multiplier
        } else if (roll < 980) {
            (150, 2)  // MEDIUM_WIN - 1.50x multiplier
        } else if (roll < 995) {
            (600, 3)  // JACKPOT - 6.00x multiplier (reduced from 8x)
        } else {
            (900, 4) // MIRACLE - 9.00x multiplier (reduced from 50x)
        }
    }
}