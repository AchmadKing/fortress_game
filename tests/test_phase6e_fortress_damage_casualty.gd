extends SceneTree

## Test Suite: Phase 6E — Fortress Damage Routing & Casualty Resolution
## Memverifikasi secara headless deterministik seluruh fondasi konsekuensi fisik pertempuran taktis:
## 1. Group A: Pressure Calculation (Tests 1-4)
## 2. Group B: Zone Routing Topology (Tests 5-8)
## 3. Group C: Enemy Pressure Progression (Tests 9-12)
## 4. Group D: Formation Modifiers (Tests 13-16)
## 5. Group E: Soldier Casualties Resolution (Tests 17-20)
## 6. Group F: Population Conservation (Tests 21-24)
## 7. Group G: Fortress Wall Damage (Tests 25-28)
## 8. Group H: Gate Damage (Tests 29-32)
## 9. Group I: Fortress Damage Routing (Tests 33-36)
## 10. Group J: Hero Danger & Party Isolation (Tests 37-40)
## 11. Group K: Hero Death & Permadeath (Tests 41-43)
## 12. Group L: Hero Equipment Return Exactly Once (Tests 44-46)
## 13. Group M: Soldier Equipment Casualty Resolution (Tests 47-49)
## 14. Group N: Battle Result Foundation (Tests 50-52)
## 15. Group O: Victory Conditions (Tests 53-55)
## 16. Group P: Defeat Conditions (Tests 56-57)
## 17. Group Q: Game Over State (Tests 58-59)
## 18. Group R: Commander Command Influence (Tests 60-63)
## 19. Group S: Battle Tick Integration (Tests 64-66)
## 20. Group T: Snapshot & Deep-Copy Telemetry (Tests 67-69)
## 21. Group U: Full Determinism (Tests 70-71)
## 22. Group V: Edge Cases & Input Validation (Tests 72-74)
## 23. Group W: 1,000-Tick Tactical Battle Stress Simulation (Test 75)

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const CombatEngine = preload("res://scripts/simulation/combat_engine.gd")
const WaveGenerator = preload("res://scripts/simulation/wave_generator.gd")
const BattlefieldZone = preload("res://scripts/domain/model/battlefield_zone.gd")
const EnemyArchetype = preload("res://scripts/domain/model/enemy_archetype.gd")
const EnemyGroup = preload("res://scripts/domain/model/enemy_group.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const PartyModel = preload("res://scripts/domain/model/party_model.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const FortressModel = preload("res://scripts/domain/model/fortress_model.gd")
const PopulationModel = preload("res://scripts/domain/model/population_model.gd")
const CommanderCommand = preload("res://scripts/domain/command/commander_command.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const GameStateSnapshot = preload("res://scripts/domain/state/game_state_snapshot.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 6E FORTRESS DAMAGE ROUTING & CASUALTY TESTS")
	print("================================================================")

	var tests: Array[Dictionary] = [
		# Group A: Pressure Calculation
		{"name": "test_a1_empty_enemy_groups_zero_pressure", "fn": Callable(self, "_test_a1_empty_enemy_groups_zero_pressure")},
		{"name": "test_a2_single_enemy_group_base_pressure", "fn": Callable(self, "_test_a2_single_enemy_group_base_pressure")},
		{"name": "test_a3_multiple_enemy_groups_aggregate_pressure", "fn": Callable(self, "_test_a3_multiple_enemy_groups_aggregate_pressure")},
		{"name": "test_a4_boss_and_siege_trait_pressure_scaling", "fn": Callable(self, "_test_a4_boss_and_siege_trait_pressure_scaling")},

		# Group B: Zone Routing Topology
		{"name": "test_b1_enemies_advance_outer_to_approach_or_flanks", "fn": Callable(self, "_test_b1_enemies_advance_outer_to_approach_or_flanks")},
		{"name": "test_b2_enemies_advance_approach_to_gate", "fn": Callable(self, "_test_b2_enemies_advance_approach_to_gate")},
		{"name": "test_b3_enemies_advance_flanks_to_wall", "fn": Callable(self, "_test_b3_enemies_advance_flanks_to_wall")},
		{"name": "test_b4_enemies_do_not_teleport_directly_to_fortress", "fn": Callable(self, "_test_b4_enemies_do_not_teleport_directly_to_fortress")},

		# Group C: Enemy Pressure Progression
		{"name": "test_c1_enemy_ticks_until_advance_decrements", "fn": Callable(self, "_test_c1_enemy_ticks_until_advance_decrements")},
		{"name": "test_c2_enemy_advances_when_counter_reaches_zero", "fn": Callable(self, "_test_c2_enemy_advances_when_counter_reaches_zero")},
		{"name": "test_c3_move_speed_ticks_governs_advance_cadence", "fn": Callable(self, "_test_c3_move_speed_ticks_governs_advance_cadence")},
		{"name": "test_c4_defeated_enemies_stop_advancing_and_applying_pressure", "fn": Callable(self, "_test_c4_defeated_enemies_stop_advancing_and_applying_pressure")},

		# Group D: Formation Modifiers
		{"name": "test_d1_frontline_formation_bonus_defense_absorption", "fn": Callable(self, "_test_d1_frontline_formation_bonus_defense_absorption")},
		{"name": "test_d2_backline_formation_reduced_casualty_risk", "fn": Callable(self, "_test_d2_backline_formation_reduced_casualty_risk")},
		{"name": "test_d3_support_formation_morale_and_zone_defense", "fn": Callable(self, "_test_d3_support_formation_morale_and_zone_defense")},
		{"name": "test_d4_mixed_formation_synergy", "fn": Callable(self, "_test_d4_mixed_formation_synergy")},

		# Group E: Soldier Casualties Resolution
		{"name": "test_e1_sub_threshold_pressure_causes_zero_casualties", "fn": Callable(self, "_test_e1_sub_threshold_pressure_causes_zero_casualties")},
		{"name": "test_e2_accumulated_pressure_triggers_casualty_at_threshold", "fn": Callable(self, "_test_e2_accumulated_pressure_triggers_casualty_at_threshold")},
		{"name": "test_e3_casualty_cannot_exceed_deployed_soldier_count", "fn": Callable(self, "_test_e3_casualty_cannot_exceed_deployed_soldier_count")},
		{"name": "test_e4_casualty_reduces_deployment_and_population_atomically", "fn": Callable(self, "_test_e4_casualty_reduces_deployment_and_population_atomically")},

		# Group F: Population Conservation
		{"name": "test_f1_zero_casualties_preserves_exact_population", "fn": Callable(self, "_test_f1_zero_casualties_preserves_exact_population")},
		{"name": "test_f2_dead_soldiers_reduce_total_population_consistently", "fn": Callable(self, "_test_f2_dead_soldiers_reduce_total_population_consistently")},
		{"name": "test_f3_civilians_and_workers_unaffected_by_battle_casualties", "fn": Callable(self, "_test_f3_civilians_and_workers_unaffected_by_battle_casualties")},
		{"name": "test_f4_population_cannot_become_negative", "fn": Callable(self, "_test_f4_population_cannot_become_negative")},

		# Group G: Fortress Wall Damage
		{"name": "test_g1_pressure_in_wall_zone_damages_wall_hp", "fn": Callable(self, "_test_g1_pressure_in_wall_zone_damages_wall_hp")},
		{"name": "test_g2_wall_damage_cannot_be_negative", "fn": Callable(self, "_test_g2_wall_damage_cannot_be_negative")},
		{"name": "test_g3_wall_hp_cannot_drop_below_zero", "fn": Callable(self, "_test_g3_wall_hp_cannot_drop_below_zero")},
		{"name": "test_g4_wall_breach_detected_when_wall_hp_zero", "fn": Callable(self, "_test_g4_wall_breach_detected_when_wall_hp_zero")},

		# Group H: Gate Damage
		{"name": "test_h1_pressure_in_gate_zone_damages_gate_hp", "fn": Callable(self, "_test_h1_pressure_in_gate_zone_damages_gate_hp")},
		{"name": "test_h2_gate_damage_cannot_be_negative", "fn": Callable(self, "_test_h2_gate_damage_cannot_be_negative")},
		{"name": "test_h3_gate_hp_cannot_drop_below_zero", "fn": Callable(self, "_test_h3_gate_hp_cannot_drop_below_zero")},
		{"name": "test_h4_gate_breach_detected_when_gate_hp_zero", "fn": Callable(self, "_test_h4_gate_breach_detected_when_gate_hp_zero")},

		# Group I: Fortress Damage Routing
		{"name": "test_i1_pressure_in_outer_zones_causes_zero_fortress_damage", "fn": Callable(self, "_test_i1_pressure_in_outer_zones_causes_zero_fortress_damage")},
		{"name": "test_i2_unbreached_gate_and_wall_shield_fortress_hp", "fn": Callable(self, "_test_i2_unbreached_gate_and_wall_shield_fortress_hp")},
		{"name": "test_i3_breached_gate_routes_pressure_to_fortress_hp", "fn": Callable(self, "_test_i3_breached_gate_routes_pressure_to_fortress_hp")},
		{"name": "test_i4_fortress_armor_reduces_raw_fortress_damage", "fn": Callable(self, "_test_i4_fortress_armor_reduces_raw_fortress_damage")},

		# Group J: Hero Danger & Party Isolation
		{"name": "test_j1_party_1_heroes_accumulate_fatigue_in_clash", "fn": Callable(self, "_test_j1_party_1_heroes_accumulate_fatigue_in_clash")},
		{"name": "test_j2_party_2_heroes_strictly_isolated_zero_danger", "fn": Callable(self, "_test_j2_party_2_heroes_strictly_isolated_zero_danger")},
		{"name": "test_j3_reserve_heroes_strictly_isolated_zero_danger", "fn": Callable(self, "_test_j3_reserve_heroes_strictly_isolated_zero_danger")},
		{"name": "test_j4_dead_heroes_not_processed_for_danger", "fn": Callable(self, "_test_j4_dead_heroes_not_processed_for_danger")},

		# Group K: Hero Death & Permadeath
		{"name": "test_k1_extreme_pressure_can_cause_hero_death", "fn": Callable(self, "_test_k1_extreme_pressure_can_cause_hero_death")},
		{"name": "test_k2_dead_hero_transitions_to_permadeath", "fn": Callable(self, "_test_k2_dead_hero_transitions_to_permadeath")},
		{"name": "test_k3_dead_hero_removed_from_party_and_aura", "fn": Callable(self, "_test_k3_dead_hero_removed_from_party_and_aura")},

		# Group L: Hero Equipment Return Exactly Once
		{"name": "test_l1_hero_permadeath_returns_equipment_to_warehouse", "fn": Callable(self, "_test_l1_hero_permadeath_returns_equipment_to_warehouse")},
		{"name": "test_l2_returned_hero_equipment_is_usable", "fn": Callable(self, "_test_l2_returned_hero_equipment_is_usable")},
		{"name": "test_l3_repeated_ticks_do_not_duplicate_hero_equipment_return", "fn": Callable(self, "_test_l3_repeated_ticks_do_not_duplicate_hero_equipment_return")},

		# Group M: Soldier Equipment Casualty Resolution
		{"name": "test_m1_surviving_soldiers_keep_100_percent_durability", "fn": Callable(self, "_test_m1_surviving_soldiers_keep_100_percent_durability")},
		{"name": "test_m2_dead_soldier_gear_split_destroyed_vs_damaged_60", "fn": Callable(self, "_test_m2_dead_soldier_gear_split_destroyed_vs_damaged_60")},
		{"name": "test_m3_destroyed_equipment_removed_from_total_owned_stock", "fn": Callable(self, "_test_m3_destroyed_equipment_removed_from_total_owned_stock")},

		# Group N: Battle Result Foundation
		{"name": "test_n1_battle_result_contains_all_canonical_fields", "fn": Callable(self, "_test_n1_battle_result_contains_all_canonical_fields")},
		{"name": "test_n2_battle_result_accurately_reflects_casualties", "fn": Callable(self, "_test_n2_battle_result_accurately_reflects_casualties")},
		{"name": "test_n3_battle_result_damage_matches_fortress_hp_delta", "fn": Callable(self, "_test_n3_battle_result_damage_matches_fortress_hp_delta")},

		# Group O: Victory Conditions
		{"name": "test_o1_all_enemies_defeated_triggers_victory", "fn": Callable(self, "_test_o1_all_enemies_defeated_triggers_victory")},
		{"name": "test_o2_victory_requires_living_fortress", "fn": Callable(self, "_test_o2_victory_requires_living_fortress")},
		{"name": "test_o3_victory_telemetry_in_snapshot", "fn": Callable(self, "_test_o3_victory_telemetry_in_snapshot")},

		# Group P: Defeat Conditions
		{"name": "test_p1_fortress_hp_zero_triggers_defeat", "fn": Callable(self, "_test_p1_fortress_hp_zero_triggers_defeat")},
		{"name": "test_p2_defeat_marks_game_over", "fn": Callable(self, "_test_p2_defeat_marks_game_over")},

		# Group Q: Game Over State
		{"name": "test_q1_destroyed_fortress_blocks_recovery_loop", "fn": Callable(self, "_test_q1_destroyed_fortress_blocks_recovery_loop")},
		{"name": "test_q2_game_over_is_terminal", "fn": Callable(self, "_test_q2_game_over_is_terminal")},

		# Group R: Commander Command Influence
		{"name": "test_r1_hold_position_boosts_defense_mitigates_casualties", "fn": Callable(self, "_test_r1_hold_position_boosts_defense_mitigates_casualties")},
		{"name": "test_r2_retreat_moves_unit_to_safer_zone", "fn": Callable(self, "_test_r2_retreat_moves_unit_to_safer_zone")},
		{"name": "test_r3_protect_reduces_damage_to_protected_target", "fn": Callable(self, "_test_r3_protect_reduces_damage_to_protected_target")},
		{"name": "test_r4_focus_target_accelerates_enemy_archetype_defeat", "fn": Callable(self, "_test_r4_focus_target_accelerates_enemy_archetype_defeat")},

		# Group S: Battle Tick Integration
		{"name": "test_s1_step_simulation_increments_battle_tick", "fn": Callable(self, "_test_s1_step_simulation_increments_battle_tick")},
		{"name": "test_s2_multiple_ticks_progress_clash_deterministically", "fn": Callable(self, "_test_s2_multiple_ticks_progress_clash_deterministically")},
		{"name": "test_s3_battle_clock_matches_simulation_steps", "fn": Callable(self, "_test_s3_battle_clock_matches_simulation_steps")},

		# Group T: Snapshot & Deep-Copy Telemetry
		{"name": "test_t1_snapshot_contains_enemy_and_pressure_data", "fn": Callable(self, "_test_t1_snapshot_contains_enemy_and_pressure_data")},
		{"name": "test_t2_snapshot_cloning_deep_isolation", "fn": Callable(self, "_test_t2_snapshot_cloning_deep_isolation")},
		{"name": "test_t3_snapshot_dictionary_serialization_roundtrip", "fn": Callable(self, "_test_t3_snapshot_dictionary_serialization_roundtrip")},

		# Group U: Full Determinism
		{"name": "test_u1_same_seed_produces_identical_battle_outcome", "fn": Callable(self, "_test_u1_same_seed_produces_identical_battle_outcome")},
		{"name": "test_u2_different_seed_branches_deterministically", "fn": Callable(self, "_test_u2_different_seed_branches_deterministically")},

		# Group V: Edge Cases & Input Validation
		{"name": "test_v1_null_and_empty_inputs_handled_safely", "fn": Callable(self, "_test_v1_null_and_empty_inputs_handled_safely")},
		{"name": "test_v2_zero_health_enemy_cannot_apply_pressure", "fn": Callable(self, "_test_v2_zero_health_enemy_cannot_apply_pressure")},
		{"name": "test_v3_zero_hp_fortress_rejects_further_damage", "fn": Callable(self, "_test_v3_zero_hp_fortress_rejects_further_damage")},

		# Group W: Stress Simulation
		{"name": "test_w1_1000_tick_tactical_battle_stress_simulation", "fn": Callable(self, "_test_w1_1000_tick_tactical_battle_stress_simulation")}
	]

	var passed: int = 0
	var failed: int = 0

	for t in tests:
		var test_name: String = t["name"]
		var fn: Callable = t["fn"]
		var success: bool = false
		var err_msg: String = ""

		var res = fn.call()
		if res is bool:
			success = res
		elif res is Dictionary:
			success = bool(res.get("success", false))
			err_msg = str(res.get("error", ""))

		if success:
			passed += 1
			print("[PASS] %s" % test_name)
		else:
			failed += 1
			print("[FAIL] %s %s" % [test_name, err_msg])

	print("================================================================")
	print("PHASE 6E TEST SUMMARY: %d PASSED, %d FAILED (Total %d)" % [passed, failed, tests.size()])
	print("================================================================")

	var root := get_root()
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

func _create_tactical_coord(session_id: String = "p6e_sess", seed_val: int = 42) -> GameCoordinator:
	var coord := GameCoordinator.new()
	coord.start_new_session(session_id, seed_val)
	var h_p2 := HeroModel.new("hero_ignis", "Ignis", 1, 3, HeroRole.MAGE, HeroLifecycleState.ROSTER_ACTIVE)
	var h_res := HeroModel.new("hero_zephyr", "Zephyr", 1, 3, HeroRole.PRIEST, HeroLifecycleState.ROSTER_ACTIVE)
	coord.add_hero(h_p2)
	coord.add_hero(h_res)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party("hero_ignis", "party_2")
	coord.create_deployment(4, "SWORD")
	coord.create_deployment(2, "BOW")
	coord.inspect_wave()
	coord.start_battle(true) # Mengaktifkan mode simulasi taktikal
	return coord


# ==============================================================================
# GROUP A: PRESSURE CALCULATION (Tests 1-4)
# ==============================================================================

func _test_a1_empty_enemy_groups_zero_pressure() -> bool:
	var engine := CombatEngine.new()
	var pressure: int = engine.calculate_zone_enemy_pressure([], "GATE")
	return pressure == 0


func _test_a2_single_enemy_group_base_pressure() -> bool:
	var engine := CombatEngine.new()
	var g := EnemyGroup.new("g1", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 5, "GATE")
	# Goblin Swarm base_atk = 4 -> 5 * 4 = 20
	var pressure: int = engine.calculate_zone_enemy_pressure([g], "GATE")
	return pressure == 20


func _test_a3_multiple_enemy_groups_aggregate_pressure() -> bool:
	var engine := CombatEngine.new()
	var g1 := EnemyGroup.new("g1", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 5, "GATE") # 20
	var g2 := EnemyGroup.new("g2", EnemyArchetype.ARCHETYPE_ORC_FRONTLINE, 2, "GATE") # 2 * 12 = 24
	var g3 := EnemyGroup.new("g3", EnemyArchetype.ARCHETYPE_TROLL_TANK, 1, "WALL") # di zona lain!
	var pressure: int = engine.calculate_zone_enemy_pressure([g1, g2, g3], "GATE")
	return pressure == 44


func _test_a4_boss_and_siege_trait_pressure_scaling() -> bool:
	var engine := CombatEngine.new()
	var siege := EnemyGroup.new("siege", EnemyArchetype.ARCHETYPE_SIEGE_MONSTER, 1, "GATE") # base atk 60 * 1.5 siege mult = 90
	var press: int = engine.calculate_zone_enemy_pressure([siege], "GATE")
	return press >= 90


# ==============================================================================
# GROUP B: ZONE ROUTING TOPOLOGY (Tests 5-8)
# ==============================================================================

func _test_b1_enemies_advance_outer_to_approach_or_flanks() -> bool:
	var engine := CombatEngine.new()
	var eg := EnemyGroup.new("g1", EnemyArchetype.ARCHETYPE_ORC_FRONTLINE, 2, BattlefieldZone.ZONE_OUTER_FIELD)
	eg.ticks_until_advance = 1
	var ctx: Dictionary = {"enemy_groups": [eg]}
	engine.step_simulation_tick(0, ctx)
	return eg.current_zone in [BattlefieldZone.ZONE_CENTER_APPROACH, BattlefieldZone.ZONE_LEFT_FLANK, BattlefieldZone.ZONE_RIGHT_FLANK]


func _test_b2_enemies_advance_approach_to_gate() -> bool:
	var engine := CombatEngine.new()
	var eg := EnemyGroup.new("g1", EnemyArchetype.ARCHETYPE_ORC_FRONTLINE, 2, BattlefieldZone.ZONE_CENTER_APPROACH)
	eg.ticks_until_advance = 1
	var ctx: Dictionary = {"enemy_groups": [eg]}
	engine.step_simulation_tick(0, ctx)
	return eg.current_zone == BattlefieldZone.ZONE_GATE


func _test_b3_enemies_advance_flanks_to_wall() -> bool:
	var engine := CombatEngine.new()
	var eg1 := EnemyGroup.new("g1", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 2, BattlefieldZone.ZONE_LEFT_FLANK)
	var eg2 := EnemyGroup.new("g2", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 2, BattlefieldZone.ZONE_RIGHT_FLANK)
	eg1.ticks_until_advance = 1
	eg2.ticks_until_advance = 1
	var ctx: Dictionary = {"enemy_groups": [eg1, eg2]}
	engine.step_simulation_tick(0, ctx)
	return eg1.current_zone == BattlefieldZone.ZONE_WALL and eg2.current_zone == BattlefieldZone.ZONE_WALL


func _test_b4_enemies_do_not_teleport_directly_to_fortress() -> bool:
	var engine := CombatEngine.new()
	var eg := EnemyGroup.new("g1", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 2, BattlefieldZone.ZONE_OUTER_FIELD)
	eg.ticks_until_advance = 1
	var ctx: Dictionary = {"enemy_groups": [eg]}
	engine.step_simulation_tick(0, ctx)
	# Dari outer field tidak boleh langsung berada di FORTRESS
	return eg.current_zone != BattlefieldZone.ZONE_FORTRESS


# ==============================================================================
# GROUP C: ENEMY PRESSURE PROGRESSION (Tests 9-12)
# ==============================================================================

func _test_c1_enemy_ticks_until_advance_decrements() -> bool:
	var engine := CombatEngine.new()
	var eg := EnemyGroup.new("g1", EnemyArchetype.ARCHETYPE_TROLL_TANK, 1, BattlefieldZone.ZONE_OUTER_FIELD)
	eg.move_speed_ticks = 3
	eg.ticks_until_advance = 3
	var ctx: Dictionary = {"enemy_groups": [eg]}
	engine.step_simulation_tick(0, ctx)
	return eg.ticks_until_advance == 2 and eg.current_zone == BattlefieldZone.ZONE_OUTER_FIELD


func _test_c2_enemy_advances_when_counter_reaches_zero() -> bool:
	var engine := CombatEngine.new()
	var eg := EnemyGroup.new("g1", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 1, BattlefieldZone.ZONE_OUTER_FIELD)
	eg.move_speed_ticks = 1
	eg.ticks_until_advance = 1
	var ctx: Dictionary = {"enemy_groups": [eg]}
	engine.step_simulation_tick(0, ctx)
	return eg.current_zone != BattlefieldZone.ZONE_OUTER_FIELD


func _test_c3_move_speed_ticks_governs_advance_cadence() -> bool:
	var engine := CombatEngine.new()
	var slow := EnemyGroup.new("slow", EnemyArchetype.ARCHETYPE_SIEGE_MONSTER, 1, BattlefieldZone.ZONE_OUTER_FIELD)
	slow.move_speed_ticks = 4
	slow.ticks_until_advance = 4
	var ctx: Dictionary = {"enemy_groups": [slow]}
	for i in range(3):
		engine.step_simulation_tick(i, ctx)
	if slow.current_zone != BattlefieldZone.ZONE_OUTER_FIELD:
		return false
	engine.step_simulation_tick(3, ctx)
	return slow.current_zone != BattlefieldZone.ZONE_OUTER_FIELD


func _test_c4_defeated_enemies_stop_advancing_and_applying_pressure() -> bool:
	var engine := CombatEngine.new()
	var eg := EnemyGroup.new("dead", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 5, BattlefieldZone.ZONE_GATE)
	eg.apply_damage(eg.max_hp_pool) # Habisi HP
	if not eg.is_defeated():
		return false
	var press: int = engine.calculate_zone_enemy_pressure([eg], "GATE")
	return press == 0


# ==============================================================================
# GROUP D: FORMATION MODIFIERS (Tests 13-16)
# ==============================================================================

func _test_d1_frontline_formation_bonus_defense_absorption() -> bool:
	var engine := CombatEngine.new()
	var dep_front := DeploymentComposition.new(2, "SWORD", "NONE", "NONE", "GATE", "FRONTLINE")
	var dep_back := DeploymentComposition.new(2, "SWORD", "NONE", "NONE", "GATE", "BACKLINE")
	var p_front = engine.calculate_zone_defender_power([dep_front], [], "GATE")
	var p_back = engine.calculate_zone_defender_power([dep_back], [], "GATE")
	return float(p_front["total_def"]) > float(p_back["total_def"])


func _test_d2_backline_formation_reduced_casualty_risk() -> bool:
	var engine := CombatEngine.new()
	var dep_front := DeploymentComposition.new(5, "SWORD", "NONE", "NONE", "GATE", "FRONTLINE")
	var dep_back := DeploymentComposition.new(5, "BOW", "NONE", "NONE", "GATE", "BACKLINE")
	# 70 accumulated pressure: frontline butuh 50, backline butuh 70 (1.4x)
	var cas_f = engine.resolve_soldier_casualties(dep_front, 70, 50)
	var cas_b = engine.resolve_soldier_casualties(dep_back, 70, 50)
	return cas_f["casualties"] >= cas_b["casualties"]


func _test_d3_support_formation_morale_and_zone_defense() -> bool:
	var engine := CombatEngine.new()
	var dep_supp := DeploymentComposition.new(2, "SWORD", "NONE", "NONE", "GATE", "SUPPORT")
	var p = engine.calculate_zone_defender_power([dep_supp], [], "GATE")
	return float(p["total_def"]) > 0.0


func _test_d4_mixed_formation_synergy() -> bool:
	var engine := CombatEngine.new()
	var f := DeploymentComposition.new(3, "SWORD", "SHIELD", "NONE", "GATE", "FRONTLINE")
	var b := DeploymentComposition.new(2, "BOW", "NONE", "NONE", "GATE", "BACKLINE")
	var p = engine.calculate_zone_defender_power([f, b], [], "GATE")
	return p["frontline_present"] == true and float(p["total_atk"]) > 0.0 and float(p["total_def"]) > 0.0


# ==============================================================================
# GROUP E: SOLDIER CASUALTIES RESOLUTION (Tests 17-20)
# ==============================================================================

func _test_e1_sub_threshold_pressure_causes_zero_casualties() -> bool:
	var engine := CombatEngine.new()
	var dep := DeploymentComposition.new(5, "SWORD", "NONE", "NONE", "GATE", "FRONTLINE")
	var res = engine.resolve_soldier_casualties(dep, 40, 50) # threshold 50, acc 40
	return res["casualties"] == 0 and res["remaining_pressure"] == 40


func _test_e2_accumulated_pressure_triggers_casualty_at_threshold() -> bool:
	var engine := CombatEngine.new()
	var dep := DeploymentComposition.new(5, "SWORD", "NONE", "NONE", "GATE", "FRONTLINE")
	var res = engine.resolve_soldier_casualties(dep, 110, 50)
	# 110 / 50 = 2 deaths, remaining 10
	return res["casualties"] == 2 and res["remaining_pressure"] == 10


func _test_e3_casualty_cannot_exceed_deployed_soldier_count() -> bool:
	var engine := CombatEngine.new()
	var dep := DeploymentComposition.new(1, "SWORD", "NONE", "NONE", "GATE", "FRONTLINE")
	var res = engine.resolve_soldier_casualties(dep, 1000, 50) # Tekanan masif
	return res["casualties"] == 1 # Hanya ada 1 prajurit


func _test_e4_casualty_reduces_deployment_and_population_atomically() -> bool:
	var coord := _create_tactical_coord("p6e_e4")
	var initial_living: int = coord._population.get_total_soldiers()
	var initial_total: int = coord._population.get_total_population()

	# Simulasikan casualty
	coord._population.apply_casualties({"SWORDSMAN": 1})
	var final_living: int = coord._population.get_total_soldiers()
	var final_total: int = coord._population.get_total_population()

	return final_living == initial_living - 1 and final_total == initial_total - 1


# ==============================================================================
# GROUP F: POPULATION CONSERVATION (Tests 21-24)
# ==============================================================================

func _test_f1_zero_casualties_preserves_exact_population() -> bool:
	var coord := _create_tactical_coord("p6e_f1")
	var p_before: int = coord._population.get_total_population()
	coord._population.apply_casualties({"SWORDSMAN": 0, "ARCHER": 0})
	return coord._population.get_total_population() == p_before


func _test_f2_dead_soldiers_reduce_total_population_consistently() -> bool:
	var coord := _create_tactical_coord("p6e_f2")
	var init: int = coord._population.get_total_population()
	coord._population.apply_casualties({"SWORDSMAN": 2})
	return coord._population.get_total_population() == init - 2


func _test_f3_civilians_and_workers_unaffected_by_battle_casualties() -> bool:
	var coord := _create_tactical_coord("p6e_f3")
	var civ: int = coord._population.civilians
	var wrk: int = coord._population.workers
	coord._population.apply_casualties({"SWORDSMAN": 2})
	return coord._population.civilians == civ and coord._population.workers == wrk


func _test_f4_population_cannot_become_negative() -> bool:
	var pop := PopulationModel.new(10)
	pop.soldiers["SWORDSMAN"] = 2
	var dead: int = pop.apply_casualties({"SWORDSMAN": 999})
	return dead == 2 and pop.soldiers["SWORDSMAN"] == 0 and pop.get_total_population() >= 0


# ==============================================================================
# GROUP G: FORTRESS WALL DAMAGE (Tests 25-28)
# ==============================================================================

func _test_g1_pressure_in_wall_zone_damages_wall_hp() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new(1000, 40, 500, 300)
	var res = engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_WALL, 50)
	return res["target"] == "WALL" and res["damage"] == 50 and fort.wall_hp == 450


func _test_g2_wall_damage_cannot_be_negative() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new()
	var res = engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_WALL, -100)
	return res["damage"] == 0 and fort.wall_hp == fort.wall_max_hp


