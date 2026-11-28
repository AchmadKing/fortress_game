class_name GameStateSnapshot
extends RefCounted

## GameStateSnapshot
## Murni merepresentasikan snapshot data state game (domain layer).
## Tidak memiliki dependensi ke Node, SceneTree, UI, rendering, atau file I/O.
## Diperluas di Phase 3 untuk menampung model benteng, populasi, pahlawan, gudang senjata, bendahara.
## Diperluas di Phase 4 untuk menampung data regu (parties_data), chemistry, talent, dan skill.
## Diperluas di Phase 5 untuk menampung data tenaga kerja (worker_data), fasilitas (buildings_data),
## serta status perbaikan dan konstruksi aktif.

# Phase 1 Core Fields
var tick: int = 0
var session_id: String = ""
var state_name: String = "INITIAL"
var metadata: Dictionary = {}

# Phase 3 Gameplay Prototype Structured Fields
var current_wave: int = 1
var game_phase: String = "BOOT"
var fortress_data: Dictionary = {}
var population_data: Dictionary = {}
var heroes_data: Array = []
var parties_data: Array = []
var warehouse_data: Array = []
var economy_data: Dictionary = {}
var current_wave_data: Dictionary = {}
var last_battle_result: Dictionary = {}
var last_commander_command: Dictionary = {}
var battle_speed: float = 1.0
var battle_paused: bool = false
var battle_phase_name: String = ""
var battle_tick: int = 0

# Phase 3B Temporary Soldier Deployment Fields
var active_deployments_data: Array = []
var available_soldiers_count: int = 0
var total_living_soldiers_count: int = 0
var deployed_soldiers_count: int = 0

# Phase 5 Fortress & Management Systems Fields
var worker_data: Dictionary = {}
var buildings_data: Array = []
var active_repair_data: Dictionary = {}
var active_construction_data: Dictionary = {}

# Phase 6C Battlefield Participation & Aura Fields
var battle_deployments_data: Array = []
var battle_party_data: Dictionary = {}
var battle_aura_data: Dictionary = {}

# Phase 6D Commander Commands Execution Fields
var command_history: Array = []
var active_commander_intents: Dictionary = {}

# Phase 6E Fortress Damage Routing & Casualty Resolution Fields
var enemy_groups_data: Array = []
var battle_zone_pressure: Dictionary = {}
var accumulated_pressure: Dictionary = {}
var battle_casualties: Dictionary = {}
var wall_hp: int = 500
var gate_hp: int = 300
var fortress_hp: int = 1000
var battle_heroes_killed: Array = []
var battle_is_finished: bool = false
var battle_victory: bool = false

# Phase 7A Resource Authority & Economy Domain Model Fields
var resources_data: Dictionary = {}


func _init(p_tick: int = 0, p_session_id: String = "", p_state_name: String = "INITIAL", p_metadata: Dictionary = {}) -> void:
	tick = p_tick
	session_id = p_session_id
	state_name = p_state_name
	metadata = p_metadata.duplicate(true)
	game_phase = p_state_name if p_state_name != "INITIAL" else "BOOT"
	current_wave = 1
	fortress_data = {}
	population_data = {}
	heroes_data = []
	parties_data = []
	warehouse_data = []
	economy_data = {}
	current_wave_data = {}
	last_battle_result = {}
	last_commander_command = {}
	battle_speed = 1.0
	battle_paused = false
	battle_phase_name = ""
	active_deployments_data = []
	available_soldiers_count = 0
	total_living_soldiers_count = 0
	deployed_soldiers_count = 0
	worker_data = {}
	buildings_data = []
	active_repair_data = {}
	active_construction_data = {}
	resources_data = {
		"GOLD": 150,
		"MONSTER_CORE": 0,
		"MONSTER_MATERIAL": 0,
		"BASIC_MATERIAL": 0,
		"RARE_MATERIAL": 0
	}


