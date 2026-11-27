extends SceneTree

## TestPhase5FortressManagement
## Test suite komprehensif untuk Phase 5 — Fortress & Management Systems.
## Menguji:
## - Group A: Fortress & Wall/Gate Defense (Tests 1-14)
## - Group B: Population Accounting & Conservation (Tests 15-25)
## - Group C: Worker Allocation, Jobs & Productivity (Tests 26-41)
## - Group D: Building & Facility Foundation (Tests 42-51)
## - Group E: Repair System Foundation (Tests 52-62)
## - Group F: Construction System Foundation (Tests 63-69)
## - Group G: UI, Controller, Snapshot & Battle Lock (Tests 70-81)
## - Group H: Deterministic 100-Cycle Management Stress Simulation (Test 82)

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const PrototypeDebugView = preload("res://scripts/presentation/views/prototype_debug_view.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const FortressModel = preload("res://scripts/domain/model/fortress_model.gd")
const PopulationModel = preload("res://scripts/domain/model/population_model.gd")
const WorkerModel = preload("res://scripts/domain/model/worker_model.gd")
const BuildingModel = preload("res://scripts/domain/model/building_model.gd")
const GameStateSnapshot = preload("res://scripts/domain/state/game_state_snapshot.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 5 FORTRESS & MANAGEMENT SYSTEMS TESTS")
	print("================================================================")

	var tests: Array[Dictionary] = [
		# Group A: Fortress & Wall/Gate Defense
		{"name": "test_a1_fortress_initial_state_valid", "fn": Callable(self, "_test_a1_fortress_initial_state_valid")},
		{"name": "test_a2_fortress_hp_invariants_strictly_enforced", "fn": Callable(self, "_test_a2_fortress_hp_invariants_strictly_enforced")},
		{"name": "test_a3_fortress_take_damage_absorbs_armor", "fn": Callable(self, "_test_a3_fortress_take_damage_absorbs_armor")},
		{"name": "test_a4_fortress_repair_heals_up_to_max_hp", "fn": Callable(self, "_test_a4_fortress_repair_heals_up_to_max_hp")},
		{"name": "test_a5_fortress_destruction_detection", "fn": Callable(self, "_test_a5_fortress_destruction_detection")},
		{"name": "test_a6_wall_initial_state_and_invariants", "fn": Callable(self, "_test_a6_wall_initial_state_and_invariants")},
		{"name": "test_a7_wall_damage_reduces_hp_accurately", "fn": Callable(self, "_test_a7_wall_damage_reduces_hp_accurately")},
		{"name": "test_a8_wall_repair_caps_at_wall_max_hp", "fn": Callable(self, "_test_a8_wall_repair_caps_at_wall_max_hp")},
		{"name": "test_a9_wall_breach_detection", "fn": Callable(self, "_test_a9_wall_breach_detection")},
		{"name": "test_a10_gate_initial_state_and_invariants", "fn": Callable(self, "_test_a10_gate_initial_state_and_invariants")},
		{"name": "test_a11_gate_damage_reduces_hp_accurately", "fn": Callable(self, "_test_a11_gate_damage_reduces_hp_accurately")},
		{"name": "test_a12_gate_repair_caps_at_gate_max_hp", "fn": Callable(self, "_test_a12_gate_repair_caps_at_gate_max_hp")},
		{"name": "test_a13_gate_breach_detection", "fn": Callable(self, "_test_a13_gate_breach_detection")},
		{"name": "test_a14_negative_damage_and_repair_rejected", "fn": Callable(self, "_test_a14_negative_damage_and_repair_rejected")},

		# Group B: Population Accounting & Conservation
		{"name": "test_b1_population_initial_counts_valid", "fn": Callable(self, "_test_b1_population_initial_counts_valid")},
		{"name": "test_b2_civilian_to_soldier_conversion_zero_sum", "fn": Callable(self, "_test_b2_civilian_to_soldier_conversion_zero_sum")},
		{"name": "test_b3_civilian_to_worker_conversion_zero_sum", "fn": Callable(self, "_test_b3_civilian_to_worker_conversion_zero_sum")},
		{"name": "test_b4_worker_to_civilian_conversion_zero_sum", "fn": Callable(self, "_test_b4_worker_to_civilian_conversion_zero_sum")},
		{"name": "test_b5_population_conservation_invariant_strictly_maintained", "fn": Callable(self, "_test_b5_population_conservation_invariant_strictly_maintained")},
		{"name": "test_b6_soldier_casualty_reduces_population_permanently", "fn": Callable(self, "_test_b6_soldier_casualty_reduces_population_permanently")},
		{"name": "test_b7_over_allocation_and_conversion_rejected", "fn": Callable(self, "_test_b7_over_allocation_and_conversion_rejected")},
		{"name": "test_b8_negative_conversion_counts_rejected", "fn": Callable(self, "_test_b8_negative_conversion_counts_rejected")},
		{"name": "test_b9_population_growth_respects_capacity_and_morale", "fn": Callable(self, "_test_b9_population_growth_respects_capacity_and_morale")},
		{"name": "test_b10_population_model_clone_isolation", "fn": Callable(self, "_test_b10_population_model_clone_isolation")},
		{"name": "test_b11_population_invariants_validation", "fn": Callable(self, "_test_b11_population_invariants_validation")},

		# Group C: Worker Allocation, Jobs & Productivity
		{"name": "test_c1_worker_model_initial_state_idle", "fn": Callable(self, "_test_c1_worker_model_initial_state_idle")},
		{"name": "test_c2_worker_allocation_to_four_canonical_jobs", "fn": Callable(self, "_test_c2_worker_allocation_to_four_canonical_jobs")},
		{"name": "test_c3_worker_conservation_assigned_plus_idle_equals_total", "fn": Callable(self, "_test_c3_worker_conservation_assigned_plus_idle_equals_total")},
		{"name": "test_c4_worker_reassign_between_jobs", "fn": Callable(self, "_test_c4_worker_reassign_between_jobs")},
		{"name": "test_c5_worker_allocation_exceeding_total_rejected_atomically", "fn": Callable(self, "_test_c5_worker_allocation_exceeding_total_rejected_atomically")},
		{"name": "test_c6_worker_negative_allocation_rejected", "fn": Callable(self, "_test_c6_worker_negative_allocation_rejected")},
		{"name": "test_c7_worker_reassign_invalid_job_rejected", "fn": Callable(self, "_test_c7_worker_reassign_invalid_job_rejected")},
		{"name": "test_c8_worker_reassign_insufficient_job_count_rejected", "fn": Callable(self, "_test_c8_worker_reassign_insufficient_job_count_rejected")},
		{"name": "test_c9_worker_sync_total_workers_increase_routes_to_idle", "fn": Callable(self, "_test_c9_worker_sync_total_workers_increase_routes_to_idle")},
		{"name": "test_c10_worker_sync_total_workers_decrease_scales_down_safely", "fn": Callable(self, "_test_c10_worker_sync_total_workers_decrease_scales_down_safely")},
		{"name": "test_c11_worker_morale_boundary_clamped_zero_to_hundred", "fn": Callable(self, "_test_c11_worker_morale_boundary_clamped_zero_to_hundred")},
		{"name": "test_c12_worker_productivity_derived_from_morale", "fn": Callable(self, "_test_c12_worker_productivity_derived_from_morale")},
		{"name": "test_c13_worker_no_duplicate_workers_possible", "fn": Callable(self, "_test_c13_worker_no_duplicate_workers_possible")},
		{"name": "test_c14_worker_model_clone_isolation", "fn": Callable(self, "_test_c14_worker_model_clone_isolation")},
		{"name": "test_c15_worker_model_to_and_from_dictionary", "fn": Callable(self, "_test_c15_worker_model_to_and_from_dictionary")},
		{"name": "test_c16_worker_model_invariants_validation", "fn": Callable(self, "_test_c16_worker_model_invariants_validation")},

		# Group D: Building & Facility Foundation
		{"name": "test_d1_nine_canonical_buildings_initialized", "fn": Callable(self, "_test_d1_nine_canonical_buildings_initialized")},
		{"name": "test_d2_valid_building_types_validated", "fn": Callable(self, "_test_d2_valid_building_types_validated")},
		{"name": "test_d3_invalid_building_type_rejected_by_validation", "fn": Callable(self, "_test_d3_invalid_building_type_rejected_by_validation")},
		{"name": "test_d4_building_upgrade_increments_level", "fn": Callable(self, "_test_d4_building_upgrade_increments_level")},
		{"name": "test_d5_building_upgrade_capped_at_max_level", "fn": Callable(self, "_test_d5_building_upgrade_capped_at_max_level")},
		{"name": "test_d6_cannot_upgrade_unbuilt_or_max_level_building", "fn": Callable(self, "_test_d6_cannot_upgrade_unbuilt_or_max_level_building")},
		{"name": "test_d7_query_building_by_id", "fn": Callable(self, "_test_d7_query_building_by_id")},
		{"name": "test_d8_query_all_buildings_returns_canonical_list", "fn": Callable(self, "_test_d8_query_all_buildings_returns_canonical_list")},
		{"name": "test_d9_building_clone_complete_isolation", "fn": Callable(self, "_test_d9_building_clone_complete_isolation")},
		{"name": "test_d10_building_to_and_from_dictionary_preserves_state", "fn": Callable(self, "_test_d10_building_to_and_from_dictionary_preserves_state")},

		# Group E: Repair System Foundation
		{"name": "test_e1_repair_valid_structure_fortress", "fn": Callable(self, "_test_e1_repair_valid_structure_fortress")},
		{"name": "test_e2_repair_valid_structure_wall", "fn": Callable(self, "_test_e2_repair_valid_structure_wall")},
		{"name": "test_e3_repair_valid_structure_gate", "fn": Callable(self, "_test_e3_repair_valid_structure_gate")},
		{"name": "test_e4_repair_rejected_when_target_at_max_hp", "fn": Callable(self, "_test_e4_repair_rejected_when_target_at_max_hp")},
		{"name": "test_e5_repair_rejected_when_no_repair_workers", "fn": Callable(self, "_test_e5_repair_rejected_when_no_repair_workers")},
		{"name": "test_e6_repair_cost_formula_matches_fifteen_percent_gold_per_hp", "fn": Callable(self, "_test_e6_repair_cost_formula_matches_fifteen_percent_gold_per_hp")},
		{"name": "test_e7_repair_rejected_when_insufficient_treasury_gold", "fn": Callable(self, "_test_e7_repair_rejected_when_insufficient_treasury_gold")},
		{"name": "test_e8_repair_atomic_deduction_and_healing", "fn": Callable(self, "_test_e8_repair_atomic_deduction_and_healing")},
		{"name": "test_e9_repair_caps_healing_at_needed_hp", "fn": Callable(self, "_test_e9_repair_caps_healing_at_needed_hp")},
		{"name": "test_e10_repair_invalid_target_rejected", "fn": Callable(self, "_test_e10_repair_invalid_target_rejected")},
		{"name": "test_e11_repair_active_data_recorded_in_snapshot", "fn": Callable(self, "_test_e11_repair_active_data_recorded_in_snapshot")},

		# Group F: Construction System Foundation
		{"name": "test_f1_start_construction_valid_building", "fn": Callable(self, "_test_f1_start_construction_valid_building")},
		{"name": "test_f2_start_construction_rejected_without_construction_workers", "fn": Callable(self, "_test_f2_start_construction_rejected_without_construction_workers")},
		{"name": "test_f3_start_construction_rejected_when_treasury_insufficient", "fn": Callable(self, "_test_f3_start_construction_rejected_when_treasury_insufficient")},
		{"name": "test_f4_advance_construction_increments_progress", "fn": Callable(self, "_test_f4_advance_construction_increments_progress")},
		{"name": "test_f5_advance_construction_completes_and_upgrades_building", "fn": Callable(self, "_test_f5_advance_construction_completes_and_upgrades_building")},
		{"name": "test_f6_cancel_construction_refunds_gold_safely", "fn": Callable(self, "_test_f6_cancel_construction_refunds_gold_safely")},
		{"name": "test_f7_start_construction_invalid_building_rejected", "fn": Callable(self, "_test_f7_start_construction_invalid_building_rejected")},

		# Group G: UI, Controller, Snapshot & Battle Lock
		{"name": "test_g1_controller_delegates_population_conversion", "fn": Callable(self, "_test_g1_controller_delegates_population_conversion")},
		{"name": "test_g2_controller_delegates_worker_reassign", "fn": Callable(self, "_test_g2_controller_delegates_worker_reassign")},
		{"name": "test_g3_controller_delegates_repair_structure", "fn": Callable(self, "_test_g3_controller_delegates_repair_structure")},
		{"name": "test_g4_controller_delegates_construction", "fn": Callable(self, "_test_g4_controller_delegates_construction")},
		{"name": "test_g5_snapshot_contains_all_phase5_fields", "fn": Callable(self, "_test_g5_snapshot_contains_all_phase5_fields")},
		{"name": "test_g6_snapshot_clone_complete_isolation_phase5", "fn": Callable(self, "_test_g6_snapshot_clone_complete_isolation_phase5")},
		{"name": "test_g7_battle_lock_blocks_worker_allocation", "fn": Callable(self, "_test_g7_battle_lock_blocks_worker_allocation")},
		{"name": "test_g8_battle_lock_blocks_population_conversion", "fn": Callable(self, "_test_g8_battle_lock_blocks_population_conversion")},
		{"name": "test_g9_battle_lock_blocks_structure_repair", "fn": Callable(self, "_test_g9_battle_lock_blocks_structure_repair")},
		{"name": "test_g10_battle_lock_blocks_construction_actions", "fn": Callable(self, "_test_g10_battle_lock_blocks_construction_actions")},
		{"name": "test_g11_battle_lock_blocks_building_upgrade", "fn": Callable(self, "_test_g11_battle_lock_blocks_building_upgrade")},
		{"name": "test_g12_ui_start_battle_button_disabled_in_phase5", "fn": Callable(self, "_test_g12_ui_start_battle_button_disabled_in_phase5")},

		# Group H: Deterministic 100-Cycle Management Stress Simulation
		{"name": "test_h1_deterministic_100_cycle_management_stress_simulation", "fn": Callable(self, "_test_h1_deterministic_100_cycle_management_stress_simulation")}
	]

	var passed: int = 0
	var failed: int = 0

	for t in tests:
		print("[TEST] Running %s..." % t["name"])
		var result: bool = false
		var fn: Callable = t["fn"]
		result = fn.call()
		if result:
			passed += 1
			print("[PASS] %s" % t["name"])
		else:
			failed += 1
			printerr("[FAIL] %s" % t["name"])

	print("================================================================")
	print("PHASE 5 TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("================================================================")

	for c in root.get_children():
		root.remove_child(c)
		c.free()

	if failed == 0:
		quit(0)
	else:
		quit(1)


# ==============================================================================
# TEST SESSION HELPERS
# ==============================================================================

func _create_test_session() -> Dictionary:
	var coord := GameCoordinator.new()
	coord.start_new_session("session_phase5_test", 9999)
	var ctrl := GameController.new()
	var view := PrototypeDebugView.new()
	root.add_child(ctrl)
	root.add_child(view)
	ctrl.setup(coord)
	view.setup(coord, ctrl)
	return {"coordinator": coord, "controller": ctrl, "view": view}


func _cleanup_session(s: Dictionary) -> void:
	if s.has("view") and s["view"] != null and is_instance_valid(s["view"]):
		var v: Node = s["view"]
		if v.get_parent() != null:
			v.get_parent().remove_child(v)
		v.free()
	if s.has("controller") and s["controller"] != null and is_instance_valid(s["controller"]):
		var c: Node = s["controller"]
		if c.get_parent() != null:
			c.get_parent().remove_child(c)
		c.free()


# ==============================================================================
# GROUP A: FORTRESS & WALL/GATE DEFENSE
# ==============================================================================

func _test_a1_fortress_initial_state_valid() -> bool:
	var f := FortressModel.new(1000, 40, 500, 300)
	var ok: bool = (f.max_hp == 1000 and f.current_hp == 1000)
	ok = ok and (f.armor == 40 and f.upgrade_tier == 1)
	ok = ok and (f.wall_max_hp == 500 and f.wall_hp == 500)
	ok = ok and (f.gate_max_hp == 300 and f.gate_hp == 300)
	ok = ok and (not f.is_destroyed() and not f.is_wall_breached() and not f.is_gate_breached())
	return ok


func _test_a2_fortress_hp_invariants_strictly_enforced() -> bool:
	var f := FortressModel.new(1000, 40)
	var ok: bool = f.validate_invariants()
	f.current_hp = 1200 # Over max
	ok = ok and (not f.validate_invariants())
	f.current_hp = -10 # Negative
	ok = ok and (not f.validate_invariants())
	f.current_hp = 500
	ok = ok and f.validate_invariants()
	return ok


func _test_a3_fortress_take_damage_absorbs_armor() -> bool:
	var f := FortressModel.new(1000, 40)
	# Raw damage 100 absorbed by armor 40 / 190 (~21.05% absorption -> ~78 actual damage)
	var dmg: int = f.take_damage(100)
	var ok: bool = (dmg > 0 and dmg < 100)
	ok = ok and (f.current_hp == 1000 - dmg)
	return ok


func _test_a4_fortress_repair_heals_up_to_max_hp() -> bool:
	var f := FortressModel.new(1000, 40)
	f.current_hp = 800
	var rep: int = f.repair(150)
	var ok: bool = (rep == 150 and f.current_hp == 950)
	var rep_over: int = f.repair(100) # Only 50 needed
	ok = ok and (rep_over == 50 and f.current_hp == 1000)
	return ok


func _test_a5_fortress_destruction_detection() -> bool:
	var f := FortressModel.new(1000, 40)
	var ok: bool = (not f.is_destroyed())
	f.current_hp = 0
	ok = ok and f.is_destroyed()
	# Damage on destroyed fortress does 0 damage
	ok = ok and (f.take_damage(50) == 0)
	ok = ok and (f.repair(50) == 0)
	return ok


func _test_a6_wall_initial_state_and_invariants() -> bool:
	var f := FortressModel.new(1000, 40, 600, 350)
	var ok: bool = (f.wall_hp == 600 and f.wall_max_hp == 600)
	ok = ok and (not f.is_wall_breached())
	ok = ok and f.validate_invariants()
	return ok


func _test_a7_wall_damage_reduces_hp_accurately() -> bool:
	var f := FortressModel.new(1000, 40, 500, 300)
	var dmg: int = f.damage_wall(200)
	var ok: bool = (dmg == 200 and f.wall_hp == 300)
	var dmg_excess: int = f.damage_wall(400) # Only 300 left
	ok = ok and (dmg_excess == 300 and f.wall_hp == 0)
	return ok


func _test_a8_wall_repair_caps_at_wall_max_hp() -> bool:
	var f := FortressModel.new(1000, 40, 500, 300)
	f.wall_hp = 400
	var rep: int = f.repair_wall(50)
	var ok: bool = (rep == 50 and f.wall_hp == 450)
	var rep_over: int = f.repair_wall(100) # Only 50 needed to reach 500
	ok = ok and (rep_over == 50 and f.wall_hp == 500)
	return ok


func _test_a9_wall_breach_detection() -> bool:
	var f := FortressModel.new(1000, 40, 500, 300)
	var ok: bool = (not f.is_wall_breached())
	f.damage_wall(500)
	ok = ok and f.is_wall_breached()
	return ok


func _test_a10_gate_initial_state_and_invariants() -> bool:
	var f := FortressModel.new(1000, 40, 500, 300)
	var ok: bool = (f.gate_hp == 300 and f.gate_max_hp == 300)
	ok = ok and (not f.is_gate_breached())
	ok = ok and f.validate_invariants()
	return ok


func _test_a11_gate_damage_reduces_hp_accurately() -> bool:
	var f := FortressModel.new(1000, 40, 500, 300)
	var dmg: int = f.damage_gate(120)
	var ok: bool = (dmg == 120 and f.gate_hp == 180)
	var dmg_excess: int = f.damage_gate(300) # Only 180 left
	ok = ok and (dmg_excess == 180 and f.gate_hp == 0)
	return ok


func _test_a12_gate_repair_caps_at_gate_max_hp() -> bool:
	var f := FortressModel.new(1000, 40, 500, 300)
	f.gate_hp = 250
	var rep: int = f.repair_gate(30)
	var ok: bool = (rep == 30 and f.gate_hp == 280)
	var rep_over: int = f.repair_gate(50) # Only 20 needed to reach 300
	ok = ok and (rep_over == 20 and f.gate_hp == 300)
	return ok


func _test_a13_gate_breach_detection() -> bool:
	var f := FortressModel.new(1000, 40, 500, 300)
	var ok: bool = (not f.is_gate_breached())
	f.damage_gate(300)
	ok = ok and f.is_gate_breached()
	return ok


func _test_a14_negative_damage_and_repair_rejected() -> bool:
	var f := FortressModel.new(1000, 40, 500, 300)
	var ok: bool = (f.take_damage(-50) == 0 and f.current_hp == 1000)
	ok = ok and (f.repair(-50) == 0 and f.current_hp == 1000)
	ok = ok and (f.damage_wall(-50) == 0 and f.wall_hp == 500)
	ok = ok and (f.repair_wall(-50) == 0 and f.wall_hp == 500)
	ok = ok and (f.damage_gate(-50) == 0 and f.gate_hp == 300)
	ok = ok and (f.repair_gate(-50) == 0 and f.gate_hp == 300)
	return ok


# ==============================================================================
# GROUP B: POPULATION ACCOUNTING & CONSERVATION
# ==============================================================================

func _test_b1_population_initial_counts_valid() -> bool:
	var pop := PopulationModel.new(15, 30, 100, 5)
	var ok: bool = (pop.get_civilian_count() == 15)
	ok = ok and (pop.get_worker_count() == 5)
	ok = ok and (pop.get_soldier_count() == 0)
	ok = ok and (pop.get_total_population() == 20)
	return ok


func _test_b2_civilian_to_soldier_conversion_zero_sum() -> bool:
	var pop := PopulationModel.new(20, 30, 100, 0)
	var ok: bool = pop.recruit_soldier("SWORDSMAN", 5)
	ok = ok and (pop.get_civilian_count() == 15)
	ok = ok and (pop.get_soldier_count() == 5)
	ok = ok and (pop.get_total_population() == 20)
	return ok


func _test_b3_civilian_to_worker_conversion_zero_sum() -> bool:
	var pop := PopulationModel.new(20, 30, 100, 0)
	var ok: bool = pop.civilian_to_worker(6)
	ok = ok and (pop.get_civilian_count() == 14)
	ok = ok and (pop.get_worker_count() == 6)
	ok = ok and (pop.get_total_population() == 20)
	return ok


func _test_b4_worker_to_civilian_conversion_zero_sum() -> bool:
	var pop := PopulationModel.new(14, 30, 100, 6)
	var ok: bool = pop.worker_to_civilian(4)
	ok = ok and (pop.get_civilian_count() == 18)
	ok = ok and (pop.get_worker_count() == 2)
	ok = ok and (pop.get_total_population() == 20)
	return ok


func _test_b5_population_conservation_invariant_strictly_maintained() -> bool:
	var pop := PopulationModel.new(100, 150, 100, 0)
	pop.civilian_to_worker(30)
	pop.recruit_soldier("SWORDSMAN", 20)
	pop.recruit_soldier("ARCHER", 10)
	var civ: int = pop.get_civilian_count() # 40
	var wrk: int = pop.get_worker_count()   # 30
	var sld: int = pop.get_soldier_count()  # 30
	var ok: bool = (civ + wrk + sld == 100)
	ok = ok and (pop.get_total_population() == 100)
	return ok


func _test_b6_soldier_casualty_reduces_population_permanently() -> bool:
	var pop := PopulationModel.new(70, 150, 100, 30)
	pop.recruit_soldier("SWORDSMAN", 30)
	var dead: int = pop.apply_casualties({"SWORDSMAN": 10})
	var ok: bool = (dead == 10)
	ok = ok and (pop.get_soldier_count() == 20)
	ok = ok and (pop.get_civilian_count() == 40)
	ok = ok and (pop.get_worker_count() == 30)
	ok = ok and (pop.get_total_population() == 90) # Reduced from 100 to 90
	return ok


func _test_b7_over_allocation_and_conversion_rejected() -> bool:
	var pop := PopulationModel.new(10, 30, 100, 5)
	var fail_sol: bool = pop.recruit_soldier("SWORDSMAN", 15) # Only 10 civs
	var fail_wrk: bool = pop.civilian_to_worker(12)           # Only 10 civs
	var fail_rev: bool = pop.worker_to_civilian(8)            # Only 5 wrks
	var ok: bool = (not fail_sol and not fail_wrk and not fail_rev)
	ok = ok and (pop.get_civilian_count() == 10 and pop.get_worker_count() == 5)
	return ok


func _test_b8_negative_conversion_counts_rejected() -> bool:
	var pop := PopulationModel.new(15, 30, 100, 5)
	var f1: bool = pop.recruit_soldier("SWORDSMAN", -2)
	var f2: bool = pop.civilian_to_worker(-5)
	var f3: bool = pop.worker_to_civilian(-3)
	var ok: bool = (not f1 and not f2 and not f3)
	ok = ok and (pop.get_civilian_count() == 15 and pop.get_worker_count() == 5)
	return ok


func _test_b9_population_growth_respects_capacity_and_morale() -> bool:
	var pop := PopulationModel.new(10, 30, 100, 5)
	var grown: int = pop.grow_population(0.10)
	var ok: bool = (grown > 0 and pop.get_civilian_count() == 10 + grown)
	# At full housing capacity, growth returns 0
	pop.civilians = 25 # 25 civ + 5 wrk = 30 (cap)
	ok = ok and (pop.grow_population(0.10) == 0)
	# Low morale (<50) stops growth
	pop.civilians = 10
	pop.morale = 40
	ok = ok and (pop.grow_population(0.10) == 0)
	return ok


func _test_b10_population_model_clone_isolation() -> bool:
	var p1 := PopulationModel.new(15, 30, 100, 5)
	p1.recruit_soldier("SWORDSMAN", 3)
	var p2: PopulationModel = p1.clone()
	p2.civilian_to_worker(2)
	p2.recruit_soldier("ARCHER", 2)
	var ok: bool = (p1.get_worker_count() == 5 and p2.get_worker_count() == 7)
	ok = ok and (p1.soldiers["ARCHER"] == 0 and p2.soldiers["ARCHER"] == 2)
	return ok


func _test_b11_population_invariants_validation() -> bool:
	var pop := PopulationModel.new(10, 30, 100, 5)
	var ok: bool = pop.validate_invariants()
	pop.civilians = -1
	ok = ok and (not pop.validate_invariants())
	pop.civilians = 10
	pop.workers = -2
	ok = ok and (not pop.validate_invariants())
	return ok


# ==============================================================================
# GROUP C: WORKER ALLOCATION, JOBS & PRODUCTIVITY
# ==============================================================================

func _test_c1_worker_model_initial_state_idle() -> bool:
	var wm := WorkerModel.new(10, 100)
	var ok: bool = (wm.total_workers == 10 and wm.idle_workers == 10)
	ok = ok and (wm.blacksmith_workers == 0 and wm.repair_workers == 0 and wm.construction_workers == 0)
	ok = ok and (wm.get_assigned_workers() == 0)
	ok = ok and (wm.morale == 100 and wm.get_productivity() == 1.0)
	return ok


func _test_c2_worker_allocation_to_four_canonical_jobs() -> bool:
	var wm := WorkerModel.new(10, 100)
	var ok: bool = wm.set_allocations(3, 4, 2) # 3 Rep, 4 Smith, 2 Constr -> 9 assigned, 1 idle
	ok = ok and (wm.repair_workers == 3 and wm.blacksmith_workers == 4 and wm.construction_workers == 2)
	ok = ok and (wm.idle_workers == 1)
	return ok


func _test_c3_worker_conservation_assigned_plus_idle_equals_total() -> bool:
	var wm := WorkerModel.new(20, 100)
	wm.set_allocations(5, 7, 3)
	var ok: bool = (wm.get_assigned_workers() + wm.idle_workers == wm.total_workers)
	ok = ok and (wm.get_job_count(WorkerModel.JOB_REPAIR) == 5)
	ok = ok and (wm.get_job_count(WorkerModel.JOB_BLACKSMITH) == 7)
	ok = ok and (wm.get_job_count(WorkerModel.JOB_CONSTRUCTION) == 3)
	ok = ok and (wm.get_job_count(WorkerModel.JOB_IDLE) == 5)
	return ok


func _test_c4_worker_reassign_between_jobs() -> bool:
	var wm := WorkerModel.new(10, 100)
	wm.set_allocations(2, 3, 1) # 2 rep, 3 smith, 1 constr, 4 idle
	var ok: bool = wm.reassign(WorkerModel.JOB_BLACKSMITH, WorkerModel.JOB_REPAIR, 2)
	ok = ok and (wm.blacksmith_workers == 1 and wm.repair_workers == 4)
	ok = ok and (wm.reassign(WorkerModel.JOB_IDLE, WorkerModel.JOB_CONSTRUCTION, 3))
	ok = ok and (wm.idle_workers == 1 and wm.construction_workers == 4)
	ok = ok and (wm.get_assigned_workers() + wm.idle_workers == wm.total_workers)
	return ok


func _test_c5_worker_allocation_exceeding_total_rejected_atomically() -> bool:
	var wm := WorkerModel.new(10, 100)
	wm.set_allocations(2, 2, 2) # 6 assigned, 4 idle
	var fail: bool = wm.set_allocations(5, 5, 5) # 15 > 10
	var ok: bool = (not fail)
	# State unchanged
	ok = ok and (wm.repair_workers == 2 and wm.blacksmith_workers == 2 and wm.construction_workers == 2 and wm.idle_workers == 4)
	return ok


func _test_c6_worker_negative_allocation_rejected() -> bool:
	var wm := WorkerModel.new(10, 100)
	var fail: bool = wm.set_allocations(-1, 2, 2)
	return not fail


func _test_c7_worker_reassign_invalid_job_rejected() -> bool:
	var wm := WorkerModel.new(10, 100)
	wm.set_allocations(2, 2, 2)
	var fail: bool = wm.reassign("FARMING", WorkerModel.JOB_REPAIR, 1)
	return not fail


func _test_c8_worker_reassign_insufficient_job_count_rejected() -> bool:
	var wm := WorkerModel.new(10, 100)
	wm.set_allocations(2, 2, 2) # only 2 smiths
	var fail: bool = wm.reassign(WorkerModel.JOB_BLACKSMITH, WorkerModel.JOB_REPAIR, 5)
	return not fail


func _test_c9_worker_sync_total_workers_increase_routes_to_idle() -> bool:
	var wm := WorkerModel.new(10, 100)
	wm.set_allocations(2, 3, 1) # 6 assigned, 4 idle
	wm.sync_total_workers(15) # +5 workers
	var ok: bool = (wm.total_workers == 15 and wm.idle_workers == 9)
	ok = ok and (wm.repair_workers == 2 and wm.blacksmith_workers == 3 and wm.construction_workers == 1)
	return ok


func _test_c10_worker_sync_total_workers_decrease_scales_down_safely() -> bool:
	var wm := WorkerModel.new(10, 100)
	wm.set_allocations(4, 4, 2) # 10 assigned, 0 idle
	wm.sync_total_workers(5)    # Reduced to 5
	var ok: bool = (wm.total_workers == 5 and wm.idle_workers == 0)
	ok = ok and (wm.get_assigned_workers() == 5)
	return ok


func _test_c11_worker_morale_boundary_clamped_zero_to_hundred() -> bool:
	var wm := WorkerModel.new(10, 100)
	wm.modify_morale(50) # clamp at 100
	var ok: bool = (wm.morale == 100)
	wm.modify_morale(-150) # clamp at 0
	ok = ok and (wm.morale == 0)
	wm.modify_morale(75)
	ok = ok and (wm.morale == 75)
	return ok


func _test_c12_worker_productivity_derived_from_morale() -> bool:
	var wm := WorkerModel.new(10, 100)
	var ok: bool = is_equal_approx(wm.get_productivity(), 1.0)
	wm.morale = 50
	ok = ok and is_equal_approx(wm.get_productivity(), 0.5)
	wm.morale = 0
	ok = ok and is_equal_approx(wm.get_productivity(), 0.5) # Minimum bound 0.5
	return ok


func _test_c13_worker_no_duplicate_workers_possible() -> bool:
	var wm := WorkerModel.new(15, 100)
	wm.set_allocations(3, 5, 2) # 10 assigned, 5 idle
	var sum: int = wm.repair_workers + wm.blacksmith_workers + wm.construction_workers + wm.idle_workers
	return (sum == wm.total_workers and sum == 15)


func _test_c14_worker_model_clone_isolation() -> bool:
	var w1 := WorkerModel.new(10, 100)
	w1.set_allocations(2, 3, 1)
	var w2: WorkerModel = w1.clone()
	w2.set_allocations(4, 4, 0)
	w2.modify_morale(-20)
	var ok: bool = (w1.repair_workers == 2 and w2.repair_workers == 4)
	ok = ok and (w1.morale == 100 and w2.morale == 80)
	return ok


func _test_c15_worker_model_to_and_from_dictionary() -> bool:
	var w1 := WorkerModel.new(12, 90)
	w1.set_allocations(3, 4, 2)
	var dict: Dictionary = w1.to_dictionary()
	var w2 := WorkerModel.from_dictionary(dict)
	var ok: bool = (w2.total_workers == 12 and w2.morale == 90)
	ok = ok and (w2.repair_workers == 3 and w2.blacksmith_workers == 4 and w2.construction_workers == 2 and w2.idle_workers == 3)
	return ok


func _test_c16_worker_model_invariants_validation() -> bool:
	var wm := WorkerModel.new(10, 100)
	wm.set_allocations(2, 3, 1)
	var ok: bool = wm.validate_invariants()
	wm.idle_workers = 10 # Violates sum == total
	ok = ok and (not wm.validate_invariants())
	return ok


# ==============================================================================
# GROUP D: BUILDING & FACILITY FOUNDATION
# ==============================================================================

func _test_d1_nine_canonical_buildings_initialized() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var buildings: Array = coord.get_buildings()
	var ok: bool = (buildings.size() == 9)
	var expected_ids := [
		"fortress_main", "wall_outer", "gate_main", "barracks",
		"blacksmith", "warehouse", "training_facility", "mercenary_guild", "construction_area"
	]
	for id in expected_ids:
		ok = ok and (coord.get_building(id) != null)
	_cleanup_session(s)
	return ok


func _test_d2_valid_building_types_validated() -> bool:
	var ok: bool = BuildingModel.is_valid_type("FORTRESS")
	ok = ok and BuildingModel.is_valid_type("WALL")
	ok = ok and BuildingModel.is_valid_type("GATE")
	ok = ok and BuildingModel.is_valid_type("BARRACKS")
	ok = ok and BuildingModel.is_valid_type("BLACKSMITH")
	ok = ok and BuildingModel.is_valid_type("WAREHOUSE")
	ok = ok and BuildingModel.is_valid_type("TRAINING_FACILITY")
	ok = ok and BuildingModel.is_valid_type("MERCENARY_GUILD")
	ok = ok and BuildingModel.is_valid_type("CONSTRUCTION_AREA")
	return ok


func _test_d3_invalid_building_type_rejected_by_validation() -> bool:
	var ok: bool = (not BuildingModel.is_valid_type("CASINO"))
	ok = ok and (not BuildingModel.is_valid_type("MARKETPLACE"))
	var b := BuildingModel.new("invalid_id", "INVALID_TYPE")
	ok = ok and (not b.validate_invariants())
	return ok


func _test_d4_building_upgrade_increments_level() -> bool:
	var b := BuildingModel.new("barracks", BuildingModel.TYPE_BARRACKS, "Barak Militer", 1, true, 5)
	var ok: bool = b.can_upgrade()
	var upgraded: bool = b.upgrade()
	ok = ok and (upgraded and b.level == 2)
	return ok


func _test_d5_building_upgrade_capped_at_max_level() -> bool:
	var b := BuildingModel.new("blacksmith", BuildingModel.TYPE_BLACKSMITH, "Pandai Besi", 4, true, 5)
	b.upgrade() # Reaches Lv 5
	var ok: bool = (b.level == 5 and not b.can_upgrade())
	var fail: bool = b.upgrade()
	ok = ok and (not fail and b.level == 5)
	return ok


func _test_d6_cannot_upgrade_unbuilt_or_max_level_building() -> bool:
	var b := BuildingModel.new("wh", BuildingModel.TYPE_WAREHOUSE, "Gudang", 1, false, 5)
	return not b.can_upgrade()


func _test_d7_query_building_by_id() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var b: BuildingModel = coord.get_building("training_facility")
	var ok: bool = (b != null and b.building_type == BuildingModel.TYPE_TRAINING_FACILITY)
	var none: BuildingModel = coord.get_building("non_existent_building")
	ok = ok and (none == null)
	_cleanup_session(s)
	return ok


func _test_d8_query_all_buildings_returns_canonical_list() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var list: Array = coord.get_buildings()
	var ok: bool = (list.size() == 9)
	for item in list:
		ok = ok and (item is BuildingModel and (item as BuildingModel).validate_invariants())
	_cleanup_session(s)
	return ok


func _test_d9_building_clone_complete_isolation() -> bool:
	var b1 := BuildingModel.new("b1", BuildingModel.TYPE_WALL, "Tembok", 1, true, 5)
	var b2: BuildingModel = b1.clone()
	b2.upgrade()
	var ok: bool = (b1.level == 1 and b2.level == 2)
	return ok


func _test_d10_building_to_and_from_dictionary_preserves_state() -> bool:
	var b1 := BuildingModel.new("b_gate", BuildingModel.TYPE_GATE, "Gerbang Depan", 3, true, 5)
	var dict: Dictionary = b1.to_dictionary()
	var b2 := BuildingModel.from_dictionary(dict)
	var ok: bool = (b2.building_id == "b_gate" and b2.building_type == BuildingModel.TYPE_GATE)
	ok = ok and (b2.level == 3 and b2.is_built and b2.max_level == 5)
	return ok


# ==============================================================================
# GROUP E: REPAIR SYSTEM FOUNDATION
# ==============================================================================

func _test_e1_repair_valid_structure_fortress() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0) # 2 repair workers
	coord._fortress.current_hp = 900
	var init_gold: int = coord.get_treasury_gold()
	var ok: bool = coord.repair_structure("FORTRESS", 50)
	ok = ok and (coord._fortress.current_hp == 950)
	var cost: int = int(ceil(50 * 0.15))
	ok = ok and (coord.get_treasury_gold() == init_gold - cost)
	_cleanup_session(s)
	return ok


func _test_e2_repair_valid_structure_wall() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0)
	coord._fortress.wall_hp = 400
	var ok: bool = coord.repair_structure("WALL", 60)
	ok = ok and (coord._fortress.wall_hp == 460)
	_cleanup_session(s)
	return ok


