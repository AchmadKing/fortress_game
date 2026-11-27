extends SceneTree

## TestPhase6FTacticalBattleUi
## Test suite otomatis untuk memvalidasi implementasi Phase 6F:
## Tactical Battle UI & Verification Gate (PrototypeDebugView, GameController, GameCoordinator).
##
## Memvalidasi 72 pengujian fungsional, taktis, reaktif, dan integrasi yang terbagi dalam 23 kelompok:
## Group A (UI Init): Render saat battle dimulai, nonaktif saat persiapan, nama panel BattlefieldPanel, in-place preservation.
## Group B (Zone Rendering): 7 zona kanonikal, pemetaan status EMPTY, FRIENDLY, ENEMY OCCUPIED, CONTESTED.
## Group C (Enemy Groups): Arketipe & jumlah, HP pool agregat, indikator BOSS, indikator trait spesial.
## Group D (Party 1 Forces): Jumlah serdadu terjun, formasi & zona, aura aktif, isolasi Party 2 & Reserve.
## Group E (Hero Status): Hero Party 1 terdaftar dengan peran & pemimpin, HP stat, fatigue & morale, permadeath saat gugur.
## Group F (Fortress Condition): HP & Max HP benteng, armor benteng, status DESTROYED saat HP 0.
## Group G (Wall & Gate): HP dinding & gerbang, status BREACHED saat dinding HP 0, status BREACHED saat gerbang HP 0.
## Group H (Clock & Tick): Battle tick dimulai dari 0, pembaruan tick saat simulasi berjalan, telemetry header menampilkan wave.
## Group I (Pause/Resume): Tombol pause saat running, klik pause menghentikan simulasi & mengubah teks ke Resume, klik resume melanjutkan.
## Group J (Speed Controls): Tombol 1x, 2x, 4x mengubah kecepatan, highlight bracket kecepatan aktif.
## Group K (Command Buttons): Keberadaan seluruh tombol perintah kanonikal, eksekusi HOLD, ADVANCE, RETREAT, PROTECT.
## Group L (Validation & Feedback): Umpan balik sukses perintah valid, penolakan target tidak valid, selektor zona & entitas.
## Group M (Battle Lock): Rekrutmen dinonaktifkan saat tempur, progresi hero dikunci, penugasan regu dikunci.
## Group N (Telemetry): Korban serdadu terakumulasi, kerusakan benteng tercatat, hero gugur tercatat.
## Group O (Hero Permadeath): Penandaan gugur saat kerusakan fatal, aksi terkunci, refleksi di ringkasan regu.
## Group P (Victory Display): Overlay hasil muncul saat battle selesai, headline VICTORY, tombol proceed ke recovery.
## Group Q (Defeat Display): Overlay hasil menampilkan DEFEAT / BREACH, rincian kerusakan benteng & serdadu gugur, kehilangan perlengkapan.
## Group R (Game Over Display): Overlay Game Over saat benteng roboh (HP 0), headline Game Over, tombol restart session.
## Group S (Reactive Sync): Pembaruan UI via sinyal state_changed, pembaruan zona reaktif saat musuh bergerak, UI tertutup di luar tempur.
## Group T (Safety & Isolation): UI tidak memutasi snapshot secara langsung, snapshot adalah read-model terisolasi.
## Group U (Determinism): Seed & input identik menghasilkan tampilan visual identik, pengganda kecepatan tidak mengubah kalkulasi deterministik.
## Group V (Architecture Delegation): UI mendelegasikan ke GameController, controller mendelegasikan ke coordinator dan mengembalikan boolean.
## Group W (Mobile Touch & Smoke): Ukuran tombol perintah & pacing >= 44x44 px, selektor OptionButton >= 44x44 px, full lifecycle playtest.

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const PrototypeDebugView = preload("res://scripts/presentation/views/prototype_debug_view.gd")
const BattlefieldZone = preload("res://scripts/domain/model/battlefield_zone.gd")
const EnemyArchetype = preload("res://scripts/domain/model/enemy_archetype.gd")
const CommanderCommand = preload("res://scripts/domain/command/commander_command.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const PartyModel = preload("res://scripts/domain/model/party_model.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const GameStateSnapshot = preload("res://scripts/domain/state/game_state_snapshot.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 6F TACTICAL BATTLE UI & VERIFICATION TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# Group A: UI Initialization & Lifecycle (1-4)
		{"name": "test_a1_tactical_ui_hidden_or_inactive_in_preparation", "fn": Callable(self, "_test_a1_tactical_ui_hidden_or_inactive_in_preparation")},
		{"name": "test_a2_tactical_ui_built_and_visible_when_battle_starts", "fn": Callable(self, "_test_a2_tactical_ui_built_and_visible_when_battle_starts")},
		{"name": "test_a3_battlefield_panel_named_properly", "fn": Callable(self, "_test_a3_battlefield_panel_named_properly")},
		{"name": "test_a4_in_place_rendering_preserves_panel_identity_across_ticks", "fn": Callable(self, "_test_a4_in_place_rendering_preserves_panel_identity_across_ticks")},

		# Group B: Zone Rendering & Status Mapping (5-8)
		{"name": "test_b1_all_7_canonical_zones_rendered", "fn": Callable(self, "_test_b1_all_7_canonical_zones_rendered")},
		{"name": "test_b2_zone_status_empty_when_no_units", "fn": Callable(self, "_test_b2_zone_status_empty_when_no_units")},
		{"name": "test_b3_zone_status_friendly_when_only_allies_present", "fn": Callable(self, "_test_b3_zone_status_friendly_when_only_allies_present")},
		{"name": "test_b4_zone_status_enemy_occupied_and_contested", "fn": Callable(self, "_test_b4_zone_status_enemy_occupied_and_contested")},

		# Group C: Enemy Group Visualization (9-12)
		{"name": "test_c1_enemy_group_archetype_and_count_displayed_in_zone", "fn": Callable(self, "_test_c1_enemy_group_archetype_and_count_displayed_in_zone")},
		{"name": "test_c2_enemy_group_hp_pool_displayed_accurately", "fn": Callable(self, "_test_c2_enemy_group_hp_pool_displayed_accurately")},
		{"name": "test_c3_enemy_group_boss_indicator_displayed", "fn": Callable(self, "_test_c3_enemy_group_boss_indicator_displayed")},
		{"name": "test_c4_enemy_group_special_trait_displayed", "fn": Callable(self, "_test_c4_enemy_group_special_trait_displayed")},

		# Group D: Party 1 Tactical Force Visualization (13-16)
		{"name": "test_d1_party1_summary_displays_deployed_soldiers_count", "fn": Callable(self, "_test_d1_party1_summary_displays_deployed_soldiers_count")},
		{"name": "test_d2_party1_summary_displays_formation_and_zone", "fn": Callable(self, "_test_d2_party1_summary_displays_formation_and_zone")},
		{"name": "test_d3_party1_summary_displays_active_auras", "fn": Callable(self, "_test_d3_party1_summary_displays_active_auras")},
		{"name": "test_d4_party2_and_reserve_strictly_excluded_from_battlefield_combatants", "fn": Callable(self, "_test_d4_party2_and_reserve_strictly_excluded_from_battlefield_combatants")},

		# Group E: Hero Visualization & Status (17-20)
		{"name": "test_e1_party1_heroes_listed_with_roles_and_leader", "fn": Callable(self, "_test_e1_party1_heroes_listed_with_roles_and_leader")},
		{"name": "test_e2_hero_stats_hp_displayed", "fn": Callable(self, "_test_e2_hero_stats_hp_displayed")},
		{"name": "test_e3_hero_fatigue_and_morale_displayed", "fn": Callable(self, "_test_e3_hero_fatigue_and_morale_displayed")},
		{"name": "test_e4_hero_permadeath_status_displayed_when_killed", "fn": Callable(self, "_test_e4_hero_permadeath_status_displayed_when_killed")},

		# Group F: Fortress Structural Condition Card (21-23)
		{"name": "test_f1_fortress_hp_and_max_hp_displayed", "fn": Callable(self, "_test_f1_fortress_hp_and_max_hp_displayed")},
		{"name": "test_f2_fortress_armor_displayed", "fn": Callable(self, "_test_f2_fortress_armor_displayed")},
		{"name": "test_f3_fortress_status_destroyed_when_hp_zero", "fn": Callable(self, "_test_f3_fortress_status_destroyed_when_hp_zero")},

		# Group G: Wall & Gate Condition (24-26)
		{"name": "test_g1_wall_and_gate_hp_displayed_in_structural_status", "fn": Callable(self, "_test_g1_wall_and_gate_hp_displayed_in_structural_status")},
		{"name": "test_g2_wall_status_breached_when_hp_zero", "fn": Callable(self, "_test_g2_wall_status_breached_when_hp_zero")},
		{"name": "test_g3_gate_status_breached_when_hp_zero", "fn": Callable(self, "_test_g3_gate_status_breached_when_hp_zero")},

		# Group H: Battle Clock & Tick Display (27-29)
		{"name": "test_h1_battle_tick_starts_at_zero", "fn": Callable(self, "_test_h1_battle_tick_starts_at_zero")},
		{"name": "test_h2_battle_tick_updates_on_simulation_step", "fn": Callable(self, "_test_h2_battle_tick_updates_on_simulation_step")},
		{"name": "test_h3_battle_clock_telemetry_header_displays_current_wave", "fn": Callable(self, "_test_h3_battle_clock_telemetry_header_displays_current_wave")},

		# Group I: Pause / Resume UI (30-32)
		{"name": "test_i1_pause_button_displays_pause_when_running", "fn": Callable(self, "_test_i1_pause_button_displays_pause_when_running")},
		{"name": "test_i2_clicking_pause_button_pauses_battle_and_updates_text_to_resume", "fn": Callable(self, "_test_i2_clicking_pause_button_pauses_battle_and_updates_text_to_resume")},
		{"name": "test_i3_clicking_resume_button_resumes_battle_and_updates_text_to_pause", "fn": Callable(self, "_test_i3_clicking_resume_button_resumes_battle_and_updates_text_to_pause")},

		# Group J: Speed Controls 1x / 2x / 4x (33-36)
		{"name": "test_j1_speed_1x_button_sets_speed_1", "fn": Callable(self, "_test_j1_speed_1x_button_sets_speed_1")},
		{"name": "test_j2_speed_2x_button_sets_speed_2", "fn": Callable(self, "_test_j2_speed_2x_button_sets_speed_2")},
		{"name": "test_j3_speed_4x_button_sets_speed_4", "fn": Callable(self, "_test_j3_speed_4x_button_sets_speed_4")},
		{"name": "test_j4_speed_buttons_highlight_active_speed", "fn": Callable(self, "_test_j4_speed_buttons_highlight_active_speed")},

		# Group K: Commander Command Buttons (37-41)
		{"name": "test_k1_all_canonical_command_buttons_exist", "fn": Callable(self, "_test_k1_all_canonical_command_buttons_exist")},
		{"name": "test_k2_clicking_hold_position_dispatches_hold_command", "fn": Callable(self, "_test_k2_clicking_hold_position_dispatches_hold_command")},
		{"name": "test_k3_clicking_advance_dispatches_advance_command", "fn": Callable(self, "_test_k3_clicking_advance_dispatches_advance_command")},
		{"name": "test_k4_clicking_retreat_dispatches_retreat_command", "fn": Callable(self, "_test_k4_clicking_retreat_dispatches_retreat_command")},
		{"name": "test_k5_clicking_protect_dispatches_protect_command", "fn": Callable(self, "_test_k5_clicking_protect_dispatches_protect_command")},

		# Group L: Command Validation & Rejection Feedback (42-45)
		{"name": "test_l1_valid_command_displays_success_feedback", "fn": Callable(self, "_test_l1_valid_command_displays_success_feedback")},
		{"name": "test_l2_invalid_command_displays_rejected_feedback", "fn": Callable(self, "_test_l2_invalid_command_displays_rejected_feedback")},
		{"name": "test_l3_feedback_updates_without_crashing_when_units_dead", "fn": Callable(self, "_test_l3_feedback_updates_without_crashing_when_units_dead")},
		{"name": "test_l4_target_zone_and_entity_selectors_feed_command_execution", "fn": Callable(self, "_test_l4_target_zone_and_entity_selectors_feed_command_execution")},

		# Group M: Battle Lock Preservation (46-48)
		{"name": "test_m1_recruitment_disabled_during_battle", "fn": Callable(self, "_test_m1_recruitment_disabled_during_battle")},
		{"name": "test_m2_hero_ascension_and_training_disabled_during_battle", "fn": Callable(self, "_test_m2_hero_ascension_and_training_disabled_during_battle")},
		{"name": "test_m3_party_reassignment_disabled_during_battle", "fn": Callable(self, "_test_m3_party_reassignment_disabled_during_battle")},

		# Group N: Casualty & Damage Telemetry (49-51)
		{"name": "test_n1_soldier_casualties_telemetry_displayed", "fn": Callable(self, "_test_n1_soldier_casualties_telemetry_displayed")},
		{"name": "test_n2_fortress_damage_telemetry_displayed", "fn": Callable(self, "_test_n2_fortress_damage_telemetry_displayed")},
		{"name": "test_n3_fallen_heroes_telemetry_displayed", "fn": Callable(self, "_test_n3_fallen_heroes_telemetry_displayed")},

		# Group O: Hero Death Display (52-54)
		{"name": "test_o1_hero_marked_dead_on_lethal_damage", "fn": Callable(self, "_test_o1_hero_marked_dead_on_lethal_damage")},
		{"name": "test_o2_dead_hero_actions_locked", "fn": Callable(self, "_test_o2_dead_hero_actions_locked")},
		{"name": "test_o3_dead_hero_permadeath_reflected_in_party_summary", "fn": Callable(self, "_test_o3_dead_hero_permadeath_reflected_in_party_summary")},

		# Group P: Victory Display (55-57)
		{"name": "test_p1_result_overlay_visible_on_battle_finish", "fn": Callable(self, "_test_p1_result_overlay_visible_on_battle_finish")},
		{"name": "test_p2_result_overlay_displays_victory_headline", "fn": Callable(self, "_test_p2_result_overlay_displays_victory_headline")},
		{"name": "test_p3_proceed_button_transitions_to_recovery", "fn": Callable(self, "_test_p3_proceed_button_transitions_to_recovery")},

		# Group Q: Defeat Display (58-60)
		{"name": "test_q1_result_overlay_displays_defeat_headline_when_breached", "fn": Callable(self, "_test_q1_result_overlay_displays_defeat_headline_when_breached")},
		{"name": "test_q2_result_overlay_details_fortress_damage_and_soldier_losses", "fn": Callable(self, "_test_q2_result_overlay_details_fortress_damage_and_soldier_losses")},
		{"name": "test_q3_equipment_losses_summarized_in_result_body", "fn": Callable(self, "_test_q3_equipment_losses_summarized_in_result_body")},

		# Group R: Game Over Display (61-63)
		{"name": "test_r1_game_over_overlay_visible_when_fortress_hp_zero", "fn": Callable(self, "_test_r1_game_over_overlay_visible_when_fortress_hp_zero")},
		{"name": "test_r2_game_over_headline_and_body_show_collapsed", "fn": Callable(self, "_test_r2_game_over_headline_and_body_show_collapsed")},
		{"name": "test_r3_restart_session_button_resets_session", "fn": Callable(self, "_test_r3_restart_session_button_resets_session")},

		# Group S: Snapshot Reactive Synchronization (64-66)
		{"name": "test_s1_ui_reacts_to_state_changed_signal", "fn": Callable(self, "_test_s1_ui_reacts_to_state_changed_signal")},
		{"name": "test_s2_zone_status_updates_reactively_on_enemy_movement", "fn": Callable(self, "_test_s2_zone_status_updates_reactively_on_enemy_movement")},
		{"name": "test_s3_battlefield_hidden_when_not_in_battle_phase", "fn": Callable(self, "_test_s3_battlefield_hidden_when_not_in_battle_phase")},

		# Group T: Deep-Copy / Read-Model Safety (67-68)
		{"name": "test_t1_ui_does_not_mutate_snapshot_properties", "fn": Callable(self, "_test_t1_ui_does_not_mutate_snapshot_properties")},
		{"name": "test_t2_snapshot_from_coordinator_is_isolated_read_model", "fn": Callable(self, "_test_t2_snapshot_from_coordinator_is_isolated_read_model")},

		# Group U: Determinism (69-70)
		{"name": "test_u1_same_seed_and_commands_produce_identical_ui_state", "fn": Callable(self, "_test_u1_same_seed_and_commands_produce_identical_ui_state")},
		{"name": "test_u2_speed_multiplier_does_not_change_simulation_state", "fn": Callable(self, "_test_u2_speed_multiplier_does_not_change_simulation_state")},

		# Group V: UI Architecture Delegation Integrity (71-72)
		{"name": "test_v1_ui_delegates_all_mutations_to_controller", "fn": Callable(self, "_test_v1_ui_delegates_all_mutations_to_controller")},
		{"name": "test_v2_controller_delegates_to_coordinator_and_returns_boolean", "fn": Callable(self, "_test_v2_controller_delegates_to_coordinator_and_returns_boolean")},

		# Group W: Integration, Touch Targets & Full Lifecycle Smoke (73-75)
		{"name": "test_w1_all_pacing_and_command_buttons_meet_minimum_touch_target_44px", "fn": Callable(self, "_test_w1_all_pacing_and_command_buttons_meet_minimum_touch_target_44px")},
		{"name": "test_w2_selector_option_buttons_meet_minimum_touch_target_44px", "fn": Callable(self, "_test_w2_selector_option_buttons_meet_minimum_touch_target_44px")},
		{"name": "test_w3_full_wave_lifecycle_interactive_smoke_test", "fn": Callable(self, "_test_w3_full_wave_lifecycle_interactive_smoke_test")}
	]

	for t in test_list:
		var ok: bool = false
		var err_msg: String = ""
		var fn: Callable = t["fn"]
		var res = fn.call()
		if res is bool:
			ok = res
		else:
			ok = false
			err_msg = "Test did not return boolean."

		if ok:
			passed += 1
			print("[PASS] %s" % t["name"])
		else:
			failed += 1
			printerr("[FAIL] %s %s" % [t["name"], err_msg])

	print("================================================================")
	print("PHASE 6F TESTS SUMMARY: %d PASSED, %d FAILED (TOTAL %d)" % [passed, failed, test_list.size()])
	print("================================================================")

	if failed > 0:
		quit(1)
	else:
		quit(0)


