module magic_swap::user_types {
    #[allow(unused_field)]
    public struct UserStats has store {
        total_wagered: u64,
        total_payout: u64,
        games_played: u64,
    }
}