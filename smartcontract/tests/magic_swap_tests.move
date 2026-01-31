#[test_only]
module magic_swap::magic_swap_tests {
    use magic_swap::game::{Self, Game};
    use sui::test_scenario;
    use sui::coin;
    use sui::sui::SUI;
    use sui::random;

    #[test]
    fun test_game_flow() {
        let admin = @0xA;
        let player = @0xB;

        let mut scenario = test_scenario::begin(admin);
        
        // 1. Init
        {
            let ctx = test_scenario::ctx(&mut scenario);
            game::init_for_testing(ctx);
        };

        // 2. Fund House
        test_scenario::next_tx(&mut scenario, admin);
        {
            let mut game_val = test_scenario::take_shared<Game>(&scenario);
            let game = &mut game_val;
            
            // Mint coin for house (1000 SUI)
            let ctx = test_scenario::ctx(&mut scenario);
            let coin = coin::mint_for_testing<SUI>(1000000000, ctx); 
            game::deposit(game, coin);

            test_scenario::return_shared(game_val);
        };

        // 3. Play
        test_scenario::next_tx(&mut scenario, player);
        {
            let mut game_val = test_scenario::take_shared<Game>(&scenario);
            let game = &mut game_val;
            let ctx = test_scenario::ctx(&mut scenario);
            
            let r = random::create_for_testing(ctx);
            let wager = coin::mint_for_testing<SUI>(1000000, ctx); // 1 SUI
            
            // Random state needs update or simple usage
            random::update_randomness_state_for_testing(
                &mut r,
                0,
                x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F", // Random bytes
                ctx
            );

            game::swap(game, &r, wager, ctx);

            random::destroy_for_testing(r);
            test_scenario::return_shared(game_val);
        };

        test_scenario::end(scenario);
    }
}
