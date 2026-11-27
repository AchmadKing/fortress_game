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
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const PartyModel = preload("res://scripts/domain/model/party_model.gd")
const EconomyManager = preload("res://scripts/simulation/economy_manager.gd")
const WaveGenerator = preload("res://scripts/simulation/wave_generator.gd")
const CombatEngine = preload("res://scripts/simulation/combat_engine.gd")
const WorkerModel = preload("res://scripts/domain/model/worker_model.gd")
const BuildingModel = preload("res://scripts/domain/model/building_model.gd")

const HERO_RECRUITMENT_COST_DEFAULT: int = 500

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
var _parties: Array = []      # Array[PartyModel]
var _warehouse: Array = []    # Array[EquipmentModel]

# Phase 5 Fortress & Management Systems
var _worker_model: WorkerModel
var _buildings: Dictionary = {}
var _active_repair: Dictionary = {}
var _active_construction: Dictionary = {}

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
var _battle_tick: int = 0
var _time_accumulator: float = 0.0
const BASE_TICK_DURATION: float = 1.0
var _session_seed: int = 12345
var _hero_id_counter: int = 1
var _hero_training_wave_tracker: Dictionary = {} # hero_id (String) -> wave_num (int)


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


func get_current_snapshot() -> GameStateSnapshot:
	return get_current_state()


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
	_battle_tick = 0
	_time_accumulator = 0.0
	_last_command = null
	_last_battle_result = {}
	_hero_training_wave_tracker.clear()

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
	var total_pool: int = _population.workers if (_population != null and _population.workers > 0) else (_population.civilians if _population != null else 0)
	var ok: bool = _economy.set_worker_allocation(repair, blacksmith, construction, total_pool)
	if ok:
		if _worker_model != null:
			_worker_model.sync_total_workers(total_pool)
			_worker_model.set_allocations(repair, blacksmith, construction)
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

func get_warehouse_usable_stock(eq_type: String) -> int:
	var total: int = 0
	for item in _warehouse:
		if item is EquipmentModel and (item as EquipmentModel).role_type == eq_type and (item as EquipmentModel).is_usable():
			total += (item as EquipmentModel).quantity
	return total


func get_warehouse_damaged_stock(eq_type: String) -> int:
	var total: int = 0
	for item in _warehouse:
		if item is EquipmentModel and (item as EquipmentModel).role_type == eq_type and (item as EquipmentModel).is_damaged():
			total += (item as EquipmentModel).quantity
	return total


func get_warehouse_total_stock(eq_type: String) -> int:
	return get_warehouse_usable_stock(eq_type) + get_warehouse_damaged_stock(eq_type)


func get_warehouse_stock(eq_type: String) -> int:
	# Single source of truth untuk ketersediaan deploy: hanya item usable (durability == 100%)
	return get_warehouse_usable_stock(eq_type)


func get_reserved_equipment_stock(eq_type: String) -> int:
	var total: int = 0
	for comp in _active_deployments:
		if comp is DeploymentComposition:
			for item in (comp as DeploymentComposition).reserved_equipment:
				if item is EquipmentModel and (item as EquipmentModel).role_type == eq_type:
					total += (item as EquipmentModel).quantity
	return total


func get_total_owned_stock(eq_type: String) -> int:
	var total: int = get_warehouse_total_stock(eq_type) + get_reserved_equipment_stock(eq_type)
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


func get_total_deployed_soldiers() -> int:
	var total: int = 0
	for comp in _active_deployments:
		if comp is DeploymentComposition:
			total += (comp as DeploymentComposition).count
	return total


func get_active_deployments() -> Array:
	return _active_deployments.duplicate(true)


func is_equipment_option_available(eq_type: String, count: int) -> bool:
	return get_warehouse_usable_stock(eq_type) >= count


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


func create_soldier_deployment(count: int, primary: String, secondary: String = "NONE", armor: String = "NONE") -> bool:
	return create_deployment(count, primary, secondary, armor)


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
		if item is EquipmentModel and (item as EquipmentModel).role_type == eq_type and (item as EquipmentModel).is_usable() and (item as EquipmentModel).quantity > 0:
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
# BLACKSMITH REPAIR (PHASE 3D CORRECTION)
# ==============================================================================

func get_treasury_gold() -> int:
	return _economy.treasury_gold if _economy != null else 0


func set_treasury_gold(amount: int) -> void:
	if _economy != null:
		_economy.treasury_gold = maxi(0, amount)
		_update_snapshot()
		state_changed.emit(_current_state.clone())


func get_blacksmith_workers() -> int:
	return _economy.blacksmith_workers if _economy != null else 0


func get_blacksmith_discount() -> float:
	return _economy.get_blacksmith_discount() if _economy != null else 0.0


func get_equipment_repair_cost(eq_type: String, count: int = 1) -> int:
	if count <= 0:
		return 0
	var type_upper: String = eq_type.to_upper().strip_edges()
	for item in _warehouse:
		if item is EquipmentModel:
			var eq: EquipmentModel = item as EquipmentModel
			if eq.role_type == type_upper and eq.is_damaged() and eq.quantity > 0:
				var actual_count: int = mini(count, eq.quantity)
				var smith_discount: float = get_blacksmith_discount()
				var missing: int = eq.max_durability - eq.durability
				var unit_cost: float = float(missing) * eq.get_repair_cost_per_point() * (1.0 - smith_discount)
				return maxi(1, int(ceil(unit_cost * float(actual_count))))
	return 0


