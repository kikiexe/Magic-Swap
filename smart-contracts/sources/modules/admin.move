module magic_swap::admin {
    use magic_swap::game::AdminCap;

    public fun verify_admin(_cap: &AdminCap) {
        // Logika verifikasi tambahan jika diperlukan
    }
}