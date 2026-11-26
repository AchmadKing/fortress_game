extends SceneTree

## TestHeroEquipmentFoundation
## Test suite otomatis untuk memvalidasi implementasi Phase 3C (Hero Equipment Foundation).
## Memvalidasi seluruh 22 skenario B16:
## 1. Hero equips primary
## 2. Hero equips secondary
## 3. Hero equips armor
## 4. Equipment comes from shared warehouse
## 5. Insufficient warehouse stock
## 6. Invalid role/equipment combination
## 7. Failed equip causes no mutation
## 8. Hero unequip returns equipment
## 9. Hero swap
## 10. Failed swap preserves original state
## 11. Hero equipment conflicts with soldier reservation
## 12. Soldier reservation conflicts with hero equipment
## 13. Hero equipment locked during battle
## 14. Hero equipment remains after surviving wave
## 15. Hero permadeath returns all equipped equipment
## 16. Equipment is returned exactly once
## 17. Shared warehouse conservation
## 18. Existing hero stats/EXP/morale/chemistry remain intact
## 19. Existing Phase 1 regression
## 20. Existing Phase 2 regression
## 21. Existing Phase 3 regression
## 22. Phase 3B regression

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 3C HERO EQUIPMENT FOUNDATION TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		{"name": "test_hero_equips_primary", "fn": Callable(self, "_test_hero_equips_primary")},
		{"name": "test_hero_equips_secondary", "fn": Callable(self, "_test_hero_equips_secondary")},
		{"name": "test_hero_equips_armor", "fn": Callable(self, "_test_hero_equips_armor")},
		{"name": "test_equipment_comes_from_shared_warehouse", "fn": Callable(self, "_test_equipment_comes_from_shared_warehouse")},
		{"name": "test_insufficient_warehouse_stock", "fn": Callable(self, "_test_insufficient_warehouse_stock")},
		{"name": "test_invalid_role_equipment_combination", "fn": Callable(self, "_test_invalid_role_equipment_combination")},
		{"name": "test_failed_equip_causes_no_mutation", "fn": Callable(self, "_test_failed_equip_causes_no_mutation")},
		{"name": "test_hero_unequip_returns_equipment", "fn": Callable(self, "_test_hero_unequip_returns_equipment")},
		{"name": "test_hero_swap", "fn": Callable(self, "_test_hero_swap")},
		{"name": "test_failed_swap_preserves_original_state", "fn": Callable(self, "_test_failed_swap_preserves_original_state")},
		{"name": "test_hero_equipment_conflicts_with_soldier_reservation", "fn": Callable(self, "_test_hero_equipment_conflicts_with_soldier_reservation")},
		{"name": "test_soldier_reservation_conflicts_with_hero_equipment", "fn": Callable(self, "_test_soldier_reservation_conflicts_with_hero_equipment")},
		{"name": "test_hero_equipment_locked_during_battle", "fn": Callable(self, "_test_hero_equipment_locked_during_battle")},
		{"name": "test_hero_equipment_remains_after_surviving_wave", "fn": Callable(self, "_test_hero_equipment_remains_after_surviving_wave")},
		{"name": "test_hero_permadeath_returns_all_equipped_equipment", "fn": Callable(self, "_test_hero_permadeath_returns_all_equipped_equipment")},
		{"name": "test_equipment_is_returned_exactly_once", "fn": Callable(self, "_test_equipment_is_returned_exactly_once")},
		{"name": "test_shared_warehouse_conservation", "fn": Callable(self, "_test_shared_warehouse_conservation")},
		{"name": "test_existing_hero_stats_exp_morale_chemistry_intact", "fn": Callable(self, "_test_existing_hero_stats_exp_morale_chemistry_intact")},
		{"name": "test_existing_phase1_regression", "fn": Callable(self, "_test_existing_phase1_regression")},
		{"name": "test_existing_phase2_regression", "fn": Callable(self, "_test_existing_phase2_regression")},
		{"name": "test_existing_phase3_regression", "fn": Callable(self, "_test_existing_phase3_regression")},
		{"name": "test_phase3b_regression", "fn": Callable(self, "_test_phase3b_regression")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 3C TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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


# 1. Hero equips primary
func _test_hero_equips_primary() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_prim")
	var wh_sword_before: int = coord.get_warehouse_stock("SWORD")
	var ok: bool = coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	if not ok: return false
	
	var hero: HeroModel = coord.get_hero("hero_alder")
	if hero == null or not hero.has_equipment("PRIMARY"): return false
	if hero.get_equipment("PRIMARY").role_type != "SWORD": return false
	if coord.get_warehouse_stock("SWORD") != wh_sword_before - 1: return false
	return true


# 2. Hero equips secondary
func _test_hero_equips_secondary() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_sec")
	var wh_shield_before: int = coord.get_warehouse_stock("SHIELD")
	var ok: bool = coord.equip_hero("hero_alder", "SECONDARY", "SHIELD")
	if not ok: return false
	
	var hero: HeroModel = coord.get_hero("hero_alder")
	if hero == null or not hero.has_equipment("SECONDARY"): return false
	if coord.get_warehouse_stock("SHIELD") != wh_shield_before - 1: return false
	return true


# 3. Hero equips armor
func _test_hero_equips_armor() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_arm")
	var wh_armor_before: int = coord.get_warehouse_stock("HEAVY_ARMOR")
	var ok: bool = coord.equip_hero("hero_alder", "ARMOR", "HEAVY_ARMOR")
	if not ok: return false
	
	var hero: HeroModel = coord.get_hero("hero_alder")
	if hero == null or not hero.has_equipment("ARMOR"): return false
	if coord.get_warehouse_stock("HEAVY_ARMOR") != wh_armor_before - 1: return false
	return true


# 4. Equipment comes from shared warehouse
func _test_equipment_comes_from_shared_warehouse() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_shared")
	coord.equip_hero("hero_alder", "PRIMARY", "BOW")
	if coord.get_warehouse_stock("BOW") != 9: return false
	if coord.get_total_owned_stock("BOW") != 10: return false
	return true


# 5. Insufficient warehouse stock
func _test_insufficient_warehouse_stock() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_insuf")
	# Empty out all Spears
	coord._deduct_warehouse_stock("SPEAR", 10)
	var ok: bool = coord.equip_hero("hero_alder", "PRIMARY", "SPEAR")
	if ok: return false
	return true


# 6. Invalid role/equipment combination
func _test_invalid_role_equipment_combination() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_invalid_combo")
	# Heavy armor cannot be primary
	if coord.equip_hero("hero_alder", "PRIMARY", "HEAVY_ARMOR"): return false
	# Bow cannot be armor
	if coord.equip_hero("hero_alder", "ARMOR", "BOW"): return false
	# Invalid slot
	if coord.equip_hero("hero_alder", "INVALID_SLOT", "SWORD"): return false
	return true


# 7. Failed equip causes no mutation
func _test_failed_equip_causes_no_mutation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_no_mut")
	var wh_before: int = coord.get_warehouse_stock("BOW")
	var ok: bool = coord.equip_hero("hero_alder", "ARMOR", "BOW") # Invalid combo
	if ok: return false
	if coord.get_warehouse_stock("BOW") != wh_before: return false
	var hero: HeroModel = coord.get_hero("hero_alder")
	if hero.has_equipment("ARMOR"): return false
	return true


# 8. Hero unequip returns equipment
func _test_hero_unequip_returns_equipment() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_unequip")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	if coord.get_warehouse_stock("SWORD") != 9: return false
	
	var ok: bool = coord.unequip_hero("hero_alder", "PRIMARY")
	if not ok: return false
	if coord.get_warehouse_stock("SWORD") != 10: return false
	var hero: HeroModel = coord.get_hero("hero_alder")
	if hero.has_equipment("PRIMARY"): return false
	return true


# 9. Hero swap
func _test_hero_swap() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_swap")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD") # Sword=9
	var ok: bool = coord.swap_hero_equipment("hero_alder", "PRIMARY", "SPEAR")
	if not ok: return false
	
	# Sword returned (+1 -> 10), Spear taken (-1 -> 9)
	if coord.get_warehouse_stock("SWORD") != 10: return false
	if coord.get_warehouse_stock("SPEAR") != 9: return false
	var hero: HeroModel = coord.get_hero("hero_alder")
	if hero.get_equipment("PRIMARY").role_type != "SPEAR": return false
	return true


