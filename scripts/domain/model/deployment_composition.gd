class_name DeploymentComposition
extends RefCounted

## DeploymentComposition
## Model agregat regu penempatan tempur sementara berbasis gelombang (Phase 3B & 6C).
## Menyimpan jumlah prajurit, senjata primer (wajib), sekunder (opsional),
## zirah (opsional), identitas kanonikal regu, peran tempur turunan,
## daftar perlengkapan yang direservasi, serta zona penempatan dan formasi taktis (Phase 6C).

# Formasi Kanonikal Phase 6C
const FORMATION_FRONTLINE: String = "FRONTLINE"
const FORMATION_BACKLINE: String = "BACKLINE"
const FORMATION_SUPPORT: String = "SUPPORT"

const VALID_FORMATIONS: Array[String] = [
	FORMATION_FRONTLINE,
	FORMATION_BACKLINE,
	FORMATION_SUPPORT
]

var count: int = 0
var primary_weapon: String = "SWORD"    # REQUIRED: SWORD, SPEAR, BOW
var secondary_weapon: String = "NONE"   # OPTIONAL: SHIELD, NONE
var armor: String = "NONE"              # OPTIONAL: HEAVY_ARMOR, NONE
var composition_id: String = ""         # Canonical identity: primary|secondary|armor
var resolved_role: String = "SWORDSMAN" # Derived role for CombatEngine
var reserved_equipment: Array = []      # Array[EquipmentModel] instances reserved for this group
var current_zone: String = "GATE"       # Canonical battlefield zone (Phase 6C)
var formation: String = FORMATION_FRONTLINE # Canonical tactical stance (Phase 6C)
var tactical_intent: String = "HOLD_POSITION" # Canonical commander intent (Phase 6D)
var protected_target: String = ""
var focus_target: String = ""
var following_target: String = ""


func set_tactical_intent(intent: String, target: String = "") -> void:
	tactical_intent = intent.strip_edges().to_upper()
	match tactical_intent:
		"PROTECT":
			protected_target = target.strip_edges()
		"FOCUS", "FOCUS_TARGET":
			focus_target = target.strip_edges()
		"FOLLOW":
			following_target = target.strip_edges()


func reset_tactical_intent() -> void:
	tactical_intent = "HOLD_POSITION"
	protected_target = ""
	focus_target = ""
	following_target = ""


func _init(
	p_count: int = 0,
	p_primary: String = "SWORD",
	p_secondary: String = "NONE",
	p_armor: String = "NONE",
	p_zone: String = "",
	p_formation: String = ""
) -> void:
	count = maxi(0, p_count)
	primary_weapon = p_primary.to_upper().strip_edges()
	secondary_weapon = p_secondary.to_upper().strip_edges() if not p_secondary.is_empty() else "NONE"
	armor = p_armor.to_upper().strip_edges() if not p_armor.is_empty() else "NONE"
	composition_id = make_composition_id(primary_weapon, secondary_weapon, armor)
	resolved_role = resolve_role(primary_weapon, secondary_weapon, armor)
	reserved_equipment = []
	current_zone = p_zone.to_upper().strip_edges() if not p_zone.is_empty() else resolve_default_zone(resolved_role)
	formation = p_formation.to_upper().strip_edges() if not p_formation.is_empty() else resolve_default_formation(resolved_role)


static func resolve_default_formation(role: String) -> String:
	match role.to_upper().strip_edges():
		"ARCHER":
			return FORMATION_BACKLINE
		"SHIELD_INFANTRY", "HEAVY_INFANTRY", "SPEARMAN", "SWORDSMAN":
			return FORMATION_FRONTLINE
		_:
			return FORMATION_FRONTLINE


static func resolve_default_zone(role: String) -> String:
	match role.to_upper().strip_edges():
		"ARCHER":
			return "WALL"
		_:
			return "GATE"


func set_zone(new_zone: String) -> bool:
	var z: String = new_zone.to_upper().strip_edges()
	if z == "OUTER_FIELD" or z.is_empty():
		return false
	var valid_zones: Array[String] = ["LEFT_FLANK", "CENTER_APPROACH", "RIGHT_FLANK", "WALL", "GATE", "FORTRESS"]
	if not (z in valid_zones):
		return false
	current_zone = z
	return true


func set_formation(new_formation: String) -> bool:
	var f: String = new_formation.to_upper().strip_edges()
	if not (f in VALID_FORMATIONS):
		return false
	formation = f
	return true



