class_name DeploymentComposition
extends RefCounted

## DeploymentComposition
## Model agregat regu penempatan tempur sementara berbasis gelombang (Phase 3B).
## Menyimpan jumlah prajurit, senjata primer (wajib), sekunder (opsional),
## zirah (opsional), identitas kanonikal regu, peran tempur turunan,
## dan daftar perlengkapan yang direservasi sementara dari gudang.

var count: int = 0
var primary_weapon: String = "SWORD"    # REQUIRED: SWORD, SPEAR, BOW
var secondary_weapon: String = "NONE"   # OPTIONAL: SHIELD, NONE
var armor: String = "NONE"              # OPTIONAL: HEAVY_ARMOR, NONE
var composition_id: String = ""         # Canonical identity: primary|secondary|armor
var resolved_role: String = "SWORDSMAN" # Derived role for CombatEngine
var reserved_equipment: Array = []      # Array[EquipmentModel] instances reserved for this group


func _init(p_count: int = 0, p_primary: String = "SWORD", p_secondary: String = "NONE", p_armor: String = "NONE") -> void:
	count = maxi(0, p_count)
	primary_weapon = p_primary.to_upper().strip_edges()
	secondary_weapon = p_secondary.to_upper().strip_edges() if not p_secondary.is_empty() else "NONE"
	armor = p_armor.to_upper().strip_edges() if not p_armor.is_empty() else "NONE"
	composition_id = make_composition_id(primary_weapon, secondary_weapon, armor)
	resolved_role = resolve_role(primary_weapon, secondary_weapon, armor)
	reserved_equipment = []


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
	var copy = script.new(count, primary_weapon, secondary_weapon, armor)
	copy.composition_id = composition_id
	copy.resolved_role = resolved_role
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
		"reserved_equipment": reserved_data
	}


static func from_dictionary(data: Dictionary) -> RefCounted:
	var p_count: int = int(data.get("count", 0))
	var p_primary: String = str(data.get("primary_weapon", "SWORD"))
	var p_secondary: String = str(data.get("secondary_weapon", "NONE"))
	var p_armor: String = str(data.get("armor", "NONE"))
	var script = load("res://scripts/domain/model/deployment_composition.gd")
	var comp = script.new(p_count, p_primary, p_secondary, p_armor)
	comp.composition_id = str(data.get("composition_id", comp.composition_id))
	comp.resolved_role = str(data.get("resolved_role", comp.resolved_role))
	
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
