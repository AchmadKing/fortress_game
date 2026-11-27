class_name BattlefieldZone
extends RefCounted

## BattlefieldZone
## Domain model untuk zona medan pertempuran taktis (Phase 6A).
## Mengelola 7 zona kanonikal, graf ketetanggaan deterministik dua arah,
## modifier pertahanan/jangkauan, dan isolasi data domain.
## Bebas dari dependensi Node, SceneTree, UI, dan visual.

const ZONE_OUTER_FIELD: String = "OUTER_FIELD"
const ZONE_LEFT_FLANK: String = "LEFT_FLANK"
const ZONE_CENTER_APPROACH: String = "CENTER_APPROACH"
const ZONE_RIGHT_FLANK: String = "RIGHT_FLANK"
const ZONE_WALL: String = "WALL"
const ZONE_GATE: String = "GATE"
const ZONE_FORTRESS: String = "FORTRESS"

const VALID_ZONES: Array[String] = [
	ZONE_OUTER_FIELD,
	ZONE_LEFT_FLANK,
	ZONE_CENTER_APPROACH,
	ZONE_RIGHT_FLANK,
	ZONE_WALL,
	ZONE_GATE,
	ZONE_FORTRESS
]

const CANONICAL_ZONES: Array[String] = VALID_ZONES

const TYPE_FIELD: String = "FIELD"
const TYPE_FLANK: String = "FLANK"
const TYPE_APPROACH: String = "APPROACH"
const TYPE_DEFENSE: String = "DEFENSE"
const TYPE_CORE: String = "CORE"

const VALID_TYPES: Array[String] = [
	TYPE_FIELD,
	TYPE_FLANK,
	TYPE_APPROACH,
	TYPE_DEFENSE,
	TYPE_CORE
]

## Graf ketetanggaan kanonikal deterministik simetris (bidirectional) tanpa self-reference.
const CANONICAL_ADJACENCY: Dictionary = {
	ZONE_OUTER_FIELD: [ZONE_LEFT_FLANK, ZONE_CENTER_APPROACH, ZONE_RIGHT_FLANK],
	ZONE_LEFT_FLANK: [ZONE_OUTER_FIELD, ZONE_CENTER_APPROACH, ZONE_WALL],
	ZONE_CENTER_APPROACH: [ZONE_OUTER_FIELD, ZONE_LEFT_FLANK, ZONE_RIGHT_FLANK, ZONE_GATE],
	ZONE_RIGHT_FLANK: [ZONE_OUTER_FIELD, ZONE_CENTER_APPROACH, ZONE_WALL],
	ZONE_WALL: [ZONE_LEFT_FLANK, ZONE_RIGHT_FLANK, ZONE_GATE, ZONE_FORTRESS],
	ZONE_GATE: [ZONE_CENTER_APPROACH, ZONE_WALL, ZONE_FORTRESS],
	ZONE_FORTRESS: [ZONE_WALL, ZONE_GATE]
}

var zone_id: String = ""
var zone_name: String = ""
var zone_type: String = ""
var adjacent_zones: Array[String] = []
var defense_bonus: float = 0.0
var range_bonus: float = 0.0
var is_fortress_interior: bool = false
var allow_player_deployment: bool = true


func _init(
	p_zone_id: String = "",
	p_zone_name: String = "",
	p_zone_type: String = "",
	p_adjacent_zones: Array = [],
	p_defense_bonus: float = 0.0,
	p_range_bonus: float = 0.0,
	p_is_interior: bool = false,
	p_allow_deploy: bool = true
) -> void:
	zone_id = p_zone_id.strip_edges().to_upper()
	zone_name = p_zone_name
	zone_type = p_zone_type
	if p_adjacent_zones.is_empty() and is_valid_zone(zone_id):
		adjacent_zones = get_canonical_adjacency(zone_id)
	else:
		adjacent_zones = _sanitize_adjacencies(p_adjacent_zones)
	defense_bonus = p_defense_bonus
	range_bonus = p_range_bonus
	is_fortress_interior = p_is_interior
	allow_player_deployment = p_allow_deploy


static func is_valid_zone(p_zone_id: String) -> bool:
	return p_zone_id.strip_edges().to_upper() in VALID_ZONES


static func get_canonical_adjacency(p_zone_id: String) -> Array[String]:
	var id: String = p_zone_id.strip_edges().to_upper()
	if CANONICAL_ADJACENCY.has(id):
		var raw: Array = CANONICAL_ADJACENCY[id]
		var typed_adj: Array[String] = []
		for item in raw:
			typed_adj.append(str(item))
		return typed_adj
	return []


static func are_adjacent(p_zone_a: String, p_zone_b: String) -> bool:
	var a: String = p_zone_a.strip_edges().to_upper()
	var b: String = p_zone_b.strip_edges().to_upper()
	if not is_valid_zone(a) or not is_valid_zone(b):
		return false
	if a == b:
		return false
	var adj: Array[String] = get_canonical_adjacency(a)
	return b in adj


