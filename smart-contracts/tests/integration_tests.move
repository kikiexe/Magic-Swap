#[test_only]
module magic_swap::integration_tests {
    use sui::test_scenario::{Self, Scenario};
    use sui::coin;
    use sui::sui::SUI;

    use magic_swap::game::{Self, Game, AdminCap};
    use magic_swap::probability_engine;
    use magic_swap::treasury;
    use magic_swap::reward_pool;

    // --- Helpers ---
    fun user(): address { @0xA }
    fun admin(): address { @0xB }

    fun start_game(scenario: &mut Scenario) {
        let ctx = test_scenario::ctx(scenario);
        game::init_for_testing(ctx);
    }

    fun setup_game_objects(
        scenario: &mut Scenario
    ): (Game<SUI>, treasury::Treasury<SUI>, reward_pool::RewardPool<SUI>) {
        // 1) Use AdminCap (already minted by init_for_testing) to create Game
        test_scenario::next_tx(scenario, admin());
        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        game::create_game<SUI>(&admin_cap, test_scenario::ctx(scenario));
        test_scenario::return_to_sender(scenario, admin_cap);

        // 2) Create Treasury with 0 initial fund
        test_scenario::next_tx(scenario, admin());
        let zero = coin::mint_for_testing<SUI>(0, test_scenario::ctx(scenario));
        treasury::create_treasury<SUI>(zero, test_scenario::ctx(scenario));

        // 3) Create RewardPool with 0 initial fund
        test_scenario::next_tx(scenario, admin());
        let zero2 = coin::mint_for_testing<SUI>(0, test_scenario::ctx(scenario));
        reward_pool::create_pool<SUI>(zero2, test_scenario::ctx(scenario));

        // 4) Advance to make objects available
        test_scenario::next_tx(scenario, admin());
        
        // 5) Retrieve all objects and immediately return caps
        let game = test_scenario::take_shared<Game<SUI>>(scenario);
        let treasury_obj = test_scenario::take_shared<treasury::Treasury<SUI>>(scenario);
        let treasury_cap = test_scenario::take_from_sender<treasury::TreasuryCap>(scenario);
        test_scenario::return_to_sender(scenario, treasury_cap); // Put it back

        let reward_pool_obj = test_scenario::take_shared<reward_pool::RewardPool<SUI>>(scenario);
        let reward_cap = test_scenario::take_from_sender<reward_pool::RewardPoolCap>(scenario);
        test_scenario::return_to_sender(scenario, reward_cap); // Put it back

        (game, treasury_obj, reward_pool_obj)
    }

    // --- Tests ---

    #[test]
    fun test_loss_refund_logic() {
        let mut scenario = test_scenario::begin(admin());
        start_game(&mut scenario);

        let (mut game_obj, mut treas, mut rp) = setup_game_objects(&mut scenario);

        // Fund treasury with 1000
        test_scenario::next_tx(&mut scenario, admin());
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin_fund = coin::mint_for_testing<SUI>(1000, ctx);
            treasury::deposit(&mut treas, coin_fund);
        };

        test_scenario::next_tx(&mut scenario, user());
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let wager = coin::mint_for_testing<SUI>(100, ctx);

            let outcome = probability_engine::create_outcome_for_testing(0, 60);
            game::swap_for_testing<SUI>(&mut game_obj, &mut treas, &mut rp, outcome, wager, ctx);
        };

        // Assert Refund = 60
        test_scenario::next_tx(&mut scenario, user());
        {
            let coin_out = test_scenario::take_from_sender<coin::Coin<SUI>>(&scenario);
            assert!(coin::value(&coin_out) == 60, 0);
            test_scenario::return_to_sender(&scenario, coin_out);
        };

        // Consume objects so they don't need 'drop'
        test_scenario::return_shared(game_obj);
        test_scenario::return_shared(treas);
        test_scenario::return_shared(rp);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_small_win_logic() {
        let mut scenario = test_scenario::begin(admin());
        start_game(&mut scenario);

        let (mut game_obj, mut treas, mut rp) = setup_game_objects(&mut scenario);

        // Fund 1000
        test_scenario::next_tx(&mut scenario, admin());
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin_fund = coin::mint_for_testing<SUI>(1000, ctx);
            treasury::deposit(&mut treas, coin_fund);
        };

        test_scenario::next_tx(&mut scenario, user());
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let wager = coin::mint_for_testing<SUI>(100, ctx);

            let outcome = probability_engine::create_outcome_for_testing(1, 105);
            game::swap_for_testing<SUI>(&mut game_obj, &mut treas, &mut rp, outcome, wager, ctx);
        };

        // Assert 105
        test_scenario::next_tx(&mut scenario, user());
        {
            let coin_out = test_scenario::take_from_sender<coin::Coin<SUI>>(&scenario);
            assert!(coin::value(&coin_out) == 105, 1);
            test_scenario::return_to_sender(&scenario, coin_out);
        };

        test_scenario::return_shared(game_obj);
        test_scenario::return_shared(treas);
        test_scenario::return_shared(rp);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_safety_valve_trigger() {
        let mut scenario = test_scenario::begin(admin());
        start_game(&mut scenario);

        let (mut game_obj, mut treas, mut rp) = setup_game_objects(&mut scenario);

        // Treasury = 1000. Cap = 100 (10%).
        test_scenario::next_tx(&mut scenario, admin());
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let coin_fund = coin::mint_for_testing<SUI>(1000, ctx);
            treasury::deposit(&mut treas, coin_fund);
        };

        test_scenario::next_tx(&mut scenario, user());
        {
            let ctx = test_scenario::ctx(&mut scenario);
            let wager = coin::mint_for_testing<SUI>(100, ctx);

            // Miracle Win (50x): should be capped to 200 total payout
            let outcome = probability_engine::create_outcome_for_testing(4, 5000);
            game::swap_for_testing<SUI>(&mut game_obj, &mut treas, &mut rp, outcome, wager, ctx);
        };

        // Assert result is CAPPED at 200
        test_scenario::next_tx(&mut scenario, user());
        {
            let coin_out = test_scenario::take_from_sender<coin::Coin<SUI>>(&scenario);
            assert!(coin::value(&coin_out) == 200, 2);
            test_scenario::return_to_sender(&scenario, coin_out);
        };

        test_scenario::return_shared(game_obj);
        test_scenario::return_shared(treas);
        test_scenario::return_shared(rp);
        test_scenario::end(scenario);
    }
}