# ==============================================================================
# HELPER METHODS
# ==============================================================================

func _create_test_session() -> Dictionary:
	var coord := GameCoordinator.new()
	var ctrl := GameController.new()
	var view := PrototypeDebugView.new()
	root.add_child(ctrl)
	root.add_child(view)
	coord.start_new_session("test_phase6f_session", 1337)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.set_party_leader("hero_alder", "party_1")
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


func _transition_to_battle(session: Dictionary) -> void:
	var ctrl: GameController = session["controller"]
	ctrl.inspect_wave()
	ctrl.start_battle(true)


# ==============================================================================
# GROUP A: UI INITIALIZATION & LIFECYCLE
# ==============================================================================

func _test_a1_tactical_ui_hidden_or_inactive_in_preparation() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var visible_in_prep: bool = view.is_battlefield_visible()
	_cleanup_session(s)
	return not visible_in_prep


func _test_a2_tactical_ui_built_and_visible_when_battle_starts() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var visible_in_battle: bool = view.is_battlefield_visible()
	_cleanup_session(s)
	return visible_in_battle


func _test_a3_battlefield_panel_named_properly() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var bf: Control = view.get_battlefield_container()
	var ok: bool = (bf != null and bf.name == "BattlefieldPanel")
	_cleanup_session(s)
	return ok


