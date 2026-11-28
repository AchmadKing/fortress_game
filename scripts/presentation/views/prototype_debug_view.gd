class_name PrototypeDebugView
extends Control

## PrototypeDebugView
## Tampilan telemetri dan kontrol prototipe interaktif (Phase 3D UX & Interaction Polish).
## Mengamati sinyal GameCoordinator.state_changed secara reaktif tanpa polling di _process().
## Menyediakan:
## - State / Phase guidance contextual header
## - Kontrol alokasi pekerja & rekrutmen serdadu berumpan balik transparan
## - Soldier Deployment Builder dengan preview peran dinamis & verifikasi stok
## - Active Deployment List dengan Edit/Reconfigure atomik dan Cancel/Remove
## - Hero Roster dengan kontrol Equip/Unequip/Swap dan proteksi Battle Lock
## - Shared Warehouse Transparency dengan tabel breakdown Total = Warehouse + Hero + Soldier
## - Penanganan dead-end dan umpan balik aksi gagal/sukses

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const CommanderCommand = preload("res://scripts/domain/command/commander_command.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const HeroSkill = preload("res://scripts/domain/model/hero_skill.gd")
const PartyModel = preload("res://scripts/domain/model/party_model.gd")
const BattlefieldZone = preload("res://scripts/domain/model/battlefield_zone.gd")
const EnemyArchetype = preload("res://scripts/domain/model/enemy_archetype.gd")

var coordinator: GameCoordinator
var controller: GameController

# UI References
var _lbl_state_badge: Label
var _lbl_wave_indicator: Label
var _lbl_speed_pause: Label
var _lbl_phase_guidance: Label

var _lbl_fortress_hp: Label
var _lbl_fortress_armor: Label
var _lbl_treasury: Label
var _lbl_civilians: Label
var _lbl_workers: Label
var _lbl_soldiers: Label

var _lbl_feedback_banner: Label
var _panel_stage_actions: VBoxContainer
var _txt_telemetry_log: RichTextLabel

# Phase 4G Hero Management UI References
var _lbl_recruitment: Label
var _recruitment_container: VBoxContainer
var _lbl_parties: Label
var _party_container: VBoxContainer
var _lbl_heroes: Label
var _hero_container: VBoxContainer
var _lbl_hero_detail: Label
var _hero_detail_container: VBoxContainer

# Phase 5 Fortress & Management UI References
var _lbl_wall_hp: Label
var _lbl_gate_hp: Label
var _lbl_population_summary: Label
var _lbl_worker_morale_prod: Label
var _buildings_container: VBoxContainer
var _lbl_construction_status: Label
var _btn_start_battle: Button
var _btn_action: Button

var _lbl_warehouse: Label
var _blacksmith_container: VBoxContainer

# Phase 6F Tactical Battle UI References & State
var _battlefield_panel: PanelContainer
var _zone_panels: Dictionary = {}
var _zone_labels: Dictionary = {}
var _zone_status_labels: Dictionary = {}
var _zone_detail_labels: Dictionary = {}

var _lbl_battle_telemetry_header: Label
var _btn_battle_pause_resume: Button
var _btn_battle_speed_1x: Button
var _btn_battle_speed_2x: Button
var _btn_battle_speed_4x: Button
var _btn_battle_step_tick: Button
var _btn_battle_resolve_instantly: Button

var _opt_cmd_source: OptionButton
var _opt_cmd_target_zone: OptionButton
var _opt_cmd_target_entity: OptionButton
var _btn_cmd_advance: Button
var _btn_cmd_move: Button
var _btn_cmd_hold: Button
var _btn_cmd_retreat: Button
var _btn_cmd_protect: Button
var _btn_cmd_focus: Button
var _btn_cmd_follow: Button
var _lbl_cmd_feedback: Label

var _lbl_party1_summary: Label
var _lbl_casualties_summary: Label
var _lbl_fortress_battle_status: Label

var _result_overlay: PanelContainer
var _lbl_result_headline: Label
var _lbl_result_body: Label
var _btn_result_proceed: Button

var _game_over_overlay: PanelContainer
var _lbl_game_over_headline: Label
var _lbl_game_over_body: Label
var _btn_game_over_restart: Button

var _last_snapshot: GameStateSnapshot

# Local Hero Selection & Candidate State
var _selected_hero_id: String = ""
var _selected_recruit_role: String = "KNIGHT"

# Local Deployment Builder Selection State
var _selected_deploy_count: int = 2
var _selected_primary: String = "SWORD"
var _selected_secondary: String = "NONE"
var _selected_armor: String = "NONE"

# Local Reconfiguration Selection State
var _editing_composition_id: String = ""
var _edit_count: int = 2
var _edit_primary: String = "SWORD"
var _edit_secondary: String = "NONE"
var _edit_armor: String = "NONE"


func setup(p_coordinator: GameCoordinator, p_controller: GameController) -> void:
	coordinator = p_coordinator
	controller = p_controller
	
	if _lbl_state_badge == null:
		_build_ui()
	
	if coordinator != null:
		coordinator.state_changed.connect(_on_state_changed)
		_on_state_changed(coordinator.get_current_state())


func _ready() -> void:
	if _lbl_state_badge == null:
		_build_ui()


func _build_ui() -> void:
	# Root container
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	var main_vbox := VBoxContainer.new()
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_left = 10
	main_vbox.offset_top = 10
	main_vbox.offset_right = -10
	main_vbox.offset_bottom = -10
	add_child(main_vbox)

	# 1. Header Bar & Phase Guidance
	var header_panel := PanelContainer.new()
	var header_inner_vbox := VBoxContainer.new()
	header_panel.add_child(header_inner_vbox)
	main_vbox.add_child(header_panel)

	var header_hbox := HBoxContainer.new()
	header_inner_vbox.add_child(header_hbox)

	var title := Label.new()
	title.text = "FORTRESS GAME — PHASE 3 PLAYABLE PROTOTYPE"
	header_hbox.add_child(title)

	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(spacer1)

	_lbl_state_badge = Label.new()
	_lbl_state_badge.text = "[STATE: BOOT]"
	header_hbox.add_child(_lbl_state_badge)

	header_hbox.add_child(VSeparator.new())

	_lbl_wave_indicator = Label.new()
	_lbl_wave_indicator.text = "Wave: 1 / 100"
	header_hbox.add_child(_lbl_wave_indicator)

	header_hbox.add_child(VSeparator.new())

	_lbl_speed_pause = Label.new()
	_lbl_speed_pause.text = "Speed: 1.0x (Active)"
	header_hbox.add_child(_lbl_speed_pause)

	# Tombol kontrol tempo di header
	var btn_pause := Button.new()
	btn_pause.text = "Pause/Resume"
	btn_pause.pressed.connect(func(): if controller: controller.toggle_pause())
	header_hbox.add_child(btn_pause)

	var btn_1x := Button.new()
	btn_1x.text = "1x"
	btn_1x.pressed.connect(func(): if controller: controller.set_speed(1.0))
	header_hbox.add_child(btn_1x)

	var btn_2x := Button.new()
	btn_2x.text = "2x"
	btn_2x.pressed.connect(func(): if controller: controller.set_speed(2.0))
	header_hbox.add_child(btn_2x)

	var btn_4x := Button.new()
	btn_4x.text = "4x"
	btn_4x.pressed.connect(func(): if controller: controller.set_speed(4.0))
	header_hbox.add_child(btn_4x)

	header_inner_vbox.add_child(HSeparator.new())

	_lbl_phase_guidance = Label.new()
	_lbl_phase_guidance.text = "Session in boot state. Click start to begin."
	header_inner_vbox.add_child(_lbl_phase_guidance)

	# 2. Main Content (3 Kolom: Status Kiri, Stage Tengah, Roster Kanan)
	var content_hbox := HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_hbox)

	# KOLOM KIRI: Benteng & Ekonomi
	var left_scroll := ScrollContainer.new()
	left_scroll.custom_minimum_size = Vector2(280, 0)
	var left_vbox := VBoxContainer.new()
	left_scroll.add_child(left_vbox)
	content_hbox.add_child(left_scroll)

	var lbl_sec1 := Label.new()
	lbl_sec1.text = "=== FORTRESS & INFRASTRUCTURE ==="
	left_vbox.add_child(lbl_sec1)

	_lbl_fortress_hp = Label.new()
	_lbl_fortress_hp.text = "HP: 1000 / 1000"
	left_vbox.add_child(_lbl_fortress_hp)

	_lbl_fortress_armor = Label.new()
	_lbl_fortress_armor.text = "Armor: 40 | Status: INTACT"
	left_vbox.add_child(_lbl_fortress_armor)

	_lbl_wall_hp = Label.new()
	_lbl_wall_hp.text = "Wall: 500 / 500 | Status: INTACT"
	left_vbox.add_child(_lbl_wall_hp)

	_lbl_gate_hp = Label.new()
	_lbl_gate_hp.text = "Gate: 300 / 300 | Status: INTACT"
	left_vbox.add_child(_lbl_gate_hp)

	var rep_hbox := HBoxContainer.new()
	left_vbox.add_child(rep_hbox)

	var btn_rep_fort := Button.new()
	btn_rep_fort.text = "+Rep Benteng (50)"
	btn_rep_fort.pressed.connect(func(): _action_repair_structure("FORTRESS", 50))
	rep_hbox.add_child(btn_rep_fort)

	var btn_rep_wall := Button.new()
	btn_rep_wall.text = "+Rep Tembok (50)"
	btn_rep_wall.pressed.connect(func(): _action_repair_structure("WALL", 50))
	rep_hbox.add_child(btn_rep_wall)

	var btn_rep_gate := Button.new()
	btn_rep_gate.text = "+Rep Gerbang (50)"
	btn_rep_gate.pressed.connect(func(): _action_repair_structure("GATE", 50))
	rep_hbox.add_child(btn_rep_gate)

	left_vbox.add_child(HSeparator.new())

	var lbl_sec2 := Label.new()
	lbl_sec2.text = "=== ECONOMY & POPULATION ==="
	left_vbox.add_child(lbl_sec2)

	_lbl_treasury = Label.new()
	_lbl_treasury.text = "Treasury: 150 Gold"
	left_vbox.add_child(_lbl_treasury)

	_lbl_civilians = Label.new()
	_lbl_civilians.text = "Civilians: 12 / 30 | Morale: 100"
	left_vbox.add_child(_lbl_civilians)

	_lbl_population_summary = Label.new()
	_lbl_population_summary.text = "Populasi: Sipil 12 | Pekerja 0 | Serdadu 6 | Total: 18 / 30"
	left_vbox.add_child(_lbl_population_summary)

	_lbl_workers = Label.new()
	_lbl_workers.text = "Workers:\n- Repair: 0\n- Smith: 0\n- Constr: 0\n- Idle: 12"
	left_vbox.add_child(_lbl_workers)

	_lbl_worker_morale_prod = Label.new()
	_lbl_worker_morale_prod.text = "Moral Pekerja: 100/100 | Produktivitas: 100%"
	left_vbox.add_child(_lbl_worker_morale_prod)

	var pop_conv_hbox := HBoxContainer.new()
	left_vbox.add_child(pop_conv_hbox)

	var btn_civ_to_w := Button.new()
	btn_civ_to_w.text = "+1 Pekerja (Sipil->Pekerja)"
	btn_civ_to_w.pressed.connect(func(): _action_convert_civilian_to_worker(1))
	pop_conv_hbox.add_child(btn_civ_to_w)

	var btn_w_to_civ := Button.new()
	btn_w_to_civ.text = "-1 Pekerja (Pekerja->Sipil)"
	btn_w_to_civ.pressed.connect(func(): _action_convert_worker_to_civilian(1))
	pop_conv_hbox.add_child(btn_w_to_civ)

	# Tombol Alokasi Pekerja Cepat
	var lbl_alloc := Label.new()
	lbl_alloc.text = "-- Atur Pekerja (Repair/Smith/Constr) --"
	left_vbox.add_child(lbl_alloc)

	var worker_grid := GridContainer.new()
	worker_grid.columns = 3
	left_vbox.add_child(worker_grid)

	var btn_w_rep_plus := Button.new()
	btn_w_rep_plus.text = "+ Repair"
	btn_w_rep_plus.pressed.connect(func(): _adjust_workers(1, 0, 0))
	worker_grid.add_child(btn_w_rep_plus)

	var btn_w_smith_plus := Button.new()
	btn_w_smith_plus.text = "+ Smith"
	btn_w_smith_plus.pressed.connect(func(): _adjust_workers(0, 1, 0))
	worker_grid.add_child(btn_w_smith_plus)

	var btn_w_constr_plus := Button.new()
	btn_w_constr_plus.text = "+ Constr"
	btn_w_constr_plus.pressed.connect(func(): _adjust_workers(0, 0, 1))
	worker_grid.add_child(btn_w_constr_plus)

	var btn_w_rep_min := Button.new()
	btn_w_rep_min.text = "- Repair"
	btn_w_rep_min.pressed.connect(func(): _adjust_workers(-1, 0, 0))
	worker_grid.add_child(btn_w_rep_min)

	var btn_w_smith_min := Button.new()
	btn_w_smith_min.text = "- Smith"
	btn_w_smith_min.pressed.connect(func(): _adjust_workers(0, -1, 0))
	worker_grid.add_child(btn_w_smith_min)

	var btn_w_constr_min := Button.new()
	btn_w_constr_min.text = "- Constr"
	btn_w_constr_min.pressed.connect(func(): _adjust_workers(0, 0, -1))
	worker_grid.add_child(btn_w_constr_min)

	left_vbox.add_child(HSeparator.new())

	var lbl_sec_s := Label.new()
	lbl_sec_s.text = "=== DEPLOYED SOLDIERS ==="
	left_vbox.add_child(lbl_sec_s)

	_lbl_soldiers = Label.new()
	_lbl_soldiers.text = "Deployed Soldiers: -"
	left_vbox.add_child(_lbl_soldiers)

	left_vbox.add_child(HSeparator.new())

	var lbl_bld_title := Label.new()
	lbl_bld_title.text = "=== FASILITAS & KONSTRUKSI (PHASE 5) ==="
	left_vbox.add_child(lbl_bld_title)

	_lbl_construction_status = Label.new()
	_lbl_construction_status.text = "Proyek: Tidak ada proyek aktif"
	left_vbox.add_child(_lbl_construction_status)

	var constr_btn_hbox := HBoxContainer.new()
	left_vbox.add_child(constr_btn_hbox)

	var btn_start_c := Button.new()
	btn_start_c.text = "Mulai Proyek (50 Gold)"
	btn_start_c.pressed.connect(func(): _action_start_construction("barracks", 50, 100))
	constr_btn_hbox.add_child(btn_start_c)

	var btn_adv_c := Button.new()
	btn_adv_c.text = "+Progres (+25)"
	btn_adv_c.pressed.connect(func(): _action_advance_construction(25))
	constr_btn_hbox.add_child(btn_adv_c)

	var btn_canc_c := Button.new()
	btn_canc_c.text = "Batal Proyek"
	btn_canc_c.pressed.connect(func(): _action_cancel_construction())
	constr_btn_hbox.add_child(btn_canc_c)

	_buildings_container = VBoxContainer.new()
	left_vbox.add_child(_buildings_container)

	content_hbox.add_child(VSeparator.new())

	# KOLOM TENGAH: Action Panel, Feedback Banner & Telemetry Log
	var center_vbox := VBoxContainer.new()
	center_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(center_vbox)

	_lbl_feedback_banner = Label.new()
	_lbl_feedback_banner.text = "[INFO] Sistem siap. Lakukan persiapan untuk Wave 1."
	center_vbox.add_child(_lbl_feedback_banner)

	var panel_stage := PanelContainer.new()
	panel_stage.custom_minimum_size = Vector2(0, 260)
	var stage_scroll := ScrollContainer.new()
	panel_stage.add_child(stage_scroll)
	_panel_stage_actions = VBoxContainer.new()
	_panel_stage_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_scroll.add_child(_panel_stage_actions)
	center_vbox.add_child(panel_stage)

	var lbl_log_title := Label.new()
	lbl_log_title.text = "=== BATTLE & EVENT TELEMETRY LOG ==="
	center_vbox.add_child(lbl_log_title)

	_txt_telemetry_log = RichTextLabel.new()
	_txt_telemetry_log.bbcode_enabled = true
	_txt_telemetry_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_txt_telemetry_log.scroll_following = true
	center_vbox.add_child(_txt_telemetry_log)

	content_hbox.add_child(VSeparator.new())

	# KOLOM KANAN: Recruitment, Parties, Roster, Detail, Warehouse & Blacksmith
	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size = Vector2(340, 0)
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right_vbox)
	content_hbox.add_child(right_scroll)

	# 1. Hero Recruitment Section
	_lbl_recruitment = Label.new()
	_lbl_recruitment.text = "=== RECRUITMENT (MERCENARY GUILD) ==="
	right_vbox.add_child(_lbl_recruitment)

	_recruitment_container = VBoxContainer.new()
	right_vbox.add_child(_recruitment_container)

	right_vbox.add_child(HSeparator.new())

	# 2. Party Management Section
	_lbl_parties = Label.new()
	_lbl_parties.text = "=== PARTY MANAGEMENT (PHASE 4F) ==="
	right_vbox.add_child(_lbl_parties)

	_party_container = VBoxContainer.new()
	right_vbox.add_child(_party_container)

	right_vbox.add_child(HSeparator.new())

	# 3. Hero Roster Section
	var lbl_sec3 := Label.new()
	lbl_sec3.text = "=== HERO ROSTER ==="
	right_vbox.add_child(lbl_sec3)

	_lbl_heroes = Label.new()
	_lbl_heroes.text = "Loading Heroes..."
	right_vbox.add_child(_lbl_heroes)

	_hero_container = VBoxContainer.new()
	right_vbox.add_child(_hero_container)

	right_vbox.add_child(HSeparator.new())

	# 4. Hero Detail Panel Section
	_lbl_hero_detail = Label.new()
	_lbl_hero_detail.text = "=== HERO DETAIL PANEL ==="
	right_vbox.add_child(_lbl_hero_detail)

	_hero_detail_container = VBoxContainer.new()
	right_vbox.add_child(_hero_detail_container)

	right_vbox.add_child(HSeparator.new())

	# 5. Shared Warehouse Conservation
	var lbl_sec4 := Label.new()
	lbl_sec4.text = "=== SHARED WAREHOUSE CONSERVATION ==="
	right_vbox.add_child(lbl_sec4)

	_lbl_warehouse = Label.new()
	_lbl_warehouse.text = "Loading Equipment..."
	right_vbox.add_child(_lbl_warehouse)

	right_vbox.add_child(HSeparator.new())

	# 6. Blacksmith Workshop
	var lbl_sec5 := Label.new()
	lbl_sec5.text = "=== BLACKSMITH WORKSHOP (REPAIR) ==="
	right_vbox.add_child(lbl_sec5)

	_blacksmith_container = VBoxContainer.new()
	right_vbox.add_child(_blacksmith_container)

	# 3. Bottom Action Bar (Wireframe Reference)
	var bottom_panel := PanelContainer.new()
	var bottom_hbox := HBoxContainer.new()
	bottom_panel.add_child(bottom_hbox)
	main_vbox.add_child(bottom_panel)

	_btn_start_battle = Button.new()
	_btn_start_battle.name = "BtnStartBattle"
	_btn_start_battle.text = "Start Battle (Hanya pada Wave Preview)"
	_btn_start_battle.disabled = true
	_btn_start_battle.custom_minimum_size = Vector2(160, 44)
	_btn_start_battle.pressed.connect(func(): _action_start_battle())
	bottom_hbox.add_child(_btn_start_battle)

	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(bottom_spacer)

	_btn_action = Button.new()
	_btn_action.text = "Aksi / Bantuan Manajemen"
	_btn_action.pressed.connect(func(): _set_feedback("[BANTUAN] Kelola benteng, alokasikan pekerja, perbaiki struktur pertahanan, atau bangun fasilitas."))
	bottom_hbox.add_child(_btn_action)

	_log("Prototype initialized. Ready.")


