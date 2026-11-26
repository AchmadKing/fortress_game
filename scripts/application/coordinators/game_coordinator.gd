class_name GameCoordinator
extends RefCounted

## GameCoordinator
## Mendemonstrasikan koordinasi application layer dengan aliran data satu arah (Unidirectional Data Flow).
## Presentation/UI mengirim perintah (command) ke coordinator,
## coordinator memvalidasi legalitas via GameplayStateMachine,
## memanggil simulasi, memutasi domain state,
## kemudian memancarkan sinyal reaktif state_changed(snapshot) untuk diobservasi oleh UI.
## Dilarang keras menjadi God Object: tidak memuat formula combat, casualty, threat, atau ekonomi!

signal state_changed(new_snapshot: GameStateSnapshot)
signal step_completed(tick: int)

const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const CommanderCommand = preload("res://scripts/domain/command/commander_command.gd")
const PopulationModel = preload("res://scripts/domain/model/population_model.gd")
const FortressModel = preload("res://scripts/domain/model/fortress_model.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const EconomyManager = preload("res://scripts/simulation/economy_manager.gd")
const WaveGenerator = preload("res://scripts/simulation/wave_generator.gd")
const CombatEngine = preload("res://scripts/simulation/combat_engine.gd")

var _current_state: GameStateSnapshot
var _simulation_runner: SimulationRunner
var _state_machine: GameplayStateMachine

# Active Domain Models & Simulation Subsystems
var _population: PopulationModel
var _fortress: FortressModel
var _economy: EconomyManager
var _wave_gen: WaveGenerator
var _combat_engine: CombatEngine
var _heroes: Array = []       # Array[HeroModel]
var _warehouse: Array = []    # Array[EquipmentModel]

# Phase 3B Temporary Soldier Deployment
var _active_deployments: Array = []        # Array[DeploymentComposition]
var _available_soldiers: int = 0
var _last_processed_equipment: Array = []  # Array[EquipmentModel] snapshot returned from battle

var _current_wave_num: int = 1
var _current_wave_data: Dictionary = {}
var _last_battle_result: Dictionary = {}
var _last_command: CommanderCommand = null
var _battle_speed: float = 1.0
var _battle_paused: bool = false
var _session_seed: int = 12345


func _init(initial_state: GameStateSnapshot = null, runner: SimulationRunner = null) -> void:
	if initial_state != null:
		_current_state = initial_state
	else:
		_current_state = GameStateSnapshot.new()
		
	if runner != null:
		_simulation_runner = runner
	else:
		_simulation_runner = SimulationRunner.new()

	_state_machine = GameplayStateMachine.new()
	if _current_state.state_name in GameplayStateMachine.ALL_STATES:
		_state_machine.current_state = _current_state.state_name
	elif _current_state.game_phase in GameplayStateMachine.ALL_STATES:
		_state_machine.current_state = _current_state.game_phase

	_init_default_domain_models()


func get_current_state() -> GameStateSnapshot:
	# Mengembalikan clone agar external caller (UI) tidak dapat memutasi state internal secara langsung
	return _current_state.clone()


func get_state_machine() -> GameplayStateMachine:
	return _state_machine


# ==============================================================================
# PHASE 1 BACKWARD COMPATIBILITY API
# ==============================================================================

func initialize_session(session_id: String) -> void:
	_current_state.session_id = session_id
	_current_state.state_name = "ACTIVE"
	state_changed.emit(_current_state.clone())


func request_step(delta_tick: int = 1) -> void:
	_current_state = _simulation_runner.step(_current_state, delta_tick)
	step_completed.emit(_current_state.tick)
	state_changed.emit(_current_state.clone())


# ==============================================================================
# PHASE 3 PLAYABLE GAMEPLAY PROTOTYPE API
# ==============================================================================

## Memulai sesi gameplay baru dengan entitas starter seimbang
func start_new_session(session_id: String = "session_proto", seed_val: int = 12345) -> void:
	_session_seed = seed_val
	_current_state.session_id = session_id
	_current_wave_num = 1
	_battle_speed = 1.0
	_battle_paused = false
	_last_command = null
	_last_battle_result = {}

	_init_default_domain_models()

	_state_machine.reset(GameplayStateMachine.STATE_BOOT)
	_state_machine.transition_to(GameplayStateMachine.STATE_PREPARATION)

	_update_snapshot()
	state_changed.emit(_current_state.clone())


## Alokasi pekerja sipil ke 4 tugas sah (Repair, Blacksmith, Construction, Idle)
func allocate_workers(repair: int, blacksmith: int, construction: int) -> bool:
	if _state_machine.current_state != GameplayStateMachine.STATE_PREPARATION:
		push_warning("allocate_workers hanya diizinkan pada fase PREPARATION")
		return false
	var ok: bool = _economy.set_worker_allocation(repair, blacksmith, construction, _population.civilians)
	if ok:
		_update_snapshot()
		state_changed.emit(_current_state.clone())
	return ok


## Rekrutmen serdadu dari warga sipil secara zero-sum
func recruit_soldier(role: String, count: int = 1) -> bool:
	if _state_machine.current_state != GameplayStateMachine.STATE_PREPARATION:
		push_warning("recruit_soldier hanya diizinkan pada fase PREPARATION")
		return false
	var ok: bool = _population.recruit_soldier(role, count)
	if ok:
		_available_soldiers += count
		_update_snapshot()
		state_changed.emit(_current_state.clone())
	return ok


# ==============================================================================
# PHASE 3B TEMPORARY SOLDIER DEPLOYMENT & STOCK MANAGEMENT
# ==============================================================================

func get_warehouse_stock(eq_type: String) -> int:
	var total: int = 0
	for item in _warehouse:
		if item is EquipmentModel and (item as EquipmentModel).role_type == eq_type:
			total += (item as EquipmentModel).quantity
	return total


func get_reserved_equipment_stock(eq_type: String) -> int:
	var total: int = 0
	for comp in _active_deployments:
		if comp is DeploymentComposition:
			for item in (comp as DeploymentComposition).reserved_equipment:
				if item is EquipmentModel and (item as EquipmentModel).role_type == eq_type:
					total += (item as EquipmentModel).quantity
	return total


func get_total_owned_stock(eq_type: String) -> int:
	var total: int = get_warehouse_stock(eq_type) + get_reserved_equipment_stock(eq_type)
	for h in _heroes:
		if h is HeroModel:
			var hero: HeroModel = h as HeroModel
			if hero.has_method("get_equipped_items"):
				for item in hero.get_equipped_items():
					if item is EquipmentModel and (item as EquipmentModel).role_type == eq_type:
						total += (item as EquipmentModel).quantity
	return total


func get_available_soldiers() -> int:
	return _available_soldiers


func get_active_deployments() -> Array:
	return _active_deployments.duplicate(true)


func is_equipment_option_available(eq_type: String, count: int) -> bool:
	return get_warehouse_stock(eq_type) >= count


func create_deployment(count: int, primary: String, secondary: String = "NONE", armor: String = "NONE") -> bool:
	if _state_machine.current_state != GameplayStateMachine.STATE_PREPARATION and _state_machine.current_state != GameplayStateMachine.STATE_WAVE_PREVIEW:
		push_warning("create_deployment hanya diizinkan pada PREPARATION atau WAVE_PREVIEW")
		return false
	
	if count <= 0:
		return false
		
	if _available_soldiers < count:
		return false
		
	var p: String = primary.to_upper().strip_edges()
	var s: String = secondary.to_upper().strip_edges() if not secondary.is_empty() else "NONE"
	var a: String = armor.to_upper().strip_edges() if not armor.is_empty() else "NONE"
	
	# Primary wajib SWORD, SPEAR, atau BOW
	if not (p in ["SWORD", "SPEAR", "BOW"]):
		return false
		
	# Secondary opsional (NONE atau SHIELD), tidak boleh sama dengan primary
	if s != "NONE" and s == p:
		return false
	if s != "NONE" and not (s in ["SHIELD", "SWORD", "SPEAR", "BOW"]):
		return false
		
	# Armor opsional (NONE atau HEAVY_ARMOR), tidak boleh sama dengan primary atau secondary
	if a != "NONE" and (a == p or a == s):
		return false
	if a != "NONE" and a != "HEAVY_ARMOR":
		return false
		
	# Check warehouse stocks
	if get_warehouse_stock(p) < count:
		return false
	if s != "NONE" and get_warehouse_stock(s) < count:
		return false
	if a != "NONE" and get_warehouse_stock(a) < count:
		return false
		
	# Atomic reservation: deduct from warehouse
	var p_items: Array = _deduct_warehouse_stock(p, count)
	var s_items: Array = _deduct_warehouse_stock(s, count) if s != "NONE" else []
	var a_items: Array = _deduct_warehouse_stock(a, count) if a != "NONE" else []
	
	_available_soldiers -= count
	
	var comp_id: String = DeploymentComposition.make_composition_id(p, s, a)
	var existing_comp: DeploymentComposition = null
	for comp in _active_deployments:
		if comp is DeploymentComposition and (comp as DeploymentComposition).composition_id == comp_id:
			existing_comp = comp as DeploymentComposition
			break
			
	if existing_comp != null:
		existing_comp.count += count
		existing_comp.reserved_equipment.append_array(p_items)
		existing_comp.reserved_equipment.append_array(s_items)
		existing_comp.reserved_equipment.append_array(a_items)
	else:
		var new_comp := DeploymentComposition.new(count, p, s, a)
		new_comp.reserved_equipment.append_array(p_items)
		new_comp.reserved_equipment.append_array(s_items)
		new_comp.reserved_equipment.append_array(a_items)
		_active_deployments.append(new_comp)
		
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


func remove_deployment(composition_id: String) -> bool:
	if _state_machine.current_state != GameplayStateMachine.STATE_PREPARATION and _state_machine.current_state != GameplayStateMachine.STATE_WAVE_PREVIEW:
		push_warning("remove_deployment hanya diizinkan pada PREPARATION atau WAVE_PREVIEW")
		return false
		
	var target_idx: int = -1
	var target_comp: DeploymentComposition = null
	for i in range(_active_deployments.size()):
		var comp = _active_deployments[i]
		if comp is DeploymentComposition and (comp as DeploymentComposition).composition_id == composition_id:
			target_idx = i
			target_comp = comp as DeploymentComposition
			break
			
	if target_comp == null or target_idx == -1:
		return false
		
	# Return reserved equipment to warehouse
	for eq in target_comp.reserved_equipment:
		if eq is EquipmentModel:
			_return_equipment_to_warehouse(eq as EquipmentModel)
			
	# Return soldiers to available pool
	_available_soldiers += target_comp.count
	_active_deployments.remove_at(target_idx)
	
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


func reconfigure_deployment(old_composition_id: String, new_count: int, new_primary: String, new_secondary: String = "NONE", new_armor: String = "NONE") -> bool:
	if _state_machine.current_state != GameplayStateMachine.STATE_PREPARATION and _state_machine.current_state != GameplayStateMachine.STATE_WAVE_PREVIEW:
		push_warning("reconfigure_deployment hanya diizinkan pada PREPARATION atau WAVE_PREVIEW")
		return false
		
	var target_idx: int = -1
	var old_comp: DeploymentComposition = null
	for i in range(_active_deployments.size()):
		var comp = _active_deployments[i]
		if comp is DeploymentComposition and (comp as DeploymentComposition).composition_id == old_composition_id:
			target_idx = i
			old_comp = comp as DeploymentComposition
			break
			
	if old_comp == null or target_idx == -1:
		return false
		
	if new_count <= 0:
		return false
		
	# Save state for rollback if anything fails
	var saved_comp: DeploymentComposition = old_comp.clone()
	var saved_available: int = _available_soldiers
	var saved_warehouse: Array = []
	for w in _warehouse:
		if w is EquipmentModel:
			saved_warehouse.append((w as EquipmentModel).clone())
			
	# 1. Temporarily release old deployment
	for eq in old_comp.reserved_equipment:
		if eq is EquipmentModel:
			_return_equipment_to_warehouse(eq as EquipmentModel)
	_available_soldiers += old_comp.count
	_active_deployments.remove_at(target_idx)
	
	# 2. Attempt to create new deployment
	var success: bool = create_deployment(new_count, new_primary, new_secondary, new_armor)
	if not success:
		# Rollback! Restore old state exactly
		_warehouse = saved_warehouse
		_available_soldiers = saved_available
		_active_deployments.insert(target_idx, saved_comp)
		_update_snapshot()
		return false
		
	return true


func _deduct_warehouse_stock(eq_type: String, count: int) -> Array:
	var deducted: Array = []
	var remaining: int = count
	for item in _warehouse:
		if remaining <= 0:
			break
		if item is EquipmentModel and (item as EquipmentModel).role_type == eq_type and (item as EquipmentModel).quantity > 0:
			var eq: EquipmentModel = item as EquipmentModel
			var take: int = mini(remaining, eq.quantity)
			eq.quantity -= take
			remaining -= take
			var reserved := EquipmentModel.new(eq.role_type, eq.tier, eq.durability, take)
			deducted.append(reserved)
	return deducted


func _return_equipment_to_warehouse(item: EquipmentModel) -> void:
	if item == null or item.quantity <= 0:
		return
	var merged: bool = false
	for wh_item in _warehouse:
		if wh_item is EquipmentModel:
			var eq: EquipmentModel = wh_item as EquipmentModel
			if eq.role_type == item.role_type and eq.tier == item.tier and eq.durability == item.durability:
				eq.quantity += item.quantity
				merged = true
				break
	if not merged:
		_warehouse.append(item.clone())


# ==============================================================================
# PHASE 3C HERO EQUIPMENT FOUNDATION
# ==============================================================================

func get_hero(hero_id: String) -> HeroModel:
	for h in _heroes:
		if h is HeroModel and (h as HeroModel).hero_id == hero_id:
			return h as HeroModel
	return null


func equip_hero(hero_id: String, slot: String, eq_type: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("equip_hero dilarang pada fase BATTLE (Battle Lock)")
		return false

	var hero := get_hero(hero_id)
	if hero == null or not hero.is_alive:
		return false

	var s := slot.to_upper().strip_edges()
	var eq := eq_type.to_upper().strip_edges()

	# Validasi slot dan tipe perlengkapan
	match s:
		"PRIMARY":
			if not (eq in ["SWORD", "SPEAR", "BOW"]):
				return false
			if hero.has_equipment("SECONDARY") and hero.get_equipment("SECONDARY").role_type == eq:
				return false
		"SECONDARY":
			if not (eq in ["SHIELD", "SWORD", "SPEAR", "BOW"]):
				return false
			if hero.has_equipment("PRIMARY") and hero.get_equipment("PRIMARY").role_type == eq:
				return false
		"ARMOR":
			if eq != "HEAVY_ARMOR":
				return false
		_:
			return false

	# Validasi ketersediaan di gudang bersama
	if get_warehouse_stock(eq) < 1:
		return false

	# Atomic transaction:
	# 1. Lepas perlengkapan lama di slot tersebut jika ada
	var old_eq: EquipmentModel = hero.unequip(s) as EquipmentModel
	if old_eq != null:
		_return_equipment_to_warehouse(old_eq)

	# 2. Ambil 1 unit dari gudang bersama
	var deducted: Array = _deduct_warehouse_stock(eq, 1)
	if deducted.is_empty():
		# Rollback jika gagal ambil
		if old_eq != null:
			_deduct_warehouse_stock(old_eq.role_type, 1)
			hero.equip(s, old_eq)
		return false

	hero.equip(s, deducted[0])
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


func unequip_hero(hero_id: String, slot: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("unequip_hero dilarang pada fase BATTLE (Battle Lock)")
		return false

	var hero := get_hero(hero_id)
	if hero == null:
		return false

	var s := slot.to_upper().strip_edges()
	if not hero.has_equipment(s):
		return false

	var old_eq: EquipmentModel = hero.unequip(s) as EquipmentModel
	if old_eq != null:
		_return_equipment_to_warehouse(old_eq)

	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


func swap_hero_equipment(hero_id: String, slot: String, new_eq_type: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("swap_hero_equipment dilarang pada fase BATTLE (Battle Lock)")
		return false

	var hero := get_hero(hero_id)
	if hero == null or not hero.is_alive:
		return false

	var eq := new_eq_type.to_upper().strip_edges()
	if get_warehouse_stock(eq) < 1:
		return false

	return equip_hero(hero_id, slot, eq)


## Inspeksi gelombang ancaman berikutnya (transisi PREPARATION -> WAVE_PREVIEW)
func inspect_wave() -> bool:
	if _state_machine.current_state != GameplayStateMachine.STATE_PREPARATION:
		return false
	if not _state_machine.transition_to(GameplayStateMachine.STATE_WAVE_PREVIEW):
		return false
	_current_wave_data = _simulation_runner.prepare_wave(_current_wave_num, _session_seed + _current_wave_num)
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Batalkan preview gelombang (transisi WAVE_PREVIEW -> PREPARATION)
func cancel_wave_preview() -> bool:
	if _state_machine.current_state != GameplayStateMachine.STATE_WAVE_PREVIEW:
		return false
	if not _state_machine.transition_to(GameplayStateMachine.STATE_PREPARATION):
		return false
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Memulai pertempuran (transisi WAVE_PREVIEW -> BATTLE)
func start_battle() -> bool:
	if _state_machine.current_state != GameplayStateMachine.STATE_WAVE_PREVIEW:
		return false
	if not _state_machine.transition_to(GameplayStateMachine.STATE_BATTLE):
		return false
	_current_state.battle_phase_name = "RANGED_VOLLEY"
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Mengeksekusi pertempuran multi-fase melalui CombatEngine Phase 2 (BATTLE -> RESULT)
func execute_battle(seed_val: int = 42) -> Dictionary:
	if _state_machine.current_state != GameplayStateMachine.STATE_BATTLE:
		push_warning("execute_battle hanya diizinkan pada fase BATTLE")
		return {}
	
	if _current_wave_data.is_empty():
		_current_wave_data = _simulation_runner.prepare_wave(_current_wave_num, _session_seed + _current_wave_num)
		
	var battle_seed: int = seed_val + _current_wave_num
	var battle_population: PopulationModel = _population.clone()
	var deployment_equipment_snapshot: Array = []
	
	if not _active_deployments.is_empty():
		for r in battle_population.soldiers.keys():
			battle_population.soldiers[r] = 0
		for comp in _active_deployments:
			if comp is DeploymentComposition:
				var c: DeploymentComposition = comp as DeploymentComposition
				battle_population.soldiers[c.resolved_role] = int(battle_population.soldiers.get(c.resolved_role, 0)) + c.count
				for eq in c.reserved_equipment:
					if eq is EquipmentModel:
						deployment_equipment_snapshot.append((eq as EquipmentModel).clone())
	else:
		# Fallback backward-compatibility mode
		for eq in _warehouse:
			if eq is EquipmentModel:
				deployment_equipment_snapshot.append((eq as EquipmentModel).clone())

	var result: Dictionary = _simulation_runner.run_battle(
		battle_population,
		_heroes,
		deployment_equipment_snapshot,
		_fortress,
		_current_wave_data,
		battle_seed
	)
	_last_battle_result = result
	_last_processed_equipment = deployment_equipment_snapshot
	_current_state.battle_phase_name = "RESOLVED"

	_state_machine.transition_to(GameplayStateMachine.STATE_RESULT)
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return result


## Mengirimkan perintah intensi komandan (HOLD, ADVANCE, RETREAT, PROTECT, FOCUS, FOLLOW)
func send_commander_command(command: CommanderCommand) -> bool:
	if command == null or not CommanderCommand.is_valid_type(command.command_type):
		return false
	_last_command = command.clone()
	_last_command.status = "LOGGED_PHASE3_DEFERRED"
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Mengatur kecepatan simulasi pertempuran (1x, 2x, 4x)
func set_battle_speed(speed: float) -> void:
	_battle_speed = clampf(speed, 0.5, 4.0)
	_current_state.battle_speed = _battle_speed
	state_changed.emit(_current_state.clone())


## Menjeda atau melanjutkan pertempuran
func set_battle_paused(paused: bool) -> void:
	_battle_paused = paused
	_current_state.battle_paused = _battle_paused
	state_changed.emit(_current_state.clone())


## Melanjutkan alur dari RESULT:
## Jika benteng hancur (HP <= 0) -> GAME_OVER (Recovery tidak dijalankan).
## Jika benteng selamat (HP > 0) -> RECOVERY -> PREPARATION (wave berikutnya).
func proceed_from_result() -> bool:
	if _state_machine.current_state != GameplayStateMachine.STATE_RESULT:
		return false
		
	var is_fortress_dead: bool = _fortress.is_destroyed() or bool(_last_battle_result.get("game_over", false))
	
	if is_fortress_dead:
		# Fortress hancur: Transisi langsung ke GAME_OVER
		if not _state_machine.transition_to(GameplayStateMachine.STATE_GAME_OVER):
			return false
		_update_snapshot()
		state_changed.emit(_current_state.clone())
		return true
	else:
		# Fortress selamat: Transisi ke RECOVERY
		if not _state_machine.transition_to(GameplayStateMachine.STATE_RECOVERY):
			return false
			
		# Eksekusi Recovery pasca-tempur murni menggunakan sistem Phase 2 existing
		# 1. Battle loot ditambahkan ke kas bendahara
		var loot: int = int(_last_battle_result.get("loot_gold", 0))
		_economy.treasury_gold += loot
		
		# 2. Proses siklus ekonomi (gaji & reparasi benteng oleh Repair Worker)
		_economy.process_cycle(_population, _fortress)
		
		# 3. Istirahat hero yang kelelahan via existing HeroModel.rest()
		for h in _heroes:
			if h is HeroModel and (h as HeroModel).is_alive:
				var hero_obj: HeroModel = h as HeroModel
				if hero_obj.fatigue >= 30:
					hero_obj.rest(20)

		# 3b. Hero permadeath equipment return to shared warehouse (Phase 3C)
		for h in _heroes:
			if h is HeroModel and not (h as HeroModel).is_alive:
				var dead_hero_items: Array = (h as HeroModel).clear_equipment()
				for item in dead_hero_items:
					if item is EquipmentModel:
						_return_equipment_to_warehouse(item as EquipmentModel)
					
		# 4. Pertumbuhan alami populasi via existing PopulationModel.grow_population()
		_population.grow_population(0.08)
		
		# 5. Pasca-tempur Phase 3B: Kembalikan perlengkapan aktif & proses korban jiwa
		var casualties: Dictionary = _last_battle_result.get("casualties", {})
		if not casualties.is_empty():
			_population.apply_casualties(casualties)

		if not _active_deployments.is_empty():
			# Multi-slot equipment casualty processing (A11)
			# CombatEngine already processed primary role equipment in _last_processed_equipment.
			# Now process secondary weapon and armor casualty loss/wear if any:
			var battle_seed: int = _session_seed + _current_wave_num
			for comp in _active_deployments:
				if comp is DeploymentComposition:
					var c: DeploymentComposition = comp as DeploymentComposition
					var deaths: int = int(casualties.get(c.resolved_role, 0))
					if deaths > 0:
						var extra_slots: Array = []
						if c.secondary_weapon != "NONE" and c.resolved_role != "SHIELD_INFANTRY":
							extra_slots.append(c.secondary_weapon)
						elif c.resolved_role == "SHIELD_INFANTRY":
							extra_slots.append(c.primary_weapon)
						if c.armor != "NONE" and c.resolved_role != "HEAVY_INFANTRY":
							extra_slots.append(c.armor)
							
						for slot_type in extra_slots:
							for i in range(deaths):
								for item in _last_processed_equipment:
									if item is EquipmentModel:
										var eq: EquipmentModel = item as EquipmentModel
										if eq.role_type == slot_type and eq.quantity > 0:
											var roll: float = _combat_engine._seeded_float(battle_seed, slot_type, i * 17)
											if roll < 0.35:
												eq.quantity -= 1
											else:
												eq.apply_wear(40)
											break
			
			# Kembalikan seluruh gear yang selamat ke gudang benteng
			for item in _last_processed_equipment:
				if item is EquipmentModel and (item as EquipmentModel).quantity > 0:
					_return_equipment_to_warehouse(item as EquipmentModel)

			_active_deployments.clear()
			_last_processed_equipment.clear()

		# Kembalikan seluruh prajurit hidup ke kolam prajurit benteng
		_available_soldiers = _population.get_total_soldiers()
		
		# 6. Naikkan nomor gelombang dan kembali ke PREPARATION
		_current_wave_num += 1
		if not _state_machine.transition_to(GameplayStateMachine.STATE_PREPARATION):
			return false
			
		_update_snapshot()
		state_changed.emit(_current_state.clone())
		return true


## Reset / restart sesi permainan dari kondisi Game Over
func restart_session() -> void:
	start_new_session("session_restart_" + str(Time.get_ticks_msec()))


# ==============================================================================
# INTERNAL HELPER & SNAPSHOT GENERATION
# ==============================================================================

func _init_default_domain_models() -> void:
	_population = PopulationModel.new(18, 30, 100)
	_fortress = FortressModel.new(1000, 40)
	_economy = EconomyManager.new(150)
	_wave_gen = WaveGenerator.new()
	_combat_engine = CombatEngine.new()

	_heroes = []
	var h1 := HeroModel.new("hero_alder", "Alder Ironclad", 1, 4)
	var h2 := HeroModel.new("hero_lyra", "Lyra Windwalker", 2, 4)
	_heroes.append(h1)
	_heroes.append(h2)

	_warehouse = []
	_warehouse.append(EquipmentModel.new("SWORD", 1, 100, 10))
	_warehouse.append(EquipmentModel.new("SHIELD", 1, 100, 10))
	_warehouse.append(EquipmentModel.new("SPEAR", 1, 100, 10))
	_warehouse.append(EquipmentModel.new("BOW", 1, 100, 10))
	_warehouse.append(EquipmentModel.new("HEAVY_ARMOR", 1, 100, 10))

	_active_deployments = []
	_last_processed_equipment = []

	_population.recruit_soldier("SWORDSMAN", 2)
	_population.recruit_soldier("SHIELD_INFANTRY", 2)
	_population.recruit_soldier("ARCHER", 2)

	_available_soldiers = _population.get_total_soldiers()

	_update_snapshot()


func _update_snapshot() -> void:
	_current_state.game_phase = _state_machine.current_state
	_current_state.state_name = _state_machine.current_state
	_current_state.current_wave = _current_wave_num
	_current_state.battle_speed = _battle_speed
	_current_state.battle_paused = _battle_paused

	if _fortress != null:
		_current_state.fortress_data = {
			"current_hp": _fortress.current_hp,
			"max_hp": _fortress.max_hp,
			"armor": _fortress.armor,
			"upgrade_tier": _fortress.upgrade_tier,
			"is_destroyed": _fortress.is_destroyed()
		}

	if _population != null:
		_current_state.population_data = {
			"civilians": _population.civilians,
			"housing_capacity": _population.housing_capacity,
			"morale": _population.morale,
			"mercenaries": _population.mercenaries,
			"soldiers": _population.soldiers.duplicate(true),
			"total_soldiers": _population.get_total_soldiers(),
			"total_population": _population.get_total_population()
		}

	if _economy != null:
		_current_state.economy_data = {
			"treasury_gold": _economy.treasury_gold,
			"repair_workers": _economy.repair_workers,
			"blacksmith_workers": _economy.blacksmith_workers,
			"construction_workers": _economy.construction_workers,
			"idle_workers": _economy.idle_workers,
			"worker_salary": _economy.worker_salary,
			"soldier_salaries": _economy.soldier_salaries.duplicate(true)
		}

	_current_state.heroes_data = []
	for h in _heroes:
		if h is HeroModel:
			var hero: HeroModel = h as HeroModel
			_current_state.heroes_data.append({
				"hero_id": hero.hero_id,
				"hero_name": hero.hero_name,
				"level": hero.level,
				"current_exp": hero.current_exp,
				"current_star": hero.current_star,
				"fatigue": hero.fatigue,
				"morale": hero.morale,
				"is_alive": hero.is_alive,
				"effective_atk": hero.get_effective_atk(),
				"effective_def": hero.get_effective_def(),
				"primary_equipment": hero.primary_equipment.role_type if hero.primary_equipment != null else "NONE",
				"secondary_equipment": hero.secondary_equipment.role_type if hero.secondary_equipment != null else "NONE",
				"armor_equipment": hero.armor_equipment.role_type if hero.armor_equipment != null else "NONE"
			})

	_current_state.warehouse_data = []
	for item in _warehouse:
		if item is EquipmentModel:
			var eq: EquipmentModel = item as EquipmentModel
			_current_state.warehouse_data.append({
				"role_type": eq.role_type,
				"tier": eq.tier,
				"durability": eq.durability,
				"max_durability": eq.max_durability,
				"quantity": eq.quantity,
				"is_broken": eq.is_broken()
			})

	_current_state.active_deployments_data = []
	for comp in _active_deployments:
		if comp is DeploymentComposition:
			_current_state.active_deployments_data.append((comp as DeploymentComposition).to_dictionary())
	_current_state.available_soldiers_count = _available_soldiers
	_current_state.total_living_soldiers_count = _population.get_total_soldiers() if _population != null else 0

	_current_state.current_wave_data = _current_wave_data.duplicate(true)
	_current_state.last_battle_result = _last_battle_result.duplicate(true)
	_current_state.last_commander_command = _last_command.to_dictionary() if _last_command != null else {}
