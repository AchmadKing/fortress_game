extends SceneTree

## TestPhase7BBattleRewardSettlement
## Test suite otomatis untuk memvalidasi implementasi Phase 7B:
## Battle Reward Settlement & Loot Engine (CombatEngine, GameCoordinator, GameController, PrototypeDebugView).
##
## Memvalidasi 35 pengujian fungsional, integritas, deterministik, dan stres yang terbagi dalam 8 kelompok:
## Group A: Gold Reward Calculation (Canonical Phase 7B) (Tests A1-A6)
## Group B: Monster Core Loot Calculation (Provisional Phase 7B) (Tests B1-B8)
## Group C: Monster Material Loot Calculation (Provisional Phase 7B) (Tests C1-C5)
## Group D: Reward Settlement Authority & Invariants (Tests D1-D6)
## Group E: Duplicate Settlement & Idempotency Protection (Tests E1-E4)
## Group F: Snapshot & View State Integration (Tests F1-F2)
## Group G: Flow & Economic Conservation Integration (Tests G1-G2)
## Group H: Determinism & Stress Test (Tests H1-H2)

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const ResourceLedger = preload("res://scripts/domain/model/resource_ledger.gd")
const GameStateSnapshot = preload("res://scripts/domain/state/game_state_snapshot.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const CombatEngine = preload("res://scripts/simulation/combat_engine.gd")
const PopulationModel = preload("res://scripts/domain/model/population_model.gd")
const FortressModel = preload("res://scripts/domain/model/fortress_model.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 7B BATTLE REWARD SETTLEMENT & LOOT ENGINE TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# Group A: Gold Reward Calculation (Canonical Phase 7B)
		{"name": "test_a1_gold_loot_calculation_victory", "fn": Callable(self, "_test_a1_gold_loot_calculation_victory")},
		{"name": "test_a2_gold_loot_calculation_defeat", "fn": Callable(self, "_test_a2_gold_loot_calculation_defeat")},
		{"name": "test_a3_gold_loot_calculation_game_over", "fn": Callable(self, "_test_a3_gold_loot_calculation_game_over")},
		{"name": "test_a4_gold_loot_scaling_threat_budget", "fn": Callable(self, "_test_a4_gold_loot_scaling_threat_budget")},
		{"name": "test_a5_gold_loot_floor_rounding", "fn": Callable(self, "_test_a5_gold_loot_floor_rounding")},
		{"name": "test_a6_gold_loot_zero_threat_budget", "fn": Callable(self, "_test_a6_gold_loot_zero_threat_budget")},

		# Group B: Monster Core Loot Calculation (Provisional Phase 7B)
		{"name": "test_b1_core_loot_boss_enemy", "fn": Callable(self, "_test_b1_core_loot_boss_enemy")},
		{"name": "test_b2_core_loot_siege_monster", "fn": Callable(self, "_test_b2_core_loot_siege_monster")},
		{"name": "test_b3_core_loot_troll_tank_brute", "fn": Callable(self, "_test_b3_core_loot_troll_tank_brute")},
		{"name": "test_b4_core_loot_mixed_high_tier_enemies", "fn": Callable(self, "_test_b4_core_loot_mixed_high_tier_enemies")},
		{"name": "test_b5_core_loot_minions_and_raiders_only", "fn": Callable(self, "_test_b5_core_loot_minions_and_raiders_only")},
		{"name": "test_b6_core_loot_defeat_zero", "fn": Callable(self, "_test_b6_core_loot_defeat_zero")},
		{"name": "test_b7_core_loot_game_over_zero", "fn": Callable(self, "_test_b7_core_loot_game_over_zero")},
		{"name": "test_b8_core_loot_is_boss_flag_fallback", "fn": Callable(self, "_test_b8_core_loot_is_boss_flag_fallback")},

		# Group C: Monster Material Loot Calculation (Provisional Phase 7B)
		{"name": "test_c1_material_loot_proportional_to_defeated", "fn": Callable(self, "_test_c1_material_loot_proportional_to_defeated")},
		{"name": "test_c2_material_loot_odd_count_rounding", "fn": Callable(self, "_test_c2_material_loot_odd_count_rounding")},
		{"name": "test_c3_material_loot_zero_casualties", "fn": Callable(self, "_test_c3_material_loot_zero_casualties")},
		{"name": "test_c4_material_loot_defeat_zero", "fn": Callable(self, "_test_c4_material_loot_defeat_zero")},
		{"name": "test_c5_material_loot_game_over_zero", "fn": Callable(self, "_test_c5_material_loot_game_over_zero")},

		# Group D: Reward Settlement Authority & Invariants
		{"name": "test_d1_settle_battle_rewards_victory_credits_all_resources", "fn": Callable(self, "_test_d1_settle_battle_rewards_victory_credits_all_resources")},
		{"name": "test_d2_settle_battle_rewards_defeat_credits_nothing", "fn": Callable(self, "_test_d2_settle_battle_rewards_defeat_credits_nothing")},
		{"name": "test_d3_settle_battle_rewards_game_over_blocked", "fn": Callable(self, "_test_d3_settle_battle_rewards_game_over_blocked")},
		{"name": "test_d4_settle_battle_rewards_game_over_flag_in_result_blocked", "fn": Callable(self, "_test_d4_settle_battle_rewards_game_over_flag_in_result_blocked")},
		{"name": "test_d5_settle_battle_rewards_atomic_multi_credit", "fn": Callable(self, "_test_d5_settle_battle_rewards_atomic_multi_credit")},
		{"name": "test_d6_settle_battle_rewards_negative_values_rejected", "fn": Callable(self, "_test_d6_settle_battle_rewards_negative_values_rejected")},

		# Group E: Duplicate Settlement & Idempotency Protection
		{"name": "test_e1_settle_battle_rewards_cannot_settle_twice", "fn": Callable(self, "_test_e1_settle_battle_rewards_cannot_settle_twice")},
		{"name": "test_e2_settle_battle_rewards_result_marked_is_settled", "fn": Callable(self, "_test_e2_settle_battle_rewards_result_marked_is_settled")},
		{"name": "test_e3_settle_battle_rewards_distinct_waves_settle_independently", "fn": Callable(self, "_test_e3_settle_battle_rewards_distinct_waves_settle_independently")},
		{"name": "test_e4_is_battle_result_settled_query", "fn": Callable(self, "_test_e4_is_battle_result_settled_query")},

		# Group F: Snapshot & View State Integration
		{"name": "test_f1_snapshot_reflects_settled_resources", "fn": Callable(self, "_test_f1_snapshot_reflects_settled_resources")},
		{"name": "test_f2_controller_delegation_settle_rewards", "fn": Callable(self, "_test_f2_controller_delegation_settle_rewards")},

		# Group G: Flow & Economic Conservation Integration
		{"name": "test_g1_recovery_transition_settles_rewards_automatically", "fn": Callable(self, "_test_g1_recovery_transition_settles_rewards_automatically")},
		{"name": "test_g2_settlement_preserves_warehouse_and_population", "fn": Callable(self, "_test_g2_settlement_preserves_warehouse_and_population")},

		# Group H: Determinism & Stress Test
		{"name": "test_h1_reward_calculation_bit_identical_determinism", "fn": Callable(self, "_test_h1_reward_calculation_bit_identical_determinism")},
		{"name": "test_h2_50_wave_reward_settlement_stress", "fn": Callable(self, "_test_h2_50_wave_reward_settlement_stress")}
	]

	for t in test_list:
		var ok: bool = false
		var err_msg: String = ""
		var fn: Callable = t["fn"]
		var res = fn.call()
		if res is bool:
			ok = res
		else:
			ok = false
			err_msg = "Test did not return boolean."

		if ok:
			passed += 1
			print("[PASS] %s" % t["name"])
		else:
			failed += 1
			printerr("[FAIL] %s %s" % [t["name"], err_msg])

	print("================================================================")
	print("PHASE 7B TESTS SUMMARY: %d PASSED, %d FAILED (TOTAL %d)" % [passed, failed, test_list.size()])
	print("================================================================")

	if failed > 0:
		quit(1)
	else:
		quit(0)


# ==============================================================================
# TEST SESSION HELPERS
# ==============================================================================

func _create_test_session() -> Dictionary:
	var coord := GameCoordinator.new()
	var ctrl := GameController.new()
	ctrl.setup(coord)
	coord.start_new_session()
	return {"coordinator": coord, "controller": ctrl}


func _cleanup_session(s: Dictionary) -> void:
	if s.has("controller") and is_instance_valid(s["controller"]):
		s["controller"].free()
	s.clear()


# ==============================================================================
# GROUP A: GOLD REWARD CALCULATION (CANONICAL PHASE 7B)
# ==============================================================================

func _test_a1_gold_loot_calculation_victory() -> bool:
	var engine := CombatEngine.new()
	var res: Dictionary = engine.calculate_battle_rewards(100, {}, true, false)
	# floor(100 * 1.30) = 130
	return int(res.get("loot_gold", 0)) == 130 and bool(res.get("reward_eligibility", false)) == true


func _test_a2_gold_loot_calculation_defeat() -> bool:
	var engine := CombatEngine.new()
	var res: Dictionary = engine.calculate_battle_rewards(100, {}, false, false)
	return int(res.get("loot_gold", 0)) == 0 and bool(res.get("reward_eligibility", false)) == false


func _test_a3_gold_loot_calculation_game_over() -> bool:
	var engine := CombatEngine.new()
	var res: Dictionary = engine.calculate_battle_rewards(100, {}, true, true)
	return int(res.get("loot_gold", 0)) == 0 and bool(res.get("reward_eligibility", false)) == false


func _test_a4_gold_loot_scaling_threat_budget() -> bool:
	var engine := CombatEngine.new()
	var res: Dictionary = engine.calculate_battle_rewards(250, {}, true, false)
	# floor(250 * 1.30) = 325
	return int(res.get("loot_gold", 0)) == 325


func _test_a5_gold_loot_floor_rounding() -> bool:
	var engine := CombatEngine.new()
	# 75 * 1.30 = 97.5 -> floor = 97
	var res: Dictionary = engine.calculate_battle_rewards(75, {}, true, false)
	return int(res.get("loot_gold", 0)) == 97


func _test_a6_gold_loot_zero_threat_budget() -> bool:
	var engine := CombatEngine.new()
	var res: Dictionary = engine.calculate_battle_rewards(0, {}, true, false)
	return int(res.get("loot_gold", 0)) == 0 and bool(res.get("reward_eligibility", false)) == true


# ==============================================================================
# GROUP B: MONSTER CORE LOOT CALCULATION (PROVISIONAL PHASE 7B)
# ==============================================================================

func _test_b1_core_loot_boss_enemy() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"BOSS": 1, "MINION": 10}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, false)
	# 1 BOSS = 2 Cores
	return int(res.get("loot_monster_core", 0)) == 2


