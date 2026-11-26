class_name MainPrototype
extends Node

## MainPrototype
## Root scene untuk Phase 3 Playable Gameplay Prototype.
## Menginisialisasi GameCoordinator, GameController, dan PrototypeDebugView saat _ready().

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const PrototypeDebugView = preload("res://scripts/presentation/views/prototype_debug_view.gd")

var coordinator: GameCoordinator
var controller: GameController
var debug_view: PrototypeDebugView


func _ready() -> void:
	setup_session()


func setup_session() -> void:
	if coordinator != null:
		return
	controller = $GameController as GameController
	debug_view = $PrototypeDebugView as PrototypeDebugView
	
	coordinator = GameCoordinator.new()
	coordinator.start_new_session("session_playtest", 12345)
	
	if controller != null:
		controller.setup(coordinator)
	if debug_view != null:
		debug_view.setup(coordinator, controller)
