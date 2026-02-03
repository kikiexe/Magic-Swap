module magic_swap::randomness {
    use sui::random::{Self, Random, RandomGenerator};

    #[allow(lint(public_random))]
    public fun get_generator(r: &Random, ctx: &mut TxContext): RandomGenerator {
        random::new_generator(r, ctx)
    }

    #[allow(lint(public_random))]
    public fun roll_dice(gen: &mut RandomGenerator): u16 {
        random::generate_u16_in_range(gen, 0, 999)
    }
}