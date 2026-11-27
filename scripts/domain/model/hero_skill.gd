class_name HeroSkill
extends RefCounted

## HeroSkill
## Model data murni untuk keahlian (skill) pahlawan (Phase 4E).
## Menampung identitas, nama, peran yang disyaratkan, syarat level, tipe skill,
## dan pengali efektivitas (power multiplier).

const HeroRoleScript = preload("res://scripts/domain/model/hero_role.gd")

const TYPE_PASSIVE_STAT: String = "PASSIVE_STAT"
const TYPE_AURA: String = "AURA"

const ALL_SKILL_TYPES: Array[String] = [
	TYPE_PASSIVE_STAT,
	TYPE_AURA
]

var skill_id: String = ""
var skill_name: String = ""
var required_role: String = "KNIGHT"
var required_level: int = 1
var skill_type: String = TYPE_PASSIVE_STAT
var power_multiplier: float = 1.05


func _init(
	p_id: String = "",
	p_name: String = "",
	p_role: String = "KNIGHT",
	p_req_lvl: int = 1,
	p_type: String = TYPE_PASSIVE_STAT,
	p_multiplier: float = 1.05
) -> void:
	skill_id = p_id.strip_edges()
	skill_name = p_name.strip_edges()
	required_role = p_role.to_upper().strip_edges()
	required_level = p_req_lvl
	skill_type = p_type.to_upper().strip_edges()
	power_multiplier = p_multiplier


## Memvalidasi invarian model HeroSkill
func validate_invariants() -> bool:
	if skill_id.is_empty():
		return false
	if skill_name.is_empty():
		return false
	if not HeroRoleScript.is_valid_role(required_role):
		return false
	if required_level < 1:
		return false
	if not (skill_type in ALL_SKILL_TYPES):
		return false
	if power_multiplier <= 0.0:
		return false
	return true


## Menduplikasi instance HeroSkill
func clone() -> HeroSkill:
	return HeroSkill.new(
		skill_id,
		skill_name,
		required_role,
		required_level,
		skill_type,
		power_multiplier
	)


## Katalog Kanonikal Skill Phase 4E
## Menyediakan definisi skill kanonikal untuk setiap peran
static func get_canonical_catalog() -> Dictionary:
	return {
		# KNIGHT Skills
		"knight_offense": {
			"name": "Iron Edge",
			"role": HeroRoleScript.KNIGHT,
			"level": 3,
			"type": TYPE_PASSIVE_STAT,
			"multiplier": 1.05
		},
		"knight_defense": {
			"name": "Iron Guard",
			"role": HeroRoleScript.KNIGHT,
			"level": 5,
			"type": TYPE_PASSIVE_STAT,
			"multiplier": 1.05
		},
		"knight_leadership": {
			"name": "Battle Leadership",
			"role": HeroRoleScript.KNIGHT,
			"level": 10,
			"type": TYPE_AURA,
			"multiplier": 1.05
		},
		# ARCHER Skills
		"archer_offense": {
			"name": "Keen Shot",
			"role": HeroRoleScript.ARCHER,
			"level": 3,
			"type": TYPE_PASSIVE_STAT,
			"multiplier": 1.05
		},
		"archer_defense": {
			"name": "Evasive Step",
			"role": HeroRoleScript.ARCHER,
			"level": 5,
			"type": TYPE_PASSIVE_STAT,
			"multiplier": 1.05
		},
		"archer_leadership": {
			"name": "Hunter's Focus",
			"role": HeroRoleScript.ARCHER,
			"level": 10,
			"type": TYPE_AURA,
			"multiplier": 1.05
		},
		# MAGE Skills
		"mage_offense": {
			"name": "Arcane Power",
			"role": HeroRoleScript.MAGE,
			"level": 3,
			"type": TYPE_PASSIVE_STAT,
			"multiplier": 1.05
		},
		"mage_defense": {
			"name": "Arcane Ward",
			"role": HeroRoleScript.MAGE,
			"level": 5,
			"type": TYPE_PASSIVE_STAT,
			"multiplier": 1.05
		},
		"mage_leadership": {
			"name": "Arcane Resonance",
			"role": HeroRoleScript.MAGE,
			"level": 10,
			"type": TYPE_AURA,
			"multiplier": 1.05
		},
		# PRIEST Skills
		"priest_offense": {
			"name": "Holy Power",
			"role": HeroRoleScript.PRIEST,
			"level": 3,
			"type": TYPE_PASSIVE_STAT,
			"multiplier": 1.05
		},
		"priest_defense": {
			"name": "Divine Guard",
			"role": HeroRoleScript.PRIEST,
			"level": 5,
			"type": TYPE_PASSIVE_STAT,
			"multiplier": 1.05
		},
		"priest_leadership": {
			"name": "Divine Guidance",
			"role": HeroRoleScript.PRIEST,
			"level": 10,
			"type": TYPE_AURA,
			"multiplier": 1.05
		}
	}


## Memeriksa apakah suatu skill_id terdaftar dalam katalog kanonikal
static func is_canonical_skill(p_skill_id: String) -> bool:
	var id: String = p_skill_id.strip_edges().to_lower()
	return get_canonical_catalog().has(id)


## Mengambil instance HeroSkill kanonikal berdasarkan ID
static func get_canonical_skill(p_skill_id: String) -> HeroSkill:
	var id: String = p_skill_id.strip_edges().to_lower()
	var cat: Dictionary = get_canonical_catalog()
	if not cat.has(id):
		return null
	var data: Dictionary = cat[id]
	return HeroSkill.new(
		id,
		data["name"],
		data["role"],
		int(data["level"]),
		data["type"],
		float(data["multiplier"])
	)


## Mengambil seluruh daftar skill kanonikal untuk suatu peran
static func get_skills_for_role(p_role: String) -> Array:
	var r: String = p_role.to_upper().strip_edges()
	var result: Array = []
	var cat: Dictionary = get_canonical_catalog()
	for id in cat.keys():
		var data: Dictionary = cat[id]
		if data["role"] == r:
			result.append(get_canonical_skill(id))
	return result
