class_name EquipmentModel
extends RefCounted

## EquipmentModel
## Model perlengkapan murni (domain layer) untuk gudang senjata dan serdadu.
## Tidak memiliki dependensi ke visual/Node.

var role_type: String = "SWORD" # SWORD, SHIELD, SPEAR, BOW, HEAVY_ARMOR
var tier: int = 1               # Tier 1 sampai 5
var durability: int = 100       # 0 sampai 100
var max_durability: int = 100


func _init(p_role_type: String = "SWORD", p_tier: int = 1, p_durability: int = 100) -> void:
	role_type = p_role_type
	tier = clampi(p_tier, 1, 5)
	max_durability = 100
	durability = clampi(p_durability, 0, max_durability)


func is_broken() -> bool:
	return durability <= 0


func get_power_multiplier() -> float:
	if is_broken():
		return 0.10 # Penalti jika rusak: hanya 10% efektivitas
	match tier:
		1: return 1.15
		2: return 1.35
		3: return 1.65
		4: return 2.05
		5: return 2.60
		_: return 1.0


func get_repair_cost_per_point() -> float:
	match tier:
		1: return 0.20
		2: return 0.50
		3: return 1.10
		4: return 2.20
		5: return 4.50
		_: return 0.50


func calculate_repair_cost() -> int:
	var missing: int = max_durability - durability
	if missing <= 0:
		return 0
	return int(ceil(float(missing) * get_repair_cost_per_point()))


func apply_wear(amount: int) -> void:
	durability = clampi(durability - amount, 0, max_durability)


func repair() -> void:
	durability = max_durability


func clone() -> EquipmentModel:
	return EquipmentModel.new(role_type, tier, durability)
