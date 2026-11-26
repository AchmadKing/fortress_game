extends SceneTree

## TestSoldierDeploymentTemporary
## Test suite otomatis untuk memvalidasi implementasi Phase 3B (Temporary Soldier Deployment & Equipment Management).
## Memvalidasi seluruh 27 kriteria A15:
## 1. Valid deployment
## 2. Primary required
## 3. Insufficient primary stock
## 4. Insufficient secondary stock
## 5. Insufficient armor stock
## 6. Disabled unavailable equipment options
## 7. Soldier shortage
## 8. Multiple deployments
## 9. Equipment reservation
## 10. No double allocation
## 11. No negative warehouse stock
## 12. Failed deployment causes no mutation
## 13. Deployment editing
## 14. Failed editing preserves original
## 15. Composition identity
## 16. Different armor creates different composition
## 17. Battle lock
## 18. Deployment snapshot passed to combat
## 19. Warehouse-only equipment is not affected by wear/loss
## 20. Multi-slot equipment accounting
## 21. Equipment returns after battle
## 22. Equipment loss follows existing Phase 2 rules
## 23. Surviving soldiers return to pool
## 24. Soldier death permanently reduces living soldier count
## 25. Existing Phase 1 regression
## 26. Existing Phase 2 regression
## 27. Existing Phase 3 regression

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const CommanderCommand = preload("res://scripts/domain/command/commander_command.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 3B TEMPORARY SOLDIER DEPLOYMENT TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		{"name": "test_basic_valid_deployment", "fn": Callable(self, "_test_basic_valid_deployment")},
		{"name": "test_primary_weapon_mandatory", "fn": Callable(self, "_test_primary_weapon_mandatory")},
		{"name": "test_insufficient_primary_stock", "fn": Callable(self, "_test_insufficient_primary_stock")},
		{"name": "test_insufficient_secondary_stock", "fn": Callable(self, "_test_insufficient_secondary_stock")},
		{"name": "test_insufficient_armor_stock", "fn": Callable(self, "_test_insufficient_armor_stock")},
		{"name": "test_disabled_unavailable_equipment_options", "fn": Callable(self, "_test_disabled_unavailable_equipment_options")},
		{"name": "test_soldier_shortage", "fn": Callable(self, "_test_soldier_shortage")},
		{"name": "test_multiple_deployments", "fn": Callable(self, "_test_multiple_deployments")},
		{"name": "test_equipment_reservation", "fn": Callable(self, "_test_equipment_reservation")},
		{"name": "test_no_double_allocation", "fn": Callable(self, "_test_no_double_allocation")},
		{"name": "test_no_negative_warehouse_stock", "fn": Callable(self, "_test_no_negative_warehouse_stock")},
		{"name": "test_failed_deployment_causes_no_mutation", "fn": Callable(self, "_test_failed_deployment_causes_no_mutation")},
		{"name": "test_deployment_editing", "fn": Callable(self, "_test_deployment_editing")},
		{"name": "test_failed_editing_preserves_original", "fn": Callable(self, "_test_failed_editing_preserves_original")},
		{"name": "test_composition_identity", "fn": Callable(self, "_test_composition_identity")},
		{"name": "test_different_armor_creates_different_composition", "fn": Callable(self, "_test_different_armor_creates_different_composition")},
		{"name": "test_battle_lock", "fn": Callable(self, "_test_battle_lock")},
		{"name": "test_deployment_snapshot_passed_to_combat", "fn": Callable(self, "_test_deployment_snapshot_passed_to_combat")},
		{"name": "test_warehouse_only_equipment_is_not_affected_by_wear_loss", "fn": Callable(self, "_test_warehouse_only_equipment_is_not_affected_by_wear_loss")},
		{"name": "test_multi_slot_equipment_accounting", "fn": Callable(self, "_test_multi_slot_equipment_accounting")},
		{"name": "test_equipment_returns_after_battle", "fn": Callable(self, "_test_equipment_returns_after_battle")},
		{"name": "test_equipment_loss_phase2_deterministic", "fn": Callable(self, "_test_equipment_loss_phase2_deterministic")},
		{"name": "test_surviving_soldiers_return_to_pool", "fn": Callable(self, "_test_surviving_soldiers_return_to_pool")},
		{"name": "test_soldier_casualties_permanent", "fn": Callable(self, "_test_soldier_casualties_permanent")},
		{"name": "test_existing_phase1_regression", "fn": Callable(self, "_test_existing_phase1_regression")},
		{"name": "test_existing_phase2_regression", "fn": Callable(self, "_test_existing_phase2_regression")},
		{"name": "test_existing_phase3_regression", "fn": Callable(self, "_test_existing_phase3_regression")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 3B TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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


# 1. Valid deployment
func _test_basic_valid_deployment() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_basic")
	var initial_wh_sword: int = coord.get_warehouse_stock("SWORD")
	var initial_avail: int = coord.get_available_soldiers()
	
	var ok: bool = coord.create_deployment(2, "SWORD")
	if not ok: return false
	
	if coord.get_warehouse_stock("SWORD") != initial_wh_sword - 2: return false
	if coord.get_available_soldiers() != initial_avail - 2: return false
	if coord.get_active_deployments().size() != 1: return false
	return true


# 2. Primary required
func _test_primary_weapon_mandatory() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_prim_req")
	if coord.create_deployment(2, ""): return false
	if coord.create_deployment(2, "NONE"): return false
	if coord.create_deployment(2, "INVALID_WEAPON"): return false
	return true


# 3. Insufficient primary stock
func _test_insufficient_primary_stock() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_insuf_prim")
	var ok: bool = coord.create_deployment(999, "SWORD")
	if ok: return false
	return true


# 4. Insufficient secondary stock
func _test_insufficient_secondary_stock() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_insuf_sec")
	# Recruited soldiers up to 15, but only 10 shields in warehouse
	coord.recruit_soldier("SWORDSMAN", 8)
	var ok: bool = coord.create_deployment(12, "SWORD", "SHIELD")
	if ok: return false
	return true


# 5. Insufficient armor stock
func _test_insufficient_armor_stock() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_insuf_arm")
	coord.recruit_soldier("SWORDSMAN", 8)
	var ok: bool = coord.create_deployment(12, "SWORD", "NONE", "HEAVY_ARMOR")
	if ok: return false
	return true


# 6. Disabled unavailable equipment options
func _test_disabled_unavailable_equipment_options() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_disabled_opt")
	if not coord.is_equipment_option_available("SWORD", 2): return false
	if coord.is_equipment_option_available("SWORD", 999): return false
	return true


# 7. Soldier shortage
func _test_soldier_shortage() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_soldier_shortage")
	var avail: int = coord.get_available_soldiers()
	var ok: bool = coord.create_deployment(avail + 5, "SWORD")
	if ok: return false
	return true


# 8. Multiple deployments
func _test_multiple_deployments() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_mult")
	if not coord.create_deployment(2, "SWORD"): return false
	if not coord.create_deployment(2, "SWORD", "SHIELD"): return false
	if not coord.create_deployment(2, "BOW"): return false
	
	if coord.get_active_deployments().size() != 3: return false
	if coord.get_available_soldiers() != 0: return false
	return true


# 9. Equipment reservation
func _test_equipment_reservation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_res")
	coord.create_deployment(2, "SWORD")
	coord.create_deployment(2, "SWORD", "SHIELD")
	coord.create_deployment(2, "BOW")
	
	if coord.get_reserved_equipment_stock("SWORD") != 4: return false
	if coord.get_reserved_equipment_stock("SHIELD") != 2: return false
	if coord.get_reserved_equipment_stock("BOW") != 2: return false
	return true


# 10. No double allocation
func _test_no_double_allocation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_double_alloc")
	coord.recruit_soldier("SWORDSMAN", 8) # Total living = 14
	# Warehouse has 10 Swords
	if not coord.create_deployment(6, "SWORD"): return false
	# Only 4 Swords left in warehouse. Trying to reserve 5 Swords must fail!
	if coord.create_deployment(5, "SWORD"): return false
	return true


# 11. No negative warehouse stock
func _test_no_negative_warehouse_stock() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_neg_wh")
	for item in coord._warehouse:
		if (item as EquipmentModel).quantity < 0: return false
	coord.create_deployment(2, "SWORD")
	for item in coord._warehouse:
		if (item as EquipmentModel).quantity < 0: return false
	return true


# 12. Failed deployment causes no mutation
func _test_failed_deployment_causes_no_mutation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_no_mut")
	var snap_before: GameStateSnapshot = coord.get_current_state()
	var ok: bool = coord.create_deployment(999, "SWORD")
	if ok: return false
	var snap_after: GameStateSnapshot = coord.get_current_state()
	
	if snap_before.available_soldiers_count != snap_after.available_soldiers_count: return false
	if snap_before.active_deployments_data.size() != snap_after.active_deployments_data.size(): return false
	if coord.get_warehouse_stock("SWORD") != 10: return false
	return true


# 13. Deployment editing
func _test_deployment_editing() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_edit")
	if not coord.create_deployment(2, "SWORD"): return false
	var ok_edit: bool = coord.reconfigure_deployment("SWORD|NONE|NONE", 2, "SPEAR")
	if not ok_edit: return false
	
	if coord.get_warehouse_stock("SWORD") != 10: return false
	if coord.get_warehouse_stock("SPEAR") != 8: return false
	if coord.get_reserved_equipment_stock("SPEAR") != 2: return false
	return true


# 14. Failed editing preserves original
func _test_failed_editing_preserves_original() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_edit_fail")
	coord.create_deployment(2, "SWORD")
	var ok: bool = coord.reconfigure_deployment("SWORD|NONE|NONE", 999, "SPEAR")
	if ok: return false
	
	if coord.get_active_deployments().size() != 1: return false
	if coord.get_warehouse_stock("SWORD") != 8: return false
	if coord.get_available_soldiers() != 4: return false
	return true


# 15. Composition identity
func _test_composition_identity() -> bool:
	var id1: String = DeploymentComposition.make_composition_id("SWORD", "SHIELD", "NONE")
	var id2: String = DeploymentComposition.make_composition_id("SWORD", "NONE", "NONE")
	if id1 == id2: return false
	return true


# 16. Different armor creates different composition
func _test_different_armor_creates_different_composition() -> bool:
	var id1: String = DeploymentComposition.make_composition_id("SWORD", "SHIELD", "NONE")
	var id2: String = DeploymentComposition.make_composition_id("SWORD", "SHIELD", "HEAVY_ARMOR")
	if id1 == id2: return false
	return true


# 17. Battle lock
func _test_battle_lock() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_lock")
	coord.create_deployment(2, "SWORD")
	coord.inspect_wave()
	coord.start_battle()
	
	if coord.create_deployment(2, "BOW"): return false
	if coord.remove_deployment("SWORD|NONE|NONE"): return false
	if coord.reconfigure_deployment("SWORD|NONE|NONE", 2, "SPEAR"): return false
	return true


# 18. Deployment snapshot passed to combat
func _test_deployment_snapshot_passed_to_combat() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_combat_snap")
	coord.create_deployment(2, "SWORD")
	coord.inspect_wave()
	coord.start_battle()
	var res: Dictionary = coord.execute_battle(42)
	if res.is_empty(): return false
	return true


# 19. Warehouse-only equipment is not affected by wear/loss
func _test_warehouse_only_equipment_is_not_affected_by_wear_loss() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_wh_safe")
	# Only deploy Swords. Spears sit unused in warehouse.
	coord.create_deployment(2, "SWORD")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	
	for item in coord._warehouse:
		if (item as EquipmentModel).role_type == "SPEAR":
			if (item as EquipmentModel).durability != 100: return false
	return true


# 20. Multi-slot equipment accounting
func _test_multi_slot_equipment_accounting() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_multislot")
	var ok: bool = coord.create_deployment(2, "SWORD", "SHIELD", "HEAVY_ARMOR")
	if not ok: return false
	
	if coord.get_reserved_equipment_stock("SWORD") != 2: return false
	if coord.get_reserved_equipment_stock("SHIELD") != 2: return false
	if coord.get_reserved_equipment_stock("HEAVY_ARMOR") != 2: return false
	return true


# 21. Equipment returns after battle
func _test_equipment_returns_after_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_return")
	coord.create_deployment(2, "BOW")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()
	
	# After recovery, active deployments are 0
	if coord.get_active_deployments().size() != 0: return false
	if coord.get_reserved_equipment_stock("BOW") != 0: return false
	# Returned bows are back in warehouse
	if coord.get_warehouse_stock("BOW") <= 0: return false
	return true


# 22. Equipment loss follows existing Phase 2 rules
func _test_equipment_loss_phase2_deterministic() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_phase2_loss", 999)
	coord.create_deployment(4, "SWORD", "SHIELD")
	coord.inspect_wave()
	coord.start_battle()
	var res: Dictionary = coord.execute_battle(123)
	if not res.has("equipment_lost"): return false
	if not res.has("equipment_damaged"): return false
	return true


# 23. Surviving soldiers return to pool
func _test_surviving_soldiers_return_to_pool() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_pool_return")
	coord.create_deployment(2, "SWORD")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()
	
	if coord.get_available_soldiers() != coord.get_current_state().total_living_soldiers_count: return false
	return true


# 24. Soldier death permanently reduces living soldier count
func _test_soldier_casualties_permanent() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_casualties", 123)
	var initial_living: int = coord.get_current_state().total_living_soldiers_count
	coord.create_deployment(6, "SWORD")
	coord.inspect_wave()
	coord.start_battle()
	var res: Dictionary = coord.execute_battle(123)
	coord.proceed_from_result()
	
	var casualties: Dictionary = res.get("casualties", {})
	var dead: int = 0
	for r in casualties: dead += int(casualties[r])
	
	var final_living: int = coord.get_current_state().total_living_soldiers_count
	if final_living != initial_living - dead: return false
	return true


# 25. Existing Phase 1 regression
func _test_existing_phase1_regression() -> bool:
	var coord := GameCoordinator.new()
	coord.initialize_session("sess_p1")
	if coord.get_current_state().session_id != "sess_p1": return false
	coord.request_step(3)
	if coord.get_current_state().tick != 3: return false
	return true


# 26. Existing Phase 2 regression
func _test_existing_phase2_regression() -> bool:
	var CombatEngineScript = preload("res://scripts/simulation/combat_engine.gd")
	var engine = CombatEngineScript.new()
	var PopulationScript = preload("res://scripts/domain/model/population_model.gd")
	var pop = PopulationScript.new()
	pop.soldiers["ARCHER"] = 5
	var wh = [EquipmentModel.new("BOW", 1, 100, 5)]
	var calc = engine.calculate_role_power(5, 16.0, "BOW", wh, 100)
	if float(calc["power"]) <= 0.0: return false
	return true


# 27. Existing Phase 3 regression
func _test_existing_phase3_regression() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("sess_p3_reg")
	if not coord.allocate_workers(1, 1, 1): return false
	if not coord.recruit_soldier("SWORDSMAN", 1): return false
	if not coord.inspect_wave(): return false
	if not coord.cancel_wave_preview(): return false
	return true
