extends SceneTree

## TestArchitectureBoundaries
## Test runner minimal untuk memvalidasi boundary arsitektur Phase 1 secara headless.
## Memvalidasi:
## 1. Domain state terisolasi tanpa Node/SceneTree.
## 2. Simulasi dapat berjalan secara deterministik dan headless.
## 3. Coordinator menjalankan aliran data satu arah (unidirectional data flow).
## 4. Persistence DTO memvalidasi serialisasi data plain dan versioning.
## 5. Config Resource beroperasi sebagai wadah data statis murni.

const GameStateSnapshotScript = preload("res://scripts/domain/state/game_state_snapshot.gd")
const GameConfigResourceScript = preload("res://scripts/domain/config/game_config_resource.gd")
const SimulationRunnerScript = preload("res://scripts/simulation/simulation_runner.gd")
const GameCoordinatorScript = preload("res://scripts/application/coordinators/game_coordinator.gd")
const SaveSnapshotDtoScript = preload("res://scripts/infrastructure/persistence/save_snapshot_dto.gd")


func _init() -> void:
	print("========================================")
	print("RUNNING ARCHITECTURE BOUNDARY TESTS (PHASE 1)")
	print("========================================")
	
	var passed: int = 0
	var failed: int = 0
	
	if _run_test("test_domain_isolation", Callable(self, "_test_domain_isolation")):
		passed += 1
	else:
		failed += 1
		
	if _run_test("test_simulation_determinism", Callable(self, "_test_simulation_determinism")):
		passed += 1
	else:
		failed += 1
		
	if _run_test("test_unidirectional_coordination", Callable(self, "_test_unidirectional_coordination")):
		passed += 1
	else:
		failed += 1
		
	if _run_test("test_persistence_dto_serialization", Callable(self, "_test_persistence_dto_serialization")):
		passed += 1
	else:
		failed += 1
		
	if _run_test("test_config_resource_isolation", Callable(self, "_test_config_resource_isolation")):
		passed += 1
	else:
		failed += 1
		
	print("========================================")
	print("TEST RESULTS: %d PASSED, %d FAILED" % [passed, failed])
	print("========================================")
	
	if failed == 0:
		quit(0)
	else:
		quit(1)


func _run_test(test_name: String, test_callable: Callable) -> bool:
	print("[TEST] Running %s..." % test_name)
	var result: bool = bool(test_callable.call())
	if result:
		print("[PASS] %s" % test_name)
	else:
		printerr("[FAIL] %s" % test_name)
	return result


func _test_domain_isolation() -> bool:
	var snapshot: GameStateSnapshot = GameStateSnapshot.new(0, "test_session", "ACTIVE", {"key": "val"})
	
	# Verifikasi tipe dan isolasi
	if not (snapshot is RefCounted):
		return false
	var obj: Object = snapshot
	if obj is Node:
		return false
		
	# Verifikasi data dan clone
	var cloned: GameStateSnapshot = snapshot.clone()
	if cloned.tick != 0 or cloned.session_id != "test_session":
		return false
		
	# Pastikan mutasi clone tidak mempengaruhi original
	cloned.tick = 42
	if snapshot.tick != 0:
		return false
		
	return true


func _test_simulation_determinism() -> bool:
	var runner: SimulationRunner = SimulationRunner.new()
	if not runner.is_deterministic():
		return false
		
	var initial_state: GameStateSnapshot = GameStateSnapshot.new(10, "sess_1")
	var next_state: GameStateSnapshot = runner.step(initial_state, 5)
	
	# Verifikasi determinisme murni
	if next_state.tick != 15:
		return false
	if initial_state.tick != 10: # Immutability contract
		return false
		
	# 10 langkah simulasi beruntun
	var current: GameStateSnapshot = initial_state
	for i in range(10):
		current = runner.step(current, 1)
	if current.tick != 20:
		return false
		
	return true


func _test_unidirectional_coordination() -> bool:
	var coordinator: GameCoordinator = GameCoordinator.new()
	var signal_received: Array = []
	
	coordinator.state_changed.connect(func(new_snapshot: GameStateSnapshot) -> void:
		signal_received.append(new_snapshot.tick)
	)
	
	coordinator.initialize_session("sess_alpha")
	var state: GameStateSnapshot = coordinator.get_current_state()
	if state.session_id != "sess_alpha" or state.state_name != "ACTIVE":
		return false
		
	coordinator.request_step(3)
	var updated_state: GameStateSnapshot = coordinator.get_current_state()
	if updated_state.tick != 3:
		return false
		
	if signal_received.size() < 2:
		return false
		
	return true


func _test_persistence_dto_serialization() -> bool:
	var snapshot: GameStateSnapshot = GameStateSnapshot.new(99, "save_sess", "SAVED", {"level": 5})
	var dto: SaveSnapshotDto = SaveSnapshotDto.from_snapshot(snapshot)
	
	if dto.schema_version != SaveSnapshotDto.CURRENT_SCHEMA_VERSION:
		return false
		
	var serialized: Dictionary = dto.serialize()
	if not serialized.has("schema_version") or not serialized.has("payload"):
		return false
		
	# Deserialisasi kembali
	var deserialized: SaveSnapshotDto = SaveSnapshotDto.deserialize(serialized)
	if deserialized == null:
		return false
		
	var restored_snapshot: GameStateSnapshot = deserialized.to_snapshot()
	if restored_snapshot.tick != 99 or restored_snapshot.session_id != "save_sess":
		return false
	if int(restored_snapshot.metadata.get("level", 0)) != 5:
		return false
		
	# Verifikasi penolakan versi salah
	var invalid_version_data: Dictionary = serialized.duplicate(true)
	invalid_version_data["schema_version"] = 9999
	var invalid_dto: SaveSnapshotDto = SaveSnapshotDto.deserialize(invalid_version_data)
	if invalid_dto != null:
		return false # Harus null karena schema version mismatch
		
	return true


func _test_config_resource_isolation() -> bool:
	var config: GameConfigResource = GameConfigResource.new("cfg_01", "Core Config", 1, {"speed": 1.5})
	if not (config is Resource):
		return false
	var obj: Object = config
	if obj is Node:
		return false
	if config.config_id != "cfg_01" or config.version != 1:
		return false
		
	return true