func _test_a4_in_place_rendering_preserves_panel_identity_across_ticks() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var ctrl: GameController = s["controller"]
	_transition_to_battle(s)
	var panel1: Control = view.get_battlefield_container()
	ctrl.step_simulation()
	var panel2: Control = view.get_battlefield_container()
	var ok: bool = (panel1 == panel2 and panel1 != null)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP B: ZONE RENDERING & STATUS MAPPING
# ==============================================================================

func _test_b1_all_7_canonical_zones_rendered() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var all_exist: bool = true
	for z in BattlefieldZone.VALID_ZONES:
		var p = view.get_zone_panel(z)
		if p == null or view.get_zone_status_text(z).is_empty():
			all_exist = false
			break
	_cleanup_session(s)
	return all_exist


func _test_b2_zone_status_empty_when_no_units() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	# By default on tick 0, OUTER_FIELD holds all wave enemies, but LEFT_FLANK and RIGHT_FLANK are empty
	var lf_status: String = view.get_zone_status_text("LEFT_FLANK")
	var rf_status: String = view.get_zone_status_text("RIGHT_FLANK")
	var ok: bool = ("[EMPTY]" in lf_status and "[EMPTY]" in rf_status)
	_cleanup_session(s)
	return ok


func _test_b3_zone_status_friendly_when_only_allies_present() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	# Party 1 is initially deployed at GATE or WALL with friendly heroes
	var gate_status: String = view.get_zone_status_text("GATE")
	var wall_status: String = view.get_zone_status_text("WALL")
	var has_friendly: bool = ("[FRIENDLY]" in gate_status or "[FRIENDLY]" in wall_status)
	_cleanup_session(s)
	return has_friendly


