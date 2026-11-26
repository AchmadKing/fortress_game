class_name EquipmentModel
extends RefCounted

## EquipmentModel
## Model perlengkapan murni (domain layer) untuk gudang senjata dan serdadu.
## Mendukung tier, durabilitas, kuantitas agregat, dan penalti kerusakan.

var role_type: String = "SWORD" # SWORD, SHIELD, SPEAR, BOW, HEAVY_ARMOR
var tier: int = 1               # Tier 1 sampai 5
var durability: int = 100       # 0 sampai 100
var max_durability: int = 100
var quantity: int = 1           # Kuantitas unit equipment


func _init(p_role_type: String = "SWORD", p_tier: int = 1, p_durability: int = 100, p_quantity: int = 1) -> void:
	role_type = p_role_type
	tier = clampi(p_tier, 1, 5)
	max_durability = 100
	durability = clampi(p_durability, 0, max_durability)
	quantity = maxi(0, p_quantity)


func is_broken() -> bool:
	return durability <= 0


func is_usable() -> bool:
	return durability >= max_durability


func is_damaged() -> bool:
	return durability < max_durability


func get_power_multiplier() -> float:
	if is_broken():
		return 1.0 # Equipment rusak tidak memberikan tier bonus (sama dengan unequipped 1.0)
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


func calculate_repair_cost(discount_pct: float = 0.0) -> int:
	var missing: int = max_durability - durability
	if missing <= 0 or quantity <= 0:
		return 0
	var unit_cost: float = float(missing) * get_repair_cost_per_point() * (1.0 - clampf(discount_pct, 0.0, 0.80))
	return int(ceil(unit_cost * float(quantity)))


func apply_wear(amount: int) -> void:
	durability = clampi(durability - amount, 0, max_durability)


func repair() -> void:
	durability = max_durability


func clone() -> EquipmentModel:
	return EquipmentModel.new(role_type, tier, durability, quantity)
