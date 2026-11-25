class_name EconomyManager
extends RefCounted

## EconomyManager
## Mengelola alokasi pekerjaan warga sipil, pemeliharaan (upkeep), reparasi, dan kas bendahara.
## Menolak pendapatan pasif gaib; pendapatan harus berasal dari alokasi pekerjaan produksi nyata.

const EquipmentModelScript = preload("res://scripts/domain/model/equipment_model.gd")
const PopulationModelScript = preload("res://scripts/domain/model/population_model.gd")
const FortressModelScript = preload("res://scripts/domain/model/fortress_model.gd")

var treasury_gold: int = 150
var blacksmith_workers: int = 0
var repair_workers: int = 0
var construction_workers: int = 0
var production_workers: int = 0
var idle_workers: int = 0

# Parameter penyeimbang (Balance Parameters)
var worker_base_output: int = 12
var worker_salary: int = 4
var repair_hp_per_worker: int = 25
var repair_cost_per_hp: float = 0.15
var base_passive_income: int = 10

var soldier_salaries: Dictionary = {
	"SWORDSMAN": 6,
	"SHIELD_INFANTRY": 7,
	"SPEARMAN": 6,
	"ARCHER": 7,
	"HEAVY_INFANTRY": 11
}
var mercenary_salary: int = 18


func _init(p_initial_gold: int = 150) -> void:
	treasury_gold = maxi(0, p_initial_gold)


func set_worker_allocation(prod: int, rep: int, smith: int, constr: int, total_civilians: int) -> bool:
	var total_assigned: int = prod + rep + smith + constr
	if total_assigned > total_civilians:
		return false # Alokasi melebihi jumlah warga sipil yang tersedia
		
	production_workers = maxi(0, prod)
	repair_workers = maxi(0, rep)
	blacksmith_workers = maxi(0, smith)
	construction_workers = maxi(0, constr)
	idle_workers = total_civilians - total_assigned
	return true


func auto_allocate_balanced(total_civilians: int, fortress_needs_repair: bool) -> void:
	if total_civilians <= 0:
		production_workers = 0
		repair_workers = 0
		blacksmith_workers = 0
		construction_workers = 0
		idle_workers = 0
		return
		
	var rep: int = 0
	if fortress_needs_repair and total_civilians >= 3:
		rep = mini(4, int(ceil(float(total_civilians) * 0.25)))
		
	var remaining: int = total_civilians - rep
	var smith: int = mini(2, int(ceil(float(remaining) * 0.15)))
	remaining -= smith
	var prod: int = remaining
	
	set_worker_allocation(prod, rep, smith, 0, total_civilians)


func process_cycle(population: PopulationModel, fortress: FortressModel) -> Dictionary:
	assert(population != null, "population tidak boleh null")
	assert(fortress != null, "fortress tidak boleh null")
	
	# 1. Hitung Pendapatan
	var morale_factor: float = float(population.morale) / 100.0
	var gross_production: int = int(floor(float(production_workers * worker_base_output) * morale_factor))
	var gross_income: int = gross_production + base_passive_income
	
	# 2. Hitung Pengeluaran Gaji Warga
	var civ_upkeep: int = population.civilians * worker_salary
	
	# 3. Hitung Gaji Militer
	var sol_upkeep: int = 0
	for role in population.soldiers:
		var count: int = int(population.soldiers[role])
		var sal: int = int(soldier_salaries.get(role, 6))
		sol_upkeep += count * sal
	var merc_upkeep: int = population.mercenaries * mercenary_salary
	var total_military_upkeep: int = sol_upkeep + merc_upkeep
	
	# 4. Eksekusi Reparasi Benteng oleh Worker
	var hp_repaired: int = 0
	var repair_material_cost: int = 0
	if repair_workers > 0 and fortress.current_hp < fortress.max_hp:
		var potential_hp: int = repair_workers * repair_hp_per_worker
		var max_possible_repair: int = mini(fortress.max_hp - fortress.current_hp, potential_hp)
		var est_cost: int = int(ceil(float(max_possible_repair) * repair_cost_per_hp))
		
		# Validasi kemampuan kas bendahara
		var available_budget: int = maxi(0, treasury_gold + gross_income - civ_upkeep - total_military_upkeep)
		if est_cost > available_budget:
			# Reparasi parsial sesuai dana
			var affordable_hp: int = int(floor(float(available_budget) / repair_cost_per_hp))
			max_possible_repair = mini(max_possible_repair, affordable_hp)
			est_cost = int(ceil(float(max_possible_repair) * repair_cost_per_hp))
			
		if max_possible_repair > 0:
			hp_repaired = fortress.repair(max_possible_repair)
			repair_material_cost = est_cost
			
	# 5. Neraca Kas Akhir
	var total_expense: int = civ_upkeep + total_military_upkeep + repair_material_cost
	var net_gold: int = gross_income - total_expense
	treasury_gold = maxi(0, treasury_gold + net_gold)
	
	return {
		"gross_income": gross_income,
		"civilian_upkeep": civ_upkeep,
		"military_upkeep": total_military_upkeep,
		"repair_cost": repair_material_cost,
		"hp_repaired": hp_repaired,
		"net_gold": net_gold,
		"treasury_after": treasury_gold
	}
