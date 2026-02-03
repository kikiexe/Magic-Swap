module magic_swap::reward_types {
    #[allow(unused_field)]
    public struct RewardInfo has store {
        multiplier_bps: u64,
        outcome_name: std::ascii::String,
    }
}