class_name EconomyManager
extends RefCounted

## EconomyManager
## Mengelola alokasi pekerjaan warga sipil, pemeliharaan (upkeep), reparasi, dan kas bendahara.
## Sesuai keputusan resmi: TIDAK ADA PRODUCTION WORKER dan TIDAK ADA PASSIVE INCOME.
## Pekerjaan valid: BLACKSMITH, REPAIR, CONSTRUCTION, IDLE.
## Sumber pendapatan utama adalah Battle Loot dari kemenangan pertempuran.

const EquipmentModelScript = preload("res://scripts/domain/model/equipment_model.gd")
const PopulationModelScript = preload("res://scripts/domain/model/population_model.gd")
const FortressModelScript = preload("res://scripts/domain/model/fortress_model.gd")
const ResourceLedger = preload("res://scripts/domain/model/resource_ledger.gd")

var ledger: ResourceLedger = null

var treasury_gold: int:
	get:
		return ledger.get_gold() if ledger != null else 0
	set(value):
		if ledger != null:
			ledger.set_resource(ResourceLedger.RESOURCE_GOLD, maxi(0, value))

var blacksmith_workers: int = 0
var repair_workers: int = 0
var construction_workers: int = 0
var idle_workers: int = 0

# Parameter penyeimbang (Balance Parameters)
var worker_salary: int = 3
var repair_hp_per_worker: int = 25
var repair_cost_per_hp: float = 0.15

var soldier_salaries: Dictionary = {
	"SWORDSMAN": 5,
	"SHIELD_INFANTRY": 6,
	"SPEARMAN": 5,
	"ARCHER": 6,
	"HEAVY_INFANTRY": 10
}
var mercenary_salary: int = 18


func _init(p_initial_gold: int = 150, p_ledger: ResourceLedger = null) -> void:
	if p_ledger != null:
		ledger = p_ledger
	else:
		ledger = ResourceLedger.new(p_initial_gold)


func get_ledger() -> ResourceLedger:
	return ledger


func set_worker_allocation(rep: int, smith: int, constr: int, total_civilians: int) -> bool:
	var total_assigned: int = rep + smith + constr
	if total_assigned > total_civilians:
		return false # Alokasi melebihi jumlah warga sipil yang tersedia
		
	repair_workers = maxi(0, rep)
	blacksmith_workers = maxi(0, smith)
	construction_workers = maxi(0, constr)
	idle_workers = total_civilians - total_assigned
	return true


func auto_allocate_balanced(total_civilians: int, fortress_needs_repair: bool) -> void:
	if total_civilians <= 0:
		repair_workers = 0
		blacksmith_workers = 0
		construction_workers = 0
		idle_workers = 0
		return
		
	var rep: int = 0
	if fortress_needs_repair and total_civilians >= 3:
		rep = mini(4, int(ceil(float(total_civilians) * 0.30)))
		
	var remaining: int = total_civilians - rep
	var smith: int = mini(3, int(ceil(float(remaining) * 0.25)))
	var constr: int = mini(2, int(ceil(float(remaining) * 0.15)))
	
	set_worker_allocation(rep, smith, constr, total_civilians)


func get_blacksmith_discount() -> float:
	# Pandai besi mengurangi biaya reparasi equipment hingga 60%
	return clampf(float(blacksmith_workers) * 0.12, 0.0, 0.60)


func process_cycle(population: PopulationModel, fortress: FortressModel) -> Dictionary:
	assert(population != null, "population tidak boleh null")
	assert(fortress != null, "fortress tidak boleh null")
	
	# 1. Tidak ada passive income atau production worker income!
	var gross_income: int = 0
	
	# 2. Pengeluaran Gaji Warga
	var civ_upkeep: int = population.civilians * worker_salary
	
	# 3. Gaji Militer
	var sol_upkeep: int = 0
	for role in population.soldiers:
		var count: int = int(population.soldiers[role])
		var sal: int = int(soldier_salaries.get(role, 5))
		sol_upkeep += count * sal
	var merc_upkeep: int = population.mercenaries * mercenary_salary
	var total_military_upkeep: int = sol_upkeep + merc_upkeep
	
	# 4. Eksekusi Reparasi Benteng oleh Repair Worker
	var hp_repaired: int = 0
	var repair_material_cost: int = 0
	if repair_workers > 0 and fortress.current_hp < fortress.max_hp:
		var potential_hp: int = repair_workers * repair_hp_per_worker
		var max_possible_repair: int = mini(fortress.max_hp - fortress.current_hp, potential_hp)
		var est_cost: int = int(ceil(float(max_possible_repair) * repair_cost_per_hp))
		
		# Validasi kemampuan kas bendahara
		var available_budget: int = maxi(0, treasury_gold - civ_upkeep - total_military_upkeep)
		if est_cost > available_budget:
			# Reparasi parsial sesuai dana kas
			var affordable_hp: int = int(floor(float(available_budget) / repair_cost_per_hp))
			max_possible_repair = mini(max_possible_repair, affordable_hp)
			est_cost = int(ceil(float(max_possible_repair) * repair_cost_per_hp))
			
		if max_possible_repair > 0:
			hp_repaired = fortress.repair(max_possible_repair)
			repair_material_cost = est_cost
			
	# 5. Neraca Kas Akhir Siklus (Upkeep & Reparasi dikurangi dari Treasury)
	var total_expense: int = civ_upkeep + total_military_upkeep + repair_material_cost
	treasury_gold = maxi(0, treasury_gold - total_expense)
	
	return {
		"gross_income": gross_income,
		"civilian_upkeep": civ_upkeep,
		"military_upkeep": total_military_upkeep,
		"repair_cost": repair_material_cost,
		"hp_repaired": hp_repaired,
		"total_expense": total_expense,
		"treasury_after": treasury_gold
	}