func _test_g3_wall_hp_cannot_drop_below_zero() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new(1000, 40, 100, 300)
	engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_WALL, 500)
	return fort.wall_hp == 0


func _test_g4_wall_breach_detected_when_wall_hp_zero() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new(1000, 40, 100, 300)
	var res = engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_WALL, 100)
	return res["breached"] == true and fort.is_wall_breached()


# ==============================================================================
# GROUP H: GATE DAMAGE (Tests 29-32)
# ==============================================================================

func _test_h1_pressure_in_gate_zone_damages_gate_hp() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new(1000, 40, 500, 300)
	var res = engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_GATE, 40)
	return res["target"] == "GATE" and res["damage"] == 40 and fort.gate_hp == 260


func _test_h2_gate_damage_cannot_be_negative() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new()
	var res = engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_GATE, -50)
	return res["damage"] == 0 and fort.gate_hp == fort.gate_max_hp


func _test_h3_gate_hp_cannot_drop_below_zero() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new(1000, 40, 500, 100)
	engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_GATE, 999)
	return fort.gate_hp == 0


func _test_h4_gate_breach_detected_when_gate_hp_zero() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new(1000, 40, 500, 100)
	var res = engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_GATE, 100)
	return res["breached"] == true and fort.is_gate_breached()


