extends SceneTree

## TestPhase7AResourceAuthority
## Test suite otomatis untuk memvalidasi implementasi Phase 7A:
## Resource Authority & Economy Domain Model (ResourceLedger, GameCoordinator, GameController, GameStateSnapshot).
##
## Memvalidasi 27 pengujian fungsional, integritas, reaktif, dan integrasi yang terbagi dalam 5 kelompok:
## Group A: ResourceLedger Pure Domain Invariants (Tests A1-A6)
## Group B: Ledger Boundary, Invariants, and Serialization (Tests B1-B5)
## Group C: GameCoordinator Resource Authority & Integration (Tests C1-C6)
## Group D: GameStateSnapshot Synchronization & Isolation (Tests D1-D4)
## Group E: GameController Delegation & Compatibility with Existing Sinks (Tests E1-E6)

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const ResourceLedger = preload("res://scripts/domain/model/resource_ledger.gd")
const GameStateSnapshot = preload("res://scripts/domain/state/game_state_snapshot.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const EconomyManager = preload("res://scripts/simulation/economy_manager.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 7A RESOURCE AUTHORITY & ECONOMY DOMAIN TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# Group A: ResourceLedger Pure Domain Invariants (1-6)
		{"name": "test_a1_initial_resources_default_and_custom", "fn": Callable(self, "_test_a1_initial_resources_default_and_custom")},
		{"name": "test_a2_canonical_constants_and_aliases", "fn": Callable(self, "_test_a2_canonical_constants_and_aliases")},
		{"name": "test_a3_set_resource_clamped_non_negative", "fn": Callable(self, "_test_a3_set_resource_clamped_non_negative")},
		{"name": "test_a4_add_resource_single_and_multi", "fn": Callable(self, "_test_a4_add_resource_single_and_multi")},
		{"name": "test_a5_spend_resource_valid_and_insufficient", "fn": Callable(self, "_test_a5_spend_resource_valid_and_insufficient")},
		{"name": "test_a6_atomic_rollback_on_failed_spend_resources", "fn": Callable(self, "_test_a6_atomic_rollback_on_failed_spend_resources")},

		# Group B: Ledger Boundary, Invariants, and Serialization (7-11)
		{"name": "test_b1_validate_invariants_strictly_enforced", "fn": Callable(self, "_test_b1_validate_invariants_strictly_enforced")},
		{"name": "test_b2_ledger_clone_deep_isolation", "fn": Callable(self, "_test_b2_ledger_clone_deep_isolation")},
		{"name": "test_b3_to_and_from_dictionary_roundtrip", "fn": Callable(self, "_test_b3_to_and_from_dictionary_roundtrip")},
		{"name": "test_b4_unknown_resource_handling", "fn": Callable(self, "_test_b4_unknown_resource_handling")},
		{"name": "test_b5_zero_and_negative_amounts_safety", "fn": Callable(self, "_test_b5_zero_and_negative_amounts_safety")},

		# Group C: GameCoordinator Resource Authority & Integration (12-17)
		{"name": "test_c1_coordinator_owns_single_source_of_truth_ledger", "fn": Callable(self, "_test_c1_coordinator_owns_single_source_of_truth_ledger")},
		{"name": "test_c2_coordinator_resource_queries_and_convenience_getters", "fn": Callable(self, "_test_c2_coordinator_resource_queries_and_convenience_getters")},
		{"name": "test_c3_coordinator_can_afford_and_can_afford_resources", "fn": Callable(self, "_test_c3_coordinator_can_afford_and_can_afford_resources")},
		{"name": "test_c4_coordinator_set_add_spend_mutations_emit_signal", "fn": Callable(self, "_test_c4_coordinator_set_add_spend_mutations_emit_signal")},
		{"name": "test_c5_economy_manager_and_coordinator_zero_desync", "fn": Callable(self, "_test_c5_economy_manager_and_coordinator_zero_desync")},
		{"name": "test_c6_game_over_transaction_lock", "fn": Callable(self, "_test_c6_game_over_transaction_lock")},

		# Group D: GameStateSnapshot Synchronization & Isolation (18-21)
		{"name": "test_d1_snapshot_contains_resources_data", "fn": Callable(self, "_test_d1_snapshot_contains_resources_data")},
		{"name": "test_d2_snapshot_economy_data_contains_treasury_and_all_materials", "fn": Callable(self, "_test_d2_snapshot_economy_data_contains_treasury_and_all_materials")},
		{"name": "test_d3_snapshot_clone_and_read_isolation", "fn": Callable(self, "_test_d3_snapshot_clone_and_read_isolation")},
		{"name": "test_d4_snapshot_serialization_roundtrip_with_resources", "fn": Callable(self, "_test_d4_snapshot_serialization_roundtrip_with_resources")},

		# Group E: GameController Delegation & Compatibility with Existing Sinks (22-27)
		{"name": "test_e1_game_controller_delegates_all_resource_methods", "fn": Callable(self, "_test_e1_game_controller_delegates_all_resource_methods")},
		{"name": "test_e2_hero_recruitment_spends_500_gold_from_ledger", "fn": Callable(self, "_test_e2_hero_recruitment_spends_500_gold_from_ledger")},
		{"name": "test_e3_hero_ascension_spends_star_x_150_gold_from_ledger", "fn": Callable(self, "_test_e3_hero_ascension_spends_star_x_150_gold_from_ledger")},
		{"name": "test_e4_structure_repair_spends_gold_from_ledger", "fn": Callable(self, "_test_e4_structure_repair_spends_gold_from_ledger")},
		{"name": "test_e5_equipment_repair_and_blacksmith_discount_from_ledger", "fn": Callable(self, "_test_e5_equipment_repair_and_blacksmith_discount_from_ledger")},
		{"name": "test_e6_deterministic_100_transaction_stress_simulation", "fn": Callable(self, "_test_e6_deterministic_100_transaction_stress_simulation")}
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
	print("PHASE 7A TESTS SUMMARY: %d PASSED, %d FAILED (TOTAL %d)" % [passed, failed, test_list.size()])
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
# GROUP A: RESOURCE LEDGER PURE DOMAIN INVARIANTS
# ==============================================================================

func _test_a1_initial_resources_default_and_custom() -> bool:
	var l_default := ResourceLedger.new()
	if l_default.get_gold() != 150:
		return false
	if l_default.get_monster_cores() != 0:
		return false
	if l_default.get_monster_materials() != 0:
		return false
	if l_default.get_basic_materials() != 0:
		return false
	if l_default.get_rare_materials() != 0:
		return false

	var custom_res := {
		ResourceLedger.RESOURCE_MONSTER_CORE: 12,
		ResourceLedger.RESOURCE_BASIC_MATERIAL: 45
	}
	var l_custom := ResourceLedger.new(500, custom_res)
	if l_custom.get_gold() != 500:
		return false
	if l_custom.get_monster_cores() != 12:
		return false
	if l_custom.get_basic_materials() != 45:
		return false
	if l_custom.get_rare_materials() != 0:
		return false
	return true


func _test_a2_canonical_constants_and_aliases() -> bool:
	if ResourceLedger.normalize_resource_type("TREASURY_GOLD") != ResourceLedger.RESOURCE_GOLD:
		return false
	if ResourceLedger.normalize_resource_type("MONSTER_CORES") != ResourceLedger.RESOURCE_MONSTER_CORE:
		return false
	if ResourceLedger.normalize_resource_type("MONSTER_MATERIALS") != ResourceLedger.RESOURCE_MONSTER_MATERIAL:
		return false
	if ResourceLedger.normalize_resource_type("BASIC_MATERIALS") != ResourceLedger.RESOURCE_BASIC_MATERIAL:
		return false
	if ResourceLedger.normalize_resource_type("RARE_MATERIALS") != ResourceLedger.RESOURCE_RARE_MATERIAL:
		return false

	var ledger := ResourceLedger.new(200, {
		"MONSTER_CORES": 5,
		"BASIC_MATERIALS": 10
	})
	if ledger.get_resource("TREASURY_GOLD") != 200:
		return false
	if ledger.get_resource("MONSTER_CORES") != 5:
		return false
	if ledger.get_resource("BASIC_MATERIALS") != 10:
		return false
	return true


func _test_a3_set_resource_clamped_non_negative() -> bool:
	var ledger := ResourceLedger.new(150)
	var ok: bool = ledger.set_resource(ResourceLedger.RESOURCE_GOLD, 350)
	if not ok or ledger.get_gold() != 350:
		return false

	# Nilai negatif ditolak, saldo tetap
	var neg_ok: bool = ledger.set_resource(ResourceLedger.RESOURCE_GOLD, -99)
	if neg_ok or ledger.get_gold() != 350:
		return false

	# Unknown resource ditolak
	var unknown_res: bool = ledger.set_resource("DIAMOND_CRYSTAL", 50)
	if unknown_res:
		return false
	return true


func _test_a4_add_resource_single_and_multi() -> bool:
	var ledger := ResourceLedger.new(100)
	var ok1: bool = ledger.add_resource(ResourceLedger.RESOURCE_MONSTER_CORE, 8)
	if not ok1 or ledger.get_monster_cores() != 8:
		return false

	# Penambahan negatif ditolak
	var neg_ok: bool = ledger.add_resource(ResourceLedger.RESOURCE_MONSTER_CORE, -3)
	if neg_ok or ledger.get_monster_cores() != 8:
		return false

	# Multi add atomik
	var credits: Dictionary = {
		ResourceLedger.RESOURCE_GOLD: 50,
		ResourceLedger.RESOURCE_BASIC_MATERIAL: 30,
		ResourceLedger.RESOURCE_RARE_MATERIAL: 5
	}
	var multi_ok: bool = ledger.add_resources(credits)
	if not multi_ok:
		return false
	if ledger.get_gold() != 150:
		return false
	if ledger.get_basic_materials() != 30:
		return false
	if ledger.get_rare_materials() != 5:
		return false
	return true


func _test_a5_spend_resource_valid_and_insufficient() -> bool:
	var ledger := ResourceLedger.new(150)
	# Pengeluaran valid
	var ok: bool = ledger.spend_resource(ResourceLedger.RESOURCE_GOLD, 50)
	if not ok or ledger.get_gold() != 100:
		return false

	# Pengeluaran melebihi saldo ditolak & saldo utuh
	var over_spend: bool = ledger.spend_resource(ResourceLedger.RESOURCE_GOLD, 101)
	if over_spend or ledger.get_gold() != 100:
		return false

	# Pengeluaran negatif ditolak
	var neg_spend: bool = ledger.spend_resource(ResourceLedger.RESOURCE_GOLD, -10)
	if neg_spend or ledger.get_gold() != 100:
		return false
	return true


func _test_a6_atomic_rollback_on_failed_spend_resources() -> bool:
	var ledger := ResourceLedger.new(100, {
		ResourceLedger.RESOURCE_MONSTER_CORE: 5,
		ResourceLedger.RESOURCE_BASIC_MATERIAL: 20
	})

	# Biaya multi-resource di mana RARE_MATERIAL tidak mencukupi (saldo 0, biaya 1)
	var multi_cost: Dictionary = {
		ResourceLedger.RESOURCE_GOLD: 50,
		ResourceLedger.RESOURCE_MONSTER_CORE: 2,
		ResourceLedger.RESOURCE_BASIC_MATERIAL: 10,
		ResourceLedger.RESOURCE_RARE_MATERIAL: 1
	}

	var res: bool = ledger.spend_resources(multi_cost)
	if res:
		return false # Harus gagal karena RARE_MATERIAL kurang

	# Strict Rollback: Seluruh saldo tidak boleh berkurang sama sekali
	if ledger.get_gold() != 100:
		return false
	if ledger.get_monster_cores() != 5:
		return false
	if ledger.get_basic_materials() != 20:
		return false
	if ledger.get_rare_materials() != 0:
		return false
	return true


# ==============================================================================
# GROUP B: LEDGER BOUNDARY, INVARIANTS, AND SERIALIZATION
# ==============================================================================

func _test_b1_validate_invariants_strictly_enforced() -> bool:
	var ledger := ResourceLedger.new(150)
	if not ledger.validate_invariants():
		return false

	# Jika secara internal ada key yang hilang atau negatif
	ledger._resources[ResourceLedger.RESOURCE_GOLD] = -10
	if ledger.validate_invariants():
		return false
	return true


func _test_b2_ledger_clone_deep_isolation() -> bool:
	var original := ResourceLedger.new(200, {
		ResourceLedger.RESOURCE_MONSTER_CORE: 10
	})
	var copy: ResourceLedger = original.clone()

	# Mutasi clone tidak mempengaruhi original
	copy.spend_resource(ResourceLedger.RESOURCE_GOLD, 50)
	copy.add_resource(ResourceLedger.RESOURCE_MONSTER_CORE, 5)

	if original.get_gold() != 200:
		return false
	if original.get_monster_cores() != 10:
		return false
	if copy.get_gold() != 150:
		return false
	if copy.get_monster_cores() != 15:
		return false
	return true


func _test_b3_to_and_from_dictionary_roundtrip() -> bool:
	var ledger := ResourceLedger.new(350, {
		ResourceLedger.RESOURCE_MONSTER_CORE: 7,
		ResourceLedger.RESOURCE_MONSTER_MATERIAL: 14,
		ResourceLedger.RESOURCE_BASIC_MATERIAL: 80,
		ResourceLedger.RESOURCE_RARE_MATERIAL: 3
	})

	var dict: Dictionary = ledger.to_dictionary()
	var restored: ResourceLedger = ResourceLedger.from_dictionary(dict)

	if restored.get_gold() != 350:
		return false
	if restored.get_monster_cores() != 7:
		return false
	if restored.get_monster_materials() != 14:
		return false
	if restored.get_basic_materials() != 80:
		return false
	if restored.get_rare_materials() != 3:
		return false
	return true


func _test_b4_unknown_resource_handling() -> bool:
	var ledger := ResourceLedger.new(150)
	if ledger.get_resource("MAGIC_DUST") != 0:
		return false
	if ledger.can_afford("MAGIC_DUST", 1):
		return false
	if ledger.spend_resource("MAGIC_DUST", 1):
		return false
	if ledger.add_resource("MAGIC_DUST", 5):
		return false
	return true


func _test_b5_zero_and_negative_amounts_safety() -> bool:
	var ledger := ResourceLedger.new(150)
	# Spending 0 is valid no-op
	if not ledger.spend_resource(ResourceLedger.RESOURCE_GOLD, 0):
		return false
	if ledger.get_gold() != 150:
		return false

	# Adding 0 is valid no-op
	if not ledger.add_resource(ResourceLedger.RESOURCE_GOLD, 0):
		return false
	if ledger.get_gold() != 150:
		return false

	# Can afford 0 is always true
	if not ledger.can_afford(ResourceLedger.RESOURCE_GOLD, 0):
		return false
	return true


# ==============================================================================
# GROUP C: GAME COORDINATOR RESOURCE AUTHORITY & INTEGRATION
# ==============================================================================

func _test_c1_coordinator_owns_single_source_of_truth_ledger() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]

	var ledger: ResourceLedger = coord.get_resource_ledger()
	if ledger == null:
		_cleanup_session(s)
		return false
	if coord.get_resource(ResourceLedger.RESOURCE_GOLD) != 150:
		_cleanup_session(s)
		return false
	if coord.get_treasury_gold() != 150:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_c2_coordinator_resource_queries_and_convenience_getters() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]

	if coord.get_treasury_gold() != 150:
		_cleanup_session(s)
		return false
	if coord.get_monster_cores() != 0:
		_cleanup_session(s)
		return false
	if coord.get_monster_materials() != 0:
		_cleanup_session(s)
		return false
	if coord.get_basic_materials() != 0:
		_cleanup_session(s)
		return false
	if coord.get_rare_materials() != 0:
		_cleanup_session(s)
		return false

	var all_res: Dictionary = coord.get_all_resources()
	if all_res.size() != 5:
		_cleanup_session(s)
		return false
	if int(all_res[ResourceLedger.RESOURCE_GOLD]) != 150:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_c3_coordinator_can_afford_and_can_afford_resources() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]

	if not coord.can_afford_resource(ResourceLedger.RESOURCE_GOLD, 150):
		_cleanup_session(s)
		return false
	if coord.can_afford_resource(ResourceLedger.RESOURCE_GOLD, 151):
		_cleanup_session(s)
		return false

	coord.add_resource(ResourceLedger.RESOURCE_BASIC_MATERIAL, 25)
	var combo_afford: Dictionary = {
		ResourceLedger.RESOURCE_GOLD: 100,
		ResourceLedger.RESOURCE_BASIC_MATERIAL: 20
	}
	if not coord.can_afford_resources(combo_afford):
		_cleanup_session(s)
		return false

	var combo_unaffordable: Dictionary = {
		ResourceLedger.RESOURCE_GOLD: 100,
		ResourceLedger.RESOURCE_BASIC_MATERIAL: 26
	}
	if coord.can_afford_resources(combo_unaffordable):
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_c4_coordinator_set_add_spend_mutations_emit_signal() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]

	var ctx: Dictionary = {
		"emitted": false,
		"snapshot": null
	}
	coord.state_changed.connect(func(snap: GameStateSnapshot):
		ctx["emitted"] = true
		ctx["snapshot"] = snap
	)

	# Mutasi: add monster material
	var ok: bool = coord.add_resource(ResourceLedger.RESOURCE_MONSTER_MATERIAL, 15)
	if not ok or not bool(ctx["emitted"]):
		_cleanup_session(s)
		return false
	if coord.get_monster_materials() != 15:
		_cleanup_session(s)
		return false
	var snap1: GameStateSnapshot = ctx["snapshot"]
	if snap1 == null or int(snap1.resources_data.get(ResourceLedger.RESOURCE_MONSTER_MATERIAL, 0)) != 15:
		_cleanup_session(s)
		return false

	# Mutasi: spend gold
	ctx["emitted"] = false
	var spend_ok: bool = coord.spend_resource(ResourceLedger.RESOURCE_GOLD, 50)
	if not spend_ok or not bool(ctx["emitted"]):
		_cleanup_session(s)
		return false
	if coord.get_treasury_gold() != 100:
		_cleanup_session(s)
		return false
	var snap2: GameStateSnapshot = ctx["snapshot"]
	if snap2 == null or int(snap2.resources_data.get(ResourceLedger.RESOURCE_GOLD, 0)) != 100:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_c5_economy_manager_and_coordinator_zero_desync() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]

	# 1. Modifikasi via coordinator.set_treasury_gold
	coord.set_treasury_gold(400)
	if coord._economy.treasury_gold != 400:
		_cleanup_session(s)
		return false
	if coord.get_resource(ResourceLedger.RESOURCE_GOLD) != 400:
		_cleanup_session(s)
		return false

	# 2. Modifikasi via economy_manager property
	coord._economy.treasury_gold = 250
	if coord.get_treasury_gold() != 250:
		_cleanup_session(s)
		return false
	if coord.get_resource(ResourceLedger.RESOURCE_GOLD) != 250:
		_cleanup_session(s)
		return false

	# 3. Modifikasi via ledger langsung
	coord.get_resource_ledger().add_resource(ResourceLedger.RESOURCE_GOLD, 50)
	if coord._economy.treasury_gold != 300:
		_cleanup_session(s)
		return false
	if coord.get_treasury_gold() != 300:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_c6_game_over_transaction_lock() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]

	# Set state machine ke GAME_OVER via reset (terminal state)
	coord.get_state_machine().reset(GameplayStateMachine.STATE_GAME_OVER)
	if not coord.is_game_over():
		_cleanup_session(s)
		return false

	var gold_before: int = coord.get_treasury_gold()

	# Seluruh transaksi mutasi wajib ditolak dan saldo tidak boleh berubah
	if coord.set_resource(ResourceLedger.RESOURCE_GOLD, 9999):
		_cleanup_session(s)
		return false
	if coord.add_resource(ResourceLedger.RESOURCE_GOLD, 100):
		_cleanup_session(s)
		return false
	if coord.add_resources({ResourceLedger.RESOURCE_GOLD: 50}):
		_cleanup_session(s)
		return false
	if coord.spend_resource(ResourceLedger.RESOURCE_GOLD, 50):
		_cleanup_session(s)
		return false
	if coord.spend_resources({ResourceLedger.RESOURCE_GOLD: 50}):
		_cleanup_session(s)
		return false

	coord.set_treasury_gold(777)
	if coord.get_treasury_gold() != gold_before:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


