class_name HeroModel
extends RefCounted

## HeroModel
## Entitas pahlawan/komandan individual (domain layer).
## Mendukung stat scaling, EXP curve, bintang, fatigue, morale, chemistry, permadeath,
## peran kanonikal (HeroRole), dan status siklus hidup (HeroLifecycleState).

const HeroRoleScript = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleStateScript = preload("res://scripts/domain/model/hero_lifecycle_state.gd")

# Canonical Role Constants (Delegated to HeroRole)
const ROLE_KNIGHT: String = "KNIGHT"
const ROLE_MAGE: String = "MAGE"
const ROLE_ARCHER: String = "ARCHER"
const ROLE_PRIEST: String = "PRIEST"

# Canonical Lifecycle State Constants (Delegated to HeroLifecycleState)
const STATE_RECRUITABLE: String = "RECRUITABLE"
const STATE_ROSTER_ACTIVE: String = "ROSTER_ACTIVE"
const STATE_IN_PARTY: String = "IN_PARTY"
const STATE_IN_TRAINING: String = "IN_TRAINING"
const STATE_BATTLE_ACTIVE: String = "BATTLE_ACTIVE"
const STATE_PERMADEATH: String = "PERMADEATH"

var hero_id: String = ""
var hero_name: String = ""
var role: String = "KNIGHT"
var lifecycle_state: String = "ROSTER_ACTIVE"
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

# Phase 3C Hero Equipment Slots
var primary_equipment: RefCounted = null    # EquipmentModel (SWORD, SPEAR, BOW)
var secondary_equipment: RefCounted = null  # EquipmentModel (SHIELD, etc.)
var armor_equipment: RefCounted = null      # EquipmentModel (HEAVY_ARMOR)


func _init(
	p_id: String = "hero_1",
	p_name: String = "Hero",
	p_cur_star: int = 1,
	p_pot_star: int = 3,
	p_role: String = "KNIGHT",
	p_state: String = "ROSTER_ACTIVE"
) -> void:
	hero_id = p_id
	hero_name = p_name
	current_star = clampi(p_cur_star, 1, 5)
	potential_star = clampi(maxi(current_star, p_pot_star), 1, 5)
	role = p_role.to_upper().strip_edges() if HeroRoleScript.is_valid_role(p_role) else ROLE_KNIGHT
	lifecycle_state = p_state.to_upper().strip_edges() if HeroLifecycleStateScript.is_valid_state(p_state) else STATE_ROSTER_ACTIVE
	level = 1
	current_exp = 0
	fatigue = 0
	morale = 100
	is_alive = (lifecycle_state != STATE_PERMADEATH)
	chemistry_map = {}
	primary_equipment = null
	secondary_equipment = null
	armor_equipment = null


# ==============================================================================
# PHASE 4A ROLE & LIFECYCLE DOMAIN METHODS
# ==============================================================================

static func is_valid_role(p_role: String) -> bool:
	return HeroRoleScript.is_valid_role(p_role)


static func is_valid_lifecycle_state(p_state: String) -> bool:
	return HeroLifecycleStateScript.is_valid_state(p_state)


static func can_transition_lifecycle(from_state: String, to_state: String) -> bool:
	return HeroLifecycleStateScript.can_transition(from_state, to_state)


static func validate_identity(p_id: String, p_name: String) -> bool:
	return not p_id.strip_edges().is_empty() and not p_name.strip_edges().is_empty()


static func validate_stars(cur: int, pot: int) -> bool:
	if cur < 1 or cur > 5:
		return false
	if pot < 1 or pot > 5:
		return false
	if cur > pot:
		return false
	return true


func set_role(new_role: String) -> bool:
	if not HeroRoleScript.is_valid_role(new_role):
		return false
	role = new_role.to_upper().strip_edges()
	return true


func is_role_valid() -> bool:
	return HeroRoleScript.is_valid_role(role)


func is_lifecycle_state_valid() -> bool:
	return HeroLifecycleStateScript.is_valid_state(lifecycle_state)


func transition_lifecycle_state(new_state: String) -> bool:
	var target: String = new_state.to_upper().strip_edges()
	if not HeroLifecycleStateScript.can_transition(lifecycle_state, target):
		return false
	lifecycle_state = target
	if lifecycle_state == STATE_PERMADEATH:
		is_alive = false
	return true


func is_equipment_compatible(slot: String, eq_type: String) -> bool:
	return HeroRoleScript.is_equipment_compatible(role, slot, eq_type)