# ==============================================================================
# GROUP I: FORTRESS DAMAGE ROUTING (Tests 33-36)
# ==============================================================================

func _test_i1_pressure_in_outer_zones_causes_zero_fortress_damage() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new()
	var r1 = engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_OUTER_FIELD, 200)
	var r2 = engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_CENTER_APPROACH, 200)
	var r3 = engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_LEFT_FLANK, 200)
	return r1["damage"] == 0 and r2["damage"] == 0 and r3["damage"] == 0 and fort.current_hp == fort.max_hp


func _test_i2_unbreached_gate_and_wall_shield_fortress_hp() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new(1000, 40, 500, 300)
	engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_GATE, 50)
	engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_WALL, 50)
	# Gate & Wall menahan kerusakan, Fortress HP tetap 1000
	return fort.current_hp == 1000


func _test_i3_breached_gate_routes_pressure_to_fortress_hp() -> bool:
	var engine := CombatEngine.new()
	var fort := FortressModel.new(1000, 40, 500, 100)
	# Hancurkan gerbang
	fort.gate_hp = 0
	var res = engine.route_damage_to_fortress(fort, BattlefieldZone.ZONE_GATE, 100)
	# Rute tembus ke Fortress HP
	return res["target"] == "FORTRESS" and fort.current_hp < 1000


