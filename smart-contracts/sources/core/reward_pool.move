module magic_swap::reward_pool {
    // Gunakan Self agar modul 'coin' bisa dipanggil
    use sui::coin::{Self, Coin};
    use sui::balance::Balance;

    /// RewardPool stores accumulated fees or extra funds.
    /// This pool can be used for:
    /// 1. Staking rewards distribution
    /// 2. Jackpot payouts (if connected)
    /// 3. Community treasury reserves
    public struct RewardPool<phantom T> has key {
        id: UID,
        vault: Balance<T>,
    }

    public struct RewardPoolCap has key, store {
        id: UID,
    }

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
}