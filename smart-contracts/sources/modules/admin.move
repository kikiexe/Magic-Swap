/// Admin capability module for Magic Swap.
/// Provides authorization for privileged operations.
module magic_swap::admin {
    
    /// Capability object granting admin privileges.
    /// Holder can: create games, withdraw funds, pause system, etc.
    public struct AdminCap has key, store {
        id: UID,
    }

    /// Create AdminCap (package-level access only).
    public(package) fun create_admin_cap(ctx: &mut TxContext): AdminCap {
        AdminCap { id: object::new(ctx) }
    }

    /// Permanently destroy an AdminCap.
    public fun burn_admin_cap(cap: AdminCap) {
        let AdminCap { id } = cap;
        object::delete(id);
    }
}