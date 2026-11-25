class_name SimulationRunner
extends RefCounted

## SimulationRunner
## Mendemonstrasikan boundary layer simulasi murni.
## Tidak mengandalkan _process(), frame rendering, atau SceneTree.
## Dapat dijalankan secara deterministik dan diuji secara headless.


func step(current_state: GameStateSnapshot, delta_tick: int = 1) -> GameStateSnapshot:
	assert(current_state != null, "current_state tidak boleh null")
	assert(delta_tick >= 0, "delta_tick tidak boleh negatif")
	
	var next_state: GameStateSnapshot = current_state.clone()
	next_state.tick += delta_tick
	
	return next_state


func is_deterministic() -> bool:
	return true