# ==============================================================================
# STATE CHANGED & REACTIVE UI RENDERING
# ==============================================================================

func _on_state_changed(snapshot: GameStateSnapshot) -> void:
	if snapshot == null:
		return
	_last_snapshot = snapshot

	# Header updates
	_lbl_state_badge.text = "[STATE: %s]" % snapshot.game_phase
	_lbl_wave_indicator.text = "Wave: %d / 100" % snapshot.current_wave
	var pause_str: String = "PAUSED" if snapshot.battle_paused else "Active"
	_lbl_speed_pause.text = "Speed: %.1fx (%s) | Tick: %d" % [snapshot.battle_speed, pause_str, snapshot.battle_tick]

	# Phase Guidance Banner
	_lbl_phase_guidance.text = _get_phase_guidance_text(snapshot.game_phase)

	# Bottom Start Battle Button update
	if _btn_start_battle != null:
		if snapshot.game_phase == "WAVE_PREVIEW":
			_btn_start_battle.text = "⚔ START BATTLE ⚔"
			_btn_start_battle.disabled = false
		elif snapshot.game_phase == "BATTLE":
			_btn_start_battle.text = "⚔ Pertempuran Berlangsung ⚔"
			_btn_start_battle.disabled = true
		else:
			_btn_start_battle.text = "Start Battle (Hanya pada Wave Preview)"
			_btn_start_battle.disabled = true

	# Left Column updates
	var f_data: Dictionary = snapshot.fortress_data
	var cur_hp: int = int(f_data.get("current_hp", 0))
	var max_hp: int = int(f_data.get("max_hp", 1000))
	var armor: int = int(f_data.get("armor", 40))
	var is_dest: bool = bool(f_data.get("is_destroyed", false))
	_lbl_fortress_hp.text = "HP: %d / %d" % [cur_hp, max_hp]
	_lbl_fortress_armor.text = "Armor: %d | Status: %s" % [armor, "DESTROYED" if is_dest else "INTACT"]

	if _lbl_wall_hp != null:
		var w_hp: int = int(f_data.get("wall_hp", 500))
		var w_max: int = int(f_data.get("wall_max_hp", 500))
		_lbl_wall_hp.text = "Wall: %d / %d | Status: %s" % [w_hp, w_max, "BREACHED" if w_hp <= 0 else "INTACT"]

	if _lbl_gate_hp != null:
		var g_hp: int = int(f_data.get("gate_hp", 300))
		var g_max: int = int(f_data.get("gate_max_hp", 300))
		_lbl_gate_hp.text = "Gate: %d / %d | Status: %s" % [g_hp, g_max, "BREACHED" if g_hp <= 0 else "INTACT"]

	var e_data: Dictionary = snapshot.economy_data
	var p_data: Dictionary = snapshot.population_data
	var r_data: Dictionary = snapshot.resources_data
	_lbl_treasury.text = "Treasury: %d Gold | %d Cores | %d Materials" % [
		int(r_data.get("GOLD", e_data.get("treasury_gold", 0))),
		int(r_data.get("MONSTER_CORE", 0)),
		int(r_data.get("MONSTER_MATERIAL", 0))
	]
	_lbl_civilians.text = "Civilians: %d / %d | Morale: %d" % [
		int(p_data.get("civilians", 0)),
		int(p_data.get("housing_capacity", 30)),
		int(p_data.get("morale", 100))
	]

	if _lbl_population_summary != null:
		var civ_c: int = int(p_data.get("civilians", 0))
		var wrk_c: int = int(p_data.get("workers", 0))
		var sld_c: int = int(p_data.get("total_soldiers", 0))
		var tot_c: int = int(p_data.get("total_population", civ_c + wrk_c + sld_c))
		_lbl_population_summary.text = "Populasi: Sipil %d | Pekerja %d | Serdadu %d | Total: %d / %d" % [
			civ_c, wrk_c, sld_c, tot_c, int(p_data.get("housing_capacity", 30))
		]

	_lbl_workers.text = "Workers:\n- Repair: %d\n- Blacksmith: %d\n- Construction: %d\n- Idle: %d" % [
		int(e_data.get("repair_workers", 0)),
		int(e_data.get("blacksmith_workers", 0)),
		int(e_data.get("construction_workers", 0)),
		int(e_data.get("idle_workers", 0))
	]

	if _lbl_worker_morale_prod != null:
		var w_dict: Dictionary = snapshot.worker_data
		var w_mor: int = int(w_dict.get("morale", 100))
		var w_prod: float = float(w_dict.get("productivity", 1.0))
		_lbl_worker_morale_prod.text = "Moral Pekerja: %d/100 | Produktivitas: %.0f%%" % [w_mor, w_prod * 100.0]

	_render_buildings_panel(snapshot)
	_render_construction_panel(snapshot)

	var total_deployed: int = 0
	if controller != null:
		total_deployed = controller.get_total_deployed_soldiers()
	elif coordinator != null:
		total_deployed = coordinator.get_total_deployed_soldiers()
	else:
		for dep in snapshot.active_deployments_data:
			total_deployed += int(dep.get("count", 0))

	if total_deployed <= 0:
		_lbl_soldiers.text = "Deployed Soldiers: -"
	else:
		_lbl_soldiers.text = "Deployed Soldiers: %d" % total_deployed

	# Right Column updates
	_render_recruitment_panel(snapshot)
	_render_party_management(snapshot)
	_render_hero_roster(snapshot)
	_render_hero_detail_panel(snapshot)
	_render_warehouse_conservation(snapshot)
	_render_blacksmith_workshop(snapshot)

	# Center Action Panel rendering
	_render_stage_actions(snapshot)


func _get_phase_guidance_text(phase: String) -> String:
	match phase:
		"BOOT":
			return "Session in boot state. Click start to begin."
		"PREPARATION":
			return "Fase Persiapan — Konfigurasi pekerja, rekrutmen serdadu, penempatan regu, dan perlengkapan pahlawan."
		"WAVE_PREVIEW":
			return "Pratinjau Gelombang — Tinjau intelijen musuh dan finalisasi penempatan sebelum tempur."
		"BATTLE":
			return "Pertempuran Aktif — Seluruh konfigurasi regu, perlengkapan hero, dan alokasi gudang TERKUNCI (Battle Lock)."
		"RESULT":
			return "Hasil Pertempuran — Evaluasi kerusakan benteng, korban serdadu, status pahlawan, dan keausan perlengkapan."
		"RECOVERY":
			return "Pemulihan — Loot kas, reparasi, pemulihan fatigue hero, pertumbuhan populasi, dan pengembalian perlengkapan."
		"GAME_OVER":
			return "Benteng Runtuh — Pertahanan benteng gagal (HP 0). Sesi berakhir."
		_:
			return "Status fase tidak diketahui."


# ==============================================================================
# PHASE 4G HERO RECRUITMENT PANEL (RIGHT COLUMN)
# ==============================================================================

func _render_recruitment_panel(snapshot: GameStateSnapshot) -> void:
	if _recruitment_container == null:
		return
	for child in _recruitment_container.get_children():
		_recruitment_container.remove_child(child)
		child.queue_free()

	var gold: int = int(snapshot.economy_data.get("treasury_gold", 0))
	var cost: int = 500
	var is_battle: bool = (snapshot.game_phase == "BATTLE")
	var can_afford: bool = (gold >= cost)
	var can_rec: bool = (not is_battle and can_afford)

	var card := PanelContainer.new()
	var card_vbox := VBoxContainer.new()
	card.add_child(card_vbox)
	_recruitment_container.add_child(card)

	var lbl_cost := Label.new()
	lbl_cost.text = "Mercenary Guild | Biaya: %d Gold (Kas: %d Gold)" % [cost, gold]
	card_vbox.add_child(lbl_cost)

	# Role Picker
	var role_hbox := HBoxContainer.new()
	card_vbox.add_child(role_hbox)
	var lbl_pick := Label.new()
	lbl_pick.text = "Peran:"
	role_hbox.add_child(lbl_pick)

	var roles := ["KNIGHT", "ARCHER", "MAGE", "PRIEST"]
	for r in roles:
		var btn_r := Button.new()
		btn_r.name = "BtnPickRole_" + r
		btn_r.text = ("[%s]" if r == _selected_recruit_role else "%s") % r
		btn_r.disabled = is_battle
		btn_r.pressed.connect(func(role_choice=r):
			_selected_recruit_role = role_choice
			if _last_snapshot != null:
				_render_recruitment_panel(_last_snapshot)
		)
		role_hbox.add_child(btn_r)

	# Candidate Preview & Confirm Action
	var act_hbox := HBoxContainer.new()
	card_vbox.add_child(act_hbox)

	var lbl_cand := Label.new()
	lbl_cand.text = "Kandidat: Recruit %s (1★ / Potensi 3★)" % _selected_recruit_role.capitalize()
	lbl_cand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	act_hbox.add_child(lbl_cand)

	var btn_rec := Button.new()
	btn_rec.name = "BtnRecruitHero"
	if is_battle:
		btn_rec.text = "Terkunci (Battle Lock)"
		btn_rec.disabled = true
	elif not can_afford:
		btn_rec.text = "Kas Tidak Cukup (%d/500 G)" % gold
		btn_rec.disabled = true
	else:
		btn_rec.text = "Konfirmasi Rekrut (500 G)"
		btn_rec.disabled = false

	btn_rec.pressed.connect(func(): _action_recruit_hero())
	act_hbox.add_child(btn_rec)


# ==============================================================================
# PHASE 4G PARTY MANAGEMENT (RIGHT COLUMN)
# ==============================================================================

func _render_party_management(snapshot: GameStateSnapshot) -> void:
	if _party_container == null:
		return
	for child in _party_container.get_children():
		_party_container.remove_child(child)
		child.queue_free()

	var is_battle: bool = (snapshot.game_phase == "BATTLE")

	# Render PARTY 1
	var p1_panel := PanelContainer.new()
	var p1_vbox := VBoxContainer.new()
	p1_panel.add_child(p1_vbox)
	_party_container.add_child(p1_panel)

	var p1_data: Dictionary = {}
	var p2_data: Dictionary = {}
	for p in snapshot.parties_data:
		if p.get("party_id", "") == "party_1":
			p1_data = p
		elif p.get("party_id", "") == "party_2":
			p2_data = p

	var p1_leader: String = str(p1_data.get("leader_hero_id", ""))
	var p1_members: Array = p1_data.get("member_hero_ids", [])

	var lbl_p1 := Label.new()
	lbl_p1.text = "PARTY 1 (Active Battle Party) — Anggota: %d/3 | Pemimpin: %s" % [
		p1_members.size(),
		p1_leader if not p1_leader.is_empty() else "(Belum Ada)"
	]
	p1_vbox.add_child(lbl_p1)

	if p1_members.is_empty():
		var lbl_empty := Label.new()
		lbl_empty.text = "  (Party 1 kosong — Tugaskan pahlawan dari cadangan)"
		p1_vbox.add_child(lbl_empty)
	else:
		for m_id in p1_members:
			var m_box := HBoxContainer.new()
			p1_vbox.add_child(m_box)
			var h_info: String = str(m_id)
			for hd in snapshot.heroes_data:
				if hd.get("hero_id", "") == m_id:
					h_info = "%s (Lv.%d %s)" % [hd.get("hero_name", m_id), hd.get("level", 1), hd.get("role", "")]
					break
			if m_id == p1_leader:
				h_info += " [LEADER]"

			var lbl_m := Label.new()
			lbl_m.text = h_info
			lbl_m.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			m_box.add_child(lbl_m)

			if m_id != p1_leader:
				var btn_lead := Button.new()
				btn_lead.name = "BtnSetLeader_party_1_" + str(m_id)
				btn_lead.text = "Jadikan Leader"
				btn_lead.disabled = is_battle
				btn_lead.pressed.connect(func(hid=m_id): _action_set_party_leader(hid, "party_1"))
				m_box.add_child(btn_lead)

			var btn_rem := Button.new()
			btn_rem.name = "BtnRemoveParty_party_1_" + str(m_id)
			btn_rem.text = "Lepas"
			btn_rem.disabled = is_battle
			btn_rem.pressed.connect(func(hid=m_id): _action_remove_hero_from_party(hid))
			m_box.add_child(btn_rem)

	# Render PARTY 2
	var p2_panel := PanelContainer.new()
	var p2_vbox := VBoxContainer.new()
	p2_panel.add_child(p2_vbox)
	_party_container.add_child(p2_panel)

	var p2_leader: String = str(p2_data.get("leader_hero_id", ""))
	var p2_members: Array = p2_data.get("member_hero_ids", [])

	var lbl_p2 := Label.new()
	lbl_p2.text = "PARTY 2 (Management Reserve) — Anggota: %d/3 | Pemimpin: %s" % [
		p2_members.size(),
		p2_leader if not p2_leader.is_empty() else "(Belum Ada)"
	]
	p2_vbox.add_child(lbl_p2)

	if p2_members.is_empty():
		var lbl_empty2 := Label.new()
		lbl_empty2.text = "  (Party 2 kosong)"
		p2_vbox.add_child(lbl_empty2)
	else:
		for m_id in p2_members:
			var m_box2 := HBoxContainer.new()
			p2_vbox.add_child(m_box2)
			var h_info2: String = str(m_id)
			for hd in snapshot.heroes_data:
				if hd.get("hero_id", "") == m_id:
					h_info2 = "%s (Lv.%d %s)" % [hd.get("hero_name", m_id), hd.get("level", 1), hd.get("role", "")]
					break
			if m_id == p2_leader:
				h_info2 += " [LEADER]"

			var lbl_m2 := Label.new()
			lbl_m2.text = h_info2
			lbl_m2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			m_box2.add_child(lbl_m2)

			if m_id != p2_leader:
				var btn_lead2 := Button.new()
				btn_lead2.name = "BtnSetLeader_party_2_" + str(m_id)
				btn_lead2.text = "Jadikan Leader"
				btn_lead2.disabled = is_battle
				btn_lead2.pressed.connect(func(hid=m_id): _action_set_party_leader(hid, "party_2"))
				m_box2.add_child(btn_lead2)

			var btn_rem2 := Button.new()
			btn_rem2.name = "BtnRemoveParty_party_2_" + str(m_id)
			btn_rem2.text = "Lepas"
			btn_rem2.disabled = is_battle
			btn_rem2.pressed.connect(func(hid=m_id): _action_remove_hero_from_party(hid))
			m_box2.add_child(btn_rem2)

	# Render RESERVE
	var res_panel := PanelContainer.new()
	var res_vbox := VBoxContainer.new()
	res_panel.add_child(res_vbox)
	_party_container.add_child(res_panel)

	var lbl_res := Label.new()
	lbl_res.text = "RESERVE (Pahlawan Cadangan):"
	res_vbox.add_child(lbl_res)

	var reserve_heroes: Array = []
	for hd in snapshot.heroes_data:
		var pid: String = str(hd.get("party_id", ""))
		var alive: bool = bool(hd.get("is_alive", true))
		if pid.is_empty() and alive:
			reserve_heroes.append(hd)

	if reserve_heroes.is_empty():
		var lbl_no_res := Label.new()
		lbl_no_res.text = "  (Tidak ada pahlawan di cadangan)"
		res_vbox.add_child(lbl_no_res)
	else:
		for rh in reserve_heroes:
			var rh_id: String = str(rh.get("hero_id", ""))
			var rh_name: String = str(rh.get("hero_name", rh_id))
			var rh_lvl: int = int(rh.get("level", 1))
			var rh_role: String = str(rh.get("role", ""))

			var r_box := HBoxContainer.new()
			res_vbox.add_child(r_box)

			var lbl_rh := Label.new()
			lbl_rh.text = "%s (Lv.%d %s)" % [rh_name, rh_lvl, rh_role]
			lbl_rh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r_box.add_child(lbl_rh)

			var btn_p1 := Button.new()
			btn_p1.name = "BtnAssign_party_1_" + rh_id
			btn_p1.text = "+ Party 1"
			btn_p1.disabled = (is_battle or p1_members.size() >= 3)
			btn_p1.pressed.connect(func(hid=rh_id): _action_assign_hero_to_party(hid, "party_1"))
			r_box.add_child(btn_p1)

			var btn_p2 := Button.new()
			btn_p2.name = "BtnAssign_party_2_" + rh_id
			btn_p2.text = "+ Party 2"
			btn_p2.disabled = (is_battle or p2_members.size() >= 3)
			btn_p2.pressed.connect(func(hid=rh_id): _action_assign_hero_to_party(hid, "party_2"))
			r_box.add_child(btn_p2)


