class_name PrototypeDebugView
extends Control

## PrototypeDebugView
## Tampilan telemetri dan kontrol prototipe berbasis teks murni (Phase 3).
## Mengamati sinyal GameCoordinator.state_changed secara reaktif tanpa polling di _process().
## Menyediakan kontrol interaktif untuk alokasi pekerja, rekrutmen serdadu,
## preview gelombang, pause/speed tempur, perintah komandan, dan hasil pertempuran.

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const CommanderCommand = preload("res://scripts/domain/command/commander_command.gd")

var coordinator: GameCoordinator
var controller: GameController

# UI References
var _lbl_state_badge: Label
var _lbl_wave_indicator: Label
var _lbl_speed_pause: Label

var _lbl_fortress_hp: Label
var _lbl_fortress_armor: Label
var _lbl_treasury: Label
var _lbl_civilians: Label
var _lbl_workers: Label
var _lbl_soldiers: Label

var _panel_stage_actions: VBoxContainer
var _txt_telemetry_log: RichTextLabel

var _lbl_heroes: Label
var _lbl_warehouse: Label

var _last_snapshot: GameStateSnapshot


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

	# 1. Header Bar
	var header_panel := PanelContainer.new()
	var header_hbox := HBoxContainer.new()
	header_panel.add_child(header_hbox)
	main_vbox.add_child(header_panel)

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
	_lbl_wave_indicator.text = "Wave: 1/100"
	header_hbox.add_child(_lbl_wave_indicator)

	header_hbox.add_child(VSeparator.new())

	_lbl_speed_pause = Label.new()
	_lbl_speed_pause.text = "Speed: 1x (Active)"
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

	_lbl_workers = Label.new()
	_lbl_workers.text = "Workers:\n- Repair: 0\n- Smith: 0\n- Constr: 0\n- Idle: 12"
	left_vbox.add_child(_lbl_workers)

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

	_lbl_soldiers = Label.new()
	_lbl_soldiers.text = "Soldiers:\n- Swordsman: 2\n- Shield: 2\n- Archer: 2\n- Spear: 0\n- Heavy: 0"
	left_vbox.add_child(_lbl_soldiers)

	content_hbox.add_child(VSeparator.new())

	# KOLOM TENGAH: Action Panel & Telemetry Log
	var center_vbox := VBoxContainer.new()
	center_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(center_vbox)

	var panel_stage := PanelContainer.new()
	panel_stage.custom_minimum_size = Vector2(0, 220)
	_panel_stage_actions = VBoxContainer.new()
	panel_stage.add_child(_panel_stage_actions)
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

	# KOLOM KANAN: Heroes & Warehouse
	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size = Vector2(280, 0)
	var right_vbox := VBoxContainer.new()
	right_scroll.add_child(right_vbox)
	content_hbox.add_child(right_scroll)

	var lbl_sec3 := Label.new()
	lbl_sec3.text = "=== HERO ROSTER ==="
	right_vbox.add_child(lbl_sec3)

	_lbl_heroes = Label.new()
	_lbl_heroes.text = "Loading Heroes..."
	right_vbox.add_child(_lbl_heroes)

	right_vbox.add_child(HSeparator.new())

	var lbl_sec4 := Label.new()
	lbl_sec4.text = "=== WAREHOUSE EQUIPMENT ==="
	right_vbox.add_child(lbl_sec4)

	_lbl_warehouse = Label.new()
	_lbl_warehouse.text = "Loading Equipment..."
	right_vbox.add_child(_lbl_warehouse)

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
	_lbl_speed_pause.text = "Speed: %.1fx (%s)" % [snapshot.battle_speed, pause_str]

	# Left Column updates
	var f_data: Dictionary = snapshot.fortress_data
	var cur_hp: int = int(f_data.get("current_hp", 0))
	var max_hp: int = int(f_data.get("max_hp", 1000))
	var armor: int = int(f_data.get("armor", 40))
	var is_dest: bool = bool(f_data.get("is_destroyed", false))
	_lbl_fortress_hp.text = "HP: %d / %d" % [cur_hp, max_hp]
	_lbl_fortress_armor.text = "Armor: %d | Status: %s" % [armor, "DESTROYED" if is_dest else "INTACT"]

	var e_data: Dictionary = snapshot.economy_data
	var p_data: Dictionary = snapshot.population_data
	_lbl_treasury.text = "Treasury: %d Gold" % int(e_data.get("treasury_gold", 0))
	_lbl_civilians.text = "Civilians: %d / %d | Morale: %d" % [
		int(p_data.get("civilians", 0)),
		int(p_data.get("housing_capacity", 30)),
		int(p_data.get("morale", 100))
	]
	_lbl_workers.text = "Workers:\n- Repair: %d\n- Blacksmith: %d\n- Construction: %d\n- Idle: %d" % [
		int(e_data.get("repair_workers", 0)),
		int(e_data.get("blacksmith_workers", 0)),
		int(e_data.get("construction_workers", 0)),
		int(e_data.get("idle_workers", 0))
	]

	var s_dict: Dictionary = p_data.get("soldiers", {})
	var avail_s: int = int(snapshot.available_soldiers_count)
	var total_s: int = int(snapshot.total_living_soldiers_count)
	var deployed_s: int = total_s - avail_s
	_lbl_soldiers.text = "Soldiers (Total: %d | Avail: %d | Deployed: %d):\n- Swordsman: %d\n- Shield: %d\n- Archer: %d\n- Spearman: %d\n- Heavy: %d" % [
		total_s,
		avail_s,
		deployed_s,
		int(s_dict.get("SWORDSMAN", 0)),
		int(s_dict.get("SHIELD_INFANTRY", 0)),
		int(s_dict.get("ARCHER", 0)),
		int(s_dict.get("SPEARMAN", 0)),
		int(s_dict.get("HEAVY_INFANTRY", 0))
	]

	# Right Column updates
	var heroes_text: String = ""
	for h in snapshot.heroes_data:
		var name_str: String = str(h.get("hero_name", "Hero"))
		var lvl: int = int(h.get("level", 1))
		var fat: int = int(h.get("fatigue", 0))
		var alive: bool = bool(h.get("is_alive", true))
		var status_str: String = "ALIVE" if alive else "DEAD (Permadeath)"
		heroes_text += "- %s (Lv %d)\n  Fatigue: %d/100 | %s\n" % [name_str, lvl, fat, status_str]
	_lbl_heroes.text = heroes_text if not heroes_text.is_empty() else "No heroes"

	var eq_text: String = "--- WAREHOUSE STOCK ---\n"
	for eq in snapshot.warehouse_data:
		var role: String = str(eq.get("role_type", ""))
		var tier: int = int(eq.get("tier", 1))
		var dur: int = int(eq.get("durability", 100))
		var qty: int = int(eq.get("quantity", 0))
		var broken: bool = bool(eq.get("is_broken", false))
		eq_text += "- %s (T%d): %d units (Dur: %d%% %s)\n" % [
			role, tier, qty, dur, "[BROKEN]" if broken else ""
		]
	if snapshot.active_deployments_data.size() > 0:
		eq_text += "\n--- RESERVED IN DEPLOYMENT ---\n"
		for dep in snapshot.active_deployments_data:
			var d_count: int = int(dep.get("count", 0))
			var d_role: String = str(dep.get("resolved_role", ""))
			var d_comp: String = str(dep.get("composition_id", ""))
			eq_text += "- [%dx] %s (%s)\n" % [d_count, d_role, d_comp]
	_lbl_warehouse.text = eq_text

	# Center Action Panel rendering
	_render_stage_actions(snapshot)