func _test_e3_repair_valid_structure_gate() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0)
	coord._fortress.gate_hp = 200
	var ok: bool = coord.repair_structure("GATE", 40)
	ok = ok and (coord._fortress.gate_hp == 240)
	_cleanup_session(s)
	return ok


func _test_e4_repair_rejected_when_target_at_max_hp() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0)
	var fail: bool = coord.repair_structure("FORTRESS", 50) # Already at 1000/1000
	_cleanup_session(s)
	return not fail


func _test_e5_repair_rejected_when_no_repair_workers() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(0, 2, 2) # 0 repair workers
	coord._fortress.current_hp = 800
	var fail: bool = coord.repair_structure("FORTRESS", 50)
	_cleanup_session(s)
	return not fail


func _test_e6_repair_cost_formula_matches_fifteen_percent_gold_per_hp() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0)
	coord._fortress.current_hp = 800
	var gold_pre: int = coord.get_treasury_gold()
	coord.repair_structure("FORTRESS", 100) # 100 HP * 0.15 = 15 Gold
	var gold_post: int = coord.get_treasury_gold()
	var ok: bool = (gold_pre - gold_post == 15)
	_cleanup_session(s)
	return ok


func _test_e7_repair_rejected_when_insufficient_treasury_gold() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0)
	coord._fortress.current_hp = 500
	coord.set_treasury_gold(5) # Not enough for 100 HP (needs 15 Gold)
	var fail: bool = coord.repair_structure("FORTRESS", 100)
	var ok: bool = (not fail and coord._fortress.current_hp == 500 and coord.get_treasury_gold() == 5)
	_cleanup_session(s)
	return ok