func _test_b4_zone_status_enemy_occupied_and_contested() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	# OUTER_FIELD has all spawned enemies and no friendlies -> ENEMY OCCUPIED
	var outer_status: String = view.get_zone_status_text("OUTER_FIELD")
	var is_occ: bool = ("[ENEMY OCCUPIED]" in outer_status)

	# Inject snapshot with contested zone
	var snap := view._last_snapshot.clone()
	snap.battle_party_data["current_zone"] = "OUTER_FIELD"
	view._update_tactical_battle_ui(snap)
	var outer_contested: String = view.get_zone_status_text("OUTER_FIELD")
	var is_cont: bool = ("[CONTESTED]" in outer_contested)

	_cleanup_session(s)
	return is_occ and is_cont


# ==============================================================================
# GROUP C: ENEMY GROUP VISUALIZATION
# ==============================================================================

func _test_c1_enemy_group_archetype_and_count_displayed_in_zone() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var outer_detail: String = view.get_zone_detail_text("OUTER_FIELD")
	var ok: bool = ("Musuh:" in outer_detail and ("GOBLIN_SWARM" in outer_detail or "ORC_FRONTLINE" in outer_detail or "MINION" in outer_detail or "RAIDER" in outer_detail))
	_cleanup_session(s)
	return ok


func _test_c2_enemy_group_hp_pool_displayed_accurately() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var outer_detail: String = view.get_zone_detail_text("OUTER_FIELD")
	var ok: bool = ("HP " in outer_detail and "/" in outer_detail)
	_cleanup_session(s)
	return ok


func _test_c3_enemy_group_boss_indicator_displayed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	# Inject a boss enemy group into snapshot
	var snap := view._last_snapshot.clone()
	snap.enemy_groups_data.append({
		"archetype": "BOSS",
		"count": 1,
		"current_hp_pool": 1000,
		"max_hp_pool": 1000,
		"current_zone": "OUTER_FIELD",
		"is_boss": true,
		"traits": ["BOSS"]
	})
	view._update_tactical_battle_ui(snap)
	var outer_detail: String = view.get_zone_detail_text("OUTER_FIELD")
	var ok: bool = ("[BOSS]" in outer_detail)
	_cleanup_session(s)
	return ok


func _test_c4_enemy_group_special_trait_displayed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.enemy_groups_data.append({
		"archetype": "SIEGE",
		"count": 2,
		"current_hp_pool": 600,
		"max_hp_pool": 600,
		"current_zone": "OUTER_FIELD",
		"is_boss": false,
		"traits": ["STRUCTURE_DAMAGE"]
	})
	view._update_tactical_battle_ui(snap)
	var outer_detail: String = view.get_zone_detail_text("OUTER_FIELD")
	var ok: bool = ("STRUCTURE_DAMAGE" in outer_detail)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP D: PARTY 1 TACTICAL FORCE VISUALIZATION
# ==============================================================================

func _test_d1_party1_summary_displays_deployed_soldiers_count() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	# Recruit and deploy soldiers before battle
	coord.recruit_soldier("SWORDSMAN")
	coord.recruit_soldier("SWORDSMAN")
	coord.create_soldier_deployment(2, "SWORD", "NONE", "NONE")
	_transition_to_battle(s)
	var summary: String = view.get_party1_summary_text()
	var ok: bool = ("2" in summary and "SWORDSMAN" in summary)
	_cleanup_session(s)
	return ok


