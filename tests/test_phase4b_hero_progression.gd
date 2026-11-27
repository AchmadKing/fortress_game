extends SceneTree

## TestPhase4BHeroProgression
## Test suite otomatis untuk memvalidasi implementasi Phase 4B:
## Hero Progression & EXP Implementation.
## Meliputi formula kebutuhan EXP, progresi level, batas bintang (level cap),
## carry-over EXP, integrasi stat, kelayakan & biaya ascension,
## transaksi atomik kas benteng (Gold), dan distribusi EXP tempur deterministik.

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const CombatEngine = preload("res://scripts/simulation/combat_engine.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 4B HERO PROGRESSION & EXP TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# EXP Formula (1-4)
		{"name": "test_req_exp_lv1_is_120", "fn": Callable(self, "_test_req_exp_lv1_is_120")},
		{"name": "test_req_exp_lv2_is_351", "fn": Callable(self, "_test_req_exp_lv2_is_351")},
		{"name": "test_req_exp_lv3_is_658", "fn": Callable(self, "_test_req_exp_lv3_is_658")},
		{"name": "test_req_exp_lv4_is_1028", "fn": Callable(self, "_test_req_exp_lv4_is_1028")},

		# Level Progression (5-14)
		{"name": "test_120_exp_causes_lv1_to_lv2", "fn": Callable(self, "_test_120_exp_causes_lv1_to_lv2")},
		{"name": "test_exp_carry_over_works", "fn": Callable(self, "_test_exp_carry_over_works")},
		{"name": "test_multiple_level_ups_work", "fn": Callable(self, "_test_multiple_level_ups_work")},
		{"name": "test_negative_exp_is_ignored", "fn": Callable(self, "_test_negative_exp_is_ignored")},
		{"name": "test_zero_exp_changes_nothing", "fn": Callable(self, "_test_zero_exp_changes_nothing")},
		{"name": "test_level_cap_at_1_star_is_lv10", "fn": Callable(self, "_test_level_cap_at_1_star_is_lv10")},
		{"name": "test_level_cap_at_2_star_is_lv20", "fn": Callable(self, "_test_level_cap_at_2_star_is_lv20")},
		{"name": "test_level_cap_at_5_star_is_lv50", "fn": Callable(self, "_test_level_cap_at_5_star_is_lv50")},
		{"name": "test_level_cannot_exceed_current_star_cap", "fn": Callable(self, "_test_level_cannot_exceed_current_star_cap")},
		{"name": "test_additional_exp_at_cap_cannot_increase_level", "fn": Callable(self, "_test_additional_exp_at_cap_cannot_increase_level")},

		# Stat Integration (15-18)
		{"name": "test_level_2_atk_scaling_remains_correct", "fn": Callable(self, "_test_level_2_atk_scaling_remains_correct")},
		{"name": "test_level_2_def_scaling_remains_correct", "fn": Callable(self, "_test_level_2_def_scaling_remains_correct")},
		{"name": "test_star_multiplier_remains_correct", "fn": Callable(self, "_test_star_multiplier_remains_correct")},
		{"name": "test_existing_equipment_multiplier_remains_correct", "fn": Callable(self, "_test_existing_equipment_multiplier_remains_correct")},

		# Ascension (19-33)
		{"name": "test_1_star_to_2_star_eligibility_at_lv10", "fn": Callable(self, "_test_1_star_to_2_star_eligibility_at_lv10")},
		{"name": "test_ascension_blocked_below_cap", "fn": Callable(self, "_test_ascension_blocked_below_cap")},
		{"name": "test_ascension_blocked_at_potential_star", "fn": Callable(self, "_test_ascension_blocked_at_potential_star")},
		{"name": "test_ascension_blocked_for_dead_hero", "fn": Callable(self, "_test_ascension_blocked_for_dead_hero")},
		{"name": "test_ascension_blocked_at_5_star", "fn": Callable(self, "_test_ascension_blocked_at_5_star")},
		{"name": "test_cost_1_star_to_2_star_is_150", "fn": Callable(self, "_test_cost_1_star_to_2_star_is_150")},
		{"name": "test_cost_2_star_to_3_star_is_300", "fn": Callable(self, "_test_cost_2_star_to_3_star_is_300")},
		{"name": "test_cost_3_star_to_4_star_is_450", "fn": Callable(self, "_test_cost_3_star_to_4_star_is_450")},
		{"name": "test_cost_4_star_to_5_star_is_600", "fn": Callable(self, "_test_cost_4_star_to_5_star_is_600")},
		{"name": "test_successful_ascension_increments_exactly_one_star", "fn": Callable(self, "_test_successful_ascension_increments_exactly_one_star")},
		{"name": "test_potential_star_unchanged", "fn": Callable(self, "_test_potential_star_unchanged")},
		{"name": "test_level_unchanged_after_ascension", "fn": Callable(self, "_test_level_unchanged_after_ascension")},
		{"name": "test_exp_unchanged_after_ascension", "fn": Callable(self, "_test_exp_unchanged_after_ascension")},
		{"name": "test_equipment_unchanged_after_ascension", "fn": Callable(self, "_test_equipment_unchanged_after_ascension")},
		{"name": "test_fatigue_morale_unchanged_after_ascension", "fn": Callable(self, "_test_fatigue_morale_unchanged_after_ascension")},

		# Atomic Gold Transaction (34-38)
		{"name": "test_insufficient_gold_rejects_ascension", "fn": Callable(self, "_test_insufficient_gold_rejects_ascension")},
		{"name": "test_insufficient_gold_does_not_mutate_star", "fn": Callable(self, "_test_insufficient_gold_does_not_mutate_star")},
		{"name": "test_insufficient_gold_does_not_mutate_treasury", "fn": Callable(self, "_test_insufficient_gold_does_not_mutate_treasury")},
		{"name": "test_successful_ascension_deducts_exact_cost", "fn": Callable(self, "_test_successful_ascension_deducts_exact_cost")},
		{"name": "test_successful_ascension_changes_star_exactly_once", "fn": Callable(self, "_test_successful_ascension_changes_star_exactly_once")},

		# Battle EXP (39-45)
		{"name": "test_wave_1_exp_calculation", "fn": Callable(self, "_test_wave_1_exp_calculation")},
		{"name": "test_wave_15_exp_calculation", "fn": Callable(self, "_test_wave_15_exp_calculation")},
		{"name": "test_wave_30_exp_calculation", "fn": Callable(self, "_test_wave_30_exp_calculation")},
		{"name": "test_surviving_hero_receives_exp", "fn": Callable(self, "_test_surviving_hero_receives_exp")},
		{"name": "test_dead_hero_receives_no_exp", "fn": Callable(self, "_test_dead_hero_receives_no_exp")},
		{"name": "test_exp_distribution_is_deterministic", "fn": Callable(self, "_test_exp_distribution_is_deterministic")},
		{"name": "test_distribution_never_exceeds_awarded_exp", "fn": Callable(self, "_test_distribution_never_exceeds_awarded_exp")},

		# Supplementary Integration Tests (46-47)
		{"name": "test_ascend_hero_battle_lock_rejected", "fn": Callable(self, "_test_ascend_hero_battle_lock_rejected")},
		{"name": "test_snapshot_telemetry_contains_phase4b_fields", "fn": Callable(self, "_test_snapshot_telemetry_contains_phase4b_fields")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 4B TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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
# EXP FORMULA (1-4)
# ==============================================================================

func _test_req_exp_lv1_is_120() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	return hero.get_required_exp(1) == 120


func _test_req_exp_lv2_is_351() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	return hero.get_required_exp(2) == 351


func _test_req_exp_lv3_is_658() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	return hero.get_required_exp(3) == 658


func _test_req_exp_lv4_is_1028() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	return hero.get_required_exp(4) == 1028


# ==============================================================================
# LEVEL PROGRESSION (5-14)
# ==============================================================================

func _test_120_exp_causes_lv1_to_lv2() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	var gained: int = hero.add_exp(120)
	return gained == 1 and hero.level == 2 and hero.current_exp == 0


func _test_exp_carry_over_works() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	var gained: int = hero.add_exp(150)
	return gained == 1 and hero.level == 2 and hero.current_exp == 30


func _test_multiple_level_ups_work() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	# Lv1 req = 120, Lv2 req = 351. Total to Lv3 = 471. 480 EXP gives Lv3 with 9 remainder.
	var gained: int = hero.add_exp(480)
	return gained == 2 and hero.level == 3 and hero.current_exp == 9


func _test_negative_exp_is_ignored() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.add_exp(50)
	var gained: int = hero.add_exp(-100)
	return gained == 0 and hero.level == 1 and hero.current_exp == 50


func _test_zero_exp_changes_nothing() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	var gained: int = hero.add_exp(0)
	return gained == 0 and hero.level == 1 and hero.current_exp == 0


func _test_level_cap_at_1_star_is_lv10() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	return hero.get_level_cap() == 10


func _test_level_cap_at_2_star_is_lv20() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 2, 4)
	return hero.get_level_cap() == 20


func _test_level_cap_at_5_star_is_lv50() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 5, 5)
	return hero.get_level_cap() == 50


