class_name GameplayStateMachine
extends RefCounted

## GameplayStateMachine
## State Machine deterministik murni untuk mengatur otoritas transisi fase game (Phase 3).
## Memvalidasi rantai transisi yang sah dan menolak keras transisi ilegal.
## States: BOOT, PREPARATION, WAVE_PREVIEW, BATTLE, RESULT, RECOVERY, GAME_OVER.

signal state_changed(from_state: String, to_state: String)

const STATE_BOOT = "BOOT"
const STATE_PREPARATION = "PREPARATION"
const STATE_WAVE_PREVIEW = "WAVE_PREVIEW"
const STATE_BATTLE = "BATTLE"
const STATE_RESULT = "RESULT"
const STATE_RECOVERY = "RECOVERY"
const STATE_GAME_OVER = "GAME_OVER"

const ALL_STATES: Array = [
	STATE_BOOT,
	STATE_PREPARATION,
	STATE_WAVE_PREVIEW,
	STATE_BATTLE,
	STATE_RESULT,
	STATE_RECOVERY,
	STATE_GAME_OVER
]

const VALID_TRANSITIONS: Dictionary = {
	STATE_BOOT: [STATE_PREPARATION],
	STATE_PREPARATION: [STATE_WAVE_PREVIEW],
	STATE_WAVE_PREVIEW: [STATE_PREPARATION, STATE_BATTLE],
	STATE_BATTLE: [STATE_RESULT],
	STATE_RESULT: [STATE_RECOVERY, STATE_GAME_OVER],
	STATE_RECOVERY: [STATE_PREPARATION],
	STATE_GAME_OVER: [] # Terminal! Tidak bisa transisi keluar tanpa reboot sesi baru.
}

var current_state: String = STATE_BOOT


func _init(initial_state: String = STATE_BOOT) -> void:
	if initial_state in ALL_STATES:
		current_state = initial_state
	else:
		current_state = STATE_BOOT


func can_transition_to(target_state: String) -> bool:
	if not (target_state in ALL_STATES):
		return false
	var allowed_targets: Array = VALID_TRANSITIONS.get(current_state, [])
	return target_state in allowed_targets


func transition_to(target_state: String) -> bool:
	if not can_transition_to(target_state):
		push_warning("GameplayStateMachine: Transisi ilegal ditolak: %s -> %s" % [current_state, target_state])
		return false
	var previous: String = current_state
	current_state = target_state
	state_changed.emit(previous, current_state)
	return true


func reset(new_state: String = STATE_BOOT) -> void:
	var previous: String = current_state
	current_state = new_state if new_state in ALL_STATES else STATE_BOOT
	state_changed.emit(previous, current_state)