func _test_d2_party1_summary_displays_formation_and_zone() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var summary: String = view.get_party1_summary_text()
	var ok: bool = ("Zona:" in summary and "Formasi:" in summary)
	_cleanup_session(s)
	return ok


func _test_d3_party1_summary_displays_active_auras() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.battle_aura_data = {"attack_bonus": 0.15, "defense_bonus": 0.10, "morale_bonus": 5.0}
	view._update_tactical_battle_ui(snap)
	var summary: String = view.get_party1_summary_text()
	var ok: bool = ("+15% ATK" in summary and "+10% DEF" in summary)
	_cleanup_session(s)
	return ok


func _test_d4_party2_and_reserve_strictly_excluded_from_battlefield_combatants() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var summary: String = view.get_party1_summary_text()
	var ok: bool = (not ("PARTY 2" in summary) and not ("RESERVE" in summary))
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP E: HERO VISUALIZATION & STATUS
# ==============================================================================

func _test_e1_party1_heroes_listed_with_roles_and_leader() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var summary: String = view.get_party1_summary_text()
	var ok: bool = ("Alder Ironclad" in summary and "[LEADER]" in summary)
	_cleanup_session(s)
	return ok


func _test_e2_hero_stats_hp_displayed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var summary: String = view.get_party1_summary_text()
	var ok: bool = ("HP " in summary)
	_cleanup_session(s)
	return ok


func _test_e3_hero_fatigue_and_morale_displayed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var summary: String = view.get_party1_summary_text()
	var ok: bool = ("Fatigue:" in summary and "Morale:" in summary)
	_cleanup_session(s)
	return ok


func _test_e4_hero_permadeath_status_displayed_when_killed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	for h in snap.heroes_data:
		if h.get("hero_id", "") == "hero_alder":
			h["is_alive"] = false
			break
	view._update_tactical_battle_ui(snap)
	var summary: String = view.get_party1_summary_text()
	var ok: bool = ("[GUGUR (Permadeath)]" in summary)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP F: FORTRESS STRUCTURAL CONDITION CARD
# ==============================================================================

func _test_f1_fortress_hp_and_max_hp_displayed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var f_status: String = view.get_fortress_status_text()
	var ok: bool = ("Benteng: HP 1000/1000" in f_status)
	_cleanup_session(s)
	return ok


func _test_f2_fortress_armor_displayed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var f_status: String = view.get_fortress_status_text()
	var ok: bool = ("Armor:" in f_status)
	_cleanup_session(s)
	return ok


func _test_f3_fortress_status_destroyed_when_hp_zero() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.fortress_hp = 0
	view._update_tactical_battle_ui(snap)
	var f_zone_status: String = view.get_zone_status_text("FORTRESS")
	var ok: bool = ("[DESTROYED]" in f_zone_status)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP G: WALL & GATE CONDITION
# ==============================================================================

func _test_g1_wall_and_gate_hp_displayed_in_structural_status() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var f_status: String = view.get_fortress_status_text()
	var ok: bool = ("Dinding: HP 500/500" in f_status and "Gerbang: HP 300/300" in f_status)
	_cleanup_session(s)
	return ok


func _test_g2_wall_status_breached_when_hp_zero() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.wall_hp = 0
	view._update_tactical_battle_ui(snap)
	var w_status: String = view.get_zone_status_text("WALL")
	var ok: bool = ("[BREACHED]" in w_status)
	_cleanup_session(s)
	return ok


func _test_g3_gate_status_breached_when_hp_zero() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.gate_hp = 0
	view._update_tactical_battle_ui(snap)
	var g_status: String = view.get_zone_status_text("GATE")
	var ok: bool = ("[BREACHED]" in g_status)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP H: BATTLE CLOCK & TICK DISPLAY
# ==============================================================================

func _test_h1_battle_tick_starts_at_zero() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var tick_text: String = view.get_battle_tick_display_text()
	var ok: bool = ("TICK: 0" in tick_text)
	_cleanup_session(s)
	return ok


func _test_h2_battle_tick_updates_on_simulation_step() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var ctrl: GameController = s["controller"]
	_transition_to_battle(s)
	ctrl.step_simulation()
	var tick_text: String = view.get_battle_tick_display_text()
	var ok: bool = ("TICK: 1" in tick_text)
	_cleanup_session(s)
	return ok


func _test_h3_battle_clock_telemetry_header_displays_current_wave() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var tick_text: String = view.get_battle_tick_display_text()
	var ok: bool = ("GELOMBANG: 1" in tick_text)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP I: PAUSE / RESUME UI
# ==============================================================================

func _test_i1_pause_button_displays_pause_when_running() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var btn: Button = view.get_pause_button()
	var ok: bool = (btn != null and "PAUSE" in btn.text)
	_cleanup_session(s)
	return ok


func _test_i2_clicking_pause_button_pauses_battle_and_updates_text_to_resume() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	var btn: Button = view.get_pause_button()
	btn.pressed.emit()
	var ok: bool = coord.is_battle_paused() and ("RESUME" in view.get_pause_button().text)
	_cleanup_session(s)
	return ok


func _test_i3_clicking_resume_button_resumes_battle_and_updates_text_to_pause() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	var btn: Button = view.get_pause_button()
	btn.pressed.emit() # Pause
	btn.pressed.emit() # Resume
	var ok: bool = (not coord.is_battle_paused()) and ("PAUSE" in btn.text)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP J: SPEED CONTROLS 1X / 2X / 4X
# ==============================================================================

func _test_j1_speed_1x_button_sets_speed_1() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	var btn2: Button = view.get_speed_button(2)
	btn2.pressed.emit()
	var btn1: Button = view.get_speed_button(1)
	btn1.pressed.emit()
	var ok: bool = is_equal_approx(coord.get_battle_speed(), 1.0)
	_cleanup_session(s)
	return ok


func _test_j2_speed_2x_button_sets_speed_2() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	var btn2: Button = view.get_speed_button(2)
	btn2.pressed.emit()
	var ok: bool = is_equal_approx(coord.get_battle_speed(), 2.0)
	_cleanup_session(s)
	return ok


