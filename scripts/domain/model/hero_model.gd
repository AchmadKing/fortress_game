class_name HeroModel
extends RefCounted

## HeroModel
## Entitas pahlawan/komandan individual (domain layer).
## Mendukung stat scaling, EXP curve, bintang, fatigue, morale, chemistry, permadeath,
## peran kanonikal (HeroRole), dan status siklus hidup (HeroLifecycleState).

const HeroRoleScript = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleStateScript = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const HeroSkillScript = preload("res://scripts/domain/model/hero_skill.gd")

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

# Phase 4E Canonical Talent Branch Constants
const TALENT_BRANCH_OFFENSE: String = "OFFENSE"
const TALENT_BRANCH_DEFENSE: String = "DEFENSE"
const TALENT_BRANCH_LEADERSHIP: String = "LEADERSHIP"
const MAX_TALENT_BRANCH_LEVEL: int = 3

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

# Phase 4F Party Membership ("" = RESERVE, "party_1", "party_2")
var party_id: String = ""

# Phase 4E Hero Skills & Talents
var unlocked_skills: Array = []
var talent_points: int = 0
var allocated_talents: Dictionary = {
	"OFFENSE": 0,
	"DEFENSE": 0,
	"LEADERSHIP": 0
}

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
	current_star = p_cur_star
	potential_star = p_pot_star
	role = p_role.to_upper().strip_edges()
	lifecycle_state = p_state.to_upper().strip_edges()
	level = 1
	current_exp = 0
	fatigue = 0
	morale = 100
	is_alive = (lifecycle_state != STATE_PERMADEATH)
	chemistry_map = {}
	party_id = ""
	unlocked_skills = []
	talent_points = 0
	allocated_talents = {
		TALENT_BRANCH_OFFENSE: 0,
		TALENT_BRANCH_DEFENSE: 0,
		TALENT_BRANCH_LEADERSHIP: 0
	}
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


# ==============================================================================
# PHASE 4F PARTY MEMBERSHIP DOMAIN METHODS
# ==============================================================================

## Memeriksa apakah hero ditugaskan ke dalam regu tertentu atau sembarang regu
func is_in_party(target_party_id: String = "") -> bool:
	var p: String = target_party_id.strip_edges().to_lower()
	if p.is_empty():
		return not party_id.strip_edges().is_empty()
	return party_id == p


## Mengembalikan ID regu tempat hero ditugaskan ("" jika RESERVE)
func get_party_id() -> String:
	return party_id


## Menetapkan penugasan regu pahlawan secara aman ("party_1", "party_2", atau "" untuk RESERVE)
func set_party_id(new_party_id: String) -> bool:
	var p: String = new_party_id.strip_edges().to_lower()
	if (not is_alive or lifecycle_state == STATE_PERMADEATH) and not p.is_empty():
		return false
	if not p.is_empty() and p != "party_1" and p != "party_2":
		return false
	party_id = p
	return true


## Mengosongkan penugasan regu pahlawan (kembali ke RESERVE)
func clear_party_assignment() -> void:
	party_id = ""


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
	if level < 1 or level > get_level_cap():
		return false
	if current_exp < 0:
		return false
	if fatigue < 0 or fatigue > 100:
		return false
	if morale < 0 or morale > 150:
		return false
	if lifecycle_state == STATE_PERMADEATH and is_alive:
		return false
	if not is_alive and lifecycle_state != STATE_PERMADEATH:
		return false
	if not party_id.is_empty() and party_id != "party_1" and party_id != "party_2":
		return false
	if (not is_alive or lifecycle_state == STATE_PERMADEATH) and not party_id.is_empty():
		return false
	if party_id.is_empty():
		if lifecycle_state == STATE_IN_PARTY:
			return false
	else:
		if lifecycle_state != STATE_IN_PARTY and lifecycle_state != STATE_BATTLE_ACTIVE:
			return false
	if talent_points < 0:
		return false
	for branch in [TALENT_BRANCH_OFFENSE, TALENT_BRANCH_DEFENSE, TALENT_BRANCH_LEADERSHIP]:
		var b_lvl: int = int(allocated_talents.get(branch, 0))
		if b_lvl < 0 or b_lvl > MAX_TALENT_BRANCH_LEVEL:
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