func _test_e8_repair_atomic_deduction_and_healing() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0)
	coord._fortress.current_hp = 900
	coord.set_treasury_gold(20)
	var ok: bool = coord.repair_structure("FORTRESS", 40) # cost = 6 Gold
	ok = ok and (coord._fortress.current_hp == 940 and coord.get_treasury_gold() == 14)
	_cleanup_session(s)
	return ok


func _test_e9_repair_caps_healing_at_needed_hp() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0)
	coord._fortress.current_hp = 980 # Only 20 HP needed
	coord.set_treasury_gold(100)
	var ok: bool = coord.repair_structure("FORTRESS", 100)
	# Only 20 repaired, cost is ceil(20 * 0.15) = 3 Gold
	ok = ok and (coord._fortress.current_hp == 1000 and coord.get_treasury_gold() == 97)
	_cleanup_session(s)
	return ok


func _test_e10_repair_invalid_target_rejected() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0)
	var fail: bool = coord.repair_structure("BRIDGE", 50)
	_cleanup_session(s)
	return not fail


func _test_e11_repair_active_data_recorded_in_snapshot() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0)
	coord._fortress.current_hp = 900
	coord.repair_structure("FORTRESS", 50)
	var snap: GameStateSnapshot = coord.get_current_state()
	var ok: bool = (not snap.active_repair_data.is_empty())
	ok = ok and (snap.active_repair_data.get("target") == "FORTRESS" and snap.active_repair_data.get("repaired_hp") == 50)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP F: CONSTRUCTION SYSTEM FOUNDATION