# ==============================================================================
# GROUP D: GAME STATE SNAPSHOT SYNCHRONIZATION & ISOLATION
# ==============================================================================

func _test_d1_snapshot_contains_resources_data() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]

	coord.add_resource(ResourceLedger.RESOURCE_MONSTER_CORE, 3)
	coord.add_resource(ResourceLedger.RESOURCE_BASIC_MATERIAL, 15)

	var snapshot: GameStateSnapshot = coord.get_current_state()
	if not snapshot.resources_data.has(ResourceLedger.RESOURCE_GOLD):
		_cleanup_session(s)
		return false
	if int(snapshot.resources_data[ResourceLedger.RESOURCE_GOLD]) != 150:
		_cleanup_session(s)
		return false
	if int(snapshot.resources_data[ResourceLedger.RESOURCE_MONSTER_CORE]) != 3:
		_cleanup_session(s)
		return false
	if int(snapshot.resources_data[ResourceLedger.RESOURCE_BASIC_MATERIAL]) != 15:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_d2_snapshot_economy_data_contains_treasury_and_all_materials() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]

	coord.add_resource(ResourceLedger.RESOURCE_RARE_MATERIAL, 7)

	var snapshot: GameStateSnapshot = coord.get_current_state()
	var eco: Dictionary = snapshot.economy_data
	if int(eco.get("treasury_gold", 0)) != 150:
		_cleanup_session(s)
		return false
	if int(eco.get("rare_materials", 0)) != 7:
		_cleanup_session(s)
		return false
	if not eco.has("resources"):
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_d3_snapshot_clone_and_read_isolation() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]

	var snapshot: GameStateSnapshot = coord.get_current_state()
	# Mutasi read-model snapshot
	snapshot.resources_data[ResourceLedger.RESOURCE_GOLD] = 999999
	snapshot.economy_data["treasury_gold"] = 999999

	# Coordinator domain model tetap tidak tersentuh
	if coord.get_treasury_gold() != 150:
		_cleanup_session(s)
		return false
	if coord.get_resource(ResourceLedger.RESOURCE_GOLD) != 150:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_d4_snapshot_serialization_roundtrip_with_resources() -> bool:
	var snap := GameStateSnapshot.new(10, "sess_1", "PREPARATION")
	snap.resources_data = {
		ResourceLedger.RESOURCE_GOLD: 450,
		ResourceLedger.RESOURCE_MONSTER_CORE: 9,
		ResourceLedger.RESOURCE_MONSTER_MATERIAL: 18,
		ResourceLedger.RESOURCE_BASIC_MATERIAL: 120,
		ResourceLedger.RESOURCE_RARE_MATERIAL: 4
	}

	var serialized: Dictionary = snap.to_dictionary()
	var restored: GameStateSnapshot = GameStateSnapshot.from_dictionary(serialized)

	if int(restored.resources_data.get(ResourceLedger.RESOURCE_GOLD, 0)) != 450:
		return false
	if int(restored.resources_data.get(ResourceLedger.RESOURCE_MONSTER_CORE, 0)) != 9:
		return false
	if int(restored.resources_data.get(ResourceLedger.RESOURCE_BASIC_MATERIAL, 0)) != 120:
		return false
	return true


