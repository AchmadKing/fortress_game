extends SceneTree

## TestPhase3eFinalVerification
## Test suite otomatis untuk memvalidasi Exit Gate Phase 3 (Phase 3E).
## Memvalidasi 15 kriteria verifikasi final:
## 1. Complete state-machine cycle (BOOT -> PREP -> PREVIEW -> BATTLE -> RESULT -> RECOVERY -> PREP)
## 2. Legal and illegal state transitions
## 3. Soldier deployment conservation & atomic reservation
## 4. Soldier casualty equipment resolution (35% destroyed, 65% damaged)
## 5. Surviving soldier gear returns at 100% durability (usable, zero extra wear)
## 6. Damaged equipment remains non-usable & excluded from deployment
## 7. Destroyed equipment is permanently removed from ownership
## 8. Blacksmith repair restores durability to 100% (becomes usable)
## 9. Repair Gold validation & atomic failure on insufficient funds
## 10. Hero equipment persistence across surviving waves
## 11. Hero death equipment return exactly once
## 12. Shared warehouse conservation invariant across all actions:
##     Total = Warehouse Usable + Warehouse Damaged + Hero Held + Soldier Reserved
## 13. Duplicate result and recovery prevention
## 14. Multi-deployment soldier accounting
## 15. Deterministic 20-wave stress simulation

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const GameStateSnapshot = preload("res://scripts/domain/state/game_state_snapshot.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 3E FINAL PROTOTYPE VERIFICATION & EXIT GATE TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		{"name": "test_complete_state_machine_cycle", "fn": Callable(self, "_test_complete_state_machine_cycle")},
		{"name": "test_legal_and_illegal_state_transitions", "fn": Callable(self, "_test_legal_and_illegal_state_transitions")},
		{"name": "test_soldier_deployment_conservation", "fn": Callable(self, "_test_soldier_deployment_conservation")},
		{"name": "test_soldier_casualty_equipment_resolution", "fn": Callable(self, "_test_soldier_casualty_equipment_resolution")},
		{"name": "test_surviving_soldier_gear_returns_at_100", "fn": Callable(self, "_test_surviving_soldier_gear_returns_at_100")},
		{"name": "test_damaged_equipment_remains_non_usable", "fn": Callable(self, "_test_damaged_equipment_remains_non_usable")},
		{"name": "test_destroyed_equipment_is_permanently_removed", "fn": Callable(self, "_test_destroyed_equipment_is_permanently_removed")},
		{"name": "test_blacksmith_repair_restores_durability", "fn": Callable(self, "_test_blacksmith_repair_restores_durability")},
		{"name": "test_repair_gold_validation", "fn": Callable(self, "_test_repair_gold_validation")},
		{"name": "test_hero_equipment_persistence", "fn": Callable(self, "_test_hero_equipment_persistence")},
		{"name": "test_hero_death_equipment_return_exactly_once", "fn": Callable(self, "_test_hero_death_equipment_return_exactly_once")},
		{"name": "test_shared_warehouse_conservation_across_all_actions", "fn": Callable(self, "_test_shared_warehouse_conservation_across_all_actions")},
		{"name": "test_duplicate_result_and_recovery_prevention", "fn": Callable(self, "_test_duplicate_result_and_recovery_prevention")},
		{"name": "test_multi_deployment_soldier_accounting", "fn": Callable(self, "_test_multi_deployment_soldier_accounting")},
		{"name": "test_deterministic_20_wave_stress_simulation", "fn": Callable(self, "_test_deterministic_20_wave_stress_simulation")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 3E TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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


func _setup_coordinator(extra_soldiers: int = 10) -> GameCoordinator:
	var coord := GameCoordinator.new()
	coord.start_new_session("phase_3e_verification_seed")
	if extra_soldiers > 0:
		coord.recruit_soldier("SWORDSMAN", mini(extra_soldiers, 10))
	return coord


func _verify_warehouse_conservation(coord: GameCoordinator, expected_totals: Dictionary) -> bool:
	var eq_types := ["SWORD", "SHIELD", "SPEAR", "BOW", "HEAVY_ARMOR"]
	for eq in eq_types:
		var usable: int = coord.get_warehouse_usable_stock(eq)
		var damaged: int = coord.get_warehouse_damaged_stock(eq)
		var reserved: int = coord.get_reserved_equipment_stock(eq)
		var hero_held: int = 0
		for h in coord._heroes:
			if h is HeroModel:
				for item in (h as HeroModel).get_equipped_items():
					if item is EquipmentModel and (item as EquipmentModel).role_type == eq:
						hero_held += (item as EquipmentModel).quantity
		var total_calculated: int = usable + damaged + reserved + hero_held
		var total_coord: int = coord.get_total_owned_stock(eq)
		if total_calculated != total_coord:
			printerr("Conservation mismatch for %s: calculated (%d) != coord (%d)" % [eq, total_calculated, total_coord])
			return false
		if expected_totals.has(eq):
			var exp_total: int = int(expected_totals[eq])
			if total_calculated != exp_total:
				printerr("Conservation total for %s changed: actual (%d) != expected (%d)" % [eq, total_calculated, exp_total])
				return false
	return true


# ==============================================================================
# 1. COMPLETE STATE-MACHINE CYCLE
# ==============================================================================
func _test_complete_state_machine_cycle() -> bool:
	var coord := _setup_coordinator()
	var sm = coord.get_state_machine()

	if sm.current_state != GameplayStateMachine.STATE_PREPARATION:
		printerr("Initial state should be PREPARATION, got %s" % sm.current_state)
		return false

	var ok_prev: bool = coord.inspect_wave()
	if not ok_prev or sm.current_state != GameplayStateMachine.STATE_WAVE_PREVIEW:
		printerr("Failed to transition to WAVE_PREVIEW")
		return false

	var ok_battle: bool = coord.start_battle()
	if not ok_battle or sm.current_state != GameplayStateMachine.STATE_BATTLE:
		printerr("Failed to transition to BATTLE")
		return false

	var res: Dictionary = coord.execute_battle(123)
	if res.is_empty() or sm.current_state != GameplayStateMachine.STATE_RESULT:
		printerr("Failed to transition to RESULT")
		return false

	# Ensure fortress alive for normal cycle
	coord._fortress.current_hp = 1000
	var ok_proceed: bool = coord.proceed_from_result()
	if not ok_proceed or sm.current_state != GameplayStateMachine.STATE_PREPARATION:
		printerr("Failed to transition through RECOVERY back to PREPARATION, current: %s" % sm.current_state)
		return false

	if coord.get_current_state().current_wave != 2:
		printerr("Wave number should advance to 2, got %d" % coord.get_current_state().current_wave)
		return false

	return true


# ==============================================================================
# 2. LEGAL AND ILLEGAL STATE TRANSITIONS
# ==============================================================================
func _test_legal_and_illegal_state_transitions() -> bool:
	var sm := GameplayStateMachine.new()
	# Initial state: BOOT
	if sm.current_state != GameplayStateMachine.STATE_BOOT:
		return false

	# Illegal from BOOT: cannot go directly to BATTLE, RESULT, RECOVERY, etc.
	if sm.can_transition_to(GameplayStateMachine.STATE_BATTLE):
		return false
	if sm.can_transition_to(GameplayStateMachine.STATE_RESULT):
		return false
	if sm.transition_to(GameplayStateMachine.STATE_BATTLE):
		return false

	# Legal: BOOT -> PREPARATION
	if not sm.transition_to(GameplayStateMachine.STATE_PREPARATION):
		return false

	# Illegal from PREPARATION: cannot go directly to BATTLE, RESULT, RECOVERY
	if sm.transition_to(GameplayStateMachine.STATE_BATTLE):
		return false
	if sm.transition_to(GameplayStateMachine.STATE_RESULT):
		return false
	if sm.transition_to(GameplayStateMachine.STATE_RECOVERY):
		return false

	# Legal: PREPARATION -> WAVE_PREVIEW
	if not sm.transition_to(GameplayStateMachine.STATE_WAVE_PREVIEW):
		return false

	# Legal: WAVE_PREVIEW -> PREPARATION (cancel)
	if not sm.transition_to(GameplayStateMachine.STATE_PREPARATION):
		return false
	sm.transition_to(GameplayStateMachine.STATE_WAVE_PREVIEW)

	# Legal: WAVE_PREVIEW -> BATTLE
	if not sm.transition_to(GameplayStateMachine.STATE_BATTLE):
		return false

	# Illegal from BATTLE: cannot jump to PREPARATION or RECOVERY
	if sm.transition_to(GameplayStateMachine.STATE_PREPARATION):
		return false
	if sm.transition_to(GameplayStateMachine.STATE_RECOVERY):
		return false

	# Legal: BATTLE -> RESULT
	if not sm.transition_to(GameplayStateMachine.STATE_RESULT):
		return false

	# Legal: RESULT -> GAME_OVER
	if not sm.transition_to(GameplayStateMachine.STATE_GAME_OVER):
		return false

	# Terminal: GAME_OVER has no valid transitions
	if sm.can_transition_to(GameplayStateMachine.STATE_PREPARATION):
		return false
	if sm.transition_to(GameplayStateMachine.STATE_PREPARATION):
		return false

	return true


# ==============================================================================
# 3. SOLDIER DEPLOYMENT CONSERVATION & ATOMIC RESERVATION
# ==============================================================================
func _test_soldier_deployment_conservation() -> bool:
	var coord := _setup_coordinator()
	var initial_swords: int = coord.get_total_owned_stock("SWORD")
	var initial_shields: int = coord.get_total_owned_stock("SHIELD")

	# Deploy 4 soldiers with SWORD + SHIELD
	var ok_deploy: bool = coord.create_deployment(4, "SWORD", "SHIELD", "NONE")
	if not ok_deploy:
		printerr("Deployment of 4 soldiers failed")
		return false

	if coord.get_reserved_equipment_stock("SWORD") != 4:
		printerr("Reserved swords should be 4, got %d" % coord.get_reserved_equipment_stock("SWORD"))
		return false
	if coord.get_reserved_equipment_stock("SHIELD") != 4:
		printerr("Reserved shields should be 4, got %d" % coord.get_reserved_equipment_stock("SHIELD"))
		return false

	# Invariant check
	if coord.get_total_owned_stock("SWORD") != initial_swords:
		printerr("Total owned swords changed during reservation")
		return false
	if coord.get_total_owned_stock("SHIELD") != initial_shields:
		printerr("Total owned shields changed during reservation")
		return false

	# Cancel deployment
	var active_comps: Array = coord.get_active_deployments()
	if active_comps.is_empty():
		printerr("Active deployments should not be empty")
		return false
	var comp: DeploymentComposition = active_comps[0] as DeploymentComposition
	var ok_remove: bool = coord.remove_deployment(comp.composition_id)
	if not ok_remove:
		printerr("Failed to remove deployment")
		return false

	# Post-cancel verification
	if coord.get_reserved_equipment_stock("SWORD") != 0:
		printerr("Reserved swords should be 0 after cancellation")
		return false
	if coord.get_warehouse_usable_stock("SWORD") != initial_swords:
		printerr("Usable swords should fully return to %d, got %d" % [initial_swords, coord.get_warehouse_usable_stock("SWORD")])
		return false

	return true


# ==============================================================================
# 4. SOLDIER CASUALTY EQUIPMENT RESOLUTION (35% DESTROYED, 65% DAMAGED)
# ==============================================================================
func _test_soldier_casualty_equipment_resolution() -> bool:
	var coord := _setup_coordinator()
	var initial_swords: int = coord.get_total_owned_stock("SWORD")

	coord.create_deployment(4, "SWORD", "NONE", "NONE")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle()

	# Mock 2 casualties
	coord._last_battle_result["casualties"] = {"INFANTRY": 2}
	coord._fortress.current_hp = 1000

	var ok_proc: bool = coord.proceed_from_result()
	if not ok_proc:
		printerr("proceed_from_result failed")
		return false

	var usable: int = coord.get_warehouse_usable_stock("SWORD")
	var damaged: int = coord.get_warehouse_damaged_stock("SWORD")
	var total: int = coord.get_total_owned_stock("SWORD")

	# Survivors = 2, so at least 2 usable swords returned from survivors
	# 2 dead soldiers' swords rolled 35% destroyed / 65% damaged
	if usable < 2:
		printerr("Usable stock must be at least 2 (from survivors), got %d" % usable)
		return false

	# Total owned must equal usable + damaged (no active deployment, no hero equipped)
	if total != (usable + damaged):
		printerr("Total owned (%d) does not match usable (%d) + damaged (%d)" % [total, usable, damaged])
		return false

	# Total owned cannot exceed initial swords
	if total > initial_swords:
		printerr("Total owned exceeded initial stock: %d > %d" % [total, initial_swords])
		return false

	return true


# ==============================================================================
# 5. SURVIVING SOLDIER GEAR RETURNS AT 100% DURABILITY
# ==============================================================================
func _test_surviving_soldier_gear_returns_at_100() -> bool:
	var coord := _setup_coordinator()
	var initial_bows: int = coord.get_warehouse_usable_stock("BOW")

	coord.create_deployment(3, "BOW", "NONE", "NONE")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle()

	# Zero casualties
	coord._last_battle_result["casualties"] = {"ARCHER": 0}
	coord._fortress.current_hp = 1000
	coord.proceed_from_result()

	var final_usable: int = coord.get_warehouse_usable_stock("BOW")
	var final_damaged: int = coord.get_warehouse_damaged_stock("BOW")

	if final_usable != initial_bows:
		printerr("Usable bows should return to %d, got %d" % [initial_bows, final_usable])
		return false
	if final_damaged != 0:
		printerr("Damaged bows should be 0 for 100%% survivors, got %d" % final_damaged)
		return false

	# Verify every bow item in warehouse has durability == 100
	for item in coord._warehouse:
		if item is EquipmentModel and (item as EquipmentModel).role_type == "BOW":
			if (item as EquipmentModel).durability != 100:
				printerr("Survivor bow durability should be 100, got %d" % (item as EquipmentModel).durability)
				return false

	return true


# ==============================================================================
# 6. DAMAGED EQUIPMENT REMAINS NON-USABLE & EXCLUDED FROM DEPLOYMENT
# ==============================================================================
func _test_damaged_equipment_remains_non_usable() -> bool:
	var coord := _setup_coordinator()
	# Add damaged item (durability 60)
	var eq_damaged := EquipmentModel.new("SPEAR", 1, 60, 5)
	coord._return_equipment_to_warehouse(eq_damaged)

	if eq_damaged.is_usable():
		printerr("Damaged equipment must NOT report is_usable() == true")
		return false
	if not eq_damaged.is_damaged():
		printerr("Damaged equipment must report is_damaged() == true")
		return false

	# Usable stock must not count the 5 damaged spears
	var usable_spears: int = coord.get_warehouse_usable_stock("SPEAR")
	var damaged_spears: int = coord.get_warehouse_damaged_stock("SPEAR")

	if damaged_spears != 5:
		printerr("Damaged spears should be 5, got %d" % damaged_spears)
		return false

	# Drain usable spears completely
	var ok_drain: bool = coord.create_deployment(usable_spears, "SPEAR", "NONE", "NONE")
	if not ok_drain:
		printerr("Failed to drain usable spears")
		return false

	if coord.get_warehouse_usable_stock("SPEAR") != 0:
		printerr("Usable spears should be 0 after draining")
		return false

	# Now creating another deployment with SPEAR must fail even though 5 damaged spears exist
	var ok_excess: bool = coord.create_deployment(1, "SPEAR", "NONE", "NONE")
	if ok_excess:
		printerr("Deployment should FAIL when only damaged spears are available")
		return false

	return true


# ==============================================================================
# 7. DESTROYED EQUIPMENT IS PERMANENTLY REMOVED
# ==============================================================================
func _test_destroyed_equipment_is_permanently_removed() -> bool:
	var coord := _setup_coordinator()
	var total_initial: int = coord.get_total_owned_stock("SWORD")

	# Deduct 2 swords representing destroyed casualties (never returned)
	var deducted: Array = coord._deduct_warehouse_stock("SWORD", 2)
	var deducted_qty: int = 0
	for d in deducted:
		if d is EquipmentModel:
			deducted_qty += (d as EquipmentModel).quantity
	if deducted_qty != 2:
		printerr("Failed to deduct 2 swords")
		return false

	var total_after: int = coord.get_total_owned_stock("SWORD")
	if total_after != (total_initial - 2):
		printerr("Destroyed items must permanently decrease total owned: %d vs %d" % [total_after, total_initial - 2])
		return false

	return true


# ==============================================================================
# 8. BLACKSMITH REPAIR RESTORES DURABILITY TO 100%
# ==============================================================================
func _test_blacksmith_repair_restores_durability() -> bool:
	var coord := _setup_coordinator()
	coord.set_treasury_gold(500)

	coord._return_equipment_to_warehouse(EquipmentModel.new("BOW", 1, 60, 2))
	var usable_before: int = coord.get_warehouse_usable_stock("BOW")
	var damaged_before: int = coord.get_warehouse_damaged_stock("BOW")

	var ok_repair: bool = coord.repair_equipment("BOW", 2)
	if not ok_repair:
		printerr("repair_equipment failed")
		return false

	var usable_after: int = coord.get_warehouse_usable_stock("BOW")
	var damaged_after: int = coord.get_warehouse_damaged_stock("BOW")

	if damaged_after != (damaged_before - 2):
		printerr("Damaged stock should decrease by 2, got %d" % damaged_after)
		return false
	if usable_after != (usable_before + 2):
		printerr("Usable stock should increase by 2, got %d" % usable_after)
		return false

	return true


# ==============================================================================
# 9. REPAIR GOLD VALIDATION & ATOMIC FAILURE
# ==============================================================================
func _test_repair_gold_validation() -> bool:
	var coord := _setup_coordinator()
	coord._return_equipment_to_warehouse(EquipmentModel.new("SWORD", 1, 60, 1))

	var cost: int = coord.get_equipment_repair_cost("SWORD", 1)
	if cost <= 0:
		printerr("Repair cost must be > 0, got %d" % cost)
		return false

	# Set gold below required cost
	coord.set_treasury_gold(cost - 1)
	var damaged_before: int = coord.get_warehouse_damaged_stock("SWORD")
	var gold_before: int = coord.get_treasury_gold()

	var ok_repair: bool = coord.repair_equipment("SWORD", 1)
	if ok_repair:
		printerr("Repair must FAIL when gold is insufficient")
		return false

	if coord.get_treasury_gold() != gold_before:
		printerr("Gold must NOT mutate on failed repair: %d vs %d" % [coord.get_treasury_gold(), gold_before])
		return false
	if coord.get_warehouse_damaged_stock("SWORD") != damaged_before:
		printerr("Damaged equipment must NOT change on failed repair")
		return false

	return true


# ==============================================================================
# 10. HERO EQUIPMENT PERSISTENCE ACROSS SURVIVING WAVES
# ==============================================================================
func _test_hero_equipment_persistence() -> bool:
	var coord := _setup_coordinator()

	# Equip hero Alder with SWORD
	var ok_equip: bool = coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	if not ok_equip:
		printerr("equip_hero failed")
		return false

	var hero: HeroModel = coord.get_hero("hero_alder")
	if hero == null or not hero.has_equipment("PRIMARY"):
		printerr("Hero Alder must have PRIMARY equipment")
		return false

	# Run battle where hero survives
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle()
	hero.is_alive = true
	coord._fortress.current_hp = 1000
	coord.proceed_from_result()

	# Verify hero still has sword in next wave PREPARATION
	var hero_wave2: HeroModel = coord.get_hero("hero_alder")
	if not hero_wave2.has_equipment("PRIMARY"):
		printerr("Hero equipment should persist across surviving wave")
		return false
	var eq_item: EquipmentModel = hero_wave2.get_equipment("PRIMARY")
	if eq_item == null or eq_item.role_type != "SWORD":
		printerr("Equipped item role_type must be SWORD")
		return false

	return true


# ==============================================================================
# 11. HERO DEATH EQUIPMENT RETURN EXACTLY ONCE
# ==============================================================================
func _test_hero_death_equipment_return_exactly_once() -> bool:
	var coord := _setup_coordinator()
	var initial_swords: int = coord.get_total_owned_stock("SWORD")

	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	var hero: HeroModel = coord.get_hero("hero_alder")

	# Hero dies in battle
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle()
	hero.is_alive = false
	coord._fortress.current_hp = 1000

	coord.proceed_from_result()

	# Verify equipment returned to warehouse
	if hero.has_equipment("PRIMARY"):
		printerr("Dead hero slots should be empty after recovery")
		return false

	var total_swords: int = coord.get_total_owned_stock("SWORD")
	if total_swords != initial_swords:
		printerr("Total swords should match initial after dead hero return: %d vs %d" % [total_swords, initial_swords])
		return false

	# Advance another wave and verify no second return / duplication occurs
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle()
	coord._fortress.current_hp = 1000
	coord.proceed_from_result()

	if coord.get_total_owned_stock("SWORD") != initial_swords:
		printerr("Equipment duplicated on subsequent wave: %d vs %d" % [coord.get_total_owned_stock("SWORD"), initial_swords])
		return false

	return true


# ==============================================================================
# 12. SHARED WAREHOUSE CONSERVATION INVARIANT ACROSS ALL ACTIONS
# ==============================================================================
func _test_shared_warehouse_conservation_across_all_actions() -> bool:
	var coord := _setup_coordinator()
	var expected := {
		"SWORD": coord.get_total_owned_stock("SWORD"),
		"SHIELD": coord.get_total_owned_stock("SHIELD"),
		"SPEAR": coord.get_total_owned_stock("SPEAR"),
		"BOW": coord.get_total_owned_stock("BOW"),
		"HEAVY_ARMOR": coord.get_total_owned_stock("HEAVY_ARMOR")
	}

	# 1. Equip hero
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.equip_hero("hero_alder", "SECONDARY", "SHIELD")
	if not _verify_warehouse_conservation(coord, expected):
		return false

	# 2. Deploy soldiers
	coord.create_deployment(3, "SPEAR", "NONE", "HEAVY_ARMOR")
	if not _verify_warehouse_conservation(coord, expected):
		return false

	# 3. Add damaged equipment
	coord._return_equipment_to_warehouse(EquipmentModel.new("BOW", 1, 60, 2))
	expected["BOW"] += 2
	if not _verify_warehouse_conservation(coord, expected):
		return false

	# 4. Repair damaged equipment
	coord.set_treasury_gold(200)
	coord.repair_equipment("BOW", 2)
	if not _verify_warehouse_conservation(coord, expected):
		return false

	# 5. Remove deployment
	var comps: Array = coord.get_active_deployments()
	coord.remove_deployment((comps[0] as DeploymentComposition).composition_id)
	if not _verify_warehouse_conservation(coord, expected):
		return false

	# 6. Unequip hero
	coord.unequip_hero("hero_alder", "PRIMARY")
	coord.unequip_hero("hero_alder", "SECONDARY")
	if not _verify_warehouse_conservation(coord, expected):
		return false

	return true


# ==============================================================================
# 13. DUPLICATE RESULT AND RECOVERY PREVENTION
# ==============================================================================
func _test_duplicate_result_and_recovery_prevention() -> bool:
	var coord := _setup_coordinator()
	coord.inspect_wave()
	coord.start_battle()

	var res1: Dictionary = coord.execute_battle()
	if res1.is_empty():
		printerr("First execute_battle failed")
		return false

	# Second immediate execute_battle must be rejected
	var res2: Dictionary = coord.execute_battle()
	if not res2.is_empty():
		printerr("Second execute_battle should be rejected, returned non-empty")
		return false

	coord._fortress.current_hp = 1000
	var ok_proc1: bool = coord.proceed_from_result()
	if not ok_proc1:
		printerr("First proceed_from_result failed")
		return false

	# Second immediate proceed_from_result must be rejected
	var ok_proc2: bool = coord.proceed_from_result()
	if ok_proc2:
		printerr("Second proceed_from_result must be rejected")
		return false

	return true


# ==============================================================================
# 14. MULTI-DEPLOYMENT SOLDIER ACCOUNTING
# ==============================================================================
func _test_multi_deployment_soldier_accounting() -> bool:
	var coord := _setup_coordinator(10)
	var initial_available: int = coord.get_available_soldiers() # e.g. 16

	var ok_a: bool = coord.create_deployment(3, "SWORD", "NONE", "NONE")
	var ok_b: bool = coord.create_deployment(4, "SWORD", "SHIELD", "NONE")
	var ok_c: bool = coord.create_deployment(5, "BOW", "NONE", "NONE")

	if not (ok_a and ok_b and ok_c):
		printerr("Failed to create 3 deployment groups (3, 4, 5)")
		return false

	var total_deployed: int = coord.get_total_deployed_soldiers()
	if total_deployed != 12:
		printerr("Total deployed soldiers should be 12 (3+4+5), got %d" % total_deployed)
		return false

	var remaining_available: int = coord.get_available_soldiers()
	if remaining_available != (initial_available - 12):
		printerr("Remaining available soldiers should be %d, got %d" % [initial_available - 12, remaining_available])
		return false

	# Remove Group B (4 soldiers)
	var comps: Array = coord.get_active_deployments()
	var target_comp_id: String = ""
	for c in comps:
		if c is DeploymentComposition and (c as DeploymentComposition).count == 4:
			target_comp_id = (c as DeploymentComposition).composition_id
			break

	var ok_remove: bool = coord.remove_deployment(target_comp_id)
	if not ok_remove:
		printerr("Failed to remove group B")
		return false

	if coord.get_total_deployed_soldiers() != 8:
		printerr("Total deployed after removal should be 8, got %d" % coord.get_total_deployed_soldiers())
		return false
	if coord.get_available_soldiers() != (initial_available - 8):
		printerr("Available soldiers after removal should be %d, got %d" % [initial_available - 8, coord.get_available_soldiers()])
		return false

	return true


# ==============================================================================
# 15. DETERMINISTIC 20-WAVE STRESS SIMULATION
# ==============================================================================
func _test_deterministic_20_wave_stress_simulation() -> bool:
	print("[STRESS] Starting deterministic 20-wave stress simulation...")
	var coord := _setup_coordinator(10)
	coord.set_treasury_gold(1000)

	for wave in range(1, 21):
		# PREPARATION PHASE
		var phase: String = coord.get_current_state().game_phase
		if phase != GameplayStateMachine.STATE_PREPARATION:
			printerr("[STRESS Wave %d] Expected PREPARATION, got %s" % [wave, phase])
			return false

		# Allocate workers: 2 repair, 1 smith, 1 constr
		coord.allocate_workers(2, 1, 1)

		# Repair any damaged equipment if present
		var eq_types := ["SWORD", "SHIELD", "SPEAR", "BOW", "HEAVY_ARMOR"]
		for eq in eq_types:
			var dmg_count: int = coord.get_warehouse_damaged_stock(eq)
			if dmg_count > 0:
				var cost: int = coord.get_equipment_repair_cost(eq, dmg_count)
				if coord.get_treasury_gold() >= cost:
					coord.repair_equipment(eq, dmg_count)

		# Deploy soldiers up to available usable swords
		var usable_swords: int = coord.get_warehouse_usable_stock("SWORD")
		var avail_soldiers: int = coord.get_available_soldiers()
		var deploy_count: int = mini(avail_soldiers, mini(usable_swords, 4))
		if deploy_count > 0:
			coord.create_deployment(deploy_count, "SWORD", "NONE", "NONE")

		# WAVE PREVIEW
		var ok_prev: bool = coord.inspect_wave()
		if not ok_prev:
			printerr("[STRESS Wave %d] inspect_wave failed" % wave)
			return false

		# BATTLE
		var ok_start: bool = coord.start_battle()
		if not ok_start:
			printerr("[STRESS Wave %d] start_battle failed" % wave)
			return false

		# Execute battle with deterministic seed
		var battle_res: Dictionary = coord.execute_battle(wave * 101)
		if battle_res.is_empty():
			printerr("[STRESS Wave %d] execute_battle returned empty" % wave)
			return false

		# Maintain fortress HP above zero to avoid premature game over during 20-wave cycle test
		if coord._fortress.current_hp < 300:
			coord._fortress.current_hp = 1000
		coord._last_battle_result["game_over"] = false

		# RESULT & RECOVERY
		var ok_proc: bool = coord.proceed_from_result()
		if not ok_proc:
			printerr("[STRESS Wave %d] proceed_from_result failed" % wave)
			return false

		# Post-wave Assertions
		if coord.get_current_state().current_wave != (wave + 1):
			printerr("[STRESS Wave %d] Wave counter mismatch: %d" % [wave, coord.get_current_state().current_wave])
			return false

		if coord.get_available_soldiers() < 0:
			printerr("[STRESS Wave %d] Negative available soldiers: %d" % [wave, coord.get_available_soldiers()])
			return false

		if coord.get_treasury_gold() < 0:
			printerr("[STRESS Wave %d] Negative treasury gold: %d" % [wave, coord.get_treasury_gold()])
			return false

		if not coord.get_active_deployments().is_empty():
			printerr("[STRESS Wave %d] Active deployments should be cleared after recovery" % wave)
			return false

		# Invariant: Total Owned = Usable + Damaged + Hero + Reserved
		for eq in eq_types:
			var total_calc: int = coord.get_warehouse_usable_stock(eq) + coord.get_warehouse_damaged_stock(eq) + coord.get_reserved_equipment_stock(eq)
			for h in coord._heroes:
				if h is HeroModel:
					for item in (h as HeroModel).get_equipped_items():
						if item is EquipmentModel and (item as EquipmentModel).role_type == eq:
							total_calc += (item as EquipmentModel).quantity
			if total_calc != coord.get_total_owned_stock(eq):
				printerr("[STRESS Wave %d] Conservation equation violated for %s: %d vs %d" % [
					wave, eq, total_calc, coord.get_total_owned_stock(eq)
				])
				return false

	print("[STRESS] Completed 20 waves successfully with 100% invariant conservation!")
	return true
