class_name CommanderCommand
extends RefCounted

## CommanderCommand
## Data Transfer Object untuk intensi taktis komandan benteng (Phase 3).
## Mendukung 6 jenis perintah: HOLD, ADVANCE, RETREAT, PROTECT, FOCUS, FOLLOW.
## Sesuai batasan Phase 3, kelas ini adalah pipeline validation/intent DTO
## tanpa formula numerik final (efek taktis detail ditunda ke Phase 6).

const TYPE_HOLD = "HOLD"
const TYPE_ADVANCE = "ADVANCE"
const TYPE_RETREAT = "RETREAT"
const TYPE_PROTECT = "PROTECT"
const TYPE_FOCUS = "FOCUS"
const TYPE_FOLLOW = "FOLLOW"

const VALID_TYPES: Array = [
	TYPE_HOLD,
	TYPE_ADVANCE,
	TYPE_RETREAT,
	TYPE_PROTECT,
	TYPE_FOCUS,
	TYPE_FOLLOW
]

var command_type: String = TYPE_HOLD
var target_group: String = "ALL" # ALL, SHIELD, MELEE, ARCHER, HEROES
var target_id: String = ""       # ID target opsional (hero_id atau enemy archetype)
var issued_at_tick: int = 0
var status: String = "REGISTERED" # REGISTERED, DEFERRED, NO_OP


func _init(p_type: String = TYPE_HOLD, p_group: String = "ALL", p_target: String = "", p_tick: int = 0) -> void:
	command_type = p_type
	target_group = p_group
	target_id = p_target
	issued_at_tick = p_tick
	status = "REGISTERED"


static func is_valid_type(type: String) -> bool:
	return type in VALID_TYPES


func clone() -> CommanderCommand:
	var cmd := CommanderCommand.new(command_type, target_group, target_id, issued_at_tick)
	cmd.status = status
	return cmd


func to_dictionary() -> Dictionary:
	return {
		"command_type": command_type,
		"target_group": target_group,
		"target_id": target_id,
		"issued_at_tick": issued_at_tick,
		"status": status
	}


static func from_dictionary(data: Dictionary) -> CommanderCommand:
	var p_type: String = str(data.get("command_type", TYPE_HOLD))
	var p_group: String = str(data.get("target_group", "ALL"))
	var p_target: String = str(data.get("target_id", ""))
	var p_tick: int = int(data.get("issued_at_tick", 0))
	var cmd := CommanderCommand.new(p_type, p_group, p_target, p_tick)
	cmd.status = str(data.get("status", "REGISTERED"))
	return cmd
