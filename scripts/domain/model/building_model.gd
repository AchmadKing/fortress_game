class_name BuildingModel
extends RefCounted

## BuildingModel
## Model representasi fasilitas fisik benteng (domain layer).
## Mengelola identitas, tipe kanonikal, tingkat fasilitas, status terbangun, dan validasi invarian.

const TYPE_FORTRESS = "FORTRESS"
const TYPE_WALL = "WALL"
const TYPE_GATE = "GATE"
const TYPE_BARRACKS = "BARRACKS"
const TYPE_BLACKSMITH = "BLACKSMITH"
const TYPE_WAREHOUSE = "WAREHOUSE"
const TYPE_TRAINING_FACILITY = "TRAINING_FACILITY"
const TYPE_MERCENARY_GUILD = "MERCENARY_GUILD"
const TYPE_CONSTRUCTION_AREA = "CONSTRUCTION_AREA"

const VALID_TYPES: Array[String] = [
	TYPE_FORTRESS,
	TYPE_WALL,
	TYPE_GATE,
	TYPE_BARRACKS,
	TYPE_BLACKSMITH,
	TYPE_WAREHOUSE,
	TYPE_TRAINING_FACILITY,
	TYPE_MERCENARY_GUILD,
	TYPE_CONSTRUCTION_AREA
]

var building_id: String = ""
var building_type: String = ""
var building_name: String = ""
var level: int = 1
var is_built: bool = true
var max_level: int = 5


func _init(p_id: String, p_type: String, p_name: String = "", p_level: int = 1, p_is_built: bool = true, p_max_level: int = 5) -> void:
	building_id = p_id.strip_edges()
	building_type = p_type.to_upper().strip_edges()
	building_name = p_name if p_name != "" else _get_default_name(building_type)
	level = maxi(1, p_level)
	is_built = p_is_built
	max_level = maxi(1, p_max_level)


static func is_valid_type(t: String) -> bool:
	return t.to_upper().strip_edges() in VALID_TYPES


static func _get_default_name(t: String) -> String:
	match t.to_upper().strip_edges():
		TYPE_FORTRESS:
			return "Benteng Utama"
		TYPE_WALL:
			return "Tembok Pertahanan"
		TYPE_GATE:
			return "Gerbang Utama"
		TYPE_BARRACKS:
			return "Barak Militer"
		TYPE_BLACKSMITH:
			return "Pandai Besi"
		TYPE_WAREHOUSE:
			return "Gudang Senjata"
		TYPE_TRAINING_FACILITY:
			return "Fasilitas Latihan"
		TYPE_MERCENARY_GUILD:
			return "Mercenary Guild"
		TYPE_CONSTRUCTION_AREA:
			return "Area Pembangunan"
		_:
			return "Fasilitas Benteng"


func can_upgrade() -> bool:
	return is_built and level < max_level


func upgrade() -> bool:
	if not can_upgrade():
		return false
	level += 1
	return true


func validate_invariants() -> bool:
	if building_id == "":
		return false
	if not is_valid_type(building_type):
		return false
	if level < 1 or level > max_level:
		return false
	if max_level < 1:
		return false
	return true


func clone() -> BuildingModel:
	var b := BuildingModel.new(building_id, building_type, building_name, level, is_built, max_level)
	return b


func to_dictionary() -> Dictionary:
	return {
		"building_id": building_id,
		"building_type": building_type,
		"building_name": building_name,
		"level": level,
		"is_built": is_built,
		"max_level": max_level,
		"can_upgrade": can_upgrade()
	}


static func from_dictionary(dict: Dictionary) -> BuildingModel:
	var id: String = str(dict.get("building_id", ""))
	var type: String = str(dict.get("building_type", ""))
	var bname: String = str(dict.get("building_name", ""))
	var lvl: int = int(dict.get("level", 1))
	var built: bool = bool(dict.get("is_built", true))
	var mlvl: int = int(dict.get("max_level", 5))
	return BuildingModel.new(id, type, bname, lvl, built, mlvl)
