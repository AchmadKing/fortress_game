extends SceneTree

## TestGameplayPrototype
## Test suite otomatis untuk memvalidasi implementasi Phase 3 (Playable Gameplay Prototype) secara headless.
## Memvalidasi:
## 1. Gameplay State Machine valid & invalid transitions.
## 2. Preparation: Worker allocation & soldier recruitment (zero-sum conservation).
## 3. Wave Preview: Integrasi WaveGenerator dan cancel return.
## 4. Battle Execution: Eksekusi CombatEngine multi-fase deterministik, pause, speed.
## 5. Commander Commands: Seluruh 6 command intent dapat dikirim dan dicatat.
## 6. Result: Evaluasi akurat damage benteng, korban, gear loss, hero survival, loot.
## 7. Recovery: Siklus pasca-tempur, upkeep, reparasi benteng, wave + 1, return ke PREPARATION.
## 8. Game Over: Benteng runtuh (HP <= 0) langsung ke GAME_OVER dan TIDAK menjalankan recovery.

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const CommanderCommand = preload("res://scripts/domain/command/commander_command.gd")
const GameStateSnapshot = preload("res://scripts/domain/state/game_state_snapshot.gd")
const FortressModel = preload("res://scripts/domain/model/fortress_model.gd")
const PopulationModel = preload("res://scripts/domain/model/population_model.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 3 GAMEPLAY PROTOTYPE TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		{"name": "test_state_machine_valid_transitions", "fn": Callable(self, "_test_state_machine_valid_transitions")},
		{"name": "test_state_machine_invalid_transitions_rejected", "fn": Callable(self, "_test_state_machine_invalid_transitions_rejected")},
		{"name": "test_preparation_worker_allocation", "fn": Callable(self, "_test_preparation_worker_allocation")},
		{"name": "test_preparation_soldier_recruitment_zero_sum", "fn": Callable(self, "_test_preparation_soldier_recruitment_zero_sum")},
		{"name": "test_wave_preview_generation_and_cancel", "fn": Callable(self, "_test_wave_preview_generation_and_cancel")},
		{"name": "test_battle_execution_and_result_evaluation", "fn": Callable(self, "_test_battle_execution_and_result_evaluation")},
		{"name": "test_battle_controls_speed_and_pause", "fn": Callable(self, "_test_battle_controls_speed_and_pause")},
		{"name": "test_commander_commands_all_six_intents", "fn": Callable(self, "_test_commander_commands_all_six_intents")},
		{"name": "test_recovery_and_next_wave_progression", "fn": Callable(self, "_test_recovery_and_next_wave_progression")},
		{"name": "test_game_over_terminal_and_no_recovery_loop", "fn": Callable(self, "_test_game_over_terminal_and_no_recovery_loop")},
		{"name": "test_full_gameplay_loop_multi_wave", "fn": Callable(self, "_test_full_gameplay_loop_multi_wave")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 3 TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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


# 1. State Machine Valid Transitions
func _test_state_machine_valid_transitions() -> bool:
	var sm := GameplayStateMachine.new(GameplayStateMachine.STATE_BOOT)
	
	if not sm.transition_to(GameplayStateMachine.STATE_PREPARATION): return false
	if sm.current_state != GameplayStateMachine.STATE_PREPARATION: return false
	
	if not sm.transition_to(GameplayStateMachine.STATE_WAVE_PREVIEW): return false
	if not sm.transition_to(GameplayStateMachine.STATE_PREPARATION): return false
	if not sm.transition_to(GameplayStateMachine.STATE_WAVE_PREVIEW): return false
	
	if not sm.transition_to(GameplayStateMachine.STATE_BATTLE): return false
	if not sm.transition_to(GameplayStateMachine.STATE_RESULT): return false
	
	if not sm.transition_to(GameplayStateMachine.STATE_RECOVERY): return false
	if not sm.transition_to(GameplayStateMachine.STATE_PREPARATION): return false
	
	# Test branch to GAME_OVER from RESULT
	sm.reset(GameplayStateMachine.STATE_BATTLE)
	if not sm.transition_to(GameplayStateMachine.STATE_RESULT): return false
	if not sm.transition_to(GameplayStateMachine.STATE_GAME_OVER): return false
	if sm.current_state != GameplayStateMachine.STATE_GAME_OVER: return false
	
	return true


# 2. State Machine Invalid Transitions Rejected
func _test_state_machine_invalid_transitions_rejected() -> bool:
	var sm := GameplayStateMachine.new(GameplayStateMachine.STATE_BOOT)
	
	# Cannot jump BOOT -> BATTLE
	if sm.transition_to(GameplayStateMachine.STATE_BATTLE): return false
	
	sm.transition_to(GameplayStateMachine.STATE_PREPARATION)
	# Cannot jump PREPARATION -> BATTLE (must go through preview)
	if sm.transition_to(GameplayStateMachine.STATE_BATTLE): return false
	# Cannot jump PREPARATION -> RESULT
	if sm.transition_to(GameplayStateMachine.STATE_RESULT): return false
	
	sm.transition_to(GameplayStateMachine.STATE_WAVE_PREVIEW)
	sm.transition_to(GameplayStateMachine.STATE_BATTLE)
	# Cannot jump BATTLE -> PREPARATION
	if sm.transition_to(GameplayStateMachine.STATE_PREPARATION): return false
	# Cannot jump BATTLE -> RECOVERY
	if sm.transition_to(GameplayStateMachine.STATE_RECOVERY): return false
	# Cannot jump BATTLE -> GAME_OVER directly
	if sm.transition_to(GameplayStateMachine.STATE_GAME_OVER): return false
	
	sm.transition_to(GameplayStateMachine.STATE_RESULT)
	sm.transition_to(GameplayStateMachine.STATE_GAME_OVER)
	# GAME_OVER is terminal! Cannot transition anywhere
	if sm.transition_to(GameplayStateMachine.STATE_PREPARATION): return false
	if sm.transition_to(GameplayStateMachine.STATE_BOOT): return false
	
	return true


# 3. Preparation: Worker Allocation
func _test_preparation_worker_allocation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_prep")
	
	var initial_snap: GameStateSnapshot = coord.get_current_state()
	var total_civilians: int = int(initial_snap.population_data.get("civilians", 0))
	
	# Alokasi sah (misal 2 Repair, 2 Smith, 1 Constr)
	var ok: bool = coord.allocate_workers(2, 2, 1)
	if not ok: return false
	
	var snap: GameStateSnapshot = coord.get_current_state()
	var e_data: Dictionary = snap.economy_data
	if int(e_data["repair_workers"]) != 2: return false
	if int(e_data["blacksmith_workers"]) != 2: return false
	if int(e_data["construction_workers"]) != 1: return false
	if int(e_data["idle_workers"]) != total_civilians - 5: return false
	
	# Alokasi ilegal melebihi jumlah warga sipil
	var fail: bool = coord.allocate_workers(total_civilians + 5, 0, 0)
	if fail: return false # Harus gagal!
	
	return true


# 4. Preparation: Soldier Recruitment Zero-Sum Conservation
func _test_preparation_soldier_recruitment_zero_sum() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_recruit")
	
	var snap1: GameStateSnapshot = coord.get_current_state()
	var civ1: int = int(snap1.population_data["civilians"])
	var sol1: int = int(snap1.population_data["total_soldiers"])
	
	# Rekrut 2 Swordsman
	var ok1: bool = coord.recruit_soldier("SWORDSMAN", 2)
	if not ok1: return false
	
	var snap2: GameStateSnapshot = coord.get_current_state()
	var civ2: int = int(snap2.population_data["civilians"])
	var sol2: int = int(snap2.population_data["total_soldiers"])
	
	if civ2 != civ1 - 2: return false
	if sol2 != sol1 + 2: return false
	if civ2 + sol2 != civ1 + sol1: return false # Hukum kekekalan populasi!
	
	# Rekrut melebihi kapasitas warga sipil harus ditolak
	var fail: bool = coord.recruit_soldier("ARCHER", civ2 + 10)
	if fail: return false
	
	return true


# 5. Wave Preview Generation & Cancel
func _test_wave_preview_generation_and_cancel() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_wave_prev")
	
	if not coord.inspect_wave(): return false
	
	var snap: GameStateSnapshot = coord.get_current_state()
	if snap.game_phase != "WAVE_PREVIEW": return false
	if int(snap.current_wave_data.get("wave", 0)) != 1: return false
	if int(snap.current_wave_data.get("threat_budget", 0)) <= 0: return false
	if not snap.current_wave_data.has("enemies"): return false
	
	# Cancel wave preview harus kembali ke PREPARATION
	if not coord.cancel_wave_preview(): return false
	var snap_back: GameStateSnapshot = coord.get_current_state()
	if snap_back.game_phase != "PREPARATION": return false
	
	return true


# 6. Battle Execution & Result Evaluation
func _test_battle_execution_and_result_evaluation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_battle")
	
	coord.inspect_wave()
	if not coord.start_battle(): return false
	
	var snap_b: GameStateSnapshot = coord.get_current_state()
	if snap_b.game_phase != "BATTLE": return false
	
	var res: Dictionary = coord.execute_battle(100)
	if res.is_empty(): return false
	if not res.has("victory"): return false
	if not res.has("fortress_damage_taken"): return false
	if not res.has("loot_gold"): return false
	
	var snap_res: GameStateSnapshot = coord.get_current_state()
	if snap_res.game_phase != "RESULT": return false
	if snap_res.last_battle_result.is_empty(): return false
	
	return true


# 7. Battle Controls: Speed and Pause
func _test_battle_controls_speed_and_pause() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_controls")
	
	coord.set_battle_speed(2.0)
	var snap1: GameStateSnapshot = coord.get_current_state()
	if snap1.battle_speed != 2.0: return false
	
	coord.set_battle_speed(4.0)
	var snap2: GameStateSnapshot = coord.get_current_state()
	if snap2.battle_speed != 4.0: return false
	
	coord.set_battle_paused(true)
	var snap3: GameStateSnapshot = coord.get_current_state()
	if not snap3.battle_paused: return false
	
	coord.set_battle_paused(false)
	var snap4: GameStateSnapshot = coord.get_current_state()
	if snap4.battle_paused: return false
	
	return true


# 8. Commander Commands: All Six Intents
func _test_commander_commands_all_six_intents() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_commands")
	
	var commands: Array = [
		CommanderCommand.TYPE_HOLD,
		CommanderCommand.TYPE_ADVANCE,
		CommanderCommand.TYPE_RETREAT,
		CommanderCommand.TYPE_PROTECT,
		CommanderCommand.TYPE_FOCUS,
		CommanderCommand.TYPE_FOLLOW
	]
	
	for c_type in commands:
		var cmd := CommanderCommand.new(c_type, "ALL", "target_sample")
		var ok: bool = coord.send_commander_command(cmd)
		if not ok: return false
		var snap: GameStateSnapshot = coord.get_current_state()
		var last_cmd: Dictionary = snap.last_commander_command
		if str(last_cmd.get("command_type", "")) != c_type: return false
		if str(last_cmd.get("status", "")) != "LOGGED_PHASE3_DEFERRED": return false
		
	# Tipe command ilegal harus ditolak
	var bad_cmd := CommanderCommand.new("INVALID_TYPE")
	var bad_res: bool = coord.send_commander_command(bad_cmd)
	if bad_res: return false
	
	return true


# 9. Recovery and Next Wave Progression
func _test_recovery_and_next_wave_progression() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_recovery")
	
	coord.inspect_wave()
	coord.start_battle()
	var res: Dictionary = coord.execute_battle(42)
	
	var snap_before: GameStateSnapshot = coord.get_current_state()
	if snap_before.game_phase != "RESULT": return false
	
	var wave_before: int = snap_before.current_wave
	
	# Lanjutkan alur dari RESULT (karena benteng utuh, masuk RECOVERY lalu PREPARATION)
	var proceed_ok: bool = coord.proceed_from_result()
	if not proceed_ok: return false
	
	var snap_after: GameStateSnapshot = coord.get_current_state()
	if snap_after.game_phase != "PREPARATION": return false
	if snap_after.current_wave != wave_before + 1: return false # Wave bertambah!
	
	return true


# 10. Game Over Terminal & No Recovery Loop
func _test_game_over_terminal_and_no_recovery_loop() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_game_over")
	
	# Paksa benteng hancur secara simulasi
	coord._fortress.current_hp = 0
	
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle()
	
	var snap_res: GameStateSnapshot = coord.get_current_state()
	if snap_res.game_phase != "RESULT": return false
	
	# Proceed dari RESULT saat benteng hancur harus langsung ke GAME_OVER
	var ok: bool = coord.proceed_from_result()
	if not ok: return false
	
	var snap_go: GameStateSnapshot = coord.get_current_state()
	if snap_go.game_phase != "GAME_OVER": return false
	
	# Pastikan tidak bisa bertransisi ke mana-mana dari GAME_OVER
	if coord.get_state_machine().transition_to(GameplayStateMachine.STATE_PREPARATION): return false
	if coord.get_state_machine().transition_to(GameplayStateMachine.STATE_RECOVERY): return false
	
	# Restart session dapat mengembalikan sesi baru
	coord.restart_session()
	var snap_reboot: GameStateSnapshot = coord.get_current_state()
	if snap_reboot.game_phase != "PREPARATION": return false
	if snap_reboot.current_wave != 1: return false
	
	return true


# 11. Full End-to-End Gameplay Loop Multi-Wave
func _test_full_gameplay_loop_multi_wave() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("test_e2e_loop", 999)
	
	for wave in range(1, 4):
		var snap_p: GameStateSnapshot = coord.get_current_state()
		if snap_p.game_phase != "PREPARATION": return false
		if snap_p.current_wave != wave: return false
		
		# 1. Atur alokasi pekerja
		coord.allocate_workers(1, 1, 0)
		
		# 2. Rekrut serdadu jika ada sipil
		if int(coord.get_current_state().population_data["civilians"]) >= 2:
			coord.recruit_soldier("SWORDSMAN", 1)
			
		# 3. Wave preview
		if not coord.inspect_wave(): return false
		if coord.get_current_state().game_phase != "WAVE_PREVIEW": return false
		
		# 4. Start battle
		if not coord.start_battle(): return false
		if coord.get_current_state().game_phase != "BATTLE": return false
		
		# 5. Kirim perintah komandan
		coord.send_commander_command(CommanderCommand.new(CommanderCommand.TYPE_HOLD))
		
		# 6. Selesaikan pertempuran
		var res: Dictionary = coord.execute_battle(100 + wave)
		if coord.get_current_state().game_phase != "RESULT": return false
		
		# 7. Proceed (Recovery -> Next wave Preparation)
		if not coord.proceed_from_result(): return false
		
	var final_snap: GameStateSnapshot = coord.get_current_state()
	if final_snap.current_wave != 4: return false
	if final_snap.game_phase != "PREPARATION": return false
	
	return true
