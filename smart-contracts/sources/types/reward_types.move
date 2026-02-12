module magic_swap::reward_types {
    use std::string::{Self, String};

    public struct RewardInfo has store, drop {
        multiplier_bps: u64,
        outcome_name: String,
    }

    public fun get_tier_info(tier: u8): RewardInfo {
        if (tier == 0) {
            RewardInfo { 
                multiplier_bps: 60, 
                outcome_name: string::utf8(b"LOSS") 
            }
        } else if (tier == 1) {
            RewardInfo { 
                multiplier_bps: 105, 
                outcome_name: string::utf8(b"SMALL_WIN") 
            }
        } else if (tier == 2) {
            RewardInfo { 
                multiplier_bps: 150, 
                outcome_name: string::utf8(b"MEDIUM_WIN") 
            }
        } else if (tier == 3) {
            RewardInfo { 
                multiplier_bps: 800, 
                outcome_name: string::utf8(b"JACKPOT") 
            }
        } else {
            // Tier 4 (Miracle) or others
            RewardInfo { 
                multiplier_bps: 5000, 
                outcome_name: string::utf8(b"MIRACLE") 
            }
        }
    }
}