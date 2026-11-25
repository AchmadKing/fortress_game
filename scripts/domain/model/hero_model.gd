class_name HeroModel
extends RefCounted

## HeroModel
## Entitas pahlawan/komandan individual (domain layer).
## Mendukung stat scaling, EXP curve, bintang, fatigue, morale, chemistry, dan permadeath.

var hero_id: String = ""
var hero_name: String = ""
var level: int = 1
var current_exp: int = 0
var current_star: int = 1
var potential_star: int = 3
var base_hp: int = 250
var base_atk: int = 35
var base_def: int = 20
var fatigue: int = 0          # 0 - 100
var morale: int = 100         # 0 - 150
var is_alive: bool = true
var chemistry_map: Dictionary = {} # other_hero_id (String) -> chemistry points (int)


func _init(p_id: String = "hero_1", p_name: String = "Hero", p_cur_star: int = 1, p_pot_star: int = 3) -> void:
	hero_id = p_id
	hero_name = p_name
	current_star = clampi(p_cur_star, 1, 5)
	potential_star = clampi(maxi(current_star, p_pot_star), 1, 5)
	level = 1
	current_exp = 0
	fatigue = 0
	morale = 100
	is_alive = true
	chemistry_map = {}


func get_required_exp(target_level: int) -> int:
	assert(target_level >= 1, "target_level harus >= 1")
	# Formula: floor(120 * L^1.55)
	return int(floor(120.0 * pow(float(target_level), 1.55)))


func add_exp(amount: int) -> int:
	if not is_alive:
		return 0
	current_exp += maxi(0, amount)
	var levels_gained: int = 0
	while true:
		var req: int = get_required_exp(level)
		if current_exp >= req:
			current_exp -= req
			level += 1
			levels_gained += 1
		else:
			break
	return levels_gained


func add_fatigue(amount: int) -> void:
	fatigue = clampi(fatigue + amount, 0, 100)


func rest(recovery: int = 30) -> void:
	fatigue = clampi(fatigue - recovery, 0, 100)


func train(exp_yield: int = 150, fatigue_cost: int = 25) -> int:
	if not is_alive:
		return 0
	add_fatigue(fatigue_cost)
	return add_exp(exp_yield)


func add_chemistry(partner_hero_id: String, points: int = 2) -> void:
	var cur: int = int(chemistry_map.get(partner_hero_id, 0))
	chemistry_map[partner_hero_id] = clampi(cur + points, 0, 50)


func get_chemistry_bonus(party_hero_ids: Array) -> float:
	var total_points: int = 0
	for other_id in party_hero_ids:
		var s_id: String = str(other_id)
		if s_id != hero_id and chemistry_map.has(s_id):
			total_points += int(chemistry_map[s_id])
	return 1.0 + (float(total_points) * 0.005) # Tiap poin memberi +0.5% efektivitas


func get_fatigue_multiplier() -> float:
	if fatigue <= 20:
		return 1.0
	# Penalti linier jika fatigue > 20, batas bawah 0.40
	return maxf(0.40, 1.0 - (float(fatigue - 20) / 80.0) * 0.60)


func get_effective_atk(party_hero_ids: Array = []) -> int:
	if not is_alive:
		return 0
	var level_scale: float = 1.0 + float(level - 1) * 0.12
	var star_scale: float = 1.0 + float(current_star - 1) * 0.20
	var chem_scale: float = get_chemistry_bonus(party_hero_ids)
	var fat_scale: float = get_fatigue_multiplier()
	return int(floor(float(base_atk) * level_scale * star_scale * chem_scale * fat_scale))


func get_effective_def() -> int:
	if not is_alive:
		return 0
	var level_scale: float = 1.0 + float(level - 1) * 0.10
	var star_scale: float = 1.0 + float(current_star - 1) * 0.20
	var fat_scale: float = get_fatigue_multiplier()
	return int(floor(float(base_def) * level_scale * star_scale * fat_scale))


func mark_dead() -> void:
	is_alive = false


func clone() -> HeroModel:
	var h := HeroModel.new(hero_id, hero_name, current_star, potential_star)
	h.level = level
	h.current_exp = current_exp
	h.base_hp = base_hp
	h.base_atk = base_atk
	h.base_def = base_def
	h.fatigue = fatigue
	h.morale = morale
	h.is_alive = is_alive
	h.chemistry_map = chemistry_map.duplicate(true)
	return h