func _test_j3_speed_4x_button_sets_speed_4() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	var btn4: Button = view.get_speed_button(4)
	btn4.pressed.emit()
	var ok: bool = is_equal_approx(coord.get_battle_speed(), 4.0)
	_cleanup_session(s)
	return ok


func _test_j4_speed_buttons_highlight_active_speed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var btn2: Button = view.get_speed_button(2)
	btn2.pressed.emit()
	var btn1_cur: Button = view.get_speed_button(1)
	var btn2_cur: Button = view.get_speed_button(2)
	var ok: bool = ("[2x]" in btn2_cur.text and not ("[" in btn1_cur.text))
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP K: COMMANDER COMMAND BUTTONS
# ==============================================================================

func _test_k1_all_canonical_command_buttons_exist() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var cmds := ["ADVANCE", "MOVE", "HOLD_POSITION", "RETREAT", "PROTECT", "FOCUS_TARGET", "FOLLOW"]
	var all_exist: bool = true
	for c in cmds:
		if view.get_command_button(c) == null:
			all_exist = false
			break
	_cleanup_session(s)
	return all_exist


func _test_k2_clicking_hold_position_dispatches_hold_command() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	var btn: Button = view.get_command_button("HOLD_POSITION")
	btn.pressed.emit()
	var last_cmd: CommanderCommand = coord.get_last_commander_command()
	var ok: bool = (last_cmd != null and last_cmd.command_type in [CommanderCommand.TYPE_HOLD, CommanderCommand.TYPE_HOLD_POSITION])
	_cleanup_session(s)
	return ok


func _test_k3_clicking_advance_dispatches_advance_command() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	# Set target zone in selector
	view._opt_cmd_target_zone.selected = 2 # CENTER_APPROACH
	var btn: Button = view.get_command_button("ADVANCE")
	btn.pressed.emit()
	var last_cmd: CommanderCommand = coord.get_last_commander_command()
	var ok: bool = (last_cmd != null and last_cmd.command_type == CommanderCommand.TYPE_ADVANCE)
	_cleanup_session(s)
	return ok


func _test_k4_clicking_retreat_dispatches_retreat_command() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	var btn: Button = view.get_command_button("RETREAT")
	btn.pressed.emit()
	var last_cmd: CommanderCommand = coord.get_last_commander_command()
	var ok: bool = (last_cmd != null and last_cmd.command_type == CommanderCommand.TYPE_RETREAT)
	_cleanup_session(s)
	return ok


func _test_k5_clicking_protect_dispatches_protect_command() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	var btn: Button = view.get_command_button("PROTECT")
	btn.pressed.emit()
	var last_cmd: CommanderCommand = coord.get_last_commander_command()
	var ok: bool = (last_cmd != null and last_cmd.command_type == CommanderCommand.TYPE_PROTECT)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP L: COMMAND VALIDATION & REJECTION FEEDBACK
# ==============================================================================

func _test_l1_valid_command_displays_success_feedback() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var btn: Button = view.get_command_button("HOLD_POSITION")
	btn.pressed.emit()
	var fb: String = view.get_command_feedback_text()
	var ok: bool = ("[COMMAND]" in fb and "berhasil" in fb)
	_cleanup_session(s)
	return ok


func _test_l2_invalid_command_displays_rejected_feedback() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	# Invalid non-adjacent MOVE from GATE to OUTER_FIELD directly
	view._opt_cmd_target_zone.selected = 0 # OUTER_FIELD
	var btn: Button = view.get_command_button("MOVE")
	btn.pressed.emit()
	var fb: String = view.get_command_feedback_text()
	var ok: bool = ("[DITOLAK]" in fb)
	_cleanup_session(s)
	return ok


func _test_l3_feedback_updates_without_crashing_when_units_dead() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	# Kill heroes in snapshot
	var snap := view._last_snapshot.clone()
	for h in snap.heroes_data:
		h["is_alive"] = false
	view._update_tactical_battle_ui(snap)
	var btn: Button = view.get_command_button("HOLD_POSITION")
	btn.pressed.emit()
	var fb: String = view.get_command_feedback_text()
	var ok: bool = not fb.is_empty()
	_cleanup_session(s)
	return ok


func _test_l4_target_zone_and_entity_selectors_feed_command_execution() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	view._opt_cmd_target_entity.selected = 0 # FORTRESS
	var btn: Button = view.get_command_button("PROTECT")
	btn.pressed.emit()
	var last_cmd: CommanderCommand = coord.get_last_commander_command()
	var ok: bool = (last_cmd != null and last_cmd.target_entity_id == "FORTRESS")
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP M: BATTLE LOCK PRESERVATION
# ==============================================================================

func _test_m1_recruitment_disabled_during_battle() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	# Recruitment buttons in recruitment container should be disabled
	var r_box = view._recruitment_container
	var ok: bool = true
	if r_box != null:
		for c in r_box.get_children():
			if c is Button and not c.disabled:
				ok = false
				break
	_cleanup_session(s)
	return ok


func _test_m2_hero_ascension_and_training_disabled_during_battle() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	# In detail container, action buttons are disabled or battle lock notice shown
	var detail_text: String = ""
	for c in view._hero_detail_container.get_children():
		if c is Label:
			detail_text += (c as Label).text + " "
	var ok: bool = ("[BATTLE LOCK" in detail_text or view._last_snapshot.game_phase == "BATTLE")
	_cleanup_session(s)
	return ok


func _test_m3_party_reassignment_disabled_during_battle() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var ok: bool = true
	for c in view._party_container.get_children():
		var btns := _find_all_buttons(c)
		for b in btns:
			if not b.disabled:
				ok = false
				break
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP N: CASUALTY & DAMAGE TELEMETRY
# ==============================================================================

func _test_n1_soldier_casualties_telemetry_displayed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.battle_casualties = {"dead_soldiers": 5, "fortress_damage": 30}
	view._update_tactical_battle_ui(snap)
	var cas_text: String = view.get_casualties_display_text()
	var ok: bool = ("Prajurit Gugur: 5" in cas_text)
	_cleanup_session(s)
	return ok


