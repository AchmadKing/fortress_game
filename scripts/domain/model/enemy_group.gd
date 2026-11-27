class_name EnemyGroup
extends RefCounted

## EnemyGroup
## Aggregate domain model untuk sekelompok musuh di medan pertempuran (Phase 6A).
## Mematuhi prinsip "No Individual Entity": musuh dikelompokkan secara agregat per arketipe.
## Tidak berupa Node di SceneTree, tidak mengalokasikan visual, dan sepenuhnya serializable.
## Mengelola kuantitas hidup, kolam HP teragregasi, posisi zona, dan status bos.

var group_id: String = ""
var enemy_type: String = ""
var quantity: int = 0
var current_zone: String = BattlefieldZone.ZONE_OUTER_FIELD
var target_zone: String = ""
var base_hp_per_unit: int = 10
var base_atk_per_unit: int = 1
var base_def_per_unit: int = 0
var move_speed_ticks: int = 1
var ticks_until_advance: int = 1
var current_hp_pool: int = 10
var max_hp_pool: int = 10
var special_trait: String = ""
var target_priority: String = ""
var is_boss: bool = false


func _init(
	p_group_id: String = "",
	p_enemy_type: String = EnemyArchetype.ARCHETYPE_GOBLIN_SWARM,
	p_quantity: int = 1,
	p_current_zone: String = BattlefieldZone.ZONE_OUTER_FIELD,
	p_is_boss: bool = false
) -> void:
	group_id = p_group_id.strip_edges()
	enemy_type = p_enemy_type.strip_edges().to_upper()
	quantity = maxi(0, p_quantity)
	current_zone = p_current_zone.strip_edges().to_upper()
	target_zone = ""
	is_boss = p_is_boss
	
	if EnemyArchetype.is_valid_archetype(enemy_type):
		var def: Dictionary = EnemyArchetype.get_definition(enemy_type)
		base_hp_per_unit = int(def.get("base_hp", 10))
		base_atk_per_unit = int(def.get("base_atk", 1))
		base_def_per_unit = int(def.get("base_def", 0))
		move_speed_ticks = int(def.get("move_speed_ticks", 1))
		special_trait = str(def.get("special_trait", ""))
		target_priority = str(def.get("target_priority", ""))
	else:
		base_hp_per_unit = 10
		base_atk_per_unit = 1
		base_def_per_unit = 0
		move_speed_ticks = 1
		special_trait = ""
		target_priority = ""
		
	# Scaling atribut khusus jika merupakan bos
	if is_boss:
		base_hp_per_unit = int(base_hp_per_unit * 2.5)
		base_atk_per_unit = int(base_atk_per_unit * 1.5)
		base_def_per_unit = int(base_def_per_unit * 1.25)
		special_trait = "BOSS_ELITE" if special_trait == "" else special_trait + "_BOSS"
		
	max_hp_pool = base_hp_per_unit * quantity
	current_hp_pool = max_hp_pool
	ticks_until_advance = move_speed_ticks


func apply_damage(amount: int) -> int:
	if amount <= 0 or current_hp_pool <= 0:
		return 0
	var actual_damage: int = mini(amount, current_hp_pool)
	current_hp_pool -= actual_damage
	if current_hp_pool <= 0:
		current_hp_pool = 0
		quantity = 0
	else:
		quantity = int(ceil(float(current_hp_pool) / float(maxi(1, base_hp_per_unit))))
	return actual_damage


func is_defeated() -> bool:
	return quantity <= 0 or current_hp_pool <= 0


func validate_invariants() -> bool:
	if group_id.is_empty():
		return false
	if not EnemyArchetype.is_valid_archetype(enemy_type):
		return false
	if quantity < 0:
		return false
	if not BattlefieldZone.is_valid_zone(current_zone):
		return false
	if target_zone != "" and not BattlefieldZone.is_valid_zone(target_zone):
		return false
	if base_hp_per_unit <= 0:
		return false
	if base_atk_per_unit < 0:
		return false
	if base_def_per_unit < 0:
		return false
	if move_speed_ticks <= 0:
		return false
	if current_hp_pool < 0 or current_hp_pool > max_hp_pool:
		return false
	if max_hp_pool < 0:
		return false
	# Invarian relasi kuantitas dan HP
	if quantity == 0 and current_hp_pool != 0:
		return false
	if quantity > 0 and current_hp_pool == 0:
		return false
	return true


func clone() -> EnemyGroup:
	var copy = EnemyGroup.new(group_id, enemy_type, quantity, current_zone, is_boss)
	copy.target_zone = target_zone
	copy.base_hp_per_unit = base_hp_per_unit
	copy.base_atk_per_unit = base_atk_per_unit
	copy.base_def_per_unit = base_def_per_unit
	copy.move_speed_ticks = move_speed_ticks
	copy.ticks_until_advance = ticks_until_advance
	copy.max_hp_pool = max_hp_pool
	copy.current_hp_pool = current_hp_pool
	copy.special_trait = special_trait
	copy.target_priority = target_priority
	return copy


func to_dictionary() -> Dictionary:
	return {
		"group_id": group_id,
		"enemy_type": enemy_type,
		"quantity": quantity,
		"current_zone": current_zone,
		"target_zone": target_zone,
		"base_hp_per_unit": base_hp_per_unit,
		"base_atk_per_unit": base_atk_per_unit,
		"base_def_per_unit": base_def_per_unit,
		"move_speed_ticks": move_speed_ticks,
		"ticks_until_advance": ticks_until_advance,
		"current_hp_pool": current_hp_pool,
		"max_hp_pool": max_hp_pool,
		"special_trait": special_trait,
		"target_priority": target_priority,
		"is_boss": is_boss
	}


static func from_dictionary(dict: Dictionary) -> EnemyGroup:
	if dict.is_empty():
		return null
	var gid: String = str(dict.get("group_id", ""))
	var etype: String = str(dict.get("enemy_type", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM))
	var qty: int = int(dict.get("quantity", 0))
	var czone: String = str(dict.get("current_zone", BattlefieldZone.ZONE_OUTER_FIELD))
	var boss: bool = bool(dict.get("is_boss", false))
	
	var eg := EnemyGroup.new(gid, etype, qty, czone, boss)
	eg.target_zone = str(dict.get("target_zone", ""))
	eg.base_hp_per_unit = int(dict.get("base_hp_per_unit", eg.base_hp_per_unit))
	eg.base_atk_per_unit = int(dict.get("base_atk_per_unit", eg.base_atk_per_unit))
	eg.base_def_per_unit = int(dict.get("base_def_per_unit", eg.base_def_per_unit))
	eg.move_speed_ticks = int(dict.get("move_speed_ticks", eg.move_speed_ticks))
	eg.ticks_until_advance = int(dict.get("ticks_until_advance", eg.ticks_until_advance))
	eg.max_hp_pool = int(dict.get("max_hp_pool", eg.max_hp_pool))
	eg.current_hp_pool = int(dict.get("current_hp_pool", eg.current_hp_pool))
	eg.special_trait = str(dict.get("special_trait", eg.special_trait))
	eg.target_priority = str(dict.get("target_priority", eg.target_priority))
	return eg