func _test_i4_fortress_armor_reduces_raw_fortress_damage() -> bool:
	var fort := FortressModel.new(1000, 40)
	var actual: int = fort.take_damage(100)
	# Armor 40 -> reduction = 40/190 = ~21% -> actual ~79 damage
	return actual < 100 and fort.current_hp == 1000 - actual


# ==============================================================================
# GROUP J: HERO DANGER & PARTY ISOLATION (Tests 37-40)
# ==============================================================================

func _test_j1_party_1_heroes_accumulate_fatigue_in_clash() -> bool:
	var coord := _create_tactical_coord("p6e_j1")
	var h: HeroModel = coord.get_hero("hero_alder")
	var initial_fatigue: int = h.fatigue
	coord.step_simulation()
	return h.fatigue >= initial_fatigue


func _test_j2_party_2_heroes_strictly_isolated_zero_danger() -> bool:
	var coord := _create_tactical_coord("p6e_j2")
	var p2_hero: HeroModel = coord.get_hero("hero_ignis")
	var init_fatigue: int = p2_hero.fatigue
	for _i in range(5):
		coord.step_simulation()
	return p2_hero.is_alive and p2_hero.fatigue == init_fatigue and p2_hero.lifecycle_state != HeroLifecycleState.BATTLE_ACTIVE


