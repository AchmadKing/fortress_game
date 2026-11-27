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


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _battle_timer != null and not _battle_timer.is_inside_tree():
			_battle_timer.free()


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


func create_soldier_deployment(count: int, primary: String, secondary: String = "NONE", armor: String = "NONE") -> bool:
	return create_deployment(count, primary, secondary, armor)


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


func get_warehouse_usable_stock(eq_type: String) -> int:
	if coordinator == null:
		return 0
	return coordinator.get_warehouse_usable_stock(eq_type)


func get_warehouse_damaged_stock(eq_type: String) -> int:
	if coordinator == null:
		return 0
	return coordinator.get_warehouse_damaged_stock(eq_type)


func get_warehouse_total_stock(eq_type: String) -> int:
	if coordinator == null:
		return 0
	return coordinator.get_warehouse_total_stock(eq_type)


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
	return get_total_owned_stock(eq_type) - get_warehouse_total_stock(eq_type) - get_reserved_equipment_stock(eq_type)


func get_available_soldiers() -> int:
	if coordinator == null:
		return 0
	return coordinator.get_available_soldiers()


func get_total_deployed_soldiers() -> int:
	if coordinator == null:
		return 0
	return coordinator.get_total_deployed_soldiers()


func get_active_deployments() -> Array:
	if coordinator == null:
		return []
	return coordinator.get_active_deployments()


func get_blacksmith_workers() -> int:
	if coordinator == null:
		return 0
	return coordinator.get_blacksmith_workers()


func get_blacksmith_discount() -> float:
	if coordinator == null:
		return 0.0
	return coordinator.get_blacksmith_discount()


func get_equipment_repair_cost(eq_type: String, count: int = 1) -> int:
	if coordinator == null:
		return 0
	return coordinator.get_equipment_repair_cost(eq_type, count)


func repair_equipment(eq_type: String, count: int = 1) -> bool:
	if coordinator == null:
		return false
	return coordinator.repair_equipment(eq_type, count)


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


# ==============================================================================
# PHASE 4G HERO MANAGEMENT ACTIONS & FORWARDING
# ==============================================================================

func get_heroes() -> Array:
	if coordinator == null:
		return []
	return coordinator.get_heroes()


func can_recruit_hero() -> bool:
	if coordinator == null:
		return false
	return coordinator.can_recruit_hero()


func recruit_hero(candidate_or_role: Variant = null, cur_star: int = 1, pot_star: int = 3, p_id: String = "", p_name: String = "") -> RefCounted:
	if coordinator == null:
		return null
	return coordinator.recruit_hero(candidate_or_role, cur_star, pot_star, p_id, p_name)


