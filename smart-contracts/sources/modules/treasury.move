module magic_swap::treasury {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    // --- Errors ---
    const EInsufficientBalance: u64 = 0;

    // --- Objects ---
    public struct Treasury<phantom T> has key {
        id: UID,
        balance: Balance<T>,
    }

    public struct TreasuryCap has key, store {
        id: UID,
    }

    // --- Functions ---
    public fun create_treasury<T>(initial_fund: Coin<T>, ctx: &mut TxContext) {
        let treasury = Treasury<T> {
            id: object::new(ctx),
            balance: initial_fund.into_balance(),
        };
        transfer::share_object(treasury);

        let cap = TreasuryCap {
            id: object::new(ctx),
        };
        transfer::public_transfer(cap, ctx.sender());
    }

    public fun deposit<T>(t: &mut Treasury<T>, coin: Coin<T>) {
        balance::join(&mut t.balance, coin.into_balance());
    }

    public fun deposit_balance<T>(t: &mut Treasury<T>, balance: Balance<T>) {
        balance::join(&mut t.balance, balance);
    }

    public fun withdraw<T>(
        _: &TreasuryCap,
        t: &mut Treasury<T>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<T> {
        assert!(balance::value(&t.balance) >= amount, EInsufficientBalance);
        let b = balance::split(&mut t.balance, amount);
        coin::from_balance(b, ctx)
    }

    public fun value<T>(t: &Treasury<T>): u64 {
        balance::value(&t.balance)
    }

    public(package) fun take_balance<T>(t: &mut Treasury<T>, amount: u64): Balance<T> {
        assert!(balance::value(&t.balance) >= amount, EInsufficientBalance);
        balance::split(&mut t.balance, amount)
    }
}