func clone() -> GameStateSnapshot:
	var copy := GameStateSnapshot.new(tick, session_id, state_name, metadata)
	copy.current_wave = current_wave
	copy.game_phase = game_phase
	copy.fortress_data = fortress_data.duplicate(true)
	copy.population_data = population_data.duplicate(true)
	copy.heroes_data = heroes_data.duplicate(true)
	copy.parties_data = parties_data.duplicate(true)
	copy.warehouse_data = warehouse_data.duplicate(true)
	copy.economy_data = economy_data.duplicate(true)
	copy.current_wave_data = current_wave_data.duplicate(true)
	copy.last_battle_result = last_battle_result.duplicate(true)
	copy.last_commander_command = last_commander_command.duplicate(true)
	copy.battle_speed = battle_speed
	copy.battle_paused = battle_paused
	copy.battle_phase_name = battle_phase_name
	copy.battle_tick = battle_tick
	copy.active_deployments_data = active_deployments_data.duplicate(true)
	copy.available_soldiers_count = available_soldiers_count
	copy.total_living_soldiers_count = total_living_soldiers_count
	copy.deployed_soldiers_count = deployed_soldiers_count
	copy.worker_data = worker_data.duplicate(true)
	copy.buildings_data = buildings_data.duplicate(true)
	copy.active_repair_data = active_repair_data.duplicate(true)
	copy.active_construction_data = active_construction_data.duplicate(true)
	copy.battle_deployments_data = battle_deployments_data.duplicate(true)
	copy.battle_party_data = battle_party_data.duplicate(true)
	copy.battle_aura_data = battle_aura_data.duplicate(true)
	copy.command_history = command_history.duplicate(true)
	copy.active_commander_intents = active_commander_intents.duplicate(true)
	copy.enemy_groups_data = enemy_groups_data.duplicate(true)
	copy.battle_zone_pressure = battle_zone_pressure.duplicate(true)
	copy.accumulated_pressure = accumulated_pressure.duplicate(true)
	copy.battle_casualties = battle_casualties.duplicate(true)
	copy.wall_hp = wall_hp
	copy.gate_hp = gate_hp
	copy.fortress_hp = fortress_hp
	copy.battle_heroes_killed = battle_heroes_killed.duplicate(true)
	copy.battle_is_finished = battle_is_finished
	copy.battle_victory = battle_victory
	copy.resources_data = resources_data.duplicate(true)
	return copy


func to_dictionary() -> Dictionary:
	return {
		"tick": tick,
		"session_id": session_id,
		"state_name": state_name,
		"metadata": metadata.duplicate(true),
		"current_wave": current_wave,
		"game_phase": game_phase,
		"fortress_data": fortress_data.duplicate(true),
		"population_data": population_data.duplicate(true),
		"heroes_data": heroes_data.duplicate(true),
		"parties_data": parties_data.duplicate(true),
		"warehouse_data": warehouse_data.duplicate(true),
		"economy_data": economy_data.duplicate(true),
		"current_wave_data": current_wave_data.duplicate(true),
		"last_battle_result": last_battle_result.duplicate(true),
		"last_commander_command": last_commander_command.duplicate(true),
		"battle_speed": battle_speed,
		"battle_paused": battle_paused,
		"battle_phase_name": battle_phase_name,
		"battle_tick": battle_tick,
		"active_deployments_data": active_deployments_data.duplicate(true),
		"available_soldiers_count": available_soldiers_count,
		"total_living_soldiers_count": total_living_soldiers_count,
		"deployed_soldiers_count": deployed_soldiers_count,
		"worker_data": worker_data.duplicate(true),
		"buildings_data": buildings_data.duplicate(true),
		"active_repair_data": active_repair_data.duplicate(true),
		"active_construction_data": active_construction_data.duplicate(true),
		"battle_deployments_data": battle_deployments_data.duplicate(true),
		"battle_party_data": battle_party_data.duplicate(true),
		"battle_aura_data": battle_aura_data.duplicate(true),
		"command_history": command_history.duplicate(true),
		"active_commander_intents": active_commander_intents.duplicate(true),
		"enemy_groups_data": enemy_groups_data.duplicate(true),
		"battle_zone_pressure": battle_zone_pressure.duplicate(true),
		"accumulated_pressure": accumulated_pressure.duplicate(true),
		"battle_casualties": battle_casualties.duplicate(true),
		"wall_hp": wall_hp,
		"gate_hp": gate_hp,
		"fortress_hp": fortress_hp,
		"battle_heroes_killed": battle_heroes_killed.duplicate(true),
		"battle_is_finished": battle_is_finished,
		"battle_victory": battle_victory,
		"resources_data": resources_data.duplicate(true)
	}


