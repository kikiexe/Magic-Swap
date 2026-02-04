module magic_swap::swap_types {
    #[allow(unused_field)]
    public struct SwapConfig has store, copy, drop {
        min_wager: u64,
        max_wager: u64,
    }

    /// Membuat objek config (hanya bisa dipanggil oleh module sekawan/package)
    public(package) fun create(min: u64, max: u64): SwapConfig {
        SwapConfig {
            min_wager: min,
            max_wager: max,
        }
    }

    public fun min_wager(config: &SwapConfig): u64 { config.min_wager }
    public fun max_wager(config: &SwapConfig): u64 { config.max_wager }

    // Allow updating config logic to be handled by admin modules or directly in game
    public(package) fun update(config: &mut SwapConfig, min: u64, max: u64) {
        config.min_wager = min;
        config.max_wager = max;
    }
}