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


func start_battle(enable_tactical_sim: bool = true) -> bool:
	if coordinator == null:
		return false
	var ok: bool = coordinator.start_battle(enable_tactical_sim)
	if ok:
		_battle_step_index = 0
		_schedule_next_battle_step()
	return ok


func send_commander_command(command_type: String, target_group: String = "ALL", target_id: String = "", target_zone: String = "", target_enemy: String = "", target_entity: String = "") -> bool:
	if coordinator == null:
		return false
	var cmd := CommanderCommand.new(command_type, target_group, target_id, 0, target_zone, target_enemy, target_entity)
	return coordinator.send_commander_command(cmd)


func command_hold_position(source_id: String = "party_1") -> bool:
	return command_hold(source_id)


func command_focus(source_id: String = "party_1", enemy_target: String = "") -> bool:
	return command_focus_target(source_id, enemy_target)


# ==============================================================================
# PHASE 6D: COMMANDER COMMANDS CONVENIENCE METHODS
# ==============================================================================

func command_advance(source_id: String = "party_1", target_zone: String = "") -> bool:
	return send_commander_command(CommanderCommand.TYPE_ADVANCE, source_id, target_zone, target_zone)


func command_move(source_id: String = "party_1", target_zone: String = "") -> bool:
	return send_commander_command(CommanderCommand.TYPE_MOVE, source_id, target_zone, target_zone)


func command_hold(source_id: String = "party_1") -> bool:
	return send_commander_command(CommanderCommand.TYPE_HOLD_POSITION, source_id)


func command_retreat(source_id: String = "party_1") -> bool:
	return send_commander_command(CommanderCommand.TYPE_RETREAT, source_id)


func command_protect(source_id: String = "party_1", target: String = "FORTRESS") -> bool:
	return send_commander_command(CommanderCommand.TYPE_PROTECT, source_id, target, "", "", target)


func command_focus_target(source_id: String = "party_1", enemy_target: String = "") -> bool:
	return send_commander_command(CommanderCommand.TYPE_FOCUS_TARGET, source_id, enemy_target, "", enemy_target)


func command_follow(source_id: String = "party_1", friendly_target: String = "") -> bool:
	return send_commander_command(CommanderCommand.TYPE_FOLLOW, source_id, friendly_target, "", "", friendly_target)


func get_last_commander_command() -> CommanderCommand:
	if coordinator == null:
		return null
	return coordinator.get_last_commander_command()


func get_command_history() -> Array:
	if coordinator == null:
		return []
	return coordinator.get_command_history()


func get_active_commander_intents() -> Dictionary:
	if coordinator == null:
		return {}
	return coordinator.get_active_commander_intents()


func get_retreat_target_zone(current_zone: String) -> String:
	if coordinator == null:
		return "FORTRESS"
	return coordinator.get_retreat_target_zone(current_zone)


# ==============================================================================
# PHASE 6E: TACTICAL BATTLE & CASUALTY CONVENIENCE METHODS
# ==============================================================================

func get_battle_enemy_groups() -> Array:
	if coordinator == null:
		return []
	return coordinator.get_battle_enemy_groups()


func get_battle_zone_pressure(zone: String = "") -> Variant:
	if coordinator == null:
		return {} if zone.is_empty() else 0
	return coordinator.get_battle_zone_pressure(zone)


func get_accumulated_pressure(zone: String = "") -> Variant:
	if coordinator == null:
		return {} if zone.is_empty() else 0
	return coordinator.get_accumulated_pressure(zone)


func get_battle_casualties() -> Dictionary:
	if coordinator == null:
		return {}
	return coordinator.get_battle_casualties()


func is_battle_finished() -> bool:
	if coordinator == null:
		return false
	return coordinator.is_battle_finished()


func is_battle_victory() -> bool:
	if coordinator == null:
		return false
	return coordinator.is_battle_victory()


func get_battle_heroes_killed() -> Array:
	if coordinator == null:
		return []
	return coordinator.get_battle_heroes_killed()


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


func toggle_battle_pause() -> bool:
	if coordinator == null:
		return false
	if coordinator.is_battle_paused():
		return resume_battle()
	else:
		return pause_battle()