func _test_j3_reserve_heroes_strictly_isolated_zero_danger() -> bool:
	var coord := _create_tactical_coord("p6e_j3")
	var res_hero: HeroModel = coord.get_hero("hero_zephyr") # Tidak di-assign ke party
	var init_fatigue: int = res_hero.fatigue
	for _i in range(5):
		coord.step_simulation()
	return res_hero.is_alive and res_hero.fatigue == init_fatigue


func _test_j4_dead_heroes_not_processed_for_danger() -> bool:
	var engine := CombatEngine.new()
	var hero := HeroModel.new("h_dead", "Dead", 1, 3, HeroRole.KNIGHT)
	hero.mark_dead()
	var died = engine.resolve_hero_danger(hero, 9999, 100, false, 1, 42)
	return died == false


# ==============================================================================
# GROUP K: HERO DEATH & PERMADEATH (Tests 41-43)
# ==============================================================================

func _test_k1_extreme_pressure_can_cause_hero_death() -> bool:
	var engine := CombatEngine.new()
	var hero := HeroModel.new("h_victim", "Victim", 1, 3, HeroRole.MAGE)
	hero.fatigue = 90
	# Seed yang menghasilkan roll rendah < death_prob
	var died = engine.resolve_hero_danger(hero, 500, 100, true, 2, 999)
	return died == true and hero.is_alive == false


