#[test_only]
module magic_swap::core_tests {
    use sui::test_scenario::{Self};
    use sui::sui::SUI;
    use magic_swap::game::{Self, GameHouse};
    use magic_swap::admin::{AdminCap};

    fun admin(): address { @0xB }

    #[test]
    fun test_game_initialization() {
        let mut scenario = test_scenario::begin(admin());
        {
            game::init_for_testing(test_scenario::ctx(&mut scenario));
        };

        test_scenario::next_tx(&mut scenario, admin());
        {
            let admin_cap = test_scenario::take_from_sender<AdminCap>(&scenario);
            game::create_game<SUI>(&admin_cap, test_scenario::ctx(&mut scenario));
            test_scenario::return_to_sender(&scenario, admin_cap);
        };

        test_scenario::next_tx(&mut scenario, admin());
        {
            let game_house = test_scenario::take_shared<GameHouse<SUI>>(&scenario);
            // Verifikasi objek berhasil di-share
            test_scenario::return_shared(game_house);
        };
        test_scenario::end(scenario);
    }
}