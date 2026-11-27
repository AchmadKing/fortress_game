class_name FortressModel
extends RefCounted

## FortressModel
## Model integritas struktural benteng, dinding pertahanan, dan gerbang (domain layer).
## HP persisten antar-wave dan kondisi Game Over jika HP <= 0.

var max_hp: int = 1000
var current_hp: int = 1000
var armor: int = 40
var upgrade_tier: int = 1

# Phase 5 Defense Foundation: Wall & Gate
var wall_max_hp: int = 500
var wall_hp: int = 500
var gate_max_hp: int = 300
var gate_hp: int = 300


func _init(p_max_hp: int = 1000, p_armor: int = 40, p_wall_max_hp: int = 500, p_gate_max_hp: int = 300) -> void:
	max_hp = maxi(100, p_max_hp)
	current_hp = max_hp
	armor = maxi(0, p_armor)
	upgrade_tier = 1
	wall_max_hp = maxi(50, p_wall_max_hp)
	wall_hp = wall_max_hp
	gate_max_hp = maxi(50, p_gate_max_hp)
	gate_hp = gate_max_hp


func is_destroyed() -> bool:
	return current_hp <= 0


func is_wall_breached() -> bool:
	return wall_hp <= 0


func is_gate_breached() -> bool:
	return gate_hp <= 0


func take_damage(raw_damage: int) -> int:
	if is_destroyed() or raw_damage <= 0:
		return 0
	# Penyerapan armor benteng: armor / (armor + 150)
	var reduction_pct: float = float(armor) / float(armor + 150)
	var absorbed: float = float(raw_damage) * (1.0 - reduction_pct)
	var actual_damage: int = maxi(1, int(floor(absorbed)))
	current_hp = clampi(current_hp - actual_damage, 0, max_hp)
	return actual_damage


func repair(repaired_hp: int) -> int:
	if is_destroyed() or repaired_hp <= 0:
		return 0
	var needed: int = max_hp - current_hp
	var actual_repair: int = mini(needed, maxi(0, repaired_hp))
	current_hp += actual_repair
	return actual_repair


func damage_wall(amount: int) -> int:
	if amount <= 0:
		return 0
	var actual: int = mini(wall_hp, amount)
	wall_hp = clampi(wall_hp - actual, 0, wall_max_hp)
	return actual


func repair_wall(amount: int) -> int:
	if amount <= 0:
		return 0
	var needed: int = wall_max_hp - wall_hp
	var actual: int = mini(needed, amount)
	wall_hp = clampi(wall_hp + actual, 0, wall_max_hp)
	return actual


func damage_gate(amount: int) -> int:
	if amount <= 0:
		return 0
	var actual: int = mini(gate_hp, amount)
	gate_hp = clampi(gate_hp - actual, 0, gate_max_hp)
	return actual


func repair_gate(amount: int) -> int:
	if amount <= 0:
		return 0
	var needed: int = gate_max_hp - gate_hp
	var actual: int = mini(needed, amount)
	gate_hp = clampi(gate_hp + actual, 0, gate_max_hp)
	return actual


func upgrade_fortress(hp_bonus: int = 350, armor_bonus: int = 15) -> void:
	max_hp += hp_bonus
	current_hp += hp_bonus
	armor += armor_bonus
	upgrade_tier += 1


func validate_invariants() -> bool:
	if max_hp <= 0 or current_hp < 0 or current_hp > max_hp:
		return false
	if wall_max_hp <= 0 or wall_hp < 0 or wall_hp > wall_max_hp:
		return false
	if gate_max_hp <= 0 or gate_hp < 0 or gate_hp > gate_max_hp:
		return false
	if armor < 0 or upgrade_tier < 1:
		return false
	return true


func clone() -> FortressModel:
	var f := FortressModel.new(max_hp, armor, wall_max_hp, gate_max_hp)
	f.current_hp = current_hp
	f.wall_hp = wall_hp
	f.gate_hp = gate_hp
	f.upgrade_tier = upgrade_tier
	return f
