class_name HeroLifecycleState
extends RefCounted

## HeroLifecycleState
## Representasi kanonikal state siklus hidup pahlawan (domain layer).
## Mendefinisikan status sah pahlawan dan aturan transisi legal.

const RECRUITABLE: String = "RECRUITABLE"
const ROSTER_ACTIVE: String = "ROSTER_ACTIVE"
const IN_PARTY: String = "IN_PARTY"
const IN_TRAINING: String = "IN_TRAINING"
const BATTLE_ACTIVE: String = "BATTLE_ACTIVE"
const PERMADEATH: String = "PERMADEATH"

const ALL_STATES: Array[String] = [
	RECRUITABLE,
	ROSTER_ACTIVE,
	IN_PARTY,
	IN_TRAINING,
	BATTLE_ACTIVE,
	PERMADEATH
]

# Legal transitions mapping:
# from_state -> Array of legal target states
const LEGAL_TRANSITIONS: Dictionary = {
	RECRUITABLE: [ROSTER_ACTIVE],
	ROSTER_ACTIVE: [IN_PARTY, IN_TRAINING],
	IN_PARTY: [ROSTER_ACTIVE, BATTLE_ACTIVE],
	IN_TRAINING: [ROSTER_ACTIVE],
	BATTLE_ACTIVE: [IN_PARTY, PERMADEATH],
	PERMADEATH: [] # PERMADEATH is terminal!
}


## Memeriksa apakah status siklus hidup valid
static func is_valid_state(state_name: String) -> bool:
	var s: String = state_name.to_upper().strip_edges()
	if s.is_empty():
		return false
	return s in ALL_STATES


## Mengembalikan nama state kanonikal dalam huruf kapital bersih
static func get_canonical_state(state_name: String) -> String:
	var s: String = state_name.to_upper().strip_edges()
	if is_valid_state(s):
		return s
	return ""


## Memeriksa apakah state merupakan terminal (PERMADEATH)
static func is_terminal(state_name: String) -> bool:
	return state_name.to_upper().strip_edges() == PERMADEATH


## Memvalidasi apakah transisi dari from_state ke to_state diizinkan
static func can_transition(from_state: String, to_state: String) -> bool:
	var f: String = from_state.to_upper().strip_edges()
	var t: String = to_state.to_upper().strip_edges()
	if not is_valid_state(f) or not is_valid_state(t):
		return false
	if f == PERMADEATH:
		return false # Dead heroes cannot transition to any active state
	var allowed: Array = LEGAL_TRANSITIONS.get(f, [])
	return t in allowed
