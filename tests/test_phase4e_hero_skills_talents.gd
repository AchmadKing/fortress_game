extends SceneTree

## TestPhase4EHeroSkillsTalents
## Test suite otomatis untuk memvalidasi implementasi Phase 4E:
## Hero Skills & Talent Foundation.
## Memvalidasi model HeroSkill, katalog skill kanonikal per peran,
## syarat pembukaan skill, perolehan Talent Points berbasis odd-level,
## alokasi bakat pada 3 cabang (OFFENSE, DEFENSE, LEADERSHIP),
## pembatasan tingkat bakat (maks 3), kalkulasi pengali stat bakat,
## integrasi ke get_effective_atk() & get_effective_def(),
## proteksi Battle Lock, deep-copy clone, dan serialisasi snapshot telemetri.

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroSkill = preload("res://scripts/domain/model/hero_skill.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 4E HERO SKILLS & TALENTS TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# 1. HeroSkill Model & Catalog Tests (1-12)
		{"name": "test_hero_skill_init_defaults", "fn": Callable(self, "_test_hero_skill_init_defaults")},
		{"name": "test_hero_skill_valid_invariants", "fn": Callable(self, "_test_hero_skill_valid_invariants")},
		{"name": "test_hero_skill_invalid_empty_id", "fn": Callable(self, "_test_hero_skill_invalid_empty_id")},
		{"name": "test_hero_skill_invalid_empty_name", "fn": Callable(self, "_test_hero_skill_invalid_empty_name")},
		{"name": "test_hero_skill_invalid_role", "fn": Callable(self, "_test_hero_skill_invalid_role")},
		{"name": "test_hero_skill_invalid_level_zero", "fn": Callable(self, "_test_hero_skill_invalid_level_zero")},
		{"name": "test_hero_skill_invalid_type", "fn": Callable(self, "_test_hero_skill_invalid_type")},
		{"name": "test_hero_skill_invalid_multiplier_zero_or_negative", "fn": Callable(self, "_test_hero_skill_invalid_multiplier_zero_or_negative")},
		{"name": "test_hero_skill_clone_deep_copy", "fn": Callable(self, "_test_hero_skill_clone_deep_copy")},
		{"name": "test_canonical_catalog_contains_all_roles", "fn": Callable(self, "_test_canonical_catalog_contains_all_roles")},
		{"name": "test_canonical_catalog_skills_for_role_count", "fn": Callable(self, "_test_canonical_catalog_skills_for_role_count")},
		{"name": "test_canonical_skill_lookup_by_id", "fn": Callable(self, "_test_canonical_skill_lookup_by_id")},

		# 2. Skill Unlocking Domain & Coordinator Tests (13-26)
		{"name": "test_hero_starts_with_empty_unlocked_skills", "fn": Callable(self, "_test_hero_starts_with_empty_unlocked_skills")},
		{"name": "test_can_unlock_skill_requires_matching_role", "fn": Callable(self, "_test_can_unlock_skill_requires_matching_role")},
		{"name": "test_can_unlock_skill_requires_sufficient_level", "fn": Callable(self, "_test_can_unlock_skill_requires_sufficient_level")},
		{"name": "test_can_unlock_skill_succeeds_at_required_level", "fn": Callable(self, "_test_can_unlock_skill_succeeds_at_required_level")},
		{"name": "test_unlock_skill_adds_to_unlocked_skills", "fn": Callable(self, "_test_unlock_skill_adds_to_unlocked_skills")},
		{"name": "test_cannot_unlock_same_skill_twice", "fn": Callable(self, "_test_cannot_unlock_same_skill_twice")},
		{"name": "test_cannot_unlock_non_canonical_skill", "fn": Callable(self, "_test_cannot_unlock_non_canonical_skill")},
		{"name": "test_dead_or_permadeath_hero_cannot_unlock_skill", "fn": Callable(self, "_test_dead_or_permadeath_hero_cannot_unlock_skill")},
		{"name": "test_get_unlocked_skills_returns_duplicate", "fn": Callable(self, "_test_get_unlocked_skills_returns_duplicate")},
		{"name": "test_unlock_multiple_skills_sequentially", "fn": Callable(self, "_test_unlock_multiple_skills_sequentially")},
		{"name": "test_coordinator_can_unlock_hero_skill", "fn": Callable(self, "_test_coordinator_can_unlock_hero_skill")},
		{"name": "test_coordinator_unlock_hero_skill_succeeds", "fn": Callable(self, "_test_coordinator_unlock_hero_skill_succeeds")},
		{"name": "test_coordinator_unlock_hero_skill_blocked_during_battle", "fn": Callable(self, "_test_coordinator_unlock_hero_skill_blocked_during_battle")},
		{"name": "test_coordinator_unlock_hero_skill_invalid_hero_returns_false", "fn": Callable(self, "_test_coordinator_unlock_hero_skill_invalid_hero_returns_false")},

		# 3. Talent Points Acquisition & Odd-Level Rule Tests (27-38)
		{"name": "test_hero_starts_with_zero_talent_points", "fn": Callable(self, "_test_hero_starts_with_zero_talent_points")},
		{"name": "test_level_1_to_2_grants_no_talent_points", "fn": Callable(self, "_test_level_1_to_2_grants_no_talent_points")},
		{"name": "test_level_2_to_3_grants_one_talent_point", "fn": Callable(self, "_test_level_2_to_3_grants_one_talent_point")},
		{"name": "test_level_3_to_4_grants_no_talent_points", "fn": Callable(self, "_test_level_3_to_4_grants_no_talent_points")},
		{"name": "test_level_4_to_5_grants_one_talent_point", "fn": Callable(self, "_test_level_4_to_5_grants_one_talent_point")},
		{"name": "test_multi_level_jump_1_to_5_grants_2_points", "fn": Callable(self, "_test_multi_level_jump_1_to_5_grants_2_points")},
		{"name": "test_multi_level_jump_1_to_7_grants_3_points", "fn": Callable(self, "_test_multi_level_jump_1_to_7_grants_3_points")},
		{"name": "test_multi_level_jump_1_to_9_grants_4_points", "fn": Callable(self, "_test_multi_level_jump_1_to_9_grants_4_points")},
		{"name": "test_ascension_does_not_modify_talent_points", "fn": Callable(self, "_test_ascension_does_not_modify_talent_points")},
		{"name": "test_exp_carry_over_at_cap_grants_no_talent_points", "fn": Callable(self, "_test_exp_carry_over_at_cap_grants_no_talent_points")},
		{"name": "test_training_exp_granting_odd_level_awards_talent_point", "fn": Callable(self, "_test_training_exp_granting_odd_level_awards_talent_point")},
		{"name": "test_zero_or_negative_exp_grants_no_talent_points", "fn": Callable(self, "_test_zero_or_negative_exp_grants_no_talent_points")},

		# 4. Talent Allocation & Branch Integrity Tests (39-50)
		{"name": "test_hero_starts_with_zero_allocated_talents", "fn": Callable(self, "_test_hero_starts_with_zero_allocated_talents")},
		{"name": "test_cannot_allocate_with_zero_talent_points", "fn": Callable(self, "_test_cannot_allocate_with_zero_talent_points")},
		{"name": "test_cannot_allocate_to_invalid_branch", "fn": Callable(self, "_test_cannot_allocate_to_invalid_branch")},
		{"name": "test_allocate_offense_talent_deducts_point", "fn": Callable(self, "_test_allocate_offense_talent_deducts_point")},
		{"name": "test_allocate_defense_talent_deducts_point", "fn": Callable(self, "_test_allocate_defense_talent_deducts_point")},
		{"name": "test_allocate_leadership_talent_deducts_point", "fn": Callable(self, "_test_allocate_leadership_talent_deducts_point")},
		{"name": "test_branch_level_capped_at_max_3", "fn": Callable(self, "_test_branch_level_capped_at_max_3")},
		{"name": "test_dead_or_permadeath_hero_cannot_allocate_talent", "fn": Callable(self, "_test_dead_or_permadeath_hero_cannot_allocate_talent")},
		{"name": "test_coordinator_can_allocate_hero_talent", "fn": Callable(self, "_test_coordinator_can_allocate_hero_talent")},
		{"name": "test_coordinator_allocate_hero_talent_succeeds", "fn": Callable(self, "_test_coordinator_allocate_hero_talent_succeeds")},
		{"name": "test_coordinator_allocate_talent_blocked_during_battle", "fn": Callable(self, "_test_coordinator_allocate_talent_blocked_during_battle")},
		{"name": "test_coordinator_allocate_talent_invalid_hero_returns_false", "fn": Callable(self, "_test_coordinator_allocate_talent_invalid_hero_returns_false")},

		# 5. Stat Scaling, Multipliers, Invariants & Persistence Tests (51-62)
		{"name": "test_default_talent_multipliers_are_1_0", "fn": Callable(self, "_test_default_talent_multipliers_are_1_0")},
		{"name": "test_offense_talent_multiplier_scaling", "fn": Callable(self, "_test_offense_talent_multiplier_scaling")},
		{"name": "test_defense_talent_multiplier_scaling", "fn": Callable(self, "_test_defense_talent_multiplier_scaling")},
		{"name": "test_leadership_talent_multiplier_scaling", "fn": Callable(self, "_test_leadership_talent_multiplier_scaling")},
		{"name": "test_combined_offense_leadership_multiplier", "fn": Callable(self, "_test_combined_offense_leadership_multiplier")},
		{"name": "test_combined_defense_leadership_multiplier", "fn": Callable(self, "_test_combined_defense_leadership_multiplier")},
		{"name": "test_effective_atk_integrates_talent_multiplier", "fn": Callable(self, "_test_effective_atk_integrates_talent_multiplier")},
		{"name": "test_effective_def_integrates_talent_multiplier", "fn": Callable(self, "_test_effective_def_integrates_talent_multiplier")},
		{"name": "test_clone_preserves_skills_and_talents", "fn": Callable(self, "_test_clone_preserves_skills_and_talents")},
		{"name": "test_validate_invariants_checks_talents", "fn": Callable(self, "_test_validate_invariants_checks_talents")},
		{"name": "test_coordinator_snapshot_contains_phase4e_telemetry", "fn": Callable(self, "_test_coordinator_snapshot_contains_phase4e_telemetry")},
		{"name": "test_phase4e_deterministic_regression_stability", "fn": Callable(self, "_test_phase4e_deterministic_regression_stability")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 4E TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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
# 1. HEROSKILL MODEL & CATALOG TESTS (1-12)
# ==============================================================================

func _test_hero_skill_init_defaults() -> bool:
	var s := HeroSkill.new("k_off", "Iron Edge", HeroRole.KNIGHT, 3, HeroSkill.TYPE_PASSIVE_STAT, 1.05)
	return s.skill_id == "k_off" and s.skill_name == "Iron Edge" and s.required_role == HeroRole.KNIGHT and s.required_level == 3 and s.skill_type == HeroSkill.TYPE_PASSIVE_STAT and is_equal_approx(s.power_multiplier, 1.05)


func _test_hero_skill_valid_invariants() -> bool:
	var s := HeroSkill.new("k_off", "Iron Edge", HeroRole.KNIGHT, 3, HeroSkill.TYPE_PASSIVE_STAT, 1.05)
	return s.validate_invariants()


func _test_hero_skill_invalid_empty_id() -> bool:
	var s := HeroSkill.new("", "Iron Edge", HeroRole.KNIGHT, 3, HeroSkill.TYPE_PASSIVE_STAT, 1.05)
	return not s.validate_invariants()


func _test_hero_skill_invalid_empty_name() -> bool:
	var s := HeroSkill.new("k_off", "", HeroRole.KNIGHT, 3, HeroSkill.TYPE_PASSIVE_STAT, 1.05)
	return not s.validate_invariants()


func _test_hero_skill_invalid_role() -> bool:
	var s := HeroSkill.new("k_off", "Iron Edge", "NINJA", 3, HeroSkill.TYPE_PASSIVE_STAT, 1.05)
	return not s.validate_invariants()


func _test_hero_skill_invalid_level_zero() -> bool:
	var s := HeroSkill.new("k_off", "Iron Edge", HeroRole.KNIGHT, 0, HeroSkill.TYPE_PASSIVE_STAT, 1.05)
	return not s.validate_invariants()


func _test_hero_skill_invalid_type() -> bool:
	var s := HeroSkill.new("k_off", "Iron Edge", HeroRole.KNIGHT, 3, "SUPER_ACTIVE", 1.05)
	return not s.validate_invariants()


func _test_hero_skill_invalid_multiplier_zero_or_negative() -> bool:
	var s1 := HeroSkill.new("k_off", "Iron Edge", HeroRole.KNIGHT, 3, HeroSkill.TYPE_PASSIVE_STAT, 0.0)
	var s2 := HeroSkill.new("k_off", "Iron Edge", HeroRole.KNIGHT, 3, HeroSkill.TYPE_PASSIVE_STAT, -1.0)
	return not s1.validate_invariants() and not s2.validate_invariants()


func _test_hero_skill_clone_deep_copy() -> bool:
	var s1 := HeroSkill.new("k_off", "Iron Edge", HeroRole.KNIGHT, 3, HeroSkill.TYPE_PASSIVE_STAT, 1.05)
	var s2: HeroSkill = s1.clone()
	return s2 != null and s2 != s1 and s2.skill_id == s1.skill_id and s2.skill_name == s1.skill_name and s2.required_role == s1.required_role and s2.required_level == s1.required_level and s2.skill_type == s1.skill_type and is_equal_approx(s2.power_multiplier, s1.power_multiplier)


func _test_canonical_catalog_contains_all_roles() -> bool:
	var cat: Dictionary = HeroSkill.get_canonical_catalog()
	var roles_found: Dictionary = {}
	for id in cat.keys():
		var r: String = cat[id]["role"]
		roles_found[r] = true
	return roles_found.has(HeroRole.KNIGHT) and roles_found.has(HeroRole.ARCHER) and roles_found.has(HeroRole.MAGE) and roles_found.has(HeroRole.PRIEST)


func _test_canonical_catalog_skills_for_role_count() -> bool:
	var knight_skills: Array = HeroSkill.get_skills_for_role(HeroRole.KNIGHT)
	var archer_skills: Array = HeroSkill.get_skills_for_role(HeroRole.ARCHER)
	var mage_skills: Array = HeroSkill.get_skills_for_role(HeroRole.MAGE)
	var priest_skills: Array = HeroSkill.get_skills_for_role(HeroRole.PRIEST)
	return knight_skills.size() == 3 and archer_skills.size() == 3 and mage_skills.size() == 3 and priest_skills.size() == 3


func _test_canonical_skill_lookup_by_id() -> bool:
	var s: HeroSkill = HeroSkill.get_canonical_skill("knight_offense")
	return s != null and s.skill_id == "knight_offense" and s.skill_name == "Iron Edge" and s.required_role == HeroRole.KNIGHT and s.required_level == 3 and s.skill_type == HeroSkill.TYPE_PASSIVE_STAT and is_equal_approx(s.power_multiplier, 1.05)


# ==============================================================================
# 2. SKILL UNLOCKING DOMAIN & COORDINATOR TESTS (13-26)
# ==============================================================================

func _test_hero_starts_with_empty_unlocked_skills() -> bool:
	var hero := HeroModel.new("h_start", "Tester", 1, 3, HeroRole.KNIGHT)
	return hero.unlocked_skills.is_empty() and not hero.has_skill("knight_offense")


func _test_can_unlock_skill_requires_matching_role() -> bool:
	var hero := HeroModel.new("h_role", "Tester", 1, 3, HeroRole.KNIGHT)
	hero.level = 5
	return not hero.can_unlock_skill("archer_offense")


func _test_can_unlock_skill_requires_sufficient_level() -> bool:
	var hero := HeroModel.new("h_lvl", "Tester", 1, 3, HeroRole.KNIGHT)
	hero.level = 2 # knight_offense requires level 3
	return not hero.can_unlock_skill("knight_offense")


func _test_can_unlock_skill_succeeds_at_required_level() -> bool:
	var hero := HeroModel.new("h_succ", "Tester", 1, 3, HeroRole.KNIGHT)
	hero.level = 3
	return hero.can_unlock_skill("knight_offense")


func _test_unlock_skill_adds_to_unlocked_skills() -> bool:
	var hero := HeroModel.new("h_add", "Tester", 1, 3, HeroRole.KNIGHT)
	hero.level = 3
	var ok: bool = hero.unlock_skill("knight_offense")
	return ok and hero.has_skill("knight_offense") and hero.unlocked_skills.size() == 1


func _test_cannot_unlock_same_skill_twice() -> bool:
	var hero := HeroModel.new("h_dup", "Tester", 1, 3, HeroRole.KNIGHT)
	hero.level = 3
	hero.unlock_skill("knight_offense")
	return not hero.can_unlock_skill("knight_offense") and not hero.unlock_skill("knight_offense")


func _test_cannot_unlock_non_canonical_skill() -> bool:
	var hero := HeroModel.new("h_fake", "Tester", 1, 3, HeroRole.KNIGHT)
	hero.level = 10
	return not hero.can_unlock_skill("unknown_skill_xyz") and not hero.unlock_skill("unknown_skill_xyz")


func _test_dead_or_permadeath_hero_cannot_unlock_skill() -> bool:
	var hero := HeroModel.new("h_dead", "Tester", 1, 3, HeroRole.KNIGHT)
	hero.level = 5
	hero.mark_dead()
	return not hero.can_unlock_skill("knight_offense") and not hero.unlock_skill("knight_offense")


func _test_get_unlocked_skills_returns_duplicate() -> bool:
	var hero := HeroModel.new("h_dup_arr", "Tester", 1, 3, HeroRole.KNIGHT)
	hero.level = 3
	hero.unlock_skill("knight_offense")
	var copy: Array = hero.get_unlocked_skills()
	copy.append("malicious_injection")
	return not hero.has_skill("malicious_injection") and hero.unlocked_skills.size() == 1


func _test_unlock_multiple_skills_sequentially() -> bool:
	var hero := HeroModel.new("h_multi", "Tester", 2, 4, HeroRole.KNIGHT)
	hero.level = 10
	var ok1: bool = hero.unlock_skill("knight_offense")
	var ok2: bool = hero.unlock_skill("knight_defense")
	var ok3: bool = hero.unlock_skill("knight_leadership")
	return ok1 and ok2 and ok3 and hero.unlocked_skills.size() == 3


func _test_coordinator_can_unlock_hero_skill() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_sk_1")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.level = 3
	return coord.can_unlock_hero_skill("hero_alder", "knight_offense")


func _test_coordinator_unlock_hero_skill_succeeds() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_sk_2")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.level = 3
	var ok: bool = coord.unlock_hero_skill("hero_alder", "knight_offense")
	var snap_skills = coord.get_current_state().heroes_data[0].get("unlocked_skills", [])
	return ok and alder.has_skill("knight_offense") and ("knight_offense" in snap_skills)


func _test_coordinator_unlock_hero_skill_blocked_during_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_sk_3")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.level = 3
	coord.inspect_wave()
	coord.start_battle()
	var ok: bool = coord.unlock_hero_skill("hero_alder", "knight_offense")
	return not ok and not alder.has_skill("knight_offense")


func _test_coordinator_unlock_hero_skill_invalid_hero_returns_false() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_sk_4")
	return not coord.can_unlock_hero_skill("non_existent_hero", "knight_offense") and not coord.unlock_hero_skill("non_existent_hero", "knight_offense")


# ==============================================================================
# 3. TALENT POINTS ACQUISITION & ODD-LEVEL RULE TESTS (27-38)
# ==============================================================================

func _test_hero_starts_with_zero_talent_points() -> bool:
	var hero := HeroModel.new("h_tp_start", "Tester", 1, 3)
	return hero.talent_points == 0


func _test_level_1_to_2_grants_no_talent_points() -> bool:
	var hero := HeroModel.new("h_tp_l2", "Tester", 1, 3)
	var req: int = hero.get_required_exp(1) # 120
	hero.add_exp(req)
	return hero.level == 2 and hero.talent_points == 0


func _test_level_2_to_3_grants_one_talent_point() -> bool:
	var hero := HeroModel.new("h_tp_l3", "Tester", 1, 3)
	var exp_for_l3: int = hero.get_required_exp(1) + hero.get_required_exp(2)
	hero.add_exp(exp_for_l3)
	return hero.level == 3 and hero.talent_points == 1


func _test_level_3_to_4_grants_no_talent_points() -> bool:
	var hero := HeroModel.new("h_tp_l4", "Tester", 1, 3)
	var exp_for_l4: int = hero.get_required_exp(1) + hero.get_required_exp(2) + hero.get_required_exp(3)
	hero.add_exp(exp_for_l4)
	return hero.level == 4 and hero.talent_points == 1


func _test_level_4_to_5_grants_one_talent_point() -> bool:
	var hero := HeroModel.new("h_tp_l5", "Tester", 1, 3)
	var exp_for_l5: int = hero.get_required_exp(1) + hero.get_required_exp(2) + hero.get_required_exp(3) + hero.get_required_exp(4)
	hero.add_exp(exp_for_l5)
	return hero.level == 5 and hero.talent_points == 2


func _test_multi_level_jump_1_to_5_grants_2_points() -> bool:
	var hero := HeroModel.new("h_tp_jump5", "Tester", 1, 3)
	var total_exp: int = 0
	for i in range(1, 5):
		total_exp += hero.get_required_exp(i)
	hero.add_exp(total_exp)
	return hero.level == 5 and hero.talent_points == 2


func _test_multi_level_jump_1_to_7_grants_3_points() -> bool:
	var hero := HeroModel.new("h_tp_jump7", "Tester", 1, 3)
	var total_exp: int = 0
	for i in range(1, 7):
		total_exp += hero.get_required_exp(i)
	hero.add_exp(total_exp)
	return hero.level == 7 and hero.talent_points == 3


func _test_multi_level_jump_1_to_9_grants_4_points() -> bool:
	var hero := HeroModel.new("h_tp_jump9", "Tester", 1, 3)
	var total_exp: int = 0
	for i in range(1, 9):
		total_exp += hero.get_required_exp(i)
	hero.add_exp(total_exp)
	return hero.level == 9 and hero.talent_points == 4


func _test_ascension_does_not_modify_talent_points() -> bool:
	var hero := HeroModel.new("h_tp_asc", "Tester", 1, 3)
	var total_exp: int = 0
	for i in range(1, 10):
		total_exp += hero.get_required_exp(i)
	hero.add_exp(total_exp)
	# Level 10 reached, talent_points should be 4 (from levels 3, 5, 7, 9)
	var pts_before: int = hero.talent_points
	var ok: bool = hero.ascend()
	return ok and hero.current_star == 2 and hero.talent_points == pts_before and pts_before == 4


func _test_exp_carry_over_at_cap_grants_no_talent_points() -> bool:
	var hero := HeroModel.new("h_tp_cap", "Tester", 1, 3)
	var total_exp: int = 0
	for i in range(1, 10):
		total_exp += hero.get_required_exp(i)
	hero.add_exp(total_exp)
	var pts_at_cap: int = hero.talent_points
	hero.add_exp(500) # capped
	return hero.talent_points == pts_at_cap and hero.level == 10


func _test_training_exp_granting_odd_level_awards_talent_point() -> bool:
	var hero := HeroModel.new("h_tp_train", "Tester", 1, 3)
	# Advance hero to Level 2 with current_exp just under Lv3 requirement
	var exp_l1: int = hero.get_required_exp(1) # 120
	hero.add_exp(exp_l1)
	var req_l2: int = hero.get_required_exp(2) # 351
	hero.add_exp(req_l2 - 20)
	# Now hero is Level 2 with only 20 EXP needed for Level 3
	assert(hero.level == 2)
	assert(hero.talent_points == 0)
	hero.train(40, 15) # train grants 40 EXP -> level becomes 3!
	return hero.level == 3 and hero.talent_points == 1


func _test_zero_or_negative_exp_grants_no_talent_points() -> bool:
	var hero := HeroModel.new("h_tp_neg", "Tester", 1, 3)
	hero.add_exp(0)
	hero.add_exp(-50)
	return hero.talent_points == 0 and hero.level == 1


# ==============================================================================
# 4. TALENT ALLOCATION & BRANCH INTEGRITY TESTS (39-50)
# ==============================================================================

func _test_hero_starts_with_zero_allocated_talents() -> bool:
	var hero := HeroModel.new("h_alloc_0", "Tester", 1, 3)
	return hero.get_offense_talent_level() == 0 and hero.get_defense_talent_level() == 0 and hero.get_leadership_talent_level() == 0


func _test_cannot_allocate_with_zero_talent_points() -> bool:
	var hero := HeroModel.new("h_alloc_nopoints", "Tester", 1, 3)
	return not hero.can_allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE) and not hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)


