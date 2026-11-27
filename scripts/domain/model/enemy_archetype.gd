class_name EnemyArchetype
extends RefCounted

## EnemyArchetype
## Domain model untuk arketipe musuh kanonikal (Phase 6A).
## Mendefinisikan 6 arketipe musuh kanonikal, atribut tempur dasar,
## profil pergerakan zona, dan pemetaan deterministik dari WaveGenerator.
## Bebas dari dependensi Node, SceneTree, UI, dan visual.

const ARCHETYPE_GOBLIN_SWARM: String = "GOBLIN_SWARM"
const ARCHETYPE_ORC_FRONTLINE: String = "ORC_FRONTLINE"
const ARCHETYPE_GOBLIN_ARCHER: String = "GOBLIN_ARCHER"
const ARCHETYPE_TROLL_TANK: String = "TROLL_TANK"
const ARCHETYPE_SIEGE_MONSTER: String = "SIEGE_MONSTER"
const ARCHETYPE_FLYING_BYPASS: String = "FLYING_BYPASS"

const VALID_ARCHETYPES: Array[String] = [
	ARCHETYPE_GOBLIN_SWARM,
	ARCHETYPE_ORC_FRONTLINE,
	ARCHETYPE_GOBLIN_ARCHER,
	ARCHETYPE_TROLL_TANK,
	ARCHETYPE_SIEGE_MONSTER,
	ARCHETYPE_FLYING_BYPASS
]

# Legacy key mapping from WaveGenerator
const LEGACY_MINION: String = "MINION"
const LEGACY_RAIDER: String = "RAIDER"
const LEGACY_BRUTE: String = "BRUTE"
const LEGACY_FLYER: String = "FLYER"
const LEGACY_SIEGE: String = "SIEGE"
const LEGACY_BOSS: String = "BOSS"
const LEGACY_ARCHER: String = "ARCHER_FOE"

var archetype_id: String = ""
var display_name: String = ""
var role_category: String = ""
var threat_cost: int = 0
var base_hp: int = 0
var base_atk: int = 0
var base_def: int = 0
var move_speed_ticks: int = 1
var target_priority: String = ""
var special_trait: String = ""


func _init(
	p_id: String = "",
	p_name: String = "",
	p_role: String = "",
	p_threat: int = 0,
	p_hp: int = 0,
	p_atk: int = 0,
	p_def: int = 0,
	p_speed: int = 1,
	p_target: String = "",
	p_trait: String = ""
) -> void:
	archetype_id = p_id.strip_edges().to_upper()
	display_name = p_name
	role_category = p_role
	threat_cost = p_threat
	base_hp = p_hp
	base_atk = p_atk
	base_def = p_def
	move_speed_ticks = p_speed
	target_priority = p_target
	special_trait = p_trait


static func is_valid_archetype(type_id: String) -> bool:
	return type_id.strip_edges().to_upper() in VALID_ARCHETYPES


static func get_all_archetype_ids() -> Array[String]:
	var result: Array[String] = []
	for a in VALID_ARCHETYPES:
		result.append(a)
	return result


static func map_legacy_enemy_type(legacy_type: String) -> String:
	match legacy_type.strip_edges().to_upper():
		LEGACY_MINION:
			return ARCHETYPE_GOBLIN_SWARM
		LEGACY_RAIDER:
			return ARCHETYPE_ORC_FRONTLINE
		LEGACY_BRUTE:
			return ARCHETYPE_TROLL_TANK
		LEGACY_FLYER:
			return ARCHETYPE_FLYING_BYPASS
		LEGACY_SIEGE:
			return ARCHETYPE_SIEGE_MONSTER
		LEGACY_BOSS:
			return ARCHETYPE_TROLL_TANK
		LEGACY_ARCHER, ARCHETYPE_GOBLIN_ARCHER:
			return ARCHETYPE_GOBLIN_ARCHER
		_:
			if is_valid_archetype(legacy_type):
				return legacy_type.strip_edges().to_upper()
			return ""


static func get_definition(type_id: String) -> Dictionary:
	match type_id.strip_edges().to_upper():
		ARCHETYPE_GOBLIN_SWARM:
			return {
				"display_name": "Goblin Swarm",
				"role_category": "SWARM_MELEE",
				"threat_cost": 2,
				"base_hp": 20,
				"base_atk": 4,
				"base_def": 2,
				"move_speed_ticks": 1,
				"target_priority": "NEAREST",
				"special_trait": "SWARM"
			}
		ARCHETYPE_ORC_FRONTLINE:
			return {
				"display_name": "Orc Frontline",
				"role_category": "STANDARD_MELEE",
				"threat_cost": 6,
				"base_hp": 65,
				"base_atk": 12,
				"base_def": 8,
				"move_speed_ticks": 2,
				"target_priority": "DEFENDER",
				"special_trait": "FRONTLINE"
			}
		ARCHETYPE_GOBLIN_ARCHER:
			return {
				"display_name": "Goblin Archer",
				"role_category": "RANGED_SKIRMISH",
				"threat_cost": 8,
				"base_hp": 35,
				"base_atk": 14,
				"base_def": 4,
				"move_speed_ticks": 2,
				"target_priority": "RANGED",
				"special_trait": "RANGED"
			}
		ARCHETYPE_TROLL_TANK:
			return {
				"display_name": "Troll Tank",
				"role_category": "HEAVY_TANK_MELEE",
				"threat_cost": 16,
				"base_hp": 220,
				"base_atk": 25,
				"base_def": 18,
				"move_speed_ticks": 3,
				"target_priority": "GATE",
				"special_trait": "HIGH_DURABILITY"
			}
		ARCHETYPE_SIEGE_MONSTER:
			return {
				"display_name": "Siege Monster",
				"role_category": "STRUCTURE_DESTROYER",
				"threat_cost": 40,
				"base_hp": 450,
				"base_atk": 60,
				"base_def": 25,
				"move_speed_ticks": 4,
				"target_priority": "STRUCTURE",
				"special_trait": "STRUCTURE_DAMAGE"
			}
		ARCHETYPE_FLYING_BYPASS:
			return {
				"display_name": "Flying Bypass",
				"role_category": "AERIAL_INFILTRATOR",
				"threat_cost": 12,
				"base_hp": 50,
				"base_atk": 16,
				"base_def": 5,
				"move_speed_ticks": 1,
				"target_priority": "FORTRESS",
				"special_trait": "BYPASS_BARRIER"
			}
		_:
			return {}