# ==============================================================================

func _test_f1_start_construction_valid_building() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(0, 0, 2) # 2 construction workers
	coord.set_treasury_gold(100)
	var ok: bool = coord.start_construction("barracks", 40, 100)
	ok = ok and (coord.get_treasury_gold() == 60)
	var snap: GameStateSnapshot = coord.get_current_state()
	ok = ok and (snap.active_construction_data.get("target_building_id") == "barracks")
	_cleanup_session(s)
	return ok


func _test_f2_start_construction_rejected_without_construction_workers() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 2, 0) # 0 construction workers
	var fail: bool = coord.start_construction("barracks", 50, 100)
	_cleanup_session(s)
	return not fail


func _test_f3_start_construction_rejected_when_treasury_insufficient() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(0, 0, 2)
	coord.set_treasury_gold(20) # Needs 50
	var fail: bool = coord.start_construction("barracks", 50, 100)
	_cleanup_session(s)
	return not fail


func _test_f4_advance_construction_increments_progress() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(0, 0, 2)
	coord.start_construction("barracks", 50, 100)
	var ok: bool = coord.advance_construction(30)
	var snap: GameStateSnapshot = coord.get_current_state()
	ok = ok and (snap.active_construction_data.get("current_progress") == 30)
	_cleanup_session(s)
	return ok