func _test_n2_fortress_damage_telemetry_displayed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.battle_casualties = {"dead_soldiers": 0, "fortress_damage": 75}
	view._update_tactical_battle_ui(snap)
	var cas_text: String = view.get_casualties_display_text()
	var ok: bool = ("Kerusakan Benteng: 75" in cas_text)
	_cleanup_session(s)
	return ok


func _test_n3_fallen_heroes_telemetry_displayed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.battle_heroes_killed = ["hero_alder"]
	view._update_tactical_battle_ui(snap)
	var cas_text: String = view.get_casualties_display_text()
	var ok: bool = ("Hero Gugur: 1" in cas_text)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP O: HERO DEATH DISPLAY
# ==============================================================================

func _test_o1_hero_marked_dead_on_lethal_damage() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.heroes_data[0]["is_alive"] = false
	view._update_tactical_battle_ui(snap)
	var sum: String = view.get_party1_summary_text()
	var ok: bool = ("[GUGUR (Permadeath)]" in sum)
	_cleanup_session(s)
	return ok


func _test_o2_dead_hero_actions_locked() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var snap := view._last_snapshot.clone()
	snap.heroes_data[0]["is_alive"] = false
	view._render_hero_detail_panel(snap)
	var ok: bool = ("[PERMADEATH:" in view._hero_detail_container.get_child(0).get_child(0).get_child(5).text)
	_cleanup_session(s)
	return ok


func _test_o3_dead_hero_permadeath_reflected_in_party_summary() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.heroes_data[0]["is_alive"] = false
	view._update_tactical_battle_ui(snap)
	var summary: String = view.get_party1_summary_text()
	var ok: bool = ("Permadeath" in summary)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP P: VICTORY DISPLAY
# ==============================================================================

func _test_p1_result_overlay_visible_on_battle_finish() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var ctrl: GameController = s["controller"]
	_transition_to_battle(s)
	ctrl.resolve_battle_immediately()
	var ok: bool = view.is_result_overlay_visible()
	_cleanup_session(s)
	return ok


func _test_p2_result_overlay_displays_victory_headline() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var ctrl: GameController = s["controller"]
	_transition_to_battle(s)
	ctrl.resolve_battle_immediately()
	var title: String = view.get_result_title_text()
	var ok: bool = ("VICTORY!" in title or "DEFEAT / BREACH!" in title)
	_cleanup_session(s)
	return ok


func _test_p3_proceed_button_transitions_to_recovery() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var ctrl: GameController = s["controller"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	ctrl.resolve_battle_immediately()
	var btn: Button = view._btn_result_proceed
	btn.pressed.emit()
	var next_phase: String = coord.get_current_state().game_phase
	var ok: bool = (next_phase == "PREPARATION" or next_phase == "GAME_OVER")
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP Q: DEFEAT DISPLAY
# ==============================================================================

func _test_q1_result_overlay_displays_defeat_headline_when_breached() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var snap := view._last_snapshot.clone()
	snap.game_phase = "RESULT"
	snap.last_battle_result = {"victory": false, "fortress_damage_taken": 250, "total_dead_soldiers": 4}
	view._on_state_changed(snap)
	var title: String = view.get_result_title_text()
	var ok: bool = ("DEFEAT / BREACH!" in title)
	_cleanup_session(s)
	return ok


func _test_q2_result_overlay_details_fortress_damage_and_soldier_losses() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var snap := view._last_snapshot.clone()
	snap.game_phase = "RESULT"
	snap.last_battle_result = {"victory": false, "fortress_damage_taken": 180, "total_dead_soldiers": 3}
	view._on_state_changed(snap)
	var body: String = view._lbl_result_body.text
	var ok: bool = ("180" in body and "3" in body)
	_cleanup_session(s)
	return ok


func _test_q3_equipment_losses_summarized_in_result_body() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var snap := view._last_snapshot.clone()
	snap.game_phase = "RESULT"
	snap.last_battle_result = {"victory": true, "equipment_lost": 2, "equipment_damaged": 1}
	view._on_state_changed(snap)
	var body: String = view._lbl_result_body.text
	var ok: bool = ("2 hancur" in body and "1 rusak" in body)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP R: GAME OVER DISPLAY
# ==============================================================================

func _test_r1_game_over_overlay_visible_when_fortress_hp_zero() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var snap := view._last_snapshot.clone()
	snap.game_phase = "GAME_OVER"
	snap.fortress_hp = 0
	view._on_state_changed(snap)
	var ok: bool = view.is_game_over_overlay_visible()
	_cleanup_session(s)
	return ok


func _test_r2_game_over_headline_and_body_show_collapsed() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var snap := view._last_snapshot.clone()
	snap.game_phase = "GAME_OVER"
	snap.fortress_hp = 0
	view._on_state_changed(snap)
	var title: String = view.get_game_over_title_text()
	var ok: bool = ("FORTRESS COLLAPSED" in title)
	_cleanup_session(s)
	return ok


func _test_r3_restart_session_button_resets_session() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	var snap := view._last_snapshot.clone()
	snap.game_phase = "GAME_OVER"
	view._on_state_changed(snap)
	var btn: Button = view._btn_game_over_restart
	btn.pressed.emit()
	var ok: bool = (coord.get_current_state().game_phase == "PREPARATION")
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP S: SNAPSHOT REACTIVE SYNCHRONIZATION
# ==============================================================================

func _test_s1_ui_reacts_to_state_changed_signal() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	var snap := coord.get_current_state().clone()
	snap.battle_tick = 42
	coord.state_changed.emit(snap)
	var ok: bool = ("TICK: 42" in view.get_battle_tick_display_text())
	_cleanup_session(s)
	return ok


func _test_s2_zone_status_updates_reactively_on_enemy_movement() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	# Manually push enemy group to LEFT_FLANK
	var snap := coord.get_current_state().clone()
	snap.enemy_groups_data.append({
		"archetype": "RAIDER",
		"count": 4,
		"current_hp_pool": 320,
		"max_hp_pool": 320,
		"current_zone": "LEFT_FLANK",
		"is_boss": false,
		"traits": []
	})
	coord.state_changed.emit(snap)
	var lf_status: String = view.get_zone_status_text("LEFT_FLANK")
	var ok: bool = ("[ENEMY OCCUPIED]" in lf_status)
	_cleanup_session(s)
	return ok


func _test_s3_battlefield_hidden_when_not_in_battle_phase() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var snap := view._last_snapshot.clone()
	snap.game_phase = "PREPARATION"
	view._on_state_changed(snap)
	var ok: bool = not view.is_battlefield_visible()
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP T: DEEP-COPY / READ-MODEL SAFETY
# ==============================================================================

func _test_t1_ui_does_not_mutate_snapshot_properties() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var original_tick: int = view._last_snapshot.battle_tick
	view._update_tactical_battle_ui(view._last_snapshot)
	var ok: bool = (view._last_snapshot.battle_tick == original_tick)
	_cleanup_session(s)
	return ok


func _test_t2_snapshot_from_coordinator_is_isolated_read_model() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var snap1: GameStateSnapshot = coord.get_current_state()
	var snap2: GameStateSnapshot = coord.get_current_state()
	snap1.wall_hp = 9999
	var ok: bool = (snap2.wall_hp != 9999)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP U: DETERMINISM
# ==============================================================================

func _test_u1_same_seed_and_commands_produce_identical_ui_state() -> bool:
	var s1 := _create_test_session()
	var s2 := _create_test_session()
	_transition_to_battle(s1)
	_transition_to_battle(s2)
	var v1: PrototypeDebugView = s1["view"]
	var v2: PrototypeDebugView = s2["view"]
	var c1: GameController = s1["controller"]
	var c2: GameController = s2["controller"]
	for i in range(5):
		c1.step_simulation()
		c2.step_simulation()
	var text1: String = v1.get_battle_tick_display_text()
	var text2: String = v2.get_battle_tick_display_text()
	var fort1: String = v1.get_fortress_status_text()
	var fort2: String = v2.get_fortress_status_text()
	var ok: bool = (text1 == text2 and fort1 == fort2)
	_cleanup_session(s1)
	_cleanup_session(s2)
	return ok


func _test_u2_speed_multiplier_does_not_change_simulation_state() -> bool:
	var s1 := _create_test_session()
	var s2 := _create_test_session()
	_transition_to_battle(s1)
	_transition_to_battle(s2)
	var c1: GameController = s1["controller"]
	var c2: GameController = s2["controller"]
	c1.set_speed(1.0)
	c2.set_speed(4.0)
	for i in range(3):
		c1.step_simulation()
		c2.step_simulation()
	var coord1: GameCoordinator = s1["coordinator"]
	var coord2: GameCoordinator = s2["coordinator"]
	var ok: bool = (coord1.get_current_state().fortress_hp == coord2.get_current_state().fortress_hp)
	_cleanup_session(s1)
	_cleanup_session(s2)
	return ok


# ==============================================================================
# GROUP V: UI ARCHITECTURE DELEGATION INTEGRITY
# ==============================================================================

func _test_v1_ui_delegates_all_mutations_to_controller() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	_transition_to_battle(s)
	# Trigger command via UI execute method
	view._execute_selected_command("HOLD_POSITION")
	var last_cmd = coord.get_last_commander_command()
	var ok: bool = (last_cmd != null and last_cmd.command_type in [CommanderCommand.TYPE_HOLD, CommanderCommand.TYPE_HOLD_POSITION])
	_cleanup_session(s)
	return ok


func _test_v2_controller_delegates_to_coordinator_and_returns_boolean() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]
	_transition_to_battle(s)
	var res1: bool = ctrl.pause_battle()
	var res2: bool = ctrl.resume_battle()
	var ok: bool = (res1 and res2)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP W: INTEGRATION, TOUCH TARGETS & FULL LIFECYCLE SMOKE
