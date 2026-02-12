module magic_swap::reward_pool {
    // Gunakan Self agar modul 'coin' bisa dipanggil
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};

    // ============ Error Codes ============
    
    /// Insufficient balance in reward pool for withdrawal
    const EInsufficientPoolBalance: u64 = 201;

    // ============ Structs ============
    
    /// RewardPool stores accumulated fees or extra funds.
    /// This pool can be used for:
    /// 1. Staking rewards distribution
    /// 2. Jackpot payouts (if connected)
    /// 3. Community treasury reserves
    public struct RewardPool<phantom T> has key {
        id: UID,
        vault: Balance<T>,
    }

    /// Capability to manage the reward pool
    public struct RewardPoolCap has key, store {
        id: UID,
    }

    // ============ Initialization ============
    
    /// Create a new reward pool with initial funding
    #[allow(lint(self_transfer))]
    public fun create_pool<T>(initial_fund: Coin<T>, ctx: &mut TxContext) {
        // Tambahkan <T> pada RewardPool agar compiler tidak bingung
        let pool = RewardPool<T> {
            id: object::new(ctx),
            vault: coin::into_balance(initial_fund),
        };
        transfer::share_object(pool);

        let cap = RewardPoolCap { id: object::new(ctx) };
        transfer::public_transfer(cap, ctx.sender());
    }

    // ============ Admin Functions ============
    
    /// Withdraw funds from the reward pool (requires RewardPoolCap)
    /// This prevents funds from being locked forever in the pool
    #[allow(lint(self_transfer))]
    public fun withdraw_from_pool<T>(
        _cap: &RewardPoolCap,
        pool: &mut RewardPool<T>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert!(balance::value(&pool.vault) >= amount, EInsufficientPoolBalance);
        let coin = coin::take(&mut pool.vault, amount, ctx);
        transfer::public_transfer(coin, ctx.sender());
    }
    
    /// Deposit additional funds into the reward pool
    public fun deposit_to_pool<T>(pool: &mut RewardPool<T>, coin: Coin<T>) {
        balance::join(&mut pool.vault, coin.into_balance());
    }

    // ============ View Functions ============
    
    /// Get current reward pool balance
    public fun get_pool_balance<T>(pool: &RewardPool<T>): u64 {
        balance::value(&pool.vault)
    }
}