module magic_swap::fee_manager {
    // Definisi fee untuk operasional (misal 1% untuk maintenance)
    const OPERATIONAL_FEE_BPS: u64 = 100; 

    public fun calculate_fee(amount: u64): u64 {
        (amount * OPERATIONAL_FEE_BPS) / 10000
    }
}