class_name HeadlessSimulator
extends RefCounted

## HeadlessSimulator
## Simulator sistem deterministik untuk menjalankan simulasi 100-wave dan skenario stres.
## Memvalidasi kurva ekonomi, manpower, ketahanan benteng, kuantitas equipment, dan kelangsungan hidup hero.

const PopulationModelScript = preload("res://scripts/domain/model/population_model.gd")
const FortressModelScript = preload("res://scripts/domain/model/fortress_model.gd")
const HeroModelScript = preload("res://scripts/domain/model/hero_model.gd")
const EquipmentModelScript = preload("res://scripts/domain/model/equipment_model.gd")
const EconomyManagerScript = preload("res://scripts/simulation/economy_manager.gd")
const WaveGeneratorScript = preload("res://scripts/simulation/wave_generator.gd")
const CombatEngineScript = preload("res://scripts/simulation/combat_engine.gd")

var population: PopulationModel
var fortress: FortressModel
var economy: EconomyManager
var wave_gen: WaveGenerator
var combat: CombatEngine
var heroes: Array = [] # Array[HeroModel]
var warehouse: Array = [] # Array[EquipmentModel]


func _init(seed_val: int = 12345) -> void:
	population = PopulationModel.new(18, 30, 100)
	fortress = FortressModel.new(1000, 40)
	economy = EconomyManager.new(150)
	wave_gen = WaveGenerator.new()
	combat = CombatEngine.new()
	heroes = []
	warehouse = []
	_setup_default_entities()


func _setup_default_entities() -> void:
	# Buat 2 hero starter
	var h1 := HeroModel.new("hero_alder", "Alder Ironclad", 1, 4)
	var h2 := HeroModel.new("hero_lyra", "Lyra Windwalker", 2, 4)
	heroes.append(h1)
	heroes.append(h2)
	
	# Buat perlengkapan dasar gudang senjata dengan kuantitas awal
	warehouse.append(EquipmentModel.new("SWORD", 1, 100, 10))
	warehouse.append(EquipmentModel.new("SHIELD", 1, 100, 10))
	warehouse.append(EquipmentModel.new("SPEAR", 1, 100, 10))
	warehouse.append(EquipmentModel.new("BOW", 1, 100, 10))
	warehouse.append(EquipmentModel.new("HEAVY_ARMOR", 1, 100, 10))
	
	# Rekrut pasukan starter: 2 Swordsman, 2 Shield, 2 Archer
	population.recruit_soldier("SWORDSMAN", 2)
	population.recruit_soldier("SHIELD_INFANTRY", 2)
	population.recruit_soldier("ARCHER", 2)


func run_simulation_to_wave(target_wave: int = 100, seed_val: int = 12345) -> Dictionary:
	var wave_history: Array = []
	var game_over: bool = false
	var game_over_wave: int = -1
	
	for w in range(1, target_wave + 1):
		# 1. Alokasi pekerja cerdas (HANYA: Repair, Blacksmith, Construction, Idle - NO PRODUCTION!)
		var needs_repair: bool = fortress.current_hp < fortress.max_hp
		economy.auto_allocate_balanced(population.civilians, needs_repair)
		
		# 2. Proses siklus ekonomi (Upkeep & reparasi dibayar dari kas)
		var econ_result: Dictionary = economy.process_cycle(population, fortress)
		
		# 3. Regenerasi populasi alami
		var born: int = population.grow_population(0.08)
		
		# 4. Generate Gelombang Musuh
		var wave_data: Dictionary = wave_gen.generate_wave(w, seed_val)
		
		# 5. Pertempuran multi-fase deterministik
		var combat_result: Dictionary = combat.simulate_battle(population, heroes, warehouse, fortress, wave_data, seed_val + w)
		
		# 6. Tambah loot emas pertempuran ke kas
		economy.treasury_gold += int(combat_result.get("loot_gold", 0))
		
		# 7. Adaptasi Strategis Antar-Wave (Manajemen Benteng & Restock Equipment)
		_perform_between_wave_management(w)
		
		# Catat telemetri
		var telemetry: Dictionary = {
			"wave": w,
			"threat_budget": wave_data["threat_budget"],
			"victory": combat_result["victory"],
			"fortress_hp": fortress.current_hp,
			"fortress_max_hp": fortress.max_hp,
			"total_pop": population.get_total_population(),
			"civilians": population.civilians,
			"soldiers": population.get_total_soldiers(),
			"mercenaries": population.mercenaries,
			"treasury_gold": economy.treasury_gold,
			"casualties": combat_result["total_dead_soldiers"],
			"hero_avg_level": _get_avg_hero_level()
		}
		wave_history.append(telemetry)
		
		if bool(combat_result.get("game_over", false)) or fortress.is_destroyed():
			game_over = true
			game_over_wave = w
			break
			
	return {
		"completed_waves": wave_history.size(),
		"game_over": game_over,
		"game_over_wave": game_over_wave,
		"history": wave_history,
		"final_fortress_hp": fortress.current_hp,
		"final_gold": economy.treasury_gold,
		"final_pop": population.get_total_population()
	}