# ==============================================================================
# PHASE 4G HERO ROSTER (RIGHT COLUMN)
# ==============================================================================

func _render_hero_roster(snapshot: GameStateSnapshot) -> void:
	if _hero_container == null:
		return
	for child in _hero_container.get_children():
		_hero_container.remove_child(child)
		child.queue_free()

	if snapshot.heroes_data.is_empty():
		if _lbl_heroes != null:
			_lbl_heroes.text = "No heroes registered."
		return

	# Pastikan ada hero terpilih default
	if _selected_hero_id.is_empty():
		_selected_hero_id = str(snapshot.heroes_data[0].get("hero_id", ""))
	else:
		var found_selected: bool = false
		for h in snapshot.heroes_data:
			if str(h.get("hero_id", "")) == _selected_hero_id:
				found_selected = true
				break
		if not found_selected and not snapshot.heroes_data.is_empty():
			_selected_hero_id = str(snapshot.heroes_data[0].get("hero_id", ""))

	if _lbl_heroes != null:
		_lbl_heroes.text = "Active Heroes: %d | Terpilih: %s" % [snapshot.heroes_data.size(), _selected_hero_id]

	for h in snapshot.heroes_data:
		var hero_id: String = str(h.get("hero_id", ""))
		var name_str: String = str(h.get("hero_name", "Hero"))
		var role_str: String = str(h.get("role", "KNIGHT"))
		var lvl: int = int(h.get("level", 1))
		var cur_star: int = int(h.get("current_star", 1))
		var pot_star: int = int(h.get("potential_star", 3))
		var cur_exp: int = int(h.get("current_exp", 0))
		var req_exp: int = int(h.get("required_exp", 120))
		if req_exp <= 0:
			req_exp = int(floor(120.0 * pow(float(lvl), 1.55)))
		var fat: int = int(h.get("fatigue", 0))
		var mor: int = int(h.get("morale", 100))
		var lifecycle: String = str(h.get("lifecycle_state", "ROSTER_ACTIVE"))
		var pid: String = str(h.get("party_id", ""))
		var party_label: String = "RESERVE" if pid.is_empty() else pid.to_upper()
		var alive: bool = bool(h.get("is_alive", true))
		var is_selected: bool = (hero_id == _selected_hero_id)

		var hero_card := PanelContainer.new()
		var card_vbox := VBoxContainer.new()
		hero_card.add_child(card_vbox)
		_hero_container.add_child(hero_card)

		var status_str: String = "ALIVE" if alive else "DEAD (Permadeath)"
		var lbl_info := Label.new()
		lbl_info.text = "%s (Lv.%d) [%s] [%d★ / %d★] [%s]" % [
			name_str, lvl, role_str, cur_star, pot_star, status_str
		]
		card_vbox.add_child(lbl_info)

		var lbl_stats := Label.new()
		lbl_stats.text = "EXP: %d/%d | Fatigue: %d/100 | Morale: %d/150" % [
			cur_exp, req_exp, fat, mor
		]
		card_vbox.add_child(lbl_stats)

		var lbl_party := Label.new()
		lbl_party.text = "Status: [%s] | Regu: [%s]" % [lifecycle, party_label]
		card_vbox.add_child(lbl_party)

		var sel_hbox := HBoxContainer.new()
		card_vbox.add_child(sel_hbox)

		var btn_select := Button.new()
		btn_select.name = "BtnSelect_" + hero_id
		btn_select.text = "[TERPILIH]" if is_selected else "Pilih / Lihat Detail"
		btn_select.disabled = is_selected
		btn_select.pressed.connect(func(hid=hero_id):
			_selected_hero_id = hid
			if _last_snapshot != null:
				_render_hero_roster(_last_snapshot)
				_render_hero_detail_panel(_last_snapshot)
		)
		sel_hbox.add_child(btn_select)


# ==============================================================================
# PHASE 4G HERO DETAIL PANEL (RIGHT COLUMN)
# ==============================================================================

func _render_hero_detail_panel(snapshot: GameStateSnapshot) -> void:
	if _hero_detail_container == null:
		return
	for child in _hero_detail_container.get_children():
		_hero_detail_container.remove_child(child)
		child.queue_free()

	if _selected_hero_id.is_empty():
		var lbl_empty := Label.new()
		lbl_empty.text = "(Pilih pahlawan dari roster untuk melihat detail)"
		_hero_detail_container.add_child(lbl_empty)
		return

	var hero_data: Dictionary = {}
	for h in snapshot.heroes_data:
		if str(h.get("hero_id", "")) == _selected_hero_id:
			hero_data = h
			break

	if hero_data.is_empty():
		var lbl_none := Label.new()
		lbl_none.text = "(Pahlawan terpilih tidak ditemukan)"
		_hero_detail_container.add_child(lbl_none)
		return

	var hid: String = str(hero_data.get("hero_id", ""))
	var name_str: String = str(hero_data.get("hero_name", "Hero"))
	var role_str: String = str(hero_data.get("role", "KNIGHT"))
	var lvl: int = int(hero_data.get("level", 1))
	var cur_star: int = int(hero_data.get("current_star", 1))
	var pot_star: int = int(hero_data.get("potential_star", 3))
	var cur_exp: int = int(hero_data.get("current_exp", 0))
	var req_exp: int = int(hero_data.get("required_exp", 120))
	if req_exp <= 0:
		req_exp = int(floor(120.0 * pow(float(lvl), 1.55)))
	var cap: int = int(hero_data.get("level_cap", 10))
	var asc_cost: int = int(hero_data.get("ascension_cost", 150))
	var hp: int = int(hero_data.get("base_hp", 250))
	var b_atk: int = int(hero_data.get("base_atk", 35))
	var b_def: int = int(hero_data.get("base_def", 20))
	var eff_atk: int = int(hero_data.get("effective_atk", 35))
	var eff_def: int = int(hero_data.get("effective_def", 20))
	var fat: int = int(hero_data.get("fatigue", 0))
	var mor: int = int(hero_data.get("morale", 100))
	var lifecycle: String = str(hero_data.get("lifecycle_state", "ROSTER_ACTIVE"))
	var pid: String = str(hero_data.get("party_id", ""))
	var party_str: String = "RESERVE" if pid.is_empty() else pid.to_upper()
	var alive: bool = bool(hero_data.get("is_alive", true))
	var unlocked_skills: Array = hero_data.get("unlocked_skills", [])
	var t_points: int = int(hero_data.get("talent_points", 0))
	var alloc_talents: Dictionary = hero_data.get("allocated_talents", {})
	var t_atk_mult: float = float(hero_data.get("talent_atk_multiplier", 1.0))
	var t_def_mult: float = float(hero_data.get("talent_def_multiplier", 1.0))
	var chem_map: Dictionary = hero_data.get("chemistry_map", {})
	var prim: String = str(hero_data.get("primary_equipment", "NONE"))
	var sec: String = str(hero_data.get("secondary_equipment", "NONE"))
	var arm: String = str(hero_data.get("armor_equipment", "NONE"))
	var is_battle: bool = (snapshot.game_phase == "BATTLE")

	var card := PanelContainer.new()
	var card_vbox := VBoxContainer.new()
	card.add_child(card_vbox)
	_hero_detail_container.add_child(card)

	# --- 1. Identity & Combat Stats ---
	var lbl_title := Label.new()
	lbl_title.text = ">>> DETAIL: %s [%s] <<<" % [name_str, role_str]
	card_vbox.add_child(lbl_title)

	var lbl_ident := Label.new()
	lbl_ident.text = "Identitas: Bintang %d★ / %d★ | Status: %s | Regu: %s" % [
		cur_star, pot_star, "ALIVE" if alive else "DEAD (Permadeath)", party_str
	]
	card_vbox.add_child(lbl_ident)

	var lbl_prog := Label.new()
	lbl_prog.text = "Level: %d (Level Cap: %d) | EXP: %d / %d | Lifecycle: %s" % [
		lvl, cap, cur_exp, req_exp, lifecycle
	]
	card_vbox.add_child(lbl_prog)

	var lbl_stats := Label.new()
	lbl_stats.text = "Combat Stats: HP: %d | ATK: %d (Base: %d) | DEF: %d (Base: %d)" % [
		hp, eff_atk, b_atk, eff_def, b_def
	]
	card_vbox.add_child(lbl_stats)

	var lbl_cond := Label.new()
	lbl_cond.text = "Kondisi: Fatigue: %d/100 | Morale: %d/150" % [fat, mor]
	card_vbox.add_child(lbl_cond)

	if not alive:
		var dead_lbl := Label.new()
		dead_lbl.text = "[PERMADEATH: Pahlawan gugur permanen. Seluruh aksi terkunci.]"
		card_vbox.add_child(dead_lbl)
		return

	if is_battle:
		var battle_lbl := Label.new()
		battle_lbl.text = "[BATTLE LOCK: Seluruh mutasi pahlawan terkunci selama pertempuran.]"
		card_vbox.add_child(battle_lbl)

	card_vbox.add_child(HSeparator.new())

	# --- 2. Progression Actions: Ascension, Training, Rest ---
	var act_header := Label.new()
	act_header.text = "-- Aksi Progresi & Pemulihan --"
	card_vbox.add_child(act_header)

	var prog_hbox := HBoxContainer.new()
	card_vbox.add_child(prog_hbox)

	# Ascension Button
	var btn_asc := Button.new()
	btn_asc.name = "BtnAscendHero"
	var can_asc_coord: bool = controller.can_ascend_hero(hid) if controller else false
	btn_asc.text = "Ascend (+1★) [%d G]" % asc_cost
	btn_asc.disabled = not can_asc_coord
	btn_asc.pressed.connect(func(): _action_ascend_hero(hid))
	prog_hbox.add_child(btn_asc)

	# Training Button
	var btn_train := Button.new()
	btn_train.name = "BtnTrainHero"
	var can_train: bool = controller.can_train_hero(hid) if controller else false
	btn_train.text = "Latihan (+40 EXP, +15 Fat)"
	btn_train.disabled = not can_train
	btn_train.pressed.connect(func(): _action_train_hero(hid))
	prog_hbox.add_child(btn_train)

	# Rest Button
	var btn_rest := Button.new()
	btn_rest.name = "BtnRestHero"
	var can_rest: bool = controller.can_rest_hero(hid) if controller else false
	btn_rest.text = "Istirahat (-25 Fat, +5 Mor)"
	btn_rest.disabled = not can_rest
	btn_rest.pressed.connect(func(): _action_rest_hero(hid))
	prog_hbox.add_child(btn_rest)

	card_vbox.add_child(HSeparator.new())

	# --- 3. Canonical Skills Catalog ---
	var skill_header := Label.new()
	skill_header.text = "-- Keahlian Kanonikal (%s) --" % role_str
	card_vbox.add_child(skill_header)

	var canon_skills: Array = HeroSkill.get_skills_for_role(role_str)
	for sk in canon_skills:
		if sk is HeroSkill:
			var s_obj := sk as HeroSkill
			var s_box := HBoxContainer.new()
			card_vbox.add_child(s_box)

			var is_unlocked: bool = (s_obj.skill_id in unlocked_skills)
			var can_unlock: bool = controller.can_unlock_hero_skill(hid, s_obj.skill_id) if controller else false

			var status_tag: String = "[TERBUKA]" if is_unlocked else "[TERKUNCI]"
			var lbl_sk := Label.new()
			lbl_sk.text = "%s %s (Lv.%d req) - %s (+%.0f%%)" % [
				status_tag, s_obj.skill_name, s_obj.required_level, s_obj.skill_type, (s_obj.power_multiplier - 1.0) * 100.0
			]
			lbl_sk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			s_box.add_child(lbl_sk)

			var btn_unl := Button.new()
			btn_unl.name = "BtnUnlockSkill_" + s_obj.skill_id
			btn_unl.text = "Terbuka" if is_unlocked else "Buka Skill"
			btn_unl.disabled = (is_unlocked or not can_unlock)
			btn_unl.pressed.connect(func(sid=s_obj.skill_id): _action_unlock_skill(hid, sid))
			s_box.add_child(btn_unl)

	card_vbox.add_child(HSeparator.new())

	# --- 4. Talent Tree ---
	var talent_header := Label.new()
	talent_header.text = "-- Pohon Bakat (Poin Tersedia: %d) --" % t_points
	card_vbox.add_child(talent_header)

	var mult_lbl := Label.new()
	mult_lbl.text = "Pengali Bakat: ATK x%.2f | DEF x%.2f" % [t_atk_mult, t_def_mult]
	card_vbox.add_child(mult_lbl)

	var branches := ["OFFENSE", "DEFENSE", "LEADERSHIP"]
	for br in branches:
		var br_box := HBoxContainer.new()
		card_vbox.add_child(br_box)

		var cur_lvl: int = int(alloc_talents.get(br, 0))
		var desc: String = ""
		match br:
			"OFFENSE": desc = "+2% ATK per tingkat"
			"DEFENSE": desc = "+2% DEF per tingkat"
			"LEADERSHIP": desc = "+1% ATK & +1% DEF per tingkat"

		var lbl_br := Label.new()
		lbl_br.text = "%-11s: Lv.%d/3 (%s)" % [br, cur_lvl, desc]
		lbl_br.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		br_box.add_child(lbl_br)

		var can_alloc: bool = controller.can_allocate_hero_talent(hid, br) if controller else false
		var btn_alloc := Button.new()
		btn_alloc.name = "BtnAllocateTalent_" + br
		btn_alloc.text = "Maks" if cur_lvl >= 3 else "Alokasikan (+1)"
		btn_alloc.disabled = (cur_lvl >= 3 or not can_alloc)
		btn_alloc.pressed.connect(func(branch=br): _action_allocate_talent(hid, branch))
		br_box.add_child(btn_alloc)

	card_vbox.add_child(HSeparator.new())

	# --- 5. Chemistry Information (Display Only) ---
	var chem_header := Label.new()
	chem_header.text = "-- Kemitraan Tempur (Chemistry - Display Only) --"
	card_vbox.add_child(chem_header)

	if chem_map.is_empty():
		var no_chem := Label.new()
		no_chem.text = "  (Belum ada chemistry — terbentuk dari pertempuran bersama di Party 1)"
		card_vbox.add_child(no_chem)
	else:
		for partner_id in chem_map:
			var pts: int = int(chem_map[partner_id])
			var bonus_pct: float = float(pts) * 0.5
			var partner_name: String = str(partner_id)
			for hd in snapshot.heroes_data:
				if hd.get("hero_id", "") == partner_id:
					partner_name = str(hd.get("hero_name", partner_id))
					break
			var chem_lbl := Label.new()
			chem_lbl.text = "  - Kemitraan dengan %s: %d / 50 poin (+%.1f%% efektivitas bersama)" % [
				partner_name, pts, bonus_pct
			]
			card_vbox.add_child(chem_lbl)

	card_vbox.add_child(HSeparator.new())

	# --- 6. Equipment Controls (Existing Shared Warehouse APIs) ---
	var eq_header := Label.new()
	eq_header.text = "-- Perlengkapan Terpasang --"
	card_vbox.add_child(eq_header)

	var cur_gear_lbl := Label.new()
	cur_gear_lbl.text = "Saat Ini: [Primary: %s | Secondary: %s | Armor: %s]" % [prim, sec, arm]
	card_vbox.add_child(cur_gear_lbl)

	if not is_battle:
		# Primary Slot
		var p_hbox := HBoxContainer.new()
		card_vbox.add_child(p_hbox)
		var p_label := Label.new()
		p_label.text = "Primary:"
		p_hbox.add_child(p_label)

		if prim != "NONE":
			var btn_unequip_p := Button.new()
			btn_unequip_p.text = "Lepas (%s)" % prim
			btn_unequip_p.pressed.connect(func(): _action_unequip_hero(hid, "PRIMARY"))
			p_hbox.add_child(btn_unequip_p)
		else:
			for w_type in ["SWORD", "SPEAR", "BOW"]:
				var stock_val: int = _get_warehouse_stock(w_type)
				var btn_equip := Button.new()
				btn_equip.text = "+%s (%d)" % [w_type, stock_val]
				btn_equip.disabled = (stock_val < 1)
				btn_equip.pressed.connect(func(eq=w_type): _action_equip_hero(hid, "PRIMARY", eq))
				p_hbox.add_child(btn_equip)

		# Secondary Slot
		var s_hbox := HBoxContainer.new()
		card_vbox.add_child(s_hbox)
		var s_label := Label.new()
		s_label.text = "Secondary:"
		s_hbox.add_child(s_label)

		if sec != "NONE":
			var btn_unequip_s := Button.new()
			btn_unequip_s.text = "Lepas (%s)" % sec
			btn_unequip_s.pressed.connect(func(): _action_unequip_hero(hid, "SECONDARY"))
			s_hbox.add_child(btn_unequip_s)
		else:
			var shield_stock: int = _get_warehouse_stock("SHIELD")
			var btn_shield := Button.new()
			btn_shield.text = "+SHIELD (%d)" % shield_stock
			btn_shield.disabled = (shield_stock < 1 or prim == "SHIELD")
			btn_shield.pressed.connect(func(): _action_equip_hero(hid, "SECONDARY", "SHIELD"))
			s_hbox.add_child(btn_shield)

		# Armor Slot
		var a_hbox := HBoxContainer.new()
		card_vbox.add_child(a_hbox)
		var a_label := Label.new()
		a_label.text = "Armor:"
		a_hbox.add_child(a_label)

		if arm != "NONE":
			var btn_unequip_a := Button.new()
			btn_unequip_a.text = "Lepas (%s)" % arm
			btn_unequip_a.pressed.connect(func(): _action_unequip_hero(hid, "ARMOR"))
			a_hbox.add_child(btn_unequip_a)
		else:
			var armor_stock: int = _get_warehouse_stock("HEAVY_ARMOR")
			var btn_armor := Button.new()
			btn_armor.text = "+ARMOR (%d)" % armor_stock
			btn_armor.disabled = (armor_stock < 1)
			btn_armor.pressed.connect(func(): _action_equip_hero(hid, "ARMOR", "HEAVY_ARMOR"))
			a_hbox.add_child(btn_armor)


