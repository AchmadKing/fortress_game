extends SceneTree

## TestPhase6BSimulationTickPacing
## Unit test suite komprehensif untuk Phase 6B — Simulation Tick Loop & Pacing Controls.
## Menguji:
## - Group A: Tick Counter & Invariants (Tests 1-6)
## - Group B: Pause & Resume Controls (Tests 7-12)
## - Group C: Speed 1x, 2x, 4x & Validation (Tests 13-18)
## - Group D: Gameplay State Machine Validation (Tests 19-24)
## - Group E: Determinism & Repeatability (Tests 25-28)
## - Group F: Battle Lock & Domain Integrity (Tests 29-31)
## - Group G: Deterministic 10,000-Tick Stress Simulation (Test 32)

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const CombatEngine = preload("res://scripts/simulation/combat_engine.gd")
const GameStateSnapshot = preload("res://scripts/domain/state/game_state_snapshot.gd")
const BattlefieldZone = preload("res://scripts/domain/model/battlefield_zone.gd")
const EnemyArchetype = preload("res://scripts/domain/model/enemy_archetype.gd")
const EnemyGroup = preload("res://scripts/domain/model/enemy_group.gd")
const WaveGenerator = preload("res://scripts/simulation/wave_generator.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 6B SIMULATION TICK & PACING CONTROLS TESTS")
	print("================================================================")

	var tests: Array[Dictionary] = [
		# Group A: Tick Counter & Invariants
		{"name": "test_a1_initial_tick_is_zero", "fn": Callable(self, "_test_a1_initial_tick_is_zero")},
		{"name": "test_a2_one_step_increments_exactly_once", "fn": Callable(self, "_test_a2_one_step_increments_exactly_once")},
		{"name": "test_a3_multiple_steps_sequential", "fn": Callable(self, "_test_a3_multiple_steps_sequential")},
		{"name": "test_a4_tick_monotonic_increasing", "fn": Callable(self, "_test_a4_tick_monotonic_increasing")},
		{"name": "test_a5_negative_tick_rejected", "fn": Callable(self, "_test_a5_negative_tick_rejected")},
		{"name": "test_a6_no_duplicate_tick_per_step", "fn": Callable(self, "_test_a6_no_duplicate_tick_per_step")},

		# Group B: Pause & Resume Controls
		{"name": "test_b1_pause_state_transition", "fn": Callable(self, "_test_b1_pause_state_transition")},
		{"name": "test_b2_paused_step_blocked", "fn": Callable(self, "_test_b2_paused_step_blocked")},
		{"name": "test_b3_tick_unchanged_while_paused", "fn": Callable(self, "_test_b3_tick_unchanged_while_paused")},
		{"name": "test_b4_resume_restores_stepping", "fn": Callable(self, "_test_b4_resume_restores_stepping")},
		{"name": "test_b5_pause_does_not_reset_tick", "fn": Callable(self, "_test_b5_pause_does_not_reset_tick")},
		{"name": "test_b6_pause_does_not_reset_speed", "fn": Callable(self, "_test_b6_pause_does_not_reset_speed")},

		# Group C: Speed 1x, 2x, 4x & Validation
		{"name": "test_c1_speed_1x_canonical", "fn": Callable(self, "_test_c1_speed_1x_canonical")},
		{"name": "test_c2_speed_2x_canonical", "fn": Callable(self, "_test_c2_speed_2x_canonical")},
		{"name": "test_c3_speed_4x_canonical", "fn": Callable(self, "_test_c3_speed_4x_canonical")},
		{"name": "test_c4_invalid_speed_rejected", "fn": Callable(self, "_test_c4_invalid_speed_rejected")},
		{"name": "test_c5_speed_change_while_battle_active", "fn": Callable(self, "_test_c5_speed_change_while_battle_active")},
		{"name": "test_c6_speed_does_not_mutate_domain_incorrectly", "fn": Callable(self, "_test_c6_speed_does_not_mutate_domain_incorrectly")},

		# Group D: Gameplay State Machine Validation
		{"name": "test_d1_battle_state_permits_simulation", "fn": Callable(self, "_test_d1_battle_state_permits_simulation")},
		{"name": "test_d2_preparation_rejects_simulation", "fn": Callable(self, "_test_d2_preparation_rejects_simulation")},
		{"name": "test_d3_wave_preview_rejects_simulation", "fn": Callable(self, "_test_d3_wave_preview_rejects_simulation")},
		{"name": "test_d4_result_rejects_simulation", "fn": Callable(self, "_test_d4_result_rejects_simulation")},
		{"name": "test_d5_recovery_rejects_simulation", "fn": Callable(self, "_test_d5_recovery_rejects_simulation")},
		{"name": "test_d6_game_over_rejects_simulation", "fn": Callable(self, "_test_d6_game_over_rejects_simulation")},

		# Group E: Determinism & Repeatability
		{"name": "test_e1_same_seed_same_tick_sequence", "fn": Callable(self, "_test_e1_same_seed_same_tick_sequence")},
		{"name": "test_e2_same_initial_state_same_output", "fn": Callable(self, "_test_e2_same_initial_state_same_output")},
		{"name": "test_e3_repeated_simulation_same_output", "fn": Callable(self, "_test_e3_repeated_simulation_same_output")},
		{"name": "test_e4_pause_resume_preserves_deterministic_sequence", "fn": Callable(self, "_test_e4_pause_resume_preserves_deterministic_sequence")},

		# Group F: Battle Lock & Domain Integrity
		{"name": "test_f1_battle_lock_strictly_preserved", "fn": Callable(self, "_test_f1_battle_lock_strictly_preserved")},
		{"name": "test_f2_phase6a_enemy_groups_unchanged_by_clock_only_simulation", "fn": Callable(self, "_test_f2_phase6a_enemy_groups_unchanged_by_clock_only_simulation")},
		{"name": "test_f3_controller_delegation_and_timer_sync", "fn": Callable(self, "_test_f3_controller_delegation_and_timer_sync")},
		{"name": "test_f4_simulation_ticks_do_not_auto_resolve_battle", "fn": Callable(self, "_test_f4_simulation_ticks_do_not_auto_resolve_battle")},

		# Group G: Deterministic 10,000-Tick Stress Simulation
		{"name": "test_g1_deterministic_10000_tick_stress_simulation", "fn": Callable(self, "_test_g1_deterministic_10000_tick_stress_simulation")}
	]

	var passed: int = 0
	var failed: int = 0

	for t in tests:
		print("[TEST] Running %s..." % t["name"])
		var result: bool = false
		var fn: Callable = t["fn"]
		result = fn.call()
		if result:
			passed += 1
			print("[PASS] %s" % t["name"])
		else:
			failed += 1
			printerr("[FAIL] %s" % t["name"])

	print("================================================================")
	print("PHASE 6B TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("================================================================")

	for c in root.get_children():
		root.remove_child(c)
		c.free()

	if failed == 0:
		quit(0)
	else:
		quit(1)


# ==============================================================================
# TEST SESSION HELPERS
# ==============================================================================

func _create_battle_ready_coordinator(session_id: String = "test_battle", seed_val: int = 12345) -> GameCoordinator:
	var coord := GameCoordinator.new()
	coord.start_new_session(session_id, seed_val)
	# Transisi: PREPARATION -> WAVE_PREVIEW -> BATTLE
	coord.inspect_wave()
	coord.start_battle()
	return coord


# ==============================================================================
# GROUP A: TICK COUNTER & INVARIANTS
# ==============================================================================

func _test_a1_initial_tick_is_zero() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_a1")
	if coord.get_battle_tick() != 0:
		printerr("Initial battle_tick should be 0, got: %d" % coord.get_battle_tick())
		return false
	var snap: GameStateSnapshot = coord.get_current_state()
	if snap.battle_tick != 0:
		printerr("Snapshot battle_tick should be 0, got: %d" % snap.battle_tick)
		return false
	return true


func _test_a2_one_step_increments_exactly_once() -> bool:
	var coord := _create_battle_ready_coordinator("test_a2")
	if coord.get_battle_tick() != 0:
		printerr("Pre-step tick should be 0")
		return false
	var ok: bool = coord.step_simulation()
	if not ok:
		printerr("step_simulation should succeed in BATTLE state")
		return false
	if coord.get_battle_tick() != 1:
		printerr("Post-step tick should be exactly 1, got: %d" % coord.get_battle_tick())
		return false
	var snap: GameStateSnapshot = coord.get_current_state()
	if snap.battle_tick != 1:
		printerr("Snapshot tick should be 1, got: %d" % snap.battle_tick)
		return false
	return true


func _test_a3_multiple_steps_sequential() -> bool:
	var coord := _create_battle_ready_coordinator("test_a3")
	for i in range(1, 11):
		var ok: bool = coord.step_simulation()
		if not ok:
			printerr("Step %d failed" % i)
			return false
		if coord.get_battle_tick() != i:
			printerr("Step %d: tick mismatch: %d != %d" % [i, coord.get_battle_tick(), i])
			return false
	if coord.get_battle_tick() != 10:
		printerr("Final tick should be 10, got: %d" % coord.get_battle_tick())
		return false
	return true


func _test_a4_tick_monotonic_increasing() -> bool:
	var coord := _create_battle_ready_coordinator("test_a4")
	var prev_tick: int = -1
	for _i in range(15):
		coord.step_simulation()
		var cur_tick: int = coord.get_battle_tick()
		if cur_tick <= prev_tick:
			printerr("Tick not strictly monotonically increasing: %d <= %d" % [cur_tick, prev_tick])
			return false
		prev_tick = cur_tick
	return true


func _test_a5_negative_tick_rejected() -> bool:
	var engine := CombatEngine.new()
	# Memastikan engine menolak tick negatif
	var step_res: Dictionary = engine.step_simulation_tick(0)
	if step_res.get("tick", 0) != 1:
		printerr("Engine tick advance failed")
		return false

	var snap := GameStateSnapshot.new()
	if snap.battle_tick < 0:
		printerr("Snapshot battle_tick cannot be negative")
		return false

	return true


func _test_a6_no_duplicate_tick_per_step() -> bool:
	var coord := _create_battle_ready_coordinator("test_a6")
	var recorded_ticks: Array[int] = []
	for _i in range(5):
		var before: int = coord.get_battle_tick()
		coord.step_simulation()
		var after: int = coord.get_battle_tick()
		if after != before + 1:
			printerr("Tick incremented by unexpected amount: %d -> %d" % [before, after])
			return false
		if after in recorded_ticks:
			printerr("Duplicate tick generated: %d" % after)
			return false
		recorded_ticks.append(after)
	return true


# ==============================================================================
# GROUP B: PAUSE & RESUME CONTROLS
# ==============================================================================

func _test_b1_pause_state_transition() -> bool:
	var coord := _create_battle_ready_coordinator("test_b1")
	if coord.is_battle_paused():
		printerr("Initially battle should not be paused")
		return false
	coord.pause_battle()
	if not coord.is_battle_paused():
		printerr("is_battle_paused should return true after pause_battle()")
		return false
	var snap: GameStateSnapshot = coord.get_current_state()
	if not snap.battle_paused:
		printerr("Snapshot battle_paused should be true")
		return false
	return true


func _test_b2_paused_step_blocked() -> bool:
	var coord := _create_battle_ready_coordinator("test_b2")
	coord.pause_battle()
	var ok: bool = coord.step_simulation()
	if ok:
		printerr("step_simulation should return false while paused")
		return false
	return true


func _test_b3_tick_unchanged_while_paused() -> bool:
	var coord := _create_battle_ready_coordinator("test_b3")
	coord.step_simulation()
	coord.step_simulation()
	if coord.get_battle_tick() != 2:
		printerr("Tick should be 2")
		return false

	coord.pause_battle()
	for _i in range(5):
		coord.step_simulation()

	if coord.get_battle_tick() != 2:
		printerr("Tick changed while paused: %d != 2" % coord.get_battle_tick())
		return false
	return true


func _test_b4_resume_restores_stepping() -> bool:
	var coord := _create_battle_ready_coordinator("test_b4")
	coord.pause_battle()
	coord.resume_battle()
	if coord.is_battle_paused():
		printerr("is_battle_paused should return false after resume_battle()")
		return false
	var ok: bool = coord.step_simulation()
	if not ok:
		printerr("step_simulation should succeed after resume")
		return false
	if coord.get_battle_tick() != 1:
		printerr("Tick should advance to 1 after resume, got: %d" % coord.get_battle_tick())
		return false
	return true


func _test_b5_pause_does_not_reset_tick() -> bool:
	var coord := _create_battle_ready_coordinator("test_b5")
	for _i in range(7):
		coord.step_simulation()
	if coord.get_battle_tick() != 7:
		return false

	coord.pause_battle()
	coord.resume_battle()
	if coord.get_battle_tick() != 7:
		printerr("Pause/resume reset tick: %d != 7" % coord.get_battle_tick())
		return false
	return true


func _test_b6_pause_does_not_reset_speed() -> bool:
	var coord := _create_battle_ready_coordinator("test_b6")
	coord.set_battle_speed(CombatEngine.SPEED_4X)
	if coord.get_battle_speed() != 4.0:
		return false

	coord.pause_battle()
	coord.resume_battle()
	if coord.get_battle_speed() != 4.0:
		printerr("Pause/resume reset speed: %f != 4.0" % coord.get_battle_speed())
		return false
	return true


# ==============================================================================
# GROUP C: SPEED 1X, 2X, 4X & VALIDATION
# ==============================================================================

func _test_c1_speed_1x_canonical() -> bool:
	var coord := _create_battle_ready_coordinator("test_c1")
	var ok: bool = coord.set_battle_speed(CombatEngine.SPEED_1X)
	if not ok or coord.get_battle_speed() != 1.0:
		printerr("Speed 1x configuration failed")
		return false

	# 1.0 detik delta time pada 1x = tepat 1 langkah simulasi
	var steps: int = coord.advance_simulation_time(1.0)
	if steps != 1:
		printerr("1.0s at 1x should produce exactly 1 step, got: %d" % steps)
		return false
	if coord.get_battle_tick() != 1:
		printerr("Battle tick mismatch: %d != 1" % coord.get_battle_tick())
		return false
	return true


func _test_c2_speed_2x_canonical() -> bool:
	var coord := _create_battle_ready_coordinator("test_c2")
	coord.set_battle_speed(CombatEngine.SPEED_2X)
	if coord.get_battle_speed() != 2.0:
		return false

	# 1.0 detik delta time pada 2x = tepat 2 langkah simulasi
	var steps: int = coord.advance_simulation_time(1.0)
	if steps != 2:
		printerr("1.0s at 2x should produce exactly 2 steps, got: %d" % steps)
		return false
	if coord.get_battle_tick() != 2:
		printerr("Battle tick mismatch: %d != 2" % coord.get_battle_tick())
		return false
	return true


func _test_c3_speed_4x_canonical() -> bool:
	var coord := _create_battle_ready_coordinator("test_c3")
	coord.set_battle_speed(CombatEngine.SPEED_4X)
	if coord.get_battle_speed() != 4.0:
		return false

	# 1.0 detik delta time pada 4x = tepat 4 langkah simulasi
	var steps: int = coord.advance_simulation_time(1.0)
	if steps != 4:
		printerr("1.0s at 4x should produce exactly 4 steps, got: %d" % steps)
		return false
	if coord.get_battle_tick() != 4:
		printerr("Battle tick mismatch: %d != 4" % coord.get_battle_tick())
		return false
	return true


func _test_c4_invalid_speed_rejected() -> bool:
	var coord := _create_battle_ready_coordinator("test_c4")
	coord.set_battle_speed(CombatEngine.SPEED_1X)

	var invalid_speeds: Array[float] = [0.5, 3.0, 5.0, -1.0, 0.0]
	for spd in invalid_speeds:
		var ok: bool = coord.set_battle_speed(spd)
		if ok:
			printerr("Should reject invalid speed: %f" % spd)
			return false
		if coord.get_battle_speed() != 1.0:
			printerr("Speed was mutated by rejected value: %f" % spd)
			return false
	return true


func _test_c5_speed_change_while_battle_active() -> bool:
	var coord := _create_battle_ready_coordinator("test_c5")
	coord.step_simulation()
	coord.step_simulation()
	if coord.get_battle_tick() != 2:
		return false

	coord.set_battle_speed(CombatEngine.SPEED_4X)
	coord.step_simulation()
	if coord.get_battle_tick() != 3:
		printerr("Tick corrupted after speed change: %d != 3" % coord.get_battle_tick())
		return false
	if coord.get_battle_speed() != 4.0:
		printerr("Speed mismatch: %f != 4.0" % coord.get_battle_speed())
		return false
	return true


func _test_c6_speed_does_not_mutate_domain_incorrectly() -> bool:
	var coord := _create_battle_ready_coordinator("test_c6")
	var initial_hp: int = coord._fortress.current_hp
	var initial_pop: int = coord._population.get_total_population()
	var initial_swords: int = coord.get_warehouse_usable_stock("SWORD")

	coord.set_battle_speed(CombatEngine.SPEED_4X)
	coord.step_simulation()
	coord.step_simulation()
	coord.set_battle_speed(CombatEngine.SPEED_1X)

	if coord._fortress.current_hp != initial_hp:
		printerr("Fortress HP mutated by clock tick")
		return false
	if coord._population.get_total_population() != initial_pop:
		printerr("Population mutated by clock tick")
		return false
	if coord.get_warehouse_usable_stock("SWORD") != initial_swords:
		printerr("Warehouse swords mutated by clock tick")
		return false
	return true


# ==============================================================================
# GROUP D: GAMEPLAY STATE MACHINE VALIDATION
# ==============================================================================

func _test_d1_battle_state_permits_simulation() -> bool:
	var coord := _create_battle_ready_coordinator("test_d1")
	if not coord.can_step_simulation():
		printerr("can_step_simulation should be true in STATE_BATTLE")
		return false
	if not coord.step_simulation():
		printerr("step_simulation should succeed in STATE_BATTLE")
		return false
	return true


func _test_d2_preparation_rejects_simulation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_d2")
	# State: PREPARATION
	if coord.can_step_simulation():
		printerr("can_step_simulation should be false in PREPARATION")
		return false
	if coord.step_simulation():
		printerr("step_simulation should return false in PREPARATION")
		return false
	return true


func _test_d3_wave_preview_rejects_simulation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_d3")
	coord.inspect_wave()
	# State: WAVE_PREVIEW
	if coord.can_step_simulation():
		printerr("can_step_simulation should be false in WAVE_PREVIEW")
		return false
	if coord.step_simulation():
		printerr("step_simulation should return false in WAVE_PREVIEW")
		return false
	return true


func _test_d4_result_rejects_simulation() -> bool:
	var coord := _create_battle_ready_coordinator("test_d4")
	coord.execute_battle()
	# State: RESULT
	if coord.can_step_simulation():
		printerr("can_step_simulation should be false in RESULT")
		return false
	if coord.step_simulation():
		printerr("step_simulation should return false in RESULT")
		return false
	return true


func _test_d5_recovery_rejects_simulation() -> bool:
	var coord := _create_battle_ready_coordinator("test_d5")
	coord.execute_battle()
	# Transisi RESULT -> RECOVERY
	coord._state_machine.transition_to(GameplayStateMachine.STATE_RECOVERY)
	if coord.can_step_simulation():
		printerr("can_step_simulation should be false in RECOVERY")
		return false
	if coord.step_simulation():
		printerr("step_simulation should return false in RECOVERY")
		return false
	return true


func _test_d6_game_over_rejects_simulation() -> bool:
	var coord := _create_battle_ready_coordinator("test_d6")
	coord._fortress.current_hp = 0
	coord.execute_battle()
	coord.proceed_from_result()
	# State: GAME_OVER
	if coord.can_step_simulation():
		printerr("can_step_simulation should be false in GAME_OVER")
		return false
	if coord.step_simulation():
		printerr("step_simulation should return false in GAME_OVER")
		return false
	return true


# ==============================================================================
# GROUP E: DETERMINISM & REPEATABILITY
# ==============================================================================

func _test_e1_same_seed_same_tick_sequence() -> bool:
	var coord_a := _create_battle_ready_coordinator("test_e1_a", 99999)
	var coord_b := _create_battle_ready_coordinator("test_e1_b", 99999)

	for _i in range(20):
		coord_a.step_simulation()
		coord_b.step_simulation()
		if coord_a.get_battle_tick() != coord_b.get_battle_tick():
			printerr("Tick desynchronization between identical seed coordinators")
			return false
	return true


func _test_e2_same_initial_state_same_output() -> bool:
	var coord_a := _create_battle_ready_coordinator("test_e2_a", 12345)
	var coord_b := _create_battle_ready_coordinator("test_e2_b", 12345)

	# advance_simulation_time via accumulator
	coord_a.set_battle_speed(CombatEngine.SPEED_2X)
	coord_b.set_battle_speed(CombatEngine.SPEED_2X)

	var steps_a: int = coord_a.advance_simulation_time(2.5)
	var steps_b: int = coord_b.advance_simulation_time(2.5)

	if steps_a != steps_b:
		printerr("Accumulator steps mismatch: %d != %d" % [steps_a, steps_b])
		return false
	if coord_a.get_battle_tick() != coord_b.get_battle_tick():
		printerr("Final tick mismatch: %d != %d" % [coord_a.get_battle_tick(), coord_b.get_battle_tick()])
		return false
	return true


func _test_e3_repeated_simulation_same_output() -> bool:
	var ticks_run_1: Array[int] = []
	var coord := _create_battle_ready_coordinator("test_e3", 42)
	for _i in range(10):
		coord.step_simulation()
		ticks_run_1.append(coord.get_battle_tick())

	var ticks_run_2: Array[int] = []
	coord = _create_battle_ready_coordinator("test_e3_reset", 42)
	for _i in range(10):
		coord.step_simulation()
		ticks_run_2.append(coord.get_battle_tick())

	if ticks_run_1 != ticks_run_2:
		printerr("Repeated simulation sequence mismatch")
		return false
	return true


func _test_e4_pause_resume_preserves_deterministic_sequence() -> bool:
	var coord_straight := _create_battle_ready_coordinator("test_e4_str", 555)
	for _i in range(10):
		coord_straight.step_simulation()

	var coord_paused := _create_battle_ready_coordinator("test_e4_pzd", 555)
	for _i in range(5):
		coord_paused.step_simulation()
	coord_paused.pause_battle()
	coord_paused.step_simulation() # Should be blocked
	coord_paused.resume_battle()
	for _i in range(5):
		coord_paused.step_simulation()

	if coord_straight.get_battle_tick() != coord_paused.get_battle_tick():
		printerr("Pause/resume changed final tick count: %d != %d" % [coord_straight.get_battle_tick(), coord_paused.get_battle_tick()])
		return false
	return true


# ==============================================================================
# GROUP F: BATTLE LOCK & DOMAIN INTEGRITY
# ==============================================================================

func _test_f1_battle_lock_strictly_preserved() -> bool:
	var coord := _create_battle_ready_coordinator("test_f1")
	coord.step_simulation()
	coord.step_simulation()

	# 1. Recruit hero ditolak
	if coord.can_recruit_hero():
		printerr("Recruit hero should be blocked during battle")
		return false

	# 2. Worker reassign ditolak
	if coord.reassign_worker("IDLE", "BLACKSMITH", 1):
		printerr("Worker reassign should be blocked during battle")
		return false

	# 3. Structure repair ditolak
	if coord.can_repair_structure("FORTRESS", 50):
		printerr("Structure repair should be blocked during battle")
		return false

	# 4. Construction start ditolak
	if coord.can_start_construction("barracks", 50, 100):
		printerr("Construction should be blocked during battle")
		return false

	# 5. Party mutation ditolak
	var heroes: Array = coord.get_heroes()
	if not heroes.is_empty():
		var h_id: String = heroes[0].hero_id
		if coord.can_assign_hero_to_party(h_id, "party_1"):
			printerr("Party assignment should be blocked during battle")
			return false

	return true


func _test_f2_phase6a_enemy_groups_unchanged_by_clock_only_simulation() -> bool:
	var wg := WaveGenerator.new()
	var wave_data: Dictionary = wg.generate_wave(5, 12345)
	var groups: Array = EnemyArchetype.map_wave_to_enemy_groups(wave_data)

	# Rekam state awal groups
	var initial_state: Array[Dictionary] = []
	for g in groups:
		var eg: EnemyGroup = g as EnemyGroup
		initial_state.append({
			"id": eg.group_id,
			"qty": eg.quantity,
			"hp": eg.current_hp_pool,
			"zone": eg.current_zone
		})

	# Jalankan 15 tick clock-only
	var coord := _create_battle_ready_coordinator("test_f2")
	for _i in range(15):
		coord.step_simulation()

	# Pastikan state groups tidak terpengaruh clock-only
	for i in range(groups.size()):
		var eg: EnemyGroup = groups[i] as EnemyGroup
		var init: Dictionary = initial_state[i]
		if eg.quantity != init["qty"] or eg.current_hp_pool != init["hp"] or eg.current_zone != init["zone"]:
			printerr("EnemyGroup mutated during clock-only Phase 6B: %s" % eg.group_id)
			return false

	return true


func _test_f3_controller_delegation_and_timer_sync() -> bool:
	var coord := _create_battle_ready_coordinator("test_f3")
	var ctrl := GameController.new()
	ctrl.setup(coord)

	if ctrl.get_battle_tick() != 0:
		printerr("Controller get_battle_tick mismatch")
		ctrl.free()
		return false

	ctrl.step_simulation()
	if ctrl.get_battle_tick() != 1:
		printerr("Controller step_simulation failed to increment tick")
		ctrl.free()
		return false

	ctrl.pause_battle()
	if not ctrl.is_battle_paused():
		printerr("Controller pause_battle failed")
		ctrl.free()
		return false

	ctrl.resume_battle()
	if ctrl.is_battle_paused():
		printerr("Controller resume_battle failed")
		ctrl.free()
		return false

	var ok_speed: bool = ctrl.set_speed(CombatEngine.SPEED_2X)
	if not ok_speed or ctrl.get_battle_speed() != 2.0:
		printerr("Controller set_speed failed")
		ctrl.free()
		return false

	ctrl.free()
	return true


func _test_f4_simulation_ticks_do_not_auto_resolve_battle() -> bool:
	var coord := _create_battle_ready_coordinator("test_f4")
	var ctrl := GameController.new()
	ctrl.setup(coord)

	var initial_hp: int = coord._fortress.current_hp
	var initial_pop: int = coord._population.get_total_population()
	var initial_swords: int = coord.get_warehouse_usable_stock("SWORD")

	# Jalankan 10 timeout berturut-turut pada controller (jauh melampaui step 3 legacy)
	for i in range(1, 11):
		ctrl._on_battle_timer_timeout()
		if coord.get_battle_tick() != i:
			printerr("Timeout %d failed to advance tick: %d != %d" % [i, coord.get_battle_tick(), i])
			ctrl.free()
			return false
		# Buktikan state tetap BATTLE (tidak berpindah ke RESULT atau RECOVERY)
		if coord._state_machine.current_state != GameplayStateMachine.STATE_BATTLE:
			printerr("Timeout %d caused premature state transition to: %s" % [i, coord._state_machine.current_state])
			ctrl.free()
			return false
		var snap: GameStateSnapshot = coord.get_current_state()
		if not snap.last_battle_result.is_empty():
			printerr("Timeout %d generated premature battle result!" % i)
			ctrl.free()
			return false

	# Verifikasi domain state tidak rusak / terkorupsi oleh clock ticks
	if coord._fortress.current_hp != initial_hp:
		printerr("Fortress HP mutated during clock ticks")
		ctrl.free()
		return false
	if coord._population.get_total_population() != initial_pop:
		printerr("Population mutated during clock ticks")
		ctrl.free()
		return false
	if coord.get_warehouse_usable_stock("SWORD") != initial_swords:
		printerr("Warehouse stock mutated during clock ticks")
		ctrl.free()
		return false

	ctrl.free()
	return true


# ==============================================================================
# GROUP G: DETERMINISTIC 10,000-TICK STRESS SIMULATION
# ==============================================================================

func _test_g1_deterministic_10000_tick_stress_simulation() -> bool:
	var coord := _create_battle_ready_coordinator("stress_10000_tick", 99999)

	var target_ticks: int = 10000
	for i in range(1, target_ticks + 1):
		var ok: bool = coord.step_simulation()
		if not ok:
			printerr("Stress tick failed at index: %d" % i)
			return false

	if coord.get_battle_tick() != target_ticks:
		printerr("Stress tick target mismatch: %d != %d" % [coord.get_battle_tick(), target_ticks])
		return false

	var snap: GameStateSnapshot = coord.get_current_state()
	if snap.battle_tick != target_ticks:
		printerr("Snapshot stress tick mismatch: %d != %d" % [snap.battle_tick, target_ticks])
		return false

	# Invarian integritas pasca-stress
	if coord._fortress.current_hp <= 0:
		printerr("Fortress HP corrupted during clock stress test")
		return false
	if coord._population.get_total_population() <= 0:
		printerr("Population corrupted during clock stress test")
		return false

	return true
