extends SceneTree

## TestPhase4FHeroChemistryParty
## Test suite otomatis untuk memvalidasi implementasi Phase 4F:
## Hero Chemistry & Party Management.
## Memvalidasi domain PartyModel, keanggotaan pahlawan (maks 2 regu, maks 3 hero),
## sinkronisasi lifecycle state, aturan Party 1 sebagai active battle party tunggal,
## Party 2 sebagai reserve management, kepemilikan chemistry pada HeroModel,
## perolehan chemistry deterministik (+2 per pasangan bertarung bersama, cap 50),
## pembersihan permadeath secara atomik, penegakan Battle Lock,
## dan simulasi stres multi-wave deterministik.

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const PartyModel = preload("res://scripts/domain/model/party_model.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const CombatEngine = preload("res://scripts/simulation/combat_engine.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 4F HERO CHEMISTRY & PARTY MANAGEMENT TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# Group A: PartyModel Tests (1-12)
		{"name": "test_party_model_creation_defaults", "fn": Callable(self, "_test_party_model_creation_defaults")},
		{"name": "test_party_model_valid_ids", "fn": Callable(self, "_test_party_model_valid_ids")},
		{"name": "test_party_model_invalid_ids", "fn": Callable(self, "_test_party_model_invalid_ids")},
		{"name": "test_party_model_empty_party_has_zero_members", "fn": Callable(self, "_test_party_model_empty_party_has_zero_members")},
		{"name": "test_party_model_add_member_succeeds", "fn": Callable(self, "_test_party_model_add_member_succeeds")},
		{"name": "test_party_model_add_duplicate_member_fails", "fn": Callable(self, "_test_party_model_add_duplicate_member_fails")},
		{"name": "test_party_model_max_3_members_enforced", "fn": Callable(self, "_test_party_model_max_3_members_enforced")},
		{"name": "test_party_model_remove_member_succeeds", "fn": Callable(self, "_test_party_model_remove_member_succeeds")},
		{"name": "test_party_model_set_leader_succeeds_for_member", "fn": Callable(self, "_test_party_model_set_leader_succeeds_for_member")},
		{"name": "test_party_model_set_leader_fails_for_non_member", "fn": Callable(self, "_test_party_model_set_leader_fails_for_non_member")},
		{"name": "test_party_model_remove_leader_clears_leader_id", "fn": Callable(self, "_test_party_model_remove_leader_clears_leader_id")},
		{"name": "test_party_model_clone_and_invariants", "fn": Callable(self, "_test_party_model_clone_and_invariants")},

		# Group B: Hero Party Membership Tests (13-24)
		{"name": "test_hero_default_party_id_is_empty_reserve", "fn": Callable(self, "_test_hero_default_party_id_is_empty_reserve")},
		{"name": "test_hero_set_party_id_valid", "fn": Callable(self, "_test_hero_set_party_id_valid")},
		{"name": "test_hero_set_party_id_invalid_fails", "fn": Callable(self, "_test_hero_set_party_id_invalid_fails")},
		{"name": "test_hero_is_in_party_with_target_filter", "fn": Callable(self, "_test_hero_is_in_party_with_target_filter")},
		{"name": "test_hero_clear_party_assignment", "fn": Callable(self, "_test_hero_clear_party_assignment")},
		{"name": "test_dead_or_permadeath_hero_cannot_have_party", "fn": Callable(self, "_test_dead_or_permadeath_hero_cannot_have_party")},
		{"name": "test_hero_mark_dead_clears_party_id", "fn": Callable(self, "_test_hero_mark_dead_clears_party_id")},
		{"name": "test_hero_clone_preserves_party_id", "fn": Callable(self, "_test_hero_clone_preserves_party_id")},
		{"name": "test_hero_invariants_validates_party_id", "fn": Callable(self, "_test_hero_invariants_validates_party_id")},
		{"name": "test_hero_invariants_sync_with_lifecycle_state", "fn": Callable(self, "_test_hero_invariants_sync_with_lifecycle_state")},
		{"name": "test_dead_hero_with_non_empty_party_fails_invariants", "fn": Callable(self, "_test_dead_hero_with_non_empty_party_fails_invariants")},
		{"name": "test_hero_membership_lifecycle_transition_flow", "fn": Callable(self, "_test_hero_membership_lifecycle_transition_flow")},

		# Group C: Coordinator Party Management Tests (25-38)
		{"name": "test_coordinator_initializes_exactly_two_parties", "fn": Callable(self, "_test_coordinator_initializes_exactly_two_parties")},
		{"name": "test_coordinator_party_1_is_default_active_battle_party", "fn": Callable(self, "_test_coordinator_party_1_is_default_active_battle_party")},
		{"name": "test_coordinator_party_2_is_non_active", "fn": Callable(self, "_test_coordinator_party_2_is_non_active")},
		{"name": "test_coordinator_assign_hero_to_party_succeeds", "fn": Callable(self, "_test_coordinator_assign_hero_to_party_succeeds")},
		{"name": "test_coordinator_assign_hero_already_in_party_fails", "fn": Callable(self, "_test_coordinator_assign_hero_already_in_party_fails")},
		{"name": "test_coordinator_cannot_assign_hero_when_party_full", "fn": Callable(self, "_test_coordinator_cannot_assign_hero_when_party_full")},
		{"name": "test_coordinator_cannot_assign_dead_hero", "fn": Callable(self, "_test_coordinator_cannot_assign_dead_hero")},
		{"name": "test_coordinator_remove_hero_from_party_succeeds", "fn": Callable(self, "_test_coordinator_remove_hero_from_party_succeeds")},
		{"name": "test_coordinator_set_party_leader_succeeds", "fn": Callable(self, "_test_coordinator_set_party_leader_succeeds")},
		{"name": "test_coordinator_set_leader_fails_if_hero_not_in_party", "fn": Callable(self, "_test_coordinator_set_leader_fails_if_hero_not_in_party")},
		{"name": "test_coordinator_battle_lock_blocks_party_assignment", "fn": Callable(self, "_test_coordinator_battle_lock_blocks_party_assignment")},
		{"name": "test_coordinator_battle_lock_blocks_party_removal", "fn": Callable(self, "_test_coordinator_battle_lock_blocks_party_removal")},
		{"name": "test_coordinator_battle_lock_blocks_setting_leader", "fn": Callable(self, "_test_coordinator_battle_lock_blocks_setting_leader")},
		{"name": "test_coordinator_dismiss_hero_in_party_is_rejected", "fn": Callable(self, "_test_coordinator_dismiss_hero_in_party_is_rejected")},

		# Group D: Chemistry Progression & Rules Tests (39-50)
		{"name": "test_chemistry_starts_at_zero", "fn": Callable(self, "_test_chemistry_starts_at_zero")},
		{"name": "test_no_chemistry_gain_without_battle", "fn": Callable(self, "_test_no_chemistry_gain_without_battle")},
		{"name": "test_two_heroes_in_party_1_gain_exact_plus_2_after_battle", "fn": Callable(self, "_test_two_heroes_in_party_1_gain_exact_plus_2_after_battle")},
		{"name": "test_chemistry_gain_is_strictly_symmetric", "fn": Callable(self, "_test_chemistry_gain_is_strictly_symmetric")},
		{"name": "test_three_heroes_produce_exact_three_pairs", "fn": Callable(self, "_test_three_heroes_produce_exact_three_pairs")},
		{"name": "test_single_hero_in_party_gains_no_chemistry", "fn": Callable(self, "_test_single_hero_in_party_gains_no_chemistry")},
		{"name": "test_reserve_heroes_gain_no_chemistry_from_battle", "fn": Callable(self, "_test_reserve_heroes_gain_no_chemistry_from_battle")},
		{"name": "test_party_2_heroes_gain_no_chemistry_from_battle", "fn": Callable(self, "_test_party_2_heroes_gain_no_chemistry_from_battle")},
		{"name": "test_chemistry_accumulates_across_multiple_battles", "fn": Callable(self, "_test_chemistry_accumulates_across_multiple_battles")},
		{"name": "test_chemistry_capped_at_exactly_50", "fn": Callable(self, "_test_chemistry_capped_at_exactly_50")},
		{"name": "test_no_self_chemistry_allowed", "fn": Callable(self, "_test_no_self_chemistry_allowed")},
		{"name": "test_chemistry_persists_when_hero_leaves_party", "fn": Callable(self, "_test_chemistry_persists_when_hero_leaves_party")},

		# Group E: Combat Integration & Party 1 vs Party 2 Tests (51-60)
		{"name": "test_only_party_1_contributes_to_battle_attack", "fn": Callable(self, "_test_only_party_1_contributes_to_battle_attack")},
		{"name": "test_reserve_heroes_do_not_contribute_to_battle_attack", "fn": Callable(self, "_test_reserve_heroes_do_not_contribute_to_battle_attack")},
		{"name": "test_empty_party_1_battle_does_not_crash", "fn": Callable(self, "_test_empty_party_1_battle_does_not_crash")},
		{"name": "test_only_active_party_1_heroes_receive_battle_fatigue", "fn": Callable(self, "_test_only_active_party_1_heroes_receive_battle_fatigue")},
		{"name": "test_only_active_party_1_surviving_heroes_receive_battle_exp", "fn": Callable(self, "_test_only_active_party_1_surviving_heroes_receive_battle_exp")},
		{"name": "test_party_hero_ids_passed_correctly_to_effective_atk", "fn": Callable(self, "_test_party_hero_ids_passed_correctly_to_effective_atk")},
		{"name": "test_dead_heroes_in_party_1_do_not_contribute_to_attack", "fn": Callable(self, "_test_dead_heroes_in_party_1_do_not_contribute_to_attack")},
		{"name": "test_no_double_chemistry_increment", "fn": Callable(self, "_test_no_double_chemistry_increment")},
		{"name": "test_party_1_heroes_transition_to_battle_active_during_battle", "fn": Callable(self, "_test_party_1_heroes_transition_to_battle_active_during_battle")},
		{"name": "test_party_1_survivors_return_to_in_party_state_after_proceed", "fn": Callable(self, "_test_party_1_survivors_return_to_in_party_state_after_proceed")},

		# Group F: Permadeath, Cleanup & Multi-Wave Stress Tests (61-66)
		{"name": "test_permadeath_hero_removed_from_party", "fn": Callable(self, "_test_permadeath_hero_removed_from_party")},
		{"name": "test_permadeath_leader_clears_party_leader_id", "fn": Callable(self, "_test_permadeath_leader_clears_party_leader_id")},
		{"name": "test_permadeath_cleans_chemistry_references_symmetrically", "fn": Callable(self, "_test_permadeath_cleans_chemistry_references_symmetrically")},
		{"name": "test_permadeath_returns_equipment_to_shared_warehouse", "fn": Callable(self, "_test_permadeath_returns_equipment_to_shared_warehouse")},
		{"name": "test_snapshot_telemetry_includes_party_id_and_parties_data", "fn": Callable(self, "_test_snapshot_telemetry_includes_party_id_and_parties_data")},
		{"name": "test_20_wave_party_chemistry_stress_simulation", "fn": Callable(self, "_test_20_wave_party_chemistry_stress_simulation")},

		# Group G: Phase 4F Correction Gate Tests (67-68)
		{"name": "test_assign_party_uses_canonical_hero_party_assignment", "fn": Callable(self, "_test_assign_party_uses_canonical_hero_party_assignment")},
		{"name": "test_assign_party_rolls_back_atomically_when_mutation_fails", "fn": Callable(self, "_test_assign_party_rolls_back_atomically_when_mutation_fails")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 4F TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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
# GROUP A: PARTYMODEL TESTS (1-12)
# ==============================================================================

func _test_party_model_creation_defaults() -> bool:
	var p := PartyModel.new("party_1", "Party 1", true)
	return p.party_id == "party_1" and p.party_name == "Party 1" and p.is_deployed_to_battle and p.leader_hero_id.is_empty() and p.member_hero_ids.is_empty()


func _test_party_model_valid_ids() -> bool:
	return PartyModel.is_valid_party_id("party_1") and PartyModel.is_valid_party_id("party_2") and PartyModel.is_valid_party_id("PARTY_1")


func _test_party_model_invalid_ids() -> bool:
	return not PartyModel.is_valid_party_id("party_3") and not PartyModel.is_valid_party_id("") and not PartyModel.is_valid_party_id("invalid")


func _test_party_model_empty_party_has_zero_members() -> bool:
	var p := PartyModel.new("party_1", "Party 1")
	return p.get_member_count() == 0 and not p.is_full() and p.get_members().is_empty()


func _test_party_model_add_member_succeeds() -> bool:
	var p := PartyModel.new("party_1", "Party 1")
	var ok: bool = p.add_member("hero_1")
	return ok and p.get_member_count() == 1 and p.has_member("hero_1")


func _test_party_model_add_duplicate_member_fails() -> bool:
	var p := PartyModel.new("party_1", "Party 1")
	p.add_member("hero_1")
	var can_add: bool = p.can_add_member("hero_1")
	var add_ok: bool = p.add_member("hero_1")
	return not can_add and not add_ok and p.get_member_count() == 1


func _test_party_model_max_3_members_enforced() -> bool:
	var p := PartyModel.new("party_1", "Party 1")
	p.add_member("hero_1")
	p.add_member("hero_2")
	p.add_member("hero_3")
	var full: bool = p.is_full()
	var can_add_4th: bool = p.can_add_member("hero_4")
	var add_4th: bool = p.add_member("hero_4")
	return full and not can_add_4th and not add_4th and p.get_member_count() == 3


func _test_party_model_remove_member_succeeds() -> bool:
	var p := PartyModel.new("party_1", "Party 1")
	p.add_member("hero_1")
	p.add_member("hero_2")
	var ok: bool = p.remove_member("hero_1")
	return ok and p.get_member_count() == 1 and not p.has_member("hero_1") and p.has_member("hero_2")


func _test_party_model_set_leader_succeeds_for_member() -> bool:
	var p := PartyModel.new("party_1", "Party 1")
	p.add_member("hero_1")
	var ok: bool = p.set_leader("hero_1")
	return ok and p.leader_hero_id == "hero_1"


func _test_party_model_set_leader_fails_for_non_member() -> bool:
	var p := PartyModel.new("party_1", "Party 1")
	p.add_member("hero_1")
	var ok: bool = p.set_leader("hero_non_member")
	return not ok and p.leader_hero_id.is_empty()


func _test_party_model_remove_leader_clears_leader_id() -> bool:
	var p := PartyModel.new("party_1", "Party 1")
	p.add_member("hero_1")
	p.set_leader("hero_1")
	p.remove_member("hero_1")
	return p.leader_hero_id.is_empty() and p.get_member_count() == 0


func _test_party_model_clone_and_invariants() -> bool:
	var p := PartyModel.new("party_1", "Party 1", true)
	p.add_member("h1")
	p.add_member("h2")
	p.set_leader("h1")
	var valid: bool = p.validate_invariants()
	var c: PartyModel = p.clone()
	c.add_member("h3")
	return valid and c != null and c != p and c.get_member_count() == 3 and p.get_member_count() == 2 and c.leader_hero_id == "h1"


# ==============================================================================
# GROUP B: HERO PARTY MEMBERSHIP TESTS (13-24)
# ==============================================================================

func _test_hero_default_party_id_is_empty_reserve() -> bool:
	var hero := HeroModel.new("h_res", "Tester", 1, 3)
	return hero.party_id.is_empty() and not hero.is_in_party() and hero.get_party_id().is_empty()


func _test_hero_set_party_id_valid() -> bool:
	var hero := HeroModel.new("h_set_p", "Tester", 1, 3)
	var ok1: bool = hero.set_party_id("party_1")
	var p1_ok: bool = hero.party_id == "party_1"
	var ok2: bool = hero.set_party_id("party_2")
	var p2_ok: bool = hero.party_id == "party_2"
	return ok1 and p1_ok and ok2 and p2_ok


func _test_hero_set_party_id_invalid_fails() -> bool:
	var hero := HeroModel.new("h_bad_p", "Tester", 1, 3)
	var ok: bool = hero.set_party_id("party_3")
	return not ok and hero.party_id.is_empty()


func _test_hero_is_in_party_with_target_filter() -> bool:
	var hero := HeroModel.new("h_filter", "Tester", 1, 3)
	hero.set_party_id("party_1")
	return hero.is_in_party() and hero.is_in_party("party_1") and not hero.is_in_party("party_2")


func _test_hero_clear_party_assignment() -> bool:
	var hero := HeroModel.new("h_clr", "Tester", 1, 3)
	hero.set_party_id("party_1")
	hero.clear_party_assignment()
	return hero.party_id.is_empty() and not hero.is_in_party()


func _test_dead_or_permadeath_hero_cannot_have_party() -> bool:
	var hero := HeroModel.new("h_dead_p", "Tester", 1, 3)
	hero.mark_dead()
	var ok: bool = hero.set_party_id("party_1")
	return not ok and hero.party_id.is_empty()


func _test_hero_mark_dead_clears_party_id() -> bool:
	var hero := HeroModel.new("h_mk_dead", "Tester", 1, 3)
	hero.set_party_id("party_1")
	hero.mark_dead()
	return hero.party_id.is_empty() and not hero.is_alive and hero.lifecycle_state == HeroLifecycleState.PERMADEATH


func _test_hero_clone_preserves_party_id() -> bool:
	var hero := HeroModel.new("h_cln_p", "Tester", 1, 3)
	hero.set_party_id("party_2")
	hero.lifecycle_state = HeroLifecycleState.IN_PARTY
	var cl: HeroModel = hero.clone()
	return cl != null and cl.party_id == "party_2" and cl.is_in_party("party_2")


func _test_hero_invariants_validates_party_id() -> bool:
	var hero := HeroModel.new("h_inv_p", "Tester", 1, 3)
	hero.party_id = "invalid_party_xyz"
	return not hero.validate_invariants()


func _test_hero_invariants_sync_with_lifecycle_state() -> bool:
	var hero := HeroModel.new("h_sync_lc", "Tester", 1, 3)
	# party_id empty but lifecycle IN_PARTY -> invalid
	hero.party_id = ""
	hero.lifecycle_state = HeroLifecycleState.IN_PARTY
	var err1: bool = not hero.validate_invariants()
	# party_id set but lifecycle ROSTER_ACTIVE -> invalid
	hero.party_id = "party_1"
	hero.lifecycle_state = HeroLifecycleState.ROSTER_ACTIVE
	var err2: bool = not hero.validate_invariants()
	# party_id set and lifecycle IN_PARTY -> valid
	hero.lifecycle_state = HeroLifecycleState.IN_PARTY
	var ok: bool = hero.validate_invariants()
	return err1 and err2 and ok


func _test_dead_hero_with_non_empty_party_fails_invariants() -> bool:
	var hero := HeroModel.new("h_inv_dead_p", "Tester", 1, 3)
	hero.is_alive = false
	hero.lifecycle_state = HeroLifecycleState.PERMADEATH
	hero.party_id = "party_1"
	return not hero.validate_invariants()


func _test_hero_membership_lifecycle_transition_flow() -> bool:
	var hero := HeroModel.new("h_flow", "Tester", 1, 3)
	assert(hero.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE)
	var t1: bool = hero.transition_lifecycle_state(HeroLifecycleState.IN_PARTY)
	var t2: bool = hero.transition_lifecycle_state(HeroLifecycleState.ROSTER_ACTIVE)
	return t1 and t2 and hero.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE


# ==============================================================================
# GROUP C: COORDINATOR PARTY MANAGEMENT TESTS (25-38)
# ==============================================================================

func _test_coordinator_initializes_exactly_two_parties() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_1")
	var parties: Array = coord.get_parties()
	return parties.size() == 2 and coord.get_party("party_1") != null and coord.get_party("party_2") != null


func _test_coordinator_party_1_is_default_active_battle_party() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_2")
	var active_p: PartyModel = coord.get_active_battle_party()
	return active_p != null and active_p.party_id == "party_1" and active_p.is_deployed_to_battle


func _test_coordinator_party_2_is_non_active() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_3")
	var p2: PartyModel = coord.get_party("party_2")
	return p2 != null and p2.party_id == "party_2" and not p2.is_deployed_to_battle


func _test_coordinator_assign_hero_to_party_succeeds() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_4")
	var ok: bool = coord.assign_hero_to_party("hero_alder", "party_1")
	var alder: HeroModel = coord.get_hero("hero_alder")
	var p1: PartyModel = coord.get_party("party_1")
	return ok and alder.party_id == "party_1" and alder.lifecycle_state == HeroLifecycleState.IN_PARTY and p1.has_member("hero_alder")


func _test_coordinator_assign_hero_already_in_party_fails() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_5")
	coord.assign_hero_to_party("hero_alder", "party_1")
	var can_cross: bool = coord.can_assign_hero_to_party("hero_alder", "party_2")
	var cross_ok: bool = coord.assign_hero_to_party("hero_alder", "party_2")
	var alder: HeroModel = coord.get_hero("hero_alder")
	return not can_cross and not cross_ok and alder.party_id == "party_1"


func _test_coordinator_cannot_assign_hero_when_party_full() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_6")
	# Add 2 more heroes to reach 4 heroes total in roster
	var h3 := HeroModel.new("hero_gale", "Gale", 1, 3, HeroRole.MAGE, HeroLifecycleState.ROSTER_ACTIVE)
	var h4 := HeroModel.new("hero_mira", "Mira", 1, 3, HeroRole.PRIEST, HeroLifecycleState.ROSTER_ACTIVE)
	coord.add_hero(h3)
	coord.add_hero(h4)

	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party("hero_gale", "party_1")
	# 4th hero assignment must fail
	var can_add_4th: bool = coord.can_assign_hero_to_party("hero_mira", "party_1")
	var add_4th: bool = coord.assign_hero_to_party("hero_mira", "party_1")
	var p1: PartyModel = coord.get_party("party_1")
	return p1.is_full() and not can_add_4th and not add_4th and p1.get_member_count() == 3


func _test_coordinator_cannot_assign_dead_hero() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_7")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.mark_dead()
	var can_add: bool = coord.can_assign_hero_to_party("hero_alder", "party_1")
	var add_ok: bool = coord.assign_hero_to_party("hero_alder", "party_1")
	return not can_add and not add_ok and alder.party_id.is_empty()


func _test_coordinator_remove_hero_from_party_succeeds() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_8")
	coord.assign_hero_to_party("hero_alder", "party_1")
	var ok: bool = coord.remove_hero_from_party("hero_alder")
	var alder: HeroModel = coord.get_hero("hero_alder")
	var p1: PartyModel = coord.get_party("party_1")
	return ok and alder.party_id.is_empty() and alder.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE and not p1.has_member("hero_alder")


func _test_coordinator_set_party_leader_succeeds() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_9")
	coord.assign_hero_to_party("hero_alder", "party_1")
	var ok: bool = coord.set_party_leader("hero_alder", "party_1")
	var p1: PartyModel = coord.get_party("party_1")
	return ok and p1.leader_hero_id == "hero_alder"


func _test_coordinator_set_leader_fails_if_hero_not_in_party() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_10")
	# Alder is in RESERVE, not in party_1
	var can_lead: bool = coord.can_set_party_leader("hero_alder", "party_1")
	var lead_ok: bool = coord.set_party_leader("hero_alder", "party_1")
	var p1: PartyModel = coord.get_party("party_1")
	return not can_lead and not lead_ok and p1.leader_hero_id.is_empty()


func _test_coordinator_battle_lock_blocks_party_assignment() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_11")
	coord.inspect_wave()
	coord.start_battle()
	var can_assign: bool = coord.can_assign_hero_to_party("hero_alder", "party_1")
	var assign_ok: bool = coord.assign_hero_to_party("hero_alder", "party_1")
	var alder: HeroModel = coord.get_hero("hero_alder")
	return not can_assign and not assign_ok and alder.party_id.is_empty()


func _test_coordinator_battle_lock_blocks_party_removal() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_12")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	var can_rem: bool = coord.can_remove_hero_from_party("hero_alder")
	var rem_ok: bool = coord.remove_hero_from_party("hero_alder")
	var alder: HeroModel = coord.get_hero("hero_alder")
	return not can_rem and not rem_ok and alder.party_id == "party_1"


func _test_coordinator_battle_lock_blocks_setting_leader() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_13")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	var can_lead: bool = coord.can_set_party_leader("hero_alder", "party_1")
	var lead_ok: bool = coord.set_party_leader("hero_alder", "party_1")
	var p1: PartyModel = coord.get_party("party_1")
	return not can_lead and not lead_ok and p1.leader_hero_id.is_empty()


func _test_coordinator_dismiss_hero_in_party_is_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_coord_p_14")
	coord.assign_hero_to_party("hero_alder", "party_1")
	var ok: bool = coord.dismiss_hero("hero_alder")
	var alder: HeroModel = coord.get_hero("hero_alder")
	return not ok and alder != null and alder.party_id == "party_1"


# ==============================================================================
# GROUP D: CHEMISTRY PROGRESSION & RULES TESTS (39-50)
# ==============================================================================

func _test_chemistry_starts_at_zero() -> bool:
	var hero := HeroModel.new("h_chem_0", "Tester", 1, 3)
	return hero.chemistry_map.is_empty() and hero.get_chemistry_bonus(["other"]) == 1.0


func _test_no_chemistry_gain_without_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_chem_nobattle")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	return alder.chemistry_map.is_empty() and lyra.chemistry_map.is_empty()


func _test_two_heroes_in_party_1_gain_exact_plus_2_after_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_chem_2h")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	var chem_a_l: int = int(alder.chemistry_map.get("hero_lyra", 0))
	var chem_l_a: int = int(lyra.chemistry_map.get("hero_alder", 0))
	return chem_a_l == 2 and chem_l_a == 2


func _test_chemistry_gain_is_strictly_symmetric() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_chem_symm")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	return alder.chemistry_map["hero_lyra"] == lyra.chemistry_map["hero_alder"]


func _test_three_heroes_produce_exact_three_pairs() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_chem_3h")
	var h3 := HeroModel.new("hero_gale", "Gale", 1, 3, HeroRole.MAGE, HeroLifecycleState.ROSTER_ACTIVE)
	coord.add_hero(h3)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party("hero_gale", "party_1")

	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	var gale: HeroModel = coord.get_hero("hero_gale")

	var p_al: bool = alder.chemistry_map.get("hero_lyra", 0) == 2 and lyra.chemistry_map.get("hero_alder", 0) == 2
	var p_ag: bool = alder.chemistry_map.get("hero_gale", 0) == 2 and gale.chemistry_map.get("hero_alder", 0) == 2
	var p_lg: bool = lyra.chemistry_map.get("hero_gale", 0) == 2 and gale.chemistry_map.get("hero_lyra", 0) == 2
	return p_al and p_ag and p_lg and alder.chemistry_map.size() == 2 and lyra.chemistry_map.size() == 2 and gale.chemistry_map.size() == 2


func _test_single_hero_in_party_gains_no_chemistry() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_chem_solo")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var alder: HeroModel = coord.get_hero("hero_alder")
	return alder.chemistry_map.is_empty()


func _test_reserve_heroes_gain_no_chemistry_from_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_chem_reserve")
	# Only Alder is in party_1; Lyra remains in RESERVE
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	return not alder.chemistry_map.has("hero_lyra") and not lyra.chemistry_map.has("hero_alder")


func _test_party_2_heroes_gain_no_chemistry_from_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_chem_p2")
	# Alder in Party 1, Lyra in Party 2
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	return not alder.chemistry_map.has("hero_lyra") and not lyra.chemistry_map.has("hero_alder")


func _test_chemistry_accumulates_across_multiple_battles() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_chem_accum")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")

	for i in range(3):
		coord.inspect_wave()
		coord.start_battle()
		coord.execute_battle(42 + i)
		coord.proceed_from_result()

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	return alder.chemistry_map.get("hero_lyra", 0) == 6 and lyra.chemistry_map.get("hero_alder", 0) == 6


func _test_chemistry_capped_at_exactly_50() -> bool:
	var hero_a := HeroModel.new("h_a", "Hero A", 1, 3)
	var hero_b := HeroModel.new("h_b", "Hero B", 1, 3)
	hero_a.chemistry_map["h_b"] = 49
	hero_b.chemistry_map["h_a"] = 49

	hero_a.add_chemistry("h_b", 2)
	hero_b.add_chemistry("h_a", 2)
	var at_50: bool = hero_a.chemistry_map["h_b"] == 50 and hero_b.chemistry_map["h_a"] == 50

	hero_a.add_chemistry("h_b", 2)
	hero_b.add_chemistry("h_a", 2)
	var still_50: bool = hero_a.chemistry_map["h_b"] == 50 and hero_b.chemistry_map["h_a"] == 50
	return at_50 and still_50


func _test_no_self_chemistry_allowed() -> bool:
	var hero := HeroModel.new("h_self", "Tester", 1, 3)
	hero.add_chemistry("h_self", 10)
	return not hero.chemistry_map.has("h_self")


func _test_chemistry_persists_when_hero_leaves_party() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_chem_leave")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")

	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result() # Wave 1 -> Wave 2 (chem = 2)

	# Lyra leaves party_1
	coord.remove_hero_from_party("hero_lyra")
	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	var still_2_after_leave: bool = alder.chemistry_map.get("hero_lyra", 0) == 2 and lyra.chemistry_map.get("hero_alder", 0) == 2

	# Lyra re-joins party_1 and fights another battle
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(43)
	coord.proceed_from_result() # Wave 2 -> Wave 3 (chem = 4)

	return still_2_after_leave and alder.chemistry_map.get("hero_lyra", 0) == 4 and lyra.chemistry_map.get("hero_alder", 0) == 4