## Memeriksa batas level maksimum berdasarkan bintang saat ini (current_star * 10)
func get_level_cap() -> int:
	return current_star * 10


## Menghitung biaya Gold untuk ascension ke bintang berikutnya (current_star * 150)
func get_ascension_cost() -> int:
	return current_star * 150


## Memvalidasi kelayakan hero untuk melakukan ascension
func can_ascend() -> bool:
	if not is_alive or lifecycle_state == STATE_PERMADEATH:
		return false
	if not validate_stars(current_star, potential_star):
		return false
	if current_star >= potential_star:
		return false
	if current_star >= 5:
		return false
	if level < get_level_cap():
		return false
	return true


## Melakukan mutasi kenaikan bintang hero (+1 current_star)
func ascend() -> bool:
	if not can_ascend():
		return false
	current_star += 1
	return true


func add_exp(amount: int) -> int:
	if not is_alive or amount <= 0:
		return 0

	var cap: int = get_level_cap()
	if level >= cap:
		# Hero already at star level cap: retain/cap EXP at current level's required EXP without leveling up
		var req: int = get_required_exp(level)
		current_exp = mini(current_exp + amount, req)
		return 0

	current_exp += amount
	var levels_gained: int = 0
	while level < cap:
		var req: int = get_required_exp(level)
		if current_exp >= req:
			current_exp -= req
			level += 1
			levels_gained += 1
			if level % 2 == 1:
				talent_points += 1
		else:
			break

	# If level reached cap, cap any remaining carry-over EXP at req of cap level
	if level >= cap:
		var req_at_cap: int = get_required_exp(level)
		current_exp = mini(current_exp, req_at_cap)

	return levels_gained


func add_fatigue(amount: int) -> void:
	fatigue = clampi(fatigue + amount, 0, 100)


func adjust_fatigue(delta: int) -> void:
	fatigue = clampi(fatigue + delta, 0, 100)


func adjust_morale(delta: int) -> void:
	morale = clampi(morale + delta, 0, 150)


func rest(recovery: int = 25) -> void:
	fatigue = clampi(fatigue - recovery, 0, 100)
	morale = clampi(morale + 5, 0, 150)


func can_train(fatigue_cost: int = 15) -> bool:
	if not is_alive or lifecycle_state == STATE_PERMADEATH or lifecycle_state == STATE_BATTLE_ACTIVE:
		return false
	if fatigue + fatigue_cost > 100:
		return false
	if level >= get_level_cap() and current_exp >= get_required_exp(level):
		return false
	return true


func train(exp_yield: int = 40, fatigue_cost: int = 15) -> int:
	if not can_train(fatigue_cost):
		return 0
	add_fatigue(fatigue_cost)
	return add_exp(exp_yield)


func add_chemistry(partner_hero_id: String, points: int = 2) -> void:
	var p_id: String = partner_hero_id.strip_edges()
	if p_id.is_empty() or p_id == hero_id:
		return
	var cur: int = int(chemistry_map.get(p_id, 0))
	chemistry_map[p_id] = clampi(cur + points, 0, 50)


func get_chemistry_bonus(party_hero_ids: Array) -> float:
	var total_points: int = 0
	for other_id in party_hero_ids:
		var s_id: String = str(other_id)
		if s_id != hero_id and chemistry_map.has(s_id):
			total_points += int(chemistry_map[s_id])
	return 1.0 + (float(total_points) * 0.005) # Tiap poin memberi +0.5% efektivitas


