/// Randomness utility for Magic Swap.
/// Wraps Sui's native random module for dice rolling.
module magic_swap::randomness {
    use sui::random::{Self, Random, RandomGenerator};

    /// Create a new random generator from Sui's Random object.
    #[allow(lint(public_random))]
    public fun get_generator(r: &Random, ctx: &mut TxContext): RandomGenerator {
        random::new_generator(r, ctx)
    }

    /// Roll a random number between 0-999 (inclusive).
    #[allow(lint(public_random))]
    public fun roll_dice(gen: &mut RandomGenerator): u16 {
        random::generate_u16_in_range(gen, 0, 999)
    }
}