# ==============================================================================
# GROUP E: COMBAT INTEGRATION & PARTY 1 VS PARTY 2 TESTS (51-60)
# ==============================================================================

func _test_only_party_1_contributes_to_battle_attack() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_combat_p1_only")
	# Alder in Party 1, Lyra in Party 2
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")

	var active_heroes: Array = coord.get_active_battle_heroes()
	return active_heroes.size() == 1 and active_heroes[0].hero_id == "hero_alder"


func _test_reserve_heroes_do_not_contribute_to_battle_attack() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_combat_reserve_excluded")
	# Neither hero is assigned to party (both in RESERVE)
	var active_heroes: Array = coord.get_active_battle_heroes()
	return active_heroes.is_empty()


func _test_empty_party_1_battle_does_not_crash() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_combat_empty_p1")
	# No heroes in party_1
	coord.inspect_wave()
	coord.start_battle()
	var res: Dictionary = coord.execute_battle(42)
	var ok_proc: bool = coord.proceed_from_result()
	return not res.is_empty() and ok_proc and coord.get_current_state().current_wave == 2


func _test_only_active_party_1_heroes_receive_battle_fatigue() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_combat_fatigue")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")

	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	# Alder (Party 1) should receive +15 fatigue; Lyra (Party 2) should remain at 0
	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	return alder.fatigue == 15 and lyra.fatigue == 0