func _test_f5_advance_construction_completes_and_upgrades_building() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(0, 0, 2)
	var b_pre: BuildingModel = coord.get_building("barracks")
	var pre_lvl: int = b_pre.level
	coord.start_construction("barracks", 50, 100)
	coord.advance_construction(50)
	coord.advance_construction(50) # Reaches 100 (complete)
	var b_post: BuildingModel = coord.get_building("barracks")
	var ok: bool = (b_post.level == pre_lvl + 1)
	var snap: GameStateSnapshot = coord.get_current_state()
	ok = ok and bool(snap.active_construction_data.get("is_completed", false))
	_cleanup_session(s)
	return ok


func _test_f6_cancel_construction_refunds_gold_safely() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(0, 0, 2)
	coord.set_treasury_gold(150)
	coord.start_construction("barracks", 50, 100)
	var ok: bool = (coord.get_treasury_gold() == 100)
	coord.cancel_construction()
	ok = ok and (coord.get_treasury_gold() == 150) # Refunded
	var snap: GameStateSnapshot = coord.get_current_state()
	ok = ok and snap.active_construction_data.is_empty()
	_cleanup_session(s)
	return ok


func _test_f7_start_construction_invalid_building_rejected() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(0, 0, 2)
	var fail: bool = coord.start_construction("non_existent_building", 50, 100)
	_cleanup_session(s)
	return not fail


