class_name PartyModel
extends RefCounted

## PartyModel
## Pure domain model untuk manajemen regu pahlawan (Phase 4F).
## Tidak memiliki dependensi ke Node, SceneTree, UI, rendering, atau filesystem.
## Mengelola keanggotaan (maks 3 hero), pemimpin regu, dan status penugasan tempur.

const PARTY_1_ID: String = "party_1"
const PARTY_2_ID: String = "party_2"
const MAX_PARTIES: int = 2
const MAX_MEMBERS: int = 3

const VALID_PARTY_IDS: Array[String] = [
	PARTY_1_ID,
	PARTY_2_ID
]

var party_id: String = ""
var party_name: String = ""
var leader_hero_id: String = ""
var member_hero_ids: Array = []
var is_deployed_to_battle: bool = false
var current_zone: String = "GATE"
var formation: String = "FRONTLINE"
var tactical_intent: String = "HOLD_POSITION"
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
	p_id: String = PARTY_1_ID,
	p_name: String = "Party 1",
	p_deployed: bool = false,
	p_zone: String = "GATE",
	p_formation: String = "FRONTLINE"
) -> void:
	party_id = p_id.strip_edges().to_lower()
	party_name = p_name.strip_edges()
	leader_hero_id = ""
	member_hero_ids = []
	is_deployed_to_battle = p_deployed
	current_zone = p_zone.to_upper().strip_edges() if not p_zone.is_empty() else "GATE"
	formation = p_formation.to_upper().strip_edges() if not p_formation.is_empty() else "FRONTLINE"


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
	var valid_formations: Array[String] = ["FRONTLINE", "BACKLINE", "SUPPORT"]
	if not (f in valid_formations):
		return false
	formation = f
	return true


## Memeriksa apakah party_id valid secara kanonikal
static func is_valid_party_id(p_party_id: String) -> bool:
	var id: String = p_party_id.strip_edges().to_lower()
	return id in VALID_PARTY_IDS


## Memeriksa apakah hero dapat ditambahkan ke regu
func can_add_member(hero_id: String) -> bool:
	var h_id: String = hero_id.strip_edges()
	if h_id.is_empty():
		return false
	if has_member(h_id):
		return false
	if is_full():
		return false
	return true


## Menambahkan hero ke dalam regu
func add_member(hero_id: String) -> bool:
	if not can_add_member(hero_id):
		return false
	member_hero_ids.append(hero_id.strip_edges())
	return true


## Mengeluarkan hero dari regu
## Otomatis mengosongkan leader_hero_id jika hero yang dikeluarkan adalah leader
func remove_member(hero_id: String) -> bool:
	var h_id: String = hero_id.strip_edges()
	if not has_member(h_id):
		return false
	member_hero_ids.erase(h_id)
	if leader_hero_id == h_id:
		leader_hero_id = ""
	return true


## Memeriksa apakah hero terdaftar sebagai anggota regu
func has_member(hero_id: String) -> bool:
	return hero_id.strip_edges() in member_hero_ids


## Mengembalikan jumlah anggota dalam regu saat ini
func get_member_count() -> int:
	return member_hero_ids.size()


## Memeriksa apakah regu telah penuh (mencapai batas MAX_MEMBERS)
func is_full() -> bool:
	return member_hero_ids.size() >= MAX_MEMBERS


## Mengatur pemimpin regu
## Hero harus menjadi anggota regu, atau hero_id kosong untuk mengosongkan pemimpin
func set_leader(hero_id: String) -> bool:
	var h_id: String = hero_id.strip_edges()
	if h_id.is_empty():
		leader_hero_id = ""
		return true
	if not has_member(h_id):
		return false
	leader_hero_id = h_id
	return true


## Membersihkan leader_hero_id jika leader tidak lagi terdaftar sebagai anggota
func clear_leader_if_needed() -> void:
	if not leader_hero_id.is_empty() and not has_member(leader_hero_id):
		leader_hero_id = ""


## Mengembalikan salinan daftar ID anggota regu
func get_members() -> Array:
	return member_hero_ids.duplicate()


## Menduplikasi instance PartyModel (deep copy)
func clone() -> PartyModel:
	var p := PartyModel.new(party_id, party_name, is_deployed_to_battle, current_zone, formation)
	p.leader_hero_id = leader_hero_id
	p.member_hero_ids = member_hero_ids.duplicate()
	p.current_zone = current_zone
	p.formation = formation
	p.tactical_intent = tactical_intent
	p.protected_target = protected_target
	p.focus_target = focus_target
	p.following_target = following_target
	return p


## Memvalidasi invarian domain PartyModel
func validate_invariants() -> bool:
	if not is_valid_party_id(party_id):
		return false
	if party_name.strip_edges().is_empty():
		return false
	if member_hero_ids.size() > MAX_MEMBERS:
		return false
	var seen: Dictionary = {}
	for m in member_hero_ids:
		var s: String = str(m).strip_edges()
		if s.is_empty() or seen.has(s):
			return false
		seen[s] = true
	if not leader_hero_id.is_empty() and not has_member(leader_hero_id):
		return false
	if party_id == PARTY_2_ID and is_deployed_to_battle:
		return false
	if current_zone == "OUTER_FIELD":
		return false
	var valid_formations: Array[String] = ["FRONTLINE", "BACKLINE", "SUPPORT"]
	if not (formation in valid_formations):
		return false
	return true


## Mengonversi data regu ke Dictionary untuk telemetri snapshot
func to_dictionary() -> Dictionary:
	return {
		"party_id": party_id,
		"party_name": party_name,
		"leader_hero_id": leader_hero_id,
		"member_hero_ids": get_members(),
		"member_count": get_member_count(),
		"max_members": MAX_MEMBERS,
		"is_full": is_full(),
		"is_deployed_to_battle": is_deployed_to_battle,
		"current_zone": current_zone,
		"formation": formation,
		"tactical_intent": tactical_intent,
		"protected_target": protected_target,
		"focus_target": focus_target,
		"following_target": following_target
	}


static func from_dictionary(data: Dictionary) -> PartyModel:
	if data.is_empty():
		return null
	var pid: String = str(data.get("party_id", PARTY_1_ID))
	var pname: String = str(data.get("party_name", "Party 1"))
	var dep: bool = bool(data.get("is_deployed_to_battle", false))
	var czone: String = str(data.get("current_zone", "GATE"))
	var form: String = str(data.get("formation", "FRONTLINE"))

	var p := PartyModel.new(pid, pname, dep, czone, form)
	p.leader_hero_id = str(data.get("leader_hero_id", ""))
	p.tactical_intent = str(data.get("tactical_intent", "HOLD_POSITION"))
	p.protected_target = str(data.get("protected_target", ""))
	p.focus_target = str(data.get("focus_target", ""))
	p.following_target = str(data.get("following_target", ""))
	if data.has("member_hero_ids") and data["member_hero_ids"] is Array:
		for m in data["member_hero_ids"]:
			p.member_hero_ids.append(str(m))
	return p
