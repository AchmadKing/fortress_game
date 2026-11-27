extends SceneTree

## TestPhase4HHeroSystemIntegration
## Final Integration & Verification Gate untuk Phase 4 — Hero System.
## Memvalidasi 81 pengujian integrasi mendalam lintas subsistem (Groups A–K):
## Group A: Hero Lifecycle Integration (10 tests)
## Group B: Party & Combat Routing Integration (10 tests)
## Group C: Chemistry Integration (10 tests)
## Group D: EXP & Progression Integration (10 tests)
## Group E: Fatigue, Morale & Training Integration (8 tests)
## Group F: Skills & Talents Integration (8 tests)
## Group G: Equipment & Warehouse Conservation Integration (10 tests)
## Group H: Recruitment & Ascension Integration (6 tests)
## Group I: Snapshot, Clone & State Isolation (4 tests)
## Group J: Permadeath Full Integration (4 tests)
## Group K: Deterministic 50-Wave Multi-System Stress Simulation (1 test)

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const PrototypeDebugView = preload("res://scripts/presentation/views/prototype_debug_view.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const HeroSkill = preload("res://scripts/domain/model/hero_skill.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const PartyModel = preload("res://scripts/domain/model/party_model.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const CombatEngine = preload("res://scripts/simulation/combat_engine.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 4H HERO SYSTEM INTEGRATION & VERIFICATION TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# Group A: Hero Lifecycle Integration Tests (1-10)
		{"name": "test_a1_new_recruit_lifecycle_is_roster_active_and_reserve", "fn": Callable(self, "_test_a1_new_recruit_lifecycle_is_roster_active_and_reserve")},
		{"name": "test_a2_party_assignment_transitions_lifecycle_to_in_party", "fn": Callable(self, "_test_a2_party_assignment_transitions_lifecycle_to_in_party")},
		{"name": "test_a3_party_removal_transitions_lifecycle_to_roster_active", "fn": Callable(self, "_test_a3_party_removal_transitions_lifecycle_to_roster_active")},
		{"name": "test_a4_start_battle_transitions_party_1_to_battle_active", "fn": Callable(self, "_test_a4_start_battle_transitions_party_1_to_battle_active")},
		{"name": "test_a5_party_2_and_reserve_heroes_remain_in_party_and_roster_active_during_battle", "fn": Callable(self, "_test_a5_party_2_and_reserve_heroes_remain_in_party_and_roster_active_during_battle")},
		{"name": "test_a6_battle_survivor_transitions_back_to_in_party_after_recovery", "fn": Callable(self, "_test_a6_battle_survivor_transitions_back_to_in_party_after_recovery")},
		{"name": "test_a7_hero_death_transitions_to_permadeath", "fn": Callable(self, "_test_a7_hero_death_transitions_to_permadeath")},
		{"name": "test_a8_permadeath_is_terminal_no_transition_allowed", "fn": Callable(self, "_test_a8_permadeath_is_terminal_no_transition_allowed")},
		{"name": "test_a9_permadeath_hero_cannot_enter_party_or_battle", "fn": Callable(self, "_test_a9_permadeath_hero_cannot_enter_party_or_battle")},
		{"name": "test_a10_lifecycle_sync_across_domain_coordinator_and_snapshot", "fn": Callable(self, "_test_a10_lifecycle_sync_across_domain_coordinator_and_snapshot")},

		# Group B: Party & Combat Routing Integration Tests (11-20)
		{"name": "test_b1_exactly_two_canonical_parties_initialized", "fn": Callable(self, "_test_b1_exactly_two_canonical_parties_initialized")},
		{"name": "test_b2_party_capacity_limit_enforced_at_three", "fn": Callable(self, "_test_b2_party_capacity_limit_enforced_at_three")},
		{"name": "test_b3_hero_single_party_membership_invariant", "fn": Callable(self, "_test_b3_hero_single_party_membership_invariant")},
		{"name": "test_b4_party_leader_must_be_existing_member", "fn": Callable(self, "_test_b4_party_leader_must_be_existing_member")},
		{"name": "test_b5_party_leader_cleared_on_removal_or_death", "fn": Callable(self, "_test_b5_party_leader_cleared_on_removal_or_death")},
		{"name": "test_b6_only_party_1_contributes_to_battle_attack_power", "fn": Callable(self, "_test_b6_only_party_1_contributes_to_battle_attack_power")},
		{"name": "test_b7_party_2_heroes_completely_excluded_from_combat", "fn": Callable(self, "_test_b7_party_2_heroes_completely_excluded_from_combat")},
		{"name": "test_b8_reserve_heroes_completely_excluded_from_combat", "fn": Callable(self, "_test_b8_reserve_heroes_completely_excluded_from_combat")},
		{"name": "test_b9_empty_party_1_battle_execution_handles_gracefully", "fn": Callable(self, "_test_b9_empty_party_1_battle_execution_handles_gracefully")},
		{"name": "test_b10_atomic_party_assignment_rollback_on_failure", "fn": Callable(self, "_test_b10_atomic_party_assignment_rollback_on_failure")},

		# Group C: Chemistry Integration Tests (21-30)
		{"name": "test_c1_single_canonical_chemistry_gain_path_post_battle", "fn": Callable(self, "_test_c1_single_canonical_chemistry_gain_path_post_battle")},
		{"name": "test_c2_exact_plus_2_chemistry_per_surviving_party_1_pair", "fn": Callable(self, "_test_c2_exact_plus_2_chemistry_per_surviving_party_1_pair")},
		{"name": "test_c3_three_heroes_in_party_1_produce_exact_three_pairs", "fn": Callable(self, "_test_c3_three_heroes_in_party_1_produce_exact_three_pairs")},
		{"name": "test_c4_chemistry_is_strictly_symmetric", "fn": Callable(self, "_test_c4_chemistry_is_strictly_symmetric")},
		{"name": "test_c5_no_chemistry_gain_without_battle", "fn": Callable(self, "_test_c5_no_chemistry_gain_without_battle")},
		{"name": "test_c6_no_chemistry_gain_from_ui_or_snapshot_refresh", "fn": Callable(self, "_test_c6_no_chemistry_gain_from_ui_or_snapshot_refresh")},
		{"name": "test_c7_no_chemistry_gain_for_party_2_or_reserve_heroes", "fn": Callable(self, "_test_c7_no_chemistry_gain_for_party_2_or_reserve_heroes")},
		{"name": "test_c8_no_self_chemistry_allowed", "fn": Callable(self, "_test_c8_no_self_chemistry_allowed")},
		{"name": "test_c9_chemistry_capped_at_exactly_50", "fn": Callable(self, "_test_c9_chemistry_capped_at_exactly_50")},
		{"name": "test_c10_chemistry_persists_when_hero_leaves_and_rejoins_party", "fn": Callable(self, "_test_c10_chemistry_persists_when_hero_leaves_and_rejoins_party")},

		# Group D: EXP & Progression Integration Tests (31-40)
		{"name": "test_d1_battle_exp_awarded_only_to_surviving_party_1_heroes", "fn": Callable(self, "_test_d1_battle_exp_awarded_only_to_surviving_party_1_heroes")},
		{"name": "test_d2_party_2_and_reserve_heroes_receive_zero_battle_exp", "fn": Callable(self, "_test_d2_party_2_and_reserve_heroes_receive_zero_battle_exp")},
		{"name": "test_d3_battle_exp_distribution_is_deterministic_and_bounded", "fn": Callable(self, "_test_d3_battle_exp_distribution_is_deterministic_and_bounded")},
		{"name": "test_d4_exp_formula_matches_canonical_progression", "fn": Callable(self, "_test_d4_exp_formula_matches_canonical_progression")},
		{"name": "test_d5_level_cap_strictly_enforced_by_current_star", "fn": Callable(self, "_test_d5_level_cap_strictly_enforced_by_current_star")},
		{"name": "test_d6_exp_carry_over_preserved_at_and_after_cap", "fn": Callable(self, "_test_d6_exp_carry_over_preserved_at_and_after_cap")},
		{"name": "test_d7_odd_level_rule_grants_talent_points_on_level_up", "fn": Callable(self, "_test_d7_odd_level_rule_grants_talent_points_on_level_up")},
		{"name": "test_d8_multi_level_jump_calculates_talent_points_accurately", "fn": Callable(self, "_test_d8_multi_level_jump_calculates_talent_points_accurately")},
		{"name": "test_d9_training_exp_does_not_interfere_with_battle_exp", "fn": Callable(self, "_test_d9_training_exp_does_not_interfere_with_battle_exp")},
		{"name": "test_d10_no_double_exp_application", "fn": Callable(self, "_test_d10_no_double_exp_application")},

		# Group E: Fatigue, Morale & Training Integration Tests (41-48)
		{"name": "test_e1_battle_applies_exactly_15_fatigue_to_party_1", "fn": Callable(self, "_test_e1_battle_applies_exactly_15_fatigue_to_party_1")},
		{"name": "test_e2_battle_fatigue_not_applied_to_party_2_or_reserve", "fn": Callable(self, "_test_e2_battle_fatigue_not_applied_to_party_2_or_reserve")},
		{"name": "test_e3_training_applies_exactly_40_exp_and_15_fatigue", "fn": Callable(self, "_test_e3_training_applies_exactly_40_exp_and_15_fatigue")},
		{"name": "test_e4_training_restricted_to_once_per_hero_per_wave", "fn": Callable(self, "_test_e4_training_restricted_to_once_per_hero_per_wave")},
		{"name": "test_e5_training_wave_tracker_resets_upon_wave_progression", "fn": Callable(self, "_test_e5_training_wave_tracker_resets_upon_wave_progression")},
		{"name": "test_e6_fatigue_hard_cap_boundary_at_100", "fn": Callable(self, "_test_e6_fatigue_hard_cap_boundary_at_100")},
		{"name": "test_e7_rest_action_recovers_25_fatigue_and_5_morale", "fn": Callable(self, "_test_e7_rest_action_recovers_25_fatigue_and_5_morale")},
		{"name": "test_e8_fatigue_and_morale_multipliers_scale_effective_combat_stats", "fn": Callable(self, "_test_e8_fatigue_and_morale_multipliers_scale_effective_combat_stats")},

		# Group F: Skills & Talents Integration Tests (49-56)
		{"name": "test_f1_skill_catalog_canonical_roles_and_types", "fn": Callable(self, "_test_f1_skill_catalog_canonical_roles_and_types")},
		{"name": "test_f2_skill_unlock_level_and_role_requirements_enforced", "fn": Callable(self, "_test_f2_skill_unlock_level_and_role_requirements_enforced")},
		{"name": "test_f3_skill_unlock_idempotent_no_duplicate_unlock", "fn": Callable(self, "_test_f3_skill_unlock_idempotent_no_duplicate_unlock")},
		{"name": "test_f4_talent_allocation_branches_offense_defense_leadership", "fn": Callable(self, "_test_f4_talent_allocation_branches_offense_defense_leadership")},
		{"name": "test_f5_talent_allocation_strictly_capped_at_level_3", "fn": Callable(self, "_test_f5_talent_allocation_strictly_capped_at_level_3")},
		{"name": "test_f6_talent_allocation_requires_available_talent_points", "fn": Callable(self, "_test_f6_talent_allocation_requires_available_talent_points")},
		{"name": "test_f7_talent_multipliers_composite_stat_scaling", "fn": Callable(self, "_test_f7_talent_multipliers_composite_stat_scaling")},
		{"name": "test_f8_skills_and_talents_preserved_through_clone_and_snapshot", "fn": Callable(self, "_test_f8_skills_and_talents_preserved_through_clone_and_snapshot")},

		# Group G: Equipment & Warehouse Conservation Integration Tests (57-66)
		{"name": "test_g1_shared_warehouse_conservation_equation_invariant", "fn": Callable(self, "_test_g1_shared_warehouse_conservation_equation_invariant")},
		{"name": "test_g2_hero_equipment_compatible_role_slots_only", "fn": Callable(self, "_test_g2_hero_equipment_compatible_role_slots_only")},
		{"name": "test_g3_equipping_hero_decrements_warehouse_stock_by_one", "fn": Callable(self, "_test_g3_equipping_hero_decrements_warehouse_stock_by_one")},
		{"name": "test_g4_unequipping_hero_increments_warehouse_stock_by_one", "fn": Callable(self, "_test_g4_unequipping_hero_increments_warehouse_stock_by_one")},
		{"name": "test_g5_surviving_battle_preserves_hero_equipped_items", "fn": Callable(self, "_test_g5_surviving_battle_preserves_hero_equipped_items")},
		{"name": "test_g6_permadeath_returns_all_hero_equipment_to_warehouse_exactly_once", "fn": Callable(self, "_test_g6_permadeath_returns_all_hero_equipment_to_warehouse_exactly_once")},
		{"name": "test_g7_repeated_recovery_does_not_double_return_dead_hero_equipment", "fn": Callable(self, "_test_g7_repeated_recovery_does_not_double_return_dead_hero_equipment")},
		{"name": "test_g8_party_assignment_does_not_affect_hero_equipment", "fn": Callable(self, "_test_g8_party_assignment_does_not_affect_hero_equipment")},
		{"name": "test_g9_dismiss_hero_returns_all_equipment_to_warehouse", "fn": Callable(self, "_test_g9_dismiss_hero_returns_all_equipment_to_warehouse")},
		{"name": "test_g10_equipment_swap_preserves_total_conservation", "fn": Callable(self, "_test_g10_equipment_swap_preserves_total_conservation")},

		# Group H: Recruitment & Ascension Integration Tests (67-72)
		{"name": "test_h1_recruitment_cost_fixed_at_500_gold_no_override", "fn": Callable(self, "_test_h1_recruitment_cost_fixed_at_500_gold_no_override")},
		{"name": "test_h2_recruitment_rejected_when_treasury_under_500_gold", "fn": Callable(self, "_test_h2_recruitment_rejected_when_treasury_under_500_gold")},
		{"name": "test_h3_new_recruit_has_empty_equipment_and_starts_in_reserve", "fn": Callable(self, "_test_h3_new_recruit_has_empty_equipment_and_starts_in_reserve")},
		{"name": "test_h4_ascension_cost_formula_current_star_times_150_gold", "fn": Callable(self, "_test_h4_ascension_cost_formula_current_star_times_150_gold")},
		{"name": "test_h5_ascension_requires_level_cap_and_gold_and_potential", "fn": Callable(self, "_test_h5_ascension_requires_level_cap_and_gold_and_potential")},
		{"name": "test_h6_ascension_preserves_all_hero_progression_attributes", "fn": Callable(self, "_test_h6_ascension_preserves_all_hero_progression_attributes")},

		# Group I: Snapshot, Clone & State Isolation Tests (73-76)
		{"name": "test_i1_hero_model_clone_complete_state_isolation", "fn": Callable(self, "_test_i1_hero_model_clone_complete_state_isolation")},
		{"name": "test_i2_party_model_clone_complete_state_isolation", "fn": Callable(self, "_test_i2_party_model_clone_complete_state_isolation")},
		{"name": "test_i3_snapshot_clone_complete_state_isolation", "fn": Callable(self, "_test_i3_snapshot_clone_complete_state_isolation")},
		{"name": "test_i4_coordinator_mutation_synchronizes_snapshot_and_triggers_ui_reactively", "fn": Callable(self, "_test_i4_coordinator_mutation_synchronizes_snapshot_and_triggers_ui_reactively")},

		# Group J: Permadeath Full Lifecycle Integration Tests (77-80)
		{"name": "test_j1_permadeath_hero_removed_from_party_and_cleared_from_leader", "fn": Callable(self, "_test_j1_permadeath_hero_removed_from_party_and_cleared_from_leader")},
		{"name": "test_j2_permadeath_cleans_chemistry_references_symmetrically", "fn": Callable(self, "_test_j2_permadeath_cleans_chemistry_references_symmetrically")},
		{"name": "test_j3_permadeath_hero_blocked_from_all_roster_actions", "fn": Callable(self, "_test_j3_permadeath_hero_blocked_from_all_roster_actions")},
		{"name": "test_j4_permadeath_is_permanent_cannot_be_revived_or_reassigned", "fn": Callable(self, "_test_j4_permadeath_is_permanent_cannot_be_revived_or_reassigned")},

		# Group K: Deterministic 50-Wave Multi-System Stress Simulation (81)
		{"name": "test_k1_deterministic_50_wave_multi_system_stress_simulation", "fn": Callable(self, "_test_k1_deterministic_50_wave_multi_system_stress_simulation")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 4H TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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


# Helper session creation
func _create_test_session() -> Dictionary:
	var coord := GameCoordinator.new()
	var ctrl := GameController.new()
	var view := PrototypeDebugView.new()
	root.add_child(ctrl)
	root.add_child(view)
	coord.start_new_session("test_hero_integration_session", 777)
	ctrl.setup(coord)
	view.setup(coord, ctrl)
	return {"coordinator": coord, "controller": ctrl, "view": view}


func _cleanup_session(session: Dictionary) -> void:
	var ctrl: GameController = session.get("controller")
	var view: PrototypeDebugView = session.get("view")
	if ctrl != null and is_instance_valid(ctrl):
		ctrl.queue_free()
	if view != null and is_instance_valid(view):
		view.queue_free()


# ==============================================================================
# GROUP A: HERO LIFECYCLE INTEGRATION TESTS (1-10)
# ==============================================================================

func _test_a1_new_recruit_lifecycle_is_roster_active_and_reserve() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.set_treasury_gold(1000)
	var hero := coord.recruit_hero("KNIGHT")
	var ok: bool = (hero != null)
	ok = ok and (hero.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE)
	ok = ok and (hero.party_id == "")
	ok = ok and (not hero.is_in_party())
	_cleanup_session(s)
	return ok


func _test_a2_party_assignment_transitions_lifecycle_to_in_party() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var hero := coord.get_hero("hero_alder")
	var ok_assign: bool = coord.assign_hero_to_party("hero_alder", "party_1")
	var ok: bool = ok_assign and (hero.lifecycle_state == HeroLifecycleState.IN_PARTY)
	ok = ok and (hero.party_id == "party_1")
	_cleanup_session(s)
	return ok


func _test_a3_party_removal_transitions_lifecycle_to_roster_active() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var hero := coord.get_hero("hero_alder")
	coord.assign_hero_to_party("hero_alder", "party_1")
	var ok_rem: bool = coord.remove_hero_from_party("hero_alder")
	var ok: bool = ok_rem and (hero.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE)
	ok = ok and (hero.party_id == "")
	_cleanup_session(s)
	return ok


func _test_a4_start_battle_transitions_party_1_to_battle_active() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	var ok: bool = (alder.lifecycle_state == HeroLifecycleState.BATTLE_ACTIVE)
	_cleanup_session(s)
	return ok


func _test_a5_party_2_and_reserve_heroes_remain_in_party_and_roster_active_during_battle() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	var lyra := coord.get_hero("hero_lyra")
	coord.set_treasury_gold(1000)
	var gale := coord.recruit_hero("MAGE")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")
	# gale is in reserve
	coord.inspect_wave()
	coord.start_battle()
	var ok: bool = (alder.lifecycle_state == HeroLifecycleState.BATTLE_ACTIVE)
	ok = ok and (lyra.lifecycle_state == HeroLifecycleState.IN_PARTY)
	ok = ok and (gale.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE)
	_cleanup_session(s)
	return ok


func _test_a6_battle_survivor_transitions_back_to_in_party_after_recovery() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(100)
	coord.proceed_from_result()
	var ok: bool = (alder.is_alive and alder.lifecycle_state == HeroLifecycleState.IN_PARTY)
	ok = ok and (alder.party_id == "party_1")
	_cleanup_session(s)
	return ok


func _test_a7_hero_death_transitions_to_permadeath() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.mark_dead()
	var ok: bool = (not alder.is_alive)
	ok = ok and (alder.lifecycle_state == HeroLifecycleState.PERMADEATH)
	ok = ok and (alder.party_id == "")
	_cleanup_session(s)
	return ok


func _test_a8_permadeath_is_terminal_no_transition_allowed() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.mark_dead()
	var fail_roster: bool = alder.transition_lifecycle_state(HeroLifecycleState.ROSTER_ACTIVE)
	var fail_party: bool = alder.transition_lifecycle_state(HeroLifecycleState.IN_PARTY)
	var fail_battle: bool = alder.transition_lifecycle_state(HeroLifecycleState.BATTLE_ACTIVE)
	var ok: bool = (not fail_roster and not fail_party and not fail_battle)
	ok = ok and (alder.lifecycle_state == HeroLifecycleState.PERMADEATH)
	_cleanup_session(s)
	return ok


func _test_a9_permadeath_hero_cannot_enter_party_or_battle() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.mark_dead()
	var fail_assign1: bool = coord.assign_hero_to_party("hero_alder", "party_1")
	var fail_assign2: bool = coord.assign_hero_to_party("hero_alder", "party_2")
	var ok: bool = (not fail_assign1 and not fail_assign2)
	var battle_ids: Array = coord.get_active_battle_hero_ids()
	ok = ok and (not battle_ids.has("hero_alder"))
	_cleanup_session(s)
	return ok


func _test_a10_lifecycle_sync_across_domain_coordinator_and_snapshot() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	coord.assign_hero_to_party("hero_alder", "party_1")
	var snap := coord.get_current_state()
	var snap_alder_lc: String = ""
	var snap_alder_pid: String = ""
	for h in snap.heroes_data:
		if h.get("hero_id", "") == "hero_alder":
			snap_alder_lc = str(h.get("lifecycle_state", ""))
			snap_alder_pid = str(h.get("party_id", ""))
			break
	var ok: bool = (alder.lifecycle_state == HeroLifecycleState.IN_PARTY)
	ok = ok and (snap_alder_lc == HeroLifecycleState.IN_PARTY)
	ok = ok and (snap_alder_pid == "party_1")
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP B: PARTY & COMBAT ROUTING INTEGRATION TESTS (11-20)
# ==============================================================================

func _test_b1_exactly_two_canonical_parties_initialized() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var p1: PartyModel = coord.get_party("party_1")
	var p2: PartyModel = coord.get_party("party_2")
	var p3: PartyModel = coord.get_party("party_3")
	var parties: Array = coord.get_parties()
	var ok: bool = (p1 != null and p2 != null and p3 == null)
	ok = ok and (parties.size() == 2)
	ok = ok and (p1.is_deployed_to_battle == true)
	ok = ok and (p2.is_deployed_to_battle == false)
	_cleanup_session(s)
	return ok


func _test_b2_party_capacity_limit_enforced_at_three() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.set_treasury_gold(2000)
	var h3 := coord.recruit_hero("MAGE")
	var h4 := coord.recruit_hero("PRIEST")
	var a1: bool = coord.assign_hero_to_party("hero_alder", "party_1")
	var a2: bool = coord.assign_hero_to_party("hero_lyra", "party_1")
	var a3: bool = coord.assign_hero_to_party(h3.hero_id, "party_1")
	var a4: bool = coord.assign_hero_to_party(h4.hero_id, "party_1")
	var ok: bool = (a1 and a2 and a3 and not a4)
	var p1: PartyModel = coord.get_party("party_1")
	ok = ok and (p1.get_member_count() == 3)
	_cleanup_session(s)
	return ok


func _test_b3_hero_single_party_membership_invariant() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	var direct_to_p2: bool = coord.assign_hero_to_party("hero_alder", "party_2")
	var ok: bool = (not direct_to_p2)
	var p1: PartyModel = coord.get_party("party_1")
	var p2: PartyModel = coord.get_party("party_2")
	ok = ok and (p1.has_member("hero_alder"))
	ok = ok and (not p2.has_member("hero_alder"))
	_cleanup_session(s)
	return ok


func _test_b4_party_leader_must_be_existing_member() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	var non_member_lead: bool = coord.set_party_leader("hero_lyra", "party_1")
	var member_lead: bool = coord.set_party_leader("hero_alder", "party_1")
	var ok: bool = (not non_member_lead and member_lead)
	var p1: PartyModel = coord.get_party("party_1")
	ok = ok and (p1.leader_hero_id == "hero_alder")
	_cleanup_session(s)
	return ok


func _test_b5_party_leader_cleared_on_removal_or_death() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.set_party_leader("hero_alder", "party_1")
	coord.remove_hero_from_party("hero_alder")
	var p1: PartyModel = coord.get_party("party_1")
	var ok: bool = (p1.leader_hero_id == "")
	_cleanup_session(s)
	return ok


func _test_b6_only_party_1_contributes_to_battle_attack_power() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")
	var battle_heroes := coord.get_active_battle_heroes()
	var ok: bool = (battle_heroes.size() == 1)
	ok = ok and ((battle_heroes[0] as HeroModel).hero_id == "hero_alder")
	_cleanup_session(s)
	return ok


func _test_b7_party_2_heroes_completely_excluded_from_combat() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")
	var init_lyra_fat: int = coord.get_hero("hero_lyra").fatigue
	var init_lyra_exp: int = coord.get_hero("hero_lyra").current_exp
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(55)
	coord.proceed_from_result()
	var lyra := coord.get_hero("hero_lyra")
	var ok: bool = (lyra.fatigue == init_lyra_fat)
	ok = ok and (lyra.current_exp == init_lyra_exp)
	ok = ok and (lyra.is_alive)
	_cleanup_session(s)
	return ok


func _test_b8_reserve_heroes_completely_excluded_from_combat() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.set_treasury_gold(1000)
	var gale := coord.recruit_hero("MAGE")
	coord.assign_hero_to_party("hero_alder", "party_1")
	var init_gale_fat: int = gale.fatigue
	var init_gale_exp: int = gale.current_exp
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(56)
	coord.proceed_from_result()
	var ok: bool = (gale.fatigue == init_gale_fat)
	ok = ok and (gale.current_exp == init_gale_exp)
	ok = ok and (gale.party_id == "")
	_cleanup_session(s)
	return ok


func _test_b9_empty_party_1_battle_execution_handles_gracefully() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	# Both Alder and Lyra are in reserve
	var ok_insp: bool = coord.inspect_wave()
	var ok_start: bool = coord.start_battle()
	var res := coord.execute_battle(57)
	var ok_proc: bool = coord.proceed_from_result()
	var ok: bool = (ok_insp and ok_start and not res.is_empty() and ok_proc)
	_cleanup_session(s)
	return ok


func _test_b10_atomic_party_assignment_rollback_on_failure() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.set_treasury_gold(2000)
	var h3 := coord.recruit_hero("MAGE")
	var h4 := coord.recruit_hero("PRIEST")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party(h3.hero_id, "party_1")
	# Party 1 is full (3/3). Try to assign h4
	var ok_assign: bool = coord.assign_hero_to_party(h4.hero_id, "party_1")
	var ok: bool = (not ok_assign)
	ok = ok and (h4.party_id == "")
	ok = ok and (h4.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE)
	var p1 := coord.get_party("party_1")
	ok = ok and (not p1.has_member(h4.hero_id))
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP C: CHEMISTRY INTEGRATION TESTS (21-30)
# ==============================================================================

func _test_c1_single_canonical_chemistry_gain_path_post_battle() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	var alder := coord.get_hero("hero_alder")
	var init_chem: int = alder.chemistry_map.get("hero_lyra", 0)
	# inspect wave does not increase chemistry
	coord.inspect_wave()
	var pre_chem: int = alder.chemistry_map.get("hero_lyra", 0)
	coord.start_battle()
	var start_chem: int = alder.chemistry_map.get("hero_lyra", 0)
	coord.execute_battle(10)
	coord.proceed_from_result()
	var post_chem: int = alder.chemistry_map.get("hero_lyra", 0)
	var ok: bool = (init_chem == 0 and pre_chem == 0 and start_chem == 0 and post_chem == 2)
	_cleanup_session(s)
	return ok


func _test_c2_exact_plus_2_chemistry_per_surviving_party_1_pair() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(11)
	coord.proceed_from_result()
	var alder := coord.get_hero("hero_alder")
	var lyra := coord.get_hero("hero_lyra")
	var ok: bool = (alder.chemistry_map.get("hero_lyra", 0) == 2)
	ok = ok and (lyra.chemistry_map.get("hero_alder", 0) == 2)
	_cleanup_session(s)
	return ok


func _test_c3_three_heroes_in_party_1_produce_exact_three_pairs() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.set_treasury_gold(1000)
	var gale := coord.recruit_hero("MAGE")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party(gale.hero_id, "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(12)
	coord.proceed_from_result()
	var alder := coord.get_hero("hero_alder")
	var lyra := coord.get_hero("hero_lyra")
	var ok: bool = (alder.chemistry_map.get("hero_lyra", 0) == 2 and alder.chemistry_map.get(gale.hero_id, 0) == 2)
	ok = ok and (lyra.chemistry_map.get("hero_alder", 0) == 2 and lyra.chemistry_map.get(gale.hero_id, 0) == 2)
	ok = ok and (gale.chemistry_map.get("hero_alder", 0) == 2 and gale.chemistry_map.get("hero_lyra", 0) == 2)
	_cleanup_session(s)
	return ok


func _test_c4_chemistry_is_strictly_symmetric() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(13)
	coord.proceed_from_result()
	var alder := coord.get_hero("hero_alder")
	var lyra := coord.get_hero("hero_lyra")
	var chem_a_l: int = int(alder.chemistry_map.get("hero_lyra", -1))
	var chem_l_a: int = int(lyra.chemistry_map.get("hero_alder", -1))
	var ok: bool = (chem_a_l == chem_l_a and chem_a_l == 2)
	_cleanup_session(s)
	return ok


func _test_c5_no_chemistry_gain_without_battle() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.remove_hero_from_party("hero_alder")
	coord.assign_hero_to_party("hero_alder", "party_1")
	var alder := coord.get_hero("hero_alder")
	var ok: bool = (alder.chemistry_map.is_empty())
	_cleanup_session(s)
	return ok


func _test_c6_no_chemistry_gain_from_ui_or_snapshot_refresh() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	for i in range(5):
		coord.get_current_state()
		view._render_hero_roster(coord.get_current_state())
		view._render_hero_detail_panel(coord.get_current_state())
	var alder := coord.get_hero("hero_alder")
	var ok: bool = (alder.chemistry_map.is_empty())
	_cleanup_session(s)
	return ok


func _test_c7_no_chemistry_gain_for_party_2_or_reserve_heroes() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.set_treasury_gold(2000)
	var h3 := coord.recruit_hero("MAGE")
	var h4 := coord.recruit_hero("PRIEST")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")
	coord.assign_hero_to_party(h3.hero_id, "party_2")
	# h4 in reserve
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(14)
	coord.proceed_from_result()
	var lyra := coord.get_hero("hero_lyra")
	var ok: bool = (lyra.chemistry_map.is_empty())
	ok = ok and (h3.chemistry_map.is_empty())
	ok = ok and (h4.chemistry_map.is_empty())
	_cleanup_session(s)
	return ok


func _test_c8_no_self_chemistry_allowed() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.add_chemistry("hero_alder", 10)
	var ok: bool = (not alder.chemistry_map.has("hero_alder"))
	_cleanup_session(s)
	return ok


func _test_c9_chemistry_capped_at_exactly_50() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	var lyra := coord.get_hero("hero_lyra")
	alder.add_chemistry("hero_lyra", 49)
	lyra.add_chemistry("hero_alder", 49)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(15)
	coord.proceed_from_result()
	var ok: bool = (alder.chemistry_map.get("hero_lyra", 0) == 50)
	ok = ok and (lyra.chemistry_map.get("hero_alder", 0) == 50)
	_cleanup_session(s)
	return ok


func _test_c10_chemistry_persists_when_hero_leaves_and_rejoins_party() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(16)
	coord.proceed_from_result() # chemistry = 2
	coord.remove_hero_from_party("hero_lyra") # lyra to reserve
	var alder := coord.get_hero("hero_alder")
	var lyra := coord.get_hero("hero_lyra")
	var chem_in_res: bool = (alder.chemistry_map.get("hero_lyra", 0) == 2 and lyra.chemistry_map.get("hero_alder", 0) == 2)
	coord.assign_hero_to_party("hero_lyra", "party_1") # re-join
	var ok: bool = chem_in_res and (alder.chemistry_map.get("hero_lyra", 0) == 2 and lyra.chemistry_map.get("hero_alder", 0) == 2)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP D: EXP & PROGRESSION INTEGRATION TESTS (31-40)
# ==============================================================================

func _test_d1_battle_exp_awarded_only_to_surviving_party_1_heroes() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")
	var init_exp: int = coord.get_hero("hero_alder").current_exp
	coord.inspect_wave()
	coord.start_battle()
	var res := coord.execute_battle(20)
	coord.proceed_from_result()
	var alder := coord.get_hero("hero_alder")
	var ok: bool = (alder.current_exp > init_exp)
	_cleanup_session(s)
	return ok


func _test_d2_party_2_and_reserve_heroes_receive_zero_battle_exp() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.set_treasury_gold(1000)
	var gale := coord.recruit_hero("MAGE")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(21)
	coord.proceed_from_result()
	var lyra := coord.get_hero("hero_lyra")
	var ok: bool = (lyra.current_exp == 0 and gale.current_exp == 0)
	_cleanup_session(s)
	return ok


func _test_d3_battle_exp_distribution_is_deterministic_and_bounded() -> bool:
	var total_exp: int = 100
	var h_a := HeroModel.new("hero_b", "Hero B", 1, 3)
	var h_b := HeroModel.new("hero_a", "Hero A", 1, 3)
	var dist := CombatEngine.distribute_battle_exp(total_exp, [h_a, h_b])
	# hero_a gets 50, hero_b gets 50
	var ok: bool = (dist["hero_a"] == 50 and dist["hero_b"] == 50)
	var total_exp_odd: int = 101
	var dist_odd := CombatEngine.distribute_battle_exp(total_exp_odd, [h_a, h_b])
	# Alphabetical sort: hero_a gets remainder (51), hero_b gets 50
	ok = ok and (dist_odd["hero_a"] == 51 and dist_odd["hero_b"] == 50)
	return ok


func _test_d4_exp_formula_matches_canonical_progression() -> bool:
	var h := HeroModel.new("h", "Hero", 1, 5)
	var ok: bool = (h.get_required_exp(1) == 120)
	ok = ok and (h.get_required_exp(2) == 351)
	ok = ok and (h.get_required_exp(3) == 658)
	ok = ok and (h.get_required_exp(4) == 1028)
	return ok


func _test_d5_level_cap_strictly_enforced_by_current_star() -> bool:
	var h := HeroModel.new("h", "Hero", 1, 4) # 1 star -> level cap = 10
	h.level = 10
	h.current_exp = 0
	h.add_exp(50000)
	var ok: bool = (h.level == 10)
	return ok


func _test_d6_exp_carry_over_preserved_at_and_after_cap() -> bool:
	var h := HeroModel.new("h", "Hero", 1, 4)
	h.level = 10
	h.current_exp = 500
	var ok: bool = (h.current_exp == 500)
	h.current_star = 2 # ascension manually expanded cap to 20
	h.add_exp(5000)
	ok = ok and (h.level > 10)
	return ok


func _test_d7_odd_level_rule_grants_talent_points_on_level_up() -> bool:
	var h := HeroModel.new("h", "Hero", 1, 4)
	h.add_exp(120)
	var ok: bool = (h.level == 2 and h.talent_points == 0)
	h.add_exp(351)
	ok = ok and (h.level == 3 and h.talent_points == 1)
	return ok


func _test_d8_multi_level_jump_calculates_talent_points_accurately() -> bool:
	var h := HeroModel.new("h", "Hero", 1, 4)
	h.add_exp(120 + 351 + 658 + 1028)
	var ok: bool = (h.level == 5 and h.talent_points == 2)
	return ok


func _test_d9_training_exp_does_not_interfere_with_battle_exp() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.train_hero("hero_alder") # +40 EXP
	var exp_after_train: int = coord.get_hero("hero_alder").current_exp
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(30)
	coord.proceed_from_result()
	var final_exp: int = coord.get_hero("hero_alder").current_exp
	var ok: bool = (exp_after_train == 40 and final_exp > 40)
	_cleanup_session(s)
	return ok


func _test_d10_no_double_exp_application() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	var res := coord.execute_battle(31)
	var exp_per_hero: int = int(res.get("exp_distribution", {}).get("hero_alder", 0))
	var alder := coord.get_hero("hero_alder")
	var exp_right_after_battle: int = alder.current_exp
	coord.proceed_from_result()
	var exp_after_proceed: int = alder.current_exp
	var ok: bool = (exp_right_after_battle == exp_per_hero and exp_after_proceed == exp_per_hero)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP E: FATIGUE, MORALE & TRAINING INTEGRATION TESTS (41-48)
# ==============================================================================

func _test_e1_battle_applies_exactly_15_fatigue_to_party_1() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(40)
	var alder := coord.get_hero("hero_alder")
	var ok: bool = (alder.fatigue == 15)
	_cleanup_session(s)
	return ok


func _test_e2_battle_fatigue_not_applied_to_party_2_or_reserve() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(41)
	var lyra := coord.get_hero("hero_lyra")
	var ok: bool = (lyra.fatigue == 0)
	_cleanup_session(s)
	return ok


func _test_e3_training_applies_exactly_40_exp_and_15_fatigue() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var ok_train: bool = coord.train_hero("hero_alder")
	var alder := coord.get_hero("hero_alder")
	var ok: bool = (ok_train and alder.current_exp == 40 and alder.fatigue == 15)
	_cleanup_session(s)
	return ok


func _test_e4_training_restricted_to_once_per_hero_per_wave() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var t1: bool = coord.train_hero("hero_alder")
	var t2: bool = coord.train_hero("hero_alder")
	var ok: bool = (t1 and not t2)
	_cleanup_session(s)
	return ok


func _test_e5_training_wave_tracker_resets_upon_wave_progression() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.train_hero("hero_alder")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result() # advances to Wave 2
	var can_train_w2: bool = coord.can_train_hero("hero_alder")
	var ok: bool = can_train_w2
	_cleanup_session(s)
	return ok


func _test_e6_fatigue_hard_cap_boundary_at_100() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.fatigue = 90
	var can_t: bool = coord.can_train_hero("hero_alder")
	var ok: bool = (not can_t)
	var t_fail: bool = coord.train_hero("hero_alder")
	ok = ok and (not t_fail and alder.fatigue == 90)
	_cleanup_session(s)
	return ok


func _test_e7_rest_action_recovers_25_fatigue_and_5_morale() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.fatigue = 60
	alder.morale = 80
	var ok_rest: bool = coord.rest_hero("hero_alder")
	var ok: bool = (ok_rest and alder.fatigue == 35 and alder.morale == 85)
	_cleanup_session(s)
	return ok


func _test_e8_fatigue_and_morale_multipliers_scale_effective_combat_stats() -> bool:
	var h := HeroModel.new("h", "Hero", 1, 3, "KNIGHT")
	h.fatigue = 0
	h.morale = 100
	var eff_atk_100: int = h.get_effective_atk()
	h.morale = 50
	var eff_atk_50: int = h.get_effective_atk()
	var ok: bool = (eff_atk_100 > eff_atk_50)
	h.fatigue = 100
	var eff_atk_fat: int = h.get_effective_atk()
	ok = ok and (eff_atk_50 > eff_atk_fat)
	return ok


# ==============================================================================
# GROUP F: SKILLS & TALENTS INTEGRATION TESTS (49-56)
# ==============================================================================

func _test_f1_skill_catalog_canonical_roles_and_types() -> bool:
	var knight_skills := HeroSkill.get_skills_for_role("KNIGHT")
	var archer_skills := HeroSkill.get_skills_for_role("ARCHER")
	var mage_skills := HeroSkill.get_skills_for_role("MAGE")
	var priest_skills := HeroSkill.get_skills_for_role("PRIEST")
	var ok: bool = (knight_skills.size() == 3 and archer_skills.size() == 3 and mage_skills.size() == 3 and priest_skills.size() == 3)
	return ok


func _test_f2_skill_unlock_level_and_role_requirements_enforced() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.level = 1
	var fail_lvl: bool = coord.unlock_hero_skill("hero_alder", "knight_offense") # requires Lv.3
	var fail_role: bool = coord.unlock_hero_skill("hero_alder", "archer_offense")
	var ok: bool = (not fail_lvl and not fail_role)
	alder.level = 3
	var ok_unl: bool = coord.unlock_hero_skill("hero_alder", "knight_offense")
	ok = ok and ok_unl
	_cleanup_session(s)
	return ok


func _test_f3_skill_unlock_idempotent_no_duplicate_unlock() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.level = 3
	var u1: bool = coord.unlock_hero_skill("hero_alder", "knight_offense")
	var u2: bool = coord.unlock_hero_skill("hero_alder", "knight_offense")
	var ok: bool = (u1 and not u2)
	ok = ok and (alder.unlocked_skills.size() == 1)
	_cleanup_session(s)
	return ok


func _test_f4_talent_allocation_branches_offense_defense_leadership() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.talent_points = 3
	var o1: bool = coord.allocate_hero_talent("hero_alder", "OFFENSE")
	var d1: bool = coord.allocate_hero_talent("hero_alder", "DEFENSE")
	var l1: bool = coord.allocate_hero_talent("hero_alder", "LEADERSHIP")
	var ok: bool = (o1 and d1 and l1 and alder.talent_points == 0)
	ok = ok and (alder.allocated_talents["OFFENSE"] == 1)
	ok = ok and (alder.allocated_talents["DEFENSE"] == 1)
	ok = ok and (alder.allocated_talents["LEADERSHIP"] == 1)
	_cleanup_session(s)
	return ok


func _test_f5_talent_allocation_strictly_capped_at_level_3() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.talent_points = 5
	coord.allocate_hero_talent("hero_alder", "OFFENSE")
	coord.allocate_hero_talent("hero_alder", "OFFENSE")
	coord.allocate_hero_talent("hero_alder", "OFFENSE")
	var o4: bool = coord.allocate_hero_talent("hero_alder", "OFFENSE")
	var ok: bool = (not o4 and alder.allocated_talents["OFFENSE"] == 3 and alder.talent_points == 2)
	_cleanup_session(s)
	return ok


func _test_f6_talent_allocation_requires_available_talent_points() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.talent_points = 0
	var fail_alloc: bool = coord.allocate_hero_talent("hero_alder", "OFFENSE")
	var ok: bool = (not fail_alloc and alder.allocated_talents["OFFENSE"] == 0)
	_cleanup_session(s)
	return ok


func _test_f7_talent_multipliers_composite_stat_scaling() -> bool:
	var h := HeroModel.new("h", "Hero", 1, 3, "KNIGHT")
	h.talent_points = 3
	h.allocate_talent("OFFENSE")
	h.allocate_talent("LEADERSHIP")
	# OFFENSE 1 = 1.02, LEADERSHIP 1 = 1.01 -> Atk mult = 1.02 * 1.01 = 1.0302
	var mult: float = h.get_talent_atk_multiplier()
	var ok: bool = (absf(mult - 1.0302) < 0.0001)
	return ok


func _test_f8_skills_and_talents_preserved_through_clone_and_snapshot() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.level = 3
	alder.talent_points = 2
	coord.unlock_hero_skill("hero_alder", "knight_offense")
	coord.allocate_hero_talent("hero_alder", "OFFENSE")
	var snap := coord.get_current_state()
	var snap_skills: Array = []
	var snap_talents: Dictionary = {}
	for hd in snap.heroes_data:
		if hd.get("hero_id", "") == "hero_alder":
			snap_skills = hd.get("unlocked_skills", [])
			snap_talents = hd.get("allocated_talents", {})
			break
	var ok: bool = ("knight_offense" in snap_skills and snap_talents.get("OFFENSE", 0) == 1)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP G: EQUIPMENT & WAREHOUSE CONSERVATION INTEGRATION TESTS (57-66)
# ==============================================================================

func _test_g1_shared_warehouse_conservation_equation_invariant() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var total_initial: int = coord.get_warehouse_total_stock("SWORD")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	var total_after_equip: int = coord.get_warehouse_usable_stock("SWORD") + coord.get_warehouse_damaged_stock("SWORD") + 1
	var ok: bool = (total_initial == total_after_equip)
	_cleanup_session(s)
	return ok


func _test_g2_hero_equipment_compatible_role_slots_only() -> bool:
	var knight := HeroModel.new("h_k", "Knight", 1, 3, "KNIGHT")
	var archer := HeroModel.new("h_a", "Archer", 1, 3, "ARCHER")
	var mage := HeroModel.new("h_m", "Mage", 1, 3, "MAGE")
	var ok: bool = knight.is_equipment_compatible("PRIMARY", "SWORD") and not knight.is_equipment_compatible("PRIMARY", "BOW")
	ok = ok and (archer.is_equipment_compatible("PRIMARY", "BOW") and not archer.is_equipment_compatible("PRIMARY", "SWORD"))
	ok = ok and (not mage.is_equipment_compatible("PRIMARY", "SWORD") and not mage.is_equipment_compatible("ARMOR", "HEAVY_ARMOR"))
	return ok


func _test_g3_equipping_hero_decrements_warehouse_stock_by_one() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var init_stock: int = coord.get_warehouse_stock("SWORD")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	var final_stock: int = coord.get_warehouse_stock("SWORD")
	var ok: bool = (final_stock == init_stock - 1)
	_cleanup_session(s)
	return ok


func _test_g4_unequipping_hero_increments_warehouse_stock_by_one() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var init_stock: int = coord.get_warehouse_stock("SWORD")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.unequip_hero("hero_alder", "PRIMARY")
	var final_stock: int = coord.get_warehouse_stock("SWORD")
	var ok: bool = (final_stock == init_stock)
	_cleanup_session(s)
	return ok


func _test_g5_surviving_battle_preserves_hero_equipped_items() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(50)
	coord.proceed_from_result()
	var alder := coord.get_hero("hero_alder")
	var ok: bool = (alder.is_alive and alder.has_equipment("PRIMARY"))
	_cleanup_session(s)
	return ok


func _test_g6_permadeath_returns_all_hero_equipment_to_warehouse_exactly_once() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var init_sword: int = coord.get_warehouse_stock("SWORD")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	var alder := coord.get_hero("hero_alder")
	alder.mark_dead()
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(51)
	coord.proceed_from_result() # cleans dead hero equipment
	var final_sword: int = coord.get_warehouse_stock("SWORD")
	var ok: bool = (final_sword == init_sword)
	_cleanup_session(s)
	return ok


func _test_g7_repeated_recovery_does_not_double_return_dead_hero_equipment() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var init_sword: int = coord.get_warehouse_stock("SWORD")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	var alder := coord.get_hero("hero_alder")
	alder.mark_dead()
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(52)
	coord.proceed_from_result() # 1st recovery
	var sword_after_rec1: int = coord.get_warehouse_stock("SWORD")
	# Execute Wave 2 and recovery
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(53)
	coord.proceed_from_result() # 2nd recovery
	var sword_after_rec2: int = coord.get_warehouse_stock("SWORD")
	var ok: bool = (sword_after_rec1 == init_sword and sword_after_rec2 == init_sword)
	_cleanup_session(s)
	return ok


func _test_g8_party_assignment_does_not_affect_hero_equipment() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.assign_hero_to_party("hero_alder", "party_1")
	var has_in_p1: bool = coord.get_hero("hero_alder").has_equipment("PRIMARY")
	coord.remove_hero_from_party("hero_alder")
	var has_in_res: bool = coord.get_hero("hero_alder").has_equipment("PRIMARY")
	coord.assign_hero_to_party("hero_alder", "party_2")
	var has_in_p2: bool = coord.get_hero("hero_alder").has_equipment("PRIMARY")
	var ok: bool = (has_in_p1 and has_in_res and has_in_p2)
	_cleanup_session(s)
	return ok


func _test_g9_dismiss_hero_returns_all_equipment_to_warehouse() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var init_sword: int = coord.get_warehouse_stock("SWORD")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.dismiss_hero("hero_alder")
	var final_sword: int = coord.get_warehouse_stock("SWORD")
	var ok: bool = (final_sword == init_sword)
	_cleanup_session(s)
	return ok


func _test_g10_equipment_swap_preserves_total_conservation() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var init_swords: int = coord.get_warehouse_stock("SWORD")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.unequip_hero("hero_alder", "PRIMARY")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	var final_swords: int = coord.get_warehouse_stock("SWORD")
	var ok: bool = (final_swords == init_swords - 1)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP H: RECRUITMENT & ASCENSION INTEGRATION TESTS (67-72)
# ==============================================================================

func _test_h1_recruitment_cost_fixed_at_500_gold_no_override() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.set_treasury_gold(1000)
	coord.recruit_hero("KNIGHT")
	var ok: bool = (coord.get_treasury_gold() == 500)
	_cleanup_session(s)
	return ok


func _test_h2_recruitment_rejected_when_treasury_under_500_gold() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.set_treasury_gold(499)
	var hero := coord.recruit_hero("KNIGHT")
	var ok: bool = (hero == null and coord.get_treasury_gold() == 499)
	_cleanup_session(s)
	return ok


func _test_h3_new_recruit_has_empty_equipment_and_starts_in_reserve() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.set_treasury_gold(1000)
	var hero := coord.recruit_hero("ARCHER")
	var ok: bool = (hero.primary_equipment == null and hero.secondary_equipment == null and hero.armor_equipment == null)
	ok = ok and (hero.party_id == "" and hero.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE)
	_cleanup_session(s)
	return ok


func _test_h4_ascension_cost_formula_current_star_times_150_gold() -> bool:
	var h1 := HeroModel.new("h1", "H1", 1, 4)
	var h2 := HeroModel.new("h2", "H2", 2, 4)
	var h3 := HeroModel.new("h3", "H3", 3, 4)
	var h4 := HeroModel.new("h4", "H4", 4, 5)
	var ok: bool = (h1.get_ascension_cost() == 150)
	ok = ok and (h2.get_ascension_cost() == 300)
	ok = ok and (h3.get_ascension_cost() == 450)
	ok = ok and (h4.get_ascension_cost() == 600)
	return ok


func _test_h5_ascension_requires_level_cap_and_gold_and_potential() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.level = 9
	coord.set_treasury_gold(500)
	var fail_underlevel: bool = coord.ascend_hero("hero_alder")
	alder.level = 10
	coord.set_treasury_gold(100) # cost is 150
	var fail_gold: bool = coord.ascend_hero("hero_alder")
	coord.set_treasury_gold(500)
	var ok_asc: bool = coord.ascend_hero("hero_alder")
	var ok: bool = (not fail_underlevel and not fail_gold and ok_asc)
	ok = ok and (alder.current_star == 2)
	_cleanup_session(s)
	return ok


func _test_h6_ascension_preserves_all_hero_progression_attributes() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.level = 10
	alder.current_exp = 250
	alder.fatigue = 30
	alder.morale = 110
	alder.add_chemistry("hero_lyra", 10)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.unlock_hero_skill("hero_alder", "knight_offense")
	alder.talent_points = 2
	coord.allocate_hero_talent("hero_alder", "OFFENSE")
	coord.set_treasury_gold(500)
	var ok_asc: bool = coord.ascend_hero("hero_alder")
	var ok: bool = ok_asc and (alder.current_star == 2)
	ok = ok and (alder.level == 10 and alder.current_exp == 250)
	ok = ok and (alder.fatigue == 30 and alder.morale == 110)
	ok = ok and (alder.chemistry_map.get("hero_lyra", 0) == 10)
	ok = ok and (alder.party_id == "party_1")
	ok = ok and (alder.has_equipment("PRIMARY"))
	ok = ok and ("knight_offense" in alder.unlocked_skills)
	ok = ok and (alder.allocated_talents.get("OFFENSE", 0) == 1)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP I: SNAPSHOT, CLONE & STATE ISOLATION TESTS (73-76)
# ==============================================================================

func _test_i1_hero_model_clone_complete_state_isolation() -> bool:
	var h1 := HeroModel.new("h1", "Original", 1, 4, "KNIGHT")
	h1.add_chemistry("partner", 10)
	h1.unlocked_skills.append("knight_offense")
	h1.allocated_talents["OFFENSE"] = 1
	var h2 := h1.clone()
	h2.add_chemistry("partner", 20)
	h2.unlocked_skills.append("knight_defense")
	h2.allocated_talents["OFFENSE"] = 3
	h2.level = 5
	var ok: bool = (h1.chemistry_map["partner"] == 10 and h2.chemistry_map["partner"] == 30)
	ok = ok and (h1.unlocked_skills.size() == 1 and h2.unlocked_skills.size() == 2)
	ok = ok and (h1.allocated_talents["OFFENSE"] == 1 and h2.allocated_talents["OFFENSE"] == 3)
	ok = ok and (h1.level == 1 and h2.level == 5)
	return ok


func _test_i2_party_model_clone_complete_state_isolation() -> bool:
	var p1 := PartyModel.new("party_1", "Party 1", true)
	p1.add_member("hero_a")
	var p2 := p1.clone()
	p2.add_member("hero_b")
	var ok: bool = (p1.get_member_count() == 1 and p2.get_member_count() == 2)
	return ok


func _test_i3_snapshot_clone_complete_state_isolation() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var snap1 := coord.get_current_state()
	var snap2 := snap1.clone()
	snap2.economy_data["treasury_gold"] = 9999
	var ok: bool = (int(snap1.economy_data.get("treasury_gold", 0)) != 9999)
	_cleanup_session(s)
	return ok


func _test_i4_coordinator_mutation_synchronizes_snapshot_and_triggers_ui_reactively() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.set_treasury_gold(888)
	var snap := coord.get_current_state()
	var ok: bool = (int(snap.economy_data.get("treasury_gold", 0)) == 888)
	ok = ok and ("888 Gold" in view._lbl_treasury.text)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP J: PERMADEATH FULL LIFECYCLE INTEGRATION TESTS (77-80)
# ==============================================================================

func _test_j1_permadeath_hero_removed_from_party_and_cleared_from_leader() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.set_party_leader("hero_alder", "party_1")
	coord.get_hero("hero_alder").mark_dead()
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(70)
	coord.proceed_from_result()
	var p1 := coord.get_party("party_1")
	var ok: bool = (not p1.has_member("hero_alder"))
	ok = ok and (p1.leader_hero_id == "")
	_cleanup_session(s)
	return ok


func _test_j2_permadeath_cleans_chemistry_references_symmetrically() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(71)
	coord.proceed_from_result() # alder & lyra have chemistry 2
	coord.get_hero("hero_alder").mark_dead()
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(72)
	coord.proceed_from_result() # cleanup
	var alder := coord.get_hero("hero_alder")
	var lyra := coord.get_hero("hero_lyra")
	var ok: bool = (alder.chemistry_map.is_empty())
	ok = ok and (not lyra.chemistry_map.has("hero_alder"))
	_cleanup_session(s)
	return ok


func _test_j3_permadeath_hero_blocked_from_all_roster_actions() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.mark_dead()
	var t_fail: bool = coord.can_train_hero("hero_alder")
	var r_fail: bool = coord.can_rest_hero("hero_alder")
	var a_fail: bool = coord.can_ascend_hero("hero_alder")
	var s_fail: bool = coord.can_unlock_hero_skill("hero_alder", "knight_offense")
	var tal_fail: bool = coord.can_allocate_hero_talent("hero_alder", "OFFENSE")
	var eq_fail: bool = coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	var ok: bool = (not t_fail and not r_fail and not a_fail and not s_fail and not tal_fail and not eq_fail)
	_cleanup_session(s)
	return ok


func _test_j4_permadeath_is_permanent_cannot_be_revived_or_reassigned() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var alder := coord.get_hero("hero_alder")
	alder.mark_dead()
	var fail_p1: bool = coord.assign_hero_to_party("hero_alder", "party_1")
	var fail_p2: bool = coord.assign_hero_to_party("hero_alder", "party_2")
	var ok: bool = (not fail_p1 and not fail_p2)
	var in_battle: bool = coord.get_active_battle_hero_ids().has("hero_alder")
	ok = ok and (not in_battle)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP K: DETERMINISTIC 50-WAVE MULTI-SYSTEM STRESS SIMULATION (81)
# ==============================================================================

func _test_k1_deterministic_50_wave_multi_system_stress_simulation() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]

	# Persiapan Roster: 6 Pahlawan (3 di Party 1, 2 di Party 2, 1 di Reserve)
	coord.set_treasury_gold(50000)
	var h_gale := coord.recruit_hero("MAGE")
	var h_mira := coord.recruit_hero("PRIEST")
	var h_bran := coord.recruit_hero("KNIGHT")
	var h_sela := coord.recruit_hero("ARCHER")

	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party(h_gale.hero_id, "party_1")

	coord.assign_hero_to_party(h_mira.hero_id, "party_2")
	coord.assign_hero_to_party(h_bran.hero_id, "party_2")
	# h_sela is in Reserve

	var initial_total_swords: int = coord.get_warehouse_total_stock("SWORD")

	# Beri perlengkapan awal
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.equip_hero("hero_alder", "SECONDARY", "SHIELD")
	coord.equip_hero("hero_alder", "ARMOR", "HEAVY_ARMOR")
	coord.equip_hero("hero_lyra", "PRIMARY", "BOW")

	# Simulasikan 50 Gelombang Pertempuran
	for wave in range(1, 51):
		# 1. Pastikan invarian party capacity & isolasi Party 2/Reserve
		var p1 := coord.get_party("party_1")
		var p2 := coord.get_party("party_2")
		if p1.get_member_count() > 3 or p2.get_member_count() > 3:
			printerr("Stress Failure Wave %d: Party capacity exceeded" % wave)
			_cleanup_session(s)
			return false

		# 2. Latihan dan Istirahat jika memungkinkan
		var active_ids := coord.get_active_battle_hero_ids()
		for hid in active_ids:
			var h := coord.get_hero(hid)
			if h != null and h.is_alive:
				if h.fatigue >= 50:
					coord.rest_hero(hid)
				elif coord.can_train_hero(hid):
					coord.train_hero(hid)

		# 3. Alokasi Bakat & Pembukaan Skill jika eligible
		for hid in active_ids:
			var h := coord.get_hero(hid)
			if h != null and h.is_alive:
				if h.talent_points > 0:
					coord.allocate_hero_talent(hid, "OFFENSE")
				if h.role == "KNIGHT" and h.level >= 3 and not ("knight_offense" in h.unlocked_skills):
					coord.unlock_hero_skill(hid, "knight_offense")

		# 4. Ascension jika mencapai level cap
		for hid in active_ids:
			var h := coord.get_hero(hid)
			if h != null and h.is_alive and coord.can_ascend_hero(hid):
				coord.ascend_hero(hid)

		# 5. Pasang benteng tangguh agar tidak runtuh selama stress test
		coord._fortress.max_hp = 100000
		coord._fortress.current_hp = 100000
		coord._fortress.armor = 5000

		# Skenario Kematian Terkendali pada Wave 25 (Gale gugur untuk verifikasi permadeath)
		if wave == 25 and coord.get_hero(h_gale.hero_id).is_alive:
			coord.get_hero(h_gale.hero_id).mark_dead()

		# 6. Alur Tempur Siklus Gelombang
		if not coord.inspect_wave():
			printerr("Stress Failure Wave %d: inspect_wave failed" % wave)
			_cleanup_session(s)
			return false

		if not coord.start_battle():
			printerr("Stress Failure Wave %d: start_battle failed" % wave)
			_cleanup_session(s)
			return false

		# Verifikasi Party 2 dan Reserve tidak berada di battle_heroes
		var battle_heroes := coord.get_active_battle_heroes()
		for bh in battle_heroes:
			var bh_obj: HeroModel = bh as HeroModel
			if bh_obj.party_id != "party_1":
				printerr("Stress Failure Wave %d: Non-Party-1 hero in battle" % wave)
				_cleanup_session(s)
				return false

		var res := coord.execute_battle(777 + wave)
		if res.is_empty():
			printerr("Stress Failure Wave %d: execute_battle failed" % wave)
			_cleanup_session(s)
			return false

		if not coord.proceed_from_result():
			printerr("Stress Failure Wave %d: proceed_from_result failed" % wave)
			_cleanup_session(s)
			return false

		# 7. Verifikasi Chemistry tidak melampaui cap 50
		for bh in battle_heroes:
			var bh_obj: HeroModel = bh as HeroModel
			for partner_id in bh_obj.chemistry_map:
				var pts: int = int(bh_obj.chemistry_map[partner_id])
				if pts > 50 or pts < 0:
					printerr("Stress Failure Wave %d: Chemistry out of bounds: %d" % [wave, pts])
					_cleanup_session(s)
					return false

		# 8. Skenario Pasca-Kematian pada Wave 25 (Verifikasi pembersihan permadeath & rotasi cadangan)
		if wave == 25:
			# Gale harus sudah bersih dari party_1
			if p1.has_member(h_gale.hero_id):
				printerr("Stress Failure: Dead hero remained in Party 1")
				_cleanup_session(s)
				return false
			# Tugaskan cadangan (Sela) masuk ke Party 1 menggantikan Gale
			coord.assign_hero_to_party(h_sela.hero_id, "party_1")

		# 9. Verifikasi Konservasi Gudang Bersama (SWORD)
		var current_total_swords: int = coord.get_warehouse_usable_stock("SWORD") + coord.get_warehouse_damaged_stock("SWORD")
		if coord.get_hero("hero_alder").is_alive and coord.get_hero("hero_alder").has_equipment("PRIMARY"):
			current_total_swords += 1
		for comp in coord.get_active_deployments():
			if comp is DeploymentComposition:
				for eq in (comp as DeploymentComposition).reserved_equipment:
					if eq is EquipmentModel and (eq as EquipmentModel).role_type == "SWORD":
						current_total_swords += (eq as EquipmentModel).quantity
		if current_total_swords != initial_total_swords:
			printerr("Stress Failure Wave %d: Equipment conservation violated (%d vs %d)" % [wave, current_total_swords, initial_total_swords])
			_cleanup_session(s)
			return false

	_cleanup_session(s)
	return true
