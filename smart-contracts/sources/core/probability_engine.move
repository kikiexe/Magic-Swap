module magic_swap::probability_engine {
    /// Menghitung outcome berdasarkan angka roll (0-999)
    /// Mengembalikan: (Multiplier dalam BPS, Tipe Outcome)
    public fun calculate_outcome(roll: u16): (u64, u8) {
        if (roll < 500) {
            // LOSS: Refund 60% (Multiplier 0.60x)
            (60, 0) 
        } else if (roll < 900) {
            // Small Win: 1.05x
            (105, 1) 
        } else if (roll < 990) {
            // Medium Win: 1.50x
            (150, 2) 
        } else if (roll < 999) {
            // Jackpot: 8.00x
            (800, 3) 
        } else {
            // Miracle: 50.00x
            (5000, 4) 
        }
    }
}