func _test_b2_core_loot_siege_monster() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"SIEGE": 2, "MINION": 5}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, false)
	# 2 SIEGE = 2 Cores (1 each)
	return int(res.get("loot_monster_core", 0)) == 2


func _test_b3_core_loot_troll_tank_brute() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"BRUTE": 3, "RAIDER": 4}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, false)
	# 3 BRUTE = 3 Cores (1 each)
	return int(res.get("loot_monster_core", 0)) == 3


func _test_b4_core_loot_mixed_high_tier_enemies() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"BOSS": 1, "SIEGE": 1, "BRUTE": 2, "MINION": 10}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, false)
	# 1 BOSS (2) + 1 SIEGE (1) + 2 BRUTE (2) = 5 Cores
	return int(res.get("loot_monster_core", 0)) == 5


func _test_b5_core_loot_minions_and_raiders_only() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"MINION": 20, "RAIDER": 10, "FLYER": 5}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, false)
	return int(res.get("loot_monster_core", 0)) == 0


func _test_b6_core_loot_defeat_zero() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"BOSS": 2, "SIEGE": 3, "BRUTE": 5}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, false, false)
	return int(res.get("loot_monster_core", 0)) == 0


func _test_b7_core_loot_game_over_zero() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"BOSS": 2, "SIEGE": 3, "BRUTE": 5}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, true)
	return int(res.get("loot_monster_core", 0)) == 0