func _test_only_active_party_1_surviving_heroes_receive_battle_exp() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_combat_exp")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_2")

	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	return alder.current_exp > 0 and lyra.current_exp == 0


func _test_party_hero_ids_passed_correctly_to_effective_atk() -> bool:
	var hero_a := HeroModel.new("h_a", "Hero A", 1, 3)
	hero_a.morale = 50 # 1.00
	hero_a.fatigue = 0 # 1.00
	hero_a.chemistry_map["h_b"] = 20 # +10% bonus (0.005 * 20 = 0.10)
	# In party with h_b: bonus is 1.10 -> 35 * 1.10 = 38.5 -> floor = 38
	var atk_with_b: int = hero_a.get_effective_atk(["h_a", "h_b"])
	# In party without h_b: bonus is 1.00 -> 35
	var atk_without_b: int = hero_a.get_effective_atk(["h_a"])
	return atk_with_b == 38 and atk_without_b == 35


func _test_dead_heroes_in_party_1_do_not_contribute_to_attack() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_combat_dead_noatk")
	coord.assign_hero_to_party("hero_alder", "party_1")
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.mark_dead()
	var active_heroes: Array = coord.get_active_battle_heroes()
	return active_heroes.is_empty()


func _test_no_double_chemistry_increment() -> bool:
	# Audit validation: 1 battle between Alder & Lyra must produce EXACTLY 2 points each, never 4
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_chem_no_double")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")

	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	return alder.chemistry_map["hero_lyra"] == 2 and lyra.chemistry_map["hero_alder"] == 2


