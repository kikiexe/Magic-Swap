module magic_swap::emergency {
    use magic_swap::admin::AdminCap;

    public struct EmergencyStatus has key {
        id: UID,
        is_paused: bool,
    }

    /// Error codes
    const ESystemPaused: u64 = 100;

    /// Membuat objek status (hanya bisa dipanggil oleh module sekawan/package)
    public(package) fun create(ctx: &mut TxContext): EmergencyStatus {
        EmergencyStatus {
            id: object::new(ctx),
            is_paused: false,
        }
    }

    /// Membagikan objek status agar bisa diakses public (Shared Object)
    public(package) fun share(status: EmergencyStatus) {
        transfer::share_object(status);
    }

    /// Mengecek apakah sistem sedang dihentikan
    public fun is_paused(status: &EmergencyStatus): bool {
        status.is_paused
    }

    /// Memastikan sistem tidak pause, jika pause akan abort
    public fun assert_not_paused(status: &EmergencyStatus) {
        assert!(!status.is_paused, ESystemPaused);
    }

    /// Admin menghentikan semua permainan
    public fun pause(_: &AdminCap, status: &mut EmergencyStatus) {
        status.is_paused = true;
    }

    /// Admin mengaktifkan kembali permainan
    public fun resume(_: &AdminCap, status: &mut EmergencyStatus) {
        status.is_paused = false;
    }

    /// Admin mengubah status pause (ON <-> OFF)
    public fun toggle(_: &AdminCap, status: &mut EmergencyStatus) {
        status.is_paused = !status.is_paused;
    }
}