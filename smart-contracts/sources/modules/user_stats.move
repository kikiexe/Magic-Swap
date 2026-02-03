module magic_swap::user_stats {
    use sui::table::{Self, Table};
    use magic_swap::admin::AdminCap;

    // --- Structs ---
    /// User statistics tracking
    public struct UserStats has store, copy, drop {
        total_wagered: u64,
        total_payout: u64,
        games_played: u64,
        // Tier wins: [loss, small_win, medium_win, jackpot, miracle]
        tier_counts: vector<u64>,
        net_profit: u64,  // Can be negative conceptually, but stored as absolute
        is_profit: bool,  // true = profit, false = loss
    }

    /// Registry to store all user stats (Shared Object)
    public struct UserStatsRegistry has key {
        id: UID,
        stats: Table<address, UserStats>,
        total_players: u64,
        total_games: u64,
    }

    // --- Init Helper ---
    /// Create the registry (called from main init)
    public(package) fun create_registry(ctx: &mut TxContext): UserStatsRegistry {
        UserStatsRegistry {
            id: object::new(ctx),
            stats: table::new(ctx),
            total_players: 0,
            total_games: 0,
        }
    }

    /// Share the registry
    public(package) fun share_registry(registry: UserStatsRegistry) {
        transfer::share_object(registry);
    }

    // --- Core Functions ---
    /// Update user stats after a game (called from play())
    public(package) fun update_stats(
        registry: &mut UserStatsRegistry,
        player: address,
        wager: u64,
        payout: u64,
        outcome_tier: u8,
    ) {
        // Create new user if not exists
        if (!table::contains(&registry.stats, player)) {
            let new_stats = UserStats {
                total_wagered: 0,
                total_payout: 0,
                games_played: 0,
                tier_counts: vector[0, 0, 0, 0, 0],
                net_profit: 0,
                is_profit: true,
            };
            table::add(&mut registry.stats, player, new_stats);
            registry.total_players = registry.total_players + 1;
        };

        // Get mutable reference to stats
        let stats = table::borrow_mut(&mut registry.stats, player);
        
        // Update basic stats
        stats.total_wagered = stats.total_wagered + wager;
        stats.total_payout = stats.total_payout + payout;
        stats.games_played = stats.games_played + 1;
        
        // Update tier count
        let tier_idx = (outcome_tier as u64);
        if (tier_idx < 5) {
            let current_count = *vector::borrow(&stats.tier_counts, tier_idx);
            *vector::borrow_mut(&mut stats.tier_counts, tier_idx) = current_count + 1;
        };
        
        // Calculate net profit/loss
        if (stats.total_payout >= stats.total_wagered) {
            stats.net_profit = stats.total_payout - stats.total_wagered;
            stats.is_profit = true;
        } else {
            stats.net_profit = stats.total_wagered - stats.total_payout;
            stats.is_profit = false;
        };
        
        // Update global counter
        registry.total_games = registry.total_games + 1;
    }

    // --- View Functions ---
    /// Check if user has stats
    public fun has_stats(registry: &UserStatsRegistry, player: address): bool {
        table::contains(&registry.stats, player)
    }

    /// Get user stats (returns default if not found)
    public fun get_stats(registry: &UserStatsRegistry, player: address): UserStats {
        if (table::contains(&registry.stats, player)) {
            *table::borrow(&registry.stats, player)
        } else {
            UserStats {
                total_wagered: 0,
                total_payout: 0,
                games_played: 0,
                tier_counts: vector[0, 0, 0, 0, 0],
                net_profit: 0,
                is_profit: true,
            }
        }
    }

    /// Get total wagered by user
    public fun get_total_wagered(stats: &UserStats): u64 {
        stats.total_wagered
    }

    /// Get total payout to user
    public fun get_total_payout(stats: &UserStats): u64 {
        stats.total_payout
    }

    /// Get games played by user
    public fun get_games_played(stats: &UserStats): u64 {
        stats.games_played
    }

    /// Get tier counts [loss, small, medium, jackpot, miracle]
    public fun get_tier_counts(stats: &UserStats): vector<u64> {
        stats.tier_counts
    }

    /// Get win count (excluding losses, tier 0)
    public fun get_win_count(stats: &UserStats): u64 {
        let counts = &stats.tier_counts;
        *vector::borrow(counts, 1) + 
        *vector::borrow(counts, 2) + 
        *vector::borrow(counts, 3) + 
        *vector::borrow(counts, 4)
    }

    /// Get loss count
    public fun get_loss_count(stats: &UserStats): u64 {
        *vector::borrow(&stats.tier_counts, 0)
    }

    /// Get net profit/loss amount
    public fun get_net_profit(stats: &UserStats): (u64, bool) {
        (stats.net_profit, stats.is_profit)
    }

    /// Get global stats
    public fun get_total_players(registry: &UserStatsRegistry): u64 {
        registry.total_players
    }

    public fun get_total_games(registry: &UserStatsRegistry): u64 {
        registry.total_games
    }

    // --- Admin Functions ---
    /// Reset a user's stats (admin only)
    public fun reset_user_stats(_: &AdminCap, registry: &mut UserStatsRegistry, player: address) {
        if (table::contains(&registry.stats, player)) {
            let stats = table::borrow_mut(&mut registry.stats, player);
            stats.total_wagered = 0;
            stats.total_payout = 0;
            stats.games_played = 0;
            stats.tier_counts = vector[0, 0, 0, 0, 0];
            stats.net_profit = 0;
            stats.is_profit = true;
        }
    }

    // --- Test Helpers ---
    #[test_only]
    public fun create_registry_for_testing(ctx: &mut TxContext): UserStatsRegistry {
        create_registry(ctx)
    }

    #[test_only]
    public fun destroy_registry_for_testing(registry: UserStatsRegistry) {
        let UserStatsRegistry { id, stats, total_players: _, total_games: _ } = registry;
        object::delete(id);
        table::drop(stats);
    }

    #[test_only]
    public fun update_stats_for_testing(
        registry: &mut UserStatsRegistry,
        player: address,
        wager: u64,
        payout: u64,
        outcome_tier: u8,
    ) {
        update_stats(registry, player, wager, payout, outcome_tier)
    }
}