func _test_cannot_allocate_to_invalid_branch() -> bool:
	var hero := HeroModel.new("h_alloc_badbranch", "Tester", 1, 3)
	hero.talent_points = 2
	return not hero.can_allocate_talent("MAGIC_SPEED") and not hero.allocate_talent("MAGIC_SPEED")


func _test_allocate_offense_talent_deducts_point() -> bool:
	var hero := HeroModel.new("h_alloc_off", "Tester", 1, 3)
	hero.talent_points = 1
	var ok: bool = hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	return ok and hero.talent_points == 0 and hero.get_offense_talent_level() == 1


func _test_allocate_defense_talent_deducts_point() -> bool:
	var hero := HeroModel.new("h_alloc_def", "Tester", 1, 3)
	hero.talent_points = 1
	var ok: bool = hero.allocate_talent(HeroModel.TALENT_BRANCH_DEFENSE)
	return ok and hero.talent_points == 0 and hero.get_defense_talent_level() == 1


func _test_allocate_leadership_talent_deducts_point() -> bool:
	var hero := HeroModel.new("h_alloc_ldr", "Tester", 1, 3)
	hero.talent_points = 1
	var ok: bool = hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	return ok and hero.talent_points == 0 and hero.get_leadership_talent_level() == 1


func _test_branch_level_capped_at_max_3() -> bool:
	var hero := HeroModel.new("h_alloc_cap3", "Tester", 1, 3)
	hero.talent_points = 5
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE) # 1
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE) # 2
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE) # 3
	var can_alloc_4th: bool = hero.can_allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	var alloc_4th: bool = hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	return hero.get_offense_talent_level() == 3 and hero.talent_points == 2 and not can_alloc_4th and not alloc_4th


