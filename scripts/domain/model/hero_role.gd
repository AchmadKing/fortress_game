class_name HeroRole
extends RefCounted

## HeroRole
## Representasi kanonikal peran pahlawan (domain layer).
## Mendefinisikan peran sah (KNIGHT, MAGE, ARCHER, PRIEST), validasi peran,
## dan aturan kompatibilitas perlengkapan Phase 3.

const KNIGHT: String = "KNIGHT"
const MAGE: String = "MAGE"
const ARCHER: String = "ARCHER"
const PRIEST: String = "PRIEST"

const ALL_ROLES: Array[String] = [
	KNIGHT,
	MAGE,
	ARCHER,
	PRIEST
]


## Memeriksa apakah nama peran valid dan terdaftar
static func is_valid_role(role_name: String) -> bool:
	var r: String = role_name.to_upper().strip_edges()
	if r.is_empty():
		return false
	return r in ALL_ROLES


## Mengembalikan nama peran kanonikal dalam huruf kapital bersih
static func get_canonical_role(role_name: String) -> String:
	var r: String = role_name.to_upper().strip_edges()
	if is_valid_role(r):
		return r
	return ""


## Mengembalikan daftar senjata primer yang kompatibel untuk peran
static func get_allowed_primary_equipment(role_name: String) -> Array[String]:
	var r: String = role_name.to_upper().strip_edges()
	match r:
		KNIGHT:
			return ["SWORD", "SPEAR"]
		ARCHER:
			return ["BOW"]
		MAGE:
			return ["SPEAR", "BOW", "SWORD"]
		PRIEST:
			return ["SWORD", "SPEAR"]
		_:
			return []


## Mengembalikan daftar perlengkapan sekunder yang kompatibel untuk peran
static func get_allowed_secondary_equipment(role_name: String) -> Array[String]:
	var r: String = role_name.to_upper().strip_edges()
	match r:
		KNIGHT:
			return ["SHIELD", "NONE"]
		ARCHER:
			return ["NONE"]
		MAGE:
			return ["NONE"]
		PRIEST:
			return ["SHIELD", "NONE"]
		_:
			return ["NONE"]


## Mengembalikan daftar zirah yang kompatibel untuk peran
static func get_allowed_armor_equipment(role_name: String) -> Array[String]:
	var r: String = role_name.to_upper().strip_edges()
	match r:
		KNIGHT:
			return ["HEAVY_ARMOR", "NONE"]
		ARCHER:
			return ["HEAVY_ARMOR", "NONE"]
		MAGE:
			return ["NONE"]
		PRIEST:
			return ["HEAVY_ARMOR", "NONE"]
		_:
			return ["NONE"]


## Validasi kompatibilitas slot perlengkapan untuk peran tertentu
static func is_equipment_compatible(role_name: String, slot: String, eq_type: String) -> bool:
	var r: String = role_name.to_upper().strip_edges()
	if not is_valid_role(r):
		return false
	var s: String = slot.to_upper().strip_edges()
	var eq: String = eq_type.to_upper().strip_edges()
	match s:
		"PRIMARY":
			return eq in get_allowed_primary_equipment(r)
		"SECONDARY":
			return eq in get_allowed_secondary_equipment(r)
		"ARMOR":
			return eq in get_allowed_armor_equipment(r)
		_:
			return false