func repair_equipment(eq_type: String, count: int = 1) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("repair_equipment dilarang pada fase BATTLE (Battle Lock)")
		return false
	if count <= 0:
		return false

	var type_upper: String = eq_type.to_upper().strip_edges()
	var damaged_item: EquipmentModel = null
	for item in _warehouse:
		if item is EquipmentModel:
			var eq: EquipmentModel = item as EquipmentModel
			if eq.role_type == type_upper and eq.is_damaged() and eq.quantity > 0:
				damaged_item = eq
				break

	if damaged_item == null:
		return false # Tidak ada perlengkapan rusak dari tipe ini

	var actual_count: int = mini(count, damaged_item.quantity)
	var smith_discount: float = get_blacksmith_discount()
	var missing: int = damaged_item.max_durability - damaged_item.durability
	var unit_cost: float = float(missing) * damaged_item.get_repair_cost_per_point() * (1.0 - smith_discount)
	var total_cost: int = maxi(1, int(ceil(unit_cost * float(actual_count))))

	if _economy.treasury_gold < total_cost:
		return false # Emas tidak mencukupi

	# Transaksi reparasi atomik:
	# 1. Konsumsi emas kas
	_economy.treasury_gold -= total_cost

	# 2. Kurangi kuantitas dari bucket rusak
	damaged_item.quantity -= actual_count
	if damaged_item.quantity <= 0:
		_warehouse.erase(damaged_item)

	# 3. Kembalikan ke gudang sebagai perlengkapan 100% durability (usable)
	_return_equipment_to_warehouse(EquipmentModel.new(damaged_item.role_type, damaged_item.tier, 100, actual_count))

	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


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