static func make_composition_id(p_primary: String, p_secondary: String = "NONE", p_armor: String = "NONE") -> String:
	var p: String = p_primary.to_upper().strip_edges() if not p_primary.is_empty() else "NONE"
	var s: String = p_secondary.to_upper().strip_edges() if not p_secondary.is_empty() else "NONE"
	var a: String = p_armor.to_upper().strip_edges() if not p_armor.is_empty() else "NONE"
	return "%s|%s|%s" % [p, s, a]


static func resolve_role(p_primary: String, p_secondary: String = "NONE", p_armor: String = "NONE") -> String:
	var p: String = p_primary.to_upper().strip_edges()
	var s: String = p_secondary.to_upper().strip_edges()
	var a: String = p_armor.to_upper().strip_edges()

	# Aturan Presedensi Derivasi Peran (Phase 3B):
	# 1. SWORD + SHIELD (+ ANY ARMOR) -> SHIELD_INFANTRY
	if p == "SWORD" and s == "SHIELD":
		return "SHIELD_INFANTRY"
	# 2. SWORD + HEAVY_ARMOR (tanpa shield) -> HEAVY_INFANTRY
	elif p == "SWORD" and a == "HEAVY_ARMOR":
		return "HEAVY_INFANTRY"
	# 3. SPEAR (+ ANY) -> SPEARMAN
	elif p == "SPEAR":
		return "SPEARMAN"
	# 4. BOW (+ ANY) -> ARCHER
	elif p == "BOW":
		return "ARCHER"
	# 5. SWORD tunggal -> SWORDSMAN
	elif p == "SWORD":
		return "SWORDSMAN"
	else:
		return "SWORDSMAN"


func clone() -> RefCounted:
	var script = load("res://scripts/domain/model/deployment_composition.gd")
	var copy = script.new(count, primary_weapon, secondary_weapon, armor, current_zone, formation)
	copy.composition_id = composition_id
	copy.resolved_role = resolved_role
	copy.current_zone = current_zone
	copy.formation = formation
	copy.tactical_intent = tactical_intent
	copy.protected_target = protected_target
	copy.focus_target = focus_target
	copy.following_target = following_target
	copy.reserved_equipment = []
	for eq in reserved_equipment:
		if eq != null and eq.has_method("clone"):
			copy.reserved_equipment.append(eq.clone())
	return copy


func to_dictionary() -> Dictionary:
	var reserved_data: Array = []
	for eq in reserved_equipment:
		if eq != null:
			reserved_data.append({
				"role_type": eq.role_type,
				"tier": eq.tier,
				"durability": eq.durability,
				"max_durability": eq.max_durability,
				"quantity": eq.quantity,
				"is_broken": eq.is_broken()
			})
	return {
		"count": count,
		"primary_weapon": primary_weapon,
		"secondary_weapon": secondary_weapon,
		"armor": armor,
		"composition_id": composition_id,
		"resolved_role": resolved_role,
		"current_zone": current_zone,
		"formation": formation,
		"tactical_intent": tactical_intent,
		"protected_target": protected_target,
		"focus_target": focus_target,
		"following_target": following_target,
		"reserved_equipment": reserved_data
	}


static func from_dictionary(data: Dictionary) -> RefCounted:
	var p_count: int = int(data.get("count", 0))
	var p_primary: String = str(data.get("primary_weapon", "SWORD"))
	var p_secondary: String = str(data.get("secondary_weapon", "NONE"))
	var p_armor: String = str(data.get("armor", "NONE"))
	var p_zone: String = str(data.get("current_zone", "GATE"))
	var p_formation: String = str(data.get("formation", FORMATION_FRONTLINE))

	var script_res = load("res://scripts/domain/model/deployment_composition.gd")
	var comp = script_res.new(p_count, p_primary, p_secondary, p_armor, p_zone, p_formation)
	comp.composition_id = str(data.get("composition_id", comp.composition_id))
	comp.resolved_role = str(data.get("resolved_role", comp.resolved_role))
	comp.current_zone = p_zone
	comp.formation = p_formation
	comp.tactical_intent = str(data.get("tactical_intent", "HOLD_POSITION"))
	comp.protected_target = str(data.get("protected_target", ""))
	comp.focus_target = str(data.get("focus_target", ""))
	comp.following_target = str(data.get("following_target", ""))
	
	if data.has("reserved_equipment") and data["reserved_equipment"] is Array:
		var EquipmentModelScript = preload("res://scripts/domain/model/equipment_model.gd")
		for item_data in data["reserved_equipment"]:
			if item_data is Dictionary:
				var eq = EquipmentModelScript.new(
					str(item_data.get("role_type", "SWORD")),
					int(item_data.get("tier", 1)),
					int(item_data.get("durability", 100)),
					int(item_data.get("quantity", 1))
				)
				comp.reserved_equipment.append(eq)
	return comp