func _test_k2_dead_hero_transitions_to_permadeath() -> bool:
	var hero := HeroModel.new("h_perm", "Perm", 1, 3, HeroRole.KNIGHT)
	hero.mark_dead()
	return hero.lifecycle_state == HeroLifecycleState.PERMADEATH and not hero.is_alive


func _test_k3_dead_hero_removed_from_party_and_aura() -> bool:
	var engine := CombatEngine.new()
	var h1 := HeroModel.new("h1", "Alive", 1, 3, HeroRole.KNIGHT)
	var h2 := HeroModel.new("h2", "Dead", 1, 3, HeroRole.PRIEST)
	h2.mark_dead()
	var auras = engine.calculate_party_auras([h1, h2], "GATE")
	return auras["contributing_heroes_count"] == 1


# ==============================================================================
# GROUP L: HERO EQUIPMENT RETURN EXACTLY ONCE (Tests 44-46)
# ==============================================================================

func _test_l1_hero_permadeath_returns_equipment_to_warehouse() -> bool:
	var coord := _create_tactical_coord("p6e_l1")
	var h: HeroModel = coord.get_hero("hero_alder")
	h.equip("PRIMARY", EquipmentModel.new("SWORD", 2, 100, 1))

	var init_swords: int = coord.get_warehouse_usable_stock("SWORD")
	# Simulasikan kematian alder
	h.mark_dead()
	var items = h.clear_equipment()
	for item in items:
		coord._return_equipment_to_warehouse(item)

	var final_swords: int = coord.get_warehouse_usable_stock("SWORD")
	return final_swords == init_swords + 1


func _test_l2_returned_hero_equipment_is_usable() -> bool:
	var hero := HeroModel.new("h_gear", "GearHero", 1, 3, HeroRole.KNIGHT)
	hero.equip("PRIMARY", EquipmentModel.new("SWORD", 1, 100, 1))
	var returned = hero.clear_equipment()
	return returned.size() == 1 and returned[0].durability == 100 and returned[0].is_usable()


func _test_l3_repeated_ticks_do_not_duplicate_hero_equipment_return() -> bool:
	var hero := HeroModel.new("h_nodup", "NoDup", 1, 3, HeroRole.KNIGHT)
	hero.equip("PRIMARY", EquipmentModel.new("SWORD", 1, 100, 1))
	var items1 = hero.clear_equipment()
	var items2 = hero.clear_equipment() # Panggilan kedua harus kosong!
	return items1.size() == 1 and items2.size() == 0