func _test_dead_or_permadeath_hero_cannot_allocate_talent() -> bool:
	var hero := HeroModel.new("h_alloc_dead", "Tester", 1, 3)
	hero.talent_points = 2
	hero.mark_dead()
	return not hero.can_allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE) and not hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)


func _test_coordinator_can_allocate_hero_talent() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_tal_1")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.talent_points = 1
	return coord.can_allocate_hero_talent("hero_alder", HeroModel.TALENT_BRANCH_OFFENSE)


func _test_coordinator_allocate_hero_talent_succeeds() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_tal_2")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.talent_points = 1
	var ok: bool = coord.allocate_hero_talent("hero_alder", HeroModel.TALENT_BRANCH_OFFENSE)
	var snap_hero = coord.get_current_state().heroes_data[0]
	var allocated = snap_hero.get("allocated_talents", {})
	return ok and alder.talent_points == 0 and alder.get_offense_talent_level() == 1 and allocated.get("OFFENSE", 0) == 1


func _test_coordinator_allocate_talent_blocked_during_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_tal_3")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.talent_points = 1
	coord.inspect_wave()
	coord.start_battle()
	var ok: bool = coord.allocate_hero_talent("hero_alder", HeroModel.TALENT_BRANCH_OFFENSE)
	return not ok and alder.talent_points == 1 and alder.get_offense_talent_level() == 0


