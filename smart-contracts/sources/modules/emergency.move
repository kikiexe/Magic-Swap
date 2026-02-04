/// Emergency pause system for Magic Swap.
/// Allows admin to halt all gameplay in case of security issues.
module magic_swap::emergency {
    use magic_swap::admin::AdminCap;

    /// Shared object tracking emergency pause status.
    public struct EmergencyStatus has key {
        id: UID,
        is_paused: bool,
    }

    // ============ Error Codes ============
    const ESystemPaused: u64 = 100;

    // ============ Package Functions ============
    
    /// Create EmergencyStatus (called from main init).
    public(package) fun create(ctx: &mut TxContext): EmergencyStatus {
        EmergencyStatus {
            id: object::new(ctx),
            is_paused: false,
        }
    }

    /// Share status as shared object.
    public(package) fun share(status: EmergencyStatus) {
        transfer::share_object(status);
    }

    // ============ View Functions ============
    
    /// Check if system is paused.
    public fun is_paused(status: &EmergencyStatus): bool {
        status.is_paused
    }

    /// Assert system is not paused (aborts if paused).
    public fun assert_not_paused(status: &EmergencyStatus) {
        assert!(!status.is_paused, ESystemPaused);
    }

    // ============ Admin Functions ============
    
    /// Pause all gameplay.
    public fun pause(_: &AdminCap, status: &mut EmergencyStatus) {
        status.is_paused = true;
    }

    /// Resume gameplay.
    public fun resume(_: &AdminCap, status: &mut EmergencyStatus) {
        status.is_paused = false;
    }

    /// Toggle pause status.
    public fun toggle(_: &AdminCap, status: &mut EmergencyStatus) {
        status.is_paused = !status.is_paused;
    }
}