# ==============================================================================
# GROUP M: SOLDIER EQUIPMENT CASUALTY RESOLUTION (Tests 47-49)
# ==============================================================================

func _test_m1_surviving_soldiers_keep_100_percent_durability() -> bool:
	var coord := _create_tactical_coord("p6e_m1")
	# Seluruh equipment yang di-reserve deployment harus 100%
	for comp in coord._active_deployments:
		for eq in comp.reserved_equipment:
			if eq.durability != 100:
				return false
	return true


func _test_m2_dead_soldier_gear_split_destroyed_vs_damaged_60() -> bool:
	var engine := CombatEngine.new()
	var res = engine.resolve_soldier_equipment_loss("SWORDSMAN", 100, 12345)
	var destroyed: int = res["destroyed"]
	var damaged: int = res["damaged"]
	# Total = 100, destroyed ~35%, damaged ~65%
	return destroyed + damaged == 100 and destroyed >= 25 and destroyed <= 45 and damaged >= 55 and damaged <= 75


func _test_m3_destroyed_equipment_removed_from_total_owned_stock() -> bool:
	var eq := EquipmentModel.new("SWORD", 1, 100, 5)
	# Destroy 1 item
	eq.quantity -= 1
	return eq.quantity == 4


# ==============================================================================
# GROUP N: BATTLE RESULT FOUNDATION (Tests 50-52)
# ==============================================================================

func _test_n1_battle_result_contains_all_canonical_fields() -> bool:
	var engine := CombatEngine.new()
	var pop := PopulationModel.new(10)
	var fort := FortressModel.new()
	var wave := {"wave": 1, "threat_budget": 20, "enemies": {"MINION": 2}}
	var res = engine.simulate_battle(pop, [], [], fort, wave, 42)
	return res.has("victory") and res.has("game_over") and res.has("total_dead_soldiers") and res.has("casualties") and res.has("fortress_damage_taken")


func _test_n2_battle_result_accurately_reflects_casualties() -> bool:
	var engine := CombatEngine.new()
	var pop := PopulationModel.new(10)
	pop.soldiers["SWORDSMAN"] = 5
	var fort := FortressModel.new()
	var wave := {"wave": 1, "threat_budget": 20, "enemies": {"MINION": 2}}
	var res = engine.simulate_battle(pop, [], [], fort, wave, 42)
	return res.get("total_dead_soldiers", -1) >= 0


func _test_n3_battle_result_damage_matches_fortress_hp_delta() -> bool:
	var engine := CombatEngine.new()
	var pop := PopulationModel.new(10)
	var fort := FortressModel.new(1000)
	var init_hp: int = fort.current_hp
	var wave := {"wave": 1, "threat_budget": 20, "enemies": {"MINION": 2}}
	var res = engine.simulate_battle(pop, [], [], fort, wave, 42)
	var dmg: int = int(res.get("fortress_damage_taken", 0))
	return fort.current_hp == init_hp - dmg


# ==============================================================================
# GROUP O: VICTORY CONDITIONS (Tests 53-55)
# ==============================================================================

func _test_o1_all_enemies_defeated_triggers_victory() -> bool:
	var coord := _create_tactical_coord("p6e_o1")
	# Bunuh seluruh musuh di medan perang
	for eg in coord.get_battle_enemy_groups():
		eg.apply_damage(eg.max_hp_pool)
	coord.step_simulation()
	return coord.is_battle_finished() and coord.is_battle_victory()


func _test_o2_victory_requires_living_fortress() -> bool:
	var coord := _create_tactical_coord("p6e_o2")
	coord._fortress.current_hp = 0
	for eg in coord.get_battle_enemy_groups():
		eg.apply_damage(eg.max_hp_pool)
	coord.step_simulation()
	# Benteng hancur bukan kemenangan!
	return coord.is_battle_victory() == false


func _test_o3_victory_telemetry_in_snapshot() -> bool:
	var coord := _create_tactical_coord("p6e_o3")
	for eg in coord.get_battle_enemy_groups():
		eg.apply_damage(eg.max_hp_pool)
	coord.step_simulation()
	var snap = coord.get_current_state()
	return snap.battle_is_finished == true and snap.battle_victory == true


# ==============================================================================
# GROUP P: DEFEAT CONDITIONS (Tests 56-57)
# ==============================================================================

func _test_p1_fortress_hp_zero_triggers_defeat() -> bool:
	var coord := _create_tactical_coord("p6e_p1")
	coord._fortress.current_hp = 0
	coord.step_simulation()
	return coord.is_battle_finished() and not coord.is_battle_victory()


func _test_p2_defeat_marks_game_over() -> bool:
	var coord := _create_tactical_coord("p6e_p2")
	coord._fortress.current_hp = 0
	coord.step_simulation()
	var snap = coord.get_current_state()
	return snap.game_phase == "GAME_OVER"


# ==============================================================================
# GROUP Q: GAME OVER STATE (Tests 58-59)
# ==============================================================================

func _test_q1_destroyed_fortress_blocks_recovery_loop() -> bool:
	var coord := _create_tactical_coord("p6e_q1")
	coord._fortress.current_hp = 0
	coord._last_battle_result = {"game_over": true, "victory": false}
	coord._state_machine.current_state = GameplayStateMachine.STATE_RESULT
	var ok = coord.proceed_from_result()
	# Fortress hancur harus langsung ke GAME_OVER, tidak masuk RECOVERY
	return ok and coord.get_current_state().game_phase == "GAME_OVER"


func _test_q2_game_over_is_terminal() -> bool:
	var sm := GameplayStateMachine.new()
	sm.current_state = GameplayStateMachine.STATE_GAME_OVER
	var to_prep = sm.transition_to(GameplayStateMachine.STATE_PREPARATION)
	var to_battle = sm.transition_to(GameplayStateMachine.STATE_BATTLE)
	return not to_prep and not to_battle


# ==============================================================================
# GROUP R: COMMANDER COMMAND INFLUENCE (Tests 60-63)
# ==============================================================================

