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

var _lbl_heroes: Label
var _hero_container: VBoxContainer
var _lbl_warehouse: Label
var _blacksmith_container: VBoxContainer

var _last_snapshot: GameStateSnapshot

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

	var lbl_sec_s := Label.new()
	lbl_sec_s.text = "=== DEPLOYED SOLDIERS ==="
	left_vbox.add_child(lbl_sec_s)

	_lbl_soldiers = Label.new()
	_lbl_soldiers.text = "Deployed Soldiers: -"
	left_vbox.add_child(_lbl_soldiers)

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

	# KOLOM KANAN: Heroes & Warehouse
	var right_scroll := ScrollContainer.new()
	right_scroll.custom_minimum_size = Vector2(320, 0)
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right_vbox)
	content_hbox.add_child(right_scroll)

	var lbl_sec3 := Label.new()
	lbl_sec3.text = "=== HERO ROSTER & EQUIPMENT ==="
	right_vbox.add_child(lbl_sec3)

	_lbl_heroes = Label.new()
	_lbl_heroes.text = "Loading Heroes..."
	right_vbox.add_child(_lbl_heroes)

	_hero_container = VBoxContainer.new()
	right_vbox.add_child(_hero_container)

	right_vbox.add_child(HSeparator.new())

	var lbl_sec4 := Label.new()
	lbl_sec4.text = "=== SHARED WAREHOUSE CONSERVATION ==="
	right_vbox.add_child(lbl_sec4)

	_lbl_warehouse = Label.new()
	_lbl_warehouse.text = "Loading Equipment..."
	right_vbox.add_child(_lbl_warehouse)

	right_vbox.add_child(HSeparator.new())

	var lbl_sec5 := Label.new()
	lbl_sec5.text = "=== BLACKSMITH WORKSHOP (REPAIR) ==="
	right_vbox.add_child(lbl_sec5)

	_blacksmith_container = VBoxContainer.new()
	right_vbox.add_child(_blacksmith_container)

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

	# Phase Guidance Banner
	_lbl_phase_guidance.text = _get_phase_guidance_text(snapshot.game_phase)

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
	_render_hero_roster(snapshot)
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
# HERO ROSTER & INTERACTIVE EQUIPMENT RENDERING (RIGHT COLUMN)
# ==============================================================================

