class_name GameController
extends Node

## GameController
## Menghubungkan input pengguna dan lifecycle Godot ke GameCoordinator.
## Mengelola timer tempo simulasi pertempuran untuk kecepatan 1x, 2x, 4x, dan pause/resume.
## Tidak menyimpan state otoritatif gameplay (state murni milik coordinator/domain).

signal battle_step_triggered(step_index: int)

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const CommanderCommand = preload("res://scripts/domain/command/commander_command.gd")

var coordinator: GameCoordinator
var _battle_timer: Timer
var _battle_step_index: int = 0


func _ready() -> void:
	_ensure_timer()


func _ensure_timer() -> void:
	if _battle_timer == null:
		_battle_timer = Timer.new()
		_battle_timer.one_shot = true
		_battle_timer.timeout.connect(_on_battle_timer_timeout)
	if not _battle_timer.is_inside_tree() and is_inside_tree():
		add_child(_battle_timer)


func setup(p_coordinator: GameCoordinator) -> void:
	coordinator = p_coordinator
	_ensure_timer()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
		
	var key_event := event as InputEventKey
	match key_event.keycode:
		KEY_SPACE:
			toggle_pause()
		KEY_1:
			set_speed(1.0)
		KEY_2:
			set_speed(2.0)
		KEY_3, KEY_4:
			set_speed(4.0)


# ==============================================================================
# PLAYER ACTIONS & COMMAND HANDLERS
# ==============================================================================

func allocate_workers(repair: int, blacksmith: int, construction: int) -> bool:
	if coordinator == null:
		return false
	return coordinator.allocate_workers(repair, blacksmith, construction)


func recruit_soldier(role: String, count: int = 1) -> bool:
	if coordinator == null:
		return false
	return coordinator.recruit_soldier(role, count)


func create_deployment(count: int, primary: String, secondary: String = "NONE", armor: String = "NONE") -> bool:
	if coordinator == null:
		return false
	return coordinator.create_deployment(count, primary, secondary, armor)


func remove_deployment(composition_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.remove_deployment(composition_id)


func reconfigure_deployment(old_composition_id: String, new_count: int, new_primary: String, new_secondary: String = "NONE", new_armor: String = "NONE") -> bool:
	if coordinator == null:
		return false
	return coordinator.reconfigure_deployment(old_composition_id, new_count, new_primary, new_secondary, new_armor)


func get_warehouse_stock(eq_type: String) -> int:
	if coordinator == null:
		return 0
	return coordinator.get_warehouse_stock(eq_type)


func get_reserved_equipment_stock(eq_type: String) -> int:
	if coordinator == null:
		return 0
	return coordinator.get_reserved_equipment_stock(eq_type)


func get_total_owned_stock(eq_type: String) -> int:
	if coordinator == null:
		return 0
	return coordinator.get_total_owned_stock(eq_type)


func get_hero_held_equipment_stock(eq_type: String) -> int:
	if coordinator == null:
		return 0
	return get_total_owned_stock(eq_type) - get_warehouse_stock(eq_type) - get_reserved_equipment_stock(eq_type)


func get_available_soldiers() -> int:
	if coordinator == null:
		return 0
	return coordinator.get_available_soldiers()


func get_active_deployments() -> Array:
	if coordinator == null:
		return []
	return coordinator.get_active_deployments()


func get_hero(hero_id: String) -> RefCounted:
	if coordinator == null:
		return null
	return coordinator.get_hero(hero_id)


func is_equipment_option_available(eq_type: String, count: int) -> bool:
	if coordinator == null:
		return false
	return coordinator.is_equipment_option_available(eq_type, count)


func equip_hero(hero_id: String, slot: String, eq_type: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.equip_hero(hero_id, slot, eq_type)


func unequip_hero(hero_id: String, slot: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.unequip_hero(hero_id, slot)


func swap_hero_equipment(hero_id: String, slot: String, new_eq_type: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.swap_hero_equipment(hero_id, slot, new_eq_type)


func inspect_wave() -> bool:
	if coordinator == null:
		return false
	return coordinator.inspect_wave()


func cancel_wave_preview() -> bool:
	if coordinator == null:
		return false
	return coordinator.cancel_wave_preview()


func start_battle() -> bool:
	if coordinator == null:
		return false
	var ok: bool = coordinator.start_battle()
	if ok:
		_battle_step_index = 0
		_schedule_next_battle_step()
	return ok


func send_commander_command(command_type: String, target_group: String = "ALL", target_id: String = "") -> bool:
	if coordinator == null:
		return false
	var cmd := CommanderCommand.new(command_type, target_group, target_id)
	return coordinator.send_commander_command(cmd)


func toggle_pause() -> void:
	if coordinator == null:
		return
	var snapshot: GameStateSnapshot = coordinator.get_current_state()
	var new_paused: bool = not snapshot.battle_paused
	coordinator.set_battle_paused(new_paused)
	if _battle_timer != null and _battle_timer.is_inside_tree():
		_battle_timer.paused = new_paused
		if not new_paused and _battle_timer.is_stopped() and snapshot.game_phase == "BATTLE":
			_schedule_next_battle_step()


func set_speed(speed: float) -> void:
	if coordinator == null:
		return
	coordinator.set_battle_speed(speed)
	# Sesuaikan sisa waktu timer jika timer aktif
	if _battle_timer != null and _battle_timer.is_inside_tree() and not _battle_timer.is_stopped() and not _battle_timer.paused:
		var base_delay: float = 1.0 / maxf(0.5, speed)
		_battle_timer.start(base_delay)


func resolve_battle_immediately() -> Dictionary:
	if coordinator == null:
		return {}
	if _battle_timer != null and _battle_timer.is_inside_tree():
		_battle_timer.stop()
	return coordinator.execute_battle()


func proceed_from_result() -> bool:
	if coordinator == null:
		return false
	return coordinator.proceed_from_result()


func restart_session() -> void:
	if coordinator == null:
		return
	if _battle_timer != null and _battle_timer.is_inside_tree():
		_battle_timer.stop()
	coordinator.restart_session()


# ==============================================================================
# BATTLE TIMER PACING
# ==============================================================================

func _schedule_next_battle_step() -> void:
	if coordinator == null or _battle_timer == null:
		return
	var snapshot: GameStateSnapshot = coordinator.get_current_state()
	if snapshot.game_phase != "BATTLE":
		if _battle_timer.is_inside_tree():
			_battle_timer.stop()
		return
		
	var speed: float = snapshot.battle_speed
	var delay: float = 1.0 / maxf(0.5, speed)
	_battle_timer.paused = snapshot.battle_paused
	if _battle_timer.is_inside_tree():
		_battle_timer.start(delay)


func _on_battle_timer_timeout() -> void:
	if coordinator == null:
		return
	var snapshot: GameStateSnapshot = coordinator.get_current_state()
	if snapshot.game_phase != "BATTLE":
		return

	_battle_step_index += 1
	battle_step_triggered.emit(_battle_step_index)
	
	if _battle_step_index >= 3:
		# Pertempuran selesai langkah-demi-langkah, selesaikan via CombatEngine
		coordinator.execute_battle()
	else:
		_schedule_next_battle_step()