# ==============================================================================
# GROUP G: UI, CONTROLLER, SNAPSHOT & BATTLE LOCK
# ==============================================================================

func _test_g1_controller_delegates_population_conversion() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]
	var coord: GameCoordinator = s["coordinator"]
	var civ_pre: int = coord._population.civilians
	var ok: bool = ctrl.convert_civilian_to_worker(2)
	ok = ok and (coord._population.civilians == civ_pre - 2 and coord._population.workers == 2)
	ok = ok and ctrl.convert_worker_to_civilian(1)
	ok = ok and (coord._population.civilians == civ_pre - 1 and coord._population.workers == 1)
	_cleanup_session(s)
	return ok


func _test_g2_controller_delegates_worker_reassign() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]
	var coord: GameCoordinator = s["coordinator"]
	ctrl.allocate_workers(2, 2, 2)
	var ok: bool = ctrl.reassign_worker(WorkerModel.JOB_BLACKSMITH, WorkerModel.JOB_REPAIR, 1)
	ok = ok and (coord.get_worker_model().repair_workers == 3 and coord.get_worker_model().blacksmith_workers == 1)
	_cleanup_session(s)
	return ok


func _test_g3_controller_delegates_repair_structure() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]
	var coord: GameCoordinator = s["coordinator"]
	ctrl.allocate_workers(2, 0, 0)
	coord._fortress.current_hp = 900
	var ok: bool = ctrl.repair_structure("FORTRESS", 50)
	ok = ok and (coord._fortress.current_hp == 950)
	_cleanup_session(s)
	return ok


