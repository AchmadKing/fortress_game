class_name SaveSnapshotDto
extends RefCounted

## SaveSnapshotDto
## Data Transfer Object untuk batas persistence (Save/Load boundary).
## Bertanggung jawab mengonversi domain snapshot menjadi plain data serializable.
## Memiliki schema_version dan menolak serialisasi Node/SceneTree.

const CURRENT_SCHEMA_VERSION: int = 1

var schema_version: int = CURRENT_SCHEMA_VERSION
var timestamp_utc: int = 0
var payload: Dictionary = {}


func _init(p_payload: Dictionary = {}, p_schema_version: int = CURRENT_SCHEMA_VERSION, p_timestamp: int = 0) -> void:
	schema_version = p_schema_version
	timestamp_utc = p_timestamp
	payload = p_payload.duplicate(true)


static func from_snapshot(snapshot: GameStateSnapshot) -> SaveSnapshotDto:
	assert(snapshot != null, "snapshot tidak boleh null")
	return SaveSnapshotDto.new(snapshot.to_dictionary(), CURRENT_SCHEMA_VERSION, 0)


func to_snapshot() -> GameStateSnapshot:
	assert(schema_version == CURRENT_SCHEMA_VERSION, "Schema version tidak kompatibel")
	return GameStateSnapshot.from_dictionary(payload)


func serialize() -> Dictionary:
	return {
		"schema_version": schema_version,
		"timestamp_utc": timestamp_utc,
		"payload": payload.duplicate(true)
	}


static func deserialize(data: Dictionary) -> SaveSnapshotDto:
	var version: int = int(data.get("schema_version", 0))
	if version != CURRENT_SCHEMA_VERSION:
		push_error("SaveSnapshotDto: Schema version mismatch. Expected %d, got %d" % [CURRENT_SCHEMA_VERSION, version])
		return null
		
	var timestamp: int = int(data.get("timestamp_utc", 0))
	var p_payload: Dictionary = {}
	if data.has("payload") and data["payload"] is Dictionary:
		p_payload = (data["payload"] as Dictionary).duplicate(true)
		
	return SaveSnapshotDto.new(p_payload, version, timestamp)
