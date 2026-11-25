class_name GameStateSnapshot
extends RefCounted

## GameStateSnapshot
## Murni merepresentasikan snapshot data state game (domain layer).
## Tidak memiliki dependensi ke Node, SceneTree, UI, rendering, atau file I/O.

var tick: int = 0
var session_id: String = ""
var state_name: String = "INITIAL"
var metadata: Dictionary = {}


func _init(p_tick: int = 0, p_session_id: String = "", p_state_name: String = "INITIAL", p_metadata: Dictionary = {}) -> void:
	tick = p_tick
	session_id = p_session_id
	state_name = p_state_name
	metadata = p_metadata.duplicate(true)


func clone() -> GameStateSnapshot:
	return GameStateSnapshot.new(tick, session_id, state_name, metadata)


func to_dictionary() -> Dictionary:
	return {
		"tick": tick,
		"session_id": session_id,
		"state_name": state_name,
		"metadata": metadata.duplicate(true)
	}


static func from_dictionary(data: Dictionary) -> GameStateSnapshot:
	var p_tick: int = int(data.get("tick", 0))
	var p_session_id: String = str(data.get("session_id", ""))
	var p_state_name: String = str(data.get("state_name", "INITIAL"))
	var p_metadata: Dictionary = {}
	if data.has("metadata") and data["metadata"] is Dictionary:
		p_metadata = (data["metadata"] as Dictionary).duplicate(true)
	
	return GameStateSnapshot.new(p_tick, p_session_id, p_state_name, p_metadata)
