class_name ResourceLedger
extends RefCounted

## ResourceLedger
## Model domain murni perbendaharaan dan otoritas sumber daya benteng (Phase 7A).
## Berfungsi sebagai Single Source of Truth untuk seluruh saldo kas dan material benteng.
## Menjamin transaksi atomik zero-sum, non-negatif, validasi kecukupan saldo,
## serta pencegahan mutasi parsial pada kegagalan transaksi.

# Konstanta Sumber Daya Kanonikal Phase 7
const RESOURCE_GOLD: String = "GOLD"
const RESOURCE_MONSTER_CORE: String = "MONSTER_CORE"
const RESOURCE_MONSTER_MATERIAL: String = "MONSTER_MATERIAL"
const RESOURCE_BASIC_MATERIAL: String = "BASIC_MATERIAL"
const RESOURCE_RARE_MATERIAL: String = "RARE_MATERIAL"

# Alias Kanonikal
const ALIAS_TREASURY_GOLD: String = "TREASURY_GOLD"
const ALIAS_MONSTER_CORES: String = "MONSTER_CORES"
const ALIAS_MONSTER_MATERIALS: String = "MONSTER_MATERIALS"
const ALIAS_BASIC_MATERIALS: String = "BASIC_MATERIALS"
const ALIAS_RARE_MATERIALS: String = "RARE_MATERIALS"

const CANONICAL_RESOURCES: Array[String] = [
	RESOURCE_GOLD,
	RESOURCE_MONSTER_CORE,
	RESOURCE_MONSTER_MATERIAL,
	RESOURCE_BASIC_MATERIAL,
	RESOURCE_RARE_MATERIAL
]

var _resources: Dictionary = {}


func _init(initial_gold: int = 150, initial_resources: Dictionary = {}) -> void:
	# Inisialisasi seluruh 5 sumber daya kanonikal ke default
	_resources[RESOURCE_GOLD] = maxi(0, initial_gold)
	_resources[RESOURCE_MONSTER_CORE] = 0
	_resources[RESOURCE_MONSTER_MATERIAL] = 0
	_resources[RESOURCE_BASIC_MATERIAL] = 0
	_resources[RESOURCE_RARE_MATERIAL] = 0
	
	# Muat sumber daya tambahan jika disediakan
	for k in initial_resources:
		var norm_k: String = normalize_resource_type(str(k))
		if is_canonical_resource(norm_k):
			_resources[norm_k] = maxi(0, int(initial_resources[k]))


static func normalize_resource_type(res_type: String) -> String:
	var clean: String = res_type.strip_edges().to_upper()
	match clean:
		ALIAS_TREASURY_GOLD:
			return RESOURCE_GOLD
		ALIAS_MONSTER_CORES:
			return RESOURCE_MONSTER_CORE
		ALIAS_MONSTER_MATERIALS:
			return RESOURCE_MONSTER_MATERIAL
		ALIAS_BASIC_MATERIALS:
			return RESOURCE_BASIC_MATERIAL
		ALIAS_RARE_MATERIALS:
			return RESOURCE_RARE_MATERIAL
		_:
			return clean


static func is_canonical_resource(res_type: String) -> bool:
	var norm: String = normalize_resource_type(res_type)
	return norm in CANONICAL_RESOURCES


func get_resource(resource_id: String) -> int:
	var norm: String = normalize_resource_type(resource_id)
	if not is_canonical_resource(norm):
		push_warning("ResourceLedger: resource tidak dikenal '%s'" % resource_id)
		return 0
	return int(_resources.get(norm, 0))


func set_resource(resource_id: String, amount: int) -> bool:
	var norm: String = normalize_resource_type(resource_id)
	if not is_canonical_resource(norm):
		push_warning("ResourceLedger: gagal set_resource, tipe '%s' tidak sah" % resource_id)
		return false
	if amount < 0:
		push_warning("ResourceLedger: saldo tidak boleh bernilai negatif (%d)" % amount)
		return false
	_resources[norm] = amount
	return true