## Melakukan ascension bintang hero secara atomik (membutuhkan gold dan syarat ascension terpenuhi)
func ascend_hero(hero_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("ascend_hero dilarang pada fase BATTLE (Battle Lock)")
		return false

	var hero := get_hero(hero_id)
	if hero == null or not hero.is_alive:
		return false

	if not hero.can_ascend():
		return false

	var cost: int = hero.get_ascension_cost()
	if _economy == null or _economy.treasury_gold < cost:
		return false

	# Transaksi atomik:
	_economy.treasury_gold -= cost
	var success: bool = hero.ascend()
	if not success:
		_economy.treasury_gold += cost
		return false

	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Memvalidasi apakah pahlawan memenuhi syarat untuk ascension bintang
func can_ascend_hero(hero_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false
	var hero := get_hero(hero_id)
	if hero == null or not hero.is_alive or hero.lifecycle_state == HeroLifecycleState.PERMADEATH:
		return false
	if not hero.can_ascend():
		return false
	var cost: int = hero.get_ascension_cost()
	if _economy == null or _economy.treasury_gold < cost:
		return false
	return true


# ==============================================================================
# PHASE 4C HERO RECRUITMENT & ROSTER MANAGEMENT
# ==============================================================================

## Memvalidasi apakah benteng dapat merekrut pahlawan baru (biaya 500 gold dan bukan fase BATTLE)
func can_recruit_hero() -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false
	if _economy == null or _economy.treasury_gold < HERO_RECRUITMENT_COST_DEFAULT:
		return false
	return true


## Mengembalikan biaya rekrutmen pahlawan standar kanonikal (500 Gold)
func get_hero_recruitment_cost() -> int:
	return HERO_RECRUITMENT_COST_DEFAULT


## Menghasilkan hero_id unik dan deterministik yang belum ada di roster
func generate_unique_hero_id(prefix: String = "hero_recruited_") -> String:
	while true:
		var candidate_id: String = prefix + str(_hero_id_counter)
		_hero_id_counter += 1
		if get_hero(candidate_id) == null:
			return candidate_id
	return prefix + str(Time.get_ticks_msec())


## Menghasilkan kandidat hero terkontrol untuk persiapan rekrutmen atau pengujian
func generate_hero_candidate(
	role: String = HeroRole.KNIGHT,
	cur_star: int = 1,
	pot_star: int = 3,
	p_id: String = "",
	p_name: String = ""
) -> HeroModel:
	var target_id: String = p_id if not p_id.strip_edges().is_empty() else generate_unique_hero_id()
	var target_name: String = p_name if not p_name.strip_edges().is_empty() else ("Recruit " + role.capitalize())
	return HeroModel.new(target_id, target_name, cur_star, pot_star, role, HeroLifecycleState.RECRUITABLE)


## Mengembalikan jumlah pahlawan saat ini di dalam roster benteng
func get_roster_count() -> int:
	return _heroes.size()


## Mengembalikan salinan daftar pahlawan di dalam roster benteng
func get_roster() -> Array:
	return _heroes.duplicate()


## Mengembalikan salinan seluruh pahlawan di dalam roster benteng (alias get_roster)
func get_heroes() -> Array:
	return _heroes.duplicate()


## Memeriksa apakah pahlawan dengan ID tertentu terdaftar di roster
func has_hero(hero_id: String) -> bool:
	return get_hero(hero_id) != null


## Menambahkan instance HeroModel yang valid langsung ke roster (mencegah ID duplikat)
func add_hero(hero: HeroModel) -> bool:
	if hero == null:
		return false
	if not hero.validate_invariants():
		return false
	if get_hero(hero.hero_id) != null:
		return false # Penolakan duplikasi ID
	_heroes.append(hero)
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Memberhentikan / melepas pahlawan dari roster (perlengkapan dikembalikan ke gudang)
func dismiss_hero(hero_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("dismiss_hero dilarang pada fase BATTLE (Battle Lock)")
		return false
	if is_hero_in_party(hero_id):
		return false
	var target_idx: int = -1
	var target_hero: HeroModel = null
	for i in range(_heroes.size()):
		var h = _heroes[i]
		if h is HeroModel and (h as HeroModel).hero_id == hero_id:
			target_idx = i
			target_hero = h as HeroModel
			break
	if target_hero == null or target_idx == -1:
		return false
	var items: Array = target_hero.clear_equipment()
	for item in items:
		if item is EquipmentModel:
			_return_equipment_to_warehouse(item as EquipmentModel)
	_heroes.remove_at(target_idx)
	_hero_training_wave_tracker.erase(hero_id)
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Alias untuk dismiss_hero
func remove_hero(hero_id: String) -> bool:
	return dismiss_hero(hero_id)


## Merekrut pahlawan baru ke dalam roster benteng secara atomik
func recruit_hero(
	candidate_or_role: Variant = null,
	cur_star: int = 1,
	pot_star: int = 3,
	p_id: String = "",
	p_name: String = ""
) -> HeroModel:
	# 1. Validasi Battle Lock
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("recruit_hero dilarang pada fase BATTLE (Battle Lock)")
		return null

	# 2. Tentukan kandidat HeroModel
	var hero: HeroModel = null
	if candidate_or_role is HeroModel:
		hero = candidate_or_role as HeroModel
	elif candidate_or_role is String or candidate_or_role == null:
		var target_role: String = (candidate_or_role as String) if candidate_or_role is String and not (candidate_or_role as String).is_empty() else HeroRole.KNIGHT
		var target_id: String = p_id if not p_id.strip_edges().is_empty() else generate_unique_hero_id()
		var target_name: String = p_name if not p_name.strip_edges().is_empty() else ("Recruit " + target_role.capitalize())
		hero = HeroModel.new(target_id, target_name, cur_star, pot_star, target_role, HeroLifecycleState.RECRUITABLE)
	else:
		return null

	# 3. Validasi Invarian Hero
	if hero == null or not hero.validate_invariants():
		return null

	# 4. Validasi Duplikasi ID di Roster
	if get_hero(hero.hero_id) != null:
		return null

	# 5. Validasi State Siklus Hidup Calon Rekrut (hanya RECRUITABLE atau ROSTER_ACTIVE)
	if hero.lifecycle_state != HeroLifecycleState.RECRUITABLE and hero.lifecycle_state != HeroLifecycleState.ROSTER_ACTIVE:
		return null

	# 6. Validasi Perlengkapan Awal (Harus Kosong untuk Keamanan Konservasi Gudang)
	if hero.has_equipment("PRIMARY") or hero.has_equipment("SECONDARY") or hero.has_equipment("ARMOR"):
		return null

	# 7. Validasi dan Kalkulasi Biaya Emas Kanonikal (500 Gold mutlak)
	var cost: int = get_hero_recruitment_cost()
	if _economy == null or _economy.treasury_gold < cost:
		return null

	# 8. Transaksi Atomik: Potong Emas & Transisi State
	_economy.treasury_gold -= cost
	
	if hero.lifecycle_state == HeroLifecycleState.RECRUITABLE:
		var transitioned: bool = hero.transition_lifecycle_state(HeroLifecycleState.ROSTER_ACTIVE)
		if not transitioned:
			# Rollback
			_economy.treasury_gold += cost
			return null

	# 9. Masukkan ke Roster Benteng
	_heroes.append(hero)

	# 10. Perbarui Snapshot & Emit Sinyal
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return hero


# ==============================================================================
# PHASE 4D HERO TRAINING, FATIGUE, & MORALE
# ==============================================================================

## Memeriksa apakah pahlawan telah melakukan sesi latihan pada gelombang saat ini
func has_hero_trained_this_wave(hero_id: String) -> bool:
	return int(_hero_training_wave_tracker.get(hero_id, -1)) == _current_wave_num


## Memvalidasi kelayakan pahlawan untuk melakukan latihan pada gelombang saat ini
func can_train_hero(hero_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false
	var hero := get_hero(hero_id)
	if hero == null or not hero.is_alive:
		return false
	if hero.lifecycle_state == HeroLifecycleState.PERMADEATH or hero.lifecycle_state == HeroLifecycleState.BATTLE_ACTIVE:
		return false
	if has_hero_trained_this_wave(hero.hero_id):
		return false
	if not hero.can_train(15):
		return false
	return true


## Menjalankan sesi latihan untuk pahlawan (40 EXP, +15 fatigue, max 1 session/hero/wave)
func train_hero(hero_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("train_hero dilarang pada fase BATTLE (Battle Lock)")
		return false
	var hero := get_hero(hero_id)
	if hero == null or not hero.is_alive:
		return false
	if hero.lifecycle_state == HeroLifecycleState.PERMADEATH or hero.lifecycle_state == HeroLifecycleState.BATTLE_ACTIVE:
		return false
	if has_hero_trained_this_wave(hero.hero_id):
		return false
	if not hero.can_train(15):
		return false

	# Eksekusi latihan secara atomik
	hero.train(40, 15)
	_hero_training_wave_tracker[hero.hero_id] = _current_wave_num

	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Memvalidasi kelayakan pahlawan untuk beristirahat
func can_rest_hero(hero_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false
	var hero := get_hero(hero_id)
	if hero == null or not hero.is_alive:
		return false
	if hero.lifecycle_state == HeroLifecycleState.PERMADEATH or hero.lifecycle_state == HeroLifecycleState.BATTLE_ACTIVE:
		return false
	return true


## Menjalankan aksi istirahat untuk pahlawan (-25 fatigue, +5 morale)
func rest_hero(hero_id: String, recovery: int = 25) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("rest_hero dilarang pada fase BATTLE (Battle Lock)")
		return false
	var hero := get_hero(hero_id)
	if hero == null or not hero.is_alive:
		return false
	if hero.lifecycle_state == HeroLifecycleState.PERMADEATH or hero.lifecycle_state == HeroLifecycleState.BATTLE_ACTIVE:
		return false

	# Eksekusi istirahat secara atomik
	hero.rest(recovery)

	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


# ==============================================================================
# PHASE 4E HERO SKILLS & TALENTS
# ==============================================================================

## Memvalidasi kelayakan pahlawan untuk membuka skill kanonikal
func can_unlock_hero_skill(hero_id: String, skill_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false
	var hero := get_hero(hero_id)
	if hero == null:
		return false
	return hero.can_unlock_skill(skill_id)


## Membuka skill kanonikal untuk pahlawan dengan proteksi Battle Lock
func unlock_hero_skill(hero_id: String, skill_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("unlock_hero_skill dilarang pada fase BATTLE (Battle Lock)")
		return false
	var hero := get_hero(hero_id)
	if hero == null:
		return false
	var success: bool = hero.unlock_skill(skill_id)
	if success:
		_update_snapshot()
		state_changed.emit(_current_state.clone())
	return success


## Memvalidasi kelayakan pahlawan untuk mengalokasikan poin bakat
func can_allocate_hero_talent(hero_id: String, branch_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false
	var hero := get_hero(hero_id)
	if hero == null:
		return false
	return hero.can_allocate_talent(branch_id)


## Mengalokasikan 1 poin bakat pahlawan ke cabang tertentu dengan proteksi Battle Lock
func allocate_hero_talent(hero_id: String, branch_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("allocate_hero_talent dilarang pada fase BATTLE (Battle Lock)")
		return false
	var hero := get_hero(hero_id)
	if hero == null:
		return false
	var success: bool = hero.allocate_talent(branch_id)
	if success:
		_update_snapshot()
		state_changed.emit(_current_state.clone())
	return success


# ==============================================================================
# PHASE 4F HERO PARTY & CHEMISTRY MANAGEMENT
# ==============================================================================

## Mengambil instance PartyModel berdasarkan ID regu ("party_1" atau "party_2")
func get_party(party_id: String) -> PartyModel:
	var p_id: String = party_id.strip_edges().to_lower()
	for p in _parties:
		if p is PartyModel and (p as PartyModel).party_id == p_id:
			return p as PartyModel
	return null


## Mengembalikan salinan daftar seluruh regu benteng
func get_parties() -> Array:
	return _parties.duplicate()


## Mengembalikan daftar instance HeroModel yang terdaftar dalam regu tertentu
func get_party_members(party_id: String) -> Array:
	var p := get_party(party_id)
	if p == null:
		return []
	var members: Array = []
	for m_id in p.member_hero_ids:
		var h := get_hero(str(m_id))
		if h != null:
			members.append(h)
	return members


## Mengembalikan ID regu tempat hero bernaung ("" jika RESERVE)
func get_hero_party_id(hero_id: String) -> String:
	var hero := get_hero(hero_id)
	if hero == null:
		return ""
	return hero.party_id


## Memeriksa apakah hero terdaftar dalam salah satu regu
func is_hero_in_party(hero_id: String) -> bool:
	return not get_hero_party_id(hero_id).is_empty()


## Mengembalikan regu tempur aktif benteng (Party 1 pada Phase 4)
func get_active_battle_party() -> PartyModel:
	return get_party(PartyModel.PARTY_1_ID)


## Mengembalikan daftar ID pahlawan hidup pada Party 1 yang siap diterjunkan ke medan laga
func get_active_battle_hero_ids() -> Array:
	var p := get_active_battle_party()
	if p == null:
		return []
	var active_ids: Array = []
	for m_id in p.member_hero_ids:
		var h := get_hero(str(m_id))
		if h != null and h.is_alive and h.lifecycle_state != HeroLifecycleState.PERMADEATH:
			active_ids.append(h.hero_id)
	return active_ids


## Mengembalikan daftar instance HeroModel hidup pada Party 1 yang siap bertempur
func get_active_battle_heroes() -> Array:
	var ids := get_active_battle_hero_ids()
	var heroes_list: Array = []
	for id in ids:
		var h := get_hero(str(id))
		if h != null:
			heroes_list.append(h)
	return heroes_list


## Memvalidasi kelayakan penugasan pahlawan ke dalam regu tertentu
func can_assign_hero_to_party(hero_id: String, party_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false
	if _state_machine.current_state != GameplayStateMachine.STATE_PREPARATION and _state_machine.current_state != GameplayStateMachine.STATE_WAVE_PREVIEW:
		return false

	var hero := get_hero(hero_id)
	if hero == null or not hero.is_alive or hero.lifecycle_state == HeroLifecycleState.PERMADEATH:
		return false

	var party := get_party(party_id)
	if party == null:
		return false

	if party.is_full():
		return false

	# Hero tidak boleh sudah berada di party lain atau di party yang sama
	if hero.is_in_party() or not hero.party_id.is_empty():
		return false
	for p in _parties:
		if p is PartyModel and (p as PartyModel).has_member(hero.hero_id):
			return false

	# Status siklus hidup harus ROSTER_ACTIVE untuk dapat masuk party
	if hero.lifecycle_state != HeroLifecycleState.ROSTER_ACTIVE:
		return false

	return true


## Menugaskan pahlawan ke dalam regu secara atomik
func assign_hero_to_party(hero_id: String, party_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("assign_hero_to_party dilarang pada fase BATTLE (Battle Lock)")
		return false

	if not can_assign_hero_to_party(hero_id, party_id):
		return false

	var hero := get_hero(hero_id)
	var party := get_party(party_id)

	var prev_party_id: String = hero.get_party_id()
	var prev_lifecycle: String = hero.lifecycle_state

	# 1. Transisi lifecycle state ke IN_PARTY
	var trans_ok: bool = hero.transition_lifecycle_state(HeroLifecycleState.IN_PARTY)
	if not trans_ok:
		return false

	# 2. Penugasan ID regu menggunakan canonical domain method
	var set_ok: bool = hero.set_party_id(party.party_id)
	if not set_ok:
		# Rollback lifecycle
		if not hero.transition_lifecycle_state(prev_lifecycle):
			hero.lifecycle_state = prev_lifecycle
		return false

	# 3. Penambahan anggota ke PartyModel
	var add_ok: bool = party.add_member(hero.hero_id)
	if not add_ok:
		# Rollback atomik
		if prev_party_id.is_empty():
			hero.clear_party_assignment()
		else:
			hero.set_party_id(prev_party_id)
		if not hero.transition_lifecycle_state(prev_lifecycle):
			hero.lifecycle_state = prev_lifecycle
		party.remove_member(hero.hero_id)
		return false

	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Memvalidasi kelayakan pelepasan pahlawan dari regu
func can_remove_hero_from_party(hero_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false

	var hero := get_hero(hero_id)
	if hero == null:
		return false

	if not hero.is_in_party() or hero.party_id.is_empty():
		return false

	var party := get_party(hero.party_id)
	if party == null or not party.has_member(hero.hero_id):
		return false

	return true


## Mengeluarkan pahlawan dari regu secara atomik (kembali ke RESERVE / ROSTER_ACTIVE)
func remove_hero_from_party(hero_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("remove_hero_from_party dilarang pada fase BATTLE (Battle Lock)")
		return false

	if not can_remove_hero_from_party(hero_id):
		return false

	var hero := get_hero(hero_id)
	var party := get_party(hero.party_id)

	party.remove_member(hero.hero_id)
	hero.clear_party_assignment()
	hero.transition_lifecycle_state(HeroLifecycleState.ROSTER_ACTIVE)

	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Memvalidasi kelayakan penunjukan pemimpin regu
func can_set_party_leader(hero_id: String, party_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false

	var party := get_party(party_id)
	if party == null:
		return false

	# Mengosongkan pemimpin selalu diizinkan jika bukan saat battle
	if hero_id.strip_edges().is_empty():
		return true

	var hero := get_hero(hero_id)
	if hero == null or not hero.is_alive or hero.lifecycle_state == HeroLifecycleState.PERMADEATH:
		return false

	if not party.has_member(hero.hero_id):
		return false

	return true


## Menunjuk pahlawan sebagai pemimpin regu
func set_party_leader(hero_id: String, party_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("set_party_leader dilarang pada fase BATTLE (Battle Lock)")
		return false

	if not can_set_party_leader(hero_id, party_id):
		return false

	var party := get_party(party_id)
	var ok: bool = party.set_leader(hero_id)
	if ok:
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
	_battle_tick = 0
	_time_accumulator = 0.0
	_battle_paused = false
	_current_state.battle_phase_name = "RANGED_VOLLEY"

	# Transisi status pahlawan aktif di Party 1 ke BATTLE_ACTIVE
	var active_party := get_active_battle_party()
	if active_party != null:
		for m_id in active_party.member_hero_ids:
			var h := get_hero(str(m_id))
			if h != null and h.is_alive and h.lifecycle_state == HeroLifecycleState.IN_PARTY:
				h.transition_lifecycle_state(HeroLifecycleState.BATTLE_ACTIVE)

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

	var battle_heroes: Array = get_active_battle_heroes()
	var result: Dictionary = _simulation_runner.run_battle(
		battle_population,
		battle_heroes,
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
func set_battle_speed(speed: float) -> bool:
	if not CombatEngine.is_valid_speed(speed):
		return false
	_battle_speed = speed
	_current_state.battle_speed = _battle_speed
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Menjeda atau melanjutkan pertempuran
func set_battle_paused(paused: bool) -> void:
	_battle_paused = paused
	_current_state.battle_paused = _battle_paused
	_update_snapshot()
	state_changed.emit(_current_state.clone())


## Menjeda pertempuran (Phase 6B)
func pause_battle() -> bool:
	_battle_paused = true
	_current_state.battle_paused = true
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Melanjutkan pertempuran (Phase 6B)
func resume_battle() -> bool:
	_battle_paused = false
	_current_state.battle_paused = false
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


func get_battle_tick() -> int:
	return _battle_tick


func is_battle_paused() -> bool:
	return _battle_paused


func get_battle_speed() -> float:
	return _battle_speed


func can_step_simulation() -> bool:
	if _state_machine.current_state != GameplayStateMachine.STATE_BATTLE:
		return false
	if _battle_paused:
		return false
	return true


## Menjalankan 1 tick simulasi taktis deterministik (Phase 6B).
func step_simulation() -> bool:
	if not can_step_simulation():
		return false
	_battle_tick += 1
	_current_state.battle_tick = _battle_tick
	if _combat_engine != null:
		_combat_engine.step_simulation_tick(_battle_tick - 1)
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Akumulator waktu deterministik berbasis delta waktu nyata (Phase 6B).
## Menjalankan N langkah simulasi secara proporsional terhadap battle_speed tanpa ketergantungan FPS.
func advance_simulation_time(delta_seconds: float) -> int:
	if not can_step_simulation():
		return 0
	if delta_seconds <= 0.0:
		return 0
	_time_accumulator += delta_seconds * _battle_speed
	var steps_taken: int = 0
	while _time_accumulator >= BASE_TICK_DURATION:
		if not can_step_simulation():
			break
		step_simulation()
		_time_accumulator -= BASE_TICK_DURATION
		steps_taken += 1
	return steps_taken


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

		# 3b. Pasca-tempur pahlawan: transisi survivor kembali ke IN_PARTY dan permadeath cleanup
		for h in _heroes:
			if h is HeroModel:
				var hero_obj: HeroModel = h as HeroModel
				if hero_obj.is_alive and hero_obj.lifecycle_state == HeroLifecycleState.BATTLE_ACTIVE:
					hero_obj.transition_lifecycle_state(HeroLifecycleState.IN_PARTY)
				elif not hero_obj.is_alive:
					# Permadeath cleanup:
					# 1. Kembalikan seluruh perlengkapan ke gudang bersama tepat 1x
					var dead_hero_items: Array = hero_obj.clear_equipment()
					for item in dead_hero_items:
						if item is EquipmentModel:
							_return_equipment_to_warehouse(item as EquipmentModel)
					# 2. Hapus keanggotaan regu dan kosongkan leader jika almarhum adalah leader
					for p in _parties:
						if p is PartyModel:
							(p as PartyModel).remove_member(hero_obj.hero_id)
					hero_obj.clear_party_assignment()
					hero_obj.lifecycle_state = HeroLifecycleState.PERMADEATH
					# 3. Hapus catatan kemitraan (chemistry) referensi almarhum dari semua hero hidup
					for other in _heroes:
						if other is HeroModel and (other as HeroModel).hero_id != hero_obj.hero_id:
							(other as HeroModel).chemistry_map.erase(hero_obj.hero_id)
					hero_obj.chemistry_map.clear()
					
		# 4. Pertumbuhan alami populasi via existing PopulationModel.grow_population()
		_population.grow_population(0.08)
		
		# 5. Pasca-tempur Phase 3B: Kembalikan perlengkapan aktif & proses korban jiwa
		var casualties: Dictionary = _last_battle_result.get("casualties", {})
		if not casualties.is_empty():
			_population.apply_casualties(casualties)

		if not _active_deployments.is_empty():
			var remaining_deaths: Dictionary = casualties.duplicate(true)
			var battle_seed: int = _session_seed + _current_wave_num
			
			for comp in _active_deployments:
				if comp is DeploymentComposition:
					var c: DeploymentComposition = comp as DeploymentComposition
					var role_deaths: int = int(remaining_deaths.get(c.resolved_role, 0))
					var group_deaths: int = mini(c.count, role_deaths)
					var group_survivors: int = c.count - group_deaths
					remaining_deaths[c.resolved_role] = role_deaths - group_deaths
					
					var carried_slots: Array[String] = [c.primary_weapon]
					if c.secondary_weapon != "NONE":
						carried_slots.append(c.secondary_weapon)
					if c.armor != "NONE":
						carried_slots.append(c.armor)
						
					# 1. Prajurit Selamat: Durability = 100% (usable), kembali ke gudang tanpa aus
					if group_survivors > 0:
						for slot_type in carried_slots:
							_return_equipment_to_warehouse(EquipmentModel.new(slot_type, 1, 100, group_survivors))
							
					# 2. Prajurit Gugur (Casualty Equipment Resolution):
					# 35% DESTROYED (hilang permanen) | 65% DAMAGED (kembali ke gudang dengan durabilitas 60, non-usable)
					if group_deaths > 0:
						for i in range(group_deaths):
							for slot_type in carried_slots:
								var roll: float = _combat_engine._seeded_float(battle_seed, slot_type, i * 17)
								if roll < 0.35:
									# Destroyed permanen (tidak dikembalikan ke gudang)
									pass
								else:
									# Damaged: durabilitas 60 (aus 40), non-usable sampai diperbaiki di Pandai Besi
									_return_equipment_to_warehouse(EquipmentModel.new(slot_type, 1, 60, 1))

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


# ==============================================================================
# PHASE 5: FORTRESS, POPULATION, WORKER, BUILDING, REPAIR & CONSTRUCTION
# ==============================================================================

## Konversi warga sipil menjadi tenaga kerja (Zero-Sum)
func convert_civilian_to_worker(count: int = 1) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("convert_civilian_to_worker dilarang pada fase BATTLE (Battle Lock)")
		return false
	if count < 1 or _population == null or _population.civilians < count:
		return false
	var ok: bool = _population.civilian_to_worker(count)
	if ok:
		if _worker_model != null:
			_worker_model.sync_total_workers(_population.workers)
		_update_snapshot()
		state_changed.emit(_current_state.clone())
	return ok


## Konversi tenaga kerja kembali menjadi warga sipil (Zero-Sum)
func convert_worker_to_civilian(count: int = 1) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("convert_worker_to_civilian dilarang pada fase BATTLE (Battle Lock)")
		return false
	if count < 1 or _population == null or _population.workers < count:
		return false
	var ok: bool = _population.worker_to_civilian(count)
	if ok:
		if _worker_model != null:
			_worker_model.sync_total_workers(_population.workers)
			if _economy != null:
				_economy.set_worker_allocation(_worker_model.repair_workers, _worker_model.blacksmith_workers, _worker_model.construction_workers, _population.workers)
		_update_snapshot()
		state_changed.emit(_current_state.clone())
	return ok


## Dapatkan instance WorkerModel
func get_worker_model() -> WorkerModel:
	return _worker_model


## Dapatkan rincian alokasi tenaga kerja
func get_worker_allocations() -> Dictionary:
	return _worker_model.to_dictionary() if _worker_model != null else {}


## Mutasi perpindahan tugas tenaga kerja
func reassign_worker(from_job: String, to_job: String, count: int = 1) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("reassign_worker dilarang pada fase BATTLE (Battle Lock)")
		return false
	if _worker_model == null:
		return false
	var ok: bool = _worker_model.reassign(from_job, to_job, count)
	if ok:
		if _economy != null:
			var total_pool: int = _population.workers if (_population != null and _population.workers > 0) else (_population.civilians if _population != null else 0)
			_economy.set_worker_allocation(_worker_model.repair_workers, _worker_model.blacksmith_workers, _worker_model.construction_workers, total_pool)
		_update_snapshot()
		state_changed.emit(_current_state.clone())
	return ok


## Dapatkan moral tenaga kerja
func get_worker_morale() -> int:
	return _worker_model.morale if _worker_model != null else 100


## Dapatkan produktivitas tenaga kerja
func get_worker_productivity() -> float:
	return _worker_model.get_productivity() if _worker_model != null else 1.0


## Ubah moral tenaga kerja
func modify_worker_morale(delta: int) -> void:
	if _worker_model != null:
		_worker_model.modify_morale(delta)
		_update_snapshot()
		state_changed.emit(_current_state.clone())


## Dapatkan fasilitas gedung berdasarkan ID
func get_building(building_id: String) -> BuildingModel:
	return _buildings.get(building_id, null)


## Dapatkan seluruh fasilitas gedung
func get_buildings() -> Array:
	return _buildings.values()


## Cek kelayakan peningkatan fasilitas
func can_upgrade_building(building_id: String) -> bool:
	var b: BuildingModel = get_building(building_id)
	return b != null and b.can_upgrade()


## Tingkatkan fasilitas gedung secara langsung
func upgrade_building(building_id: String) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("upgrade_building dilarang pada fase BATTLE (Battle Lock)")
		return false
	var b: BuildingModel = get_building(building_id)
	if b == null or not b.can_upgrade():
		return false
	var ok: bool = b.upgrade()
	if ok:
		_update_snapshot()
		state_changed.emit(_current_state.clone())
	return ok


## Validasi kelayakan perbaikan struktur fisik benteng (Fortress, Wall, Gate)
func can_repair_structure(target: String, hp_amount: int) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false
	if hp_amount <= 0 or _fortress == null or _economy == null:
		return false
	var t: String = target.to_upper().strip_edges()
	if not (t in ["FORTRESS", "WALL", "GATE"]):
		return false
	var rep_workers: int = _worker_model.repair_workers if _worker_model != null else _economy.repair_workers
	if rep_workers <= 0:
		return false
	var needed: int = 0
	match t:
		"FORTRESS":
			needed = _fortress.max_hp - _fortress.current_hp
		"WALL":
			needed = _fortress.wall_max_hp - _fortress.wall_hp
		"GATE":
			needed = _fortress.gate_max_hp - _fortress.gate_hp
	if needed <= 0:
		return false
	var actual_repair: int = mini(needed, hp_amount)
	var cost: int = int(ceil(float(actual_repair) * 0.15))
	if _economy.treasury_gold < cost:
		return false
	return true


## Eksekusi perbaikan struktur fisik benteng (Fortress, Wall, Gate) secara atomik
func repair_structure(target: String, hp_amount: int) -> bool:
	if not can_repair_structure(target, hp_amount):
		return false
	var t: String = target.to_upper().strip_edges()
	var needed: int = 0
	match t:
		"FORTRESS":
			needed = _fortress.max_hp - _fortress.current_hp
		"WALL":
			needed = _fortress.wall_max_hp - _fortress.wall_hp
		"GATE":
			needed = _fortress.gate_max_hp - _fortress.gate_hp
	var actual_repair: int = mini(needed, hp_amount)
	var cost: int = int(ceil(float(actual_repair) * 0.15))
	
	_economy.treasury_gold -= cost
	var repaired: int = 0
	match t:
		"FORTRESS":
			repaired = _fortress.repair(actual_repair)
		"WALL":
			repaired = _fortress.repair_wall(actual_repair)
		"GATE":
			repaired = _fortress.repair_gate(actual_repair)
	if repaired <= 0:
		_economy.treasury_gold += cost
		return false
	
	_active_repair = {
		"target": t,
		"repaired_hp": repaired,
		"cost": cost
	}
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Cek kelayakan memulai proyek konstruksi
func can_start_construction(target_building_id: String, gold_cost: int, target_progress: int) -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		return false
	if gold_cost < 0 or target_progress <= 0:
		return false
	var b: BuildingModel = get_building(target_building_id)
	if b == null or not b.can_upgrade():
		return false
	var constr_workers: int = _worker_model.construction_workers if _worker_model != null else _economy.construction_workers
	if constr_workers <= 0:
		return false
	if _economy == null or _economy.treasury_gold < gold_cost:
		return false
	return true


## Memulai proyek konstruksi bangunan
func start_construction(target_building_id: String, gold_cost: int = 50, target_progress: int = 100) -> bool:
	if not can_start_construction(target_building_id, gold_cost, target_progress):
		return false
	_economy.treasury_gold -= gold_cost
	_active_construction = {
		"target_building_id": target_building_id,
		"gold_cost": gold_cost,
		"current_progress": 0,
		"target_progress": target_progress,
		"is_completed": false
	}
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Menambah progres proyek konstruksi aktif secara deterministik
func advance_construction(progress_delta: int) -> bool:
	if _active_construction.is_empty() or bool(_active_construction.get("is_completed", false)):
		return false
	if progress_delta <= 0:
		return false
	var curr: int = int(_active_construction.get("current_progress", 0)) + progress_delta
	var target: int = int(_active_construction.get("target_progress", 100))
	_active_construction["current_progress"] = mini(curr, target)
	if curr >= target:
		_active_construction["is_completed"] = true
		var bid: String = str(_active_construction.get("target_building_id", ""))
		var b: BuildingModel = get_building(bid)
		if b != null and b.can_upgrade():
			b.upgrade()
	_update_snapshot()
	state_changed.emit(_current_state.clone())
	return true


## Membatalkan proyek konstruksi aktif dan melakukan refund kas emas
func cancel_construction() -> bool:
	if _state_machine.current_state == GameplayStateMachine.STATE_BATTLE:
		push_warning("cancel_construction dilarang pada fase BATTLE (Battle Lock)")
		return false
	if _active_construction.is_empty():
		return false
	if not bool(_active_construction.get("is_completed", false)):
		var refund: int = int(_active_construction.get("gold_cost", 0))
		_economy.treasury_gold += refund
	_active_construction.clear()
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
	_hero_id_counter = 1
	_population = PopulationModel.new(18, 30, 100)
	_fortress = FortressModel.new(1000, 40)
	_economy = EconomyManager.new(150)
	_wave_gen = WaveGenerator.new()
	_combat_engine = CombatEngine.new()

	_heroes = []
	var h1 := HeroModel.new("hero_alder", "Alder Ironclad", 1, 4, HeroRole.KNIGHT, HeroLifecycleState.ROSTER_ACTIVE)
	var h2 := HeroModel.new("hero_lyra", "Lyra Windwalker", 2, 4, HeroRole.ARCHER, HeroLifecycleState.ROSTER_ACTIVE)
	_heroes.append(h1)
	_heroes.append(h2)

	_parties = []
	var p1 := PartyModel.new(PartyModel.PARTY_1_ID, "Party 1", true)
	var p2 := PartyModel.new(PartyModel.PARTY_2_ID, "Party 2", false)
	_parties.append(p1)
	_parties.append(p2)

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

	_buildings = {
		"fortress_main": BuildingModel.new("fortress_main", BuildingModel.TYPE_FORTRESS, "Benteng Utama", 1, true, 5),
		"wall_outer": BuildingModel.new("wall_outer", BuildingModel.TYPE_WALL, "Tembok Pertahanan", 1, true, 5),
		"gate_main": BuildingModel.new("gate_main", BuildingModel.TYPE_GATE, "Gerbang Utama", 1, true, 5),
		"barracks": BuildingModel.new("barracks", BuildingModel.TYPE_BARRACKS, "Barak Militer", 1, true, 5),
		"blacksmith": BuildingModel.new("blacksmith", BuildingModel.TYPE_BLACKSMITH, "Pandai Besi", 1, true, 5),
		"warehouse": BuildingModel.new("warehouse", BuildingModel.TYPE_WAREHOUSE, "Gudang Senjata", 1, true, 5),
		"training_facility": BuildingModel.new("training_facility", BuildingModel.TYPE_TRAINING_FACILITY, "Fasilitas Latihan", 1, true, 5),
		"mercenary_guild": BuildingModel.new("mercenary_guild", BuildingModel.TYPE_MERCENARY_GUILD, "Mercenary Guild", 1, true, 5),
		"construction_area": BuildingModel.new("construction_area", BuildingModel.TYPE_CONSTRUCTION_AREA, "Area Pembangunan", 1, true, 5),
	}
	_worker_model = WorkerModel.new(_population.workers, 100)
	_active_repair = {}
	_active_construction = {}

	_update_snapshot()


func _update_snapshot() -> void:
	_current_state.game_phase = _state_machine.current_state
	_current_state.state_name = _state_machine.current_state
	_current_state.current_wave = _current_wave_num
	_current_state.battle_speed = _battle_speed
	_current_state.battle_paused = _battle_paused
	_current_state.battle_tick = _battle_tick

	if _fortress != null:
		_current_state.fortress_data = {
			"current_hp": _fortress.current_hp,
			"max_hp": _fortress.max_hp,
			"armor": _fortress.armor,
			"upgrade_tier": _fortress.upgrade_tier,
			"is_destroyed": _fortress.is_destroyed(),
			"wall_hp": _fortress.wall_hp,
			"wall_max_hp": _fortress.wall_max_hp,
			"gate_hp": _fortress.gate_hp,
			"gate_max_hp": _fortress.gate_max_hp,
			"is_wall_breached": _fortress.is_wall_breached(),
			"is_gate_breached": _fortress.is_gate_breached()
		}

	if _population != null:
		_current_state.population_data = {
			"civilians": _population.civilians,
			"workers": _population.workers,
			"housing_capacity": _population.housing_capacity,
			"morale": _population.morale,
			"mercenaries": _population.mercenaries,
			"soldiers": _population.soldiers.duplicate(true),
			"total_soldiers": _population.get_total_soldiers(),
			"total_population": _population.get_total_population(),
			"civilian_count": _population.get_civilian_count(),
			"worker_count": _population.get_worker_count(),
			"soldier_count": _population.get_soldier_count()
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
				"role": hero.role,
				"lifecycle_state": hero.lifecycle_state,
				"level": hero.level,
				"current_exp": hero.current_exp,
				"required_exp": hero.get_required_exp(hero.level),
				"current_star": hero.current_star,
				"potential_star": hero.potential_star,
				"base_hp": hero.base_hp,
				"base_atk": hero.base_atk,
				"base_def": hero.base_def,
				"level_cap": hero.get_level_cap(),
				"can_ascend": hero.can_ascend(),
				"ascension_cost": hero.get_ascension_cost(),
				"fatigue": hero.fatigue,
				"morale": hero.morale,
				"trained_this_wave": has_hero_trained_this_wave(hero.hero_id),
				"is_alive": hero.is_alive,
				"chemistry_map": hero.chemistry_map.duplicate(true),
				"effective_atk": hero.get_effective_atk(),
				"effective_def": hero.get_effective_def(),
				"party_id": hero.party_id,
				"unlocked_skills": hero.get_unlocked_skills(),
				"talent_points": hero.talent_points,
				"allocated_talents": hero.allocated_talents.duplicate(true),
				"talent_atk_multiplier": hero.get_talent_atk_multiplier(),
				"talent_def_multiplier": hero.get_talent_def_multiplier(),
				"primary_equipment": hero.primary_equipment.role_type if hero.primary_equipment != null else "NONE",
				"secondary_equipment": hero.secondary_equipment.role_type if hero.secondary_equipment != null else "NONE",
				"armor_equipment": hero.armor_equipment.role_type if hero.armor_equipment != null else "NONE"
			})

	_current_state.parties_data = []
	for p in _parties:
		if p is PartyModel:
			_current_state.parties_data.append((p as PartyModel).to_dictionary())

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
				"is_broken": eq.is_broken(),
				"is_usable": eq.is_usable(),
				"is_damaged": eq.is_damaged()
			})

	_current_state.active_deployments_data = []
	for comp in _active_deployments:
		if comp is DeploymentComposition:
			_current_state.active_deployments_data.append((comp as DeploymentComposition).to_dictionary())
	_current_state.available_soldiers_count = _available_soldiers
	_current_state.total_living_soldiers_count = _population.get_total_soldiers() if _population != null else 0
	_current_state.deployed_soldiers_count = get_total_deployed_soldiers()

	_current_state.current_wave_data = _current_wave_data.duplicate(true)
	_current_state.last_battle_result = _last_battle_result.duplicate(true)
	_current_state.last_commander_command = _last_command.to_dictionary() if _last_command != null else {}

	_current_state.worker_data = _worker_model.to_dictionary() if _worker_model != null else {}

	_current_state.buildings_data = []
	for b in _buildings.values():
		if b is BuildingModel:
			_current_state.buildings_data.append((b as BuildingModel).to_dictionary())

	_current_state.active_repair_data = _active_repair.duplicate(true)
	_current_state.active_construction_data = _active_construction.duplicate(true)