func validate_invariants() -> bool:
	if not validate_identity(hero_id, hero_name):
		return false
	if not is_role_valid():
		return false
	if not is_lifecycle_state_valid():
		return false
	if not validate_stars(current_star, potential_star):
		return false
	if lifecycle_state == STATE_PERMADEATH and is_alive:
		return false
	if not is_alive and lifecycle_state != STATE_PERMADEATH:
		return false
	return true


# ==============================================================================
# PHASE 3C HERO EQUIPMENT METHODS
# ==============================================================================

func equip(slot: String, eq: RefCounted) -> RefCounted:
	var s: String = slot.to_upper().strip_edges()
	var old_eq: RefCounted = null
	match s:
		"PRIMARY":
			old_eq = primary_equipment
			primary_equipment = eq
		"SECONDARY":
			old_eq = secondary_equipment
			secondary_equipment = eq
		"ARMOR":
			old_eq = armor_equipment
			armor_equipment = eq
	return old_eq


func unequip(slot: String) -> RefCounted:
	var s: String = slot.to_upper().strip_edges()
	var removed: RefCounted = null
	match s:
		"PRIMARY":
			removed = primary_equipment
			primary_equipment = null
		"SECONDARY":
			removed = secondary_equipment
			secondary_equipment = null
		"ARMOR":
			removed = armor_equipment
			armor_equipment = null
	return removed


func has_equipment(slot: String) -> bool:
	var s: String = slot.to_upper().strip_edges()
	match s:
		"PRIMARY": return primary_equipment != null
		"SECONDARY": return secondary_equipment != null
		"ARMOR": return armor_equipment != null
	return false


func get_equipment(slot: String) -> RefCounted:
	var s: String = slot.to_upper().strip_edges()
	match s:
		"PRIMARY": return primary_equipment
		"SECONDARY": return secondary_equipment
		"ARMOR": return armor_equipment
	return null


func get_equipped_items() -> Array:
	var items: Array = []
	if primary_equipment != null:
		items.append(primary_equipment)
	if secondary_equipment != null:
		items.append(secondary_equipment)
	if armor_equipment != null:
		items.append(armor_equipment)
	return items


func clear_equipment() -> Array:
	var items: Array = get_equipped_items()
	primary_equipment = null
	secondary_equipment = null
	armor_equipment = null
	return items


# ==============================================================================
# PROGRESSION, FATIGUE, MORALE, & CHEMISTRY (PHASE 2 & 3 CONTRACTS)
# ==============================================================================

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
	var gear_scale: float = 1.0
	if primary_equipment != null and primary_equipment.has_method("get_power_multiplier"):
		gear_scale = primary_equipment.get_power_multiplier()
	return int(floor(float(base_atk) * level_scale * star_scale * chem_scale * fat_scale * gear_scale))


func get_effective_def() -> int:
	if not is_alive:
		return 0
	var level_scale: float = 1.0 + float(level - 1) * 0.10
	var star_scale: float = 1.0 + float(current_star - 1) * 0.20
	var fat_scale: float = get_fatigue_multiplier()
	var def_scale: float = 1.0
	if armor_equipment != null and armor_equipment.has_method("get_power_multiplier"):
		def_scale *= armor_equipment.get_power_multiplier()
	if secondary_equipment != null and secondary_equipment.has_method("get_power_multiplier"):
		def_scale *= (1.0 + (secondary_equipment.get_power_multiplier() - 1.0) * 0.5)
	return int(floor(float(base_def) * level_scale * star_scale * fat_scale * def_scale))


func mark_dead() -> void:
	is_alive = false
	lifecycle_state = STATE_PERMADEATH


func clone() -> HeroModel:
	var h := HeroModel.new(hero_id, hero_name, current_star, potential_star, role, lifecycle_state)
	h.level = level
	h.current_exp = current_exp
	h.base_hp = base_hp
	h.base_atk = base_atk
	h.base_def = base_def
	h.fatigue = fatigue
	h.morale = morale
	h.is_alive = is_alive
	h.chemistry_map = chemistry_map.duplicate(true)
	if primary_equipment != null and primary_equipment.has_method("clone"):
		h.primary_equipment = primary_equipment.clone()
	if secondary_equipment != null and secondary_equipment.has_method("clone"):
		h.secondary_equipment = secondary_equipment.clone()
	if armor_equipment != null and armor_equipment.has_method("clone"):
		h.armor_equipment = armor_equipment.clone()
	return h