func _test_level_cannot_exceed_current_star_cap() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.add_exp(2000000)
	return hero.level == 10


func _test_additional_exp_at_cap_cannot_increase_level() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.add_exp(2000000)
	if hero.level != 10:
		return false
	var gained: int = hero.add_exp(1000)
	return gained == 0 and hero.level == 10


# ==============================================================================
# STAT INTEGRATION (15-18)
# ==============================================================================

func _test_level_2_atk_scaling_remains_correct() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	# base_atk = 35. Lv1 ATK = 35.
	# Lv2 ATK = floor(35 * (1 + (2-1)*0.12) * 1.0) = floor(39.2) = 39
	hero.level = 2
	return hero.get_effective_atk() == 39


func _test_level_2_def_scaling_remains_correct() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	# base_def = 20. Lv1 DEF = 20.
	# Lv2 DEF = floor(20 * (1 + (2-1)*0.10) * 1.0) = floor(22.0) = 22
	hero.level = 2
	return hero.get_effective_def() == 22


func _test_star_multiplier_remains_correct() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 2, 3)
	# 2★ multiplier = 1.0 + (2-1)*0.20 = 1.20
	# Lv1 ATK = floor(35 * 1.0 * 1.20) = 42
	# Lv1 DEF = floor(20 * 1.0 * 1.20) = 24
	return hero.get_effective_atk() == 42 and hero.get_effective_def() == 24


