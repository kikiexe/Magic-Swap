module magic_swap::treasury {
    use sui::balance::{Self, Balance};

    /// Memastikan payout tidak melebihi 10% dari isi Treasury
    public fun check_safety_cap<T>(
        house_balance: &Balance<T>, 
        payout_amount: u64, 
        wager_amount: u64
    ): u64 {
        // Jika pemain kalah atau seri, tidak perlu pengecekan cap
        if (payout_amount <= wager_amount) return payout_amount;

        let profit_to_pay = payout_amount - wager_amount;
        let house_val = balance::value(house_balance);
        
        // Batas maksimal profit adalah 10% dari total isi kas (Blueprint)
        let max_profit_allowed = (house_val * 10) / 100;

        if (profit_to_pay > max_profit_allowed) {
            // Jika melebihi cap, berikan modal + 10% treasury
            wager_amount + max_profit_allowed
        } else {
            payout_amount
        }
    }
}