func _test_g4_controller_delegates_construction() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]
	var coord: GameCoordinator = s["coordinator"]
	ctrl.allocate_workers(0, 0, 2)
	var ok: bool = ctrl.start_construction("barracks", 50, 100)
	ok = ok and ctrl.advance_construction(25)
	var snap: GameStateSnapshot = coord.get_current_state()
	ok = ok and (snap.active_construction_data.get("current_progress") == 25)
	_cleanup_session(s)
	return ok


func _test_g5_snapshot_contains_all_phase5_fields() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var snap: GameStateSnapshot = coord.get_current_state()
	var ok: bool = snap.fortress_data.has("wall_hp") and snap.fortress_data.has("gate_hp")
	ok = ok and snap.population_data.has("workers") and snap.population_data.has("civilian_count")
	ok = ok and (not snap.worker_data.is_empty())
	ok = ok and (snap.buildings_data.size() == 9)
	_cleanup_session(s)
	return ok


func _test_g6_snapshot_clone_complete_isolation_phase5() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var snap1: GameStateSnapshot = coord.get_current_state()
	var snap2: GameStateSnapshot = snap1.clone()
	snap2.fortress_data["wall_hp"] = 0
	snap2.worker_data["morale"] = 0
	snap2.buildings_data[0]["level"] = 99
	var ok: bool = (snap1.fortress_data["wall_hp"] != 0)
	ok = ok and (snap1.worker_data["morale"] != 0)
	ok = ok and (snap1.buildings_data[0]["level"] != 99)
	_cleanup_session(s)
	return ok


