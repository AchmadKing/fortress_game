class_name SimulationRunner
extends RefCounted

## SimulationRunner
## Mendemonstrasikan boundary layer simulasi murni.
## Tidak mengandalkan _process(), frame rendering, atau SceneTree.
## Dapat dijalankan secara deterministik dan diuji secara headless.
## Diperluas di Phase 3 sebagai boundary pemanggilan engine simulasi Phase 2
## (WaveGenerator, CombatEngine, EconomyManager) tanpa menduplikasi formula matematika.

const WaveGeneratorScript = preload("res://scripts/simulation/wave_generator.gd")
const CombatEngineScript = preload("res://scripts/simulation/combat_engine.gd")
const EconomyManagerScript = preload("res://scripts/simulation/economy_manager.gd")
const PopulationModelScript = preload("res://scripts/domain/model/population_model.gd")
const FortressModelScript = preload("res://scripts/domain/model/fortress_model.gd")


func step(current_state: GameStateSnapshot, delta_tick: int = 1) -> GameStateSnapshot:
	assert(current_state != null, "current_state tidak boleh null")
	assert(delta_tick >= 0, "delta_tick tidak boleh negatif")
	
	var next_state: GameStateSnapshot = current_state.clone()
	next_state.tick += delta_tick
	
	return next_state


func is_deterministic() -> bool:
	return true


## Menghasilkan data gelombang musuh melalui WaveGenerator Phase 2
func prepare_wave(wave_num: int, seed_val: int = 12345) -> Dictionary:
	var gen: WaveGenerator = WaveGenerator.new()
	return gen.generate_wave(wave_num, seed_val)


## Menjalankan pertempuran multi-fase melalui CombatEngine Phase 2
func run_battle(population: PopulationModel, heroes: Array, warehouse: Array, fortress: FortressModel, wave_data: Dictionary, seed_val: int = 42) -> Dictionary:
	var engine: CombatEngine = CombatEngine.new()
	return engine.simulate_battle(population, heroes, warehouse, fortress, wave_data, seed_val)


## Menjalankan siklus ekonomi dan reparasi benteng melalui EconomyManager Phase 2
func run_economy_cycle(population: PopulationModel, fortress: FortressModel, economy: EconomyManager) -> Dictionary:
	return economy.process_cycle(population, fortress)