static func get_default_definition(p_zone_id: String) -> Dictionary:
	match p_zone_id.strip_edges().to_upper():
		ZONE_OUTER_FIELD:
			return {
				"name": "Outer Field",
				"type": TYPE_FIELD,
				"defense_bonus": 0.0,
				"range_bonus": 0.0,
				"is_fortress_interior": false,
				"allow_player_deployment": false
			}
		ZONE_LEFT_FLANK:
			return {
				"name": "Left Flank",
				"type": TYPE_FLANK,
				"defense_bonus": 0.0,
				"range_bonus": 0.0,
				"is_fortress_interior": false,
				"allow_player_deployment": true
			}
		ZONE_CENTER_APPROACH:
			return {
				"name": "Center Approach",
				"type": TYPE_APPROACH,
				"defense_bonus": 0.0,
				"range_bonus": 0.0,
				"is_fortress_interior": false,
				"allow_player_deployment": true
			}
		ZONE_RIGHT_FLANK:
			return {
				"name": "Right Flank",
				"type": TYPE_FLANK,
				"defense_bonus": 0.0,
				"range_bonus": 0.0,
				"is_fortress_interior": false,
				"allow_player_deployment": true
			}
		ZONE_WALL:
			return {
				"name": "Wall Ramparts",
				"type": TYPE_DEFENSE,
				"defense_bonus": 0.25,
				"range_bonus": 0.30,
				"is_fortress_interior": false,
				"allow_player_deployment": true
			}
		ZONE_GATE:
			return {
				"name": "Main Gate",
				"type": TYPE_DEFENSE,
				"defense_bonus": 0.40,
				"range_bonus": 0.0,
				"is_fortress_interior": false,
				"allow_player_deployment": true
			}
		ZONE_FORTRESS:
			return {
				"name": "Fortress Courtyard",
				"type": TYPE_CORE,
				"defense_bonus": 0.0,
				"range_bonus": 0.0,
				"is_fortress_interior": true,
				"allow_player_deployment": true
			}
		_:
			return {}


static func create_canonical_zone(p_zone_id: String) -> BattlefieldZone:
	var id: String = p_zone_id.strip_edges().to_upper()
	if not is_valid_zone(id):
		return null
	var def: Dictionary = get_default_definition(id)
	return BattlefieldZone.new(
		id,
		str(def.get("name", id)),
		str(def.get("type", TYPE_FIELD)),
		get_canonical_adjacency(id),
		float(def.get("defense_bonus", 0.0)),
		float(def.get("range_bonus", 0.0)),
		bool(def.get("is_fortress_interior", false)),
		bool(def.get("allow_player_deployment", true))
	)


static func get_all_canonical_zones() -> Array[BattlefieldZone]:
	var zones: Array[BattlefieldZone] = []
	for zid in VALID_ZONES:
		var z: BattlefieldZone = create_canonical_zone(zid)
		if z != null:
			zones.append(z)
	return zones


func is_adjacent_to(target_zone_id: String) -> bool:
	var target: String = target_zone_id.strip_edges().to_upper()
	return target in adjacent_zones


func validate_invariants() -> bool:
	if not is_valid_zone(zone_id):
		return false
	if zone_name.strip_edges().is_empty():
		return false
	if not (zone_type in VALID_TYPES):
		return false
	if defense_bonus < 0.0:
		return false
	if range_bonus < 0.0:
		return false
	# Zone id tidak boleh mereferensi dirinya sendiri di daftar adjacent
	if zone_id in adjacent_zones:
		return false
	# Seluruh adjacent_zones harus berupa zona kanonikal valid tanpa duplikat
	var seen: Dictionary = {}
	for adj in adjacent_zones:
		if not is_valid_zone(adj):
			return false
		if seen.has(adj):
			return false
		seen[adj] = true
	# Interior benteng hanya untuk ZONE_FORTRESS
	if is_fortress_interior and zone_id != ZONE_FORTRESS:
		return false
	return true


func clone() -> BattlefieldZone:
	var copy_adj: Array[String] = []
	for adj in adjacent_zones:
		copy_adj.append(adj)
	return BattlefieldZone.new(
		zone_id,
		zone_name,
		zone_type,
		copy_adj,
		defense_bonus,
		range_bonus,
		is_fortress_interior,
		allow_player_deployment
	)


func to_dictionary() -> Dictionary:
	var adj_copy: Array = []
	for a in adjacent_zones:
		adj_copy.append(a)
	return {
		"zone_id": zone_id,
		"zone_name": zone_name,
		"zone_type": zone_type,
		"adjacent_zones": adj_copy,
		"defense_bonus": defense_bonus,
		"range_bonus": range_bonus,
		"is_fortress_interior": is_fortress_interior,
		"allow_player_deployment": allow_player_deployment
	}


static func from_dictionary(dict: Dictionary) -> BattlefieldZone:
	if dict.is_empty():
		return null
	var zid: String = str(dict.get("zone_id", "")).strip_edges().to_upper()
	var zname: String = str(dict.get("zone_name", ""))
	var ztype: String = str(dict.get("zone_type", ""))
	var zadj: Array = dict.get("adjacent_zones", [])
	var def_bonus: float = float(dict.get("defense_bonus", 0.0))
	var rng_bonus: float = float(dict.get("range_bonus", 0.0))
	var is_int: bool = bool(dict.get("is_fortress_interior", false))
	var allow_dep: bool = bool(dict.get("allow_player_deployment", true))
	return BattlefieldZone.new(zid, zname, ztype, zadj, def_bonus, rng_bonus, is_int, allow_dep)


static func _sanitize_adjacencies(raw_adj: Array) -> Array[String]:
	var result: Array[String] = []
	var seen: Dictionary = {}
	for item in raw_adj:
		var s: String = str(item).strip_edges().to_upper()
		if s != "" and not seen.has(s):
			seen[s] = true
			result.append(s)
	return result