func _test_b8_core_loot_is_boss_flag_fallback() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"is_boss": true, "MINION": 12}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, false)
	# is_boss: true without BOSS key triggers boss fallback (2 Cores)
	return int(res.get("loot_monster_core", 0)) == 2


# ==============================================================================
# GROUP C: MONSTER MATERIAL LOOT CALCULATION (PROVISIONAL PHASE 7B)
# ==============================================================================

func _test_c1_material_loot_proportional_to_defeated() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"MINION": 12, "RAIDER": 8} # Total 20
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, false)
	# floor(20 * 0.50) = 10
	return int(res.get("loot_monster_material", 0)) == 10


func _test_c2_material_loot_odd_count_rounding() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"MINION": 10, "RAIDER": 5} # Total 15
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, false)
	# floor(15 * 0.50) = floor(7.5) = 7
	return int(res.get("loot_monster_material", 0)) == 7


func _test_c3_material_loot_zero_casualties() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, false)
	return int(res.get("loot_monster_material", 0)) == 0


func _test_c4_material_loot_defeat_zero() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"MINION": 20, "RAIDER": 10}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, false, false)
	return int(res.get("loot_monster_material", 0)) == 0


func _test_c5_material_loot_game_over_zero() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"MINION": 20, "RAIDER": 10}
	var res: Dictionary = engine.calculate_battle_rewards(100, enemies, true, true)
	return int(res.get("loot_monster_material", 0)) == 0


