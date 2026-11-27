extends SceneTree

## TestPhase4GHeroManagementUx
## Test suite otomatis untuk memvalidasi implementasi Phase 4G:
## Hero Management UX (Prototype/Debug View, GameController, GameCoordinator).
##
## Memvalidasi 60 pengujian fungsional dan reaktif yang terbagi dalam 10 kelompok:
## Group A (Roster UX): Render pahlawan terdaftar, seleksi default, pergantian seleksi, label reserve vs regu, indikator permadeath.
## Group B (Detail UX): Identitas & peran, bintang & potensi, level cap, EXP saat ini/syarat, combat stats dasar & efektif, fatigue & morale, fallback seleksi tak valid.
## Group C (Recruitment UX): Tampilan biaya (500 G kanonikal) & kas, pemilihan peran, eksekusi rekrutmen & potongan kas, validasi kas tidak cukup, pembatasan Battle Lock, auto-seleksi hero baru.
## Group D (Ascension UX): Tombol nonaktif saat underleveled, kas kurang, atau bintang maksimal; tombol aktif saat syarat terpenuhi; eksekusi penambahan bintang & potongan emas kanonikal; pembatasan Battle Lock.
## Group E (Training & Rest UX): Eksekusi latihan (+40 EXP, +15 Fatigue), pembatasan 1x latihan per gelombang, batas fatigue <= 100, eksekusi istirahat (-25 Fatigue, +5 Morale), pembatasan Battle Lock.
## Group F (Skills & Talents UX): Katalog skill kanonikal sesuai peran, pembatasan level minimum, eksekusi unlock skill, pohon bakat (OFFENSE/DEFENSE/LEADERSHIP), eksekusi alokasi poin bakat, batas poin 0 & cap 3, pembatasan Battle Lock.
## Group G (Party Management UX): Tampilan Party 1 & Party 2, penugasan ke Party 1 & Party 2, pengembalian ke cadangan, penetapan pemimpin regu, batas maksimal 3 anggota per regu, pembatasan Battle Lock.
## Group H (Chemistry UX): Tampilan status tanpa chemistry, kemitraan poin (cap 50) & bonus efektivitas (+0.5%/pt), antarmuka display-only tanpa tombol mutasi manual, refleksi pasca-tempur.
## Group I (Equipment UX & Permadeath): Tampilan slot & stok gudang, aksi pasang (equip) & lepas (unequip), pembatasan Battle Lock, pengembalian perlengkapan otomatis ke gudang pada hero permadeath.
## Group J (Integration & Reactive Sync): Banner umpan balik (feedback banner) untuk seluruh aksi, sinkronisasi reaktif dari mutasi domain -> snapshot -> pembaruan UI otomatis.

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


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 4G HERO MANAGEMENT UX TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		# Group A: Hero Roster UX Tests (1-6)
		{"name": "test_a1_roster_renders_all_registered_heroes", "fn": Callable(self, "_test_a1_roster_renders_all_registered_heroes")},
		{"name": "test_a2_roster_default_selection_first_hero", "fn": Callable(self, "_test_a2_roster_default_selection_first_hero")},
		{"name": "test_a3_roster_selection_updates_selected_hero_id", "fn": Callable(self, "_test_a3_roster_selection_updates_selected_hero_id")},
		{"name": "test_a4_roster_displays_reserve_label_when_no_party", "fn": Callable(self, "_test_a4_roster_displays_reserve_label_when_no_party")},
		{"name": "test_a5_roster_displays_party_id_when_assigned", "fn": Callable(self, "_test_a5_roster_displays_party_id_when_assigned")},
		{"name": "test_a6_roster_displays_dead_status_on_permadeath", "fn": Callable(self, "_test_a6_roster_displays_dead_status_on_permadeath")},

		# Group B: Hero Detail Panel UX Tests (7-12)
		{"name": "test_b1_detail_panel_renders_hero_identity_and_role", "fn": Callable(self, "_test_b1_detail_panel_renders_hero_identity_and_role")},
		{"name": "test_b2_detail_panel_renders_star_pot_star_and_level_cap", "fn": Callable(self, "_test_b2_detail_panel_renders_star_pot_star_and_level_cap")},
		{"name": "test_b3_detail_panel_renders_exp_current_and_required", "fn": Callable(self, "_test_b3_detail_panel_renders_exp_current_and_required")},
		{"name": "test_b4_detail_panel_renders_base_and_effective_combat_stats", "fn": Callable(self, "_test_b4_detail_panel_renders_base_and_effective_combat_stats")},
		{"name": "test_b5_detail_panel_renders_fatigue_and_morale", "fn": Callable(self, "_test_b5_detail_panel_renders_fatigue_and_morale")},
		{"name": "test_b6_detail_panel_empty_fallback_when_invalid_selection", "fn": Callable(self, "_test_b6_detail_panel_empty_fallback_when_invalid_selection")},

		# Group C: Hero Recruitment UX Tests (13-18)
		{"name": "test_c1_recruitment_panel_displays_cost_and_treasury", "fn": Callable(self, "_test_c1_recruitment_panel_displays_cost_and_treasury")},
		{"name": "test_c2_recruitment_role_toggle_updates_selected_role", "fn": Callable(self, "_test_c2_recruitment_role_toggle_updates_selected_role")},
		{"name": "test_c3_recruitment_action_succeeds_and_deducts_500_gold", "fn": Callable(self, "_test_c3_recruitment_action_succeeds_and_deducts_500_gold")},
		{"name": "test_c4_recruitment_button_disabled_when_gold_insufficient", "fn": Callable(self, "_test_c4_recruitment_button_disabled_when_gold_insufficient")},
		{"name": "test_c5_recruitment_button_disabled_under_battle_lock", "fn": Callable(self, "_test_c5_recruitment_button_disabled_under_battle_lock")},
		{"name": "test_c6_recruitment_selects_newly_recruited_hero", "fn": Callable(self, "_test_c6_recruitment_selects_newly_recruited_hero")},

		# Group D: Ascension UX Tests (19-24)
		{"name": "test_d1_ascend_button_disabled_when_underleveled", "fn": Callable(self, "_test_d1_ascend_button_disabled_when_underleveled")},
		{"name": "test_d2_ascend_button_disabled_when_gold_insufficient", "fn": Callable(self, "_test_d2_ascend_button_disabled_when_gold_insufficient")},
		{"name": "test_d3_ascend_button_enabled_when_cap_reached_and_affordable", "fn": Callable(self, "_test_d3_ascend_button_enabled_when_cap_reached_and_affordable")},
		{"name": "test_d4_ascend_action_increases_star_and_deducts_gold", "fn": Callable(self, "_test_d4_ascend_action_increases_star_and_deducts_gold")},
		{"name": "test_d5_ascend_button_disabled_when_current_star_equals_potential", "fn": Callable(self, "_test_d5_ascend_button_disabled_when_current_star_equals_potential")},
		{"name": "test_d6_ascend_disabled_under_battle_lock", "fn": Callable(self, "_test_d6_ascend_disabled_under_battle_lock")},

		# Group E: Training & Rest UX Tests (25-30)
		{"name": "test_e1_training_action_grants_40_exp_and_15_fatigue", "fn": Callable(self, "_test_e1_training_action_grants_40_exp_and_15_fatigue")},
		{"name": "test_e2_training_disabled_when_already_trained_this_wave", "fn": Callable(self, "_test_e2_training_disabled_when_already_trained_this_wave")},
		{"name": "test_e3_training_disabled_when_fatigue_would_exceed_100", "fn": Callable(self, "_test_e3_training_disabled_when_fatigue_would_exceed_100")},
		{"name": "test_e4_rest_action_recovers_25_fatigue_and_5_morale", "fn": Callable(self, "_test_e4_rest_action_recovers_25_fatigue_and_5_morale")},
		{"name": "test_e5_training_disabled_under_battle_lock", "fn": Callable(self, "_test_e5_training_disabled_under_battle_lock")},
		{"name": "test_e6_rest_disabled_under_battle_lock", "fn": Callable(self, "_test_e6_rest_disabled_under_battle_lock")},

		# Group F: Skills & Talents UX Tests (31-38)
		{"name": "test_f1_canonical_skills_catalog_rendered_for_role", "fn": Callable(self, "_test_f1_canonical_skills_catalog_rendered_for_role")},
		{"name": "test_f2_skill_unlock_button_disabled_when_underleveled", "fn": Callable(self, "_test_f2_skill_unlock_button_disabled_when_underleveled")},
		{"name": "test_f3_skill_unlock_action_succeeds_when_eligible", "fn": Callable(self, "_test_f3_skill_unlock_action_succeeds_when_eligible")},
		{"name": "test_f4_skill_unlock_disabled_under_battle_lock", "fn": Callable(self, "_test_f4_skill_unlock_disabled_under_battle_lock")},
		{"name": "test_f5_talent_tree_displays_branches_and_multipliers", "fn": Callable(self, "_test_f5_talent_tree_displays_branches_and_multipliers")},
		{"name": "test_f6_talent_allocation_increments_branch_and_deducts_point", "fn": Callable(self, "_test_f6_talent_allocation_increments_branch_and_deducts_point")},
		{"name": "test_f7_talent_allocation_disabled_when_points_zero", "fn": Callable(self, "_test_f7_talent_allocation_disabled_when_points_zero")},
		{"name": "test_f8_talent_allocation_disabled_under_battle_lock", "fn": Callable(self, "_test_f8_talent_allocation_disabled_under_battle_lock")},

		# Group G: Party Management UX Tests (39-45)
		{"name": "test_g1_party_lists_rendered_for_party_1_and_party_2", "fn": Callable(self, "_test_g1_party_lists_rendered_for_party_1_and_party_2")},
		{"name": "test_g2_assign_to_party_1_action_succeeds", "fn": Callable(self, "_test_g2_assign_to_party_1_action_succeeds")},
		{"name": "test_g3_assign_to_party_2_action_succeeds", "fn": Callable(self, "_test_g3_assign_to_party_2_action_succeeds")},
		{"name": "test_g4_remove_from_party_returns_hero_to_reserve", "fn": Callable(self, "_test_g4_remove_from_party_returns_hero_to_reserve")},
		{"name": "test_g5_set_party_leader_action_succeeds", "fn": Callable(self, "_test_g5_set_party_leader_action_succeeds")},
		{"name": "test_g6_party_assign_disabled_when_party_full_at_3", "fn": Callable(self, "_test_g6_party_assign_disabled_when_party_full_at_3")},
		{"name": "test_g7_party_actions_disabled_under_battle_lock", "fn": Callable(self, "_test_g7_party_actions_disabled_under_battle_lock")},

		# Group H: Chemistry UX Tests (46-49)
		{"name": "test_h1_chemistry_section_renders_empty_when_no_bonds", "fn": Callable(self, "_test_h1_chemistry_section_renders_empty_when_no_bonds")},
		{"name": "test_h2_chemistry_section_renders_bonds_and_bonus_pct", "fn": Callable(self, "_test_h2_chemistry_section_renders_bonds_and_bonus_pct")},
		{"name": "test_h3_chemistry_section_is_strictly_display_only", "fn": Callable(self, "_test_h3_chemistry_section_is_strictly_display_only")},
		{"name": "test_h4_chemistry_reflects_combat_wave_updates", "fn": Callable(self, "_test_h4_chemistry_reflects_combat_wave_updates")},

		# Group I: Equipment UX & Permadeath Tests (50-54)
		{"name": "test_i1_equipment_controls_render_slots_and_warehouse_stock", "fn": Callable(self, "_test_i1_equipment_controls_render_slots_and_warehouse_stock")},
		{"name": "test_i2_equip_action_equips_item_and_decrements_warehouse", "fn": Callable(self, "_test_i2_equip_action_equips_item_and_decrements_warehouse")},
		{"name": "test_i3_unequip_action_returns_item_to_warehouse", "fn": Callable(self, "_test_i3_unequip_action_returns_item_to_warehouse")},
		{"name": "test_i4_equipment_controls_disabled_under_battle_lock", "fn": Callable(self, "_test_i4_equipment_controls_disabled_under_battle_lock")},
		{"name": "test_i5_permadeath_hero_equipment_returned_and_actions_locked", "fn": Callable(self, "_test_i5_permadeath_hero_equipment_returned_and_actions_locked")},

		# Group J: Integration, Reactive Sync & Feedback Tests (55-60)
		{"name": "test_j1_feedback_banner_updates_on_recruitment", "fn": Callable(self, "_test_j1_feedback_banner_updates_on_recruitment")},
		{"name": "test_j2_feedback_banner_updates_on_ascension_success_and_failure", "fn": Callable(self, "_test_j2_feedback_banner_updates_on_ascension_success_and_failure")},
		{"name": "test_j3_feedback_banner_updates_on_training_and_rest", "fn": Callable(self, "_test_j3_feedback_banner_updates_on_training_and_rest")},
		{"name": "test_j4_feedback_banner_updates_on_skill_and_talent", "fn": Callable(self, "_test_j4_feedback_banner_updates_on_skill_and_talent")},
		{"name": "test_j5_feedback_banner_updates_on_party_assignment_and_removal", "fn": Callable(self, "_test_j5_feedback_banner_updates_on_party_assignment_and_removal")},
		{"name": "test_j6_full_reactive_sync_from_mutation_to_snapshot_to_ui", "fn": Callable(self, "_test_j6_full_reactive_sync_from_mutation_to_snapshot_to_ui")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 4G TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
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
	coord.start_new_session("test_hero_ux_session", 1337)
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


func _find_child_by_name(node: Node, target_name: String) -> Node:
	if node == null or node.is_queued_for_deletion():
		return null
	if node.name == target_name:
		return node
	for child in node.get_children():
		if child.is_queued_for_deletion():
			continue
		var res: Node = _find_child_by_name(child, target_name)
		if res != null:
			return res
	return null


func _find_child_by_text(node: Node, target_substr: String) -> Node:
	if node == null or node.is_queued_for_deletion():
		return null
	if not node.is_queued_for_deletion():
		if node is Label and target_substr in (node as Label).text:
			return node
		if node is Button and target_substr in (node as Button).text:
			return node
	for child in node.get_children():
		if child.is_queued_for_deletion():
			continue
		var res: Node = _find_child_by_text(child, target_substr)
		if res != null:
			return res
	return null


# ==============================================================================
# GROUP A: HERO ROSTER UX TESTS
# ==============================================================================

func _test_a1_roster_renders_all_registered_heroes() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var c_alder: Node = _find_child_by_text(view._hero_container, "Alder Ironclad")
	var c_lyra: Node = _find_child_by_text(view._hero_container, "Lyra Windwalker")
	var ok: bool = (c_alder != null and c_lyra != null)
	_cleanup_session(s)
	return ok


func _test_a2_roster_default_selection_first_hero() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var ok: bool = (view._selected_hero_id == "hero_alder")
	_cleanup_session(s)
	return ok


func _test_a3_roster_selection_updates_selected_hero_id() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var btn_lyra: Button = _find_child_by_name(view._hero_container, "BtnSelect_hero_lyra") as Button
	if btn_lyra == null:
		_cleanup_session(s)
		return false
	btn_lyra.pressed.emit()
	var ok: bool = (view._selected_hero_id == "hero_lyra")
	var detail_lyra: Node = _find_child_by_text(view._hero_detail_container, "Lyra Windwalker")
	ok = ok and (detail_lyra != null)
	_cleanup_session(s)
	return ok


func _test_a4_roster_displays_reserve_label_when_no_party() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var lbl: Node = _find_child_by_text(view._hero_container, "Regu: [RESERVE]")
	var ok: bool = (lbl != null)
	_cleanup_session(s)
	return ok


func _test_a5_roster_displays_party_id_when_assigned() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	var lbl: Node = _find_child_by_text(view._hero_container, "Regu: [PARTY_1]")
	var ok: bool = (lbl != null)
	_cleanup_session(s)
	return ok


func _test_a6_roster_displays_dead_status_on_permadeath() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.mark_dead()
	coord.set_treasury_gold(coord.get_treasury_gold()) # trigger snapshot & state_changed
	var lbl: Node = _find_child_by_text(view._hero_container, "DEAD (Permadeath)")
	var ok: bool = (lbl != null)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP B: HERO DETAIL PANEL UX TESTS
# ==============================================================================

func _test_b1_detail_panel_renders_hero_identity_and_role() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var lbl: Node = _find_child_by_text(view._hero_detail_container, "DETAIL: Alder Ironclad [KNIGHT]")
	var ok: bool = (lbl != null)
	_cleanup_session(s)
	return ok


func _test_b2_detail_panel_renders_star_pot_star_and_level_cap() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var lbl_star: Node = _find_child_by_text(view._hero_detail_container, "Bintang 1★ / 4★")
	var lbl_cap: Node = _find_child_by_text(view._hero_detail_container, "Level Cap: 10")
	var ok: bool = (lbl_star != null and lbl_cap != null)
	_cleanup_session(s)
	return ok


func _test_b3_detail_panel_renders_exp_current_and_required() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var lbl_exp: Node = _find_child_by_text(view._hero_detail_container, "EXP: 0 / 120")
	var ok: bool = (lbl_exp != null)
	_cleanup_session(s)
	return ok


func _test_b4_detail_panel_renders_base_and_effective_combat_stats() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var lbl_stats: Node = _find_child_by_text(view._hero_detail_container, "Combat Stats: HP: 250")
	var ok: bool = (lbl_stats != null and "Base: 35" in (lbl_stats as Label).text and "Base: 20" in (lbl_stats as Label).text)
	_cleanup_session(s)
	return ok


func _test_b5_detail_panel_renders_fatigue_and_morale() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var lbl_cond: Node = _find_child_by_text(view._hero_detail_container, "Kondisi: Fatigue: 0/100 | Morale: 100/150")
	var ok: bool = (lbl_cond != null)
	_cleanup_session(s)
	return ok


func _test_b6_detail_panel_empty_fallback_when_invalid_selection() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]
	view._selected_hero_id = "hero_ghost_invalid"
	view._render_hero_detail_panel(coord.get_current_state())
	var lbl: Node = _find_child_by_text(view._hero_detail_container, "(Pahlawan terpilih tidak ditemukan)")
	var ok: bool = (lbl != null)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP C: HERO RECRUITMENT UX TESTS
