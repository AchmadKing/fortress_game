class_name PopulationModel
extends RefCounted

## PopulationModel
## Model demografi dan alokasi populasi (domain layer).
## Memastikan konversi sipil -> militer dan kematian permanen tanpa exploit infinite manpower.

var civilians: int = 15
var housing_capacity: int = 30
var morale: int = 100 # 0 - 150
var mercenaries: int = 0

# Jumlah serdadu berdasarkan peran perlengkapan
var soldiers: Dictionary = {
	"SWORDSMAN": 0,
	"SHIELD_INFANTRY": 0,
	"SPEARMAN": 0,
	"ARCHER": 0,
	"HEAVY_INFANTRY": 0
}


func _init(p_civilians: int = 15, p_capacity: int = 30, p_morale: int = 100) -> void:
	civilians = maxi(0, p_civilians)
	housing_capacity = maxi(10, p_capacity)
	morale = clampi(p_morale, 0, 150)
	soldiers = {
		"SWORDSMAN": 0,
		"SHIELD_INFANTRY": 0,
		"SPEARMAN": 0,
		"ARCHER": 0,
		"HEAVY_INFANTRY": 0
	}
	mercenaries = 0


func get_total_soldiers() -> int:
	var total: int = 0
	for role in soldiers:
		total += int(soldiers[role])
	return total


func get_total_population() -> int:
	# Total populasi warga benteng = Warga Sipil + Seluruh Serdadu Reguler
	# Mercenary TIDAK masuk ke populasi warga benteng
	return civilians + get_total_soldiers()


func recruit_soldier(role: String, count: int = 1) -> bool:
	assert(count >= 1, "count harus >= 1")
	if not soldiers.has(role):
		return false
	if civilians < count:
		return false # Tidak cukup warga sipil
		
	civilians -= count
	soldiers[role] = int(soldiers[role]) + count
	return true


func apply_casualties(losses: Dictionary) -> int:
	# Kematian prajurit MENGURANGI populasi total secara permanen
	var total_dead: int = 0
	for role in losses:
		if soldiers.has(role):
			var current: int = int(soldiers[role])
			var lost: int = mini(current, int(losses[role]))
			soldiers[role] = current - lost
			total_dead += lost
	return total_dead


func hire_mercenaries(count: int) -> void:
	assert(count >= 0, "count tidak boleh negatif")
	mercenaries += count


func remove_mercenaries(count: int) -> void:
	mercenaries = maxi(0, mercenaries - count)


func grow_population(growth_rate: float = 0.08) -> int:
	var current_total: int = get_total_population()
	if current_total >= housing_capacity:
		return 0
	if morale < 50:
		return 0 # Moral rendah menghentikan pertumbuhan
		
	var space: float = float(housing_capacity - current_total)
	var morale_factor: float = float(morale) / 100.0
	var raw_growth: float = growth_rate * space * morale_factor
	var added: int = int(floor(raw_growth))
	if added > 0:
		civilians += added
	return added


func clone() -> PopulationModel:
	var p := PopulationModel.new(civilians, housing_capacity, morale)
	p.soldiers = soldiers.duplicate(true)
	p.mercenaries = mercenaries
	return p