func _test_party_1_heroes_transition_to_battle_active_during_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_combat_ba_state")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()

	var alder: HeroModel = coord.get_hero("hero_alder")
	return alder.lifecycle_state == HeroLifecycleState.BATTLE_ACTIVE


func _test_party_1_survivors_return_to_in_party_state_after_proceed() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_combat_surv_return")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var alder: HeroModel = coord.get_hero("hero_alder")
	return alder.is_alive and alder.lifecycle_state == HeroLifecycleState.IN_PARTY and alder.party_id == "party_1"


# ==============================================================================
# GROUP F: PERMADEATH, CLEANUP & MULTI-WAVE STRESS TESTS (61-66)
# ==============================================================================

func _test_permadeath_hero_removed_from_party() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_perm_rem")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")

	# Alder dies in battle
	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.mark_dead()

	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var p1: PartyModel = coord.get_party("party_1")
	return not p1.has_member("hero_alder") and p1.has_member("hero_lyra") and alder.party_id.is_empty() and alder.lifecycle_state == HeroLifecycleState.PERMADEATH


func _test_permadeath_leader_clears_party_leader_id() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_perm_leader")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.set_party_leader("hero_alder", "party_1")
	assert(coord.get_party("party_1").leader_hero_id == "hero_alder")

	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.mark_dead()

	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var p1: PartyModel = coord.get_party("party_1")
	return p1.leader_hero_id.is_empty() and not p1.has_member("hero_alder")


