module magic_swap::swap_types {
    #[allow(unused_field)]
    public struct SwapConfig has store {
        is_active: bool,
        min_wager: u64,
        max_wager: u64,
    }
}