func _perform_between_wave_management(current_wave: int) -> void:
	# 1. Target militer proporsional terhadap wave & populasi
	var target_shield: int = maxi(2, 2 + int(floor(float(current_wave) * 0.18)))
	var target_archer: int = maxi(2, 2 + int(floor(float(current_wave) * 0.18)))
	var target_sword: int = maxi(2, 2 + int(floor(float(current_wave) * 0.15)))
	var target_spear: int = int(floor(float(current_wave) * 0.12))
	var target_heavy: int = int(floor(float(current_wave) * 0.10))
	
	var recruits_done: int = 0
	while population.civilians >= 6 and economy.treasury_gold >= 40 and recruits_done < 4:
		if population.soldiers["SHIELD_INFANTRY"] < target_shield:
			population.recruit_soldier("SHIELD_INFANTRY", 1)
			_ensure_equipment_quantity("SHIELD", population.soldiers["SHIELD_INFANTRY"])
			recruits_done += 1
		elif population.soldiers["ARCHER"] < target_archer:
			population.recruit_soldier("ARCHER", 1)
			_ensure_equipment_quantity("BOW", population.soldiers["ARCHER"])
			recruits_done += 1
		elif population.soldiers["SPEARMAN"] < target_spear:
			population.recruit_soldier("SPEARMAN", 1)
			_ensure_equipment_quantity("SPEAR", population.soldiers["SPEARMAN"])
			recruits_done += 1
		elif population.soldiers["HEAVY_INFANTRY"] < target_heavy and current_wave >= 15:
			population.recruit_soldier("HEAVY_INFANTRY", 1)
			_ensure_equipment_quantity("HEAVY_ARMOR", population.soldiers["HEAVY_INFANTRY"])
			recruits_done += 1
		elif population.soldiers["SWORDSMAN"] < target_sword:
			population.recruit_soldier("SWORDSMAN", 1)
			_ensure_equipment_quantity("SWORD", population.soldiers["SWORDSMAN"])
			recruits_done += 1
		else:
			break
			
	# 2. Upgrade Tier Perlengkapan di Warehouse sesuai progresi wave
	var target_tier: int = 1
	if current_wave >= 75: target_tier = 5
	elif current_wave >= 50: target_tier = 4
	elif current_wave >= 25: target_tier = 3
	elif current_wave >= 10: target_tier = 2
	
	for item in warehouse:
		if item is EquipmentModel:
			var eq: EquipmentModel = item as EquipmentModel
			if eq.tier < target_tier:
				var up_cost: int = 40 * eq.tier
				if economy.treasury_gold >= up_cost + 100:
					economy.treasury_gold -= up_cost
					eq.tier += 1
					eq.repair()
					
	# 3. Upgrade benteng & kapasitas hunian dengan biaya yang meningkat proporsional
	var upgrade_cost: int = 120 + fortress.upgrade_tier * 35
	if economy.treasury_gold >= upgrade_cost + 150:
		population.housing_capacity += 6
		fortress.upgrade_fortress(300, 10)
		economy.treasury_gold -= upgrade_cost
		
	# 4. Reparasi equipment yang aus dengan diskon pandai besi
	var smith_discount: float = economy.get_blacksmith_discount()
	for item in warehouse:
		if item is EquipmentModel:
			var eq: EquipmentModel = item as EquipmentModel
			if eq.durability < 50 and economy.treasury_gold >= 25:
				var cost: int = eq.calculate_repair_cost(smith_discount)
				if economy.treasury_gold >= cost + 40:
					economy.treasury_gold -= cost
					eq.repair()
					
	# 5. Istirahat hero jika fatigue tinggi (hanya hero yang masih hidup)
	var active_living_heroes: int = 0
	for h in heroes:
		if h is HeroModel and (h as HeroModel).is_alive:
			active_living_heroes += 1
			var hero_obj: HeroModel = h as HeroModel
			if hero_obj.fatigue >= 45:
				hero_obj.rest(35)
				
	# 6. Rekrut komandan pengganti jika seluruh hero gugur dalam pertempuran sengit
	if active_living_heroes == 0 and economy.treasury_gold >= 150:
		var new_h := HeroModel.new("hero_reinforce_" + str(current_wave), "Commander W" + str(current_wave), 1, 3)
		heroes.append(new_h)
		economy.treasury_gold -= 60


func _ensure_equipment_quantity(role: String, needed_quantity: int) -> void:
	var total_qty: int = 0
	var primary_item: EquipmentModel = null
	for item in warehouse:
		if item is EquipmentModel and (item as EquipmentModel).role_type == role:
			var eq: EquipmentModel = item as EquipmentModel
			total_qty += eq.quantity
			if primary_item == null:
				primary_item = eq
				
	if total_qty < needed_quantity:
		var deficit: int = needed_quantity - total_qty
		if primary_item != null:
			primary_item.quantity += deficit
		else:
			warehouse.append(EquipmentModel.new(role, 1, 100, deficit))


func _get_avg_hero_level() -> float:
	if heroes.is_empty():
		return 0.0
	var sum_lvl: int = 0
	var count: int = 0
	for h in heroes:
		if h is HeroModel and (h as HeroModel).is_alive:
			sum_lvl += (h as HeroModel).level
			count += 1
	if count == 0:
		return 0.0
	return float(sum_lvl) / float(count)