static func from_dictionary(data: Dictionary) -> GameStateSnapshot:
	var p_tick: int = int(data.get("tick", 0))
	var p_session_id: String = str(data.get("session_id", ""))
	var p_state_name: String = str(data.get("state_name", "INITIAL"))
	var p_metadata: Dictionary = {}
	if data.has("metadata") and data["metadata"] is Dictionary:
		p_metadata = (data["metadata"] as Dictionary).duplicate(true)
	
	var snapshot := GameStateSnapshot.new(p_tick, p_session_id, p_state_name, p_metadata)
	snapshot.current_wave = int(data.get("current_wave", 1))
	snapshot.game_phase = str(data.get("game_phase", snapshot.state_name))
	
	if data.has("fortress_data") and data["fortress_data"] is Dictionary:
		snapshot.fortress_data = (data["fortress_data"] as Dictionary).duplicate(true)
	if data.has("population_data") and data["population_data"] is Dictionary:
		snapshot.population_data = (data["population_data"] as Dictionary).duplicate(true)
	if data.has("heroes_data") and data["heroes_data"] is Array:
		snapshot.heroes_data = (data["heroes_data"] as Array).duplicate(true)
	if data.has("parties_data") and data["parties_data"] is Array:
		snapshot.parties_data = (data["parties_data"] as Array).duplicate(true)
	if data.has("warehouse_data") and data["warehouse_data"] is Array:
		snapshot.warehouse_data = (data["warehouse_data"] as Array).duplicate(true)
	if data.has("economy_data") and data["economy_data"] is Dictionary:
		snapshot.economy_data = (data["economy_data"] as Dictionary).duplicate(true)
	if data.has("current_wave_data") and data["current_wave_data"] is Dictionary:
		snapshot.current_wave_data = (data["current_wave_data"] as Dictionary).duplicate(true)
	if data.has("last_battle_result") and data["last_battle_result"] is Dictionary:
		snapshot.last_battle_result = (data["last_battle_result"] as Dictionary).duplicate(true)
	if data.has("last_commander_command") and data["last_commander_command"] is Dictionary:
		snapshot.last_commander_command = (data["last_commander_command"] as Dictionary).duplicate(true)
		
	snapshot.battle_speed = float(data.get("battle_speed", 1.0))
	snapshot.battle_paused = bool(data.get("battle_paused", false))
	snapshot.battle_phase_name = str(data.get("battle_phase_name", ""))
	snapshot.battle_tick = int(data.get("battle_tick", 0))
	
	if data.has("active_deployments_data") and data["active_deployments_data"] is Array:
		snapshot.active_deployments_data = (data["active_deployments_data"] as Array).duplicate(true)
	snapshot.available_soldiers_count = int(data.get("available_soldiers_count", 0))
	snapshot.total_living_soldiers_count = int(data.get("total_living_soldiers_count", 0))
	snapshot.deployed_soldiers_count = int(data.get("deployed_soldiers_count", 0))
	
	if data.has("worker_data") and data["worker_data"] is Dictionary:
		snapshot.worker_data = (data["worker_data"] as Dictionary).duplicate(true)
	if data.has("buildings_data") and data["buildings_data"] is Array:
		snapshot.buildings_data = (data["buildings_data"] as Array).duplicate(true)
	if data.has("active_repair_data") and data["active_repair_data"] is Dictionary:
		snapshot.active_repair_data = (data["active_repair_data"] as Dictionary).duplicate(true)
	if data.has("active_construction_data") and data["active_construction_data"] is Dictionary:
		snapshot.active_construction_data = (data["active_construction_data"] as Dictionary).duplicate(true)
	
	if data.has("battle_deployments_data") and data["battle_deployments_data"] is Array:
		snapshot.battle_deployments_data = (data["battle_deployments_data"] as Array).duplicate(true)
	if data.has("battle_party_data") and data["battle_party_data"] is Dictionary:
		snapshot.battle_party_data = (data["battle_party_data"] as Dictionary).duplicate(true)
	if data.has("battle_aura_data") and data["battle_aura_data"] is Dictionary:
		snapshot.battle_aura_data = (data["battle_aura_data"] as Dictionary).duplicate(true)
	if data.has("command_history") and data["command_history"] is Array:
		snapshot.command_history = (data["command_history"] as Array).duplicate(true)
	if data.has("active_commander_intents") and data["active_commander_intents"] is Dictionary:
		snapshot.active_commander_intents = (data["active_commander_intents"] as Dictionary).duplicate(true)
	
	if data.has("enemy_groups_data") and data["enemy_groups_data"] is Array:
		snapshot.enemy_groups_data = (data["enemy_groups_data"] as Array).duplicate(true)
	if data.has("battle_zone_pressure") and data["battle_zone_pressure"] is Dictionary:
		snapshot.battle_zone_pressure = (data["battle_zone_pressure"] as Dictionary).duplicate(true)
	if data.has("accumulated_pressure") and data["accumulated_pressure"] is Dictionary:
		snapshot.accumulated_pressure = (data["accumulated_pressure"] as Dictionary).duplicate(true)
	if data.has("battle_casualties") and data["battle_casualties"] is Dictionary:
		snapshot.battle_casualties = (data["battle_casualties"] as Dictionary).duplicate(true)
	snapshot.wall_hp = int(data.get("wall_hp", 500))
	snapshot.gate_hp = int(data.get("gate_hp", 300))
	snapshot.fortress_hp = int(data.get("fortress_hp", 1000))
	if data.has("battle_heroes_killed") and data["battle_heroes_killed"] is Array:
		snapshot.battle_heroes_killed = (data["battle_heroes_killed"] as Array).duplicate(true)
	snapshot.battle_is_finished = bool(data.get("battle_is_finished", false))
	snapshot.battle_victory = bool(data.get("battle_victory", false))
	if data.has("resources_data") and data["resources_data"] is Dictionary:
		snapshot.resources_data = (data["resources_data"] as Dictionary).duplicate(true)
	
	return snapshot