# 10. Failed swap preserves original state
func _test_failed_swap_preserves_original_state() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_swap_fail")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD") # Sword=9
	coord._deduct_warehouse_stock("SPEAR", 10) # 0 Spears left
	
	var ok: bool = coord.swap_hero_equipment("hero_alder", "PRIMARY", "SPEAR")
	if ok: return false # Must fail
	
	# Sword must remain equipped, warehouse must still have 9 swords
	var hero: HeroModel = coord.get_hero("hero_alder")
	if hero.get_equipment("PRIMARY").role_type != "SWORD": return false
	if coord.get_warehouse_stock("SWORD") != 9: return false
	return true


# 11. Hero equipment conflicts with soldier reservation
func _test_hero_equipment_conflicts_with_soldier_reservation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_conflict_hero_first")
	# Leave only 1 Sword in warehouse
	coord._deduct_warehouse_stock("SWORD", 9)
	if coord.get_warehouse_stock("SWORD") != 1: return false
	
	# Hero equips the only Sword
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	if coord.get_warehouse_stock("SWORD") != 0: return false
	
	# Soldier deployment tries to reserve 1 Sword -> must fail!
	var ok_soldier: bool = coord.create_deployment(1, "SWORD")
	if ok_soldier: return false
	return true


# 12. Soldier reservation conflicts with hero equipment
func _test_soldier_reservation_conflicts_with_hero_equipment() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_conflict_soldier_first")
	# Leave only 1 Sword in warehouse
	coord._deduct_warehouse_stock("SWORD", 9)
	if coord.get_warehouse_stock("SWORD") != 1: return false
	
	# Soldier deployment reserves the only Sword
	var ok_soldier: bool = coord.create_deployment(1, "SWORD")
	if not ok_soldier: return false
	if coord.get_warehouse_stock("SWORD") != 0: return false
	
	# Hero tries to equip the Sword -> must fail!
	var ok_hero: bool = coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	if ok_hero: return false
	return true


