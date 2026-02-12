module magic_swap::events {
    use sui::event;

    public struct AdminActionEvent has copy, drop {
        action: std::ascii::String,
        admin: address,
        timestamp: u64,
    }

    public fun emit_admin_action(action: std::ascii::String, admin: address, ctx: &sui::tx_context::TxContext) {
        event::emit(AdminActionEvent {
            action,
            admin,
            timestamp: sui::tx_context::epoch(ctx),
        });
    }
}