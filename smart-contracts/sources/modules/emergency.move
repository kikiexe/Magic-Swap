module magic_swap::emergency {
    use magic_swap::game::AdminCap;

    public struct EmergencyStatus has key {
        id: UID,
        is_paused: bool,
    }

    /// Mengecek apakah sistem sedang dihentikan
    public fun is_paused(status: &EmergencyStatus): bool {
        status.is_paused
    }

    /// Admin menghentikan semua permainan
    public fun pause(_: &AdminCap, status: &mut EmergencyStatus) {
        status.is_paused = true;
    }

    /// Admin mengaktifkan kembali permainan
    public fun resume(_: &AdminCap, status: &mut EmergencyStatus) {
        status.is_paused = false;
    }
}