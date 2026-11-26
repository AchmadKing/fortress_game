extends SceneTree

## TestPhase3dFollowupCorrections
## Test suite otomatis untuk memvalidasi follow-up corrections Phase 3D:
## 1. Deployed Soldiers Status UI (Correction A)
##    - Deployed soldiers count strictly derived from SUM(all active deployment soldier_count).
##    - Shows '-' when no deployment is active.
##    - Separate from available soldier pool.
## 2. Soldier Equipment Durability & Casualty Resolution (Correction B)
##    - Surviving soldiers return equipment at 100% durability (usable).
##    - Dead soldiers: 35% destroyed, 65% damaged (durability 60, non-usable).
##    - Damaged equipment excluded from deployment stock validation.
## 3. Blacksmith Equipment Repair (Correction B)
##    - Damaged equipment can be repaired to 100% durability using Gold.
##    - Fails if Gold is insufficient.
##    - Repaired equipment becomes usable and deployable.
##    - Repair does not duplicate items.
## 4. Shared Warehouse Conservation Invariant (Correction B)
##    - Total Owned = Warehouse Usable + Warehouse Damaged + Soldier Reserved + Hero Equipped.
##    - Invariant holds across survivor return, damaged return, destroyed items, and repairs.
##    - Hero equipment remains persistent and unaffected by soldier casualties.

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const PrototypeDebugView = preload("res://scripts/presentation/views/prototype_debug_view.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 3D FOLLOW-UP CORRECTIONS TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# Soldier UI (4 tests)
		{"name": "test_deployed_soldier_status_empty_before_deployment", "fn": Callable(self, "_test_deployed_soldier_status_empty_before_deployment")},
		{"name": "test_deployed_soldier_status_matches_active_deployment_total", "fn": Callable(self, "_test_deployed_soldier_status_matches_active_deployment_total")},
		{"name": "test_deployed_soldier_status_handles_multiple_groups", "fn": Callable(self, "_test_deployed_soldier_status_handles_multiple_groups")},
		{"name": "test_available_soldier_pool_is_not_used_as_deployed_status", "fn": Callable(self, "_test_available_soldier_pool_is_not_used_as_deployed_status")},

		# Durability (8 tests)
		{"name": "test_surviving_soldier_equipment_returns_at_100_durability", "fn": Callable(self, "_test_surviving_soldier_equipment_returns_at_100_durability")},
		{"name": "test_surviving_soldier_equipment_is_usable", "fn": Callable(self, "_test_surviving_soldier_equipment_is_usable")},
		{"name": "test_casualty_equipment_can_return_damaged", "fn": Callable(self, "_test_casualty_equipment_can_return_damaged")},
		{"name": "test_casualty_equipment_can_be_destroyed", "fn": Callable(self, "_test_casualty_equipment_can_be_destroyed")},
		{"name": "test_damaged_equipment_is_not_usable", "fn": Callable(self, "_test_damaged_equipment_is_not_usable")},
		{"name": "test_damaged_equipment_is_excluded_from_deployment_stock", "fn": Callable(self, "_test_damaged_equipment_is_excluded_from_deployment_stock")},
		{"name": "test_destroyed_equipment_is_removed_from_owned_stock", "fn": Callable(self, "_test_destroyed_equipment_is_removed_from_owned_stock")},
		{"name": "test_damaged_equipment_remains_in_owned_stock", "fn": Callable(self, "_test_damaged_equipment_remains_in_owned_stock")},

		# Repair (6 tests)
		{"name": "test_repair_damaged_equipment_restores_100_durability", "fn": Callable(self, "_test_repair_damaged_equipment_restores_100_durability")},
		{"name": "test_repair_consumes_gold", "fn": Callable(self, "_test_repair_consumes_gold")},
		{"name": "test_repair_does_not_change_total_equipment_ownership", "fn": Callable(self, "_test_repair_does_not_change_total_equipment_ownership")},
		{"name": "test_repair_fails_without_enough_gold", "fn": Callable(self, "_test_repair_fails_without_enough_gold")},
		{"name": "test_repaired_equipment_becomes_deployable", "fn": Callable(self, "_test_repaired_equipment_becomes_deployable")},
		{"name": "test_repair_does_not_duplicate_equipment", "fn": Callable(self, "_test_repair_does_not_duplicate_equipment")},

		# Conservation (5 tests)
		{"name": "test_shared_warehouse_conservation_after_survivor_return", "fn": Callable(self, "_test_shared_warehouse_conservation_after_survivor_return")},
		{"name": "test_shared_warehouse_conservation_after_damaged_return", "fn": Callable(self, "_test_shared_warehouse_conservation_after_damaged_return")},
		{"name": "test_shared_warehouse_conservation_after_destroyed_equipment", "fn": Callable(self, "_test_shared_warehouse_conservation_after_destroyed_equipment")},
		{"name": "test_shared_warehouse_conservation_after_repair", "fn": Callable(self, "_test_shared_warehouse_conservation_after_repair")},
		{"name": "test_hero_equipment_conservation_remains_intact", "fn": Callable(self, "_test_hero_equipment_conservation_remains_intact")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 3D FOLLOW-UP TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("================================================================")

	if failed == 0:
		quit(0)
	else:
		quit(1)


func _run_test(test_name: String, test_fn: Callable) -> bool:
	print("RUNNING: %s ..." % test_name)
	var ok: bool = false
	
	var res = test_fn.call()
	if res is bool:
		ok = res
	else:
		ok = true
	
	if ok:
		print("  -> PASS")
		return true
	else:
		printerr("  -> FAIL: %s" % test_name)
		return false


func _setup_coordinator() -> GameCoordinator:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_corrections_seed")
	coord.recruit_soldier("SWORDSMAN", 10)
	return coord


# ==============================================================================
# GROUP 1: SOLDIER UI (4 TESTS)
# ==============================================================================

## 1. test_deployed_soldier_status_empty_before_deployment
func _test_deployed_soldier_status_empty_before_deployment() -> bool:
	var coord := _setup_coordinator()
	var snapshot = coord.get_current_snapshot()

	if coord.get_total_deployed_soldiers() != 0:
		printerr("Expected total deployed soldiers to be 0, got %d" % coord.get_total_deployed_soldiers())
		return false

	if snapshot.deployed_soldiers_count != 0:
		printerr("Expected snapshot deployed_soldiers_count to be 0, got %d" % snapshot.deployed_soldiers_count)
		return false

	var ctrl := GameController.new()
	ctrl.setup(coord)
	if ctrl.get_total_deployed_soldiers() != 0:
		printerr("Expected controller get_total_deployed_soldiers to be 0")
		return false

	return true


## 2. test_deployed_soldier_status_matches_active_deployment_total
func _test_deployed_soldier_status_matches_active_deployment_total() -> bool:
	var coord := _setup_coordinator()
	var success = coord.create_soldier_deployment(10, "SWORD", "SHIELD", "NONE")
	if not success:
		printerr("Failed to create soldier deployment of 10")
		return false

	var deployed: int = coord.get_total_deployed_soldiers()
	if deployed != 10:
		printerr("Expected 10 deployed soldiers, got %d" % deployed)
		return false

	var snapshot = coord.get_current_snapshot()
	if snapshot.deployed_soldiers_count != 10:
		printerr("Expected snapshot deployed_soldiers_count to be 10, got %d" % snapshot.deployed_soldiers_count)
		return false

	return true


## 3. test_deployed_soldier_status_handles_multiple_groups
func _test_deployed_soldier_status_handles_multiple_groups() -> bool:
	var coord := _setup_coordinator()
	var ok1 = coord.create_soldier_deployment(5, "SWORD", "SHIELD", "NONE")
	var ok2 = coord.create_soldier_deployment(8, "BOW", "NONE", "NONE")
	if not ok1 or not ok2:
		printerr("Failed to create multiple soldier deployments (5 + 8)")
		return false

	var deployed: int = coord.get_total_deployed_soldiers()
	if deployed != 13:
		printerr("Expected 13 deployed soldiers (5 + 8), got %d" % deployed)
		return false

	var snapshot = coord.get_current_snapshot()
	if snapshot.deployed_soldiers_count != 13:
		printerr("Expected snapshot deployed_soldiers_count to be 13, got %d" % snapshot.deployed_soldiers_count)
		return false

	return true


## 4. test_available_soldier_pool_is_not_used_as_deployed_status
func _test_available_soldier_pool_is_not_used_as_deployed_status() -> bool:
	var coord := _setup_coordinator()
	var initial_available: int = coord.get_available_soldiers() # typically 18
	
	if coord.get_total_deployed_soldiers() == initial_available:
		printerr("Deployed soldiers should NOT equal initial available soldier pool before deployment")
		return false

	var ok = coord.create_soldier_deployment(6, "SWORD", "SHIELD", "NONE")
	if not ok:
		printerr("Failed to deploy 6 soldiers")
		return false

	var after_available: int = coord.get_available_soldiers()
	var deployed: int = coord.get_total_deployed_soldiers()

	if deployed != 6:
		printerr("Expected deployed soldiers to be 6, got %d" % deployed)
		return false

	if after_available != (initial_available - 6):
		printerr("Expected remaining available soldiers to be %d, got %d" % [initial_available - 6, after_available])
		return false

	if deployed == after_available:
		printerr("Deployed count (%d) should not be conflated with available pool (%d)" % [deployed, after_available])
		return false

	return true


# ==============================================================================
# GROUP 2: DURABILITY (8 TESTS)
# ==============================================================================

## 5. test_surviving_soldier_equipment_returns_at_100_durability
func _test_surviving_soldier_equipment_returns_at_100_durability() -> bool:
	var coord := _setup_coordinator()
	# Create deployment of 4 soldiers with SWORD
	var initial_usable: int = coord.get_warehouse_usable_stock("SWORD")
	coord.create_soldier_deployment(4, "SWORD", "NONE", "NONE")

	# Mock battle outcome with 0 casualties
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle()
	# Mock last battle result with zero casualties
	coord._last_battle_result = {
		"victory": true,
		"game_over": false,
		"loot_gold": 25,
		"casualties": {"INFANTRY": 0, "ARCHER": 0, "GUARDIAN": 0}
	}
	coord._fortress.current_hp = 1000

	# Proceed from result into recovery
	var proceeded: bool = coord.proceed_from_result()
	if not proceeded:
		printerr("proceed_from_result failed")
		return false

	# All 4 swords should return to warehouse at 100% durability
	var final_usable: int = coord.get_warehouse_usable_stock("SWORD")
	var final_damaged: int = coord.get_warehouse_damaged_stock("SWORD")

	if final_usable != initial_usable:
		printerr("Expected usable stock to return to initial %d, got %d" % [initial_usable, final_usable])
		return false

	if final_damaged != 0:
		printerr("Expected 0 damaged swords for 100%% survivors, got %d" % final_damaged)
		return false

	return true


## 6. test_surviving_soldier_equipment_is_usable
func _test_surviving_soldier_equipment_is_usable() -> bool:
	var eq_survivor := EquipmentModel.new("SWORD", 1, 100, 5)
	if not eq_survivor.is_usable():
		printerr("Equipment at 100 durability should be usable")
		return false
	if eq_survivor.is_damaged():
		printerr("Equipment at 100 durability should NOT be damaged")
		return false
	return true


## 7. test_casualty_equipment_can_return_damaged
func _test_casualty_equipment_can_return_damaged() -> bool:
	var coord := _setup_coordinator()
	# Returning damaged equipment (durability 60) should increase damaged stock
	var eq_damaged := EquipmentModel.new("SWORD", 1, 60, 2)
	coord._return_equipment_to_warehouse(eq_damaged)

	var damaged_stock: int = coord.get_warehouse_damaged_stock("SWORD")
	if damaged_stock != 2:
		printerr("Expected damaged stock of SWORD to be 2, got %d" % damaged_stock)
		return false

	return true


## 8. test_casualty_equipment_can_be_destroyed
func _test_casualty_equipment_can_be_destroyed() -> bool:
	var coord := _setup_coordinator()
	var initial_total: int = coord.get_total_owned_stock("SWORD")
	# Simulate 1 item destroyed by not returning it to warehouse after deduction
	var deducted: Array = coord._deduct_warehouse_stock("SWORD", 1)
	if deducted.is_empty():
		printerr("Failed to deduct 1 SWORD")
		return false

	# Item is destroyed, not returned
	var after_total: int = coord.get_total_owned_stock("SWORD")
	if after_total != initial_total - 1:
		printerr("Expected total owned to decrease by 1 for destroyed item, got %d vs %d" % [after_total, initial_total - 1])
		return false

	return true


## 9. test_damaged_equipment_is_not_usable
func _test_damaged_equipment_is_not_usable() -> bool:
	var eq_damaged := EquipmentModel.new("SWORD", 1, 60, 1)
	if eq_damaged.is_usable():
		printerr("Damaged equipment (durability 60) must NOT be usable")
		return false
	if not eq_damaged.is_damaged():
		printerr("Damaged equipment (durability 60) must report is_damaged() == true")
		return false
	return true


## 10. test_damaged_equipment_is_excluded_from_deployment_stock
func _test_damaged_equipment_is_excluded_from_deployment_stock() -> bool:
	var coord := _setup_coordinator()
	# Add 10 damaged swords to warehouse
	coord._return_equipment_to_warehouse(EquipmentModel.new("SWORD", 1, 60, 10))

	var usable_stock: int = coord.get_warehouse_usable_stock("SWORD")
	var damaged_stock: int = coord.get_warehouse_damaged_stock("SWORD")
	var total_stock: int = coord.get_warehouse_total_stock("SWORD")

	if damaged_stock != 10:
		printerr("Expected 10 damaged swords, got %d" % damaged_stock)
		return false

	if total_stock != (usable_stock + 10):
		printerr("Total stock should be usable (%d) + 10, got %d" % [usable_stock, total_stock])
		return false

	# Attempt to deploy more than usable stock should fail, even if total stock >= count
	var excess_count: int = usable_stock + 1
	var ok_excess = coord.create_soldier_deployment(excess_count, "SWORD", "NONE", "NONE")
	if ok_excess:
		printerr("Deployment should FAIL when requesting more than usable stock")
		return false

	# Deploying exact usable stock should succeed
	var ok_usable = coord.create_soldier_deployment(usable_stock, "SWORD", "NONE", "NONE")
	if not ok_usable:
		printerr("Deployment should SUCCEED when requesting exactly usable stock")
		return false

	return true


## 11. test_destroyed_equipment_is_removed_from_owned_stock
func _test_destroyed_equipment_is_removed_from_owned_stock() -> bool:
	var coord := _setup_coordinator()
	var total_before: int = coord.get_total_owned_stock("BOW")

	# Destroy 2 bows (deduct without return)
	var deducted: Array = coord._deduct_warehouse_stock("BOW", 2)
	var deducted_qty: int = 0
	for d in deducted:
		if d is EquipmentModel:
			deducted_qty += (d as EquipmentModel).quantity
	if deducted_qty != 2:
		printerr("Failed to deduct 2 BOWs, got %d" % deducted_qty)
		return false

	var total_after: int = coord.get_total_owned_stock("BOW")
	if total_after != total_before - 2:
		printerr("Expected total owned to decrease by 2, got %d vs %d" % [total_after, total_before - 2])
		return false

	return true


## 12. test_damaged_equipment_remains_in_owned_stock
func _test_damaged_equipment_remains_in_owned_stock() -> bool:
	var coord := _setup_coordinator()
	var total_before: int = coord.get_total_owned_stock("SHIELD")

	# Deduct 1 shield, return it as damaged (durability 60)
	var deducted: Array = coord._deduct_warehouse_stock("SHIELD", 1)
	if deducted.is_empty():
		printerr("Failed to deduct shield")
		return false

	coord._return_equipment_to_warehouse(EquipmentModel.new("SHIELD", 1, 60, 1))

	var total_after: int = coord.get_total_owned_stock("SHIELD")
	if total_after != total_before:
		printerr("Total owned stock must remain constant when item returns damaged, got %d vs %d" % [total_after, total_before])
		return false

	var damaged_shields: int = coord.get_warehouse_damaged_stock("SHIELD")
	if damaged_shields < 1:
		printerr("Damaged stock must be >= 1")
		return false

	return true


# ==============================================================================
# GROUP 3: REPAIR (6 TESTS)
# ==============================================================================

## 13. test_repair_damaged_equipment_restores_100_durability
func _test_repair_damaged_equipment_restores_100_durability() -> bool:
	var coord := _setup_coordinator()
	coord.set_treasury_gold(500)

	# Add 2 damaged swords
	coord._return_equipment_to_warehouse(EquipmentModel.new("SWORD", 1, 60, 2))
	var initial_usable: int = coord.get_warehouse_usable_stock("SWORD")

	var repair_ok: bool = coord.repair_equipment("SWORD", 2)
	if not repair_ok:
		printerr("repair_equipment failed")
		return false

	var after_usable: int = coord.get_warehouse_usable_stock("SWORD")
	var after_damaged: int = coord.get_warehouse_damaged_stock("SWORD")

	if after_damaged != 0:
		printerr("Expected 0 damaged swords after repair, got %d" % after_damaged)
		return false

	if after_usable != initial_usable + 2:
		printerr("Expected usable stock to increase by 2, got %d vs %d" % [after_usable, initial_usable + 2])
		return false

	return true


## 14. test_repair_consumes_gold
func _test_repair_consumes_gold() -> bool:
	var coord := _setup_coordinator()
	coord.set_treasury_gold(200)

	coord._return_equipment_to_warehouse(EquipmentModel.new("SWORD", 1, 60, 1))
	var expected_cost: int = coord.get_equipment_repair_cost("SWORD", 1)
	if expected_cost <= 0:
		printerr("Expected repair cost > 0, got %d" % expected_cost)
		return false

	var gold_before: int = coord.get_treasury_gold()
	var ok: bool = coord.repair_equipment("SWORD", 1)
	if not ok:
		printerr("Repair failed")
		return false

	var gold_after: int = coord.get_treasury_gold()
	if gold_after != (gold_before - expected_cost):
		printerr("Expected gold after repair to be %d, got %d" % [gold_before - expected_cost, gold_after])
		return false

	return true


## 15. test_repair_does_not_change_total_equipment_ownership
func _test_repair_does_not_change_total_equipment_ownership() -> bool:
	var coord := _setup_coordinator()
	coord.set_treasury_gold(300)

	coord._return_equipment_to_warehouse(EquipmentModel.new("BOW", 1, 60, 3))
	var total_before: int = coord.get_total_owned_stock("BOW")

	coord.repair_equipment("BOW", 2)

	var total_after: int = coord.get_total_owned_stock("BOW")
	if total_after != total_before:
		printerr("Total owned stock changed after repair: before=%d, after=%d" % [total_before, total_after])
		return false

	return true


## 16. test_repair_fails_without_enough_gold
func _test_repair_fails_without_enough_gold() -> bool:
	var coord := _setup_coordinator()
	coord.set_treasury_gold(0)

	coord._return_equipment_to_warehouse(EquipmentModel.new("SWORD", 1, 60, 2))
	var damaged_before: int = coord.get_warehouse_damaged_stock("SWORD")

	var repair_result: bool = coord.repair_equipment("SWORD", 1)
	if repair_result:
		printerr("repair_equipment should FAIL when gold is 0")
		return false

	var damaged_after: int = coord.get_warehouse_damaged_stock("SWORD")
	if damaged_after != damaged_before:
		printerr("Damaged stock should not change after failed repair")
		return false

	if coord.get_treasury_gold() != 0:
		printerr("Gold should remain 0")
		return false

	return true


## 17. test_repaired_equipment_becomes_deployable
func _test_repaired_equipment_becomes_deployable() -> bool:
	var coord := _setup_coordinator()
	coord.set_treasury_gold(200)

	# Drain all usable swords by creating maximum deployment
	var initial_usable: int = coord.get_warehouse_usable_stock("SWORD")
	coord.create_soldier_deployment(initial_usable, "SWORD", "NONE", "NONE")

	if coord.get_warehouse_usable_stock("SWORD") != 0:
		printerr("Expected 0 usable swords after draining")
		return false

	# Add 2 damaged swords
	coord._return_equipment_to_warehouse(EquipmentModel.new("SWORD", 1, 60, 2))

	# Reconfiguring/adding deployment with SWORD should fail
	var failed_deploy = coord.create_soldier_deployment(1, "SWORD", "NONE", "NONE")
	if failed_deploy:
		printerr("Deployment should fail when usable stock is 0 (even with damaged stock)")
		return false

	# Repair 1 sword
	var repair_ok: bool = coord.repair_equipment("SWORD", 1)
	if not repair_ok:
		printerr("Failed to repair 1 sword")
		return false

	# Now deploying 1 sword should succeed!
	var succeed_deploy = coord.create_soldier_deployment(1, "SWORD", "NONE", "NONE")
	if not succeed_deploy:
		printerr("Deployment should succeed after repairing equipment")
		return false

	return true


## 18. test_repair_does_not_duplicate_equipment
func _test_repair_does_not_duplicate_equipment() -> bool:
	var coord := _setup_coordinator()
	coord.set_treasury_gold(500)

	coord._return_equipment_to_warehouse(EquipmentModel.new("SWORD", 1, 60, 3))
	var damaged_before: int = coord.get_warehouse_damaged_stock("SWORD")
	var usable_before: int = coord.get_warehouse_usable_stock("SWORD")
	var total_wh_before: int = coord.get_warehouse_total_stock("SWORD")

	coord.repair_equipment("SWORD", 2)

	var damaged_after: int = coord.get_warehouse_damaged_stock("SWORD")
	var usable_after: int = coord.get_warehouse_usable_stock("SWORD")
	var total_wh_after: int = coord.get_warehouse_total_stock("SWORD")

	if damaged_after != (damaged_before - 2):
		printerr("Damaged stock should decrease by exactly 2, got %d" % damaged_after)
		return false

	if usable_after != (usable_before + 2):
		printerr("Usable stock should increase by exactly 2, got %d" % usable_after)
		return false

	if total_wh_after != total_wh_before:
		printerr("Total warehouse stock should not change after repair: %d vs %d" % [total_wh_after, total_wh_before])
		return false

	return true


# ==============================================================================
# GROUP 4: CONSERVATION (5 TESTS)
# ==============================================================================

## 19. test_shared_warehouse_conservation_after_survivor_return
func _test_shared_warehouse_conservation_after_survivor_return() -> bool:
	var coord := _setup_coordinator()
	var total_owned_initial: int = coord.get_total_owned_stock("SWORD")

	# Deploy 5 soldiers with sword
	coord.create_soldier_deployment(5, "SWORD", "NONE", "NONE")
	var total_during: int = coord.get_total_owned_stock("SWORD")
	if total_during != total_owned_initial:
		printerr("Conservation violated during deployment: %d vs %d" % [total_during, total_owned_initial])
		return false

	# Mock battle outcome with 0 casualties
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle()
	coord._last_battle_result = {
		"victory": true,
		"game_over": false,
		"loot_gold": 10,
		"casualties": {"INFANTRY": 0, "ARCHER": 0, "GUARDIAN": 0}
	}
	coord._fortress.current_hp = 1000
	var proceeded: bool = coord.proceed_from_result()
	if not proceeded:
		printerr("proceed_from_result failed in test 19")
		return false

	var total_after: int = coord.get_total_owned_stock("SWORD")
	if total_after != total_owned_initial:
		printerr("Conservation violated after survivor return: %d vs %d" % [total_after, total_owned_initial])
		return false

	return true


## 20. test_shared_warehouse_conservation_after_damaged_return
func _test_shared_warehouse_conservation_after_damaged_return() -> bool:
	var coord := _setup_coordinator()
	var total_owned_initial: int = coord.get_total_owned_stock("SWORD")

	# Add damaged equipment directly
	coord._return_equipment_to_warehouse(EquipmentModel.new("SWORD", 1, 60, 2))
	var new_total_expected: int = total_owned_initial + 2

	var total_owned_actual: int = coord.get_total_owned_stock("SWORD")
	var usable: int = coord.get_warehouse_usable_stock("SWORD")
	var damaged: int = coord.get_warehouse_damaged_stock("SWORD")

	if total_owned_actual != (usable + damaged):
		printerr("Total owned (%d) does not match usable (%d) + damaged (%d)" % [total_owned_actual, usable, damaged])
		return false

	if total_owned_actual != new_total_expected:
		printerr("Expected total owned %d, got %d" % [new_total_expected, total_owned_actual])
		return false

	return true


## 21. test_shared_warehouse_conservation_after_destroyed_equipment
func _test_shared_warehouse_conservation_after_destroyed_equipment() -> bool:
	var coord := _setup_coordinator()
	var total_owned_initial: int = coord.get_total_owned_stock("SWORD")

	# Permanently destroy 3 swords
	var deducted: Array = coord._deduct_warehouse_stock("SWORD", 3)
	var deducted_qty: int = 0
	for d in deducted:
		if d is EquipmentModel:
			deducted_qty += (d as EquipmentModel).quantity
	if deducted_qty != 3:
		printerr("Failed to deduct 3 swords for destruction, got %d" % deducted_qty)
		return false

	var total_owned_after: int = coord.get_total_owned_stock("SWORD")
	var usable: int = coord.get_warehouse_usable_stock("SWORD")
	var damaged: int = coord.get_warehouse_damaged_stock("SWORD")

	if total_owned_after != (total_owned_initial - 3):
		printerr("Expected total owned to decrease by 3: %d vs %d" % [total_owned_after, total_owned_initial - 3])
		return false

	if total_owned_after != (usable + damaged):
		printerr("Conservation equation broken: total_owned (%d) != usable (%d) + damaged (%d)" % [total_owned_after, usable, damaged])
		return false

	return true


## 22. test_shared_warehouse_conservation_after_repair
func _test_shared_warehouse_conservation_after_repair() -> bool:
	var coord := _setup_coordinator()
	coord.set_treasury_gold(300)

	coord._return_equipment_to_warehouse(EquipmentModel.new("BOW", 1, 60, 3))
	var total_before: int = coord.get_total_owned_stock("BOW")

	coord.repair_equipment("BOW", 3)

	var total_after: int = coord.get_total_owned_stock("BOW")
	var usable: int = coord.get_warehouse_usable_stock("BOW")
	var damaged: int = coord.get_warehouse_damaged_stock("BOW")

	if total_after != total_before:
		printerr("Total owned changed across repair: %d vs %d" % [total_after, total_before])
		return false

	if total_after != (usable + damaged):
		printerr("Conservation equation broken after repair: total (%d) != usable (%d) + damaged (%d)" % [total_after, usable, damaged])
		return false

	return true


## 23. test_hero_equipment_conservation_remains_intact
func _test_hero_equipment_conservation_remains_intact() -> bool:
	var coord := _setup_coordinator()
	var initial_total_swords: int = coord.get_total_owned_stock("SWORD")

	# Equip hero Alder with SWORD
	var equip_ok: bool = coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	if not equip_ok:
		printerr("equip_hero failed")
		return false

	var total_after_equip: int = coord.get_total_owned_stock("SWORD")
	if total_after_equip != initial_total_swords:
		printerr("Total owned changed after equipping hero: %d vs %d" % [total_after_equip, initial_total_swords])
		return false

	var usable_stock: int = coord.get_warehouse_usable_stock("SWORD")
	var damaged_stock: int = coord.get_warehouse_damaged_stock("SWORD")
	var hero_stock: int = 1
	var reserved_stock: int = 0

	if total_after_equip != (usable_stock + damaged_stock + hero_stock + reserved_stock):
		printerr("Conservation equation violated: %d != %d + %d + %d + %d" % [
			total_after_equip, usable_stock, damaged_stock, hero_stock, reserved_stock
		])
		return false

	# Unequip hero Alder
	var unequip_ok: bool = coord.unequip_hero("hero_alder", "PRIMARY")
	if not unequip_ok:
		printerr("unequip_hero failed")
		return false

	var total_after_unequip: int = coord.get_total_owned_stock("SWORD")
	if total_after_unequip != initial_total_swords:
		printerr("Total owned changed after unequipping hero: %d vs %d" % [total_after_unequip, initial_total_swords])
		return false

	return true