func can_ascend_hero(hero_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_ascend_hero(hero_id)


func ascend_hero(hero_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.ascend_hero(hero_id)


func can_train_hero(hero_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_train_hero(hero_id)


func train_hero(hero_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.train_hero(hero_id)


func can_rest_hero(hero_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_rest_hero(hero_id)


func rest_hero(hero_id: String, recovery: int = 25) -> bool:
	if coordinator == null:
		return false
	return coordinator.rest_hero(hero_id, recovery)


func can_unlock_hero_skill(hero_id: String, skill_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_unlock_hero_skill(hero_id, skill_id)


func unlock_hero_skill(hero_id: String, skill_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.unlock_hero_skill(hero_id, skill_id)


func can_allocate_hero_talent(hero_id: String, branch_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_allocate_hero_talent(hero_id, branch_id)


func allocate_hero_talent(hero_id: String, branch_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.allocate_hero_talent(hero_id, branch_id)


func get_party(party_id: String) -> RefCounted:
	if coordinator == null:
		return null
	return coordinator.get_party(party_id)


func get_parties() -> Array:
	if coordinator == null:
		return []
	return coordinator.get_parties()


func can_assign_hero_to_party(hero_id: String, party_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_assign_hero_to_party(hero_id, party_id)


func assign_hero_to_party(hero_id: String, party_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.assign_hero_to_party(hero_id, party_id)


func can_remove_hero_from_party(hero_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_remove_hero_from_party(hero_id)


func remove_hero_from_party(hero_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.remove_hero_from_party(hero_id)


func can_set_party_leader(hero_id: String, party_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_set_party_leader(hero_id, party_id)


func set_party_leader(hero_id: String, party_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.set_party_leader(hero_id, party_id)


# ==============================================================================
# PHASE 5: FORTRESS & MANAGEMENT SYSTEMS DELEGATION
# ==============================================================================

func convert_civilian_to_worker(count: int = 1) -> bool:
	if coordinator == null:
		return false
	return coordinator.convert_civilian_to_worker(count)


func convert_worker_to_civilian(count: int = 1) -> bool:
	if coordinator == null:
		return false
	return coordinator.convert_worker_to_civilian(count)


func reassign_worker(from_job: String, to_job: String, count: int = 1) -> bool:
	if coordinator == null:
		return false
	return coordinator.reassign_worker(from_job, to_job, count)


func get_worker_allocations() -> Dictionary:
	if coordinator == null:
		return {}
	return coordinator.get_worker_allocations()


func get_worker_morale() -> int:
	if coordinator == null:
		return 100
	return coordinator.get_worker_morale()


func get_worker_productivity() -> float:
	if coordinator == null:
		return 1.0
	return coordinator.get_worker_productivity()


func modify_worker_morale(delta: int) -> void:
	if coordinator != null:
		coordinator.modify_worker_morale(delta)


func get_building(building_id: String) -> RefCounted:
	if coordinator == null:
		return null
	return coordinator.get_building(building_id)


func get_buildings() -> Array:
	if coordinator == null:
		return []
	return coordinator.get_buildings()


func can_upgrade_building(building_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_upgrade_building(building_id)


func upgrade_building(building_id: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.upgrade_building(building_id)


func can_repair_structure(target: String, hp_amount: int) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_repair_structure(target, hp_amount)


func repair_structure(target: String, hp_amount: int) -> bool:
	if coordinator == null:
		return false
	return coordinator.repair_structure(target, hp_amount)


func can_start_construction(target_building_id: String, gold_cost: int, target_progress: int) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_start_construction(target_building_id, gold_cost, target_progress)


func start_construction(target_building_id: String, gold_cost: int = 50, target_progress: int = 100) -> bool:
	if coordinator == null:
		return false
	return coordinator.start_construction(target_building_id, gold_cost, target_progress)


func advance_construction(progress_delta: int) -> bool:
	if coordinator == null:
		return false
	return coordinator.advance_construction(progress_delta)


func cancel_construction() -> bool:
	if coordinator == null:
		return false
	return coordinator.cancel_construction()


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
	if coordinator.is_battle_paused():
		resume_battle()
	else:
		pause_battle()


func pause_battle() -> bool:
	if coordinator == null:
		return false
	var ok: bool = coordinator.pause_battle()
	if ok and _battle_timer != null and _battle_timer.is_inside_tree():
		_battle_timer.paused = true
	return ok


func resume_battle() -> bool:
	if coordinator == null:
		return false
	var ok: bool = coordinator.resume_battle()
	if ok and _battle_timer != null and _battle_timer.is_inside_tree():
		_battle_timer.paused = false
		if _battle_timer.is_stopped() and coordinator.get_current_state().game_phase == "BATTLE":
			_schedule_next_battle_step()
	return ok


func set_speed(speed: float) -> bool:
	if coordinator == null:
		return false
	var ok: bool = coordinator.set_battle_speed(speed)
	# Sesuaikan sisa waktu timer jika timer aktif
	if ok and _battle_timer != null and _battle_timer.is_inside_tree() and not _battle_timer.is_stopped() and not _battle_timer.paused:
		var base_delay: float = 1.0 / maxf(0.5, speed)
		_battle_timer.start(base_delay)
	return ok


func step_simulation() -> bool:
	if coordinator == null:
		return false
	return coordinator.step_simulation()


func advance_simulation_time(delta_seconds: float) -> int:
	if coordinator == null:
		return 0
	return coordinator.advance_simulation_time(delta_seconds)


func get_battle_tick() -> int:
	if coordinator == null:
		return 0
	return coordinator.get_battle_tick()


func is_battle_paused() -> bool:
	if coordinator == null:
		return false
	return coordinator.is_battle_paused()


func get_battle_speed() -> float:
	if coordinator == null:
		return 1.0
	return coordinator.get_battle_speed()


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