func _test_existing_equipment_multiplier_remains_correct() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	var sword := EquipmentModel.new("SWORD", 1, 100, 1)
	hero.equip("PRIMARY", sword)
	# SWORD gives 1.15x power. Lv1 ATK = floor(35 * 1.15) = floor(40.25) = 40
	return hero.get_effective_atk() == 40


# ==============================================================================
# ASCENSION (19-33)
# ==============================================================================

func _test_1_star_to_2_star_eligibility_at_lv10() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.level = 10
	return hero.can_ascend() == true


func _test_ascension_blocked_below_cap() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.level = 9
	return hero.can_ascend() == false


func _test_ascension_blocked_at_potential_star() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 3, 3)
	hero.level = 30
	return hero.can_ascend() == false


func _test_ascension_blocked_for_dead_hero() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.level = 10
	hero.mark_dead()
	return hero.can_ascend() == false


func _test_ascension_blocked_at_5_star() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 5, 5)
	hero.level = 50
	return hero.can_ascend() == false


func _test_cost_1_star_to_2_star_is_150() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	return hero.get_ascension_cost() == 150


func _test_cost_2_star_to_3_star_is_300() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 2, 4)
	return hero.get_ascension_cost() == 300


func _test_cost_3_star_to_4_star_is_450() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 3, 5)
	return hero.get_ascension_cost() == 450


func _test_cost_4_star_to_5_star_is_600() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 4, 5)
	return hero.get_ascension_cost() == 600


func _test_successful_ascension_increments_exactly_one_star() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.level = 10
	var ok: bool = hero.ascend()
	return ok and hero.current_star == 2


func _test_potential_star_unchanged() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.level = 10
	hero.ascend()
	return hero.potential_star == 3


func _test_level_unchanged_after_ascension() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.level = 10
	hero.ascend()
	return hero.level == 10


func _test_exp_unchanged_after_ascension() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.level = 10
	hero.current_exp = 55
	hero.ascend()
	return hero.current_exp == 55


func _test_equipment_unchanged_after_ascension() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.level = 10
	var sword := EquipmentModel.new("SWORD", 1, 100, 1)
	hero.equip("PRIMARY", sword)
	hero.ascend()
	return hero.get_equipment("PRIMARY") == sword


func _test_fatigue_morale_unchanged_after_ascension() -> bool:
	var hero := HeroModel.new("h_test", "Tester", 1, 3)
	hero.level = 10
	hero.fatigue = 45
	hero.morale = 115
	hero.ascend()
	return hero.fatigue == 45 and hero.morale == 115


# ==============================================================================
# ATOMIC GOLD TRANSACTION (34-38)
# ==============================================================================

func _test_insufficient_gold_rejects_ascension() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_test")
	coord.set_treasury_gold(100) # Biaya untuk Alder (1★) adalah 150
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.level = 10
	var ok: bool = coord.ascend_hero("hero_alder")
	return ok == false