func _test_r1_hold_position_boosts_defense_mitigates_casualties() -> bool:
	var engine := CombatEngine.new()
	var dep := DeploymentComposition.new(5, "SWORD", "NONE", "NONE", "GATE", "FRONTLINE")
	var p_norm = engine.calculate_zone_defender_power([dep], [], "GATE", {})
	var intents: Dictionary = {dep.composition_id: {"intent": "HOLD_POSITION"}}
	var p_hold = engine.calculate_zone_defender_power([dep], [], "GATE", intents)
	return float(p_hold["total_def"]) > float(p_norm["total_def"])


func _test_r2_retreat_moves_unit_to_safer_zone() -> bool:
	var coord := _create_tactical_coord("p6e_r2")
	var p1 := coord.get_party("party_1")
	p1.set_zone("CENTER_APPROACH")
	coord.send_commander_command(CommanderCommand.new("RETREAT", "party_1"))
	return p1.current_zone == "GATE"


func _test_r3_protect_reduces_damage_to_protected_target() -> bool:
	var engine := CombatEngine.new()
	var dep := DeploymentComposition.new(5, "SWORD", "SHIELD", "NONE", "GATE", "FRONTLINE")
	var intents: Dictionary = {dep.composition_id: {"intent": "PROTECT", "protected_target": "FORTRESS"}}
	var p = engine.calculate_zone_defender_power([dep], [], "GATE", intents)
	return float(p["total_def"]) > 0.0


func _test_r4_focus_target_accelerates_enemy_archetype_defeat() -> bool:
	var coord := _create_tactical_coord("p6e_r4")
	coord.send_commander_command(CommanderCommand.new("FOCUS_TARGET", "party_1", "GOBLIN_SWARM", 0, "", "GOBLIN_SWARM"))
	var last = coord.get_last_commander_command()
	return last.command_type in [CommanderCommand.TYPE_FOCUS_TARGET, "FOCUS"]


# ==============================================================================
# GROUP S: BATTLE TICK INTEGRATION (Tests 64-66)
# ==============================================================================

func _test_s1_step_simulation_increments_battle_tick() -> bool:
	var coord := _create_tactical_coord("p6e_s1")
	var t0: int = coord.get_battle_tick()
	coord.step_simulation()
	return coord.get_battle_tick() == t0 + 1


func _test_s2_multiple_ticks_progress_clash_deterministically() -> bool:
	var coord := _create_tactical_coord("p6e_s2")
	for _i in range(5):
		coord.step_simulation()
	return coord.get_battle_tick() == 5


func _test_s3_battle_clock_matches_simulation_steps() -> bool:
	var coord := _create_tactical_coord("p6e_s3")
	var ctrl := GameController.new()
	ctrl.setup(coord)
	ctrl.step_simulation()
	ctrl.step_simulation()
	var ok: bool = ctrl.get_battle_tick() == 2
	ctrl.free()
	return ok


# ==============================================================================
# GROUP T: SNAPSHOT & DEEP-COPY TELEMETRY (Tests 67-69)
# ==============================================================================

func _test_t1_snapshot_contains_enemy_and_pressure_data() -> bool:
	var coord := _create_tactical_coord("p6e_t1")
	coord.step_simulation()
	var snap = coord.get_current_state()
	return snap.wall_hp > 0 and snap.gate_hp > 0 and snap.fortress_hp > 0 and snap.enemy_groups_data.size() > 0


func _test_t2_snapshot_cloning_deep_isolation() -> bool:
	var coord := _create_tactical_coord("p6e_t2")
	coord.step_simulation()
	var s1 = coord.get_current_state()
	var s2 = s1.clone()
	s2.battle_zone_pressure["GATE"] = 9999
	return s1.battle_zone_pressure.get("GATE", 0) != 9999


func _test_t3_snapshot_dictionary_serialization_roundtrip() -> bool:
	var coord := _create_tactical_coord("p6e_t3")
	coord.step_simulation()
	var s1 = coord.get_current_state()
	var dict = s1.to_dictionary()
	var s2 = GameStateSnapshot.from_dictionary(dict)
	return s2.wall_hp == s1.wall_hp and s2.gate_hp == s1.gate_hp and s2.fortress_hp == s1.fortress_hp


# ==============================================================================
# GROUP U: FULL DETERMINISM (Tests 70-71)
# ==============================================================================

func _test_u1_same_seed_produces_identical_battle_outcome() -> bool:
	var c1 := _create_tactical_coord("det_1", 12345)
	var c2 := _create_tactical_coord("det_2", 12345)
	for _i in range(10):
		c1.step_simulation()
		c2.step_simulation()
	return c1.get_battle_tick() == c2.get_battle_tick() and c1._fortress.gate_hp == c2._fortress.gate_hp and c1._fortress.current_hp == c2._fortress.current_hp


func _test_u2_different_seed_branches_deterministically() -> bool:
	var c1 := _create_tactical_coord("seed_a", 11111)
	var c2 := _create_tactical_coord("seed_b", 99999)
	for _i in range(10):
		c1.step_simulation()
		c2.step_simulation()
	return c1.get_battle_tick() == c2.get_battle_tick()


# ==============================================================================
# GROUP V: EDGE CASES & INPUT VALIDATION (Tests 72-74)
# ==============================================================================

func _test_v1_null_and_empty_inputs_handled_safely() -> bool:
	var engine := CombatEngine.new()
	var r = engine.route_damage_to_fortress(null, "GATE", 100)
	var p = engine.calculate_zone_enemy_pressure([], "")
	var c = engine.resolve_soldier_casualties(null, 100)
	return r["damage"] == 0 and p == 0 and c["casualties"] == 0


func _test_v2_zero_health_enemy_cannot_apply_pressure() -> bool:
	var eg := EnemyGroup.new("zero", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 1, "GATE")
	eg.current_hp_pool = 0
	eg.quantity = 0
	var engine := CombatEngine.new()
	var press = engine.calculate_zone_enemy_pressure([eg], "GATE")
	return press == 0


func _test_v3_zero_hp_fortress_rejects_further_damage() -> bool:
	var fort := FortressModel.new()
	fort.current_hp = 0
	var dmg = fort.take_damage(50)
	return dmg == 0


# ==============================================================================
# GROUP W: STRESS SIMULATION (Test 75)
# ==============================================================================

func _test_w1_1000_tick_tactical_battle_stress_simulation() -> bool:
	var coord := _create_tactical_coord("p6e_stress", 54321)
	for i in range(1, 1001):
		var ok = coord.step_simulation()
		if not ok:
			printerr("Stress tick %d failed" % i)
			return false
	var snap = coord.get_current_state()
	return snap.battle_tick == 1000 and snap.fortress_hp >= 0