func _test_permadeath_cleans_chemistry_references_symmetrically() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_perm_chem_clean")
	var h3 := HeroModel.new("hero_gale", "Gale", 1, 3, HeroRole.MAGE, HeroLifecycleState.ROSTER_ACTIVE)
	coord.add_hero(h3)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party("hero_gale", "party_1")

	# Wave 1: All 3 fight and gain chemistry with each other (2 pts each)
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	var gale: HeroModel = coord.get_hero("hero_gale")
	assert(alder.chemistry_map.has("hero_lyra") and alder.chemistry_map.has("hero_gale"))

	# Gale dies
	gale.mark_dead()
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(43)
	coord.proceed_from_result()

	var gale_wiped: bool = gale.chemistry_map.is_empty()
	var alder_cleared_gale: bool = not alder.chemistry_map.has("hero_gale")
	var lyra_cleared_gale: bool = not lyra.chemistry_map.has("hero_gale")
	var alder_lyra_intact: bool = alder.chemistry_map.has("hero_lyra") and lyra.chemistry_map.has("hero_alder")
	return gale_wiped and alder_cleared_gale and lyra_cleared_gale and alder_lyra_intact


func _test_permadeath_returns_equipment_to_shared_warehouse() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_perm_eq_ret")
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.assign_hero_to_party("hero_alder", "party_1")

	assert(coord.get_warehouse_stock("SWORD") == 9)

	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.mark_dead()

	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(42)
	coord.proceed_from_result()

	return coord.get_warehouse_stock("SWORD") == 10 and not alder.has_equipment("PRIMARY")


