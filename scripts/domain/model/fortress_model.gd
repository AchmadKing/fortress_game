class_name FortressModel
extends RefCounted

## FortressModel
## Model integritas struktural benteng (domain layer).
## HP persisten antar-wave dan kondisi Game Over jika HP <= 0.

var max_hp: int = 1000
var current_hp: int = 1000
var armor: int = 40
var upgrade_tier: int = 1


func _init(p_max_hp: int = 1000, p_armor: int = 40) -> void:
	max_hp = maxi(100, p_max_hp)
	current_hp = max_hp
	armor = maxi(0, p_armor)
	upgrade_tier = 1


func is_destroyed() -> bool:
	return current_hp <= 0


func take_damage(raw_damage: int) -> int:
	if is_destroyed():
		return 0
	# Penyerapan armor benteng: armor / (armor + 150)
	var reduction_pct: float = float(armor) / float(armor + 150)
	var absorbed: float = float(raw_damage) * (1.0 - reduction_pct)
	var actual_damage: int = maxi(1, int(floor(absorbed)))
	current_hp = clampi(current_hp - actual_damage, 0, max_hp)
	return actual_damage


func repair(repaired_hp: int) -> int:
	if is_destroyed():
		return 0
	var needed: int = max_hp - current_hp
	var actual_repair: int = mini(needed, maxi(0, repaired_hp))
	current_hp += actual_repair
	return actual_repair


func upgrade_fortress(hp_bonus: int = 350, armor_bonus: int = 15) -> void:
	max_hp += hp_bonus
	current_hp += hp_bonus
	armor += armor_bonus
	upgrade_tier += 1


func clone() -> FortressModel:
	var f := FortressModel.new(max_hp, armor)
	f.current_hp = current_hp
	f.upgrade_tier = upgrade_tier
	return f