func set_speed(speed: float) -> bool:
	if coordinator == null:
		return false
	var ok: bool = coordinator.set_battle_speed(speed)
	# Sesuaikan sisa waktu timer jika timer aktif
	if ok and _battle_timer != null and _battle_timer.is_inside_tree() and not _battle_timer.is_stopped() and not _battle_timer.paused:
		var base_delay: float = 1.0 / maxf(0.5, speed)
		_battle_timer.start(base_delay)
	return ok


func set_battle_speed(speed: float) -> bool:
	return set_speed(speed)


func step_simulation() -> bool:
	if coordinator == null:
		return false
	return coordinator.step_simulation()


func step_battle_tick() -> bool:
	return step_simulation()


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


# ==============================================================================
# PHASE 6C: BATTLEFIELD FORMATIONS, PLACEMENT & AURA DELEGATIONS
# ==============================================================================

func set_deployment_zone(composition_id: String, zone: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.set_deployment_zone(composition_id, zone)


func set_deployment_formation(composition_id: String, formation: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.set_deployment_formation(composition_id, formation)


func set_party_zone(party_id: String, zone: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.set_party_zone(party_id, zone)


func set_party_formation(party_id: String, formation: String) -> bool:
	if coordinator == null:
		return false
	return coordinator.set_party_formation(party_id, formation)


func get_active_battle_auras() -> Dictionary:
	if coordinator == null:
		return {}
	return coordinator.get_active_battle_auras()


func apply_battle_chemistry_gain() -> Dictionary:
	if coordinator == null:
		return {}
	return coordinator.apply_battle_chemistry_gain()


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
		if _battle_timer != null and _battle_timer.is_inside_tree():
			_battle_timer.stop()
		return

	# Eksekusi tepat satu langkah simulasi kanonikal via coordinator
	var stepped: bool = coordinator.step_simulation()
	if not stepped:
		# Jika gagal step (misal karena jeda/pause atau state berubah), hentikan timer jika bukan pause
		if coordinator.is_battle_paused():
			return
		if _battle_timer != null and _battle_timer.is_inside_tree():
			_battle_timer.stop()
		return

	_battle_step_index = coordinator.get_battle_tick()
	battle_step_triggered.emit(_battle_step_index)

	# Selama fase tetap BATTLE, jadwalkan tick simulasi berikutnya (tidak auto-resolve execute_battle)
	var post_snapshot: GameStateSnapshot = coordinator.get_current_state()
	if post_snapshot.game_phase == "BATTLE":
		_schedule_next_battle_step()
	else:
		if _battle_timer != null and _battle_timer.is_inside_tree():
			_battle_timer.stop()


# ==============================================================================
# PHASE 7A RESOURCE AUTHORITY DELEGATION
# ==============================================================================

func get_resource(resource_id: String) -> int:
	if coordinator == null:
		return 0
	return coordinator.get_resource(resource_id)


func get_all_resources() -> Dictionary:
	if coordinator == null:
		return {}
	return coordinator.get_all_resources()


func get_monster_cores() -> int:
	if coordinator == null:
		return 0
	return coordinator.get_monster_cores()


func get_monster_materials() -> int:
	if coordinator == null:
		return 0
	return coordinator.get_monster_materials()


func get_basic_materials() -> int:
	if coordinator == null:
		return 0
	return coordinator.get_basic_materials()


func get_rare_materials() -> int:
	if coordinator == null:
		return 0
	return coordinator.get_rare_materials()


func can_afford_resource(resource_id: String, amount: int) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_afford_resource(resource_id, amount)


func can_afford_resources(cost_dict: Dictionary) -> bool:
	if coordinator == null:
		return false
	return coordinator.can_afford_resources(cost_dict)


func add_resource(resource_id: String, amount: int) -> bool:
	if coordinator == null:
		return false
	return coordinator.add_resource(resource_id, amount)


func add_resources(credit_dict: Dictionary) -> bool:
	if coordinator == null:
		return false
	return coordinator.add_resources(credit_dict)


func spend_resource(resource_id: String, amount: int) -> bool:
	if coordinator == null:
		return false
	return coordinator.spend_resource(resource_id, amount)


func spend_resources(cost_dict: Dictionary) -> bool:
	if coordinator == null:
		return false
	return coordinator.spend_resources(cost_dict)