func _test_snapshot_telemetry_includes_party_id_and_parties_data() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_snap_party")
	coord.assign_hero_to_party("hero_alder", "party_1")

	var snap = coord.get_current_state()
	var alder_snap = snap.heroes_data[0]
	var has_pid: bool = alder_snap.has("party_id") and alder_snap["party_id"] == "party_1"
	var has_parties: bool = snap.parties_data.size() == 2 and snap.parties_data[0]["party_id"] == "party_1" and snap.parties_data[0]["member_count"] == 1
	return has_pid and has_parties


func _test_20_wave_party_chemistry_stress_simulation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_stress_20w")

	# Add 4 additional heroes to create a 6-hero roster
	var h3 := HeroModel.new("hero_gale", "Gale", 1, 4, HeroRole.MAGE, HeroLifecycleState.ROSTER_ACTIVE)
	var h4 := HeroModel.new("hero_mira", "Mira", 1, 4, HeroRole.PRIEST, HeroLifecycleState.ROSTER_ACTIVE)
	var h5 := HeroModel.new("hero_bran", "Bran", 1, 4, HeroRole.KNIGHT, HeroLifecycleState.ROSTER_ACTIVE)
	var h6 := HeroModel.new("hero_sela", "Sela", 1, 4, HeroRole.ARCHER, HeroLifecycleState.ROSTER_ACTIVE)
	coord.add_hero(h3)
	coord.add_hero(h4)
	coord.add_hero(h5)
	coord.add_hero(h6)

	# Assign Party 1 (Active Battle Party): Alder, Lyra, Gale
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party("hero_gale", "party_1")
	coord.set_party_leader("hero_alder", "party_1")

	# Assign Party 2 (Management Reserve): Mira, Bran, Sela
	coord.assign_hero_to_party("hero_mira", "party_2")
	coord.assign_hero_to_party("hero_bran", "party_2")
	coord.assign_hero_to_party("hero_sela", "party_2")
	coord.set_party_leader("hero_mira", "party_2")

	# Equip heroes
	coord.equip_hero("hero_alder", "PRIMARY", "SWORD")
	coord.equip_hero("hero_bran", "PRIMARY", "SWORD")

	var initial_total_swords: int = coord.get_total_owned_stock("SWORD")

	# Bolster fortress and soldier defense so threat is completely absorbed with zero breach danger
	coord._fortress.armor = 1000
	coord._fortress.max_hp = 5000
	coord._fortress.current_hp = 5000
	coord._population.soldiers["SWORDSMAN"] = 100
	coord._population.soldiers["ARCHER"] = 100
	coord._population.soldiers["SHIELD_INFANTRY"] = 50

	# Simulate 20 waves deterministically
	for wave in range(1, 21):
		# Keep heroes fresh and defense high so they survive naturally without casualty danger
		var a_pre: HeroModel = coord.get_hero("hero_alder")
		var l_pre: HeroModel = coord.get_hero("hero_lyra")
		var g_pre: HeroModel = coord.get_hero("hero_gale")
		a_pre.fatigue = 0
		l_pre.fatigue = 0
		g_pre.fatigue = 0
		a_pre.base_def = 500
		l_pre.base_def = 500
		g_pre.base_def = 500

		coord.inspect_wave()
		coord.start_battle()
		var res: Dictionary = coord.execute_battle(wave * 77)
		if res.is_empty():
			printerr("Stress wave %d execute_battle returned empty" % wave)
			return false

		# Ensure fortress survives for full 20 waves
		coord._fortress.current_hp = 1000

		var ok_proc: bool = coord.proceed_from_result()
		if not ok_proc:
			printerr("Stress wave %d proceed_from_result failed" % wave)
			return false

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	var gale: HeroModel = coord.get_hero("hero_gale")
	var mira: HeroModel = coord.get_hero("hero_mira")
	var bran: HeroModel = coord.get_hero("hero_bran")
	var sela: HeroModel = coord.get_hero("hero_sela")

	# Assertions:
	# 1. 20 waves * 2 pts = 40 pts chemistry between active battle heroes
	var chem_a_l: int = int(alder.chemistry_map.get("hero_lyra", 0))
	var chem_a_g: int = int(alder.chemistry_map.get("hero_gale", 0))
	var chem_l_g: int = int(lyra.chemistry_map.get("hero_gale", 0))
	if chem_a_l != 40 or chem_a_g != 40 or chem_l_g != 40:
		printerr("Expected 40 chemistry between Party 1 heroes, got %d, %d, %d" % [chem_a_l, chem_a_g, chem_a_g])
		return false

	# 2. Party 2 heroes have zero chemistry
	if not mira.chemistry_map.is_empty() or not bran.chemistry_map.is_empty() or not sela.chemistry_map.is_empty():
		printerr("Party 2 heroes must have zero chemistry")
		return false

	# 3. Party membership remains intact
	var p1: PartyModel = coord.get_party("party_1")
	var p2: PartyModel = coord.get_party("party_2")
	if p1.get_member_count() != 3 or p2.get_member_count() != 3:
		printerr("Party member counts corrupted")
		return false

	# 4. Total warehouse stock conservation
	if coord.get_total_owned_stock("SWORD") != initial_total_swords:
		printerr("Warehouse equipment conservation violated")
		return false

	# 5. Current wave is 21
	if coord.get_current_state().current_wave != 21:
		printerr("Expected current wave 21, got %d" % coord.get_current_state().current_wave)
		return false

	return true


