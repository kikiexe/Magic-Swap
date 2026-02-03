module magic_swap::admin {
    public struct AdminCap has key, store {
        id: UID,
    }

    /// Membuat AdminCap (hanya bisa dipanggil oleh module sekawan/package)
    public(package) fun create_admin_cap(ctx: &mut TxContext): AdminCap {
        AdminCap { id: object::new(ctx) }
    }

    public fun burn_admin_cap(cap: AdminCap) {
        let AdminCap { id } = cap;
        object::delete(id);
    }
}