func _render_stage_actions(snapshot: GameStateSnapshot) -> void:
	for child in _panel_stage_actions.get_children():
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
			btn_inspect.pressed.connect(func(): if controller: controller.inspect_wave())
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

			var btn_hbox := HBoxContainer.new()
			_panel_stage_actions.add_child(btn_hbox)

			var btn_start_battle := Button.new()
			btn_start_battle.text = "⚔ START BATTLE ⚔"
			btn_start_battle.pressed.connect(func(): if controller: controller.start_battle())
			btn_hbox.add_child(btn_start_battle)

			var btn_cancel := Button.new()
			btn_cancel.text = "Back to Preparation"
			btn_cancel.pressed.connect(func(): if controller: controller.cancel_wave_preview())
			btn_hbox.add_child(btn_cancel)

		"BATTLE":
			var lbl := Label.new()
			lbl.text = "=== BATTLE IN PROGRESS ==="
			_panel_stage_actions.add_child(lbl)

			var lock_lbl := Label.new()
			lock_lbl.text = "[BATTLE LOCK: Deployment configuration is locked during active combat]"
			_panel_stage_actions.add_child(lock_lbl)

			var cmd_lbl := Label.new()
			cmd_lbl.text = "Commander Commands (Intents):"
			_panel_stage_actions.add_child(cmd_lbl)

			var cmd_hbox := HBoxContainer.new()
			_panel_stage_actions.add_child(cmd_hbox)

			var commands := ["HOLD", "ADVANCE", "RETREAT", "PROTECT", "FOCUS", "FOLLOW"]
			for cmd in commands:
				var btn_cmd := Button.new()
				btn_cmd.text = cmd
				btn_cmd.pressed.connect(func(c=cmd): _send_command(c))
				cmd_hbox.add_child(btn_cmd)

			var btn_resolve := Button.new()
			btn_resolve.text = "⚡ Resolve Battle Instantly"
			btn_resolve.pressed.connect(func(): if controller: controller.resolve_battle_immediately())
			_panel_stage_actions.add_child(btn_resolve)

		"RESULT":
			var lbl := Label.new()
			var res: Dictionary = snapshot.last_battle_result
			var vic: bool = bool(res.get("victory", false))
			lbl.text = "=== BATTLE RESULT: %s ===" % ("VICTORY!" if vic else "DEFEAT / BREACH!")
			_panel_stage_actions.add_child(lbl)

			var res_details := Label.new()
			res_details.text = "Fortress Damage: %d | Dead Soldiers: %d\nEquipment Lost: %d | Damaged: %d\nLoot Gold: +%d | EXP/Hero: +%d" % [
				int(res.get("fortress_damage_taken", 0)),
				int(res.get("total_dead_soldiers", 0)),
				int(res.get("equipment_lost", 0)),
				int(res.get("equipment_damaged", 0)),
				int(res.get("loot_gold", 0)),
				int(res.get("exp_per_hero", 0))
			]
			_panel_stage_actions.add_child(res_details)

			var btn_proceed := Button.new()
			btn_proceed.text = ">> PROCEED (RECOVERY / NEXT WAVE) >>"
			btn_proceed.pressed.connect(func(): if controller: controller.proceed_from_result())
			_panel_stage_actions.add_child(btn_proceed)

		"GAME_OVER":
			var lbl := Label.new()
			lbl.text = "☠ GAME OVER — FORTRESS COLLAPSED ☠"
			_panel_stage_actions.add_child(lbl)

			var desc := Label.new()
			desc.text = "Fortress HP reached 0. Sesi berakhir pada Wave %d." % snapshot.current_wave
			_panel_stage_actions.add_child(desc)

			var btn_restart := Button.new()
			btn_restart.text = "↺ RESTART SESSION"
			btn_restart.pressed.connect(func(): if controller: controller.restart_session())
			_panel_stage_actions.add_child(btn_restart)


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
		_log("Alokasi pekerja diubah: Repair=%d, Smith=%d, Constr=%d" % [new_rep, new_smith, new_constr])
	else:
		_log("[WARN] Alokasi pekerja melebihi warga sipil yang tersedia.")