# ==============================================================================
# GROUP G: PHASE 4F CORRECTION GATE TESTS (67-68)
# ==============================================================================

func _test_assign_party_uses_canonical_hero_party_assignment() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_assign_canon")

	var alder: HeroModel = coord.get_hero("hero_alder")
	if alder == null:
		printerr("Alder not found")
		return false
	if alder.is_in_party() or not alder.party_id.is_empty() or alder.lifecycle_state != HeroLifecycleState.ROSTER_ACTIVE:
		printerr("Alder initial state invalid")
		return false

	var ok: bool = coord.assign_hero_to_party("hero_alder", "party_1")
	if not ok:
		printerr("assign_hero_to_party returned false")
		return false

	var party: PartyModel = coord.get_party("party_1")
	var party_id_canonical: bool = (alder.get_party_id() == "party_1" and alder.party_id == "party_1")
	var is_in_party_ok: bool = alder.is_in_party("party_1")
	var lifecycle_ok: bool = (alder.lifecycle_state == HeroLifecycleState.IN_PARTY)
	var party_model_contains_hero: bool = (party != null and party.has_member("hero_alder") and party.get_members().has("hero_alder"))
	var invariants_ok: bool = alder.validate_invariants()

	return party_id_canonical and is_in_party_ok and lifecycle_ok and party_model_contains_hero and invariants_ok


