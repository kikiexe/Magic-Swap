/// User statistics tracking for Magic Swap.
/// Tracks per-user gameplay history, tier outcomes, and profit/loss.
module magic_swap::user_stats {
    use sui::table::{Self, Table};
    use magic_swap::admin::AdminCap;

    // ============ Structs ============
    
    /// Individual user statistics.
    public struct UserStats has store, copy, drop {
        total_wagered: u64,
        total_payout: u64,
        games_played: u64,
        tier_counts: vector<u64>,  // [loss, small, medium, jackpot, miracle]
        net_profit: u64,
        is_profit: bool,
        last_play_timestamp: u64,  // Anti-spam: track last play epoch
    }

    /// Global registry storing all user stats.
    public struct UserStatsRegistry has key {
        id: UID,
        stats: Table<address, UserStats>,
        total_players: u64,
        total_games: u64,
    }

    // ============ Package Functions ============
    
    /// Create registry (called from main init).
    public(package) fun create_registry(ctx: &mut TxContext): UserStatsRegistry {
        UserStatsRegistry {
            id: object::new(ctx),
            stats: table::new(ctx),
            total_players: 0,
            total_games: 0,
        }
    }

    /// Share registry as shared object.
    public(package) fun share_registry(registry: UserStatsRegistry) {
        transfer::share_object(registry);
    }

    /// Update stats after a game.
    public(package) fun update_stats(
        registry: &mut UserStatsRegistry,
        player: address,
        wager: u64,
        payout: u64,
        outcome_tier: u8,
        current_epoch: u64,
    ) {
        // Auto-create user if new
        if (!table::contains(&registry.stats, player)) {
            let new_stats = UserStats {
                total_wagered: 0,
                total_payout: 0,
                games_played: 0,
                tier_counts: vector[0, 0, 0, 0, 0],
                net_profit: 0,
                is_profit: true,
                last_play_timestamp: 0,
            };
            table::add(&mut registry.stats, player, new_stats);
            registry.total_players = registry.total_players + 1;
        };

        let stats = table::borrow_mut(&mut registry.stats, player);
        
        // Anti-spam cooldown check (minimum 2 epochs between plays)
        // Skip check for first play (last_play_timestamp == 0)
        if (stats.last_play_timestamp > 0) {
            assert!(current_epoch >= stats.last_play_timestamp + 2, 999); // ERR_COOLDOWN
        };
        
        // Update basic stats
        stats.total_wagered = stats.total_wagered + wager;
        stats.total_payout = stats.total_payout + payout;
        stats.games_played = stats.games_played + 1;
        stats.last_play_timestamp = current_epoch;
        
        // Update tier count
        let tier_idx = (outcome_tier as u64);
        if (tier_idx < 5) {
            let current = *vector::borrow(&stats.tier_counts, tier_idx);
            *vector::borrow_mut(&mut stats.tier_counts, tier_idx) = current + 1;
        };
        
        // Calculate net profit/loss
        if (stats.total_payout >= stats.total_wagered) {
            stats.net_profit = stats.total_payout - stats.total_wagered;
            stats.is_profit = true;
        } else {
            stats.net_profit = stats.total_wagered - stats.total_payout;
            stats.is_profit = false;
        };
        
        registry.total_games = registry.total_games + 1;
    }

    // ============ View Functions ============
    
    public fun has_stats(registry: &UserStatsRegistry, player: address): bool {
        table::contains(&registry.stats, player)
    }

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
                last_play_timestamp: 0,
            }
        }
    }

    public fun get_total_wagered(stats: &UserStats): u64 { stats.total_wagered }
    public fun get_total_payout(stats: &UserStats): u64 { stats.total_payout }
    public fun get_games_played(stats: &UserStats): u64 { stats.games_played }
    public fun get_tier_counts(stats: &UserStats): vector<u64> { stats.tier_counts }
    
    public fun get_win_count(stats: &UserStats): u64 {
        let c = &stats.tier_counts;
        *vector::borrow(c, 1) + *vector::borrow(c, 2) + *vector::borrow(c, 3) + *vector::borrow(c, 4)
    }

    public fun get_loss_count(stats: &UserStats): u64 {
        *vector::borrow(&stats.tier_counts, 0)
    }

    public fun get_net_profit(stats: &UserStats): (u64, bool) {
        (stats.net_profit, stats.is_profit)
    }

    public fun get_total_players(registry: &UserStatsRegistry): u64 { registry.total_players }
    public fun get_total_games(registry: &UserStatsRegistry): u64 { registry.total_games }

    // ============ Admin Functions ============
    
    /// Reset a user's stats.
    public fun reset_user_stats(_: &AdminCap, registry: &mut UserStatsRegistry, player: address) {
        if (table::contains(&registry.stats, player)) {
            let stats = table::borrow_mut(&mut registry.stats, player);
            stats.total_wagered = 0;
            stats.total_payout = 0;
            stats.games_played = 0;
            stats.tier_counts = vector[0, 0, 0, 0, 0];
            stats.net_profit = 0;
            stats.is_profit = true;
            stats.last_play_timestamp = 0;
        }
    }

    // ============ Test Helpers ============
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
        current_epoch: u64,
    ) {
        update_stats(registry, player, wager, payout, outcome_tier, current_epoch)
    }
}