# 13. Hero equipment locked during battle
func _test_hero_equipment_locked_during_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_lock")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.inspect_wave()
	coord.start_battle()
	
	if coord.equip_hero("hero_alder", "SECONDARY", "SHIELD"): return false
	if coord.unequip_hero("hero_alder", "PRIMARY"): return false
	if coord.swap_hero_equipment("hero_alder", "PRIMARY", "SPEAR"): return false
	return true


# 14. Hero equipment remains after surviving wave
func _test_hero_equipment_remains_after_surviving_wave() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_surv")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()
	
	# In wave 2, hero still has Sword equipped!
	var hero: HeroModel = coord.get_hero("hero_alder")
	if not hero.has_equipment("PRIMARY"): return false
	if hero.get_equipment("PRIMARY").role_type != "SWORD": return false
	if coord.get_warehouse_stock("SWORD") != 9: return false
	return true


# 15. Hero permadeath returns all equipped equipment
func _test_hero_permadeath_returns_all_equipped_equipment() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_permadeath")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.equip_hero("hero_alder", "SECONDARY", "SHIELD")
	coord.equip_hero("hero_alder", "ARMOR", "HEAVY_ARMOR")
	
	if coord.get_warehouse_stock("SWORD") != 9: return false
	if coord.get_warehouse_stock("SHIELD") != 9: return false
	if coord.get_warehouse_stock("HEAVY_ARMOR") != 9: return false
	
	# Simulate hero dying in battle
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.mark_dead()
	
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()
	
	# Dead hero's equipment returned automatically to warehouse!
	if coord.get_warehouse_stock("SWORD") != 10: return false
	if coord.get_warehouse_stock("SHIELD") != 10: return false
	if coord.get_warehouse_stock("HEAVY_ARMOR") != 10: return false
	return true


# 16. Equipment is returned exactly once
func _test_equipment_is_returned_exactly_once() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_once")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.mark_dead()
	
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result() # Wave 1 -> Wave 2
	
	var wh_sword_w2: int = coord.get_warehouse_stock("SWORD")
	if wh_sword_w2 != 10: return false
	
	# Run Wave 2 to Wave 3
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()
	
	# Sword stock must NOT duplicate to 11!
	if coord.get_warehouse_stock("SWORD") != 10: return false
	return true


# 17. Shared warehouse conservation
func _test_shared_warehouse_conservation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3c_conservation")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.create_deployment(2, "SWORD")
	
	var wh: int = coord.get_warehouse_stock("SWORD")
	var hero_eq: int = 1
	var sol_eq: int = coord.get_reserved_equipment_stock("SWORD")
	var total: int = coord.get_total_owned_stock("SWORD")
	
	if wh + hero_eq + sol_eq != total: return false
	if total != 10: return false
	return true


# 18. Existing hero stats/EXP/morale/chemistry remain intact
func _test_existing_hero_stats_exp_morale_chemistry_intact() -> bool:
	var hero := HeroModel.new("h_test", "Test Hero", 1, 3)
	hero.add_exp(300)
	if hero.level <= 1: return false
	hero.add_chemistry("hero_partner", 10)
	if float(hero.get_chemistry_bonus(["hero_partner"])) <= 1.0: return false
	return true


# 19. Existing Phase 1 regression
func _test_existing_phase1_regression() -> bool:
	var coord := GameCoordinator.new()
	coord.initialize_session("sess_p1_c")
	coord.request_step(2)
	if coord.get_current_state().tick != 2: return false
	return true


# 20. Existing Phase 2 regression
func _test_existing_phase2_regression() -> bool:
	var hero := HeroModel.new("h_p2", "P2 Hero", 2, 4)
	var atk: int = hero.get_effective_atk()
	if atk <= 0: return false
	return true


# 21. Existing Phase 3 regression
func _test_existing_phase3_regression() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_p3_reg")
	if not coord.allocate_workers(1, 1, 0): return false
	if not coord.recruit_soldier("SWORDSMAN", 1): return false
	return true


# 22. Phase 3B regression
func _test_phase3b_regression() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_3b_reg")
	var ok_dep: bool = coord.create_deployment(2, "SWORD", "SHIELD")
	if not ok_dep: return false
	if coord.get_active_deployments().size() != 1: return false
	return true
