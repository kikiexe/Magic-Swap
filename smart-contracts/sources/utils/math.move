module magic_swap::math {
    /// Menghitung nilai berdasarkan Basis Points (10000 = 100%)
    public fun scale_by_bps(amount: u64, bps: u64): u64 {
        (amount * bps) / 10000
    }
}