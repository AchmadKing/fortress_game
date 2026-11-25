class_name GameCoordinator
extends RefCounted

## GameCoordinator
## Mendemonstrasikan koordinasi application layer dengan aliran data satu arah (Unidirectional Data Flow).
## Presentation/UI mengirim perintah (command) ke coordinator,
## coordinator menjalankan simulasi dan memutasi domain state,
## kemudian memancarkan signal reaktif untuk diobservasi oleh UI.

signal state_changed(new_snapshot: GameStateSnapshot)
signal step_completed(tick: int)

var _current_state: GameStateSnapshot
var _simulation_runner: SimulationRunner


func _init(initial_state: GameStateSnapshot = null, runner: SimulationRunner = null) -> void:
	if initial_state != null:
		_current_state = initial_state
	else:
		_current_state = GameStateSnapshot.new()
		
	if runner != null:
		_simulation_runner = runner
	else:
		_simulation_runner = SimulationRunner.new()


func get_current_state() -> GameStateSnapshot:
	# Mengembalikan clone agar external caller (UI) tidak dapat memutasi state internal secara langsung
	return _current_state.clone()


func initialize_session(session_id: String) -> void:
	_current_state.session_id = session_id
	_current_state.state_name = "ACTIVE"
	state_changed.emit(_current_state.clone())


func request_step(delta_tick: int = 1) -> void:
	_current_state = _simulation_runner.step(_current_state, delta_tick)
	step_completed.emit(_current_state.tick)
	state_changed.emit(_current_state.clone())
