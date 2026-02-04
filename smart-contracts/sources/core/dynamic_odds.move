/// Dynamic odds adjustment for Magic Swap.
/// Adjusts win probability based on treasury level to protect house solvency.
module magic_swap::dynamic_odds {
    use sui::balance::{Self, Balance};

    // ============ Treasury Thresholds (in MIST) ============
    const LOW_TREASURY_THRESHOLD: u64 = 1_000_000_000;      // 1 SUI
    const MEDIUM_TREASURY_THRESHOLD: u64 = 10_000_000_000;  // 10 SUI
    const HIGH_TREASURY_THRESHOLD: u64 = 100_000_000_000;   // 100 SUI

    // ============ Roll Adjustments ============
    // Higher adjustment = more borderline wins become losses
    const CRITICAL_ADJUSTMENT: u64 = 50;
    const LOW_ADJUSTMENT: u64 = 25;
    const NORMAL_ADJUSTMENT: u64 = 0;

    // ============ Core Functions ============
    
    /// Get current odds mode based on treasury balance.
    /// 
    /// Modes:
    /// - 0 (CRITICAL): Treasury < 1 SUI - Very conservative
    /// - 1 (LOW): 1-10 SUI - Conservative  
    /// - 2 (NORMAL): 10-100 SUI - Standard odds
    /// - 3 (GENEROUS): > 100 SUI - Player-friendly
    public fun get_odds_mode<T>(house_balance: &Balance<T>): u8 {
        let treasury = balance::value(house_balance);
        
        if (treasury < LOW_TREASURY_THRESHOLD) {
            0
        } else if (treasury < MEDIUM_TREASURY_THRESHOLD) {
            1
        } else if (treasury < HIGH_TREASURY_THRESHOLD) {
            2
        } else {
            3
        }
    }

    /// Adjust roll based on treasury status.
    /// 
    /// When treasury is low, borderline wins (rolls 500-600) are pushed
    /// into the loss zone to reduce house exposure.
    public fun adjust_roll<T>(house_balance: &Balance<T>, base_roll: u16): u16 {
        let mode = get_odds_mode(house_balance);
        
        let adjustment = if (mode == 0) {
            CRITICAL_ADJUSTMENT
        } else if (mode == 1) {
            LOW_ADJUSTMENT
        } else {
            NORMAL_ADJUSTMENT
        };
        
        // Only adjust borderline wins (500-600 range)
        if (adjustment > 0 && base_roll >= 500 && base_roll < 600) {
            let adjusted = (base_roll as u64);
            if (adjusted >= adjustment + 500) {
                let new_roll = adjusted - adjustment;
                if (new_roll < 500) {
                    (new_roll as u16)
                } else {
                    base_roll
                }
            } else {
                ((adjusted - adjustment) as u16)
            }
        } else {
            base_roll
        }
    }

    /// Check if odds are in conservative mode (treasury low).
    public fun is_conservative_mode<T>(house_balance: &Balance<T>): bool {
        get_odds_mode(house_balance) < 2
    }

    // ============ View Functions ============
    
    /// Get mode name as bytes.
    public fun get_mode_name(mode: u8): vector<u8> {
        if (mode == 0) { b"CRITICAL" }
        else if (mode == 1) { b"LOW" }
        else if (mode == 2) { b"NORMAL" }
        else { b"GENEROUS" }
    }

    public fun get_low_threshold(): u64 { LOW_TREASURY_THRESHOLD }
    public fun get_medium_threshold(): u64 { MEDIUM_TREASURY_THRESHOLD }
    public fun get_high_threshold(): u64 { HIGH_TREASURY_THRESHOLD }

    // ============ Test Helpers ============
    #[test_only]
    public fun adjust_roll_for_testing<T>(house_balance: &Balance<T>, roll: u16): u16 {
        adjust_roll(house_balance, roll)
    }
}
