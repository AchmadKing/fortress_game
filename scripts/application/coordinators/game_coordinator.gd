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
		_ensure_equipment_quantity_for_role(role, int(_population.soldiers.get(role, 0)))
		_update_snapshot()
		state_changed.emit(_current_state.clone())
	return ok


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
	var result: Dictionary = _simulation_runner.run_battle(
		_population,
		_heroes,
		_warehouse,
		_fortress,
		_current_wave_data,
		battle_seed
	)
	_last_battle_result = result
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
					
		# 4. Pertumbuhan alami populasi via existing PopulationModel.grow_population()
		_population.grow_population(0.08)
		
		# 5. Naikkan nomor gelombang dan kembali ke PREPARATION
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

	_population.recruit_soldier("SWORDSMAN", 2)
	_population.recruit_soldier("SHIELD_INFANTRY", 2)
	_population.recruit_soldier("ARCHER", 2)

	_update_snapshot()


func _ensure_equipment_quantity_for_role(role: String, count: int) -> void:
	var role_map: Dictionary = {
		"SWORDSMAN": "SWORD",
		"SHIELD_INFANTRY": "SHIELD",
		"SPEARMAN": "SPEAR",
		"ARCHER": "BOW",
		"HEAVY_INFANTRY": "HEAVY_ARMOR"
	}
	var eq_type: String = str(role_map.get(role, ""))
	if eq_type.is_empty():
		return
		
	var found: bool = false
	for item in _warehouse:
		if item is EquipmentModel and (item as EquipmentModel).role_type == eq_type:
			var eq: EquipmentModel = item as EquipmentModel
			if eq.quantity < count:
				eq.quantity = count
			found = true
			break
	if not found:
		_warehouse.append(EquipmentModel.new(eq_type, 1, 100, count))


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
				"effective_def": hero.get_effective_def()
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

	_current_state.current_wave_data = _current_wave_data.duplicate(true)
	_current_state.last_battle_result = _last_battle_result.duplicate(true)
	_current_state.last_commander_command = _last_command.to_dictionary() if _last_command != null else {}