func _test_assign_party_rolls_back_atomically_when_mutation_fails() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("proto_assign_rollback")

	var alder: HeroModel = coord.get_hero("hero_alder")
	if alder == null or alder.is_in_party() or alder.lifecycle_state != HeroLifecycleState.ROSTER_ACTIVE:
		return false

	# Test Part A: Simulasi kegagalan pada tahap set_party_id
	# Kita manipulasi sementara party_id pada party_1 agar ditolak oleh HeroModel.set_party_id (bukan party_1 / party_2)
	var p1: PartyModel = coord.get_party("party_1")
	var orig_pid: String = p1.party_id
	p1.party_id = "party_invalid_target"

	var fail_res_a: bool = coord.assign_hero_to_party("hero_alder", "party_invalid_target")

	# Pulihkan party_id party_1
	p1.party_id = orig_pid

	# Pastikan Part A rollback sempurna:
	# 1. assign gagal
	# 2. party_id kembali kosong ("")
	# 3. is_in_party() false
	# 4. lifecycle kembali ke ROSTER_ACTIVE
	# 5. tidak ada partial membership di party
	# 6. invarian hero tetap valid
	var a_ok: bool = (not fail_res_a
		and alder.party_id.is_empty()
		and alder.get_party_id() == ""
		and not alder.is_in_party()
		and alder.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE
		and not p1.has_member("hero_alder")
		and p1.get_member_count() == 0
		and alder.validate_invariants())

	if not a_ok:
		printerr("Rollback failed for set_party_id failure path")
		return false

	# Test Part B: Simulasi kegagalan pada tahap party.add_member
	# Definisikan mock party yang menolak add_member
	var mock_p := MockFailingParty.new()
	coord._parties[0] = mock_p

	var fail_res_b: bool = coord.assign_hero_to_party("hero_alder", "party_1")

	# Pulihkan party_1 asli
	coord._parties[0] = p1

	# Pastikan Part B rollback sempurna:
	# 1. assign gagal
	# 2. hero.clear_party_assignment() dijalankan (party_id kembali kosong)
	# 3. lifecycle_state kembali ke ROSTER_ACTIVE
	# 4. tidak ada partial membership
	# 5. invarian hero tetap valid
	var b_ok: bool = (not fail_res_b
		and alder.party_id.is_empty()
		and alder.get_party_id() == ""
		and not alder.is_in_party()
		and alder.lifecycle_state == HeroLifecycleState.ROSTER_ACTIVE
		and not p1.has_member("hero_alder")
		and p1.get_member_count() == 0
		and alder.validate_invariants())

	if not b_ok:
		printerr("Rollback failed for party.add_member failure path")
		return false

	return true


class MockFailingParty:
	extends RefCounted
	var party_id: String = "party_1"
	var party_name: String = "Mock Failing Party"
	var leader_hero_id: String = ""
	var member_hero_ids: Array = []
	var is_deployed_to_battle: bool = true

	func is_full() -> bool:
		return false

	func has_member(_h_id: String) -> bool:
		return false

	func add_member(_h_id: String) -> bool:
		return false

	func remove_member(_h_id: String) -> bool:
		return true

	func get_member_count() -> int:
		return 0

	func get_members() -> Array:
		return []
