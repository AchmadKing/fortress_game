extends SceneTree

## TestPhase4DHeroTrainingFatigueMorale
## Test suite otomatis untuk memvalidasi implementasi Phase 4D:
## Hero Training, Fatigue, & Morale.
## Memvalidasi batasan sesi latihan per gelombang (anti-exploit), perolehan EXP kanonikal (40 EXP),
## akumulasi kelelahan (+15 fatigue), batas kelelahan 100, pemulihan istirahat (-25 fatigue, +5 morale),
## rentang moral 0–150, formula multiplier kelelahan dan moral, serta integrasi status efektif pahlawan.

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 4D HERO TRAINING, FATIGUE & MORALE TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# Training Tests (1-20)
		{"name": "test_valid_training_succeeds", "fn": Callable(self, "_test_valid_training_succeeds")},
		{"name": "test_training_grants_exactly_40_exp", "fn": Callable(self, "_test_training_grants_exactly_40_exp")},
		{"name": "test_training_adds_exactly_15_fatigue", "fn": Callable(self, "_test_training_adds_exactly_15_fatigue")},
		{"name": "test_training_can_level_up_hero", "fn": Callable(self, "_test_training_can_level_up_hero")},
		{"name": "test_training_preserves_exp_carry_over", "fn": Callable(self, "_test_training_preserves_exp_carry_over")},
		{"name": "test_training_respects_star_level_cap", "fn": Callable(self, "_test_training_respects_star_level_cap")},
		{"name": "test_second_training_in_same_wave_fails", "fn": Callable(self, "_test_second_training_in_same_wave_fails")},
		{"name": "test_second_training_gives_no_exp", "fn": Callable(self, "_test_second_training_gives_no_exp")},
		{"name": "test_second_training_gives_no_fatigue", "fn": Callable(self, "_test_second_training_gives_no_fatigue")},
		{"name": "test_training_works_again_on_next_wave", "fn": Callable(self, "_test_training_works_again_on_next_wave")},
		{"name": "test_dead_hero_cannot_train", "fn": Callable(self, "_test_dead_hero_cannot_train")},
		{"name": "test_permadeath_hero_cannot_train", "fn": Callable(self, "_test_permadeath_hero_cannot_train")},
		{"name": "test_battle_hero_cannot_train", "fn": Callable(self, "_test_battle_hero_cannot_train")},
		{"name": "test_invalid_hero_cannot_train", "fn": Callable(self, "_test_invalid_hero_cannot_train")},
		{"name": "test_training_with_fatigue_85_succeeds", "fn": Callable(self, "_test_training_with_fatigue_85_succeeds")},
		{"name": "test_training_with_fatigue_86_fails", "fn": Callable(self, "_test_training_with_fatigue_86_fails")},
		{"name": "test_training_with_fatigue_100_fails", "fn": Callable(self, "_test_training_with_fatigue_100_fails")},
		{"name": "test_failed_training_leaves_state_unchanged", "fn": Callable(self, "_test_failed_training_leaves_state_unchanged")},
		{"name": "test_training_does_not_consume_gold", "fn": Callable(self, "_test_training_does_not_consume_gold")},
		{"name": "test_training_does_not_alter_equipment", "fn": Callable(self, "_test_training_does_not_alter_equipment")},

		# Fatigue Tests (21-33)
		{"name": "test_fatigue_starts_at_0", "fn": Callable(self, "_test_fatigue_starts_at_0")},
		{"name": "test_plus_15_training_fatigue", "fn": Callable(self, "_test_plus_15_training_fatigue")},
		{"name": "test_fatigue_85_to_100", "fn": Callable(self, "_test_fatigue_85_to_100")},
		{"name": "test_fatigue_86_training_rejected", "fn": Callable(self, "_test_fatigue_86_training_rejected")},
		{"name": "test_fatigue_100_training_rejected", "fn": Callable(self, "_test_fatigue_100_training_rejected")},
		{"name": "test_rest_reduces_fatigue_by_25", "fn": Callable(self, "_test_rest_reduces_fatigue_by_25")},
		{"name": "test_rest_does_not_reduce_below_0", "fn": Callable(self, "_test_rest_does_not_reduce_below_0")},
		{"name": "test_rest_at_0_remains_0", "fn": Callable(self, "_test_rest_at_0_remains_0")},
		{"name": "test_rest_blocked_during_battle", "fn": Callable(self, "_test_rest_blocked_during_battle")},
		{"name": "test_rest_does_not_change_exp", "fn": Callable(self, "_test_rest_does_not_change_exp")},
		{"name": "test_rest_does_not_change_level", "fn": Callable(self, "_test_rest_does_not_change_level")},
		{"name": "test_rest_does_not_change_stars", "fn": Callable(self, "_test_rest_does_not_change_stars")},
		{"name": "test_rest_does_not_change_equipment", "fn": Callable(self, "_test_rest_does_not_change_equipment")},

		# Morale Tests (34-42)
		{"name": "test_morale_starts_at_100", "fn": Callable(self, "_test_morale_starts_at_100")},
		{"name": "test_positive_morale_adjustment_works", "fn": Callable(self, "_test_positive_morale_adjustment_works")},
		{"name": "test_negative_morale_adjustment_works", "fn": Callable(self, "_test_negative_morale_adjustment_works")},
		{"name": "test_morale_lower_clamp_zero", "fn": Callable(self, "_test_morale_lower_clamp_zero")},
		{"name": "test_morale_upper_clamp_150", "fn": Callable(self, "_test_morale_upper_clamp_150")},
		{"name": "test_rest_adds_exactly_5_morale", "fn": Callable(self, "_test_rest_adds_exactly_5_morale")},
		{"name": "test_rest_fatigue_and_morale_changes_are_atomic", "fn": Callable(self, "_test_rest_fatigue_and_morale_changes_are_atomic")},
		{"name": "test_morale_remains_independent_from_fatigue", "fn": Callable(self, "_test_morale_remains_independent_from_fatigue")},
		{"name": "test_morale_does_not_change_exp", "fn": Callable(self, "_test_morale_does_not_change_exp")},

		# Effective Stat Tests (43-54)
		{"name": "test_fatigue_0_gives_multiplier_1_00", "fn": Callable(self, "_test_fatigue_0_gives_multiplier_1_00")},
		{"name": "test_fatigue_50_gives_multiplier_0_75", "fn": Callable(self, "_test_fatigue_50_gives_multiplier_0_75")},
		{"name": "test_fatigue_100_gives_multiplier_0_50", "fn": Callable(self, "_test_fatigue_100_gives_multiplier_0_50")},
		{"name": "test_morale_0_gives_multiplier_0_75", "fn": Callable(self, "_test_morale_0_gives_multiplier_0_75")},
		{"name": "test_morale_50_gives_multiplier_1_00", "fn": Callable(self, "_test_morale_50_gives_multiplier_1_00")},
		{"name": "test_morale_100_gives_multiplier_1_25", "fn": Callable(self, "_test_morale_100_gives_multiplier_1_25")},
		{"name": "test_morale_150_gives_multiplier_1_50", "fn": Callable(self, "_test_morale_150_gives_multiplier_1_50")},
		{"name": "test_combined_fatigue_morale_modifiers_applied", "fn": Callable(self, "_test_combined_fatigue_morale_modifiers_applied")},
		{"name": "test_level_scaling_remains_intact", "fn": Callable(self, "_test_level_scaling_remains_intact")},
		{"name": "test_star_scaling_remains_intact", "fn": Callable(self, "_test_star_scaling_remains_intact")},
		{"name": "test_effective_atk_remains_deterministic", "fn": Callable(self, "_test_effective_atk_remains_deterministic")},
		{"name": "test_effective_def_remains_deterministic", "fn": Callable(self, "_test_effective_def_remains_deterministic")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 4D TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("================================================================")

	if failed == 0:
		quit(0)
	else:
		quit(1)


func _run_test(test_name: String, test_fn: Callable) -> bool:
	print("[TEST] Running %s..." % test_name)
	var ok: bool = bool(test_fn.call())
	if ok:
		print("[PASS] %s" % test_name)
	else:
		printerr("[FAIL] %s" % test_name)
	return ok


# ==============================================================================
# TRAINING TESTS (1-20)
# ==============================================================================

func _test_valid_training_succeeds() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_1")
	var ok: bool = coord.train_hero("hero_alder")
	var alder: HeroModel = coord.get_hero("hero_alder")
	return ok and alder != null and alder.current_exp == 40 and alder.fatigue == 15


func _test_training_grants_exactly_40_exp() -> bool:
	var hero := HeroModel.new("h_exp", "Tester", 1, 3)
	hero.train(40, 15)
	return hero.current_exp == 40


func _test_training_adds_exactly_15_fatigue() -> bool:
	var hero := HeroModel.new("h_fat", "Tester", 1, 3)
	hero.train(40, 15)
	return hero.fatigue == 15


func _test_training_can_level_up_hero() -> bool:
	var hero := HeroModel.new("h_lvl", "Tester", 1, 3)
	# Lv1 req_exp = 120. Set current_exp to 100.
	hero.current_exp = 100
	var levels: int = hero.train(40, 15)
	return levels == 1 and hero.level == 2 and hero.current_exp == 20


func _test_training_preserves_exp_carry_over() -> bool:
	var hero := HeroModel.new("h_carry", "Tester", 1, 3)
	hero.current_exp = 110 # 110 + 40 = 150 -> 150 - 120 = 30 carryover
	hero.train(40, 15)
	return hero.level == 2 and hero.current_exp == 30


func _test_training_respects_star_level_cap() -> bool:
	var hero := HeroModel.new("h_cap", "Tester", 1, 3)
	hero.level = 10 # 1★ cap is 10
	var req_at_10: int = hero.get_required_exp(10)
	hero.current_exp = req_at_10 - 20
	hero.train(40, 15)
	return hero.level == 10 and hero.current_exp == req_at_10


func _test_second_training_in_same_wave_fails() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_7")
	var first_ok: bool = coord.train_hero("hero_alder")
	var second_ok: bool = coord.train_hero("hero_alder")
	return first_ok and not second_ok


func _test_second_training_gives_no_exp() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_8")
	coord.train_hero("hero_alder")
	var exp_after_first: int = coord.get_hero("hero_alder").current_exp # 40
	coord.train_hero("hero_alder")
	return coord.get_hero("hero_alder").current_exp == exp_after_first


func _test_second_training_gives_no_fatigue() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_9")
	coord.train_hero("hero_alder")
	var fat_after_first: int = coord.get_hero("hero_alder").fatigue # 15
	coord.train_hero("hero_alder")
	return coord.get_hero("hero_alder").fatigue == fat_after_first


func _test_training_works_again_on_next_wave() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_10")
	var wave1_ok: bool = coord.train_hero("hero_alder")
	# Majukan gelombang (simulasi wave transition)
	coord._current_wave_num += 1
	var wave2_ok: bool = coord.train_hero("hero_alder")
	var alder: HeroModel = coord.get_hero("hero_alder")
	return wave1_ok and wave2_ok and alder.current_exp == 80 and alder.fatigue == 30


func _test_dead_hero_cannot_train() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_11")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.is_alive = false
	var ok: bool = coord.train_hero("hero_alder")
	return not ok and alder.current_exp == 0 and alder.fatigue == 0


func _test_permadeath_hero_cannot_train() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_12")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.mark_dead()
	var ok: bool = coord.train_hero("hero_alder")
	return not ok and alder.current_exp == 0


func _test_battle_hero_cannot_train() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_13")
	coord.inspect_wave()
	coord.start_battle()
	var ok: bool = coord.train_hero("hero_alder")
	return not ok


func _test_invalid_hero_cannot_train() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_14")
	var ok: bool = coord.train_hero("non_existent_hero_id")
	return not ok


func _test_training_with_fatigue_85_succeeds() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_15")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.fatigue = 85
	var ok: bool = coord.train_hero("hero_alder")
	return ok and alder.fatigue == 100 and alder.current_exp == 40


func _test_training_with_fatigue_86_fails() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_16")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.fatigue = 86
	var ok: bool = coord.train_hero("hero_alder")
	return not ok and alder.fatigue == 86 and alder.current_exp == 0


func _test_training_with_fatigue_100_fails() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_17")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.fatigue = 100
	var ok: bool = coord.train_hero("hero_alder")
	return not ok and alder.fatigue == 100 and alder.current_exp == 0


func _test_failed_training_leaves_state_unchanged() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_18")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.fatigue = 90
	alder.current_exp = 25
	var ok: bool = coord.train_hero("hero_alder")
	return not ok and alder.fatigue == 90 and alder.current_exp == 25 and not coord.has_hero_trained_this_wave("hero_alder")


func _test_training_does_not_consume_gold() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_19")
	coord.set_treasury_gold(1000)
	var ok: bool = coord.train_hero("hero_alder")
	return ok and coord.get_treasury_gold() == 1000


func _test_training_does_not_alter_equipment() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_train_20")
	var sword := EquipmentModel.new("SWORD", 1, 100, 1)
	coord.get_hero("hero_alder").equip("PRIMARY", sword)
	var ok: bool = coord.train_hero("hero_alder")
	return ok and coord.get_hero("hero_alder").get_equipment("PRIMARY") == sword


# ==============================================================================
# FATIGUE TESTS (21-33)
# ==============================================================================

func _test_fatigue_starts_at_0() -> bool:
	var hero := HeroModel.new("h_f0", "Tester", 1, 3)
	return hero.fatigue == 0


func _test_plus_15_training_fatigue() -> bool:
	var hero := HeroModel.new("h_f15", "Tester", 1, 3)
	hero.train(40, 15)
	return hero.fatigue == 15


func _test_fatigue_85_to_100() -> bool:
	var hero := HeroModel.new("h_f85", "Tester", 1, 3)
	hero.fatigue = 85
	var ok: bool = hero.can_train(15)
	hero.train(40, 15)
	return ok and hero.fatigue == 100


func _test_fatigue_86_training_rejected() -> bool:
	var hero := HeroModel.new("h_f86", "Tester", 1, 3)
	hero.fatigue = 86
	var ok: bool = hero.can_train(15)
	var exp_gained: int = hero.train(40, 15)
	return not ok and exp_gained == 0 and hero.fatigue == 86


func _test_fatigue_100_training_rejected() -> bool:
	var hero := HeroModel.new("h_f100", "Tester", 1, 3)
	hero.fatigue = 100
	var ok: bool = hero.can_train(15)
	var exp_gained: int = hero.train(40, 15)
	return not ok and exp_gained == 0 and hero.fatigue == 100


func _test_rest_reduces_fatigue_by_25() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rest_26")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.fatigue = 60
	var ok: bool = coord.rest_hero("hero_alder")
	return ok and alder.fatigue == 35


func _test_rest_does_not_reduce_below_0() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rest_27")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.fatigue = 20
	var ok: bool = coord.rest_hero("hero_alder")
	return ok and alder.fatigue == 0


func _test_rest_at_0_remains_0() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rest_28")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.fatigue = 0
	var ok: bool = coord.rest_hero("hero_alder")
	return ok and alder.fatigue == 0


func _test_rest_blocked_during_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rest_29")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.fatigue = 50
	coord.inspect_wave()
	coord.start_battle()
	var ok: bool = coord.rest_hero("hero_alder")
	return not ok and alder.fatigue == 50


func _test_rest_does_not_change_exp() -> bool:
	var hero := HeroModel.new("h_rest_exp", "Tester", 1, 3)
	hero.current_exp = 50
	hero.fatigue = 50
	hero.rest(25)
	return hero.current_exp == 50


func _test_rest_does_not_change_level() -> bool:
	var hero := HeroModel.new("h_rest_lvl", "Tester", 1, 3)
	hero.level = 2
	hero.fatigue = 50
	hero.rest(25)
	return hero.level == 2


func _test_rest_does_not_change_stars() -> bool:
	var hero := HeroModel.new("h_rest_star", "Tester", 2, 4)
	hero.fatigue = 50
	hero.rest(25)
	return hero.current_star == 2 and hero.potential_star == 4


func _test_rest_does_not_change_equipment() -> bool:
	var hero := HeroModel.new("h_rest_eq", "Tester", 1, 3)
	var sword := EquipmentModel.new("SWORD", 1, 100, 1)
	hero.equip("PRIMARY", sword)
	hero.fatigue = 50
	hero.rest(25)
	return hero.get_equipment("PRIMARY") == sword


# ==============================================================================
# MORALE TESTS (34-42)
# ==============================================================================

func _test_morale_starts_at_100() -> bool:
	var hero := HeroModel.new("h_m100", "Tester", 1, 3)
	return hero.morale == 100


func _test_positive_morale_adjustment_works() -> bool:
	var hero := HeroModel.new("h_m_pos", "Tester", 1, 3)
	hero.adjust_morale(20)
	return hero.morale == 120


func _test_negative_morale_adjustment_works() -> bool:
	var hero := HeroModel.new("h_m_neg", "Tester", 1, 3)
	hero.adjust_morale(-30)
	return hero.morale == 70


func _test_morale_lower_clamp_zero() -> bool:
	var hero := HeroModel.new("h_m_clamp0", "Tester", 1, 3)
	hero.adjust_morale(-200)
	return hero.morale == 0


func _test_morale_upper_clamp_150() -> bool:
	var hero := HeroModel.new("h_m_clamp150", "Tester", 1, 3)
	hero.adjust_morale(200)
	return hero.morale == 150


func _test_rest_adds_exactly_5_morale() -> bool:
	var hero := HeroModel.new("h_rest_mor", "Tester", 1, 3)
	hero.morale = 100
	hero.fatigue = 50
	hero.rest(25)
	return hero.morale == 105


func _test_rest_fatigue_and_morale_changes_are_atomic() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rest_atom")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.fatigue = 50
	alder.morale = 100
	var ok: bool = coord.rest_hero("hero_alder")
	return ok and alder.fatigue == 25 and alder.morale == 105


func _test_morale_remains_independent_from_fatigue() -> bool:
	var hero := HeroModel.new("h_indep", "Tester", 1, 3)
	hero.adjust_morale(30)
	var f_ok: bool = (hero.fatigue == 0 and hero.morale == 130)
	hero.adjust_fatigue(40)
	var m_ok: bool = (hero.fatigue == 40 and hero.morale == 130)
	return f_ok and m_ok


func _test_morale_does_not_change_exp() -> bool:
	var hero := HeroModel.new("h_mor_exp", "Tester", 1, 3)
	hero.current_exp = 75
	hero.adjust_morale(25)
	return hero.current_exp == 75


# ==============================================================================
# EFFECTIVE STAT TESTS (43-54)
# ==============================================================================

func _test_fatigue_0_gives_multiplier_1_00() -> bool:
	var hero := HeroModel.new("h_stat_f0", "Tester", 1, 3)
	hero.fatigue = 0
	return is_equal_approx(hero.get_fatigue_multiplier(), 1.00)


func _test_fatigue_50_gives_multiplier_0_75() -> bool:
	var hero := HeroModel.new("h_stat_f50", "Tester", 1, 3)
	hero.fatigue = 50
	return is_equal_approx(hero.get_fatigue_multiplier(), 0.75)


func _test_fatigue_100_gives_multiplier_0_50() -> bool:
	var hero := HeroModel.new("h_stat_f100", "Tester", 1, 3)
	hero.fatigue = 100
	return is_equal_approx(hero.get_fatigue_multiplier(), 0.50)


func _test_morale_0_gives_multiplier_0_75() -> bool:
	var hero := HeroModel.new("h_stat_m0", "Tester", 1, 3)
	hero.morale = 0
	return is_equal_approx(hero.get_morale_multiplier(), 0.75)


func _test_morale_50_gives_multiplier_1_00() -> bool:
	var hero := HeroModel.new("h_stat_m50", "Tester", 1, 3)
	hero.morale = 50
	return is_equal_approx(hero.get_morale_multiplier(), 1.00)


func _test_morale_100_gives_multiplier_1_25() -> bool:
	var hero := HeroModel.new("h_stat_m100", "Tester", 1, 3)
	hero.morale = 100
	return is_equal_approx(hero.get_morale_multiplier(), 1.25)


func _test_morale_150_gives_multiplier_1_50() -> bool:
	var hero := HeroModel.new("h_stat_m150", "Tester", 1, 3)
	hero.morale = 150
	return is_equal_approx(hero.get_morale_multiplier(), 1.50)


func _test_combined_fatigue_morale_modifiers_applied() -> bool:
	var hero := HeroModel.new("h_stat_comb", "Tester", 1, 3)
	hero.fatigue = 50 # 0.75
	hero.morale = 50  # 1.00
	# Base ATK = 35. Level 1 (1.0), Star 1 (1.0).
	# ATK = floor(35 * 1.0 * 1.0 * 0.75 * 1.0) = floor(26.25) = 26
	return hero.get_effective_atk() == 26


func _test_level_scaling_remains_intact() -> bool:
	var hero := HeroModel.new("h_stat_lvl", "Tester", 1, 3)
	hero.level = 2   # Level multiplier: 1.12
	hero.fatigue = 0 # 1.00
	hero.morale = 50 # 1.00
	# ATK = floor(35 * 1.12 * 1.0 * 1.0 * 1.0) = floor(39.2) = 39
	return hero.get_effective_atk() == 39


func _test_star_scaling_remains_intact() -> bool:
	var hero := HeroModel.new("h_stat_star", "Tester", 2, 4)
	hero.level = 1   # Level multiplier: 1.00
	hero.fatigue = 0 # 1.00
	hero.morale = 50 # 1.00
	# 2★ multiplier: 1.20
	# ATK = floor(35 * 1.0 * 1.20 * 1.0 * 1.0) = 42
	# DEF = floor(20 * 1.0 * 1.20 * 1.0 * 1.0) = 24
	return hero.get_effective_atk() == 42 and hero.get_effective_def() == 24


func _test_effective_atk_remains_deterministic() -> bool:
	var hero := HeroModel.new("h_stat_det_atk", "Tester", 2, 4)
	hero.fatigue = 30
	hero.morale = 120
	var first_val: int = hero.get_effective_atk()
	for i in range(10):
		if hero.get_effective_atk() != first_val:
			return false
	return true


func _test_effective_def_remains_deterministic() -> bool:
	var hero := HeroModel.new("h_stat_det_def", "Tester", 2, 4)
	hero.fatigue = 30
	hero.morale = 120
	var first_val: int = hero.get_effective_def()
	for i in range(10):
		if hero.get_effective_def() != first_val:
			return false
	return true