# ==============================================================================
# GROUP D: REWARD SETTLEMENT AUTHORITY & INVARIANTS
# ==============================================================================

func _test_d1_settle_battle_rewards_victory_credits_all_resources() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var init_gold: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)
	var init_core: int = coord.get_monster_cores()
	var init_mat: int = coord.get_monster_materials()

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_test_d1",
		"loot_gold": 130,
		"loot_monster_core": 3,
		"loot_monster_material": 10,
		"is_settled": false
	}

	var ok: bool = coord.settle_battle_rewards(custom_res)
	if not ok:
		_cleanup_session(session)
		return false

	var end_gold: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)
	var end_core: int = coord.get_monster_cores()
	var end_mat: int = coord.get_monster_materials()

	_cleanup_session(session)
	return end_gold == (init_gold + 130) and end_core == (init_core + 3) and end_mat == (init_mat + 10)


func _test_d2_settle_battle_rewards_defeat_credits_nothing() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var init_gold: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)
	var init_core: int = coord.get_monster_cores()
	var init_mat: int = coord.get_monster_materials()

	var custom_res: Dictionary = {
		"victory": false,
		"game_over": false,
		"settlement_id": "wave_1_test_d2",
		"loot_gold": 100,
		"loot_monster_core": 2,
		"loot_monster_material": 5,
		"is_settled": false
	}

	var ok: bool = coord.settle_battle_rewards(custom_res)
	# Defeat settlement is rejected (returns false)
	if ok:
		_cleanup_session(session)
		return false

	var end_gold: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)
	var end_core: int = coord.get_monster_cores()
	var end_mat: int = coord.get_monster_materials()

	_cleanup_session(session)
	return end_gold == init_gold and end_core == init_core and end_mat == init_mat


func _test_d3_settle_battle_rewards_game_over_blocked() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	coord.get_state_machine().reset(GameplayStateMachine.STATE_GAME_OVER)

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_test_d3",
		"loot_gold": 130,
		"loot_monster_core": 3,
		"loot_monster_material": 10,
		"is_settled": false
	}

	var ok: bool = coord.settle_battle_rewards(custom_res)
	var gold: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)

	_cleanup_session(session)
	# Settlement blocked during GAME_OVER, balance unmutated
	return ok == false and gold == 150


func _test_d4_settle_battle_rewards_game_over_flag_in_result_blocked() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": true, # Fortress destroyed
		"settlement_id": "wave_1_test_d4",
		"loot_gold": 130,
		"loot_monster_core": 3,
		"loot_monster_material": 10,
		"is_settled": false
	}

	var ok: bool = coord.settle_battle_rewards(custom_res)
	_cleanup_session(session)
	return ok == false


func _test_d5_settle_battle_rewards_atomic_multi_credit() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_test_d5",
		"loot_gold": 200,
		"loot_monster_core": 5,
		"loot_monster_material": 12,
		"is_settled": false
	}

	var ok: bool = coord.settle_battle_rewards(custom_res)
	var all_res: Dictionary = coord.get_all_resources()

	_cleanup_session(session)
	return ok and all_res[ResourceLedger.RESOURCE_GOLD] == 350 and all_res[ResourceLedger.RESOURCE_MONSTER_CORE] == 5 and all_res[ResourceLedger.RESOURCE_MONSTER_MATERIAL] == 12


func _test_d6_settle_battle_rewards_negative_values_rejected() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var init_gold: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_test_d6",
		"loot_gold": -50,
		"loot_monster_core": 0,
		"loot_monster_material": 0,
		"is_settled": false
	}

	var ok: bool = coord.settle_battle_rewards(custom_res)
	var end_gold: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)

	_cleanup_session(session)
	return ok == false and end_gold == init_gold


