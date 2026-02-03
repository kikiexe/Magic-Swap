module magic_swap::loss_cap {
    // --- Constants ---
    const MAX_PAYOUT_PERCENT: u64 = 10; // 10% of treasury

    // --- Functions ---
    public fun cap_payout_10_percent(
        treasury_balance: u64,
        wager_amount: u64,
        desired_payout: u64
    ): (u64, bool) {
        if (desired_payout <= wager_amount) {
            return (desired_payout, false)
        };

        let profit = desired_payout - wager_amount;
        let max_profit = (treasury_balance * MAX_PAYOUT_PERCENT) / 100;

        if (profit > max_profit) {
            (wager_amount + max_profit, true)
        } else {
            (desired_payout, false)
        }
    }
}