func _recruit(role: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.recruit_soldier(role, 1)
	if ok:
		_log("Rekrut 1 serdadu %s berhasil (Sipil -1)." % role)
	else:
		_log("[WARN] Gagal rekrut %s. Warga sipil tidak mencukupi." % role)


func _send_command(cmd_type: String) -> void:
	if controller == null:
		return
	var ok: bool = controller.send_commander_command(cmd_type)
	if ok:
		_log("Commander Command dikirim: [%s] (Pipeline logged)." % cmd_type)


func _log(message: String) -> void:
	if _txt_telemetry_log != null:
		_txt_telemetry_log.append_text(message + "\n")


func _render_deployment_controls(snapshot: GameStateSnapshot) -> void:
	var dep_title := Label.new()
	dep_title.text = "=== TEMPORARY SOLDIER DEPLOYMENT (Wave %d) ===" % snapshot.current_wave
	_panel_stage_actions.add_child(dep_title)

	var avail_cnt: int = int(snapshot.available_soldiers_count)
	var tot_cnt: int = int(snapshot.total_living_soldiers_count)
	var dep_info := Label.new()
	dep_info.text = "Available Soldiers: %d | Deployed: %d / %d" % [
		avail_cnt,
		tot_cnt - avail_cnt,
		tot_cnt
	]
	_panel_stage_actions.add_child(dep_info)

	var dep_hbox := HBoxContainer.new()
	_panel_stage_actions.add_child(dep_hbox)

	var btn_dep_sword := Button.new()
	btn_dep_sword.text = "+ Deploy 2x Sword"
	btn_dep_sword.disabled = (controller == null) or (avail_cnt < 2) or (controller.get_warehouse_stock("SWORD") < 2)
	btn_dep_sword.pressed.connect(func(): if controller: controller.create_deployment(2, "SWORD"))
	dep_hbox.add_child(btn_dep_sword)

	var btn_dep_shield := Button.new()
	btn_dep_shield.text = "+ Deploy 2x Shield"
	btn_dep_shield.disabled = (controller == null) or (avail_cnt < 2) or (controller.get_warehouse_stock("SWORD") < 2) or (controller.get_warehouse_stock("SHIELD") < 2)
	btn_dep_shield.pressed.connect(func(): if controller: controller.create_deployment(2, "SWORD", "SHIELD"))
	dep_hbox.add_child(btn_dep_shield)

	var btn_dep_archer := Button.new()
	btn_dep_archer.text = "+ Deploy 2x Archer"
	btn_dep_archer.disabled = (controller == null) or (avail_cnt < 2) or (controller.get_warehouse_stock("BOW") < 2)
	btn_dep_archer.pressed.connect(func(): if controller: controller.create_deployment(2, "BOW"))
	dep_hbox.add_child(btn_dep_archer)

	var btn_dep_spear := Button.new()
	btn_dep_spear.text = "+ Deploy 2x Spear"
	btn_dep_spear.disabled = (controller == null) or (avail_cnt < 2) or (controller.get_warehouse_stock("SPEAR") < 2)
	btn_dep_spear.pressed.connect(func(): if controller: controller.create_deployment(2, "SPEAR"))
	dep_hbox.add_child(btn_dep_spear)

	if snapshot.active_deployments_data.size() > 0:
		var active_lbl := Label.new()
		active_lbl.text = "-- Active Groups --"
		_panel_stage_actions.add_child(active_lbl)
		for dep in snapshot.active_deployments_data:
			var comp_id: String = str(dep.get("composition_id", ""))
			var count_val: int = int(dep.get("count", 0))
			var role_val: String = str(dep.get("resolved_role", ""))
			var row := HBoxContainer.new()
			_panel_stage_actions.add_child(row)
			var row_lbl := Label.new()
			row_lbl.text = "[%dx] %s (%s)" % [count_val, role_val, comp_id]
			row.add_child(row_lbl)
			var btn_cancel_dep := Button.new()
			btn_cancel_dep.text = "Cancel"
			btn_cancel_dep.pressed.connect(func(cid=comp_id): if controller: controller.remove_deployment(cid))
			row.add_child(btn_cancel_dep)