func _test_insufficient_gold_does_not_mutate_star() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_test")
	coord.set_treasury_gold(100)
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.level = 10
	coord.ascend_hero("hero_alder")
	return alder.current_star == 1


func _test_insufficient_gold_does_not_mutate_treasury() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_test")
	coord.set_treasury_gold(100)
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.level = 10
	coord.ascend_hero("hero_alder")
	return coord.get_treasury_gold() == 100


func _test_successful_ascension_deducts_exact_cost() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_test")
	coord.set_treasury_gold(200)
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.level = 10
	var ok: bool = coord.ascend_hero("hero_alder")
	# Biaya = 150. Sisa gold = 200 - 150 = 50.
	return ok == true and coord.get_treasury_gold() == 50


func _test_successful_ascension_changes_star_exactly_once() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_test")
	coord.set_treasury_gold(200)
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.level = 10
	var ok: bool = coord.ascend_hero("hero_alder")
	return ok == true and alder.current_star == 2


# ==============================================================================
# BATTLE EXP (39-45)
# ==============================================================================

func _test_wave_1_exp_calculation() -> bool:
	# floor(60.0 * (1.0 + 1 / 15.0)) = 64
	return CombatEngine.calculate_battle_exp(1) == 64


func _test_wave_15_exp_calculation() -> bool:
	# floor(60.0 * (1.0 + 15 / 15.0)) = 120
	return CombatEngine.calculate_battle_exp(15) == 120


func _test_wave_30_exp_calculation() -> bool:
	# floor(60.0 * (1.0 + 30 / 15.0)) = 180
	return CombatEngine.calculate_battle_exp(30) == 180


func _test_surviving_hero_receives_exp() -> bool:
	var h1 := HeroModel.new("hero_1", "H1", 1, 3)
	var dist: Dictionary = CombatEngine.distribute_battle_exp(64, [h1])
	return dist.get("hero_1", 0) == 64 and h1.current_exp == 64


func _test_dead_hero_receives_no_exp() -> bool:
	var h1 := HeroModel.new("hero_1", "H1", 1, 3)
	var h2 := HeroModel.new("hero_2", "H2", 1, 3)
	h2.mark_dead()
	var surviving: Array = [h1]
	CombatEngine.distribute_battle_exp(100, surviving)
	return h1.current_exp == 100 and h2.current_exp == 0


func _test_exp_distribution_is_deterministic() -> bool:
	var h_a := HeroModel.new("hero_a", "A", 1, 3)
	var h_b := HeroModel.new("hero_b", "B", 1, 3)
	var h_c := HeroModel.new("hero_c", "C", 1, 3)
	# total 64 EXP / 3 heroes = base 21, remainder 1.
	# hero_a (first alphabetically) receives 22, hero_b receives 21, hero_c receives 21.
	var dist: Dictionary = CombatEngine.distribute_battle_exp(64, [h_c, h_a, h_b])
	return dist.get("hero_a", 0) == 22 and dist.get("hero_b", 0) == 21 and dist.get("hero_c", 0) == 21


func _test_distribution_never_exceeds_awarded_exp() -> bool:
	var heroes: Array = []
	for i in range(5):
		heroes.append(HeroModel.new("hero_" + str(i), "H", 1, 3))

	for total_val in [1, 7, 13, 64, 100, 233]:
		for h in heroes:
			(h as HeroModel).current_exp = 0
		var dist: Dictionary = CombatEngine.distribute_battle_exp(total_val, heroes)
		var sum_exp: int = 0
		for k in dist.keys():
			sum_exp += int(dist[k])
		if sum_exp != total_val:
			return false
	return true


# ==============================================================================
# SUPPLEMENTARY INTEGRATION TESTS (46-47)
# ==============================================================================

func _test_ascend_hero_battle_lock_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_test")
	coord.set_treasury_gold(500)
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.level = 10
	coord.inspect_wave()
	coord.start_battle()
	var ok: bool = coord.ascend_hero("hero_alder")
	return ok == false and alder.current_star == 1 and coord.get_treasury_gold() == 500


func _test_snapshot_telemetry_contains_phase4b_fields() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_test")
	var snap := coord.get_current_snapshot()
	if snap.heroes_data.is_empty():
		return false
	var h_data: Dictionary = snap.heroes_data[0]
	return h_data.has("potential_star") and h_data.has("level_cap") and h_data.has("can_ascend") and h_data.has("ascension_cost")