# ==============================================================================
# GROUP E: GAME CONTROLLER DELEGATION & COMPATIBILITY WITH EXISTING SINKS
# ==============================================================================

func _test_e1_game_controller_delegates_all_resource_methods() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]
	var coord: GameCoordinator = s["coordinator"]

	if ctrl.get_resource(ResourceLedger.RESOURCE_GOLD) != 150:
		_cleanup_session(s)
		return false
	if ctrl.get_monster_cores() != 0:
		_cleanup_session(s)
		return false

	ctrl.add_resource(ResourceLedger.RESOURCE_BASIC_MATERIAL, 50)
	if ctrl.get_basic_materials() != 50:
		_cleanup_session(s)
		return false
	if coord.get_basic_materials() != 50:
		_cleanup_session(s)
		return false

	ctrl.spend_resource(ResourceLedger.RESOURCE_BASIC_MATERIAL, 20)
	if ctrl.get_basic_materials() != 30:
		_cleanup_session(s)
		return false

	var can_spend: bool = ctrl.can_afford_resources({
		ResourceLedger.RESOURCE_GOLD: 100,
		ResourceLedger.RESOURCE_BASIC_MATERIAL: 30
	})
	if not can_spend:
		_cleanup_session(s)
		return false

	ctrl.spend_resources({
		ResourceLedger.RESOURCE_GOLD: 50,
		ResourceLedger.RESOURCE_BASIC_MATERIAL: 10
	})
	if ctrl.get_resource(ResourceLedger.RESOURCE_GOLD) != 100:
		_cleanup_session(s)
		return false
	if ctrl.get_basic_materials() != 20:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_e2_hero_recruitment_spends_500_gold_from_ledger() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var ctrl: GameController = s["controller"]

	# Isi kas cukup untuk merekrut hero (500 gold)
	coord.set_treasury_gold(600)
	var hero_count_before: int = coord._heroes.size()

	var recruited = ctrl.recruit_hero(HeroRole.MAGE)
	if recruited == null:
		_cleanup_session(s)
		return false
	if coord._heroes.size() != hero_count_before + 1:
		_cleanup_session(s)
		return false
	# Saldo harus berkurang tepat 500 gold di single source of truth ledger
	if coord.get_resource(ResourceLedger.RESOURCE_GOLD) != 100:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_e3_hero_ascension_spends_star_x_150_gold_from_ledger() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var ctrl: GameController = s["controller"]

	# Alder Ironclad (hero_alder): star 1, level 1, butuh dinaikkan ke level 10 & 150 gold
	var alder: HeroModel = coord._heroes[0]
	alder.level = 10
	coord.set_treasury_gold(300)

	var ok: bool = ctrl.ascend_hero(alder.hero_id)
	if not ok:
		_cleanup_session(s)
		return false
	if alder.current_star != 2:
		_cleanup_session(s)
		return false
	# Biaya ascension = 1 * 150 = 150 gold
	if coord.get_resource(ResourceLedger.RESOURCE_GOLD) != 150:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_e4_structure_repair_spends_gold_from_ledger() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var ctrl: GameController = s["controller"]

	coord.set_treasury_gold(500)
	ctrl.allocate_workers(2, 0, 0)
	coord._fortress.current_hp = 900
	var cost: int = int(ceil(50 * 0.15)) # 8 gold

	var repaired: bool = ctrl.repair_structure("FORTRESS", 50)
	if not repaired:
		_cleanup_session(s)
		return false
	if coord.get_resource(ResourceLedger.RESOURCE_GOLD) != (500 - cost):
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_e5_equipment_repair_and_blacksmith_discount_from_ledger() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var ctrl: GameController = s["controller"]

	coord.set_treasury_gold(500)
	# Alokasikan pandai besi untuk mendapatkan diskon
	ctrl.allocate_workers(0, 2, 0)
	# Buat equipment rusak di warehouse
	coord._warehouse[0].durability = 50 # SWORD rusak 50 poin
	var repair_cost: int = coord.get_equipment_repair_cost("SWORD", 1)

	var ok: bool = ctrl.repair_equipment("SWORD", 1)
	if not ok:
		_cleanup_session(s)
		return false
	if coord.get_resource(ResourceLedger.RESOURCE_GOLD) != (500 - repair_cost):
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


