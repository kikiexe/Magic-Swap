module magic_swap::probability_engine {
    use sui::random::{Self, Random};
    use sui::tx_context::TxContext;

    // --- Types ---
    public struct Outcome has copy, drop {
        tier: u8, // 0: Loss, 1: Small, 2: Medium, 3: Jackpot, 4: Miracle
        multiplier: u64, // Scaled by 100 (e.g. 105 = 1.05x)
    }

    // --- Functions ---
    public fun resolve(r: &Random, ctx: &mut TxContext): Outcome {
        let mut generator = random::new_generator(r, ctx);
        let roll = random::generate_u16_in_range(&mut generator, 0, 999);
        
        /* 
           0-499   (50.0%): LOSS -> Refund 60%
           500-899 (40.0%): Small Win -> 1.05x
           900-989 (9.0%) : Medium Win -> 1.50x
           990-998 (0.9%) : Jackpot -> 8.00x
           999     (0.1%) : Miracle -> 50.00x
        */
        
        if (roll < 500) {
            Outcome { tier: 0, multiplier: 60 }
        } else if (roll < 900) {
            Outcome { tier: 1, multiplier: 105 }
        } else if (roll < 990) {
            Outcome { tier: 2, multiplier: 150 }
        } else if (roll < 999) {
            Outcome { tier: 3, multiplier: 800 }
        } else {
            Outcome { tier: 4, multiplier: 5000 }
        }
    }

    public fun get_multiplier(outcome: &Outcome): u64 {
        outcome.multiplier
    }

    public fun get_tier(outcome: &Outcome): u8 {
        outcome.tier
    }

    #[test_only]
    public fun create_outcome_for_testing(tier: u8, multiplier: u64): Outcome {
        Outcome { tier, multiplier }
    }
}
