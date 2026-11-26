extends SceneTree

## TestPhase4AHeroDomainLifecycle
## Test suite otomatis untuk memvalidasi implementasi Phase 4A:
## Hero Domain & Lifecycle Foundation.
## Memvalidasi seluruh kriteria peran kanonikal, state siklus hidup,
## aturan transisi legal, invarian domain hero, dan kompatibilitas perlengkapan.

const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 4A HERO DOMAIN & LIFECYCLE FOUNDATION TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# Role Tests (1-6)
		{"name": "test_knight_role_is_valid", "fn": Callable(self, "_test_knight_role_is_valid")},
		{"name": "test_mage_role_is_valid", "fn": Callable(self, "_test_mage_role_is_valid")},
		{"name": "test_archer_role_is_valid", "fn": Callable(self, "_test_archer_role_is_valid")},
		{"name": "test_priest_role_is_valid", "fn": Callable(self, "_test_priest_role_is_valid")},
		{"name": "test_unknown_role_is_rejected", "fn": Callable(self, "_test_unknown_role_is_rejected")},
		{"name": "test_empty_role_is_rejected", "fn": Callable(self, "_test_empty_role_is_rejected")},

		# Lifecycle Tests (7-12)
		{"name": "test_recruitable_state_is_valid", "fn": Callable(self, "_test_recruitable_state_is_valid")},
		{"name": "test_roster_active_state_is_valid", "fn": Callable(self, "_test_roster_active_state_is_valid")},
		{"name": "test_in_party_state_is_valid", "fn": Callable(self, "_test_in_party_state_is_valid")},
		{"name": "test_in_training_state_is_valid", "fn": Callable(self, "_test_in_training_state_is_valid")},
		{"name": "test_battle_active_state_is_valid", "fn": Callable(self, "_test_battle_active_state_is_valid")},
		{"name": "test_permadeath_state_is_valid", "fn": Callable(self, "_test_permadeath_state_is_valid")},

		# Transition Tests (13-22)
		{"name": "test_transition_recruitable_to_roster_active", "fn": Callable(self, "_test_transition_recruitable_to_roster_active")},
		{"name": "test_transition_roster_active_to_in_party", "fn": Callable(self, "_test_transition_roster_active_to_in_party")},
		{"name": "test_transition_in_party_to_roster_active", "fn": Callable(self, "_test_transition_in_party_to_roster_active")},
		{"name": "test_transition_roster_active_to_in_training", "fn": Callable(self, "_test_transition_roster_active_to_in_training")},
		{"name": "test_transition_in_training_to_roster_active", "fn": Callable(self, "_test_transition_in_training_to_roster_active")},
		{"name": "test_transition_in_party_to_battle_active", "fn": Callable(self, "_test_transition_in_party_to_battle_active")},
		{"name": "test_transition_battle_active_to_in_party_survivor", "fn": Callable(self, "_test_transition_battle_active_to_in_party_survivor")},
		{"name": "test_transition_battle_active_to_permadeath", "fn": Callable(self, "_test_transition_battle_active_to_permadeath")},
		{"name": "test_permadeath_to_any_active_state_fails", "fn": Callable(self, "_test_permadeath_to_any_active_state_fails")},
		{"name": "test_illegal_transitions_rejected", "fn": Callable(self, "_test_illegal_transitions_rejected")},

		# Invariant Tests (23-29)
		{"name": "test_empty_hero_id_rejected", "fn": Callable(self, "_test_empty_hero_id_rejected")},
		{"name": "test_empty_hero_name_rejected", "fn": Callable(self, "_test_empty_hero_name_rejected")},
		{"name": "test_valid_star_potential_accepted", "fn": Callable(self, "_test_valid_star_potential_accepted")},
		{"name": "test_invalid_star_greater_than_potential_rejected", "fn": Callable(self, "_test_invalid_star_greater_than_potential_rejected")},
		{"name": "test_invalid_star_greater_than_five_rejected", "fn": Callable(self, "_test_invalid_star_greater_than_five_rejected")},
		{"name": "test_dead_hero_cannot_become_active_again", "fn": Callable(self, "_test_dead_hero_cannot_become_active_again")},
		{"name": "test_existing_hero_equipment_behavior_remains_valid", "fn": Callable(self, "_test_existing_hero_equipment_behavior_remains_valid")},

		# Supplementary Domain Tests (30-33)
		{"name": "test_role_equipment_compatibility_rules", "fn": Callable(self, "_test_role_equipment_compatibility_rules")},
		{"name": "test_hero_safe_defaults_for_backward_compatibility", "fn": Callable(self, "_test_hero_safe_defaults_for_backward_compatibility")},
		{"name": "test_case_insensitivity_and_whitespace_handling", "fn": Callable(self, "_test_case_insensitivity_and_whitespace_handling")},
		{"name": "test_hero_clone_preserves_role_and_lifecycle", "fn": Callable(self, "_test_hero_clone_preserves_role_and_lifecycle")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 4A TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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
# ROLE TESTS (1-6)
# ==============================================================================

func _test_knight_role_is_valid() -> bool:
	if not HeroRole.is_valid_role("KNIGHT"): return false
	if not HeroModel.is_valid_role("KNIGHT"): return false
	var hero := HeroModel.new("h_k", "Sir Knight", 1, 3, "KNIGHT")
	return hero.role == "KNIGHT" and hero.is_role_valid()


func _test_mage_role_is_valid() -> bool:
	if not HeroRole.is_valid_role("MAGE"): return false
	if not HeroModel.is_valid_role("MAGE"): return false
	var hero := HeroModel.new("h_m", "Mage Alex", 1, 3, "MAGE")
	return hero.role == "MAGE" and hero.is_role_valid()


func _test_archer_role_is_valid() -> bool:
	if not HeroRole.is_valid_role("ARCHER"): return false
	if not HeroModel.is_valid_role("ARCHER"): return false
	var hero := HeroModel.new("h_a", "Ranger Robin", 1, 3, "ARCHER")
	return hero.role == "ARCHER" and hero.is_role_valid()


func _test_priest_role_is_valid() -> bool:
	if not HeroRole.is_valid_role("PRIEST"): return false
	if not HeroModel.is_valid_role("PRIEST"): return false
	var hero := HeroModel.new("h_p", "Cleric John", 1, 3, "PRIEST")
	return hero.role == "PRIEST" and hero.is_role_valid()


func _test_unknown_role_is_rejected() -> bool:
	if HeroRole.is_valid_role("WARRIOR"): return false
	if HeroRole.is_valid_role("PALADIN"): return false
	if HeroRole.is_valid_role("ROGUE"): return false
	if HeroRole.is_valid_role("BERSERKER"): return false
	var hero := HeroModel.new("h_u", "Hero Unknown", 1, 3)
	if hero.set_role("WARRIOR"): return false
	return hero.role == "KNIGHT" # Unchanged


func _test_empty_role_is_rejected() -> bool:
	if HeroRole.is_valid_role(""): return false
	if HeroRole.is_valid_role("   "): return false
	var hero := HeroModel.new("h_e", "Hero Empty", 1, 3)
	if hero.set_role(""): return false
	if hero.set_role("   "): return false
	return hero.role == "KNIGHT" # Unchanged


# ==============================================================================
# LIFECYCLE TESTS (7-12)
# ==============================================================================

func _test_recruitable_state_is_valid() -> bool:
	if not HeroLifecycleState.is_valid_state("RECRUITABLE"): return false
	if not HeroModel.is_valid_lifecycle_state("RECRUITABLE"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "RECRUITABLE")
	return hero.lifecycle_state == "RECRUITABLE" and hero.is_lifecycle_state_valid()


func _test_roster_active_state_is_valid() -> bool:
	if not HeroLifecycleState.is_valid_state("ROSTER_ACTIVE"): return false
	if not HeroModel.is_valid_lifecycle_state("ROSTER_ACTIVE"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "ROSTER_ACTIVE")
	return hero.lifecycle_state == "ROSTER_ACTIVE" and hero.is_lifecycle_state_valid()


func _test_in_party_state_is_valid() -> bool:
	if not HeroLifecycleState.is_valid_state("IN_PARTY"): return false
	if not HeroModel.is_valid_lifecycle_state("IN_PARTY"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "IN_PARTY")
	return hero.lifecycle_state == "IN_PARTY" and hero.is_lifecycle_state_valid()


func _test_in_training_state_is_valid() -> bool:
	if not HeroLifecycleState.is_valid_state("IN_TRAINING"): return false
	if not HeroModel.is_valid_lifecycle_state("IN_TRAINING"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "IN_TRAINING")
	return hero.lifecycle_state == "IN_TRAINING" and hero.is_lifecycle_state_valid()


func _test_battle_active_state_is_valid() -> bool:
	if not HeroLifecycleState.is_valid_state("BATTLE_ACTIVE"): return false
	if not HeroModel.is_valid_lifecycle_state("BATTLE_ACTIVE"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "BATTLE_ACTIVE")
	return hero.lifecycle_state == "BATTLE_ACTIVE" and hero.is_lifecycle_state_valid()


func _test_permadeath_state_is_valid() -> bool:
	if not HeroLifecycleState.is_valid_state("PERMADEATH"): return false
	if not HeroModel.is_valid_lifecycle_state("PERMADEATH"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "PERMADEATH")
	return hero.lifecycle_state == "PERMADEATH" and hero.is_lifecycle_state_valid() and not hero.is_alive


# ==============================================================================
# TRANSITION TESTS (13-22)
# ==============================================================================

func _test_transition_recruitable_to_roster_active() -> bool:
	if not HeroLifecycleState.can_transition("RECRUITABLE", "ROSTER_ACTIVE"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "RECRUITABLE")
	var ok: bool = hero.transition_lifecycle_state("ROSTER_ACTIVE")
	return ok and hero.lifecycle_state == "ROSTER_ACTIVE" and hero.is_alive


func _test_transition_roster_active_to_in_party() -> bool:
	if not HeroLifecycleState.can_transition("ROSTER_ACTIVE", "IN_PARTY"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "ROSTER_ACTIVE")
	var ok: bool = hero.transition_lifecycle_state("IN_PARTY")
	return ok and hero.lifecycle_state == "IN_PARTY"


func _test_transition_in_party_to_roster_active() -> bool:
	if not HeroLifecycleState.can_transition("IN_PARTY", "ROSTER_ACTIVE"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "IN_PARTY")
	var ok: bool = hero.transition_lifecycle_state("ROSTER_ACTIVE")
	return ok and hero.lifecycle_state == "ROSTER_ACTIVE"


func _test_transition_roster_active_to_in_training() -> bool:
	if not HeroLifecycleState.can_transition("ROSTER_ACTIVE", "IN_TRAINING"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "ROSTER_ACTIVE")
	var ok: bool = hero.transition_lifecycle_state("IN_TRAINING")
	return ok and hero.lifecycle_state == "IN_TRAINING"


func _test_transition_in_training_to_roster_active() -> bool:
	if not HeroLifecycleState.can_transition("IN_TRAINING", "ROSTER_ACTIVE"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "IN_TRAINING")
	var ok: bool = hero.transition_lifecycle_state("ROSTER_ACTIVE")
	return ok and hero.lifecycle_state == "ROSTER_ACTIVE"


func _test_transition_in_party_to_battle_active() -> bool:
	if not HeroLifecycleState.can_transition("IN_PARTY", "BATTLE_ACTIVE"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "IN_PARTY")
	var ok: bool = hero.transition_lifecycle_state("BATTLE_ACTIVE")
	return ok and hero.lifecycle_state == "BATTLE_ACTIVE"


func _test_transition_battle_active_to_in_party_survivor() -> bool:
	if not HeroLifecycleState.can_transition("BATTLE_ACTIVE", "IN_PARTY"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "BATTLE_ACTIVE")
	var ok: bool = hero.transition_lifecycle_state("IN_PARTY")
	return ok and hero.lifecycle_state == "IN_PARTY" and hero.is_alive


func _test_transition_battle_active_to_permadeath() -> bool:
	if not HeroLifecycleState.can_transition("BATTLE_ACTIVE", "PERMADEATH"): return false
	var hero := HeroModel.new("h1", "Hero", 1, 3, "KNIGHT", "BATTLE_ACTIVE")
	var ok: bool = hero.transition_lifecycle_state("PERMADEATH")
	return ok and hero.lifecycle_state == "PERMADEATH" and not hero.is_alive


func _test_permadeath_to_any_active_state_fails() -> bool:
	var hero := HeroModel.new("h_dead", "Dead Hero", 1, 3, "KNIGHT", "PERMADEATH")
	if hero.transition_lifecycle_state("RECRUITABLE"): return false
	if hero.transition_lifecycle_state("ROSTER_ACTIVE"): return false
	if hero.transition_lifecycle_state("IN_PARTY"): return false
	if hero.transition_lifecycle_state("IN_TRAINING"): return false
	if hero.transition_lifecycle_state("BATTLE_ACTIVE"): return false
	return hero.lifecycle_state == "PERMADEATH" and not hero.is_alive


func _test_illegal_transitions_rejected() -> bool:
	var hero := HeroModel.new("h_illegal", "Hero", 1, 3, "KNIGHT", "RECRUITABLE")
	# RECRUITABLE cannot skip directly to IN_PARTY, IN_TRAINING, or BATTLE_ACTIVE
	if hero.transition_lifecycle_state("IN_PARTY"): return false
	if hero.transition_lifecycle_state("IN_TRAINING"): return false
	if hero.transition_lifecycle_state("BATTLE_ACTIVE"): return false
	if hero.transition_lifecycle_state("UNKNOWN_STATE"): return false
	
	# ROSTER_ACTIVE cannot jump straight to BATTLE_ACTIVE (must be IN_PARTY first)
	hero.transition_lifecycle_state("ROSTER_ACTIVE")
	if hero.transition_lifecycle_state("BATTLE_ACTIVE"): return false
	if hero.transition_lifecycle_state("RECRUITABLE"): return false

	# IN_TRAINING cannot jump to BATTLE_ACTIVE or IN_PARTY directly
	hero.transition_lifecycle_state("IN_TRAINING")
	if hero.transition_lifecycle_state("BATTLE_ACTIVE"): return false
	if hero.transition_lifecycle_state("IN_PARTY"): return false

	return true


# ==============================================================================
# INVARIANT TESTS (23-29)
# ==============================================================================

func _test_empty_hero_id_rejected() -> bool:
	if HeroModel.validate_identity("", "Alder"): return false
	if HeroModel.validate_identity("   ", "Alder"): return false
	var hero := HeroModel.new("h_valid", "Alder", 1, 3)
	hero.hero_id = ""
	return not hero.validate_invariants()


func _test_empty_hero_name_rejected() -> bool:
	if HeroModel.validate_identity("hero_1", ""): return false
	if HeroModel.validate_identity("hero_1", "   "): return false
	var hero := HeroModel.new("hero_1", "Alder", 1, 3)
	hero.hero_name = "   "
	return not hero.validate_invariants()


func _test_valid_star_potential_accepted() -> bool:
	if not HeroModel.validate_stars(1, 3): return false
	if not HeroModel.validate_stars(2, 4): return false
	if not HeroModel.validate_stars(3, 3): return false
	if not HeroModel.validate_stars(5, 5): return false
	var hero := HeroModel.new("h_stars", "Hero", 2, 4)
	return hero.validate_invariants()


func _test_invalid_star_greater_than_potential_rejected() -> bool:
	if HeroModel.validate_stars(4, 2): return false
	if HeroModel.validate_stars(3, 1): return false
	if HeroModel.validate_stars(5, 4): return false
	var hero := HeroModel.new("h_bad_stars", "Hero", 1, 4)
	hero.current_star = 4
	hero.potential_star = 2
	return not hero.validate_invariants()


func _test_invalid_star_greater_than_five_rejected() -> bool:
	if HeroModel.validate_stars(6, 6): return false
	if HeroModel.validate_stars(1, 6): return false
	if HeroModel.validate_stars(0, 3): return false
	if HeroModel.validate_stars(-1, 5): return false
	var hero := HeroModel.new("h_over_five", "Hero", 1, 4)
	hero.current_star = 6
	hero.potential_star = 6
	return not hero.validate_invariants()


func _test_dead_hero_cannot_become_active_again() -> bool:
	var hero := HeroModel.new("h_perma", "Hero", 1, 3, "KNIGHT", "BATTLE_ACTIVE")
	hero.mark_dead()
	if hero.is_alive: return false
	if hero.lifecycle_state != "PERMADEATH": return false
	if hero.transition_lifecycle_state("ROSTER_ACTIVE"): return false
	if hero.transition_lifecycle_state("IN_PARTY"): return false
	return hero.lifecycle_state == "PERMADEATH" and not hero.is_alive


func _test_existing_hero_equipment_behavior_remains_valid() -> bool:
	var hero := HeroModel.new("h_eq", "Hero Eq", 1, 3)
	var sword := EquipmentModel.new("SWORD", 1, 100, 1)
	var shield := EquipmentModel.new("SHIELD", 1, 100, 1)
	var armor := EquipmentModel.new("HEAVY_ARMOR", 1, 100, 1)

	hero.equip("PRIMARY", sword)
	hero.equip("SECONDARY", shield)
	hero.equip("ARMOR", armor)

	if not hero.has_equipment("PRIMARY"): return false
	if not hero.has_equipment("SECONDARY"): return false
	if not hero.has_equipment("ARMOR"): return false
	if hero.get_equipment("PRIMARY") != sword: return false

	if hero.get_effective_atk() <= hero.base_atk: return false
	if hero.get_effective_def() <= hero.base_def: return false

	var unequipped_pri: RefCounted = hero.unequip("PRIMARY")
	if unequipped_pri != sword: return false
	if hero.has_equipment("PRIMARY"): return false

	var remaining: Array = hero.clear_equipment()
	if remaining.size() != 2: return false
	if hero.has_equipment("SECONDARY") or hero.has_equipment("ARMOR"): return false

	return true


# ==============================================================================
# SUPPLEMENTARY DOMAIN TESTS (30-33)
# ==============================================================================

func _test_role_equipment_compatibility_rules() -> bool:
	# KNIGHT
	var knight := HeroModel.new("h_k", "Knight", 1, 3, "KNIGHT")
	if not knight.is_equipment_compatible("PRIMARY", "SWORD"): return false
	if not knight.is_equipment_compatible("PRIMARY", "SPEAR"): return false
	if knight.is_equipment_compatible("PRIMARY", "BOW"): return false
	if not knight.is_equipment_compatible("SECONDARY", "SHIELD"): return false
	if not knight.is_equipment_compatible("ARMOR", "HEAVY_ARMOR"): return false

	# ARCHER
	var archer := HeroModel.new("h_a", "Archer", 1, 3, "ARCHER")
	if not archer.is_equipment_compatible("PRIMARY", "BOW"): return false
	if archer.is_equipment_compatible("PRIMARY", "SWORD"): return false
	if archer.is_equipment_compatible("SECONDARY", "SHIELD"): return false
	if not archer.is_equipment_compatible("ARMOR", "HEAVY_ARMOR"): return false

	# MAGE
	var mage := HeroModel.new("h_m", "Mage", 1, 3, "MAGE")
	if not mage.is_equipment_compatible("PRIMARY", "SPEAR"): return false
	if mage.is_equipment_compatible("SECONDARY", "SHIELD"): return false
	if mage.is_equipment_compatible("ARMOR", "HEAVY_ARMOR"): return false

	# PRIEST
	var priest := HeroModel.new("h_p", "Priest", 1, 3, "PRIEST")
	if not priest.is_equipment_compatible("PRIMARY", "SWORD"): return false
	if not priest.is_equipment_compatible("SECONDARY", "SHIELD"): return false

	return true


func _test_hero_safe_defaults_for_backward_compatibility() -> bool:
	# Called with old 4 arguments
	var hero := HeroModel.new("h_old", "Old Hero", 1, 4)
	if hero.role != "KNIGHT": return false
	if hero.lifecycle_state != "ROSTER_ACTIVE": return false
	if not hero.is_alive: return false
	if not hero.validate_invariants(): return false
	return true


func _test_case_insensitivity_and_whitespace_handling() -> bool:
	if not HeroRole.is_valid_role("  knight  "): return false
	if not HeroRole.is_valid_role("mage"): return false
	if not HeroLifecycleState.is_valid_state("  roster_active  "): return false
	if not HeroLifecycleState.is_valid_state("in_party"): return false
	var hero := HeroModel.new("h_case", "Hero", 1, 3, " archer ", " in_training ")
	return hero.role == "ARCHER" and hero.lifecycle_state == "IN_TRAINING"


func _test_hero_clone_preserves_role_and_lifecycle() -> bool:
	var hero := HeroModel.new("h_clone", "Hero Clone", 2, 4, "PRIEST", "IN_PARTY")
	hero.level = 3
	hero.fatigue = 25
	var cloned := hero.clone()
	if cloned.hero_id != hero.hero_id: return false
	if cloned.role != "PRIEST": return false
	if cloned.lifecycle_state != "IN_PARTY": return false
	if cloned.level != 3: return false
	if cloned.fatigue != 25: return false
	return true
