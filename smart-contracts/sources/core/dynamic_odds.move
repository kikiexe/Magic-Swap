module magic_swap::dynamic_odds {
    use sui::balance::{Self, Balance};

    // --- Constants ---
    /// Treasury thresholds for dynamic odds adjustment (in MIST for SUI)
    const LOW_TREASURY_THRESHOLD: u64 = 1_000_000_000;      // 1 SUI
    const MEDIUM_TREASURY_THRESHOLD: u64 = 10_000_000_000;  // 10 SUI
    const HIGH_TREASURY_THRESHOLD: u64 = 100_000_000_000;   // 100 SUI

    /// Roll adjustment values (added to base roll)
    /// Lower adjustment = lower win chance (roll stays in loss range longer)
    /// Higher adjustment = higher win chance (roll pushed into win range)
    const CRITICAL_ADJUSTMENT: u64 = 50;  // Push rolls DOWN (more losses when treasury critical)
    const LOW_ADJUSTMENT: u64 = 25;       // Slight push down
    const NORMAL_ADJUSTMENT: u64 = 0;     // No adjustment

    // --- Odds Mode Enum ---
    // 0 = Critical (treasury < 1 SUI): Very conservative
    // 1 = Low (1-10 SUI): Conservative
    // 2 = Normal (10-100 SUI): Standard odds
    // 3 = Generous (> 100 SUI): Player-friendly

    // --- Core Functions ---
    
    /// Get the current odds mode based on treasury balance
    public fun get_odds_mode<T>(house_balance: &Balance<T>): u8 {
        let treasury = balance::value(house_balance);
        
        if (treasury < LOW_TREASURY_THRESHOLD) {
            0 // Critical
        } else if (treasury < MEDIUM_TREASURY_THRESHOLD) {
            1 // Low
        } else if (treasury < HIGH_TREASURY_THRESHOLD) {
            2 // Normal
        } else {
            3 // Generous
        }
    }

    /// Adjust the roll based on treasury status
    /// Returns adjusted roll value (still 0-999)
    /// 
    /// Strategy:
    /// - When treasury is low, we want MORE losses (outcome 0)
    /// - Loss range is 0-499, so we ADD to rolls in 500-549 range to push them back to loss
    /// - This is done by subtracting from the roll if it's near the boundary
    public fun adjust_roll<T>(house_balance: &Balance<T>, base_roll: u16): u16 {
        let mode = get_odds_mode(house_balance);
        
        // Get adjustment based on mode
        let adjustment = if (mode == 0) {
            CRITICAL_ADJUSTMENT
        } else if (mode == 1) {
            LOW_ADJUSTMENT
        } else {
            NORMAL_ADJUSTMENT
        };
        
        // Only adjust rolls in the "near-win" zone (500-600)
        // This makes borderline wins become losses when treasury is low
        if (adjustment > 0 && base_roll >= 500 && base_roll < 600) {
            let adjusted = (base_roll as u64);
            if (adjusted >= adjustment + 500) {
                // Subtract adjustment, but don't go below 500-adjustment boundary
                let new_roll = adjusted - adjustment;
                if (new_roll < 500) {
                    // Push into loss zone
                    (new_roll as u16)
                } else {
                    base_roll // Keep as is if still in win zone
                }
            } else {
                // Roll is very close to 500, push it to loss
                ((adjusted - adjustment) as u16)
            }
        } else {
            base_roll
        }
    }

    /// Check if dynamic odds are active (treasury is not in normal/generous mode)
    public fun is_conservative_mode<T>(house_balance: &Balance<T>): bool {
        let mode = get_odds_mode(house_balance);
        mode < 2
    }

    // --- View Functions ---
    
    /// Get mode name for display
    public fun get_mode_name(mode: u8): vector<u8> {
        if (mode == 0) {
            b"CRITICAL"
        } else if (mode == 1) {
            b"LOW"
        } else if (mode == 2) {
            b"NORMAL"
        } else {
            b"GENEROUS"
        }
    }

    /// Get thresholds (for frontend display)
    public fun get_low_threshold(): u64 {
        LOW_TREASURY_THRESHOLD
    }

    public fun get_medium_threshold(): u64 {
        MEDIUM_TREASURY_THRESHOLD
    }

    public fun get_high_threshold(): u64 {
        HIGH_TREASURY_THRESHOLD
    }

    // --- Test Helpers ---
    #[test_only]
    public fun adjust_roll_for_testing<T>(house_balance: &Balance<T>, roll: u16): u16 {
        adjust_roll(house_balance, roll)
    }
}