func can_afford(resource_id: String, amount: int) -> bool:
	if amount < 0:
		return false
	var norm: String = normalize_resource_type(resource_id)
	if not is_canonical_resource(norm):
		return false
	return get_resource(norm) >= amount


func can_afford_resources(cost_dict: Dictionary) -> bool:
	if cost_dict.is_empty():
		return true
	for k in cost_dict:
		var cost: int = int(cost_dict[k])
		if cost < 0:
			return false
		if not can_afford(str(k), cost):
			return false
	return true


func spend_resource(resource_id: String, amount: int) -> bool:
	if amount < 0:
		push_warning("ResourceLedger: spend_resource jumlah tidak boleh negatif (%d)" % amount)
		return false
	if not can_afford(resource_id, amount):
		return false
	var norm: String = normalize_resource_type(resource_id)
	_resources[norm] = int(_resources.get(norm, 0)) - amount
	return true


func spend_resources(cost_dict: Dictionary) -> bool:
	if cost_dict.is_empty():
		return true
	# 1. Validasi atomik: pastikan seluruh sumber daya mencukupi sebelum memutasi
	if not can_afford_resources(cost_dict):
		return false
	# 2. Mutasi atomik: kurangi seluruh sumber daya
	for k in cost_dict:
		var cost: int = int(cost_dict[k])
		var norm: String = normalize_resource_type(str(k))
		_resources[norm] = int(_resources.get(norm, 0)) - cost
	return true


func add_resource(resource_id: String, amount: int) -> bool:
	if amount < 0:
		push_warning("ResourceLedger: add_resource jumlah tidak boleh negatif (%d)" % amount)
		return false
	var norm: String = normalize_resource_type(resource_id)
	if not is_canonical_resource(norm):
		push_warning("ResourceLedger: gagal add_resource, tipe '%s' tidak sah" % resource_id)
		return false
	_resources[norm] = int(_resources.get(norm, 0)) + amount
	return true


func add_resources(credit_dict: Dictionary) -> bool:
	if credit_dict.is_empty():
		return true
	# 1. Validasi atomik: pastikan semua tipe valid dan jumlah >= 0
	for k in credit_dict:
		var amt: int = int(credit_dict[k])
		if amt < 0 or not is_canonical_resource(str(k)):
			push_warning("ResourceLedger: add_resources kredit tidak valid untuk '%s' (%d)" % [str(k), amt])
			return false
	# 2. Mutasi atomik
	for k in credit_dict:
		var amt: int = int(credit_dict[k])
		var norm: String = normalize_resource_type(str(k))
		_resources[norm] = int(_resources.get(norm, 0)) + amt
	return true


func get_all_resources() -> Dictionary:
	return _resources.duplicate(true)


# Convenience Getters
func get_gold() -> int:
	return get_resource(RESOURCE_GOLD)


func get_monster_cores() -> int:
	return get_resource(RESOURCE_MONSTER_CORE)


func get_monster_materials() -> int:
	return get_resource(RESOURCE_MONSTER_MATERIAL)


func get_basic_materials() -> int:
	return get_resource(RESOURCE_BASIC_MATERIAL)


func get_rare_materials() -> int:
	return get_resource(RESOURCE_RARE_MATERIAL)


func validate_invariants() -> bool:
	for res in CANONICAL_RESOURCES:
		if not _resources.has(res):
			return false
		if int(_resources[res]) < 0:
			return false
	return true


func clone() -> ResourceLedger:
	var script = load("res://scripts/domain/model/resource_ledger.gd")
	var copy = script.new(_resources[RESOURCE_GOLD])
	for k in _resources:
		copy._resources[k] = _resources[k]
	return copy


func to_dictionary() -> Dictionary:
	return _resources.duplicate(true)


static func from_dictionary(dict: Dictionary) -> ResourceLedger:
	var script = load("res://scripts/domain/model/resource_ledger.gd")
	var init_gold: int = int(dict.get(RESOURCE_GOLD, 150))
	var ledger = script.new(init_gold)
	for k in dict:
		var norm: String = normalize_resource_type(str(k))
		if is_canonical_resource(norm):
			ledger.set_resource(norm, maxi(0, int(dict[k])))
	return ledger