func _test_coordinator_allocate_talent_invalid_hero_returns_false() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_tal_4")
	return not coord.can_allocate_hero_talent("non_existent_hero", HeroModel.TALENT_BRANCH_OFFENSE) and not coord.allocate_hero_talent("non_existent_hero", HeroModel.TALENT_BRANCH_OFFENSE)


# ==============================================================================
# 5. STAT SCALING, MULTIPLIERS, INVARIANTS & PERSISTENCE TESTS (51-62)
# ==============================================================================

func _test_default_talent_multipliers_are_1_0() -> bool:
	var hero := HeroModel.new("h_mult_def", "Tester", 1, 3)
	return is_equal_approx(hero.get_talent_atk_multiplier(), 1.0) and is_equal_approx(hero.get_talent_def_multiplier(), 1.0)


func _test_offense_talent_multiplier_scaling() -> bool:
	var hero := HeroModel.new("h_mult_off", "Tester", 1, 3)
	hero.talent_points = 3
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	var atk_lv1: bool = is_equal_approx(hero.get_talent_atk_multiplier(), 1.02)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	var atk_lv2: bool = is_equal_approx(hero.get_talent_atk_multiplier(), 1.04)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	var atk_lv3: bool = is_equal_approx(hero.get_talent_atk_multiplier(), 1.06)
	var def_untouched: bool = is_equal_approx(hero.get_talent_def_multiplier(), 1.0)
	return atk_lv1 and atk_lv2 and atk_lv3 and def_untouched