# ==============================================================================
# GROUP E: DUPLICATE SETTLEMENT & IDEMPOTENCY PROTECTION
# ==============================================================================

func _test_e1_settle_battle_rewards_cannot_settle_twice() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_unique_e1",
		"loot_gold": 100,
		"loot_monster_core": 1,
		"loot_monster_material": 2,
		"is_settled": false
	}

	var ok1: bool = coord.settle_battle_rewards(custom_res)
	var gold_after_first: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)

	# Second call with the same dictionary / settlement ID
	var ok2: bool = coord.settle_battle_rewards(custom_res)
	var gold_after_second: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)

	_cleanup_session(session)
	return ok1 == true and ok2 == false and gold_after_first == gold_after_second


func _test_e2_settle_battle_rewards_result_marked_is_settled() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_unique_e2",
		"loot_gold": 50,
		"loot_monster_core": 0,
		"loot_monster_material": 0,
		"is_settled": false
	}

	var ok: bool = coord.settle_battle_rewards(custom_res)
	var is_settled_flag: bool = bool(custom_res.get("is_settled", false))

	_cleanup_session(session)
	return ok == true and is_settled_flag == true


func _test_e3_settle_battle_rewards_distinct_waves_settle_independently() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var wave1_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_unique_e3",
		"loot_gold": 100,
		"loot_monster_core": 1,
		"loot_monster_material": 2,
		"is_settled": false
	}

	var wave2_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_2_unique_e3",
		"loot_gold": 150,
		"loot_monster_core": 2,
		"loot_monster_material": 4,
		"is_settled": false
	}

	var ok1: bool = coord.settle_battle_rewards(wave1_res)
	var ok2: bool = coord.settle_battle_rewards(wave2_res)

	var total_gold: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)
	var total_core: int = coord.get_monster_cores()
	var total_mat: int = coord.get_monster_materials()

	_cleanup_session(session)
	# Initial 150 + 100 + 150 = 400
	return ok1 and ok2 and total_gold == 400 and total_core == 3 and total_mat == 6


func _test_e4_is_battle_result_settled_query() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_query_e4",
		"loot_gold": 60,
		"loot_monster_core": 1,
		"loot_monster_material": 1,
		"is_settled": false
	}

	var before_query: bool = coord.is_battle_result_settled("wave_1_query_e4")
	coord.settle_battle_rewards(custom_res)
	var after_query: bool = coord.is_battle_result_settled("wave_1_query_e4")

	_cleanup_session(session)
	return before_query == false and after_query == true


# ==============================================================================
# GROUP F: SNAPSHOT & VIEW STATE INTEGRATION
# ==============================================================================

func _test_f1_snapshot_reflects_settled_resources() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_snap_f1",
		"loot_gold": 120,
		"loot_monster_core": 2,
		"loot_monster_material": 6,
		"is_settled": false
	}

	coord.settle_battle_rewards(custom_res)
	var snap: GameStateSnapshot = coord.get_current_state()

	var r_data: Dictionary = snap.resources_data
	var e_data: Dictionary = snap.economy_data

	_cleanup_session(session)
	return int(r_data.get("GOLD", 0)) == 270 and int(r_data.get("MONSTER_CORE", 0)) == 2 and int(r_data.get("MONSTER_MATERIAL", 0)) == 6 and int(e_data.get("treasury_gold", 0)) == 270


func _test_f2_controller_delegation_settle_rewards() -> bool:
	var session: Dictionary = _create_test_session()
	var ctrl: GameController = session["controller"]
	var coord: GameCoordinator = session["coordinator"]

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_ctrl_f2",
		"loot_gold": 80,
		"loot_monster_core": 1,
		"loot_monster_material": 3,
		"is_settled": false
	}

	var ok: bool = ctrl.settle_battle_rewards(custom_res)
	var is_settled: bool = ctrl.is_battle_result_settled("wave_1_ctrl_f2")
	var last_res: Dictionary = ctrl.get_last_battle_result()

	_cleanup_session(session)
	return ok == true and is_settled == true and (last_res is Dictionary)


# ==============================================================================
# GROUP G: FLOW & ECONOMIC CONSERVATION INTEGRATION
# ==============================================================================

