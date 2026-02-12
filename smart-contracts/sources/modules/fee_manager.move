/// Fee management module for Magic Swap.
/// Handles 1% operational fee collection and admin withdrawals.
module magic_swap::fee_manager {
    use sui::coin;
    use sui::balance::{Self, Balance};
    use magic_swap::admin::AdminCap;

    // ============ Constants ============
    /// Operational fee: 1% (100 basis points)
    const OPERATIONAL_FEE_BPS: u64 = 100;

    // ============ Error Codes ============
    const EInsufficientFees: u64 = 200;

    // ============ Structs ============
    
    /// Vault storing collected fees.
    public struct FeeVault<phantom T> has key {
        id: UID,
        collected_fees: Balance<T>,
        total_collected: u64,
        total_withdrawn: u64,
    }

    // ============ Package Functions ============
    
    /// Create a new FeeVault.
    public(package) fun create_vault<T>(ctx: &mut TxContext): FeeVault<T> {
        FeeVault<T> {
            id: object::new(ctx),
            collected_fees: balance::zero(),
            total_collected: 0,
            total_withdrawn: 0,
        }
    }

    /// Share vault as shared object.
    public(package) fun share_vault<T>(vault: FeeVault<T>) {
        transfer::share_object(vault);
    }

    /// Collect fee from a balance.
    public(package) fun collect_fee_from_balance<T>(
        vault: &mut FeeVault<T>,
        fee_balance: Balance<T>
    ) {
        let fee_amount = balance::value(&fee_balance);
        vault.total_collected = vault.total_collected + fee_amount;
        balance::join(&mut vault.collected_fees, fee_balance);
    }

    // ============ Fee Calculation ============
    
    /// Calculate fee amount (1% of wager).
    public fun calculate_fee(amount: u64): u64 {
        (amount * OPERATIONAL_FEE_BPS) / 10000
    }

    /// Get net amount after fee deduction.
    /// Returns: (net_amount, fee_amount)
    public fun get_net_amount(amount: u64): (u64, u64) {
        let fee = calculate_fee(amount);
        (amount - fee, fee)
    }

    // ============ Admin Functions ============
    
    /// Withdraw specific amount of fees.
    #[allow(lint(self_transfer))]
    public fun withdraw_fees<T>(
        _: &AdminCap,
        vault: &mut FeeVault<T>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&vault.collected_fees) >= amount, EInsufficientFees);
        
        let withdrawn = coin::take(&mut vault.collected_fees, amount, ctx);
        vault.total_withdrawn = vault.total_withdrawn + amount;
        transfer::public_transfer(withdrawn, ctx.sender());
    }

    /// Withdraw all collected fees.
    #[allow(lint(self_transfer))]
    public fun withdraw_all_fees<T>(
        _: &AdminCap,
        vault: &mut FeeVault<T>,
        ctx: &mut TxContext
    ) {
        let amount = balance::value(&vault.collected_fees);
        if (amount > 0) {
            let withdrawn = coin::take(&mut vault.collected_fees, amount, ctx);
            vault.total_withdrawn = vault.total_withdrawn + amount;
            transfer::public_transfer(withdrawn, ctx.sender());
        }
    }

    // ============ View Functions ============
    
    public fun get_fee_balance<T>(vault: &FeeVault<T>): u64 {
        balance::value(&vault.collected_fees)
    }

    public fun get_total_collected<T>(vault: &FeeVault<T>): u64 {
        vault.total_collected
    }

    public fun get_total_withdrawn<T>(vault: &FeeVault<T>): u64 {
        vault.total_withdrawn
    }

    public fun get_fee_rate_bps(): u64 {
        OPERATIONAL_FEE_BPS
    }

    // ============ Test Helpers ============
    #[test_only]
    public fun create_vault_for_testing<T>(ctx: &mut TxContext): FeeVault<T> {
        create_vault<T>(ctx)
    }

    #[test_only]
    public fun destroy_vault_for_testing<T>(vault: FeeVault<T>) {
        let FeeVault { id, collected_fees, total_collected: _, total_withdrawn: _ } = vault;
        object::delete(id);
        balance::destroy_for_testing(collected_fees);
    }
}