static func create(type_id: String) -> EnemyArchetype:
	var id: String = type_id.strip_edges().to_upper()
	if not is_valid_archetype(id):
		return null
	var def: Dictionary = get_definition(id)
	return EnemyArchetype.new(
		id,
		str(def.get("display_name", id)),
		str(def.get("role_category", "")),
		int(def.get("threat_cost", 1)),
		int(def.get("base_hp", 10)),
		int(def.get("base_atk", 1)),
		int(def.get("base_def", 0)),
		int(def.get("move_speed_ticks", 1)),
		str(def.get("target_priority", "NEAREST")),
		str(def.get("special_trait", ""))
	)


static func map_wave_to_enemy_groups(wave_data: Dictionary, _seed_val: int = 0) -> Array:
	var groups: Array = []
	if wave_data.is_empty():
		return groups
	
	var wave_num: int = int(wave_data.get("wave", 1))
	var enemies_dict: Dictionary = wave_data.get("enemies", {})
	
	# Urutan iterasi kanonikal deterministik
	var processing_order: Array[String] = [
		LEGACY_MINION,
		LEGACY_RAIDER,
		ARCHETYPE_GOBLIN_ARCHER,
		LEGACY_ARCHER,
		LEGACY_BRUTE,
		LEGACY_FLYER,
		LEGACY_SIEGE,
		LEGACY_BOSS
	]
	
	var processed_keys: Dictionary = {}
	
	for key in processing_order:
		if enemies_dict.has(key):
			var count: int = int(enemies_dict[key])
			if count > 0:
				var is_boss: bool = (key == LEGACY_BOSS)
				var arch_type: String = map_legacy_enemy_type(key)
				if arch_type != "":
					var group_id: String = "enemy_wave_%d_%s" % [wave_num, key.to_lower()]
					var group = EnemyGroup.new(
						group_id,
						arch_type,
						count,
						BattlefieldZone.ZONE_OUTER_FIELD,
						is_boss
					)
					groups.append(group)
				processed_keys[key] = true
	
	# Tangani tipe tambahan apa pun yang belum termasuk dalam urutan canonical
	var remaining_keys: Array = enemies_dict.keys()
	remaining_keys.sort()
	for rem_key in remaining_keys:
		var k_str: String = str(rem_key).strip_edges().to_upper()
		if not processed_keys.has(k_str):
			var count: int = int(enemies_dict[rem_key])
			if count > 0:
				var arch_type: String = map_legacy_enemy_type(k_str)
				if arch_type != "":
					var is_boss: bool = (k_str == LEGACY_BOSS)
					var group_id: String = "enemy_wave_%d_%s" % [wave_num, k_str.to_lower()]
					var group = EnemyGroup.new(
						group_id,
						arch_type,
						count,
						BattlefieldZone.ZONE_OUTER_FIELD,
						is_boss
					)
					groups.append(group)
				processed_keys[k_str] = true
				
	return groups


func validate_invariants() -> bool:
	if not is_valid_archetype(archetype_id):
		return false
	if display_name.strip_edges().is_empty():
		return false
	if threat_cost <= 0:
		return false
	if base_hp <= 0:
		return false
	if base_atk < 0:
		return false
	if base_def < 0:
		return false
	if move_speed_ticks <= 0:
		return false
	if target_priority.strip_edges().is_empty():
		return false
	return true


func clone() -> EnemyArchetype:
	return EnemyArchetype.new(
		archetype_id,
		display_name,
		role_category,
		threat_cost,
		base_hp,
		base_atk,
		base_def,
		move_speed_ticks,
		target_priority,
		special_trait
	)


func to_dictionary() -> Dictionary:
	return {
		"archetype_id": archetype_id,
		"display_name": display_name,
		"role_category": role_category,
		"threat_cost": threat_cost,
		"base_hp": base_hp,
		"base_atk": base_atk,
		"base_def": base_def,
		"move_speed_ticks": move_speed_ticks,
		"target_priority": target_priority,
		"special_trait": special_trait
	}


static func from_dictionary(dict: Dictionary) -> EnemyArchetype:
	if dict.is_empty():
		return null
	return EnemyArchetype.new(
		str(dict.get("archetype_id", "")),
		str(dict.get("display_name", "")),
		str(dict.get("role_category", "")),
		int(dict.get("threat_cost", 0)),
		int(dict.get("base_hp", 0)),
		int(dict.get("base_atk", 0)),
		int(dict.get("base_def", 0)),
		int(dict.get("move_speed_ticks", 1)),
		str(dict.get("target_priority", "")),
		str(dict.get("special_trait", ""))
	)