func _render_hero_roster(snapshot: GameStateSnapshot) -> void:
	for child in _hero_container.get_children():
		child.queue_free()

	if snapshot.heroes_data.is_empty():
		_lbl_heroes.text = "No heroes registered."
		return

	_lbl_heroes.text = "Active Heroes: %d" % snapshot.heroes_data.size()

	var is_battle: bool = (snapshot.game_phase == "BATTLE")

	for h in snapshot.heroes_data:
		var hero_id: String = str(h.get("hero_id", ""))
		var name_str: String = str(h.get("hero_name", "Hero"))
		var lvl: int = int(h.get("level", 1))
		var fat: int = int(h.get("fatigue", 0))
		var alive: bool = bool(h.get("is_alive", true))
		var prim: String = str(h.get("primary_equipment", "NONE"))
		var sec: String = str(h.get("secondary_equipment", "NONE"))
		var arm: String = str(h.get("armor_equipment", "NONE"))
		var atk: int = int(h.get("effective_atk", 0))
		var def_val: int = int(h.get("effective_def", 0))

		var hero_card := PanelContainer.new()
		var card_vbox := VBoxContainer.new()
		hero_card.add_child(card_vbox)
		_hero_container.add_child(hero_card)

		var status_str: String = "ALIVE" if alive else "DEAD (Permadeath)"
		var lbl_info := Label.new()
		lbl_info.text = "%s (Lv %d) [%s]\nATK: %d | DEF: %d | Fatigue: %d/100" % [
			name_str, lvl, status_str, atk, def_val, fat
		]
		card_vbox.add_child(lbl_info)

		var lbl_gear := Label.new()
		lbl_gear.text = "Gear: [P: %s | S: %s | A: %s]" % [prim, sec, arm]
		card_vbox.add_child(lbl_gear)

		if not alive:
			var dead_notice := Label.new()
			dead_notice.text = "[PERMADEATH: Perlengkapan telah dikembalikan ke gudang]"
			card_vbox.add_child(dead_notice)
			continue

		if is_battle:
			var lock_notice := Label.new()
			lock_notice.text = "[BATTLE LOCK: Perlengkapan terkunci selama pertempuran]"
			card_vbox.add_child(lock_notice)
			continue

		# Kontrol Interaktif Equip / Unequip
		# 1. Primary Slot
		var p_hbox := HBoxContainer.new()
		card_vbox.add_child(p_hbox)
		var p_label := Label.new()
		p_label.text = "Primary:"
		p_hbox.add_child(p_label)

		if prim != "NONE":
			var btn_unequip_p := Button.new()
			btn_unequip_p.text = "Lepas (%s)" % prim
			btn_unequip_p.pressed.connect(func(hid=hero_id): _action_unequip_hero(hid, "PRIMARY"))
			p_hbox.add_child(btn_unequip_p)
		else:
			for w_type in ["SWORD", "SPEAR", "BOW"]:
				var stock_val: int = _get_warehouse_stock(w_type)
				var btn_equip := Button.new()
				btn_equip.text = "+%s (%d)" % [w_type, stock_val]
				btn_equip.disabled = (stock_val < 1)
				btn_equip.pressed.connect(func(hid=hero_id, eq=w_type): _action_equip_hero(hid, "PRIMARY", eq))
				p_hbox.add_child(btn_equip)

		# 2. Secondary Slot
		var s_hbox := HBoxContainer.new()
		card_vbox.add_child(s_hbox)
		var s_label := Label.new()
		s_label.text = "Secondary:"
		s_hbox.add_child(s_label)

		if sec != "NONE":
			var btn_unequip_s := Button.new()
			btn_unequip_s.text = "Lepas (%s)" % sec
			btn_unequip_s.pressed.connect(func(hid=hero_id): _action_unequip_hero(hid, "SECONDARY"))
			s_hbox.add_child(btn_unequip_s)
		else:
			var shield_stock: int = _get_warehouse_stock("SHIELD")
			var btn_shield := Button.new()
			btn_shield.text = "+SHIELD (%d)" % shield_stock
			btn_shield.disabled = (shield_stock < 1 or prim == "SHIELD")
			btn_shield.pressed.connect(func(hid=hero_id): _action_equip_hero(hid, "SECONDARY", "SHIELD"))
			s_hbox.add_child(btn_shield)

		# 3. Armor Slot
		var a_hbox := HBoxContainer.new()
		card_vbox.add_child(a_hbox)
		var a_label := Label.new()
		a_label.text = "Armor:"
		a_hbox.add_child(a_label)

		if arm != "NONE":
			var btn_unequip_a := Button.new()
			btn_unequip_a.text = "Lepas (%s)" % arm
			btn_unequip_a.pressed.connect(func(hid=hero_id): _action_unequip_hero(hid, "ARMOR"))
			a_hbox.add_child(btn_unequip_a)
		else:
			var armor_stock: int = _get_warehouse_stock("HEAVY_ARMOR")
			var btn_armor := Button.new()
			btn_armor.text = "+ARMOR (%d)" % armor_stock
			btn_armor.disabled = (armor_stock < 1)
			btn_armor.pressed.connect(func(hid=hero_id): _action_equip_hero(hid, "ARMOR", "HEAVY_ARMOR"))
			a_hbox.add_child(btn_armor)


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
			var lbl := Label.new()
			lbl.text = "=== BATTLE IN PROGRESS ==="
			_panel_stage_actions.add_child(lbl)

			var lock_lbl := Label.new()
			lock_lbl.text = "[⚔ BATTLE LOCK: Konfigurasi regu, perlengkapan hero & gudang TERKUNCI selama tempur]"
			_panel_stage_actions.add_child(lock_lbl)

			var note_lbl := Label.new()
			note_lbl.text = "Kontrol komandan dan tempo (Pause / 1x / 2x / 4x) tetap aktif."
			_panel_stage_actions.add_child(note_lbl)

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

			var f_data: Dictionary = snapshot.fortress_data
			var cur_hp: int = int(f_data.get("current_hp", 0))
			var max_hp: int = int(f_data.get("max_hp", 1000))
			var dmg_taken: int = int(res.get("fortress_damage_taken", 0))

			var dead_s: int = int(res.get("total_dead_soldiers", 0))
			var eq_lost: int = int(res.get("equipment_lost", 0))
			var eq_dmg: int = int(res.get("equipment_damaged", 0))
			var loot_gold: int = int(res.get("loot_gold", 0))
			var exp_val: int = int(res.get("exp_per_hero", 0))

			var res_details := Label.new()
			res_details.text = "• Kerusakan Benteng: %d (Sisa HP: %d / %d)\n• Korban Serdadu: %d prajurit gugur permanen\n• Perlengkapan: %d hancur permanen | %d rusak berat (-40 dur)\n• Hadiah: +%d Gold | +%d EXP per Hero" % [
				dmg_taken, cur_hp, max_hp, dead_s, eq_lost, eq_dmg, loot_gold, exp_val
			]
			_panel_stage_actions.add_child(res_details)

			var hero_loss: bool = false
			for h in snapshot.heroes_data:
				if not bool(h.get("is_alive", true)):
					hero_loss = true
					break
			if hero_loss:
				var h_notice := Label.new()
				h_notice.text = "[HERO PERMADEATH: Hero yang gugur telah melepaskan seluruh perlengkapannya kembali ke gudang bersama.]"
				_panel_stage_actions.add_child(h_notice)

			var recovery_note := Label.new()
			recovery_note.text = "[INFO RECOVERY: Seluruh perlengkapan prajurit yang selamat telah dikembalikan ke gudang benteng. Penempatan serdadu bersifat sementara per gelombang.]"
			_panel_stage_actions.add_child(recovery_note)

			var btn_proceed := Button.new()
			btn_proceed.text = ">> PROCEED (RECOVERY / NEXT WAVE) >>"
			btn_proceed.pressed.connect(func(): if controller: controller.proceed_from_result())
			_panel_stage_actions.add_child(btn_proceed)

		"GAME_OVER":
			var lbl := Label.new()
			lbl.text = "☠ GAME OVER — FORTRESS COLLAPSED ☠"
			_panel_stage_actions.add_child(lbl)

			var desc := Label.new()
			desc.text = "Benteng hancur total (HP 0). Pertahanan berakhir pada Wave %d." % snapshot.current_wave
			_panel_stage_actions.add_child(desc)

			var btn_restart := Button.new()
			btn_restart.text = "↺ RESTART SESSION"
			btn_restart.pressed.connect(func(): if controller: controller.restart_session())
			_panel_stage_actions.add_child(btn_restart)


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
	if controller == null:
		return
	var ok: bool = controller.send_commander_command(cmd_type)
	if ok:
		_set_feedback("[COMMAND] Commander Command dikirim: [%s] (Pipeline logged)." % cmd_type)


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