func _test_e6_deterministic_100_transaction_stress_simulation() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var ctrl: GameController = s["controller"]

	coord.set_treasury_gold(1000)

	# 100 deterministic transactions
	for i in range(1, 101):
		var add_gold: int = (i * 7) % 53
		var add_core: int = 1 if i % 10 == 0 else 0
		var add_basic: int = (i * 3) % 17

		ctrl.add_resources({
			ResourceLedger.RESOURCE_GOLD: add_gold,
			ResourceLedger.RESOURCE_MONSTER_CORE: add_core,
			ResourceLedger.RESOURCE_BASIC_MATERIAL: add_basic
		})

		var spend_gold: int = (i * 5) % 31
		var spend_basic: int = (i * 2) % 9

		if ctrl.can_afford_resources({
			ResourceLedger.RESOURCE_GOLD: spend_gold,
			ResourceLedger.RESOURCE_BASIC_MATERIAL: spend_basic
		}):
			ctrl.spend_resources({
				ResourceLedger.RESOURCE_GOLD: spend_gold,
				ResourceLedger.RESOURCE_BASIC_MATERIAL: spend_basic
			})

		# Enforce invariant validity after each step
		if not coord.get_resource_ledger().validate_invariants():
			_cleanup_session(s)
			return false

	_cleanup_session(s)
	return true