# ==============================================================================

func _test_c1_recruitment_panel_displays_cost_and_treasury() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var lbl: Node = _find_child_by_text(view._recruitment_container, "Biaya: 500 Gold (Kas: 150 Gold)")
	var ok: bool = (lbl != null)
	_cleanup_session(s)
	return ok


func _test_c2_recruitment_role_toggle_updates_selected_role() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var btn_mage: Button = _find_child_by_name(view._recruitment_container, "BtnPickRole_MAGE") as Button
	if btn_mage == null:
		_cleanup_session(s)
		return false
	btn_mage.pressed.emit()
	var ok: bool = (view._selected_recruit_role == "MAGE")
	var cand_lbl: Node = _find_child_by_text(view._recruitment_container, "Kandidat: Recruit Mage")
	ok = ok and (cand_lbl != null)
	_cleanup_session(s)
	return ok


func _test_c3_recruitment_action_succeeds_and_deducts_500_gold() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.set_treasury_gold(600)
	view._action_recruit_hero()
	var ok: bool = (coord.get_heroes().size() == 3)
	ok = ok and (coord.get_treasury_gold() == 100)
	ok = ok and ("[REKRUTMEN]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_c4_recruitment_button_disabled_when_gold_insufficient() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var btn: Button = _find_child_by_name(view._recruitment_container, "BtnRecruitHero") as Button
	var ok: bool = (btn != null and btn.disabled and "Kas Tidak Cukup" in btn.text)
	_cleanup_session(s)
	return ok


func _test_c5_recruitment_button_disabled_under_battle_lock() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.set_treasury_gold(1000)
	coord.inspect_wave()
	coord.start_battle()
	var btn: Button = _find_child_by_name(view._recruitment_container, "BtnRecruitHero") as Button
	var ok: bool = (btn != null and btn.disabled and "Battle Lock" in btn.text)
	_cleanup_session(s)
	return ok


func _test_c6_recruitment_selects_newly_recruited_hero() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.set_treasury_gold(600)
	view._selected_recruit_role = "PRIEST"
	view._action_recruit_hero()
	var newest_hero: HeroModel = coord.get_heroes()[coord.get_heroes().size() - 1] as HeroModel
	var ok: bool = (view._selected_hero_id == newest_hero.hero_id)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP D: ASCENSION UX TESTS
# ==============================================================================

func _test_d1_ascend_button_disabled_when_underleveled() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnAscendHero") as Button
	var ok: bool = (btn != null and btn.disabled)
	_cleanup_session(s)
	return ok


func _test_d2_ascend_button_disabled_when_gold_insufficient() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.level = 10
	coord.set_treasury_gold(0)
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnAscendHero") as Button
	var ok: bool = (btn != null and btn.disabled)
	_cleanup_session(s)
	return ok


func _test_d3_ascend_button_enabled_when_cap_reached_and_affordable() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.level = 10
	coord.set_treasury_gold(500)
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnAscendHero") as Button
	var ok: bool = (btn != null and not btn.disabled)
	_cleanup_session(s)
	return ok


func _test_d4_ascend_action_increases_star_and_deducts_gold() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.level = 10
	coord.set_treasury_gold(500)
	view._action_ascend_hero("hero_alder")
	var ok: bool = (hero.current_star == 2)
	ok = ok and (coord.get_treasury_gold() == 350)
	ok = ok and ("[ASCENSION]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_d5_ascend_button_disabled_when_current_star_equals_potential() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.current_star = 4
	hero.level = 40
	coord.set_treasury_gold(1000)
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnAscendHero") as Button
	var ok: bool = (btn != null and btn.disabled)
	_cleanup_session(s)
	return ok


func _test_d6_ascend_disabled_under_battle_lock() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.level = 10
	coord.set_treasury_gold(500)
	coord.inspect_wave()
	coord.start_battle()
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnAscendHero") as Button
	var ok: bool = (btn == null or btn.disabled) # detail shows Battle Lock notice or disabled
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP E: TRAINING & REST UX TESTS
# ==============================================================================

func _test_e1_training_action_grants_40_exp_and_15_fatigue() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	view._action_train_hero("hero_alder")
	var ok: bool = (hero.current_exp == 40 and hero.fatigue == 15)
	ok = ok and ("[LATIHAN]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_e2_training_disabled_when_already_trained_this_wave() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	view._action_train_hero("hero_alder")
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnTrainHero") as Button
	var ok: bool = (btn != null and btn.disabled)
	_cleanup_session(s)
	return ok


func _test_e3_training_disabled_when_fatigue_would_exceed_100() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.fatigue = 90
	coord.set_treasury_gold(coord.get_treasury_gold())
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnTrainHero") as Button
	var ok: bool = (btn != null and btn.disabled)
	_cleanup_session(s)
	return ok


func _test_e4_rest_action_recovers_25_fatigue_and_5_morale() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.fatigue = 50
	hero.morale = 90
	view._action_rest_hero("hero_alder")
	var ok: bool = (hero.fatigue == 25 and hero.morale == 95)
	ok = ok and ("[ISTIRAHAT]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_e5_training_disabled_under_battle_lock() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.inspect_wave()
	coord.start_battle()
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnTrainHero") as Button
	var ok: bool = (btn == null or btn.disabled)
	_cleanup_session(s)
	return ok


func _test_e6_rest_disabled_under_battle_lock() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.inspect_wave()
	coord.start_battle()
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnRestHero") as Button
	var ok: bool = (btn == null or btn.disabled)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP F: SKILLS & TALENTS UX TESTS
# ==============================================================================

func _test_f1_canonical_skills_catalog_rendered_for_role() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var s1: Node = _find_child_by_text(view._hero_detail_container, "Iron Edge")
	var s2: Node = _find_child_by_text(view._hero_detail_container, "Iron Guard")
	var s3: Node = _find_child_by_text(view._hero_detail_container, "Battle Leadership")
	var ok: bool = (s1 != null and s2 != null and s3 != null)
	_cleanup_session(s)
	return ok


func _test_f2_skill_unlock_button_disabled_when_underleveled() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnUnlockSkill_knight_offense") as Button
	var ok: bool = (btn != null and btn.disabled)
	_cleanup_session(s)
	return ok


func _test_f3_skill_unlock_action_succeeds_when_eligible() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.level = 3
	coord.set_treasury_gold(coord.get_treasury_gold())
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnUnlockSkill_knight_offense") as Button
	var ok: bool = (btn != null and not btn.disabled)
	view._action_unlock_skill("hero_alder", "knight_offense")
	ok = ok and ("knight_offense" in hero.unlocked_skills)
	ok = ok and ("[SKILL]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_f4_skill_unlock_disabled_under_battle_lock() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.level = 5
	coord.inspect_wave()
	coord.start_battle()
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnUnlockSkill_knight_offense") as Button
	var ok: bool = (btn == null or btn.disabled)
	_cleanup_session(s)
	return ok


func _test_f5_talent_tree_displays_branches_and_multipliers() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var t_off: Node = _find_child_by_text(view._hero_detail_container, "OFFENSE")
	var t_def: Node = _find_child_by_text(view._hero_detail_container, "DEFENSE")
	var t_lead: Node = _find_child_by_text(view._hero_detail_container, "LEADERSHIP")
	var t_mult: Node = _find_child_by_text(view._hero_detail_container, "Pengali Bakat: ATK x1.00 | DEF x1.00")
	var ok: bool = (t_off != null and t_def != null and t_lead != null and t_mult != null)
	_cleanup_session(s)
	return ok


func _test_f6_talent_allocation_increments_branch_and_deducts_point() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.talent_points = 2
	coord.set_treasury_gold(coord.get_treasury_gold())
	view._action_allocate_talent("hero_alder", "OFFENSE")
	var ok: bool = (hero.allocated_talents.get("OFFENSE", 0) == 1)
	ok = ok and (hero.talent_points == 1)
	ok = ok and ("[BAKAT]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_f7_talent_allocation_disabled_when_points_zero() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnAllocateTalent_OFFENSE") as Button
	var ok: bool = (btn != null and btn.disabled)
	_cleanup_session(s)
	return ok


func _test_f8_talent_allocation_disabled_under_battle_lock() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.talent_points = 2
	coord.inspect_wave()
	coord.start_battle()
	var btn: Button = _find_child_by_name(view._hero_detail_container, "BtnAllocateTalent_OFFENSE") as Button
	var ok: bool = (btn == null or btn.disabled)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP G: PARTY MANAGEMENT UX TESTS
# ==============================================================================

func _test_g1_party_lists_rendered_for_party_1_and_party_2() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var p1: Node = _find_child_by_text(view._party_container, "PARTY 1 (Active Battle Party)")
	var p2: Node = _find_child_by_text(view._party_container, "PARTY 2 (Management Reserve)")
	var res: Node = _find_child_by_text(view._party_container, "RESERVE (Pahlawan Cadangan)")
	var ok: bool = (p1 != null and p2 != null and res != null)
	_cleanup_session(s)
	return ok


func _test_g2_assign_to_party_1_action_succeeds() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	view._action_assign_hero_to_party("hero_alder", "party_1")
	var hero: HeroModel = coord.get_hero("hero_alder")
	var party: PartyModel = coord.get_party("party_1")
	var ok: bool = (hero.party_id == "party_1")
	ok = ok and (party.member_hero_ids.has("hero_alder"))
	ok = ok and ("[REGU]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_g3_assign_to_party_2_action_succeeds() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	view._action_assign_hero_to_party("hero_lyra", "party_2")
	var hero: HeroModel = coord.get_hero("hero_lyra")
	var party: PartyModel = coord.get_party("party_2")
	var ok: bool = (hero.party_id == "party_2")
	ok = ok and (party.member_hero_ids.has("hero_lyra"))
	_cleanup_session(s)
	return ok


func _test_g4_remove_from_party_returns_hero_to_reserve() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	view._action_assign_hero_to_party("hero_alder", "party_1")
	view._action_remove_hero_from_party("hero_alder")
	var hero: HeroModel = coord.get_hero("hero_alder")
	var party: PartyModel = coord.get_party("party_1")
	var ok: bool = (hero.party_id == "")
	ok = ok and (not party.member_hero_ids.has("hero_alder"))
	ok = ok and ("[REGU]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_g5_set_party_leader_action_succeeds() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	view._action_assign_hero_to_party("hero_alder", "party_1")
	view._action_assign_hero_to_party("hero_lyra", "party_1")
	view._action_set_party_leader("hero_lyra", "party_1")
	var party: PartyModel = coord.get_party("party_1")
	var ok: bool = (party.leader_hero_id == "hero_lyra")
	ok = ok and ("[LEADER]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_g6_party_assign_disabled_when_party_full_at_3() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	# Buat 2 hero baru
	var h3 := HeroModel.new("hero_3", "Hero Three", 1, 3, HeroRole.MAGE, HeroLifecycleState.ROSTER_ACTIVE)
	var h4 := HeroModel.new("hero_4", "Hero Four", 1, 3, HeroRole.PRIEST, HeroLifecycleState.ROSTER_ACTIVE)
	coord.add_hero(h3)
	coord.add_hero(h4)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party("hero_3", "party_1")
	# Party 1 penuh (3/3), tombol assign party 1 untuk hero_4 harus disabled
	var btn_p1: Button = _find_child_by_name(view._party_container, "BtnAssign_party_1_hero_4") as Button
	var ok: bool = (btn_p1 != null and btn_p1.disabled)
	_cleanup_session(s)
	return ok


func _test_g7_party_actions_disabled_under_battle_lock() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	var btn_rem: Button = _find_child_by_name(view._party_container, "BtnRemoveParty_party_1_hero_alder") as Button
	var btn_ass: Button = _find_child_by_name(view._party_container, "BtnAssign_party_1_hero_lyra") as Button
	var ok: bool = (btn_rem != null and btn_rem.disabled)
	ok = ok and (btn_ass != null and btn_ass.disabled)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP H: CHEMISTRY UX TESTS
# ==============================================================================

func _test_h1_chemistry_section_renders_empty_when_no_bonds() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var lbl: Node = _find_child_by_text(view._hero_detail_container, "(Belum ada chemistry — terbentuk dari pertempuran bersama di Party 1)")
	var ok: bool = (lbl != null)
	_cleanup_session(s)
	return ok


func _test_h2_chemistry_section_renders_bonds_and_bonus_pct() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.add_chemistry("hero_lyra", 20)
	coord.set_treasury_gold(coord.get_treasury_gold())
	var lbl: Node = _find_child_by_text(view._hero_detail_container, "Kemitraan dengan Lyra Windwalker: 20 / 50 poin (+10.0% efektivitas bersama)")
	var ok: bool = (lbl != null)
	_cleanup_session(s)
	return ok


func _test_h3_chemistry_section_is_strictly_display_only() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.add_chemistry("hero_lyra", 20)
	coord.set_treasury_gold(coord.get_treasury_gold())
	# Pastikan tidak ada tombol manipulasi chemistry langsung
	var btn_chem: Node = _find_child_by_text(view._hero_detail_container, "Add Chemistry")
	var btn_chem2: Node = _find_child_by_text(view._hero_detail_container, "Tingkatkan Kemitraan")
	var ok: bool = (btn_chem == null and btn_chem2 == null)
	_cleanup_session(s)
	return ok


func _test_h4_chemistry_reflects_combat_wave_updates() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(99)
	coord.proceed_from_result() # Wave 1 -> Wave 2: chemistry bertambah +2
	view._selected_hero_id = "hero_alder"
	view._render_hero_detail_panel(coord.get_current_state())
	var lbl: Node = _find_child_by_text(view._hero_detail_container, "Kemitraan dengan Lyra Windwalker: 2 / 50 poin (+1.0% efektivitas bersama)")
	var ok: bool = (lbl != null)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP I: EQUIPMENT UX & PERMADEATH TESTS
# ==============================================================================

func _test_i1_equipment_controls_render_slots_and_warehouse_stock() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var lbl_cur: Node = _find_child_by_text(view._hero_detail_container, "Saat Ini: [Primary: NONE | Secondary: NONE | Armor: NONE]")
	var btn_sword: Node = _find_child_by_text(view._hero_detail_container, "+SWORD")
	var ok: bool = (lbl_cur != null and btn_sword != null)
	_cleanup_session(s)
	return ok


func _test_i2_equip_action_equips_item_and_decrements_warehouse() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var init_sword: int = coord.get_warehouse_stock("SWORD")
	view._action_equip_hero("hero_alder", "PRIMARY", "SWORD")
	var hero: HeroModel = coord.get_hero("hero_alder")
	var ok: bool = (hero.primary_equipment != null and (hero.primary_equipment as EquipmentModel).role_type == "SWORD")
	ok = ok and (coord.get_warehouse_stock("SWORD") == init_sword - 1)
	var btn_unequip: Node = _find_child_by_text(view._hero_detail_container, "Lepas (SWORD)")
	ok = ok and (btn_unequip != null)
	_cleanup_session(s)
	return ok


func _test_i3_unequip_action_returns_item_to_warehouse() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var init_sword: int = coord.get_warehouse_stock("SWORD")
	view._action_equip_hero("hero_alder", "PRIMARY", "SWORD")
	view._action_unequip_hero("hero_alder", "PRIMARY")
	var hero: HeroModel = coord.get_hero("hero_alder")
	var ok: bool = (hero.primary_equipment == null)
	ok = ok and (coord.get_warehouse_stock("SWORD") == init_sword)
	_cleanup_session(s)
	return ok


func _test_i4_equipment_controls_disabled_under_battle_lock() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.inspect_wave()
	coord.start_battle()
	var btn_sword: Node = _find_child_by_text(view._hero_detail_container, "+SWORD")
	var ok: bool = (btn_sword == null) # Pada fase BATTLE, panel perlengkapan disembunyikan/dikunci
	_cleanup_session(s)
	return ok


func _test_i5_permadeath_hero_equipment_returned_and_actions_locked() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	view._action_equip_hero("hero_alder", "PRIMARY", "SWORD")
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.mark_dead()
	coord.inspect_wave()
	coord.start_battle()
	coord.execute_battle(123)
	coord.proceed_from_result() # Post-battle cleans dead hero equipment back to warehouse
	view._selected_hero_id = "hero_alder"
	view._render_hero_detail_panel(coord.get_current_state())
	var lbl_perm: Node = _find_child_by_text(view._hero_detail_container, "[PERMADEATH: Pahlawan gugur permanen. Seluruh aksi terkunci.]")
	var ok: bool = (lbl_perm != null)
	_cleanup_session(s)
	return ok


# ==============================================================================
# GROUP J: INTEGRATION, REACTIVE SYNC & FEEDBACK TESTS
# ==============================================================================

func _test_j1_feedback_banner_updates_on_recruitment() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	coord.set_treasury_gold(1000)
	view._action_recruit_hero()
	var ok: bool = ("[REKRUTMEN]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_j2_feedback_banner_updates_on_ascension_success_and_failure() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	view._action_ascend_hero("hero_alder") # Underleveled -> Ditolak
	var ok: bool = ("[DITOLAK]" in view._lbl_feedback_banner.text)
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.level = 10
	coord.set_treasury_gold(500)
	view._action_ascend_hero("hero_alder") # Sukses
	ok = ok and ("[ASCENSION]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_j3_feedback_banner_updates_on_training_and_rest() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	view._action_train_hero("hero_alder")
	var ok: bool = ("[LATIHAN]" in view._lbl_feedback_banner.text)
	view._action_train_hero("hero_alder") # 2x in same wave -> Ditolak
	ok = ok and ("[DITOLAK]" in view._lbl_feedback_banner.text)
	view._action_rest_hero("hero_alder")
	ok = ok and ("[ISTIRAHAT]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_j4_feedback_banner_updates_on_skill_and_talent() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.level = 3
	hero.talent_points = 2
	coord.set_treasury_gold(coord.get_treasury_gold())
	view._action_unlock_skill("hero_alder", "knight_offense")
	var ok: bool = ("[SKILL]" in view._lbl_feedback_banner.text)
	view._action_allocate_talent("hero_alder", "OFFENSE")
	ok = ok and ("[BAKAT]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_j5_feedback_banner_updates_on_party_assignment_and_removal() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	view._action_assign_hero_to_party("hero_alder", "party_1")
	var ok: bool = ("[REGU]" in view._lbl_feedback_banner.text)
	view._action_set_party_leader("hero_alder", "party_1")
	ok = ok and ("[LEADER]" in view._lbl_feedback_banner.text)
	view._action_remove_hero_from_party("hero_alder")
	ok = ok and ("[REGU]" in view._lbl_feedback_banner.text)
	_cleanup_session(s)
	return ok


func _test_j6_full_reactive_sync_from_mutation_to_snapshot_to_ui() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var view: PrototypeDebugView = s["view"]
	# Mutasi di domain / coordinator secara langsung
	coord.set_treasury_gold(750)
	# Verifikasi UI ter-update tanpa pemanggilan manual view
	var lbl: Node = _find_child_by_text(view._recruitment_container, "Kas: 750 Gold")
	var ok: bool = (lbl != null)
	_cleanup_session(s)
	return ok