func _test_defense_talent_multiplier_scaling() -> bool:
	var hero := HeroModel.new("h_mult_def_scale", "Tester", 1, 3)
	hero.talent_points = 3
	hero.allocate_talent(HeroModel.TALENT_BRANCH_DEFENSE)
	var def_lv1: bool = is_equal_approx(hero.get_talent_def_multiplier(), 1.02)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_DEFENSE)
	var def_lv2: bool = is_equal_approx(hero.get_talent_def_multiplier(), 1.04)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_DEFENSE)
	var def_lv3: bool = is_equal_approx(hero.get_talent_def_multiplier(), 1.06)
	var atk_untouched: bool = is_equal_approx(hero.get_talent_atk_multiplier(), 1.0)
	return def_lv1 and def_lv2 and def_lv3 and atk_untouched


func _test_leadership_talent_multiplier_scaling() -> bool:
	var hero := HeroModel.new("h_mult_ldr_scale", "Tester", 1, 3)
	hero.talent_points = 3
	hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	var lv1_ok: bool = is_equal_approx(hero.get_talent_atk_multiplier(), 1.01) and is_equal_approx(hero.get_talent_def_multiplier(), 1.01)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	var lv2_ok: bool = is_equal_approx(hero.get_talent_atk_multiplier(), 1.02) and is_equal_approx(hero.get_talent_def_multiplier(), 1.02)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	var lv3_ok: bool = is_equal_approx(hero.get_talent_atk_multiplier(), 1.03) and is_equal_approx(hero.get_talent_def_multiplier(), 1.03)
	return lv1_ok and lv2_ok and lv3_ok


