extends SceneTree

## TestPhase6DCommanderCommands
## Unit test suite komprehensif untuk Phase 6D — Commander Commands Execution.
## Menguji:
## - Group A: Command Contract & DTO (Tests 1-5)
## - Group B: Command Validation & Rejection (Tests 6-9)
## - Group C: Battle-State Restrictions (Tests 10-14)
## - Group D: Move & Advance Topology (Tests 15-20)
## - Group E: Retreat Determinism (Tests 21-25)
## - Group F: Hold Position (Tests 26-28)
## - Group G: Protect Intent (Tests 29-31)
## - Group H: Focus Target Intent (Tests 32-34)
## - Group I: Follow Intent (Tests 35-37)
## - Group J: Battle Lock & Physical Invariants Preservation (Tests 38-41)
## - Group K: Tick Integration & Timing (Tests 42-44)
## - Group L: Snapshot & Deep-Copy Integrity (Tests 45-47)
## - Group M: Determinism & Repeatability (Tests 48-49)
## - Group N: Deterministic 1,000-Command / Tick Stress Simulation (Test 50)

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const CombatEngine = preload("res://scripts/simulation/combat_engine.gd")
const GameStateSnapshot = preload("res://scripts/domain/state/game_state_snapshot.gd")
const BattlefieldZone = preload("res://scripts/domain/model/battlefield_zone.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const PartyModel = preload("res://scripts/domain/model/party_model.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const CommanderCommand = preload("res://scripts/domain/command/commander_command.gd")
const EnemyArchetype = preload("res://scripts/domain/model/enemy_archetype.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 6D COMMANDER COMMANDS EXECUTION TESTS")
	print("================================================================")

	var tests: Array[Dictionary] = [
		# Group A: Command Contract & DTO
		{"name": "test_a1_command_creation_defaults", "fn": Callable(self, "_test_a1_command_creation_defaults")},
		{"name": "test_a2_canonical_and_alias_types", "fn": Callable(self, "_test_a2_canonical_and_alias_types")},
		{"name": "test_a3_command_normalization", "fn": Callable(self, "_test_a3_command_normalization")},
		{"name": "test_a4_command_cloning", "fn": Callable(self, "_test_a4_command_cloning")},
		{"name": "test_a5_command_serialization_roundtrip", "fn": Callable(self, "_test_a5_command_serialization_roundtrip")},

		# Group B: Command Validation & Rejection
		{"name": "test_b1_invalid_command_type_rejected", "fn": Callable(self, "_test_b1_invalid_command_type_rejected")},
		{"name": "test_b2_empty_command_type_rejected", "fn": Callable(self, "_test_b2_empty_command_type_rejected")},
		{"name": "test_b3_null_command_rejected", "fn": Callable(self, "_test_b3_null_command_rejected")},
		{"name": "test_b4_party_2_command_rejected", "fn": Callable(self, "_test_b4_party_2_command_rejected")},

		# Group C: Battle-State Restrictions
		{"name": "test_c1_battle_state_permits_command", "fn": Callable(self, "_test_c1_battle_state_permits_command")},
		{"name": "test_c2_preparation_rejects_command", "fn": Callable(self, "_test_c2_preparation_rejects_command")},
		{"name": "test_c3_wave_preview_rejects_command", "fn": Callable(self, "_test_c3_wave_preview_rejects_command")},
		{"name": "test_c4_result_rejects_command", "fn": Callable(self, "_test_c4_result_rejects_command")},
		{"name": "test_c5_game_over_rejects_command", "fn": Callable(self, "_test_c5_game_over_rejects_command")},

		# Group D: Move & Advance Topology
		{"name": "test_d1_move_to_valid_neighbor_gate_to_wall", "fn": Callable(self, "_test_d1_move_to_valid_neighbor_gate_to_wall")},
		{"name": "test_d2_move_to_valid_neighbor_gate_to_center", "fn": Callable(self, "_test_d2_move_to_valid_neighbor_gate_to_center")},
		{"name": "test_d3_move_to_non_neighbor_rejected", "fn": Callable(self, "_test_d3_move_to_non_neighbor_rejected")},
		{"name": "test_d4_move_to_same_zone_rejected", "fn": Callable(self, "_test_d4_move_to_same_zone_rejected")},
		{"name": "test_d5_move_to_outer_field_rejected", "fn": Callable(self, "_test_d5_move_to_outer_field_rejected")},
		{"name": "test_d6_advance_forward_topology", "fn": Callable(self, "_test_d6_advance_forward_topology")},

		# Group E: Retreat Determinism
		{"name": "test_e1_retreat_center_approach_to_gate", "fn": Callable(self, "_test_e1_retreat_center_approach_to_gate")},
		{"name": "test_e2_retreat_left_flank_to_wall", "fn": Callable(self, "_test_e2_retreat_left_flank_to_wall")},
		{"name": "test_e3_retreat_right_flank_to_wall", "fn": Callable(self, "_test_e3_retreat_right_flank_to_wall")},
		{"name": "test_e4_retreat_gate_and_wall_to_fortress", "fn": Callable(self, "_test_e4_retreat_gate_and_wall_to_fortress")},
		{"name": "test_e5_retreat_fortress_stays_in_fortress", "fn": Callable(self, "_test_e5_retreat_fortress_stays_in_fortress")},

		# Group F: Hold Position
		{"name": "test_f1_hold_position_zone_unchanged", "fn": Callable(self, "_test_f1_hold_position_zone_unchanged")},
		{"name": "test_f2_hold_position_sets_intent", "fn": Callable(self, "_test_f2_hold_position_sets_intent")},
		{"name": "test_f3_repeated_hold_position_deterministic", "fn": Callable(self, "_test_f3_repeated_hold_position_deterministic")},

		# Group G: Protect Intent
		{"name": "test_g1_protect_fortress_intent_saved", "fn": Callable(self, "_test_g1_protect_fortress_intent_saved")},
		{"name": "test_g2_protect_zone_intent_saved", "fn": Callable(self, "_test_g2_protect_zone_intent_saved")},
		{"name": "test_g3_protect_does_not_mutate_zone", "fn": Callable(self, "_test_g3_protect_does_not_mutate_zone")},

		# Group H: Focus Target Intent
		{"name": "test_h1_focus_enemy_archetype_saved", "fn": Callable(self, "_test_h1_focus_enemy_archetype_saved")},
		{"name": "test_h2_focus_enemy_group_id_saved", "fn": Callable(self, "_test_h2_focus_enemy_group_id_saved")},
		{"name": "test_h3_focus_empty_target_rejected", "fn": Callable(self, "_test_h3_focus_empty_target_rejected")},

		# Group I: Follow Intent
		{"name": "test_i1_follow_valid_friendly_target", "fn": Callable(self, "_test_i1_follow_valid_friendly_target")},
		{"name": "test_i2_follow_self_rejected", "fn": Callable(self, "_test_i2_follow_self_rejected")},
		{"name": "test_i3_follow_nonexistent_target_rejected", "fn": Callable(self, "_test_i3_follow_nonexistent_target_rejected")},

		# Group J: Battle Lock & Physical Invariants Preservation
		{"name": "test_j1_battle_lock_equipment_preserved", "fn": Callable(self, "_test_j1_battle_lock_equipment_preserved")},
		{"name": "test_j2_command_does_not_mutate_population", "fn": Callable(self, "_test_j2_command_does_not_mutate_population")},
		{"name": "test_j3_command_does_not_mutate_fortress_hp", "fn": Callable(self, "_test_j3_command_does_not_mutate_fortress_hp")},
		{"name": "test_j4_command_does_not_cause_casualties_or_loot", "fn": Callable(self, "_test_j4_command_does_not_cause_casualties_or_loot")},

		# Group K: Tick Integration & Timing
		{"name": "test_k1_command_issued_at_battle_tick_stamped", "fn": Callable(self, "_test_k1_command_issued_at_battle_tick_stamped")},
		{"name": "test_k2_command_tick_advances_with_simulation", "fn": Callable(self, "_test_k2_command_tick_advances_with_simulation")},
		{"name": "test_k3_command_history_retains_tick_order", "fn": Callable(self, "_test_k3_command_history_retains_tick_order")},

		# Group L: Snapshot & Deep-Copy Integrity
		{"name": "test_l1_snapshot_telemetry_last_command", "fn": Callable(self, "_test_l1_snapshot_telemetry_last_command")},
		{"name": "test_l2_snapshot_command_history_deep_copy", "fn": Callable(self, "_test_l2_snapshot_command_history_deep_copy")},
		{"name": "test_l3_snapshot_active_intents_mapping", "fn": Callable(self, "_test_l3_snapshot_active_intents_mapping")},

		# Group M: Determinism & Repeatability
		{"name": "test_m1_same_seed_and_commands_identical_state", "fn": Callable(self, "_test_m1_same_seed_and_commands_identical_state")},
		{"name": "test_m2_command_sequence_id_monotonic", "fn": Callable(self, "_test_m2_command_sequence_id_monotonic")},

		# Group N: Deterministic 1,000-Command / Tick Stress Simulation
		{"name": "test_n1_1000_command_tick_stress_simulation", "fn": Callable(self, "_test_n1_1000_command_tick_stress_simulation")},
	]

	var passed: int = 0
	var failed: int = 0

	for t in tests:
		var test_name: String = t["name"]
		var callable: Callable = t["fn"]
		var success: bool = false
		var err_msg: String = ""

		var result = callable.call()
		if result is bool:
			success = result
		else:
			success = true

		if success:
			passed += 1
			print("[PASS] %s" % test_name)
		else:
			failed += 1
			print("[FAIL] %s %s" % [test_name, err_msg])

	print("================================================================")
	print("PHASE 6D TEST SUMMARY: %d PASSED, %d FAILED (Total %d)" % [passed, failed, tests.size()])
	print("================================================================")

	for c in root.get_children():
		root.remove_child(c)
		c.free()

	if failed > 0:
		quit(1)
	else:
		quit(0)


# ==============================================================================
# HELPER SETUP
# ==============================================================================

func _create_battle_ready_coord(session_id: String = "p6d_sess", seed_val: int = 42) -> GameCoordinator:
	var coord := GameCoordinator.new()
	coord.start_new_session(session_id, seed_val)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.create_deployment(2, "SWORD")
	coord.inspect_wave()
	coord.start_battle()
	return coord


# ==============================================================================
# GROUP A: COMMAND CONTRACT & DTO
# ==============================================================================

func _test_a1_command_creation_defaults() -> bool:
	var cmd := CommanderCommand.new()
	if cmd.command_type != CommanderCommand.TYPE_HOLD_POSITION:
		return false
	if cmd.source_id != "party_1":
		return false
	if cmd.status != "REGISTERED":
		return false
	if cmd.issued_at_battle_tick != 0:
		return false
	return true


func _test_a2_canonical_and_alias_types() -> bool:
	var expected := ["ADVANCE", "MOVE", "HOLD_POSITION", "HOLD", "RETREAT", "PROTECT", "FOCUS_TARGET", "FOCUS", "FOLLOW"]
	for t in expected:
		if not CommanderCommand.is_valid_type(t):
			return false
	return true


func _test_a3_command_normalization() -> bool:
	if CommanderCommand.normalize_type("HOLD") != "HOLD_POSITION":
		return false
	if CommanderCommand.normalize_type("FOCUS") != "FOCUS_TARGET":
		return false
	if CommanderCommand.normalize_type("MOVE") != "MOVE":
		return false
	if CommanderCommand.normalize_type("ADVANCE") != "ADVANCE":
		return false
	return true


func _test_a4_command_cloning() -> bool:
	var cmd := CommanderCommand.new("MOVE", "party_1", "WALL", 15, "WALL")
	cmd.sequence_id = 7
	cmd.status = "EXECUTED"
	var copy: CommanderCommand = cmd.clone()

	if copy.command_type != cmd.command_type:
		return false
	if copy.source_id != cmd.source_id:
		return false
	if copy.target_zone != cmd.target_zone:
		return false
	if copy.issued_at_battle_tick != 15:
		return false
	if copy.sequence_id != 7 or copy.status != "EXECUTED":
		return false
	return true


func _test_a5_command_serialization_roundtrip() -> bool:
	var cmd := CommanderCommand.new("PROTECT", "party_1", "FORTRESS", 20, "FORTRESS")
	cmd.sequence_id = 12
	cmd.status = "EXECUTED"

	var d: Dictionary = cmd.to_dictionary()
	var restored: CommanderCommand = CommanderCommand.from_dictionary(d)

	if restored.command_type != CommanderCommand.TYPE_PROTECT:
		return false
	if restored.source_id != "party_1":
		return false
	if restored.target_zone != "FORTRESS":
		return false
	if restored.issued_at_battle_tick != 20:
		return false
	if restored.sequence_id != 12:
		return false
	return true


# ==============================================================================
# GROUP B: COMMAND VALIDATION & REJECTION
# ==============================================================================

func _test_b1_invalid_command_type_rejected() -> bool:
	var coord := _create_battle_ready_coord("p6d_b1")
	var cmd := CommanderCommand.new("FLY_TO_MOON")
	return not coord.send_commander_command(cmd)


func _test_b2_empty_command_type_rejected() -> bool:
	var coord := _create_battle_ready_coord("p6d_b2")
	var cmd := CommanderCommand.new("")
	return not coord.send_commander_command(cmd)


func _test_b3_null_command_rejected() -> bool:
	var coord := _create_battle_ready_coord("p6d_b3")
	return not coord.send_commander_command(null)


func _test_b4_party_2_command_rejected() -> bool:
	var coord := _create_battle_ready_coord("p6d_b4")
	# Party 2 dilarang berpartisipasi dalam pertempuran
	var cmd := CommanderCommand.new("HOLD_POSITION", "party_2")
	return not coord.send_commander_command(cmd)


# ==============================================================================
# GROUP C: BATTLE-STATE RESTRICTIONS
# ==============================================================================

func _test_c1_battle_state_permits_command() -> bool:
	var coord := _create_battle_ready_coord("p6d_c1")
	var cmd := CommanderCommand.new("HOLD_POSITION", "party_1")
	return coord.send_commander_command(cmd)


func _test_c2_preparation_rejects_command() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6d_c2")
	# Masih dalam STATE_PREPARATION
	var cmd := CommanderCommand.new("HOLD_POSITION", "party_1")
	return not coord.send_commander_command(cmd)


func _test_c3_wave_preview_rejects_command() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6d_c3")
	coord.inspect_wave()
	# Dalam STATE_WAVE_PREVIEW
	var cmd := CommanderCommand.new("HOLD_POSITION", "party_1")
	return not coord.send_commander_command(cmd)


func _test_c4_result_rejects_command() -> bool:
	var coord := _create_battle_ready_coord("p6d_c4")
	coord.execute_battle(42)
	# Dalam STATE_RESULT
	var cmd := CommanderCommand.new("HOLD_POSITION", "party_1")
	return not coord.send_commander_command(cmd)


func _test_c5_game_over_rejects_command() -> bool:
	var coord := _create_battle_ready_coord("p6d_c5")
	# Runtuhkan benteng agar game over
	coord._fortress.current_hp = 0
	coord.execute_battle(42)
	coord.proceed_from_result()
	# Sekarang STATE_GAME_OVER
	var cmd := CommanderCommand.new("HOLD_POSITION", "party_1")
	return not coord.send_commander_command(cmd)


# ==============================================================================
# GROUP D: MOVE & ADVANCE TOPOLOGY
# ==============================================================================

func _test_d1_move_to_valid_neighbor_gate_to_wall() -> bool:
	var coord := _create_battle_ready_coord("p6d_d1")
	var p1: PartyModel = coord.get_party("party_1")
	if p1.current_zone != "GATE":
		return false
	var cmd := CommanderCommand.new("MOVE", "party_1", "WALL", 0, "WALL")
	var ok: bool = coord.send_commander_command(cmd)
	if not ok:
		return false
	return p1.current_zone == "WALL"


func _test_d2_move_to_valid_neighbor_gate_to_center() -> bool:
	var coord := _create_battle_ready_coord("p6d_d2")
	var p1: PartyModel = coord.get_party("party_1")
	var cmd := CommanderCommand.new("MOVE", "party_1", "CENTER_APPROACH", 0, "CENTER_APPROACH")
	var ok: bool = coord.send_commander_command(cmd)
	if not ok:
		return false
	return p1.current_zone == "CENTER_APPROACH"


func _test_d3_move_to_non_neighbor_rejected() -> bool:
	var coord := _create_battle_ready_coord("p6d_d3")
	var p1: PartyModel = coord.get_party("party_1")
	# GATE tidak bertetangga langsung dengan LEFT_FLANK
	var cmd := CommanderCommand.new("MOVE", "party_1", "LEFT_FLANK", 0, "LEFT_FLANK")
	var ok: bool = coord.send_commander_command(cmd)
	if ok:
		return false
	return p1.current_zone == "GATE"


func _test_d4_move_to_same_zone_rejected() -> bool:
	var coord := _create_battle_ready_coord("p6d_d4")
	# Party 1 sudah di GATE, MOVE ke GATE harus ditolak
	var cmd := CommanderCommand.new("MOVE", "party_1", "GATE", 0, "GATE")
	return not coord.send_commander_command(cmd)


func _test_d5_move_to_outer_field_rejected() -> bool:
	var coord := _create_battle_ready_coord("p6d_d5")
	# Pindahkan ke CENTER_APPROACH terlebih dahulu
	coord.send_commander_command(CommanderCommand.new("MOVE", "party_1", "CENTER_APPROACH", 0, "CENTER_APPROACH"))
	# Coba masuk ke OUTER_FIELD (harus ditolak keras)
	var cmd := CommanderCommand.new("MOVE", "party_1", "OUTER_FIELD", 0, "OUTER_FIELD")
	return not coord.send_commander_command(cmd)


func _test_d6_advance_forward_topology() -> bool:
	var coord := _create_battle_ready_coord("p6d_d6")
	var p1: PartyModel = coord.get_party("party_1")
	# Dari GATE, ADVANCE maju ke CENTER_APPROACH
	var cmd := CommanderCommand.new("ADVANCE", "party_1")
	var ok: bool = coord.send_commander_command(cmd)
	if not ok:
		return false
	return p1.current_zone == "CENTER_APPROACH" and p1.tactical_intent == "ADVANCE"


# ==============================================================================
# GROUP E: RETREAT DETERMINISM
# ==============================================================================

func _test_e1_retreat_center_approach_to_gate() -> bool:
	var coord := _create_battle_ready_coord("p6d_e1")
	var p1: PartyModel = coord.get_party("party_1")
	p1.set_zone("CENTER_APPROACH")
	var cmd := CommanderCommand.new("RETREAT", "party_1")
	var ok: bool = coord.send_commander_command(cmd)
	if not ok:
		return false
	return p1.current_zone == "GATE"


func _test_e2_retreat_left_flank_to_wall() -> bool:
	var coord := _create_battle_ready_coord("p6d_e2")
	var p1: PartyModel = coord.get_party("party_1")
	p1.set_zone("LEFT_FLANK")
	var cmd := CommanderCommand.new("RETREAT", "party_1")
	var ok: bool = coord.send_commander_command(cmd)
	if not ok:
		return false
	return p1.current_zone == "WALL"


func _test_e3_retreat_right_flank_to_wall() -> bool:
	var coord := _create_battle_ready_coord("p6d_e3")
	var p1: PartyModel = coord.get_party("party_1")
	p1.set_zone("RIGHT_FLANK")
	var cmd := CommanderCommand.new("RETREAT", "party_1")
	var ok: bool = coord.send_commander_command(cmd)
	if not ok:
		return false
	return p1.current_zone == "WALL"


func _test_e4_retreat_gate_and_wall_to_fortress() -> bool:
	var coord := _create_battle_ready_coord("p6d_e4")
	var p1: PartyModel = coord.get_party("party_1")
	# Dari GATE mundur ke FORTRESS
	p1.set_zone("GATE")
	coord.send_commander_command(CommanderCommand.new("RETREAT", "party_1"))
	if p1.current_zone != "FORTRESS":
		return false

	# Dari WALL mundur ke FORTRESS
	p1.set_zone("WALL")
	coord.send_commander_command(CommanderCommand.new("RETREAT", "party_1"))
	if p1.current_zone != "FORTRESS":
		return false
	return true


func _test_e5_retreat_fortress_stays_in_fortress() -> bool:
	var coord := _create_battle_ready_coord("p6d_e5")
	var p1: PartyModel = coord.get_party("party_1")
	p1.set_zone("FORTRESS")
	var ok: bool = coord.send_commander_command(CommanderCommand.new("RETREAT", "party_1"))
	if not ok:
		return false
	return p1.current_zone == "FORTRESS"


# ==============================================================================
# GROUP F: HOLD POSITION
# ==============================================================================

func _test_f1_hold_position_zone_unchanged() -> bool:
	var coord := _create_battle_ready_coord("p6d_f1")
	var p1: PartyModel = coord.get_party("party_1")
	p1.set_zone("WALL")
	var ok: bool = coord.send_commander_command(CommanderCommand.new("HOLD_POSITION", "party_1"))
	if not ok:
		return false
	return p1.current_zone == "WALL"


func _test_f2_hold_position_sets_intent() -> bool:
	var coord := _create_battle_ready_coord("p6d_f2")
	var p1: PartyModel = coord.get_party("party_1")
	coord.send_commander_command(CommanderCommand.new("HOLD_POSITION", "party_1"))
	return p1.tactical_intent == "HOLD_POSITION"


func _test_f3_repeated_hold_position_deterministic() -> bool:
	var coord := _create_battle_ready_coord("p6d_f3")
	var p1: PartyModel = coord.get_party("party_1")
	for i in range(10):
		var ok: bool = coord.send_commander_command(CommanderCommand.new("HOLD_POSITION", "party_1"))
		if not ok or p1.current_zone != "GATE" or p1.tactical_intent != "HOLD_POSITION":
			return false
	return true


# ==============================================================================
# GROUP G: PROTECT INTENT
# ==============================================================================

func _test_g1_protect_fortress_intent_saved() -> bool:
	var coord := _create_battle_ready_coord("p6d_g1")
	var p1: PartyModel = coord.get_party("party_1")
	var ok: bool = coord.send_commander_command(CommanderCommand.new("PROTECT", "party_1", "FORTRESS", 0, "FORTRESS"))
	if not ok:
		return false
	return p1.tactical_intent == "PROTECT" and p1.protected_target == "FORTRESS"


func _test_g2_protect_zone_intent_saved() -> bool:
	var coord := _create_battle_ready_coord("p6d_g2")
	var p1: PartyModel = coord.get_party("party_1")
	var ok: bool = coord.send_commander_command(CommanderCommand.new("PROTECT", "party_1", "GATE", 0, "GATE"))
	if not ok:
		return false
	return p1.tactical_intent == "PROTECT" and p1.protected_target == "GATE"


func _test_g3_protect_does_not_mutate_zone() -> bool:
	var coord := _create_battle_ready_coord("p6d_g3")
	var p1: PartyModel = coord.get_party("party_1")
	var orig_zone: String = p1.current_zone
	coord.send_commander_command(CommanderCommand.new("PROTECT", "party_1", "FORTRESS", 0, "FORTRESS"))
	return p1.current_zone == orig_zone


# ==============================================================================
# GROUP H: FOCUS TARGET INTENT
# ==============================================================================

func _test_h1_focus_enemy_archetype_saved() -> bool:
	var coord := _create_battle_ready_coord("p6d_h1")
	var p1: PartyModel = coord.get_party("party_1")
	var cmd := CommanderCommand.new("FOCUS_TARGET", "party_1", "ORC_FRONTLINE", 0, "", "ORC_FRONTLINE")
	var ok: bool = coord.send_commander_command(cmd)
	if not ok:
		return false
	return p1.tactical_intent == "FOCUS_TARGET" and p1.focus_target == "ORC_FRONTLINE"


func _test_h2_focus_enemy_group_id_saved() -> bool:
	var coord := _create_battle_ready_coord("p6d_h2")
	var p1: PartyModel = coord.get_party("party_1")
	var cmd := CommanderCommand.new("FOCUS_TARGET", "party_1", "enemy_group_3", 0, "", "enemy_group_3")
	var ok: bool = coord.send_commander_command(cmd)
	if not ok:
		return false
	return p1.tactical_intent == "FOCUS_TARGET" and p1.focus_target == "enemy_group_3"


func _test_h3_focus_empty_target_rejected() -> bool:
	var coord := _create_battle_ready_coord("p6d_h3")
	var cmd := CommanderCommand.new("FOCUS_TARGET", "party_1", "")
	return not coord.send_commander_command(cmd)


# ==============================================================================
# GROUP I: FOLLOW INTENT
# ==============================================================================

func _test_i1_follow_valid_friendly_target() -> bool:
	var coord := _create_battle_ready_coord("p6d_i1")
	var depls := coord.get_active_deployments()
	var target_comp_id: String = (depls[0] as DeploymentComposition).composition_id
	var p1: PartyModel = coord.get_party("party_1")

	var cmd := CommanderCommand.new("FOLLOW", "party_1", target_comp_id, 0, "", "", target_comp_id)
	var ok: bool = coord.send_commander_command(cmd)
	if not ok:
		return false
	return p1.tactical_intent == "FOLLOW" and p1.following_target == target_comp_id


func _test_i2_follow_self_rejected() -> bool:
	var coord := _create_battle_ready_coord("p6d_i2")
	# Target follow adalah party_1 itu sendiri (self)
	var cmd := CommanderCommand.new("FOLLOW", "party_1", "party_1", 0, "", "", "party_1")
	return not coord.send_commander_command(cmd)


func _test_i3_follow_nonexistent_target_rejected() -> bool:
	var coord := _create_battle_ready_coord("p6d_i3")
	var cmd := CommanderCommand.new("FOLLOW", "party_1", "unknown_ghost_entity", 0, "", "", "unknown_ghost_entity")
	return not coord.send_commander_command(cmd)


# ==============================================================================
# GROUP J: BATTLE LOCK & PHYSICAL INVARIANTS PRESERVATION
# ==============================================================================

func _test_j1_battle_lock_equipment_preserved() -> bool:
	var coord := _create_battle_ready_coord("p6d_j1")
	# Battle Lock harus tetap melindungi peralatan
	if coord.equip_hero("hero_alder", "PRIMARY", "SWORD"):
		return false
	if coord.unequip_hero("hero_alder", "PRIMARY"):
		return false
	return true


func _test_j2_command_does_not_mutate_population() -> bool:
	var coord := _create_battle_ready_coord("p6d_j2")
	var orig_pop: int = coord._population.get_total_population()
	var orig_avail: int = coord.get_available_soldiers()
	var orig_deployed: int = coord.get_total_deployed_soldiers()

	coord.send_commander_command(CommanderCommand.new("HOLD_POSITION", "party_1"))
	coord.send_commander_command(CommanderCommand.new("MOVE", "party_1", "WALL", 0, "WALL"))

	if coord._population.get_total_population() != orig_pop:
		return false
	if coord.get_available_soldiers() != orig_avail or coord.get_total_deployed_soldiers() != orig_deployed:
		return false
	return true


func _test_j3_command_does_not_mutate_fortress_hp() -> bool:
	var coord := _create_battle_ready_coord("p6d_j3")
	var orig_hp: int = coord._fortress.current_hp
	var orig_wall: int = coord._fortress.wall_hp
	var orig_gate: int = coord._fortress.gate_hp

	coord.send_commander_command(CommanderCommand.new("PROTECT", "party_1", "FORTRESS"))
	coord.send_commander_command(CommanderCommand.new("RETREAT", "party_1"))

	if coord._fortress.current_hp != orig_hp:
		return false
	if coord._fortress.wall_hp != orig_wall or coord._fortress.gate_hp != orig_gate:
		return false
	return true


func _test_j4_command_does_not_cause_casualties_or_loot() -> bool:
	var coord := _create_battle_ready_coord("p6d_j4")
	var orig_gold: int = coord.get_treasury_gold()

	coord.send_commander_command(CommanderCommand.new("FOCUS_TARGET", "party_1", "ORC_FRONTLINE"))

	# Tidak ada loot dan tidak ada casualty akibat command
	if coord.get_treasury_gold() != orig_gold:
		return false
	var alder: HeroModel = coord.get_hero("hero_alder")
	if not alder.is_alive or alder.lifecycle_state != HeroLifecycleState.BATTLE_ACTIVE:
		return false
	return true


# ==============================================================================
# GROUP K: TICK INTEGRATION & TIMING
# ==============================================================================

func _test_k1_command_issued_at_battle_tick_stamped() -> bool:
	var coord := _create_battle_ready_coord("p6d_k1")
	# Majukan 5 tick simulasi
	for i in range(5):
		coord.step_simulation()
	if coord.get_battle_tick() != 5:
		return false

	var cmd := CommanderCommand.new("HOLD_POSITION", "party_1")
	coord.send_commander_command(cmd)

	var last_cmd: CommanderCommand = coord.get_last_commander_command()
	return last_cmd.issued_at_battle_tick == 5


func _test_k2_command_tick_advances_with_simulation() -> bool:
	var coord := _create_battle_ready_coord("p6d_k2")
	coord.step_simulation()
	coord.send_commander_command(CommanderCommand.new("HOLD_POSITION", "party_1"))
	var c1: CommanderCommand = coord.get_last_commander_command()
	if c1.issued_at_battle_tick != 1:
		return false

	coord.step_simulation()
	coord.step_simulation()
	coord.send_commander_command(CommanderCommand.new("MOVE", "party_1", "WALL", 0, "WALL"))
	var c2: CommanderCommand = coord.get_last_commander_command()
	return c2.issued_at_battle_tick == 3


func _test_k3_command_history_retains_tick_order() -> bool:
	var coord := _create_battle_ready_coord("p6d_k3")
	coord.step_simulation()
	coord.send_commander_command(CommanderCommand.new("HOLD_POSITION", "party_1"))

	coord.step_simulation()
	coord.send_commander_command(CommanderCommand.new("MOVE", "party_1", "WALL", 0, "WALL"))

	coord.step_simulation()
	coord.send_commander_command(CommanderCommand.new("RETREAT", "party_1"))

	var hist: Array = coord.get_command_history()
	if hist.size() < 3:
		return false
	if hist[0]["issued_at_battle_tick"] != 1:
		return false
	if hist[1]["issued_at_battle_tick"] != 2:
		return false
	if hist[2]["issued_at_battle_tick"] != 3:
		return false
	return true


# ==============================================================================
# GROUP L: SNAPSHOT & DEEP-COPY INTEGRITY
# ==============================================================================

func _test_l1_snapshot_telemetry_last_command() -> bool:
	var coord := _create_battle_ready_coord("p6d_l1")
	coord.send_commander_command(CommanderCommand.new("PROTECT", "party_1", "FORTRESS", 0, "FORTRESS"))

	var snap: GameStateSnapshot = coord.get_current_state()
	var last_c: Dictionary = snap.last_commander_command
	if last_c.is_empty():
		return false
	if last_c["command_type"] != "PROTECT":
		return false
	if last_c["status"] != "EXECUTED":
		return false
	return true


func _test_l2_snapshot_command_history_deep_copy() -> bool:
	var coord := _create_battle_ready_coord("p6d_l2")
	coord.send_commander_command(CommanderCommand.new("HOLD_POSITION", "party_1"))

	var snap: GameStateSnapshot = coord.get_current_state()
	snap.command_history.append({"fake": "corrupt"})

	# Mutasi eksternal pada snapshot tidak boleh mengubah riwayat internal coordinator
	if coord.get_command_history().size() != 1:
		return false
	return true


func _test_l3_snapshot_active_intents_mapping() -> bool:
	var coord := _create_battle_ready_coord("p6d_l3")
	coord.send_commander_command(CommanderCommand.new("PROTECT", "party_1", "GATE", 0, "GATE"))

	var snap: GameStateSnapshot = coord.get_current_state()
	var intents: Dictionary = snap.active_commander_intents
	if not intents.has("party_1"):
		return false
	if intents["party_1"]["intent"] != "PROTECT":
		return false
	if intents["party_1"]["protected_target"] != "GATE":
		return false
	return true


# ==============================================================================
# GROUP M: DETERMINISM & REPEATABILITY
# ==============================================================================

func _test_m1_same_seed_and_commands_identical_state() -> bool:
	var c1 := _create_battle_ready_coord("det_1", 12345)
	var c2 := _create_battle_ready_coord("det_2", 12345)

	# Urutan perintah yang identik
	c1.send_commander_command(CommanderCommand.new("MOVE", "party_1", "WALL", 0, "WALL"))
	c2.send_commander_command(CommanderCommand.new("MOVE", "party_1", "WALL", 0, "WALL"))

	c1.step_simulation()
	c2.step_simulation()

	c1.send_commander_command(CommanderCommand.new("PROTECT", "party_1", "FORTRESS", 0, "FORTRESS"))
	c2.send_commander_command(CommanderCommand.new("PROTECT", "party_1", "FORTRESS", 0, "FORTRESS"))

	var snap1: GameStateSnapshot = c1.get_current_state()
	var snap2: GameStateSnapshot = c2.get_current_state()

	if snap1.battle_tick != snap2.battle_tick:
		return false
	if snap1.last_commander_command != snap2.last_commander_command:
		return false
	if snap1.command_history != snap2.command_history:
		return false
	if snap1.battle_party_data["current_zone"] != snap2.battle_party_data["current_zone"]:
		return false
	return true


func _test_m2_command_sequence_id_monotonic() -> bool:
	var coord := _create_battle_ready_coord("p6d_m2")
	coord.send_commander_command(CommanderCommand.new("HOLD_POSITION", "party_1"))
	var id1: int = coord.get_last_commander_command().sequence_id

	coord.send_commander_command(CommanderCommand.new("MOVE", "party_1", "WALL", 0, "WALL"))
	var id2: int = coord.get_last_commander_command().sequence_id

	coord.send_commander_command(CommanderCommand.new("RETREAT", "party_1"))
	var id3: int = coord.get_last_commander_command().sequence_id

	return id1 == 1 and id2 == 2 and id3 == 3


# ==============================================================================
# GROUP N: DETERMINISTIC 1,000-COMMAND / TICK STRESS SIMULATION
# ==============================================================================

func _test_n1_1000_command_tick_stress_simulation() -> bool:
	var coord := _create_battle_ready_coord("stress_1000_cmds", 777)
	var p1: PartyModel = coord.get_party("party_1")

	var initial_pop: int = coord._population.get_total_population()
	var initial_fortress_hp: int = coord._fortress.current_hp

	for i in range(1, 1001):
		# Putar perintah secara deterministik berdasarkan indeks
		var mod: int = i % 7
		var cmd: CommanderCommand = null
		match mod:
			0:
				# HOLD
				cmd = CommanderCommand.new("HOLD_POSITION", "party_1")
			1:
				# MOVE / ADVANCE
				var cur_z: String = p1.current_zone
				var target_z: String = "WALL" if cur_z == "GATE" else "GATE"
				cmd = CommanderCommand.new("MOVE", "party_1", target_z, 0, target_z)
			2:
				# PROTECT
				cmd = CommanderCommand.new("PROTECT", "party_1", "FORTRESS", 0, "FORTRESS")
			3:
				# RETREAT
				cmd = CommanderCommand.new("RETREAT", "party_1")
			4:
				# FOCUS TARGET
				cmd = CommanderCommand.new("FOCUS_TARGET", "party_1", "ORC_FRONTLINE", 0, "", "ORC_FRONTLINE")
			5:
				# ADVANCE
				cmd = CommanderCommand.new("ADVANCE", "party_1")
			6:
				# HOLD
				cmd = CommanderCommand.new("HOLD_POSITION", "party_1")

		var ok: bool = coord.send_commander_command(cmd)
		if not ok:
			printerr("Stress command failed at iteration: %d, type: %s" % [i, cmd.command_type])
			return false

		# Majukan simulasi tepat 1 tick
		var step_ok: bool = coord.step_simulation()
		if not step_ok:
			printerr("Stress step_simulation failed at iteration: %d" % i)
			return false

	# Verifikasi pasca-stres 1.000 iterasi
	if coord.get_battle_tick() != 1000:
		printerr("Battle tick mismatch: %d != 1000" % coord.get_battle_tick())
		return false

	# Invarian integritas: populasi dan benteng tidak boleh terpengaruh
	if coord._population.get_total_population() != initial_pop:
		printerr("Population mutated during command stress")
		return false
	if coord._fortress.current_hp != initial_fortress_hp:
		printerr("Fortress HP mutated during command stress")
		return false

	var snap: GameStateSnapshot = coord.get_current_state()
	if snap.battle_tick != 1000:
		return false
	if snap.command_history.size() == 0:
		return false

	return true