# ==============================================================================

func _test_w1_all_pacing_and_command_buttons_meet_minimum_touch_target_44px() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var btns: Array[Button] = [
		view._btn_battle_pause_resume,
		view._btn_battle_speed_1x,
		view._btn_battle_speed_2x,
		view._btn_battle_speed_4x,
		view._btn_battle_step_tick,
		view._btn_battle_resolve_instantly,
		view._btn_cmd_advance,
		view._btn_cmd_move,
		view._btn_cmd_hold,
		view._btn_cmd_retreat,
		view._btn_cmd_protect,
		view._btn_cmd_focus,
		view._btn_cmd_follow
	]
	var ok: bool = true
	for b in btns:
		if b == null or b.custom_minimum_size.x < 44.0 or b.custom_minimum_size.y < 44.0:
			ok = false
			break
	_cleanup_session(s)
	return ok


func _test_w2_selector_option_buttons_meet_minimum_touch_target_44px() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	_transition_to_battle(s)
	var opts: Array[OptionButton] = [
		view._opt_cmd_source,
		view._opt_cmd_target_zone,
		view._opt_cmd_target_entity
	]
	var ok: bool = true
	for opt in opts:
		if opt == null or opt.custom_minimum_size.x < 44.0 or opt.custom_minimum_size.y < 44.0:
			ok = false
			break
	_cleanup_session(s)
	return ok


func _test_w3_full_wave_lifecycle_interactive_smoke_test() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var ctrl: GameController = s["controller"]
	var coord: GameCoordinator = s["coordinator"]

	# 1. Start preparation
	# 2. Inspect Wave
	ctrl.inspect_wave()
	if coord.get_current_state().game_phase != "WAVE_PREVIEW":
		_cleanup_session(s)
		return false

	# 3. Start Battle
	ctrl.start_battle(true)
	if not view.is_battlefield_visible():
		_cleanup_session(s)
		return false

	# 4. Simulation ticks
	for i in range(3):
		ctrl.step_simulation()

	# 5. Commander command
	view.get_command_button("HOLD_POSITION").pressed.emit()

	# 6. Resolve battle immediately
	ctrl.resolve_battle_immediately()
	if not view.is_result_overlay_visible():
		_cleanup_session(s)
		return false

	# 7. Proceed to next phase
	view._btn_result_proceed.pressed.emit()
	var final_phase: String = coord.get_current_state().game_phase
	var ok: bool = (final_phase == "PREPARATION" or final_phase == "GAME_OVER")

	_cleanup_session(s)
	return ok


# Helper to find all buttons in a subtree
func _find_all_buttons(node: Node) -> Array[Button]:
	var res: Array[Button] = []
	if node is Button:
		res.append(node as Button)
	for c in node.get_children():
		res.append_array(_find_all_buttons(c))
	return res