# ==============================================================================
# PHASE 4G ACTION HANDLERS
# ==============================================================================

func _action_recruit_hero() -> void:
	if controller == null:
		return
	if not controller.can_recruit_hero():
		_set_feedback("[DITOLAK] Gagal merekrut: Kas tidak mencukupi (500 Gold) atau Battle Lock aktif.")
		return
	var new_hero = controller.recruit_hero(_selected_recruit_role)
	if new_hero != null:
		_selected_hero_id = new_hero.hero_id
		_set_feedback("[REKRUTMEN] Berhasil merekrut pahlawan baru: %s (%s, 1★/3★) seharga 500 Gold." % [new_hero.hero_name, new_hero.role])
	else:
		_set_feedback("[DITOLAK] Gagal merekrut pahlawan baru.")


func _action_ascend_hero(hero_id: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.ascend_hero(hero_id)
	if ok:
		_set_feedback("[ASCENSION] Pahlawan %s berhasil naik bintang (+1★)!" % hero_id)
	else:
		_set_feedback("[DITOLAK] Ascension %s ditolak: Syarat level cap / emas belum terpenuhi atau Battle Lock aktif." % hero_id)


func _action_train_hero(hero_id: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.train_hero(hero_id)
	if ok:
		_set_feedback("[LATIHAN] Sesi latihan %s berhasil (+40 EXP, +15 Fatigue)." % hero_id)
	else:
		_set_feedback("[DITOLAK] Latihan %s ditolak: Sudah latihan pada gelombang ini, kelelahan melampaui batas, atau Battle Lock aktif." % hero_id)


func _action_rest_hero(hero_id: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.rest_hero(hero_id)
	if ok:
		_set_feedback("[ISTIRAHAT] Pahlawan %s beristirahat (-25 Fatigue, +5 Morale)." % hero_id)
	else:
		_set_feedback("[DITOLAK] Istirahat %s ditolak: Battle Lock aktif." % hero_id)


func _action_unlock_skill(hero_id: String, skill_id: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.unlock_hero_skill(hero_id, skill_id)
	if ok:
		_set_feedback("[SKILL] Berhasil membuka keahlian [%s] untuk pahlawan %s!" % [skill_id, hero_id])
	else:
		_set_feedback("[DITOLAK] Gagal membuka skill %s: Level belum memenuhi atau Battle Lock aktif." % skill_id)


func _action_allocate_talent(hero_id: String, branch_id: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.allocate_hero_talent(hero_id, branch_id)
	if ok:
		_set_feedback("[BAKAT] Berhasil mengalokasikan 1 poin bakat ke cabang [%s] untuk %s!" % [branch_id, hero_id])
	else:
		_set_feedback("[DITOLAK] Gagal alokasi bakat %s: Poin tidak cukup, cabang sudah maksimal, atau Battle Lock aktif." % branch_id)


func _action_assign_hero_to_party(hero_id: String, party_id: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.assign_hero_to_party(hero_id, party_id)
	if ok:
		_set_feedback("[REGU] Pahlawan %s berhasil ditugaskan ke [%s]." % [hero_id, party_id])
	else:
		_set_feedback("[DITOLAK] Penugasan %s ke %s ditolak: Regu penuh, pahlawan sudah berada di regu lain, atau Battle Lock aktif." % [hero_id, party_id])


func _action_remove_hero_from_party(hero_id: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.remove_hero_from_party(hero_id)
	if ok:
		_set_feedback("[REGU] Pahlawan %s dikeluarkan dari regu (kembali ke RESERVE)." % hero_id)
	else:
		_set_feedback("[DITOLAK] Gagal mengeluarkan %s dari regu: Battle Lock aktif." % hero_id)


func _action_set_party_leader(hero_id: String, party_id: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.set_party_leader(hero_id, party_id)
	if ok:
		_set_feedback("[LEADER] Pahlawan %s ditetapkan sebagai pemimpin [%s]." % [hero_id, party_id])
	else:
		_set_feedback("[DITOLAK] Gagal menetapkan pemimpin %s untuk %s: Bukan anggota regu atau Battle Lock aktif." % [hero_id, party_id])


# ==============================================================================
# SHARED WAREHOUSE CONSERVATION RENDERING (RIGHT COLUMN)
# ==============================================================================

func _render_warehouse_conservation(snapshot: GameStateSnapshot) -> void:
	var lines: Array[String] = []
	lines.append("[Invariant: Total Owned = Usable + Damaged + Hero + Soldier]")
	lines.append("ITEM         | USBL | DMGD | HERO | REGD | TOTAL")
	lines.append("-------------------------------------------------")

	var item_types := ["SWORD", "SHIELD", "SPEAR", "BOW", "HEAVY_ARMOR"]
	for t in item_types:
		var usable_stock: int = _get_warehouse_usable_stock(t)
		var damaged_stock: int = _get_warehouse_damaged_stock(t)
		var res_stock: int = _get_reserved_equipment_stock(t)
		var tot_stock: int = _get_total_owned_stock(t)
		var hero_stock: int = maxi(0, tot_stock - (usable_stock + damaged_stock) - res_stock)
		lines.append("%-12s |  %2d  |  %2d  |  %2d  |  %2d  |  %2d" % [
			t, usable_stock, damaged_stock, hero_stock, res_stock, tot_stock
		])

	lines.append("-------------------------------------------------")
	lines.append("Kondisi Fisik di Gudang:")
	var wh_list: Array = snapshot.warehouse_data
	if wh_list.is_empty():
		lines.append("  (Gudang kosong)")
	else:
		for eq in wh_list:
			var r: String = str(eq.get("role_type", ""))
			var dur: int = int(eq.get("durability", 100))
			var qty: int = int(eq.get("quantity", 0))
			var broken: bool = bool(eq.get("is_broken", false))
			var status_tag: String = ""
			if broken:
				status_tag = " [BROKEN]"
			elif dur < 100:
				status_tag = " [DAMAGED]"
			lines.append("  - %s: %d unit (Dur: %d%%%s)" % [
				r, qty, dur, status_tag
			])

	_lbl_warehouse.text = "\n".join(lines)


func _render_blacksmith_workshop(snapshot: GameStateSnapshot) -> void:
	if _blacksmith_container == null:
		return
	for child in _blacksmith_container.get_children():
		child.queue_free()

	var smith_workers: int = 0
	var smith_discount: float = 0.0
	if controller != null:
		smith_workers = controller.get_blacksmith_workers()
		smith_discount = controller.get_blacksmith_discount()
	elif coordinator != null:
		smith_workers = coordinator.get_blacksmith_workers()
		smith_discount = coordinator.get_blacksmith_discount()

	var info_lbl := Label.new()
	info_lbl.text = "Blacksmith Workers: %d (Discount: %.0f%%)" % [smith_workers, smith_discount * 100.0]
	_blacksmith_container.add_child(info_lbl)

	var has_damaged: bool = false
	var is_battle: bool = (snapshot.game_phase == "BATTLE")
	var treasury: int = int(snapshot.economy_data.get("treasury_gold", 0))

	var item_types := ["SWORD", "SHIELD", "SPEAR", "BOW", "HEAVY_ARMOR"]
	for t in item_types:
		var dmg_qty: int = _get_warehouse_damaged_stock(t)
		if dmg_qty > 0:
			has_damaged = true
			var cost: int = 0
			if controller != null:
				cost = controller.get_equipment_repair_cost(t, 1)
			elif coordinator != null:
				cost = coordinator.get_equipment_repair_cost(t, 1)

			var row := HBoxContainer.new()
			_blacksmith_container.add_child(row)

			var row_lbl := Label.new()
			row_lbl.text = "• %s: %d rusak | Biaya: %d Gold/unit" % [t, dmg_qty, cost]
			row.add_child(row_lbl)

			var btn_rep := Button.new()
			btn_rep.text = "Repair 1x (%d Gold)" % cost
			var can_afford: bool = (treasury >= cost)
			btn_rep.disabled = (not can_afford) or is_battle or (controller == null)
			if not can_afford:
				btn_rep.text += " [Not enough Gold]"
			elif is_battle:
				btn_rep.text += " [BATTLE LOCK]"
			btn_rep.pressed.connect(func(eq_t=t): _action_repair_equipment(eq_t, 1))
			row.add_child(btn_rep)

	if not has_damaged:
		var empty_lbl := Label.new()
		empty_lbl.text = "(Tidak ada perlengkapan rusak di gudang. Semua perlengkapan 100% usable.)"
		_blacksmith_container.add_child(empty_lbl)


# ==============================================================================
# ACTION PANEL RENDERING (CENTER COLUMN)
# ==============================================================================

func _render_stage_actions(snapshot: GameStateSnapshot) -> void:
	if snapshot.game_phase == "BATTLE":
		_render_tactical_battle_ui(snapshot)
		return

	_battlefield_panel = null
	_zone_panels.clear()
	_zone_labels.clear()
	_zone_status_labels.clear()
	_zone_detail_labels.clear()
	_result_overlay = null
	_game_over_overlay = null

	for child in _panel_stage_actions.get_children():
		_panel_stage_actions.remove_child(child)
		child.queue_free()

	match snapshot.game_phase:
		"BOOT":
			var lbl := Label.new()
			lbl.text = "Session in BOOT state. Click to start preparation."
			_panel_stage_actions.add_child(lbl)
			var btn_start := Button.new()
			btn_start.text = "START SESSION"
			btn_start.pressed.connect(func(): if controller: controller.restart_session())
			_panel_stage_actions.add_child(btn_start)

		"PREPARATION":
			var lbl := Label.new()
			lbl.text = "=== FASE PERSIAPAN: REKRUTMEN MILITER ==="
			_panel_stage_actions.add_child(lbl)

			var recruit_hbox := HBoxContainer.new()
			_panel_stage_actions.add_child(recruit_hbox)

			var btn_r_sword := Button.new()
			btn_r_sword.text = "+ Swordsman"
			btn_r_sword.pressed.connect(func(): _recruit("SWORDSMAN"))
			recruit_hbox.add_child(btn_r_sword)

			var btn_r_shield := Button.new()
			btn_r_shield.text = "+ Shield"
			btn_r_shield.pressed.connect(func(): _recruit("SHIELD_INFANTRY"))
			recruit_hbox.add_child(btn_r_shield)

			var btn_r_archer := Button.new()
			btn_r_archer.text = "+ Archer"
			btn_r_archer.pressed.connect(func(): _recruit("ARCHER"))
			recruit_hbox.add_child(btn_r_archer)

			var btn_r_spear := Button.new()
			btn_r_spear.text = "+ Spear"
			btn_r_spear.pressed.connect(func(): _recruit("SPEARMAN"))
			recruit_hbox.add_child(btn_r_spear)

			var btn_r_heavy := Button.new()
			btn_r_heavy.text = "+ Heavy"
			btn_r_heavy.pressed.connect(func(): _recruit("HEAVY_INFANTRY"))
			recruit_hbox.add_child(btn_r_heavy)

			_render_deployment_controls(snapshot)

			var btn_inspect := Button.new()
			btn_inspect.text = ">> INSPECT NEXT WAVE (WAVE PREVIEW) >>"
			btn_inspect.pressed.connect(func(): _action_inspect_wave())
			_panel_stage_actions.add_child(btn_inspect)

		"WAVE_PREVIEW":
			var lbl := Label.new()
			lbl.text = "=== WAVE PREVIEW (THREAT INTEL) ==="
			_panel_stage_actions.add_child(lbl)

			var w_data: Dictionary = snapshot.current_wave_data
			var threat: int = int(w_data.get("threat_budget", 0))
			var enemies: Dictionary = w_data.get("enemies", {})

			var info_lbl := Label.new()
			info_lbl.text = "Threat Budget: %d\nEnemy Composition: Minion: %d, Raider: %d, Brute: %d, Flyer: %d, Siege: %d, Boss: %d" % [
				threat,
				int(enemies.get("MINION", 0)),
				int(enemies.get("RAIDER", 0)),
				int(enemies.get("BRUTE", 0)),
				int(enemies.get("FLYER", 0)),
				int(enemies.get("SIEGE", 0)),
				int(enemies.get("BOSS", 0))
			]
			_panel_stage_actions.add_child(info_lbl)

			_render_deployment_controls(snapshot)

			# Dead-end check: jika serdadu belum ditempatkan sama sekali
			var avail_cnt: int = int(snapshot.available_soldiers_count)
			if snapshot.active_deployments_data.is_empty() and avail_cnt > 0:
				var warn_lbl := Label.new()
				warn_lbl.text = "[PERHATIAN: Ada %d serdadu tersedia yang belum ditempatkan ke dalam regu tempur!]" % avail_cnt
				_panel_stage_actions.add_child(warn_lbl)

			var btn_hbox := HBoxContainer.new()
			_panel_stage_actions.add_child(btn_hbox)

			var btn_start_battle := Button.new()
			btn_start_battle.text = "⚔ START BATTLE ⚔"
			btn_start_battle.pressed.connect(func(): _action_start_battle())
			btn_hbox.add_child(btn_start_battle)

			var btn_cancel := Button.new()
			btn_cancel.text = "Back to Preparation"
			btn_cancel.pressed.connect(func(): if controller: controller.cancel_wave_preview())
			btn_hbox.add_child(btn_cancel)

		"BATTLE":
			_render_tactical_battle_ui(snapshot)

		"RESULT":
			_render_battle_result_ui(snapshot)

		"GAME_OVER":
			_render_game_over_ui(snapshot)


# ==============================================================================
# SOLDIER DEPLOYMENT CONTROLS & RECONFIGURATION (PHASE 3D POLISH)
# ==============================================================================

func _render_deployment_controls(snapshot: GameStateSnapshot) -> void:
	var dep_title := Label.new()
	dep_title.text = "=== SOLDIER DEPLOYMENT BUILDER (Wave %d) ===" % snapshot.current_wave
	_panel_stage_actions.add_child(dep_title)

	var avail_cnt: int = int(snapshot.available_soldiers_count)
	var tot_cnt: int = int(snapshot.total_living_soldiers_count)
	var dep_cnt: int = tot_cnt - avail_cnt

	var dep_info := Label.new()
	dep_info.text = "Available Soldiers: %d | Deployed: %d / %d" % [
		avail_cnt, dep_cnt, tot_cnt
	]
	_panel_stage_actions.add_child(dep_info)

	# --- Custom Deployment Builder Box ---
	var builder_panel := PanelContainer.new()
	var builder_vbox := VBoxContainer.new()
	builder_panel.add_child(builder_vbox)
	_panel_stage_actions.add_child(builder_panel)

	# Row 1: Jumlah prajurit
	var count_row := HBoxContainer.new()
	builder_vbox.add_child(count_row)
	var lbl_c := Label.new()
	lbl_c.text = "Count:"
	count_row.add_child(lbl_c)

	for c in [1, 2, 3, 4, 5]:
		var btn_c := Button.new()
		btn_c.text = "[%d]" % c if _selected_deploy_count == c else "%d" % c
		btn_c.disabled = (avail_cnt < c)
		btn_c.pressed.connect(func(val=c):
			_selected_deploy_count = val
			_render_stage_actions(snapshot)
		)
		count_row.add_child(btn_c)

	# Row 2: Senjata Primer (Wajib)
	var prim_row := HBoxContainer.new()
	builder_vbox.add_child(prim_row)
	var lbl_p := Label.new()
	lbl_p.text = "Primary (Req):"
	prim_row.add_child(lbl_p)

	for w in ["SWORD", "SPEAR", "BOW"]:
		var stock: int = _get_warehouse_stock(w)
		var btn_p := Button.new()
		var is_sel: bool = (_selected_primary == w)
		btn_p.text = "[*%s* (%d usable)]" % [w, stock] if is_sel else "%s (%d usable)" % [w, stock]
		btn_p.pressed.connect(func(sel=w):
			_selected_primary = sel
			_render_stage_actions(snapshot)
		)
		prim_row.add_child(btn_p)

	# Row 3: Senjata Sekunder (Opsional)
	var sec_row := HBoxContainer.new()
	builder_vbox.add_child(sec_row)
	var lbl_s := Label.new()
	lbl_s.text = "Secondary (Opt):"
	sec_row.add_child(lbl_s)

	var btn_s_none := Button.new()
	btn_s_none.text = "[*NONE*]" if _selected_secondary == "NONE" else "NONE"
	btn_s_none.pressed.connect(func():
		_selected_secondary = "NONE"
		_render_stage_actions(snapshot)
	)
	sec_row.add_child(btn_s_none)

	var shield_stock: int = _get_warehouse_stock("SHIELD")
	var btn_s_shield := Button.new()
	var shield_sel: bool = (_selected_secondary == "SHIELD")
	btn_s_shield.text = "[*SHIELD* (%d usable)]" % shield_stock if shield_sel else "SHIELD (%d usable)" % shield_stock
	btn_s_shield.pressed.connect(func():
		_selected_secondary = "SHIELD"
		_render_stage_actions(snapshot)
	)
	sec_row.add_child(btn_s_shield)

	# Row 4: Zirah (Opsional)
	var arm_row := HBoxContainer.new()
	builder_vbox.add_child(arm_row)
	var lbl_a := Label.new()
	lbl_a.text = "Armor (Opt):"
	arm_row.add_child(lbl_a)

	var btn_a_none := Button.new()
	btn_a_none.text = "[*NONE*]" if _selected_armor == "NONE" else "NONE"
	btn_a_none.pressed.connect(func():
		_selected_armor = "NONE"
		_render_stage_actions(snapshot)
	)
	arm_row.add_child(btn_a_none)

	var armor_stock: int = _get_warehouse_stock("HEAVY_ARMOR")
	var btn_a_armor := Button.new()
	var armor_sel: bool = (_selected_armor == "HEAVY_ARMOR")
	btn_a_armor.text = "[*HEAVY_ARMOR* (%d usable)]" % armor_stock if armor_sel else "HEAVY_ARMOR (%d usable)" % armor_stock
	btn_a_armor.pressed.connect(func():
		_selected_armor = "HEAVY_ARMOR"
		_render_stage_actions(snapshot)
	)
	arm_row.add_child(btn_a_armor)

	# Preview Derivasi Peran Dinamis & Validasi Stok
	var derived_role: String = DeploymentComposition.resolve_role(_selected_primary, _selected_secondary, _selected_armor)
	var preview_row := HBoxContainer.new()
	builder_vbox.add_child(preview_row)

	var p_stock: int = _get_warehouse_stock(_selected_primary)
	var s_stock: int = _get_warehouse_stock(_selected_secondary) if _selected_secondary != "NONE" else 999
	var a_stock: int = _get_warehouse_stock(_selected_armor) if _selected_armor != "NONE" else 999

	var is_valid: bool = true
	var error_msg: String = ""

	if avail_cnt < _selected_deploy_count:
		is_valid = false
		error_msg = "Serdadu tersedia kurang (%d dibutuhkan, %d ada)" % [_selected_deploy_count, avail_cnt]
	elif p_stock < _selected_deploy_count:
		is_valid = false
		error_msg = "Stok gudang %s yang usable tidak cukup (%d dibutuhkan, %d ada)" % [_selected_primary, _selected_deploy_count, p_stock]
	elif _selected_secondary != "NONE" and s_stock < _selected_deploy_count:
		is_valid = false
		error_msg = "Stok gudang %s yang usable tidak cukup (%d dibutuhkan, %d ada)" % [_selected_secondary, _selected_deploy_count, s_stock]
	elif _selected_armor != "NONE" and a_stock < _selected_deploy_count:
		is_valid = false
		error_msg = "Stok gudang %s yang usable tidak cukup (%d dibutuhkan, %d ada)" % [_selected_armor, _selected_deploy_count, a_stock]

	var lbl_prev := Label.new()
	if is_valid:
		lbl_prev.text = "Role Preview: %dx %s [Status: SIAP]" % [_selected_deploy_count, derived_role]
	else:
		lbl_prev.text = "Role Preview: %dx %s [DITOLAK: %s]" % [_selected_deploy_count, derived_role, error_msg]
	preview_row.add_child(lbl_prev)

	var btn_deploy_custom := Button.new()
	btn_deploy_custom.text = "+ Deploy Group (%dx %s)" % [_selected_deploy_count, derived_role]
	btn_deploy_custom.disabled = (not is_valid) or (controller == null)
	btn_deploy_custom.pressed.connect(func():
		_action_create_deployment(_selected_deploy_count, _selected_primary, _selected_secondary, _selected_armor)
	)
	preview_row.add_child(btn_deploy_custom)

	# --- Quick Preset Buttons (Single-click Convenience) ---
	var preset_row := HBoxContainer.new()
	_panel_stage_actions.add_child(preset_row)
	var preset_lbl := Label.new()
	preset_lbl.text = "Quick Presets (2x):"
	preset_row.add_child(preset_lbl)

	var presets: Array = [
		{"label": "+2 Swordsman", "p": "SWORD", "s": "NONE", "a": "NONE", "need": {"SWORD": 2}},
		{"label": "+2 Shield Inf", "p": "SWORD", "s": "SHIELD", "a": "NONE", "need": {"SWORD": 2, "SHIELD": 2}},
		{"label": "+2 Archer", "p": "BOW", "s": "NONE", "a": "NONE", "need": {"BOW": 2}},
		{"label": "+2 Spearman", "p": "SPEAR", "s": "NONE", "a": "NONE", "need": {"SPEAR": 2}},
		{"label": "+2 Heavy Inf", "p": "SWORD", "s": "SHIELD", "a": "HEAVY_ARMOR", "need": {"SWORD": 2, "SHIELD": 2, "HEAVY_ARMOR": 2}}
	]

	for pr in presets:
		var btn_pr := Button.new()
		btn_pr.text = str(pr["label"])
		var pr_ok: bool = (avail_cnt >= 2)
		var need_dict: Dictionary = pr["need"]
		for k in need_dict:
			if _get_warehouse_stock(str(k)) < int(need_dict[k]):
				pr_ok = false
				break
		btn_pr.disabled = not pr_ok or (controller == null)
		btn_pr.pressed.connect(func(p_def=pr):
			_action_create_deployment(2, str(p_def["p"]), str(p_def["s"]), str(p_def["a"]))
		)
		preset_row.add_child(btn_pr)

	# --- Active Deployment Groups List ---
	var active_title := Label.new()
	active_title.text = "-- Active Deployment Groups (%d active) --" % snapshot.active_deployments_data.size()
	_panel_stage_actions.add_child(active_title)

	if snapshot.active_deployments_data.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "(Belum ada regu serdadu yang ditempatkan. Seluruh serdadu berada di cadangan benteng.)"
		_panel_stage_actions.add_child(empty_lbl)
	else:
		for dep in snapshot.active_deployments_data:
			var comp_id: String = str(dep.get("composition_id", ""))
			var count_val: int = int(dep.get("count", 0))
			var role_val: String = str(dep.get("resolved_role", ""))
			var prim_val: String = str(dep.get("primary_weapon", ""))
			var sec_val: String = str(dep.get("secondary_weapon", "NONE"))
			var arm_val: String = str(dep.get("armor", "NONE"))

			if _editing_composition_id == comp_id:
				# Tampilan Inline Reconfiguration Form
				_render_inline_reconfigure_box(snapshot, comp_id, count_val, role_val)
			else:
				var row := HBoxContainer.new()
				_panel_stage_actions.add_child(row)

				var row_lbl := Label.new()
				row_lbl.text = "• [%dx] %s (%s) | Gear: [P: %s, S: %s, A: %s]" % [
					count_val, role_val, comp_id, prim_val, sec_val, arm_val
				]
				row.add_child(row_lbl)

				var btn_edit := Button.new()
				btn_edit.text = "Edit / Reconfigure"
				btn_edit.pressed.connect(func(cid=comp_id, c=count_val, p=prim_val, s=sec_val, a=arm_val):
					_editing_composition_id = cid
					_edit_count = c
					_edit_primary = p
					_edit_secondary = s
					_edit_armor = a
					_render_stage_actions(snapshot)
				)
				row.add_child(btn_edit)

				var btn_cancel_dep := Button.new()
				btn_cancel_dep.text = "Cancel / Remove"
				btn_cancel_dep.pressed.connect(func(cid=comp_id):
					_action_remove_deployment(cid)
				)
				row.add_child(btn_cancel_dep)


func _render_inline_reconfigure_box(snapshot: GameStateSnapshot, comp_id: String, cur_count: int, cur_role: String) -> void:
	var edit_box := PanelContainer.new()
	var edit_vbox := VBoxContainer.new()
	edit_box.add_child(edit_vbox)
	_panel_stage_actions.add_child(edit_box)

	var title_lbl := Label.new()
	title_lbl.text = ">> RECONFIGURING REGIMENT: %s (Current: %dx %s) <<" % [comp_id, cur_count, cur_role]
	edit_vbox.add_child(title_lbl)

	var avail_cnt: int = int(snapshot.available_soldiers_count)
	var max_allowed: int = avail_cnt + cur_count

	# Edit Count
	var ec_row := HBoxContainer.new()
	edit_vbox.add_child(ec_row)
	var ec_lbl := Label.new()
	ec_lbl.text = "New Count:"
	ec_row.add_child(ec_lbl)

	for c in [1, 2, 3, 4, 5]:
		var btn := Button.new()
		btn.text = "[%d]" % c if _edit_count == c else "%d" % c
		btn.disabled = (max_allowed < c)
		btn.pressed.connect(func(val=c):
			_edit_count = val
			_render_stage_actions(snapshot)
		)
		ec_row.add_child(btn)

	# Edit Primary
	var ep_row := HBoxContainer.new()
	edit_vbox.add_child(ep_row)
	var ep_lbl := Label.new()
	ep_lbl.text = "New Primary:"
	ep_row.add_child(ep_lbl)

	for w in ["SWORD", "SPEAR", "BOW"]:
		var btn := Button.new()
		btn.text = "[*%s*]" % w if _edit_primary == w else w
		btn.pressed.connect(func(sel=w):
			_edit_primary = sel
			_render_stage_actions(snapshot)
		)
		ep_row.add_child(btn)

	# Edit Secondary
	var es_row := HBoxContainer.new()
	edit_vbox.add_child(es_row)
	var es_lbl := Label.new()
	es_lbl.text = "New Secondary:"
	es_row.add_child(es_lbl)

	var btn_s_none := Button.new()
	btn_s_none.text = "[*NONE*]" if _edit_secondary == "NONE" else "NONE"
	btn_s_none.pressed.connect(func():
		_edit_secondary = "NONE"
		_render_stage_actions(snapshot)
	)
	es_row.add_child(btn_s_none)

	var btn_s_shield := Button.new()
	btn_s_shield.text = "[*SHIELD*]" if _edit_secondary == "SHIELD" else "SHIELD"
	btn_s_shield.pressed.connect(func():
		_edit_secondary = "SHIELD"
		_render_stage_actions(snapshot)
	)
	es_row.add_child(btn_s_shield)

	# Edit Armor
	var ea_row := HBoxContainer.new()
	edit_vbox.add_child(ea_row)
	var ea_lbl := Label.new()
	ea_lbl.text = "New Armor:"
	ea_row.add_child(ea_lbl)

	var btn_a_none := Button.new()
	btn_a_none.text = "[*NONE*]" if _edit_armor == "NONE" else "NONE"
	btn_a_none.pressed.connect(func():
		_edit_armor = "NONE"
		_render_stage_actions(snapshot)
	)
	ea_row.add_child(btn_a_none)

	var btn_a_armor := Button.new()
	btn_a_armor.text = "[*HEAVY_ARMOR*]" if _edit_armor == "HEAVY_ARMOR" else "HEAVY_ARMOR"
	btn_a_armor.pressed.connect(func():
		_edit_armor = "HEAVY_ARMOR"
		_render_stage_actions(snapshot)
	)
	ea_row.add_child(btn_a_armor)

	# Preview & Actions
	var new_role: String = DeploymentComposition.resolve_role(_edit_primary, _edit_secondary, _edit_armor)
	var act_row := HBoxContainer.new()
	edit_vbox.add_child(act_row)

	var lbl_edit_prev := Label.new()
	lbl_edit_prev.text = "Preview: %dx %s" % [_edit_count, new_role]
	act_row.add_child(lbl_edit_prev)

	var btn_apply := Button.new()
	btn_apply.text = "✔ Apply Reconfiguration"
	btn_apply.pressed.connect(func(old_cid=comp_id):
		_action_reconfigure_deployment(old_cid, _edit_count, _edit_primary, _edit_secondary, _edit_armor)
	)
	act_row.add_child(btn_apply)

	var btn_cancel_edit := Button.new()
	btn_cancel_edit.text = "✖ Cancel Edit"
	btn_cancel_edit.pressed.connect(func():
		_editing_composition_id = ""
		_render_stage_actions(snapshot)
	)
	act_row.add_child(btn_cancel_edit)


# ==============================================================================
# ACTION DISPATCHERS & FEEDBACK HELPERS
# ==============================================================================

func _adjust_workers(d_rep: int, d_smith: int, d_constr: int) -> void:
	if _last_snapshot == null or controller == null:
		return
	var e_data: Dictionary = _last_snapshot.economy_data
	var cur_rep: int = int(e_data.get("repair_workers", 0))
	var cur_smith: int = int(e_data.get("blacksmith_workers", 0))
	var cur_constr: int = int(e_data.get("construction_workers", 0))

	var new_rep: int = maxi(0, cur_rep + d_rep)
	var new_smith: int = maxi(0, cur_smith + d_smith)
	var new_constr: int = maxi(0, cur_constr + d_constr)

	var ok: bool = controller.allocate_workers(new_rep, new_smith, new_constr)
	if ok:
		_set_feedback("[SUKSES] Alokasi pekerja diubah: Repair=%d, Smith=%d, Constr=%d" % [new_rep, new_smith, new_constr])
	else:
		_set_feedback("[DITOLAK] Alokasi pekerja gagal. Total pekerja melebihi warga sipil yang tersedia.")


func _recruit(role: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.recruit_soldier(role, 1)
	if ok:
		_set_feedback("[SUKSES] Rekrut 1 serdadu %s berhasil (Sipil -1, Serdadu +1)." % role)
	else:
		_set_feedback("[DITOLAK] Gagal rekrut %s. Warga sipil tidak mencukupi (minimal 1 sipil dibutuhkan)." % role)


func _action_create_deployment(count: int, primary: String, secondary: String, armor: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.create_deployment(count, primary, secondary, armor)
	var role: String = DeploymentComposition.resolve_role(primary, secondary, armor)
	if ok:
		_set_feedback("[SUKSES] Regu tempur %dx %s berhasil ditempatkan. Perlengkapan direservasi dari gudang." % [count, role])
	else:
		_set_feedback("[DITOLAK] Gagal menempatkan regu %dx %s. Periksa ketersediaan serdadu dan stok gudang." % [count, role])


func _action_remove_deployment(composition_id: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.remove_deployment(composition_id)
	if ok:
		_set_feedback("[SUKSES] Regu %s dibatalkan. Serdadu kembali ke pool dan gear kembali ke gudang." % composition_id)
	else:
		_set_feedback("[DITOLAK] Gagal membatalkan regu %s." % composition_id)


func _action_reconfigure_deployment(old_cid: String, new_count: int, new_p: String, new_s: String, new_a: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.reconfigure_deployment(old_cid, new_count, new_p, new_s, new_a)
	var role: String = DeploymentComposition.resolve_role(new_p, new_s, new_a)
	if ok:
		_editing_composition_id = ""
		_set_feedback("[SUKSES] Rekonfigurasi regu berhasil menjadi %dx %s." % [new_count, role])
	else:
		_set_feedback("[DITOLAK] Rekonfigurasi regu gagal (stok/serdadu tidak cukup). Konfigurasi awal dipertahankan tanpa perubahan.")


func _action_equip_hero(hero_id: String, slot: String, eq_type: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.equip_hero(hero_id, slot, eq_type)
	if ok:
		_set_feedback("[SUKSES] Hero %s memasang %s di slot %s (stok gudang -1)." % [hero_id, eq_type, slot])
	else:
		_set_feedback("[DITOLAK] Gagal memasang %s ke hero %s. Periksa stok gudang atau validitas slot." % [eq_type, hero_id])


func _action_unequip_hero(hero_id: String, slot: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.unequip_hero(hero_id, slot)
	if ok:
		_set_feedback("[SUKSES] Hero %s melepas perlengkapan di slot %s (dikembalikan ke gudang)." % [hero_id, slot])
	else:
		_set_feedback("[DITOLAK] Gagal melepas perlengkapan slot %s dari hero %s." % [slot, hero_id])


func _action_inspect_wave() -> void:
	if controller == null:
		return
	var ok: bool = controller.inspect_wave()
	if ok:
		_set_feedback("[INFO] Masuk ke Wave Preview. Tinjau intel musuh sebelum menekan Start Battle.")
	else:
		_set_feedback("[DITOLAK] Tidak dapat melakukan inspect wave dari fase saat ini.")


func _action_start_battle() -> void:
	if controller == null:
		return
	var ok: bool = controller.start_battle()
	if ok:
		_set_feedback("[INFO] Pertempuran dimulai! Seluruh alokasi gudang dan konfigurasi regu TERKUNCI.")
	else:
		_set_feedback("[DITOLAK] Pertempuran tidak dapat dimulai.")


func _send_command(cmd_type: String) -> void:
	_execute_selected_command(cmd_type)


func _set_feedback(msg: String) -> void:
	if _lbl_feedback_banner != null:
		_lbl_feedback_banner.text = msg
	_log(msg)


func _log(message: String) -> void:
	if _txt_telemetry_log != null:
		_txt_telemetry_log.append_text(message + "\n")


func _action_repair_equipment(eq_type: String, count: int = 1) -> void:
	if controller == null:
		return
	var cost: int = controller.get_equipment_repair_cost(eq_type, count)
	var ok: bool = controller.repair_equipment(eq_type, count)
	if ok:
		_set_feedback("[BLACKSMITH] Berhasil memperbaiki %dx %s (%d Gold). Durabilitas pulih 100%% (usable)." % [count, eq_type, cost])
	else:
		_set_feedback("[DITOLAK] Gagal memperbaiki %s. Pastikan emas kas mencukupi dan tidak sedang dalam pertempuran." % eq_type)


func _get_warehouse_usable_stock(eq_type: String) -> int:
	if controller != null:
		return controller.get_warehouse_usable_stock(eq_type)
	if coordinator != null:
		return coordinator.get_warehouse_usable_stock(eq_type)
	return 0


func _get_warehouse_damaged_stock(eq_type: String) -> int:
	if controller != null:
		return controller.get_warehouse_damaged_stock(eq_type)
	if coordinator != null:
		return coordinator.get_warehouse_damaged_stock(eq_type)
	return 0


func _get_warehouse_stock(eq_type: String) -> int:
	if controller != null:
		return controller.get_warehouse_stock(eq_type)
	if coordinator != null:
		return coordinator.get_warehouse_stock(eq_type)
	return 0


func _get_reserved_equipment_stock(eq_type: String) -> int:
	if controller != null:
		return controller.get_reserved_equipment_stock(eq_type)
	if coordinator != null:
		return coordinator.get_reserved_equipment_stock(eq_type)
	return 0


func _get_total_owned_stock(eq_type: String) -> int:
	if controller != null:
		return controller.get_total_owned_stock(eq_type)
	if coordinator != null:
		return coordinator.get_total_owned_stock(eq_type)
	return 0


# ==============================================================================
# PHASE 5: FORTRESS, WORKERS, BUILDINGS, REPAIR & CONSTRUCTION UI HELPERS
# ==============================================================================

func _render_buildings_panel(snapshot: GameStateSnapshot) -> void:
	if _buildings_container == null:
		return
	for c in _buildings_container.get_children():
		c.queue_free()

	for b_dict in snapshot.buildings_data:
		var b_id: String = str(b_dict.get("building_id", ""))
		var b_name: String = str(b_dict.get("building_name", ""))
		var b_lvl: int = int(b_dict.get("level", 1))
		var b_max: int = int(b_dict.get("max_level", 5))
		var can_up: bool = bool(b_dict.get("can_upgrade", false))

		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "- %s (Lv %d/%d)" % [b_name, b_lvl, b_max]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var btn_up := Button.new()
		btn_up.text = "Tingkatkan"
		btn_up.name = "BtnUp_" + b_id
		btn_up.disabled = (not can_up) or (snapshot.game_phase == "BATTLE")
		btn_up.pressed.connect(func(): _action_upgrade_building(b_id))
		row.add_child(btn_up)

		_buildings_container.add_child(row)


func _render_construction_panel(snapshot: GameStateSnapshot) -> void:
	if _lbl_construction_status == null:
		return
	var c_data: Dictionary = snapshot.active_construction_data
	if c_data.is_empty():
		_lbl_construction_status.text = "Proyek: Tidak ada proyek aktif"
	else:
		var bid: String = str(c_data.get("target_building_id", ""))
		var prog: int = int(c_data.get("current_progress", 0))
		var target: int = int(c_data.get("target_progress", 100))
		var is_comp: bool = bool(c_data.get("is_completed", false))
		var status_str: String = "SELESAI" if is_comp else ("%d / %d" % [prog, target])
		_lbl_construction_status.text = "Proyek: %s [%s]" % [bid, status_str]


func _action_repair_structure(target: String, amount: int = 50) -> void:
	if controller == null:
		return
	var ok: bool = controller.repair_structure(target, amount)
	if ok:
		_set_feedback("[REPARASI] Berhasil memperbaiki struktur %s (+%d HP)." % [target, amount])
	else:
		_set_feedback("[DITOLAK] Gagal memperbaiki %s. Pastikan pekerja perbaikan tersedia, emas kas cukup, dan tidak sedang bertempur." % target)


func _action_convert_civilian_to_worker(count: int = 1) -> void:
	if controller == null:
		return
	var ok: bool = controller.convert_civilian_to_worker(count)
	if ok:
		_set_feedback("[POPULASI] Berhasil mengonversi %d warga sipil menjadi pekerja." % count)
	else:
		_set_feedback("[DITOLAK] Gagal mengonversi sipil ke pekerja. Warga sipil tidak mencukupi atau sedang bertempur.")


func _action_convert_worker_to_civilian(count: int = 1) -> void:
	if controller == null:
		return
	var ok: bool = controller.convert_worker_to_civilian(count)
	if ok:
		_set_feedback("[POPULASI] Berhasil mengonversi %d pekerja kembali menjadi warga sipil." % count)
	else:
		_set_feedback("[DITOLAK] Gagal mengonversi pekerja ke sipil. Pekerja tidak mencukupi atau sedang bertempur.")


func _action_upgrade_building(b_id: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.upgrade_building(b_id)
	if ok:
		_set_feedback("[BANGUNAN] Fasilitas %s berhasil ditingkatkan tingkatnya." % b_id)
	else:
		_set_feedback("[DITOLAK] Gagal meningkatkan fasilitas %s. Level sudah maksimal atau sedang dalam pertempuran." % b_id)


func _action_start_construction(b_id: String, gold_cost: int = 50, target_progress: int = 100) -> void:
	if controller == null:
		return
	var ok: bool = controller.start_construction(b_id, gold_cost, target_progress)
	if ok:
		_set_feedback("[KONSTRUKSI] Proyek konstruksi %s berhasil dimulai (%d Gold)." % [b_id, gold_cost])
	else:
		_set_feedback("[DITOLAK] Gagal memulai konstruksi %s. Pastikan pekerja konstruksi tersedia, kas cukup, dan tidak sedang bertempur." % b_id)


func _action_advance_construction(progress_delta: int = 25) -> void:
	if controller == null:
		return
	var ok: bool = controller.advance_construction(progress_delta)
	if ok:
		_set_feedback("[KONSTRUKSI] Progres konstruksi bertambah +%d poin." % progress_delta)
	else:
		_set_feedback("[DITOLAK] Gagal menambah progres konstruksi. Tidak ada proyek aktif atau proyek sudah selesai.")


func _action_cancel_construction() -> void:
	if controller == null:
		return
	var ok: bool = controller.cancel_construction()
	if ok:
		_set_feedback("[KONSTRUKSI] Proyek konstruksi dibatalkan. Biaya telah dikembalikan ke kas.")
	else:
		_set_feedback("[DITOLAK] Gagal membatalkan konstruksi.")


func _action_reassign_worker(from_job: String, to_job: String, count: int = 1) -> void:
	if controller == null:
		return
	var ok: bool = controller.reassign_worker(from_job, to_job, count)
	if ok:
		_set_feedback("[PEKERJA] Berhasil memindahkan %d pekerja dari %s ke %s." % [count, from_job, to_job])
	else:
		_set_feedback("[DITOLAK] Gagal memindahkan pekerja. Jumlah pekerja tidak mencukupi atau sedang bertempur.")


# ==============================================================================
# PHASE 6F: TACTICAL BATTLE UI RENDERING & IN-PLACE TICK UPDATES
# ==============================================================================

func _render_tactical_battle_ui(snapshot: GameStateSnapshot) -> void:
	if _battlefield_panel == null or not is_instance_valid(_battlefield_panel) or _battlefield_panel.get_parent() != _panel_stage_actions:
		for child in _panel_stage_actions.get_children():
			_panel_stage_actions.remove_child(child)
			child.queue_free()
		_build_tactical_battle_ui()
	_update_tactical_battle_ui(snapshot)


func _build_tactical_battle_ui() -> void:
	_battlefield_panel = PanelContainer.new()
	_panel_stage_actions.add_child(_battlefield_panel, true)
	_battlefield_panel.name = "BattlefieldPanel"

	var main_vbox := VBoxContainer.new()
	main_vbox.name = "BattlefieldMainVBox"
	_battlefield_panel.add_child(main_vbox)

	# --- 1. Header Telemetry & Pacing Controls ---
	var telemetry_box := VBoxContainer.new()
	main_vbox.add_child(telemetry_box)

	_lbl_battle_telemetry_header = Label.new()
	_lbl_battle_telemetry_header.name = "LblBattleTelemetryHeader"
	_lbl_battle_telemetry_header.text = "⏱ TICK: 0 | TEMPO: 1.0x | STATUS: RUNNING | GELOMBANG: 1"
	telemetry_box.add_child(_lbl_battle_telemetry_header)

	var pacing_hbox := HBoxContainer.new()
	pacing_hbox.name = "BattlePacingHBox"
	telemetry_box.add_child(pacing_hbox)

	_btn_battle_pause_resume = Button.new()
	_btn_battle_pause_resume.name = "BtnPauseResume"
	_btn_battle_pause_resume.text = "⏸ PAUSE"
	_btn_battle_pause_resume.custom_minimum_size = Vector2(80, 44)
	_btn_battle_pause_resume.pressed.connect(func():
		if controller:
			controller.toggle_battle_pause()
	)
	pacing_hbox.add_child(_btn_battle_pause_resume)

	_btn_battle_speed_1x = Button.new()
	_btn_battle_speed_1x.name = "BtnSpeed1x"
	_btn_battle_speed_1x.text = "[1x]"
	_btn_battle_speed_1x.custom_minimum_size = Vector2(44, 44)
	_btn_battle_speed_1x.pressed.connect(func():
		if controller:
			controller.set_speed(1.0)
	)
	pacing_hbox.add_child(_btn_battle_speed_1x)

	_btn_battle_speed_2x = Button.new()
	_btn_battle_speed_2x.name = "BtnSpeed2x"
	_btn_battle_speed_2x.text = "2x"
	_btn_battle_speed_2x.custom_minimum_size = Vector2(44, 44)
	_btn_battle_speed_2x.pressed.connect(func():
		if controller:
			controller.set_speed(2.0)
	)
	pacing_hbox.add_child(_btn_battle_speed_2x)

	_btn_battle_speed_4x = Button.new()
	_btn_battle_speed_4x.name = "BtnSpeed4x"
	_btn_battle_speed_4x.text = "4x"
	_btn_battle_speed_4x.custom_minimum_size = Vector2(44, 44)
	_btn_battle_speed_4x.pressed.connect(func():
		if controller:
			controller.set_speed(4.0)
	)
	pacing_hbox.add_child(_btn_battle_speed_4x)

	_btn_battle_step_tick = Button.new()
	_btn_battle_step_tick.name = "BtnStepTick"
	_btn_battle_step_tick.text = "⏭ Step Tick"
	_btn_battle_step_tick.custom_minimum_size = Vector2(80, 44)
	_btn_battle_step_tick.pressed.connect(func():
		if controller:
			controller.step_simulation()
	)
	pacing_hbox.add_child(_btn_battle_step_tick)

	_btn_battle_resolve_instantly = Button.new()
	_btn_battle_resolve_instantly.name = "BtnResolveInstantly"
	_btn_battle_resolve_instantly.text = "⚡ Selesaikan Instan"
	_btn_battle_resolve_instantly.custom_minimum_size = Vector2(160, 44)
	_btn_battle_resolve_instantly.pressed.connect(func():
		if controller:
			controller.resolve_battle_immediately()
	)
	pacing_hbox.add_child(_btn_battle_resolve_instantly)

	main_vbox.add_child(HSeparator.new())

	# --- 2. Structural Condition & Casualties ---
	var struct_hbox := HBoxContainer.new()
	main_vbox.add_child(struct_hbox)

	_lbl_fortress_battle_status = Label.new()
	_lbl_fortress_battle_status.name = "LblFortressBattleStatus"
	_lbl_fortress_battle_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_fortress_battle_status.text = "Benteng: HP 1000/1000 | Armor: 50 | Dinding: HP 500/500 | Gerbang: HP 300/300"
	struct_hbox.add_child(_lbl_fortress_battle_status)

	_lbl_casualties_summary = Label.new()
	_lbl_casualties_summary.name = "LblCasualtiesSummary"
	_lbl_casualties_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_casualties_summary.text = "Korban: Prajurit Gugur: 0 | Hero Gugur: 0 | Kerusakan Benteng: 0"
	struct_hbox.add_child(_lbl_casualties_summary)

	main_vbox.add_child(HSeparator.new())

	# --- 3. Canonical 7 Zones Battlefield Map ---
	var battlefield_map := VBoxContainer.new()
	battlefield_map.name = "BattlefieldMapContainer"
	main_vbox.add_child(battlefield_map)

	_zone_panels.clear()
	_zone_labels.clear()
	_zone_status_labels.clear()
	_zone_detail_labels.clear()

	# Zone 1: OUTER_FIELD (Top)
	battlefield_map.add_child(_create_zone_card("OUTER_FIELD"))

	# Middle row: LEFT_FLANK, CENTER_APPROACH, RIGHT_FLANK
	var mid_row := HBoxContainer.new()
	mid_row.name = "MidRowZones"
	battlefield_map.add_child(mid_row)
	mid_row.add_child(_create_zone_card("LEFT_FLANK"))
	mid_row.add_child(_create_zone_card("CENTER_APPROACH"))
	mid_row.add_child(_create_zone_card("RIGHT_FLANK"))

	# Defense line row: WALL, GATE
	var def_row := HBoxContainer.new()
	def_row.name = "DefRowZones"
	battlefield_map.add_child(def_row)
	def_row.add_child(_create_zone_card("WALL"))
	def_row.add_child(_create_zone_card("GATE"))

	# Citadel row: FORTRESS
	battlefield_map.add_child(_create_zone_card("FORTRESS"))

	main_vbox.add_child(HSeparator.new())

	# --- 4. Party 1 Active Tactical Forces Visualization ---
	var forces_panel := PanelContainer.new()
	forces_panel.name = "Party1ForcesPanel"
	main_vbox.add_child(forces_panel)

	var forces_vbox := VBoxContainer.new()
	forces_panel.add_child(forces_vbox)

	_lbl_party1_summary = Label.new()
	_lbl_party1_summary.name = "LblParty1Summary"
	_lbl_party1_summary.text = "Party 1 Tempur: (Memuat status pasukan...)"
	forces_vbox.add_child(_lbl_party1_summary)

	main_vbox.add_child(HSeparator.new())

	# --- 5. Commander Command Controls ---
	var cmd_panel := PanelContainer.new()
	cmd_panel.name = "CommanderCommandPanel"
	main_vbox.add_child(cmd_panel)

	var cmd_vbox := VBoxContainer.new()
	cmd_panel.add_child(cmd_vbox)

	var cmd_title := Label.new()
	cmd_title.text = "⚔ KONTROL TAKTIS KOMANDAN (INTENTS) ⚔"
	cmd_vbox.add_child(cmd_title)

	var sel_row := HBoxContainer.new()
	cmd_vbox.add_child(sel_row)

	var lbl_src := Label.new()
	lbl_src.text = "Sumber:"
	sel_row.add_child(lbl_src)

	_opt_cmd_source = OptionButton.new()
	_opt_cmd_source.name = "OptCmdSource"
	_opt_cmd_source.custom_minimum_size = Vector2(130, 44)
	_opt_cmd_source.add_item("party_1")
	_opt_cmd_source.set_item_metadata(0, "party_1")
	sel_row.add_child(_opt_cmd_source)

	var lbl_tz := Label.new()
	lbl_tz.text = "Zona Target:"
	sel_row.add_child(lbl_tz)

	_opt_cmd_target_zone = OptionButton.new()
	_opt_cmd_target_zone.name = "OptCmdTargetZone"
	_opt_cmd_target_zone.custom_minimum_size = Vector2(140, 44)
	for i in range(BattlefieldZone.CANONICAL_ZONES.size()):
		var z: String = BattlefieldZone.CANONICAL_ZONES[i]
		_opt_cmd_target_zone.add_item(z)
		_opt_cmd_target_zone.set_item_metadata(i, z)
	for idx in range(_opt_cmd_target_zone.item_count):
		if _opt_cmd_target_zone.get_item_text(idx) == "CENTER_APPROACH":
			_opt_cmd_target_zone.selected = idx
			break
	sel_row.add_child(_opt_cmd_target_zone)

	var lbl_te := Label.new()
	lbl_te.text = "Entitas/Arketipe:"
	sel_row.add_child(lbl_te)

	_opt_cmd_target_entity = OptionButton.new()
	_opt_cmd_target_entity.name = "OptCmdTargetEntity"
	_opt_cmd_target_entity.custom_minimum_size = Vector2(130, 44)
	var entity_options := ["FORTRESS", "GATE", "WALL", "MINION", "RAIDER", "BRUTE", "FLYER", "SIEGE", "BOSS"]
	for idx in range(entity_options.size()):
		var ent: String = entity_options[idx]
		_opt_cmd_target_entity.add_item(ent)
		_opt_cmd_target_entity.set_item_metadata(idx, ent)
	sel_row.add_child(_opt_cmd_target_entity)

	var btn_row := HBoxContainer.new()
	cmd_vbox.add_child(btn_row)

	_btn_cmd_advance = Button.new()
	_btn_cmd_advance.name = "BtnCmd_ADVANCE"
	_btn_cmd_advance.text = "ADVANCE"
	_btn_cmd_advance.custom_minimum_size = Vector2(80, 44)
	_btn_cmd_advance.pressed.connect(func(): _execute_selected_command("ADVANCE"))
	btn_row.add_child(_btn_cmd_advance)

	_btn_cmd_move = Button.new()
	_btn_cmd_move.name = "BtnCmd_MOVE"
	_btn_cmd_move.text = "MOVE"
	_btn_cmd_move.custom_minimum_size = Vector2(70, 44)
	_btn_cmd_move.pressed.connect(func(): _execute_selected_command("MOVE"))
	btn_row.add_child(_btn_cmd_move)

	_btn_cmd_hold = Button.new()
	_btn_cmd_hold.name = "BtnCmd_HOLD_POSITION"
	_btn_cmd_hold.text = "HOLD POSITION"
	_btn_cmd_hold.custom_minimum_size = Vector2(110, 44)
	_btn_cmd_hold.pressed.connect(func(): _execute_selected_command("HOLD_POSITION"))
	btn_row.add_child(_btn_cmd_hold)

	_btn_cmd_retreat = Button.new()
	_btn_cmd_retreat.name = "BtnCmd_RETREAT"
	_btn_cmd_retreat.text = "RETREAT"
	_btn_cmd_retreat.custom_minimum_size = Vector2(80, 44)
	_btn_cmd_retreat.pressed.connect(func(): _execute_selected_command("RETREAT"))
	btn_row.add_child(_btn_cmd_retreat)

	_btn_cmd_protect = Button.new()
	_btn_cmd_protect.name = "BtnCmd_PROTECT"
	_btn_cmd_protect.text = "PROTECT"
	_btn_cmd_protect.custom_minimum_size = Vector2(80, 44)
	_btn_cmd_protect.pressed.connect(func(): _execute_selected_command("PROTECT"))
	btn_row.add_child(_btn_cmd_protect)

	_btn_cmd_focus = Button.new()
	_btn_cmd_focus.name = "BtnCmd_FOCUS_TARGET"
	_btn_cmd_focus.text = "FOCUS TARGET"
	_btn_cmd_focus.custom_minimum_size = Vector2(110, 44)
	_btn_cmd_focus.pressed.connect(func(): _execute_selected_command("FOCUS_TARGET"))
	btn_row.add_child(_btn_cmd_focus)

	_btn_cmd_follow = Button.new()
	_btn_cmd_follow.name = "BtnCmd_FOLLOW"
	_btn_cmd_follow.text = "FOLLOW"
	_btn_cmd_follow.custom_minimum_size = Vector2(80, 44)
	_btn_cmd_follow.pressed.connect(func(): _execute_selected_command("FOLLOW"))
	btn_row.add_child(_btn_cmd_follow)

	_lbl_cmd_feedback = Label.new()
	_lbl_cmd_feedback.name = "LblCommandFeedback"
	_lbl_cmd_feedback.text = "Siap menerima perintah komandan."
	cmd_vbox.add_child(_lbl_cmd_feedback)


func _create_zone_card(zone_id: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "ZonePanel_" + zone_id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	var lbl_status := Label.new()
	lbl_status.name = "LblZoneStatus_" + zone_id
	lbl_status.text = "%s [EMPTY]" % zone_id
	vbox.add_child(lbl_status)

	var lbl_detail := Label.new()
	lbl_detail.name = "LblZoneDetail_" + zone_id
	lbl_detail.text = "Musuh: -\nKawan: -"
	vbox.add_child(lbl_detail)

	_zone_panels[zone_id] = card
	_zone_status_labels[zone_id] = lbl_status
	_zone_detail_labels[zone_id] = lbl_detail
	return card


func _get_zone_status(zone_id: String, snapshot: GameStateSnapshot) -> String:
	if zone_id == "WALL" and snapshot.wall_hp <= 0:
		return "[BREACHED]"
	if zone_id == "GATE" and snapshot.gate_hp <= 0:
		return "[BREACHED]"
	if zone_id == "FORTRESS" and snapshot.fortress_hp <= 0:
		return "[DESTROYED]"

	var enemy_count: int = 0
	for eg in snapshot.enemy_groups_data:
		var z_eg: String = str(eg.get("current_zone", ""))
		var q_eg: int = int(eg.get("quantity", eg.get("count", 0)))
		var hp_eg: int = int(eg.get("current_hp_pool", 0))
		if z_eg == zone_id and q_eg > 0 and hp_eg > 0:
			enemy_count += q_eg

	var friendly_count: int = 0
	if str(snapshot.battle_party_data.get("current_zone", "")) == zone_id:
		friendly_count += int(snapshot.battle_party_data.get("soldiers_count", 0)) + snapshot.battle_party_data.get("member_hero_ids", []).size()

	for dep in snapshot.battle_deployments_data:
		if str(dep.get("zone", "")) == zone_id and int(dep.get("count", 0)) > 0:
			friendly_count += int(dep.get("count", 0))

	if enemy_count > 0 and friendly_count > 0:
		return "[CONTESTED]"
	if enemy_count > 0 and friendly_count == 0:
		return "[ENEMY OCCUPIED]"
	if enemy_count == 0 and friendly_count > 0:
		return "[FRIENDLY]"

	if zone_id == "WALL" and snapshot.wall_hp < 500:
		return "[DAMAGED]"
	if zone_id == "GATE" and snapshot.gate_hp < 300:
		return "[DAMAGED]"
	if zone_id == "FORTRESS" and snapshot.fortress_hp < 1000:
		return "[DAMAGED]"

	return "[EMPTY]"


func _get_zone_details_string(zone_id: String, snapshot: GameStateSnapshot) -> String:
	var enemy_strs: Array[String] = []
	for eg in snapshot.enemy_groups_data:
		var z_eg: String = str(eg.get("current_zone", ""))
		var q_eg: int = int(eg.get("quantity", eg.get("count", 0)))
		var hp_eg: int = int(eg.get("current_hp_pool", 0))
		if z_eg == zone_id and q_eg > 0 and hp_eg > 0:
			var arch: String = str(eg.get("enemy_type", eg.get("archetype", "ENEMY")))
			var count: int = q_eg
			var cur_hp: int = hp_eg
			var max_hp: int = int(eg.get("max_hp_pool", cur_hp))
			var is_boss: bool = bool(eg.get("is_boss", false))
			var trait_str: String = str(eg.get("special_trait", ""))
			var traits: Array = eg.get("traits", [])
			var tag_str: String = ""
			if is_boss:
				tag_str += "[BOSS] "
			if not trait_str.is_empty():
				tag_str += "[%s] " % trait_str
			elif not traits.is_empty():
				tag_str += "[%s] " % ",".join(traits)
			enemy_strs.append("%s (x%d, HP %d/%d %s)" % [arch, count, cur_hp, max_hp, tag_str.strip_edges()])

	var friendly_strs: Array[String] = []
	if str(snapshot.battle_party_data.get("current_zone", "")) == zone_id:
		var hero_names: Array[String] = []
		for hid in snapshot.battle_party_data.get("member_hero_ids", []):
			for hd in snapshot.heroes_data:
				if hd.get("hero_id", "") == hid:
					var alive_tag: String = "" if bool(hd.get("is_alive", true)) else "†"
					hero_names.append(hd.get("hero_name", hid) + alive_tag)
					break
		var s_cnt: int = int(snapshot.battle_party_data.get("soldiers_count", 0))
		var form: String = str(snapshot.battle_party_data.get("formation", "NONE"))
		if not hero_names.is_empty() or s_cnt > 0:
			var h_label: String = ", ".join(hero_names) if not hero_names.is_empty() else "(Tanpa Hero)"
			friendly_strs.append("Party 1 (%s | %d prajurit [%s])" % [h_label, s_cnt, form])

	for dep in snapshot.battle_deployments_data:
		if str(dep.get("zone", "")) == zone_id and int(dep.get("count", 0)) > 0:
			var r_name: String = str(dep.get("resolved_role", dep.get("role", "SOLDIER")))
			var c_cnt: int = int(dep.get("count", 0))
			var f_name: String = str(dep.get("formation", "NONE"))
			friendly_strs.append("%s x%d [%s]" % [r_name, c_cnt, f_name])

	var lines: Array[String] = []
	if enemy_strs.is_empty():
		lines.append("Musuh: -")
	else:
		lines.append("Musuh: " + "; ".join(enemy_strs))

	if friendly_strs.is_empty():
		lines.append("Kawan: -")
	else:
		lines.append("Kawan: " + "; ".join(friendly_strs))

	if zone_id == "WALL":
		lines.append("Kondisi Dinding: %d / 500 HP" % snapshot.wall_hp)
	elif zone_id == "GATE":
		lines.append("Kondisi Gerbang: %d / 300 HP" % snapshot.gate_hp)
	elif zone_id == "FORTRESS":
		lines.append("Kondisi Benteng: %d / 1000 HP" % snapshot.fortress_hp)

	var pressure: int = int(snapshot.battle_zone_pressure.get(zone_id, 0))
	if pressure > 0:
		lines.append("Tekanan Tempur: %d" % pressure)

	return "\n".join(lines)


func _update_tactical_battle_ui(snapshot: GameStateSnapshot) -> void:
	if _battlefield_panel == null or not is_instance_valid(_battlefield_panel):
		return

	# 1. Telemetry Header & Controls
	if _lbl_battle_telemetry_header != null:
		var status_str: String = "PAUSED" if snapshot.battle_paused else "RUNNING"
		_lbl_battle_telemetry_header.text = "⏱ TICK: %d | TEMPO: %.1fx | STATUS: %s | GELOMBANG: %d" % [
			snapshot.battle_tick,
			snapshot.battle_speed,
			status_str,
			snapshot.current_wave
		]

	if _btn_battle_pause_resume != null:
		_btn_battle_pause_resume.text = "▶ RESUME" if snapshot.battle_paused else "⏸ PAUSE"

	if _btn_battle_speed_1x != null:
		_btn_battle_speed_1x.text = "[1x]" if is_equal_approx(snapshot.battle_speed, 1.0) else "1x"
	if _btn_battle_speed_2x != null:
		_btn_battle_speed_2x.text = "[2x]" if is_equal_approx(snapshot.battle_speed, 2.0) else "2x"
	if _btn_battle_speed_4x != null:
		_btn_battle_speed_4x.text = "[4x]" if is_equal_approx(snapshot.battle_speed, 4.0) else "4x"

	# 2. Structural Condition & Casualties
	if _lbl_fortress_battle_status != null:
		var armor_val: int = int(snapshot.fortress_data.get("armor", 50))
		_lbl_fortress_battle_status.text = "Benteng: HP %d/1000 | Armor: %d | Dinding: HP %d/500 | Gerbang: HP %d/300" % [
			snapshot.fortress_hp,
			armor_val,
			snapshot.wall_hp,
			snapshot.gate_hp
		]

	if _lbl_casualties_summary != null:
		var dead_s: int = int(snapshot.battle_casualties.get("dead_soldiers", 0))
		var dead_h_count: int = snapshot.battle_heroes_killed.size()
		var dmg_fort: int = int(snapshot.battle_casualties.get("fortress_damage", 0))
		_lbl_casualties_summary.text = "Korban: Prajurit Gugur: %d | Hero Gugur: %d | Kerusakan Benteng: %d" % [
			dead_s, dead_h_count, dmg_fort
		]

	# 3. Canonical 7 Zones
	for zone_id in BattlefieldZone.CANONICAL_ZONES:
		var status_str: String = _get_zone_status(zone_id, snapshot)
		if _zone_status_labels.has(zone_id):
			(_zone_status_labels[zone_id] as Label).text = "%s %s" % [zone_id, status_str]
		if _zone_detail_labels.has(zone_id):
			(_zone_detail_labels[zone_id] as Label).text = _get_zone_details_string(zone_id, snapshot)

	# 4. Party 1 Tactical Forces Summary
	if _lbl_party1_summary != null:
		var p1_lines: Array[String] = []
		var p1_zone: String = str(snapshot.battle_party_data.get("current_zone", "GATE"))
		var p1_intent: String = str(snapshot.battle_party_data.get("tactical_intent", "HOLD_POSITION"))
		var p1_form: String = str(snapshot.battle_party_data.get("formation", "BALANCED"))
		var p1_members: Array = snapshot.battle_party_data.get("member_hero_ids", [])
		var p1_leader: String = str(snapshot.battle_party_data.get("leader_hero_id", ""))

		p1_lines.append("=== PARTY 1 TEMPUR (Zona: %s | Formasi: %s | Intensi: %s) ===" % [p1_zone, p1_form, p1_intent])
		if p1_members.is_empty():
			p1_lines.append("  (Tidak ada hero yang ditugaskan ke Party 1)")
		else:
			for hid in p1_members:
				var h_data: Dictionary = {}
				for hd in snapshot.heroes_data:
					if hd.get("hero_id", "") == hid:
						h_data = hd
						break
				if h_data.is_empty():
					continue
				var h_name: String = str(h_data.get("hero_name", hid))
				var h_role: String = str(h_data.get("role", "HERO"))
				var h_alive: bool = bool(h_data.get("is_alive", true))
				var h_hp: int = int(h_data.get("base_hp", 100))
				var h_fat: int = int(h_data.get("fatigue", 0))
				var h_mor: int = int(h_data.get("morale", 100))
				var leader_tag: String = " [LEADER]" if hid == p1_leader else ""
				if h_alive:
					p1_lines.append("  • %s (%s)%s: HP %d | Fatigue: %d/100 | Morale: %d/150 [ALIVE]" % [
						h_name, h_role, leader_tag, h_hp, h_fat, h_mor
					])
				else:
					p1_lines.append("  • %s (%s)%s: [GUGUR (Permadeath)]" % [h_name, h_role, leader_tag])

		# Aura
		var aura_strs: Array[String] = []
		if snapshot.battle_aura_data.has("attack_bonus") and float(snapshot.battle_aura_data["attack_bonus"]) > 0.0:
			aura_strs.append("+%.0f%% ATK" % (float(snapshot.battle_aura_data["attack_bonus"]) * 100.0))
		if snapshot.battle_aura_data.has("defense_bonus") and float(snapshot.battle_aura_data["defense_bonus"]) > 0.0:
			aura_strs.append("+%.0f%% DEF" % (float(snapshot.battle_aura_data["defense_bonus"]) * 100.0))
		if snapshot.battle_aura_data.has("morale_bonus") and float(snapshot.battle_aura_data["morale_bonus"]) > 0.0:
			aura_strs.append("+%.0f Morale" % float(snapshot.battle_aura_data["morale_bonus"]))
		if not aura_strs.is_empty():
			p1_lines.append("  Aura Aktif: " + ", ".join(aura_strs))

		# Soldier deployments
		if not snapshot.battle_deployments_data.is_empty():
			p1_lines.append("Regu Serdadu Tempur:")
			for dep in snapshot.battle_deployments_data:
				var r: String = str(dep.get("resolved_role", dep.get("role", "SOLDIER")))
				var cnt: int = int(dep.get("count", 0))
				var z: String = str(dep.get("zone", "GATE"))
				var f: String = str(dep.get("formation", "NONE"))
				p1_lines.append("  - %d %s di %s [%s]" % [cnt, r, z, f])

		_lbl_party1_summary.text = "\n".join(p1_lines)

	# 5. Populate OptionButton sources if new active deployments exist
	if _opt_cmd_source != null:
		var cur_sel: int = _opt_cmd_source.selected
		var cur_id: String = ""
		if cur_sel >= 0 and cur_sel < _opt_cmd_source.item_count:
			cur_id = str(_opt_cmd_source.get_item_metadata(cur_sel))
		
		var expected_sources: Array[String] = ["party_1"]
		for dep in snapshot.battle_deployments_data:
			var cid: String = str(dep.get("composition_id", ""))
			if not cid.is_empty() and not expected_sources.has(cid):
				expected_sources.append(cid)
		
		if _opt_cmd_source.item_count != expected_sources.size():
			_opt_cmd_source.clear()
			for idx in range(expected_sources.size()):
				var sid: String = expected_sources[idx]
				var sname: String = "Party 1 (Heroes)" if sid == "party_1" else sid
				_opt_cmd_source.add_item(sname)
				_opt_cmd_source.set_item_metadata(idx, sid)
				if sid == cur_id:
					_opt_cmd_source.selected = idx


func _execute_selected_command(cmd_type: String) -> void:
	if controller == null:
		return

	var source_id: String = "party_1"
	if _opt_cmd_source != null and _opt_cmd_source.selected >= 0:
		var meta = _opt_cmd_source.get_item_metadata(_opt_cmd_source.selected)
		if meta != null and not str(meta).is_empty():
			source_id = str(meta)

	var target_zone: String = "CENTER_APPROACH"
	if _opt_cmd_target_zone != null and _opt_cmd_target_zone.selected >= 0:
		var meta = _opt_cmd_target_zone.get_item_metadata(_opt_cmd_target_zone.selected)
		if meta != null and not str(meta).is_empty():
			target_zone = str(meta)

	var target_entity: String = "FORTRESS"
	if _opt_cmd_target_entity != null and _opt_cmd_target_entity.selected >= 0:
		var meta = _opt_cmd_target_entity.get_item_metadata(_opt_cmd_target_entity.selected)
		if meta != null and not str(meta).is_empty():
			target_entity = str(meta)

	var ok: bool = false
	match cmd_type:
		"ADVANCE":
			ok = controller.command_advance(source_id, target_zone)
		"MOVE":
			ok = controller.command_move(source_id, target_zone)
		"HOLD", "HOLD_POSITION":
			ok = controller.command_hold_position(source_id)
		"RETREAT":
			ok = controller.command_retreat(source_id)
		"PROTECT":
			ok = controller.command_protect(source_id, target_entity)
		"FOCUS", "FOCUS_TARGET":
			ok = controller.command_focus_target(source_id, target_entity)
		"FOLLOW":
			ok = controller.command_follow(source_id, target_entity)
		_:
			ok = controller.send_commander_command(cmd_type, source_id, target_zone, target_zone, target_entity, target_entity)

	if ok:
		var msg: String = "[COMMAND] Perintah [%s] berhasil dikirim ke unit %s." % [cmd_type, source_id]
		if _lbl_cmd_feedback != null:
			_lbl_cmd_feedback.text = msg
		_set_feedback(msg)
	else:
		var rej: String = "[DITOLAK] Perintah [%s] ditolak! Target tidak valid untuk unit %s." % [cmd_type, source_id]
		if _lbl_cmd_feedback != null:
			_lbl_cmd_feedback.text = rej
		_set_feedback(rej)


func _render_battle_result_ui(snapshot: GameStateSnapshot) -> void:
	for child in _panel_stage_actions.get_children():
		_panel_stage_actions.remove_child(child)
		child.queue_free()
	_result_overlay = PanelContainer.new()
	_panel_stage_actions.add_child(_result_overlay, true)
	_result_overlay.name = "BattleResultPanel"

	var vbox := VBoxContainer.new()
	_result_overlay.add_child(vbox)

	var res: Dictionary = snapshot.last_battle_result
	var vic: bool = bool(res.get("victory", false))

	_lbl_result_headline = Label.new()
	_lbl_result_headline.name = "LblResultHeadline"
	_lbl_result_headline.text = "=== BATTLE RESULT: %s ===" % ("VICTORY!" if vic else "DEFEAT / BREACH!")
	vbox.add_child(_lbl_result_headline)

	var f_data: Dictionary = snapshot.fortress_data
	var cur_hp: int = int(f_data.get("current_hp", snapshot.fortress_hp))
	var max_hp: int = int(f_data.get("max_hp", 1000))
	var dmg_taken: int = int(res.get("fortress_damage_taken", 0))

	var dead_s: int = int(res.get("total_dead_soldiers", 0))
	var eq_lost: int = int(res.get("equipment_lost", 0))
	var eq_dmg: int = int(res.get("equipment_damaged", 0))
	var loot_gold: int = int(res.get("loot_gold", 0))
	var loot_core: int = int(res.get("loot_monster_core", 0))
	var loot_mat: int = int(res.get("loot_monster_material", 0))
	var exp_val: int = int(res.get("exp_per_hero", 0))

	_lbl_result_body = Label.new()
	_lbl_result_body.name = "LblResultBody"
	_lbl_result_body.text = "• Kerusakan Benteng: %d (Sisa HP: %d / %d)\n• Korban Serdadu: %d prajurit gugur permanen\n• Perlengkapan: %d hancur permanen | %d rusak berat (-40 dur)\n• Hadiah: +%d Gold | +%d Core | +%d Material | +%d EXP per Hero" % [
		dmg_taken, cur_hp, max_hp, dead_s, eq_lost, eq_dmg, loot_gold, loot_core, loot_mat, exp_val
	]
	vbox.add_child(_lbl_result_body)

	var hero_loss: bool = false
	for h in snapshot.heroes_data:
		if not bool(h.get("is_alive", true)):
			hero_loss = true
			break
	if hero_loss:
		var h_notice := Label.new()
		h_notice.name = "LblHeroPermadeathNotice"
		h_notice.text = "[HERO PERMADEATH: Hero yang gugur telah melepaskan seluruh perlengkapannya kembali ke gudang bersama.]"
		vbox.add_child(h_notice)

	var recovery_note := Label.new()
	recovery_note.text = "[INFO RECOVERY: Seluruh perlengkapan prajurit yang selamat telah dikembalikan ke gudang benteng. Penempatan serdadu bersifat sementara per gelombang.]"
	vbox.add_child(recovery_note)

	_btn_result_proceed = Button.new()
	_btn_result_proceed.name = "BtnProceedResult"
	_btn_result_proceed.text = ">> PROCEED (RECOVERY / NEXT WAVE) >>"
	_btn_result_proceed.custom_minimum_size = Vector2(200, 44)
	_btn_result_proceed.pressed.connect(func(): if controller: controller.proceed_from_result())
	vbox.add_child(_btn_result_proceed)


func _render_game_over_ui(snapshot: GameStateSnapshot) -> void:
	for child in _panel_stage_actions.get_children():
		_panel_stage_actions.remove_child(child)
		child.queue_free()
	_game_over_overlay = PanelContainer.new()
	_panel_stage_actions.add_child(_game_over_overlay, true)
	_game_over_overlay.name = "GameOverPanel"

	var vbox := VBoxContainer.new()
	_game_over_overlay.add_child(vbox)

	_lbl_game_over_headline = Label.new()
	_lbl_game_over_headline.name = "LblGameOverHeadline"
	_lbl_game_over_headline.text = "☠ GAME OVER — FORTRESS COLLAPSED ☠"
	vbox.add_child(_lbl_game_over_headline)

	_lbl_game_over_body = Label.new()
	_lbl_game_over_body.name = "LblGameOverBody"
	_lbl_game_over_body.text = "Benteng hancur total (HP 0). Pertahanan berakhir pada Wave %d." % snapshot.current_wave
	vbox.add_child(_lbl_game_over_body)

	_btn_game_over_restart = Button.new()
	_btn_game_over_restart.name = "BtnRestartSession"
	_btn_game_over_restart.text = "↺ RESTART SESSION"
	_btn_game_over_restart.custom_minimum_size = Vector2(180, 44)
	_btn_game_over_restart.pressed.connect(func(): if controller: controller.restart_session())
	vbox.add_child(_btn_game_over_restart)


# ==============================================================================
# PHASE 6F: TACTICAL BATTLE UI PUBLIC INSPECTION METHODS
# ==============================================================================

func get_zone_panel(zone_name: String) -> PanelContainer:
	return _zone_panels.get(zone_name, null)


func get_zone_status_text(zone_name: String) -> String:
	if _zone_status_labels.has(zone_name) and _zone_status_labels[zone_name] != null:
		return (_zone_status_labels[zone_name] as Label).text
	return ""


func get_zone_detail_text(zone_name: String) -> String:
	if _zone_detail_labels.has(zone_name) and _zone_detail_labels[zone_name] != null:
		return (_zone_detail_labels[zone_name] as Label).text
	return ""


func get_battlefield_container() -> Control:
	return _battlefield_panel


func get_command_button(cmd_name: String) -> Button:
	match cmd_name.strip_edges().to_upper():
		"ADVANCE":
			return _btn_cmd_advance
		"MOVE":
			return _btn_cmd_move
		"HOLD", "HOLD_POSITION", "HOLD POSITION":
			return _btn_cmd_hold
		"RETREAT":
			return _btn_cmd_retreat
		"PROTECT":
			return _btn_cmd_protect
		"FOCUS", "FOCUS_TARGET", "FOCUS TARGET":
			return _btn_cmd_focus
		"FOLLOW":
			return _btn_cmd_follow
		_:
			return null


func get_speed_button(speed_val: int) -> Button:
	match speed_val:
		1:
			return _btn_battle_speed_1x
		2:
			return _btn_battle_speed_2x
		4:
			return _btn_battle_speed_4x
		_:
			return null


func get_pause_button() -> Button:
	return _btn_battle_pause_resume


func get_command_feedback_text() -> String:
	if _lbl_cmd_feedback != null:
		return _lbl_cmd_feedback.text
	return ""


func get_battle_tick_display_text() -> String:
	if _lbl_battle_telemetry_header != null:
		return _lbl_battle_telemetry_header.text
	return ""


func get_fortress_status_text() -> String:
	if _lbl_fortress_battle_status != null:
		return _lbl_fortress_battle_status.text
	return ""


func get_casualties_display_text() -> String:
	if _lbl_casualties_summary != null:
		return _lbl_casualties_summary.text
	return ""


func get_party1_summary_text() -> String:
	if _lbl_party1_summary != null:
		return _lbl_party1_summary.text
	return ""


func get_result_title_text() -> String:
	if _lbl_result_headline != null:
		return _lbl_result_headline.text
	return ""


func get_game_over_title_text() -> String:
	if _lbl_game_over_headline != null:
		return _lbl_game_over_headline.text
	return ""


func is_battlefield_visible() -> bool:
	return _battlefield_panel != null and is_instance_valid(_battlefield_panel) and _battlefield_panel.get_parent() == _panel_stage_actions and _battlefield_panel.visible


func is_result_overlay_visible() -> bool:
	return _result_overlay != null and is_instance_valid(_result_overlay) and _result_overlay.get_parent() == _panel_stage_actions and _result_overlay.visible


func is_game_over_overlay_visible() -> bool:
	return _game_over_overlay != null and is_instance_valid(_game_over_overlay) and _game_over_overlay.get_parent() == _panel_stage_actions and _game_over_overlay.visible