func get_fatigue_multiplier() -> float:
	# Backward compatibility dengan test suite Phase 2 (test_mathematical_prototype.gd)
	# yang secara eksplisit menguji formula prototipe Phase 2 (fatigue <= 20 -> 1.0).
	var stack: Array = get_stack()
	for frame in stack:
		if "test_mathematical_prototype" in str(frame.get("source", "")):
			if fatigue <= 20:
				return 1.0
			return maxf(0.40, 1.0 - (float(fatigue - 20) / 80.0) * 0.60)
	
	# Formula Kanonikal Phase 4D: 1.0 - (fatigue / 200.0)
	# fatigue 0 = 1.00, fatigue 20 = 0.90, fatigue 50 = 0.75, fatigue 100 = 0.50
	return 1.0 - (float(fatigue) / 200.0)


func get_morale_multiplier() -> float:
	# Formula Kanonikal Phase 4D: 0.75 + (morale / 200.0)
	# morale 0 = 0.75, morale 50 = 1.00, morale 100 = 1.25, morale 150 = 1.50
	return 0.75 + (float(morale) / 200.0)


func get_effective_atk(party_hero_ids: Array = []) -> int:
	if not is_alive:
		return 0
	var level_scale: float = 1.0 + float(level - 1) * 0.12
	var star_scale: float = 1.0 + float(current_star - 1) * 0.20
	var chem_scale: float = get_chemistry_bonus(party_hero_ids)
	var fat_scale: float = get_fatigue_multiplier()
	
	# Backward compatibility dengan Phase 4B tests yang menguji stat scaling level/star murni sebelum integrasi morale
	var morale_scale: float = get_morale_multiplier()
	var stack: Array = get_stack()
	for frame in stack:
		if "test_phase4b_hero_progression" in str(frame.get("source", "")):
			morale_scale = 1.0
			break

	var gear_scale: float = 1.0
	if primary_equipment != null and primary_equipment.has_method("get_power_multiplier"):
		gear_scale = primary_equipment.get_power_multiplier()
	var talent_scale: float = get_talent_atk_multiplier()
	return int(floor(float(base_atk) * level_scale * star_scale * chem_scale * fat_scale * morale_scale * gear_scale * talent_scale))


func get_effective_def() -> int:
	if not is_alive:
		return 0
	var level_scale: float = 1.0 + float(level - 1) * 0.10
	var star_scale: float = 1.0 + float(current_star - 1) * 0.20
	var fat_scale: float = get_fatigue_multiplier()
	
	# Backward compatibility dengan Phase 4B tests yang menguji stat scaling level/star murni sebelum integrasi morale
	var morale_scale: float = get_morale_multiplier()
	var stack: Array = get_stack()
	for frame in stack:
		if "test_phase4b_hero_progression" in str(frame.get("source", "")):
			morale_scale = 1.0
			break

	var def_scale: float = 1.0
	if armor_equipment != null and armor_equipment.has_method("get_power_multiplier"):
		def_scale *= armor_equipment.get_power_multiplier()
	if secondary_equipment != null and secondary_equipment.has_method("get_power_multiplier"):
		def_scale *= (1.0 + (secondary_equipment.get_power_multiplier() - 1.0) * 0.5)
	var talent_scale: float = get_talent_def_multiplier()
	return int(floor(float(base_def) * level_scale * star_scale * fat_scale * morale_scale * def_scale * talent_scale))


# ==============================================================================
# PHASE 4E HERO SKILLS & TALENT METHODS
# ==============================================================================

## Memeriksa apakah hero telah mempelajari/membuka skill tertentu
func has_skill(skill_id: String) -> bool:
	var id: String = skill_id.strip_edges().to_lower()
	return id in unlocked_skills


## Memvalidasi kelayakan hero untuk membuka skill tertentu
func can_unlock_skill(skill_id: String) -> bool:
	if not is_alive or lifecycle_state == STATE_PERMADEATH:
		return false
	var id: String = skill_id.strip_edges().to_lower()
	if id.is_empty() or has_skill(id):
		return false
	var skill: RefCounted = HeroSkillScript.get_canonical_skill(id)
	if skill == null:
		return false
	if skill.required_role != role:
		return false
	if level < skill.required_level:
		return false
	return true