func _test_g1_recovery_transition_settles_rewards_automatically() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	# Selesaikan battle kanonikal: PREPARATION -> WAVE_PREVIEW -> BATTLE -> RESULT
	coord.inspect_wave()
	coord.start_battle()
	var battle_res: Dictionary = coord.execute_battle()

	var is_victory: bool = bool(battle_res.get("victory", false))

	# Transisi ke RECOVERY -> PREPARATION via proceed_from_result
	var ok: bool = coord.proceed_from_result()
	if not ok:
		_cleanup_session(session)
		return false

	var phase: String = coord.get_current_state().game_phase
	var is_settled: bool = coord.is_battle_result_settled(str(battle_res.get("settlement_id", "")))

	_cleanup_session(session)
	# Pada victory, proceed_from_result otomatis settle rewards dan kembali ke PREPARATION untuk wave berikutnya
	return is_victory and phase == "PREPARATION" and is_settled


func _test_g2_settlement_preserves_warehouse_and_population() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]

	var warehouse_before: int = coord.get_current_state().warehouse_data.size()
	var pop_before: int = coord.get_available_soldiers()

	var custom_res: Dictionary = {
		"victory": true,
		"game_over": false,
		"settlement_id": "wave_1_preserve_g2",
		"loot_gold": 100,
		"loot_monster_core": 2,
		"loot_monster_material": 5,
		"is_settled": false
	}

	coord.settle_battle_rewards(custom_res)

	var warehouse_after: int = coord.get_current_state().warehouse_data.size()
	var pop_after: int = coord.get_available_soldiers()

	_cleanup_session(session)
	return warehouse_before == warehouse_after and pop_before == pop_after


# ==============================================================================
# GROUP H: DETERMINISM & STRESS TEST
# ==============================================================================

func _test_h1_reward_calculation_bit_identical_determinism() -> bool:
	var engine := CombatEngine.new()
	var enemies: Dictionary = {"BOSS": 1, "SIEGE": 2, "BRUTE": 3, "MINION": 15, "RAIDER": 5}

	var base_res: Dictionary = engine.calculate_battle_rewards(300, enemies, true, false)

	for i in range(100):
		var test_res: Dictionary = engine.calculate_battle_rewards(300, enemies, true, false)
		if test_res["loot_gold"] != base_res["loot_gold"] or \
		   test_res["loot_monster_core"] != base_res["loot_monster_core"] or \
		   test_res["loot_monster_material"] != base_res["loot_monster_material"] or \
		   test_res["reward_eligibility"] != base_res["reward_eligibility"]:
			return false

	return true


func _test_h2_50_wave_reward_settlement_stress() -> bool:
	var session: Dictionary = _create_test_session()
	var coord: GameCoordinator = session["coordinator"]
	var engine := CombatEngine.new()

	var expected_total_gold: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)
	var expected_total_core: int = 0
	var expected_total_mat: int = 0

	for w in range(1, 51):
		var threat: int = 50 + (w * 10)
		var enemies: Dictionary = {
			"MINION": 10 + w,
			"RAIDER": 2 + (w / 5),
			"BRUTE": 1 if (w % 3 == 0) else 0,
			"SIEGE": 1 if (w % 10 == 0) else 0,
			"BOSS": 1 if (w % 25 == 0) else 0
		}

		var rewards: Dictionary = engine.calculate_battle_rewards(threat, enemies, true, false)
		expected_total_gold += int(rewards["loot_gold"])
		expected_total_core += int(rewards["loot_monster_core"])
		expected_total_mat += int(rewards["loot_monster_material"])

		var wave_result: Dictionary = {
			"victory": true,
			"game_over": false,
			"settlement_id": "stress_wave_%d" % w,
			"loot_gold": rewards["loot_gold"],
			"loot_monster_core": rewards["loot_monster_core"],
			"loot_monster_material": rewards["loot_monster_material"],
			"is_settled": false
		}

		var ok: bool = coord.settle_battle_rewards(wave_result)
		if not ok:
			_cleanup_session(session)
			return false

	var final_gold: int = coord.get_resource(ResourceLedger.RESOURCE_GOLD)
	var final_core: int = coord.get_monster_cores()
	var final_mat: int = coord.get_monster_materials()

	_cleanup_session(session)
	return final_gold == expected_total_gold and final_core == expected_total_core and final_mat == expected_total_mat
