class_name CommanderCommand
extends RefCounted

## CommanderCommand
## Data Transfer Object untuk intensi taktis komandan benteng (Phase 3 & Phase 6D).
## Mendukung 7 perintah kanonikal:
## 1. ADVANCE: Bergerak maju menuju zona tetangga yang valid.
## 2. MOVE: Berpindah secara eksplisit ke zona tetangga yang valid.
## 3. HOLD_POSITION (HOLD): Mempertahankan posisi zona saat ini.
## 4. RETREAT: Mundur secara teratur ke zona pertahanan menuju benteng.
## 5. PROTECT: Menetapkan postur perlindungan terhadap zona/entitas kawan.
## 6. FOCUS_TARGET (FOCUS): Menetapkan prioritas target kelompok/arketipe musuh.
## 7. FOLLOW: Menugaskan unit untuk mengawal/mengikuti unit kawan valid.

const TYPE_HOLD = "HOLD"
const TYPE_HOLD_POSITION = "HOLD_POSITION"
const TYPE_MOVE = "MOVE"
const TYPE_ADVANCE = "ADVANCE"
const TYPE_RETREAT = "RETREAT"
const TYPE_PROTECT = "PROTECT"
const TYPE_FOCUS = "FOCUS"
const TYPE_FOCUS_TARGET = "FOCUS_TARGET"
const TYPE_FOLLOW = "FOLLOW"

const VALID_TYPES: Array[String] = [
	TYPE_HOLD_POSITION,
	TYPE_HOLD,
	TYPE_MOVE,
	TYPE_ADVANCE,
	TYPE_RETREAT,
	TYPE_PROTECT,
	TYPE_FOCUS_TARGET,
	TYPE_FOCUS,
	TYPE_FOLLOW
]

const CANONICAL_TYPES: Array[String] = [
	TYPE_ADVANCE,
	TYPE_MOVE,
	TYPE_HOLD_POSITION,
	TYPE_RETREAT,
	TYPE_PROTECT,
	TYPE_FOCUS_TARGET,
	TYPE_FOLLOW
]

var command_type: String = TYPE_HOLD_POSITION
var source_id: String = "party_1"
var target_group: String = "ALL"
var target_zone: String = ""
var target_enemy_id: String = ""
var target_enemy_type: String = ""
var target_entity_id: String = ""
var target_id: String = ""
var issued_at_battle_tick: int = 0
var issued_at_tick: int = 0
var sequence_id: int = 0
var status: String = "REGISTERED" # REGISTERED, EXECUTED, REJECTED, LOGGED_PHASE3_DEFERRED


func _init(
	p_type: String = TYPE_HOLD_POSITION,
	p_source_or_group: String = "party_1",
	p_target: String = "",
	p_tick: int = 0,
	p_target_zone: String = "",
	p_target_enemy: String = "",
	p_target_entity: String = ""
) -> void:
	command_type = p_type.strip_edges().to_upper()
	source_id = p_source_or_group.strip_edges() if not p_source_or_group.is_empty() else "party_1"
	target_group = source_id
	target_id = p_target.strip_edges()
	
	target_zone = p_target_zone.strip_edges().to_upper()
	if target_zone.is_empty() and (p_target.to_upper() in ["WALL", "GATE", "CENTER_APPROACH", "LEFT_FLANK", "RIGHT_FLANK", "FORTRESS", "OUTER_FIELD"]):
		target_zone = p_target.to_upper()
		
	target_enemy_id = p_target_enemy.strip_edges()
	target_enemy_type = target_enemy_id
	if target_enemy_id.is_empty() and (p_target.begins_with("enemy_") or p_target.begins_with("group_") or (p_target.to_upper() in ["GOBLIN_SWARM", "ORC_FRONTLINE", "GOBLIN_ARCHER", "TROLL_TANK", "SIEGE_MONSTER", "FLYING_BYPASS"])):
		target_enemy_id = p_target
		target_enemy_type = p_target
		
	target_entity_id = p_target_entity.strip_edges()
	if target_entity_id.is_empty() and (p_target.begins_with("comp_") or p_target == "party_1" or p_target == "party_2" or p_target.begins_with("hero_")):
		target_entity_id = p_target
		
	issued_at_battle_tick = maxi(0, p_tick)
	issued_at_tick = issued_at_battle_tick
	sequence_id = 0
	status = "REGISTERED"


static func is_valid_type(type: String) -> bool:
	return type.strip_edges().to_upper() in VALID_TYPES


static func normalize_type(p_type: String) -> String:
	var t: String = p_type.strip_edges().to_upper()
	match t:
		"HOLD", "HOLD_POSITION":
			return TYPE_HOLD_POSITION
		"FOCUS", "FOCUS_TARGET":
			return TYPE_FOCUS_TARGET
		"MOVE":
			return TYPE_MOVE
		"ADVANCE":
			return TYPE_ADVANCE
		"RETREAT":
			return TYPE_RETREAT
		"PROTECT":
			return TYPE_PROTECT
		"FOLLOW":
			return TYPE_FOLLOW
		_:
			return t


func clone() -> CommanderCommand:
	var copy := CommanderCommand.new(
		command_type,
		source_id,
		target_id,
		issued_at_battle_tick,
		target_zone,
		target_enemy_id,
		target_entity_id
	)
	copy.sequence_id = sequence_id
	copy.status = status
	return copy


func to_dictionary() -> Dictionary:
	return {
		"command_type": command_type,
		"source_id": source_id,
		"target_group": target_group,
		"target_zone": target_zone,
		"target_enemy_id": target_enemy_id,
		"target_enemy_type": target_enemy_type,
		"target_entity_id": target_entity_id,
		"target_id": target_id,
		"issued_at_battle_tick": issued_at_battle_tick,
		"issued_at_tick": issued_at_tick,
		"sequence_id": sequence_id,
		"status": status
	}


static func from_dictionary(data: Dictionary) -> CommanderCommand:
	var p_type: String = str(data.get("command_type", TYPE_HOLD_POSITION))
	var p_src: String = str(data.get("source_id", data.get("target_group", "party_1")))
	var p_target: String = str(data.get("target_id", ""))
	var p_tick: int = int(data.get("issued_at_battle_tick", data.get("issued_at_tick", 0)))
	var p_zone: String = str(data.get("target_zone", ""))
	var p_enemy: String = str(data.get("target_enemy_id", data.get("target_enemy_type", "")))
	var p_entity: String = str(data.get("target_entity_id", ""))
	
	var cmd := CommanderCommand.new(p_type, p_src, p_target, p_tick, p_zone, p_enemy, p_entity)
	cmd.sequence_id = int(data.get("sequence_id", 0))
	cmd.status = str(data.get("status", "REGISTERED"))
	return cmd