func _test_g7_battle_lock_blocks_worker_allocation() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.inspect_wave()
	coord.start_battle()
	var fail: bool = coord.allocate_workers(2, 2, 2)
	_cleanup_session(s)
	return not fail


func _test_g8_battle_lock_blocks_population_conversion() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.inspect_wave()
	coord.start_battle()
	var f1: bool = coord.convert_civilian_to_worker(1)
	var f2: bool = coord.convert_worker_to_civilian(1)
	_cleanup_session(s)
	return (not f1 and not f2)


func _test_g9_battle_lock_blocks_structure_repair() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(2, 0, 0)
	coord._fortress.current_hp = 800
	coord.inspect_wave()
	coord.start_battle()
	var fail: bool = coord.repair_structure("FORTRESS", 50)
	_cleanup_session(s)
	return not fail


func _test_g10_battle_lock_blocks_construction_actions() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.allocate_workers(0, 0, 2)
	coord.start_construction("barracks", 50, 100)
	coord.inspect_wave()
	coord.start_battle()
	var f1: bool = coord.start_construction("blacksmith", 50, 100)
	var f2: bool = coord.cancel_construction()
	_cleanup_session(s)
	return (not f1 and not f2)


func _test_g11_battle_lock_blocks_building_upgrade() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.inspect_wave()
	coord.start_battle()
	var fail: bool = coord.upgrade_building("barracks")
	_cleanup_session(s)
	return not fail


func _test_g12_ui_start_battle_button_disabled_in_phase5() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var ok: bool = (view._btn_start_battle != null and view._btn_start_battle.disabled)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP H: DETERMINISTIC 100-CYCLE MANAGEMENT STRESS SIMULATION
# ==============================================================================

func _test_h1_deterministic_100_cycle_management_stress_simulation() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var ctrl: GameController = s["controller"]

	coord.set_treasury_gold(10000)

	var initial_total_swords: int = coord.get_warehouse_total_stock("SWORD")

	for cycle in range(1, 101):
		# 1. Siklus Konversi Populasi
		if coord._population.civilians >= 2:
			ctrl.convert_civilian_to_worker(1)
		elif coord._population.workers >= 2:
			ctrl.convert_worker_to_civilian(1)

		# 2. Alokasi & Mutasi Pekerja
		var total_w: int = coord._population.workers if coord._population.workers > 0 else coord._population.civilians
		var rep_alloc: int = mini(total_w, 2)
		var smith_alloc: int = mini(total_w - rep_alloc, 1)
		var constr_alloc: int = mini(total_w - rep_alloc - smith_alloc, 1)
		ctrl.allocate_workers(rep_alloc, smith_alloc, constr_alloc)

		if coord.get_worker_model().blacksmith_workers > 0 and coord.get_worker_model().idle_workers > 0:
			ctrl.reassign_worker(WorkerModel.JOB_BLACKSMITH, WorkerModel.JOB_REPAIR, 1)

		# 3. Simulasi Kerusakan & Reparasi Struktur
		coord._fortress.damage_wall(20)
		coord._fortress.damage_gate(15)
		coord._fortress.take_damage(25)

		if coord._fortress.wall_hp < coord._fortress.wall_max_hp and coord.can_repair_structure("WALL", 20):
			ctrl.repair_structure("WALL", 20)
		if coord._fortress.gate_hp < coord._fortress.gate_max_hp and coord.can_repair_structure("GATE", 15):
			ctrl.repair_structure("GATE", 15)
		if coord._fortress.current_hp < coord._fortress.max_hp and coord.can_repair_structure("FORTRESS", 25):
			ctrl.repair_structure("FORTRESS", 25)

		# 4. Konstruksi Bangunan
		if cycle == 10:
			ctrl.start_construction("warehouse", 50, 100)
		elif cycle > 10 and cycle <= 14:
			ctrl.advance_construction(25) # Completes warehouse at cycle 14
		elif cycle == 50:
			ctrl.start_construction("barracks", 50, 100)
		elif cycle == 52:
			ctrl.cancel_construction() # Verifikasi cancel & refund

		# 5. Verifikasi Invarian Mutlak di Setiap Siklus
		# Invarian Populasi
		var civ: int = coord._population.get_civilian_count()
		var wrk: int = coord._population.get_worker_count()
		var sld: int = coord._population.get_soldier_count()
		var tot_pop: int = coord._population.get_total_population()
		if civ < 0 or wrk < 0 or sld < 0:
			printerr("Cycle %d: Negative population value detected" % cycle)
			_cleanup_session(s)
			return false
		if (civ + wrk + sld) != tot_pop:
			printerr("Cycle %d: Population conservation violated (%d vs %d)" % [cycle, civ + wrk + sld, tot_pop])
			_cleanup_session(s)
			return false

		# Invarian Tenaga Kerja
		var wm: WorkerModel = coord.get_worker_model()
		if not wm.validate_invariants():
			printerr("Cycle %d: WorkerModel invariants violated" % cycle)
			_cleanup_session(s)
			return false

		# Invarian Pertahanan Benteng
		if not coord._fortress.validate_invariants():
			printerr("Cycle %d: FortressModel invariants violated" % cycle)
			_cleanup_session(s)
			return false

		# Invarian Konservasi Gudang
		var cur_total_swords: int = coord.get_warehouse_usable_stock("SWORD") + coord.get_warehouse_damaged_stock("SWORD")
		for comp in coord.get_active_deployments():
			if comp is DeploymentComposition:
				for eq in (comp as DeploymentComposition).reserved_equipment:
					if eq is EquipmentModel and (eq as EquipmentModel).role_type == "SWORD":
						cur_total_swords += (eq as EquipmentModel).quantity
		if cur_total_swords != initial_total_swords:
			printerr("Cycle %d: Equipment conservation violated (%d vs %d)" % [cycle, cur_total_swords, initial_total_swords])
			_cleanup_session(s)
			return false

		# Invarian Snapshot
		var snap: GameStateSnapshot = coord.get_current_state()
		if snap.buildings_data.size() != 9:
			printerr("Cycle %d: Buildings snapshot corrupted" % cycle)
			_cleanup_session(s)
			return false

	_cleanup_session(s)
	return true