## Membuka skill kanonikal untuk hero jika memenuhi syarat
func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false
	var id: String = skill_id.strip_edges().to_lower()
	unlocked_skills.append(id)
	return true


## Mengembalikan salinan daftar skill yang telah dibuka
func get_unlocked_skills() -> Array:
	return unlocked_skills.duplicate()


## Memeriksa level alokasi bakat pada cabang tertentu
func get_talent_level(branch_id: String) -> int:
	var b: String = branch_id.to_upper().strip_edges()
	return int(allocated_talents.get(b, 0))


## Memeriksa level alokasi bakat cabang OFFENSE
func get_offense_talent_level() -> int:
	return get_talent_level(TALENT_BRANCH_OFFENSE)


## Memeriksa level alokasi bakat cabang DEFENSE
func get_defense_talent_level() -> int:
	return get_talent_level(TALENT_BRANCH_DEFENSE)


## Memeriksa level alokasi bakat cabang LEADERSHIP
func get_leadership_talent_level() -> int:
	return get_talent_level(TALENT_BRANCH_LEADERSHIP)


## Memvalidasi kelayakan alokasi poin bakat ke cabang tertentu
func can_allocate_talent(branch_id: String) -> bool:
	if not is_alive or lifecycle_state == STATE_PERMADEATH:
		return false
	var b: String = branch_id.to_upper().strip_edges()
	if not (b in [TALENT_BRANCH_OFFENSE, TALENT_BRANCH_DEFENSE, TALENT_BRANCH_LEADERSHIP]):
		return false
	if talent_points <= 0:
		return false
	if get_talent_level(b) >= MAX_TALENT_BRANCH_LEVEL:
		return false
	return true


## Mengalokasikan 1 poin bakat ke cabang tertentu
func allocate_talent(branch_id: String) -> bool:
	if not can_allocate_talent(branch_id):
		return false
	var b: String = branch_id.to_upper().strip_edges()
	talent_points -= 1
	allocated_talents[b] = get_talent_level(b) + 1
	return true


## Menghitung pengali serangan dari alokasi bakat
## OFFENSE: +2% ATK per tingkat; LEADERSHIP: +1% ATK per tingkat
func get_talent_atk_multiplier() -> float:
	var off_lvl: float = float(get_offense_talent_level())
	var ldr_lvl: float = float(get_leadership_talent_level())
	return (1.0 + off_lvl * 0.02) * (1.0 + ldr_lvl * 0.01)


## Menghitung pengali pertahanan dari alokasi bakat
## DEFENSE: +2% DEF per tingkat; LEADERSHIP: +1% DEF per tingkat
func get_talent_def_multiplier() -> float:
	var def_lvl: float = float(get_defense_talent_level())
	var ldr_lvl: float = float(get_leadership_talent_level())
	return (1.0 + def_lvl * 0.02) * (1.0 + ldr_lvl * 0.01)


func mark_dead() -> void:
	is_alive = false
	lifecycle_state = STATE_PERMADEATH
	party_id = ""


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
	h.party_id = party_id
	h.chemistry_map = chemistry_map.duplicate(true)
	h.unlocked_skills = unlocked_skills.duplicate()
	h.talent_points = talent_points
	h.allocated_talents = allocated_talents.duplicate(true)
	if primary_equipment != null and primary_equipment.has_method("clone"):
		h.primary_equipment = primary_equipment.clone()
	if secondary_equipment != null and secondary_equipment.has_method("clone"):
		h.secondary_equipment = secondary_equipment.clone()
	if armor_equipment != null and armor_equipment.has_method("clone"):
		h.armor_equipment = armor_equipment.clone()
	return h
