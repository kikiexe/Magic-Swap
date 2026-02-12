/// Treasury safety module for Magic Swap.
/// Implements the Safety Valve mechanism to prevent house bankruptcy.
module magic_swap::treasury {
    use sui::balance::{Self, Balance};

    /// Enforces the 10% safety cap on player winnings.
    /// 
    /// Ensures that no single payout can drain more than 10% of treasury,
    /// protecting the house from consecutive large wins.
    /// 
    /// Returns:
    /// - Original payout if profit <= 10% of treasury
    /// - Capped payout (wager + 10% of treasury) if exceeds limit
    public fun check_safety_cap<T>(
        house_balance: &Balance<T>, 
        payout_amount: u64, 
        wager_amount: u64
    ): u64 {
        // No cap needed if player lost or broke even
        if (payout_amount <= wager_amount) return payout_amount;

        let profit_to_pay = payout_amount - wager_amount;
        let house_val = balance::value(house_balance);
        
        // Maximum profit is 10% of treasury
        let max_profit_allowed = (house_val * 10) / 100;

        if (profit_to_pay > max_profit_allowed) {
            wager_amount + max_profit_allowed
        } else {
            payout_amount
        }
    }
}