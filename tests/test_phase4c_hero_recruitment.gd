extends SceneTree

## TestPhase4CHeroRecruitment
## Test suite otomatis untuk memvalidasi implementasi Phase 4C:
## Hero Recruitment & Roster Management.
## Memvalidasi proses rekrutmen pahlawan, identitas unik deterministik,
## validasi peran dan bintang, inisialisasi state awal (level 1, 0 EXP, gear kosong),
## integritas dan kepemilikan roster benteng, serialisasi snapshot telemetri,
## serta atomisitas transaksi kas emas dan proteksi Battle Lock.

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 4C HERO RECRUITMENT & ROSTER MANAGEMENT TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# Recruitment (1-11)
		{"name": "test_valid_recruitment_succeeds", "fn": Callable(self, "_test_valid_recruitment_succeeds")},
		{"name": "test_recruited_hero_enters_roster_active", "fn": Callable(self, "_test_recruited_hero_enters_roster_active")},
		{"name": "test_recruitment_deducts_exact_gold", "fn": Callable(self, "_test_recruitment_deducts_exact_gold")},
		{"name": "test_exact_gold_amount_succeeds", "fn": Callable(self, "_test_exact_gold_amount_succeeds")},
		{"name": "test_insufficient_gold_fails", "fn": Callable(self, "_test_insufficient_gold_fails")},
		{"name": "test_insufficient_gold_leaves_gold_unchanged", "fn": Callable(self, "_test_insufficient_gold_leaves_gold_unchanged")},
		{"name": "test_insufficient_gold_leaves_roster_unchanged", "fn": Callable(self, "_test_insufficient_gold_leaves_roster_unchanged")},
		{"name": "test_successful_recruitment_increases_roster_size", "fn": Callable(self, "_test_successful_recruitment_increases_roster_size")},
		{"name": "test_failed_recruitment_does_not_increase_roster_size", "fn": Callable(self, "_test_failed_recruitment_does_not_increase_roster_size")},
		{"name": "test_gold_with_surplus_501_leaves_1_gold", "fn": Callable(self, "_test_gold_with_surplus_501_leaves_1_gold")},
		{"name": "test_no_custom_cost_override_parameter_exists", "fn": Callable(self, "_test_no_custom_cost_override_parameter_exists")},

		# Identity (12-17)
		{"name": "test_hero_id_is_generated", "fn": Callable(self, "_test_hero_id_is_generated")},
		{"name": "test_hero_id_is_unique", "fn": Callable(self, "_test_hero_id_is_unique")},
		{"name": "test_duplicate_hero_id_rejected", "fn": Callable(self, "_test_duplicate_hero_id_rejected")},
		{"name": "test_hero_id_survives_roster_reordering", "fn": Callable(self, "_test_hero_id_survives_roster_reordering")},
		{"name": "test_hero_lookup_by_id_works", "fn": Callable(self, "_test_hero_lookup_by_id_works")},
		{"name": "test_missing_hero_lookup_fails_safely", "fn": Callable(self, "_test_missing_hero_lookup_fails_safely")},

		# Validation (18-25)
		{"name": "test_invalid_role_rejected", "fn": Callable(self, "_test_invalid_role_rejected")},
		{"name": "test_current_star_less_than_one_rejected", "fn": Callable(self, "_test_current_star_less_than_one_rejected")},
		{"name": "test_current_star_greater_than_five_rejected", "fn": Callable(self, "_test_current_star_greater_than_five_rejected")},
		{"name": "test_potential_star_less_than_current_star_rejected", "fn": Callable(self, "_test_potential_star_less_than_current_star_rejected")},
		{"name": "test_potential_star_greater_than_five_rejected", "fn": Callable(self, "_test_potential_star_greater_than_five_rejected")},
		{"name": "test_invalid_level_rejected", "fn": Callable(self, "_test_invalid_level_rejected")},
		{"name": "test_invalid_generated_hero_rejected", "fn": Callable(self, "_test_invalid_generated_hero_rejected")},
		{"name": "test_valid_potential_star_progression_accepted", "fn": Callable(self, "_test_valid_potential_star_progression_accepted")},

		# Initial State (26-33)
		{"name": "test_new_hero_starts_at_level_1", "fn": Callable(self, "_test_new_hero_starts_at_level_1")},
		{"name": "test_new_hero_starts_at_zero_exp", "fn": Callable(self, "_test_new_hero_starts_at_zero_exp")},
		{"name": "test_new_hero_has_valid_current_star", "fn": Callable(self, "_test_new_hero_has_valid_current_star")},
		{"name": "test_new_hero_has_valid_potential_star", "fn": Callable(self, "_test_new_hero_has_valid_potential_star")},
		{"name": "test_new_hero_starts_with_empty_equipment", "fn": Callable(self, "_test_new_hero_starts_with_empty_equipment")},
		{"name": "test_new_hero_has_valid_fatigue", "fn": Callable(self, "_test_new_hero_has_valid_fatigue")},
		{"name": "test_new_hero_has_valid_morale", "fn": Callable(self, "_test_new_hero_has_valid_morale")},
		{"name": "test_new_hero_has_valid_chemistry_map", "fn": Callable(self, "_test_new_hero_has_valid_chemistry_map")},

		# Roster Ownership (34-38)
		{"name": "test_roster_contains_only_valid_heroes", "fn": Callable(self, "_test_roster_contains_only_valid_heroes")},
		{"name": "test_duplicate_insertion_rejected", "fn": Callable(self, "_test_duplicate_insertion_rejected")},
		{"name": "test_stable_roster_lookup_works_after_adding_multiple_heroes", "fn": Callable(self, "_test_stable_roster_lookup_works_after_adding_multiple_heroes")},
		{"name": "test_removal_reordering_does_not_corrupt_remaining_heroes", "fn": Callable(self, "_test_removal_reordering_does_not_corrupt_remaining_heroes")},
		{"name": "test_dismiss_hero_returns_equipment_to_warehouse", "fn": Callable(self, "_test_dismiss_hero_returns_equipment_to_warehouse")},

		# Snapshot (39-43)
		{"name": "test_hero_roster_snapshot_preserves_identity", "fn": Callable(self, "_test_hero_roster_snapshot_preserves_identity")},
		{"name": "test_snapshot_preserves_progression_fields", "fn": Callable(self, "_test_snapshot_preserves_progression_fields")},
		{"name": "test_snapshot_preserves_lifecycle_state", "fn": Callable(self, "_test_snapshot_preserves_lifecycle_state")},
		{"name": "test_snapshot_preserves_equipment_references_state", "fn": Callable(self, "_test_snapshot_preserves_equipment_references_state")},
		{"name": "test_snapshot_preserves_chemistry_map", "fn": Callable(self, "_test_snapshot_preserves_chemistry_map")},

		# Transaction Safety (44-48)
		{"name": "test_failed_hero_generation_does_not_consume_gold", "fn": Callable(self, "_test_failed_hero_generation_does_not_consume_gold")},
		{"name": "test_failed_roster_insertion_does_not_consume_gold", "fn": Callable(self, "_test_failed_roster_insertion_does_not_consume_gold")},
		{"name": "test_successful_recruitment_consumes_gold_exactly_once", "fn": Callable(self, "_test_successful_recruitment_consumes_gold_exactly_once")},
		{"name": "test_hero_is_added_exactly_once", "fn": Callable(self, "_test_hero_is_added_exactly_once")},
		{"name": "test_duplicate_recruitment_request_cannot_duplicate_same_hero_id", "fn": Callable(self, "_test_duplicate_recruitment_request_cannot_duplicate_same_hero_id")},

		# Supplementary Constraints (49-51)
		{"name": "test_recruitment_blocked_during_battle_state", "fn": Callable(self, "_test_recruitment_blocked_during_battle_state")},
		{"name": "test_candidate_with_existing_equipment_rejected", "fn": Callable(self, "_test_candidate_with_existing_equipment_rejected")},
		{"name": "test_candidate_with_invalid_initial_lifecycle_state_rejected", "fn": Callable(self, "_test_candidate_with_invalid_initial_lifecycle_state_rejected")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 4C TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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
# RECRUITMENT (1-9)
# ==============================================================================

func _test_valid_recruitment_succeeds() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rec_1")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.KNIGHT)
	return hero != null and hero.role == HeroRole.KNIGHT


func _test_recruited_hero_enters_roster_active() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rec_2")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.ARCHER)
	return hero != null and hero.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE


func _test_recruitment_deducts_exact_gold() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rec_3")
	coord.set_treasury_gold(1000)
	var cost: int = coord.get_hero_recruitment_cost() # 500
	if cost != 500:
		return false
	var hero: HeroModel = coord.recruit_hero()
	return hero != null and coord.get_treasury_gold() == 500


func _test_exact_gold_amount_succeeds() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rec_4")
	coord.set_treasury_gold(500)
	var hero: HeroModel = coord.recruit_hero()
	return hero != null and coord.get_treasury_gold() == 0


func _test_insufficient_gold_fails() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rec_5")
	coord.set_treasury_gold(499)
	var hero: HeroModel = coord.recruit_hero()
	return hero == null and coord.get_treasury_gold() == 499


func _test_insufficient_gold_leaves_gold_unchanged() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rec_6")
	coord.set_treasury_gold(350)
	var hero: HeroModel = coord.recruit_hero()
	return hero == null and coord.get_treasury_gold() == 350


func _test_insufficient_gold_leaves_roster_unchanged() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rec_7")
	var count_before: int = coord.get_roster_count()
	coord.set_treasury_gold(100)
	var hero: HeroModel = coord.recruit_hero()
	return hero == null and coord.get_roster_count() == count_before


func _test_successful_recruitment_increases_roster_size() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rec_8")
	var count_before: int = coord.get_roster_count()
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero()
	return hero != null and coord.get_roster_count() == count_before + 1


func _test_failed_recruitment_does_not_increase_roster_size() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rec_9")
	var count_before: int = coord.get_roster_count()
	coord.set_treasury_gold(50)
	coord.recruit_hero()
	return coord.get_roster_count() == count_before


func _test_gold_with_surplus_501_leaves_1_gold() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rec_501")
	coord.set_treasury_gold(501)
	var hero: HeroModel = coord.recruit_hero()
	return hero != null and coord.get_treasury_gold() == 1


func _test_no_custom_cost_override_parameter_exists() -> bool:
	var coord := GameCoordinator.new()
	var method_found := false
	var arg_count := 0
	for m in coord.get_method_list():
		if m.get("name") == "recruit_hero":
			method_found = true
			var args: Array = m.get("args", [])
			arg_count = args.size()
			for arg in args:
				var arg_name: String = str(arg.get("name", ""))
				if arg_name == "recruitment_cost" or arg_name == "cost":
					return false
			break
	return method_found and arg_count == 5


# ==============================================================================
# IDENTITY (10-15)
# ==============================================================================

func _test_hero_id_is_generated() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_id_10")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero()
	return hero != null and not hero.hero_id.strip_edges().is_empty()


func _test_hero_id_is_unique() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_id_11")
	coord.set_treasury_gold(2000)
	var h1: HeroModel = coord.recruit_hero()
	var h2: HeroModel = coord.recruit_hero()
	return h1 != null and h2 != null and h1.hero_id != h2.hero_id


func _test_duplicate_hero_id_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_id_12")
	coord.set_treasury_gold(2000)
	# Attempt to recruit with ID of Alder which already exists
	var duplicate: HeroModel = coord.recruit_hero(HeroRole.KNIGHT, 1, 3, "hero_alder")
	return duplicate == null and coord.get_roster_count() == 2


func _test_hero_id_survives_roster_reordering() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_id_13")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.MAGE, 1, 3, "hero_unique_mage")
	if hero == null:
		return false
	# Dismiss alder (first hero), verifying remaining mage keeps ID
	var dismissed: bool = coord.dismiss_hero("hero_alder")
	var remaining: HeroModel = coord.get_hero("hero_unique_mage")
	return dismissed and remaining != null and remaining.hero_id == "hero_unique_mage"


func _test_hero_lookup_by_id_works() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_id_14")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.PRIEST, 1, 4, "hero_my_priest")
	var lookup: HeroModel = coord.get_hero("hero_my_priest")
	return lookup != null and lookup == hero


func _test_missing_hero_lookup_fails_safely() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_id_15")
	var lookup: HeroModel = coord.get_hero("non_existent_hero_id")
	return lookup == null


# ==============================================================================
# VALIDATION (16-23)
# ==============================================================================

func _test_invalid_role_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_val_16")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero("INVALID_ROLE_WARLOCK")
	return hero == null


func _test_current_star_less_than_one_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_val_17")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.KNIGHT, 0, 3)
	return hero == null


func _test_current_star_greater_than_five_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_val_18")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.KNIGHT, 6, 6)
	return hero == null


func _test_potential_star_less_than_current_star_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_val_19")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.KNIGHT, 4, 2)
	return hero == null


func _test_potential_star_greater_than_five_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_val_20")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.KNIGHT, 2, 6)
	return hero == null


func _test_invalid_level_rejected() -> bool:
	var hero := HeroModel.new("h_inv_lvl", "InvalidLevel", 1, 3)
	hero.level = 0
	if hero.validate_invariants():
		return false
	hero.level = 15 # Melebihi level cap 1★ (10)
	return hero.validate_invariants() == false


func _test_invalid_generated_hero_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_val_22")
	coord.set_treasury_gold(1000)
	var bad_hero := HeroModel.new("", "", 1, 3)
	var ok: bool = coord.add_hero(bad_hero)
	return ok == false


func _test_valid_potential_star_progression_accepted() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_val_23")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.ARCHER, 2, 4)
	return hero != null and hero.current_star == 2 and hero.potential_star == 4


# ==============================================================================
# INITIAL STATE (24-31)
# ==============================================================================

func _test_new_hero_starts_at_level_1() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_init_24")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero()
	return hero != null and hero.level == 1


func _test_new_hero_starts_at_zero_exp() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_init_25")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero()
	return hero != null and hero.current_exp == 0


func _test_new_hero_has_valid_current_star() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_init_26")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.KNIGHT, 2, 4)
	return hero != null and hero.current_star == 2


func _test_new_hero_has_valid_potential_star() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_init_27")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero(HeroRole.KNIGHT, 2, 5)
	return hero != null and hero.potential_star == 5


func _test_new_hero_starts_with_empty_equipment() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_init_28")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero()
	if hero == null:
		return false
	return not hero.has_equipment("PRIMARY") and not hero.has_equipment("SECONDARY") and not hero.has_equipment("ARMOR")


func _test_new_hero_has_valid_fatigue() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_init_29")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero()
	return hero != null and hero.fatigue == 0


func _test_new_hero_has_valid_morale() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_init_30")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero()
	return hero != null and hero.morale == 100


func _test_new_hero_has_valid_chemistry_map() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_init_31")
	coord.set_treasury_gold(1000)
	var hero: HeroModel = coord.recruit_hero()
	return hero != null and hero.chemistry_map.is_empty()


# ==============================================================================
# ROSTER OWNERSHIP (32-35)
# ==============================================================================

func _test_roster_contains_only_valid_heroes() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rost_32")
	coord.set_treasury_gold(2000)
	coord.recruit_hero(HeroRole.KNIGHT)
	coord.recruit_hero(HeroRole.ARCHER)
	for h in coord.get_roster():
		if not (h is HeroModel) or not (h as HeroModel).validate_invariants():
			return false
	return true


func _test_duplicate_insertion_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rost_33")
	var existing: HeroModel = coord.get_hero("hero_alder")
	var duplicate_added: bool = coord.add_hero(existing)
	return duplicate_added == false and coord.get_roster_count() == 2


func _test_stable_roster_lookup_works_after_adding_multiple_heroes() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rost_34")
	coord.set_treasury_gold(2000)
	var h1 := coord.recruit_hero(HeroRole.KNIGHT, 1, 3, "hero_knight_custom")
	var h2 := coord.recruit_hero(HeroRole.ARCHER, 1, 3, "hero_archer_custom")
	var lookup1 := coord.get_hero("hero_knight_custom")
	var lookup2 := coord.get_hero("hero_archer_custom")
	return lookup1 == h1 and lookup2 == h2


func _test_removal_reordering_does_not_corrupt_remaining_heroes() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_rost_35")
	coord.set_treasury_gold(2000)
	var h1 := coord.recruit_hero(HeroRole.MAGE, 1, 3, "hero_mage_target")
	var h2 := coord.recruit_hero(HeroRole.PRIEST, 1, 3, "hero_priest_target")
	coord.dismiss_hero("hero_lyra")
	var remaining_mage := coord.get_hero("hero_mage_target")
	var remaining_priest := coord.get_hero("hero_priest_target")
	var remaining_alder := coord.get_hero("hero_alder")
	return remaining_mage == h1 and remaining_priest == h2 and remaining_alder != null


func _test_dismiss_hero_returns_equipment_to_warehouse() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_dismiss_gear")
	coord.set_treasury_gold(1000)
	var hero := coord.recruit_hero(HeroRole.KNIGHT, 1, 3, "hero_gear_test")
	if hero == null:
		return false
	var sword_before: int = coord.get_warehouse_stock("SWORD")
	if sword_before < 1:
		return false
	var ok_equip: bool = coord.equip_hero("hero_gear_test", "PRIMARY", "SWORD")
	if not ok_equip or coord.get_warehouse_stock("SWORD") != sword_before - 1:
		return false
	var dismissed: bool = coord.dismiss_hero("hero_gear_test")
	if not dismissed or coord.has_hero("hero_gear_test"):
		return false
	return coord.get_warehouse_stock("SWORD") == sword_before


# ==============================================================================
# SNAPSHOT (36-40)
# ==============================================================================

func _test_hero_roster_snapshot_preserves_identity() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_snap_36")
	coord.set_treasury_gold(1000)
	coord.recruit_hero(HeroRole.KNIGHT, 1, 4, "hero_rec_snap", "Ser Snap")
	var snap := coord.get_current_snapshot()
	var found: bool = false
	for entry in snap.heroes_data:
		if entry.get("hero_id") == "hero_rec_snap" and entry.get("hero_name") == "Ser Snap":
			found = true
			break
	return found


func _test_snapshot_preserves_progression_fields() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_snap_37")
	coord.set_treasury_gold(1000)
	coord.recruit_hero(HeroRole.ARCHER, 2, 4, "hero_prog_snap")
	var snap := coord.get_current_snapshot()
	for entry in snap.heroes_data:
		if entry.get("hero_id") == "hero_prog_snap":
			return entry.get("level") == 1 and entry.get("current_exp") == 0 and entry.get("current_star") == 2 and entry.get("potential_star") == 4 and entry.get("level_cap") == 20
	return false


func _test_snapshot_preserves_lifecycle_state() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_snap_38")
	coord.set_treasury_gold(1000)
	coord.recruit_hero(HeroRole.KNIGHT, 1, 3, "hero_life_snap")
	var snap := coord.get_current_snapshot()
	for entry in snap.heroes_data:
		if entry.get("hero_id") == "hero_life_snap":
			return entry.get("lifecycle_state") == HeroLifecycleState.ROSTER_ACTIVE
	return false


func _test_snapshot_preserves_equipment_references_state() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_snap_39")
	coord.set_treasury_gold(1000)
	coord.recruit_hero(HeroRole.KNIGHT, 1, 3, "hero_eq_snap")
	var snap := coord.get_current_snapshot()
	for entry in snap.heroes_data:
		if entry.get("hero_id") == "hero_eq_snap":
			return entry.get("primary_equipment") == "NONE" and entry.get("secondary_equipment") == "NONE" and entry.get("armor_equipment") == "NONE"
	return false


func _test_snapshot_preserves_chemistry_map() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_snap_40")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.add_chemistry("hero_lyra", 8)
	coord._update_snapshot()
	var snap := coord.get_current_snapshot()
	for entry in snap.heroes_data:
		if entry.get("hero_id") == "hero_alder":
			var chem: Dictionary = entry.get("chemistry_map", {})
			return chem.get("hero_lyra") == 8
	return false


# ==============================================================================
# TRANSACTION SAFETY (41-45)
# ==============================================================================

func _test_failed_hero_generation_does_not_consume_gold() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_tx_41")
	coord.set_treasury_gold(1000)
	# Invalid star: cur_star 4 > pot_star 2
	coord.recruit_hero(HeroRole.KNIGHT, 4, 2)
	return coord.get_treasury_gold() == 1000


func _test_failed_roster_insertion_does_not_consume_gold() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_tx_42")
	coord.set_treasury_gold(1000)
	# Attempt to recruit with existing ID Alder
	coord.recruit_hero(HeroRole.KNIGHT, 1, 3, "hero_alder")
	return coord.get_treasury_gold() == 1000


func _test_successful_recruitment_consumes_gold_exactly_once() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_tx_43")
	coord.set_treasury_gold(1000)
	var hero := coord.recruit_hero()
	return hero != null and coord.get_treasury_gold() == 500


func _test_hero_is_added_exactly_once() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_tx_44")
	coord.set_treasury_gold(1000)
	var hero := coord.recruit_hero(HeroRole.KNIGHT, 1, 3, "hero_once_id")
	var occurrences: int = 0
	for h in coord.get_roster():
		if (h as HeroModel).hero_id == "hero_once_id":
			occurrences += 1
	return hero != null and occurrences == 1


func _test_duplicate_recruitment_request_cannot_duplicate_same_hero_id() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_tx_45")
	coord.set_treasury_gold(2000)
	var h1 := coord.recruit_hero(HeroRole.KNIGHT, 1, 3, "hero_dup_check")
	var h2 := coord.recruit_hero(HeroRole.KNIGHT, 1, 3, "hero_dup_check")
	return h1 != null and h2 == null and coord.get_treasury_gold() == 1500 and coord.get_roster_count() == 3


# ==============================================================================
# SUPPLEMENTARY CONSTRAINTS (46-48)
# ==============================================================================

func _test_recruitment_blocked_during_battle_state() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_sup_46")
	coord.set_treasury_gold(2000)
	coord.inspect_wave()
	coord.start_battle()
	var hero := coord.recruit_hero()
	return hero == null and coord.get_treasury_gold() == 2000


func _test_candidate_with_existing_equipment_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_sup_47")
	coord.set_treasury_gold(1000)
	var candidate := HeroModel.new("hero_illegal_gear", "IllegalGear", 1, 3, HeroRole.KNIGHT, HeroLifecycleState.RECRUITABLE)
	candidate.equip("PRIMARY", EquipmentModel.new("SWORD", 1, 100, 1))
	var hero := coord.recruit_hero(candidate)
	return hero == null and coord.get_treasury_gold() == 1000


func _test_candidate_with_invalid_initial_lifecycle_state_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_sup_48")
	coord.set_treasury_gold(1000)
	var dead_candidate := HeroModel.new("hero_dead_candidate", "Dead", 1, 3, HeroRole.KNIGHT, HeroLifecycleState.PERMADEATH)
	var battle_candidate := HeroModel.new("hero_battle_candidate", "Battle", 1, 3, HeroRole.KNIGHT, HeroLifecycleState.BATTLE_ACTIVE)
	var h1 := coord.recruit_hero(dead_candidate)
	var h2 := coord.recruit_hero(battle_candidate)
	return h1 == null and h2 == null and coord.get_treasury_gold() == 1000