func _test_combined_offense_leadership_multiplier() -> bool:
	var hero := HeroModel.new("h_mult_comb_off", "Tester", 1, 3)
	hero.talent_points = 6
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	# Expected: 1.06 * 1.03 = 1.0918
	var expected: float = 1.06 * 1.03
	return is_equal_approx(hero.get_talent_atk_multiplier(), expected)


func _test_combined_defense_leadership_multiplier() -> bool:
	var hero := HeroModel.new("h_mult_comb_def", "Tester", 1, 3)
	hero.talent_points = 6
	hero.allocate_talent(HeroModel.TALENT_BRANCH_DEFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_DEFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_DEFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	# Expected: 1.06 * 1.03 = 1.0918
	var expected: float = 1.06 * 1.03
	return is_equal_approx(hero.get_talent_def_multiplier(), expected)


func _test_effective_atk_integrates_talent_multiplier() -> bool:
	var hero := HeroModel.new("h_eff_atk", "Tester", 1, 3)
	hero.fatigue = 0 # 1.00
	hero.morale = 50 # 1.00
	# Base ATK = 35. Level 1, Star 1 -> base effective without talent = 35.
	var atk_before: int = hero.get_effective_atk()
	hero.talent_points = 3
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	# Offense Lv3 gives 1.06 -> 35 * 1.06 = 37.1 -> floor = 37.
	var atk_after: int = hero.get_effective_atk()
	return atk_before == 35 and atk_after == 37


func _test_effective_def_integrates_talent_multiplier() -> bool:
	var hero := HeroModel.new("h_eff_def", "Tester", 1, 3)
	hero.fatigue = 0 # 1.00
	hero.morale = 50 # 1.00
	# Base DEF = 20. Level 1, Star 1 -> base effective without talent = 20.
	var def_before: int = hero.get_effective_def()
	hero.talent_points = 3
	hero.allocate_talent(HeroModel.TALENT_BRANCH_DEFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_DEFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_DEFENSE)
	# Defense Lv3 gives 1.06 -> 20 * 1.06 = 21.2 -> floor = 21.
	var def_after: int = hero.get_effective_def()
	return def_before == 20 and def_after == 21


func _test_clone_preserves_skills_and_talents() -> bool:
	var hero := HeroModel.new("h_clone", "Tester", 2, 4, HeroRole.KNIGHT)
	hero.level = 5
	hero.unlock_skill("knight_offense")
	hero.talent_points = 2
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	var cl: HeroModel = hero.clone()
	return cl != null and cl != hero and cl.has_skill("knight_offense") and cl.talent_points == 1 and cl.get_offense_talent_level() == 1


func _test_validate_invariants_checks_talents() -> bool:
	var hero := HeroModel.new("h_inv", "Tester", 1, 3)
	hero.talent_points = -1
	var neg_pts_fail: bool = not hero.validate_invariants()
	hero.talent_points = 0
	hero.allocated_talents["OFFENSE"] = 4 # Exceeds max 3
	var over_lvl_fail: bool = not hero.validate_invariants()
	hero.allocated_talents["OFFENSE"] = 3
	var valid_ok: bool = hero.validate_invariants()
	return neg_pts_fail and over_lvl_fail and valid_ok


func _test_coordinator_snapshot_contains_phase4e_telemetry() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_snap_phase4e")
	var snap = coord.get_current_state()
	var h_data = snap.heroes_data[0]
	return h_data.has("unlocked_skills") and h_data.has("talent_points") and h_data.has("allocated_talents") and h_data.has("talent_atk_multiplier") and h_data.has("talent_def_multiplier")


func _test_phase4e_deterministic_regression_stability() -> bool:
	var hero := HeroModel.new("h_det", "Tester", 2, 4, HeroRole.KNIGHT)
	hero.level = 5
	hero.talent_points = 2
	hero.allocate_talent(HeroModel.TALENT_BRANCH_OFFENSE)
	hero.allocate_talent(HeroModel.TALENT_BRANCH_LEADERSHIP)
	var atk_1: int = hero.get_effective_atk()
	var def_1: int = hero.get_effective_def()
	for i in range(10):
		if hero.get_effective_atk() != atk_1 or hero.get_effective_def() != def_1:
			return false
	return true
