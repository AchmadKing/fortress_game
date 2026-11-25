class_name GameConfigResource
extends Resource

## GameConfigResource
## Contoh representasi data definition / static configuration berbasis Godot Resource.
## Digunakan hanya sebagai wadah data konfigurasi statis, BUKAN tempat logika gameplay atau rendering.

@export var config_id: String = ""
@export var version: int = 1
@export var title: String = ""
@export var parameters: Dictionary = {}


func _init(p_config_id: String = "", p_title: String = "", p_version: int = 1, p_parameters: Dictionary = {}) -> void:
	config_id = p_config_id
	title = p_title
	version = p_version
	parameters = p_parameters.duplicate(true)
