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


func _init(
	p_id: String = PARTY_1_ID,
	p_name: String = "Party 1",
	p_deployed: bool = false
) -> void:
	party_id = p_id.strip_edges().to_lower()
	party_name = p_name.strip_edges()
	leader_hero_id = ""
	member_hero_ids = []
	is_deployed_to_battle = p_deployed


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
	var p := PartyModel.new(party_id, party_name, is_deployed_to_battle)
	p.leader_hero_id = leader_hero_id
	p.member_hero_ids = member_hero_ids.duplicate()
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
		"is_deployed_to_battle": is_deployed_to_battle
	}
