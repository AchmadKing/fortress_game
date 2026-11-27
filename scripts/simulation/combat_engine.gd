class_name CombatEngine
extends RefCounted

## CombatEngine
## Engine kalkulasi pertempuran headless deterministik multi-fase (Phase 1 - 5).
## Mematuhi 4 perbaikan wajib:
## 1. Aggregate equipment quantity & ownership (jumlah equipment membatasi benefit tier).
## 2. Equipment loss & damage deterministik pasca-korban (casualties).
## 3. Hero survival/death deterministik (bukan otomatis semua mati saat benteng runtuh).
## 4. Full determinism berbasis seed.

const PopulationModelScript = preload("res://scripts/domain/model/population_model.gd")
const FortressModelScript = preload("res://scripts/domain/model/fortress_model.gd")
const HeroModelScript = preload("res://scripts/domain/model/hero_model.gd")
const EquipmentModelScript = preload("res://scripts/domain/model/equipment_model.gd")
const BattlefieldZoneScript = preload("res://scripts/domain/model/battlefield_zone.gd")
const EnemyGroupScript = preload("res://scripts/domain/model/enemy_group.gd")
const EnemyArchetypeScript = preload("res://scripts/domain/model/enemy_archetype.gd")
const DeploymentCompositionScript = preload("res://scripts/domain/model/deployment_composition.gd")
const CommanderCommandScript = preload("res://scripts/domain/command/commander_command.gd")

# Phase 6B: Canonical Simulation Speed Constants
const SPEED_1X: float = 1.0
const SPEED_2X: float = 2.0
const SPEED_4X: float = 4.0
const VALID_SPEEDS: Array[float] = [SPEED_1X, SPEED_2X, SPEED_4X]

# Phase 6E: Canonical Casualty Pressure Threshold
const CASUALTY_PRESSURE_THRESHOLD: int = 50


static func is_valid_speed(speed: float) -> bool:
	return is_equal_approx(speed, SPEED_1X) or is_equal_approx(speed, SPEED_2X) or is_equal_approx(speed, SPEED_4X)


## Menjalankan 1 tick simulasi taktis headless deterministik (Phase 6B & 6E).
## Jika battle_context kosong, berlaku sebagai clock-only advance murni.
## Jika battle_context diberikan, menjalankan kalkulasi tekanan, pergerakan, kerusakan benteng, dan korban.
func step_simulation_tick(current_tick: int, battle_context: Dictionary = {}) -> Dictionary:
	assert(current_tick >= 0, "current_tick tidak boleh negatif")
	var next_tick: int = current_tick + 1

	if battle_context.is_empty():
		return {
			"tick": next_tick,
			"events": []
		}

	var enemy_groups: Array = battle_context.get("enemy_groups", [])
	var deployments: Array = battle_context.get("deployments", [])
	var party_heroes: Array = battle_context.get("party_heroes", [])
	var fortress: FortressModel = battle_context.get("fortress", null)
	var commander_intents: Dictionary = battle_context.get("commander_intents", {})
	var accumulated_pressure: Dictionary = battle_context.get("accumulated_pressure", {}).duplicate(true)
	var battle_seed: int = int(battle_context.get("battle_seed", 42))
	var party_zone: String = str(battle_context.get("party_zone", BattlefieldZoneScript.ZONE_GATE)).to_upper().strip_edges()

	var events: Array[Dictionary] = []
	var zone_pressure: Dictionary = {}
	var casualties: Dictionary = {}

	# 1. Pergerakan Musuh Berdasarkan Kecepatan Arketipe (Ticks Until Advance)
	for g in enemy_groups:
		if g is EnemyGroup:
			var eg: EnemyGroup = g as EnemyGroup
			if not eg.is_defeated():
				eg.ticks_until_advance -= 1
				if eg.ticks_until_advance <= 0:
					eg.ticks_until_advance = maxi(1, eg.move_speed_ticks)
					var curr_z: String = eg.current_zone
					var target_z: String = curr_z

					match curr_z:
						BattlefieldZoneScript.ZONE_OUTER_FIELD:
							if eg.target_priority == "GATE" or eg.enemy_type == EnemyArchetypeScript.ARCHETYPE_ORC_FRONTLINE or eg.enemy_type == EnemyArchetypeScript.ARCHETYPE_TROLL_TANK or eg.enemy_type == EnemyArchetypeScript.ARCHETYPE_SIEGE_MONSTER:
								target_z = BattlefieldZoneScript.ZONE_CENTER_APPROACH
							elif eg.special_trait.begins_with("FLYING"):
								target_z = BattlefieldZoneScript.ZONE_CENTER_APPROACH
							else:
								var roll_idx: int = abs(eg.group_id.hash() + next_tick) % 3
								match roll_idx:
									0: target_z = BattlefieldZoneScript.ZONE_LEFT_FLANK
									1: target_z = BattlefieldZoneScript.ZONE_CENTER_APPROACH
									2: target_z = BattlefieldZoneScript.ZONE_RIGHT_FLANK
						BattlefieldZoneScript.ZONE_CENTER_APPROACH:
							target_z = BattlefieldZoneScript.ZONE_GATE
						BattlefieldZoneScript.ZONE_LEFT_FLANK, BattlefieldZoneScript.ZONE_RIGHT_FLANK:
							target_z = BattlefieldZoneScript.ZONE_WALL
						BattlefieldZoneScript.ZONE_GATE:
							if fortress != null and fortress.is_gate_breached():
								target_z = BattlefieldZoneScript.ZONE_FORTRESS
						BattlefieldZoneScript.ZONE_WALL:
							if fortress != null and fortress.is_wall_breached():
								target_z = BattlefieldZoneScript.ZONE_FORTRESS
						BattlefieldZoneScript.ZONE_FORTRESS:
							target_z = BattlefieldZoneScript.ZONE_FORTRESS

					if target_z != curr_z:
						eg.current_zone = target_z
						events.append({
							"type": "ENEMY_ADVANCE",
							"group_id": eg.group_id,
							"from": curr_z,
							"to": target_z,
							"tick": next_tick
						})

	# 2. Evaluasi Tekanan Musuh, Pertahanan Kawan, Kerusakan Struktur & Korban per Zona
	for zone_id in BattlefieldZoneScript.VALID_ZONES:
		var raw_enemy_press: int = calculate_zone_enemy_pressure(enemy_groups, zone_id)
		zone_pressure[zone_id] = raw_enemy_press

		# Cari apakah ada Party 1 di zona ini
		var heroes_in_this_zone: Array = []
		if party_zone == zone_id:
			heroes_in_this_zone = party_heroes

		var def_power: Dictionary = calculate_zone_defender_power(deployments, heroes_in_this_zone, zone_id, commander_intents)
		var total_atk: float = float(def_power.get("total_atk", 0.0))
		var total_def: float = float(def_power.get("total_def", 0.0))
		var total_soldiers: int = int(def_power.get("total_soldiers", 0))

		# A. Defender menyerang musuh di zona ini
		if total_atk > 0.0:
			var living_in_zone: Array[EnemyGroup] = []
			for g in enemy_groups:
				if g is EnemyGroup and (g as EnemyGroup).current_zone == zone_id and not (g as EnemyGroup).is_defeated():
					living_in_zone.append(g as EnemyGroup)

			if not living_in_zone.is_empty():
				# Cek target prioritas FOCUS_TARGET dari perintah komandan
				var focus_target: String = ""
				for c_id in commander_intents:
					var intent_data: Dictionary = commander_intents[c_id]
					if intent_data.get("intent") in [CommanderCommandScript.TYPE_FOCUS_TARGET, "FOCUS"]:
						focus_target = str(intent_data.get("focus_target", "")).to_upper().strip_edges()
						break

				var primary_target: EnemyGroup = null
				if not focus_target.is_empty():
					for eg in living_in_zone:
						if eg.enemy_type == focus_target or eg.group_id == focus_target:
							primary_target = eg
							break

				var dmg_pool: int = maxi(1, int(ceil(total_atk * 0.20)))
				if primary_target != null:
					var dealt: int = primary_target.apply_damage(dmg_pool)
					if primary_target.is_defeated():
						events.append({
							"type": "ENEMY_DEFEATED",
							"group_id": primary_target.group_id,
							"zone": zone_id,
							"tick": next_tick
						})
				else:
					var share: int = maxi(1, dmg_pool / living_in_zone.size())
					for eg in living_in_zone:
						eg.apply_damage(share)
						if eg.is_defeated():
							events.append({
								"type": "ENEMY_DEFEATED",
								"group_id": eg.group_id,
								"zone": zone_id,
								"tick": next_tick
							})

		# B. Tekanan musuh terhadap struktur dan serdadu
		if raw_enemy_press > 0:
			var absorbed: int = mini(raw_enemy_press, int(floor(total_def * 0.40)))
			var net_press: int = maxi(0, raw_enemy_press - absorbed)

			# Kerusakan Struktur Benteng (GATE, WALL, FORTRESS)
			if zone_id in [BattlefieldZoneScript.ZONE_GATE, BattlefieldZoneScript.ZONE_WALL, BattlefieldZoneScript.ZONE_FORTRESS]:
				if fortress != null:
					var struct_raw: int = maxi(1, int(ceil(float(net_press) * 0.35))) if net_press > 0 else 0
					if struct_raw > 0:
						var route_res: Dictionary = route_damage_to_fortress(fortress, zone_id, struct_raw)
						if route_res["damage"] > 0:
							events.append({
								"type": "FORTRESS_DAMAGE",
								"target": route_res["target"],
								"damage": route_res["damage"],
								"breached": route_res.get("breached", false),
								"destroyed": route_res.get("destroyed", false),
								"tick": next_tick
							})
							# Pertahanan pasif struktur benteng memberikan counter-damage ke musuh yang membentur
							var fort_recoil: int = maxi(1, int(ceil(float(route_res["damage"]) * 0.75)))
							for g in enemy_groups:
								if g is EnemyGroup and (g as EnemyGroup).current_zone == zone_id and not (g as EnemyGroup).is_defeated():
									(g as EnemyGroup).apply_damage(fort_recoil)
									if (g as EnemyGroup).is_defeated():
										events.append({
											"type": "ENEMY_DEFEATED",
											"group_id": (g as EnemyGroup).group_id,
											"zone": zone_id,
											"tick": next_tick
										})

			# Korban Jiwa Serdadu (Casualties)
			if total_soldiers > 0 and net_press > 0:
				var curr_acc: int = int(accumulated_pressure.get(zone_id, 0)) + net_press
				accumulated_pressure[zone_id] = curr_acc

				for comp in deployments:
					if comp is DeploymentComposition and (comp as DeploymentComposition).current_zone == zone_id and (comp as DeploymentComposition).count > 0:
						var dep: DeploymentComposition = comp as DeploymentComposition
						var cas_res: Dictionary = resolve_soldier_casualties(dep, int(accumulated_pressure.get(zone_id, 0)))
						if cas_res["casualties"] > 0:
							var r_type: String = str(cas_res["role"])
							var deaths_count: int = int(cas_res["casualties"])
							casualties[r_type] = int(casualties.get(r_type, 0)) + deaths_count
							accumulated_pressure[zone_id] = int(cas_res["remaining_pressure"])
							dep.count = maxi(0, dep.count - deaths_count)
							events.append({
								"type": "SOLDIER_CASUALTY",
								"role": r_type,
								"count": deaths_count,
								"zone": zone_id,
								"tick": next_tick
							})

			# Bahaya Pahlawan (Hero Danger & Death)
			if not heroes_in_this_zone.is_empty() and net_press > 0:
				for h in heroes_in_this_zone:
					if h is HeroModel and (h as HeroModel).is_alive:
						var hero_obj: HeroModel = h as HeroModel
						hero_obj.add_fatigue(1)
						var died: bool = resolve_hero_danger(
							hero_obj,
							net_press,
							100,
							fortress != null and fortress.is_destroyed(),
							next_tick,
							battle_seed
						)
						if died:
							events.append({
								"type": "HERO_DEATH",
								"hero_id": hero_obj.hero_id,
								"zone": zone_id,
								"tick": next_tick
							})

	# 3. Status Penyelesaian Pertempuran (Victory / Defeat)
	var all_enemies_defeated: bool = true
	for g in enemy_groups:
		if g is EnemyGroup and not (g as EnemyGroup).is_defeated():
			all_enemies_defeated = false
			break

	var fortress_destroyed: bool = fortress != null and fortress.is_destroyed()
	var is_finished: bool = all_enemies_defeated or fortress_destroyed
	var is_victory: bool = all_enemies_defeated and not fortress_destroyed
	var is_game_over: bool = fortress_destroyed

	return {
		"tick": next_tick,
		"events": events,
		"zone_pressure": zone_pressure,
		"accumulated_pressure": accumulated_pressure,
		"casualties": casualties,
		"is_finished": is_finished,
		"victory": is_victory,
		"game_over": is_game_over
	}


## Menghitung modifier aura pasif dari pahlawan Party 1 yang hidup di medan tempur (Phase 6C).
## Murni fondasi pasif deterministik: tidak memutasi statistik dasar HeroModel.
func calculate_party_auras(battle_heroes: Array, target_zone: String = "") -> Dictionary:
	var total_atk_bonus: float = 0.0
	var total_def_bonus: float = 0.0
	var total_morale_bonus: float = 0.0
	var aura_breakdown: Array = []

	var living_heroes: Array = []
	for h in battle_heroes:
		if h != null and h.get("is_alive") == true:
			var ls: String = str(h.get("lifecycle_state"))
			if ls != "PERMADEATH":
				living_heroes.append(h)

	for h in living_heroes:
		var role: String = str(h.get("role")).to_upper().strip_edges()
		var hero_atk_mod: float = 0.0
		var hero_def_mod: float = 0.0
		var hero_morale_mod: float = 0.0

		match role:
			"KNIGHT":
				hero_def_mod += 0.10
				hero_morale_mod += 5.0
			"ARCHER":
				hero_atk_mod += 0.10
			"MAGE":
				hero_atk_mod += 0.15
			"PRIEST":
				hero_def_mod += 0.10
				hero_morale_mod += 5.0

		# Bonus Bakat Cabang LEADERSHIP (Phase 4E): +1% ATK & +1% DEF per tingkat bakat
		var talents: Dictionary = h.get("allocated_talents") if h.get("allocated_talents") is Dictionary else {}
		var lead_level: int = int(talents.get("LEADERSHIP", 0))
		if lead_level > 0:
			hero_atk_mod += float(lead_level) * 0.01
			hero_def_mod += float(lead_level) * 0.01

		total_atk_bonus += hero_atk_mod
		total_def_bonus += hero_def_mod
		total_morale_bonus += hero_morale_mod

		aura_breakdown.append({
			"hero_id": str(h.get("hero_id")),
			"role": role,
			"atk_bonus": hero_atk_mod,
			"def_bonus": hero_def_mod,
			"morale_bonus": hero_morale_mod
		})

	# Chemistry Bonus antar pahlawan hidup di Party 1 (Phase 4F): +0.5% kontribusi per poin chemistry
	var chemistry_bonus: float = 0.0
	for i in range(living_heroes.size()):
		for j in range(i + 1, living_heroes.size()):
			var h1 = living_heroes[i]
			var h2 = living_heroes[j]
			var chem: int = 0
			if h1.has_method("get_chemistry_with"):
				chem = h1.get_chemistry_with(str(h2.get("hero_id")))
			if chem > 0:
				chemistry_bonus += float(chem) * 0.005

	total_atk_bonus += chemistry_bonus

	return {
		"target_zone": target_zone,
		"atk_multiplier": 1.0 + total_atk_bonus,
		"def_multiplier": 1.0 + total_def_bonus,
		"total_atk_bonus": total_atk_bonus,
		"total_def_bonus": total_def_bonus,
		"total_morale_bonus": total_morale_bonus,
		"chemistry_bonus": chemistry_bonus,
		"contributing_heroes_count": living_heroes.size(),
		"aura_breakdown": aura_breakdown
	}


# ==============================================================================
# PHASE 6E: ZONE PRESSURE, DEFENSIVE ROUTING & CASUALTY RESOLUTION HELPERS
# ==============================================================================

## Menghitung total tekanan musuh di suatu zona tertentu (Phase 6E).
func calculate_zone_enemy_pressure(enemy_groups: Array, zone: String) -> int:
	var total_pressure: int = 0
	var z_upper: String = zone.to_upper().strip_edges()
	for g in enemy_groups:
		if g is EnemyGroup:
			var eg: EnemyGroup = g as EnemyGroup
			if eg.current_zone == z_upper and not eg.is_defeated():
				var unit_atk: int = eg.base_atk_per_unit
				var trait_mult: float = 1.0
				if eg.special_trait.begins_with("SIEGE") or eg.special_trait.find("STRUCTURE") != -1 or eg.enemy_type == EnemyArchetypeScript.ARCHETYPE_SIEGE_MONSTER:
					trait_mult = 1.5
				elif eg.special_trait.begins_with("BOSS") or eg.is_boss:
					trait_mult = 1.25
				total_pressure += int(ceil(float(eg.quantity * unit_atk) * trait_mult))
	return maxi(0, total_pressure)


## Menghitung kekuatan bertahan dan menyerang pasukan kawan di suatu zona (Phase 6E).
## Mempertimbangkan kuantitas, formasi (Phase 6C), aura pahlawan (Phase 6C), dan perintah komandan (Phase 6D).
func calculate_zone_defender_power(
	deployments: Array,
	party_heroes: Array,
	zone: String,
	commander_intents: Dictionary = {}
) -> Dictionary:
	var z_upper: String = zone.to_upper().strip_edges()
	var total_atk: float = 0.0
	var total_def: float = 0.0
	var total_soldiers: int = 0
	var frontline_present: bool = false

	# 1. Kekuatan Serdadu Agregat
	for comp in deployments:
		if comp is DeploymentComposition:
			var c: DeploymentComposition = comp as DeploymentComposition
			if c.current_zone == z_upper and c.count > 0:
				total_soldiers += c.count
				var base_atk: float = 12.0
				var base_def: float = 10.0
				match c.resolved_role:
					"SWORDSMAN":
						base_atk = 14.0
						base_def = 8.0
					"SHIELD_INFANTRY":
						base_atk = 8.0
						base_def = 18.0
					"SPEARMAN":
						base_atk = 12.0
						base_def = 10.0
					"ARCHER":
						base_atk = 16.0
						base_def = 6.0
					"HEAVY_INFANTRY":
						base_atk = 16.0
						base_def = 20.0

				var formation_atk_mod: float = 1.0
				var formation_def_mod: float = 1.0
				match c.formation:
					"FRONTLINE":
						frontline_present = true
						formation_def_mod = 1.20
						formation_atk_mod = 1.10
					"BACKLINE":
						formation_atk_mod = 1.20
						formation_def_mod = 0.85
					"SUPPORT":
						formation_def_mod = 1.10

				# Perintah Komandan pada unit
				var intent: String = ""
				if commander_intents.has(c.composition_id):
					intent = str(commander_intents[c.composition_id].get("intent", ""))
				match intent:
					CommanderCommandScript.TYPE_HOLD_POSITION, "HOLD":
						formation_def_mod += 0.15
					CommanderCommandScript.TYPE_PROTECT:
						formation_def_mod += 0.20
					CommanderCommandScript.TYPE_FOCUS_TARGET, "FOCUS":
						formation_atk_mod += 0.25

				total_atk += float(c.count) * base_atk * formation_atk_mod
				total_def += float(c.count) * base_def * formation_def_mod

	# 2. Pahlawan Party 1 (jika berada di zona yang sama)
	var party_hero_atk: float = 0.0
	var party_hero_def: float = 0.0
	var party_ids: Array = []
	for h in party_heroes:
		if h is HeroModel and (h as HeroModel).is_alive:
			party_ids.append((h as HeroModel).hero_id)

	for h in party_heroes:
		if h is HeroModel and (h as HeroModel).is_alive:
			var hero: HeroModel = h as HeroModel
			party_hero_atk += float(hero.get_effective_atk(party_ids))
			party_hero_def += float(hero.get_effective_def())

	# 3. Aura Pahlawan Party 1 (Phase 6C)
	var auras: Dictionary = calculate_party_auras(party_heroes, z_upper)
	var atk_mult: float = float(auras.get("atk_multiplier", 1.0))
	var def_mult: float = float(auras.get("def_multiplier", 1.0))

	# Jika hero Party 1 sedang berada di zona ini, tambahkan stat mereka
	total_atk = (total_atk + party_hero_atk) * atk_mult
	total_def = (total_def + party_hero_def) * def_mult

	return {
		"zone": z_upper,
		"total_atk": total_atk,
		"total_def": total_def,
		"total_soldiers": total_soldiers,
		"frontline_present": frontline_present
	}


## Merutekan kerusakan musuh secara bertingkat dan deterministik ke struktur benteng (Phase 6E).
## Zona musuh menentukan target:
## - GATE -> Gate HP (jika hancur -> tembus ke Fortress HP)
## - WALL -> Wall HP (jika hancur -> tembus ke Fortress HP)
## - FORTRESS -> Fortress HP langsung
## - Zona luar (FIELD, APPROACH, FLANK) -> TIDAK menghasilkan damage langsung ke struktur benteng.
func route_damage_to_fortress(fortress: FortressModel, enemy_zone: String, raw_damage: int) -> Dictionary:
	if fortress == null or raw_damage <= 0:
		return {"target": "NONE", "damage": 0, "breached": false, "destroyed": false}

	var z: String = enemy_zone.to_upper().strip_edges()
	match z:
		BattlefieldZoneScript.ZONE_GATE:
			if fortress.gate_hp > 0:
				var dmg: int = fortress.damage_gate(raw_damage)
				var breached: bool = fortress.is_gate_breached()
				return {
					"target": "GATE",
					"damage": dmg,
					"breached": breached,
					"destroyed": fortress.is_destroyed()
				}
			else:
				# Gerbang sudah jebol: damage tembus ke HP benteng utama!
				var dmg: int = fortress.take_damage(raw_damage)
				return {
					"target": "FORTRESS",
					"damage": dmg,
					"breached": true,
					"destroyed": fortress.is_destroyed()
				}

		BattlefieldZoneScript.ZONE_WALL:
			if fortress.wall_hp > 0:
				var dmg: int = fortress.damage_wall(raw_damage)
				var breached: bool = fortress.is_wall_breached()
				return {
					"target": "WALL",
					"damage": dmg,
					"breached": breached,
					"destroyed": fortress.is_destroyed()
				}
			else:
				# Tembok sudah runtuh: damage tembus ke HP benteng utama!
				var dmg: int = fortress.take_damage(raw_damage)
				return {
					"target": "FORTRESS",
					"damage": dmg,
					"breached": true,
					"destroyed": fortress.is_destroyed()
				}

		BattlefieldZoneScript.ZONE_FORTRESS:
			var dmg: int = fortress.take_damage(raw_damage)
			return {
				"target": "FORTRESS",
				"damage": dmg,
				"breached": true,
				"destroyed": fortress.is_destroyed()
			}

		_:
			# Musuh di OUTER_FIELD, APPROACH, atau FLANK belum menyentuh struktur pertahanan
			return {
				"target": "NONE",
				"damage": 0,
				"breached": false,
				"destroyed": fortress.is_destroyed()
			}


## Resolusi korban serdadu agregat berdasarkan akumulasi tekanan (Phase 6E).
func resolve_soldier_casualties(
	deployment: DeploymentComposition,
	accumulated_pressure: int,
	threshold: int = CASUALTY_PRESSURE_THRESHOLD
) -> Dictionary:
	if deployment == null or deployment.count <= 0 or accumulated_pressure < threshold:
		return {
			"casualties": 0,
			"remaining_pressure": accumulated_pressure,
			"role": deployment.resolved_role if deployment != null else ""
		}

	var effective_threshold: int = threshold
	if deployment.formation == "BACKLINE":
		effective_threshold = int(float(threshold) * 1.40) # Lebih aman
	elif deployment.formation == "SUPPORT":
		effective_threshold = int(float(threshold) * 1.25)

	var possible_deaths: int = int(floor(float(accumulated_pressure) / float(effective_threshold)))
	var actual_deaths: int = clampi(possible_deaths, 0, deployment.count)
	var pressure_consumed: int = actual_deaths * effective_threshold

	return {
		"casualties": actual_deaths,
		"remaining_pressure": maxi(0, accumulated_pressure - pressure_consumed),
		"role": deployment.resolved_role
	}


## Evaluasi bahaya dan kelangsungan hidup pahlawan Party 1 pada tick pertempuran (Phase 6E).
func resolve_hero_danger(
	hero: HeroModel,
	incoming_pressure: int,
	threat_budget: int = 100,
	fortress_destroyed: bool = false,
	tick: int = 0,
	seed_val: int = 42
) -> bool:
	if hero == null or not hero.is_alive or hero.lifecycle_state == HeroLifecycleState.PERMADEATH:
		return false

	if incoming_pressure <= 0 and not fortress_destroyed:
		return false

	var base_danger: float = 0.0
	if fortress_destroyed:
		base_danger = 0.40 + 0.30 * clampf(float(incoming_pressure) / float(maxi(1, threat_budget)), 0.0, 1.0)
	else:
		if incoming_pressure > hero.get_effective_def() * 2:
			base_danger = 0.05 + 0.25 * clampf(float(incoming_pressure) / float(maxi(1, threat_budget)), 0.0, 1.0)

	if base_danger <= 0.0:
		return false

	var fatigue_factor: float = 1.0 + (float(hero.fatigue) / 100.0) * 0.50
	var def_factor: float = 80.0 / (80.0 + float(hero.get_effective_def()))
	var death_prob: float = clampf(base_danger * fatigue_factor * def_factor, 0.0, 0.75)

	var roll: float = _seeded_float(seed_val, hero.hero_id, tick * 23 + 7)
	if roll < death_prob:
		hero.mark_dead()
		return true
	return false


## Resolusi aus dan kehancuran perlengkapan serdadu akibat korban jiwa deterministik (Phase 6E).
func resolve_soldier_equipment_loss(role: String, casualty_count: int, seed_val: int, step_num: int = 0) -> Dictionary:
	var destroyed_count: int = 0
	var damaged_count: int = 0
	for i in range(casualty_count):
		var roll: float = _seeded_float(seed_val, role, (step_num + i) * 17)
		if roll < 0.35:
			destroyed_count += 1
		else:
			damaged_count += 1
	return {
		"destroyed": destroyed_count,
		"damaged": damaged_count
	}



func simulate_battle(population: PopulationModel, heroes: Array, warehouse_equipment: Array, fortress: FortressModel, wave: Dictionary, seed_val: int = 42) -> Dictionary:
	assert(population != null, "population tidak boleh null")
	assert(fortress != null, "fortress tidak boleh null")
	assert(wave.has("enemies"), "wave harus memiliki dictionary enemies")
	
	var enemies: Dictionary = (wave["enemies"] as Dictionary).duplicate(true)
	var initial_fortress_hp: int = fortress.current_hp
	var threat_budget: int = int(wave.get("threat_budget", 50))
	var wave_num: int = int(wave.get("wave", 1))
	
	# === FASE 1: RANGED VOLLEY ===
	# Pemanah menembak musuh sebelum mendekati tembok.
	var archers: int = int(population.soldiers.get("ARCHER", 0))
	var archer_calc: Dictionary = calculate_role_power(archers, 16.0, "BOW", warehouse_equipment, population.morale)
	var archer_power: float = float(archer_calc["power"])
	
	# Panah memprioritaskan Flyer (+50% dmg) dan Minion (+30% dmg)
	var flyer_damage_capacity: float = archer_power * 0.60
	var minion_damage_capacity: float = archer_power * 0.40
	
	var flyers_killed: int = mini(int(enemies.get("FLYER", 0)), int(floor(flyer_damage_capacity / 12.0 * 1.50)))
	var minions_killed_ranged: int = mini(int(enemies.get("MINION", 0)), int(floor(minion_damage_capacity / 2.0 * 1.30)))
	
	enemies["FLYER"] = int(enemies.get("FLYER", 0)) - flyers_killed
	enemies["MINION"] = int(enemies.get("MINION", 0)) - minions_killed_ranged
	
	# === FASE 2: FRONTLINE CLASH ===
	# Shield Infantry menahan benturan, Spearman menyerang Brute (+40% bonus)
	var shield_infantry: int = int(population.soldiers.get("SHIELD_INFANTRY", 0))
	var spearman: int = int(population.soldiers.get("SPEARMAN", 0))
	
	var shield_calc: Dictionary = calculate_role_power(shield_infantry, 18.0, "SHIELD", warehouse_equipment, population.morale)
	var spear_calc: Dictionary = calculate_role_power(spearman, 12.0, "SPEAR", warehouse_equipment, population.morale)
	
	var shield_defense: float = float(shield_calc["power"])
	var spear_power: float = float(spear_calc["power"])
	
	var brutes_killed: int = mini(int(enemies.get("BRUTE", 0)), int(floor(spear_power * 1.40 / 16.0)))
	enemies["BRUTE"] = int(enemies.get("BRUTE", 0)) - brutes_killed
	
	# === FASE 3: MELEE & HERO ENGAGEMENT ===
	# Swordsman, Heavy Infantry, dan Hero melawan Raiders & sisa musuh
	var swordsmen: int = int(population.soldiers.get("SWORDSMAN", 0))
	var heavy_infantry: int = int(population.soldiers.get("HEAVY_INFANTRY", 0))
	var mercenaries: int = population.mercenaries
	
	var sword_calc: Dictionary = calculate_role_power(swordsmen, 14.0, "SWORD", warehouse_equipment, population.morale)
	var heavy_calc: Dictionary = calculate_role_power(heavy_infantry, 20.0, "HEAVY_ARMOR", warehouse_equipment, population.morale)
	
	var sword_power: float = float(sword_calc["power"])
	var heavy_power: float = float(heavy_calc["power"])
	var merc_power: float = float(mercenaries * 15)
	
	# Kontribusi Hero Aktif (Hero mati dilarang berkontribusi)
	var hero_total_atk: float = 0.0
	var party_hero_ids: Array = []
	for h in heroes:
		if h is HeroModel and (h as HeroModel).is_alive:
			party_hero_ids.append((h as HeroModel).hero_id)
			
	for h in heroes:
		if h is HeroModel and (h as HeroModel).is_alive:
			var hero_obj: HeroModel = h as HeroModel
			hero_total_atk += float(hero_obj.get_effective_atk(party_hero_ids))
			hero_obj.add_fatigue(15) # Menambah kelelahan per battle
					
	var melee_total_power: float = sword_power + heavy_power + merc_power + hero_total_atk
	
	var raiders_killed: int = mini(int(enemies.get("RAIDER", 0)), int(floor(melee_total_power * 0.60 / 6.0)))
	var minions_killed_melee: int = mini(int(enemies.get("MINION", 0)), int(floor(melee_total_power * 0.40 / 2.0)))
	
	enemies["RAIDER"] = int(enemies.get("RAIDER", 0)) - raiders_killed
	enemies["MINION"] = int(enemies.get("MINION", 0)) - minions_killed_melee
	
	# === FASE 4: WALL BREACH & SIEGE ASSAULT ===
	# Sisa musuh yang belum tereliminasi menyerang benteng secara langsung
	var residual_threat: int = (
		int(enemies.get("MINION", 0)) * 2 +
		int(enemies.get("RAIDER", 0)) * 6 +
		int(enemies.get("BRUTE", 0)) * 16 +
		int(enemies.get("FLYER", 0)) * 12 +
		int(enemies.get("SIEGE", 0)) * 40 +
		int(enemies.get("BOSS", 0)) * 120
	)
	
	# Shield infantry menyerap sebagian residual threat sebelum mengenai tembok
	var threat_absorbed_by_shield: int = mini(residual_threat, int(floor(shield_defense * 0.50)))
	var breach_threat: int = residual_threat - threat_absorbed_by_shield
	
	var actual_damage_taken: int = 0
	if breach_threat > 0:
		actual_damage_taken = fortress.take_damage(breach_threat)
		
	# === FASE 5: RESOLUSI KORBAN, EQUIPMENT LOSS, HERO DEATH, EXP, & LOOT ===
	var casualties: Dictionary = {
		"SWORDSMAN": 0,
		"SHIELD_INFANTRY": 0,
		"SPEARMAN": 0,
		"ARCHER": 0,
		"HEAVY_INFANTRY": 0
	}
	
	var casualty_severity: float = float(breach_threat) / float(maxi(1, threat_budget))
	casualty_severity = clampf(casualty_severity, 0.0, 0.60)
	
	if shield_infantry > 0:
		casualties["SHIELD_INFANTRY"] = int(ceil(float(shield_infantry) * casualty_severity * 0.35))
	if swordsmen > 0:
		casualties["SWORDSMAN"] = int(ceil(float(swordsmen) * casualty_severity * 0.25))
	if spearman > 0:
		casualties["SPEARMAN"] = int(ceil(float(spearman) * casualty_severity * 0.20))
	if archers > 0 and breach_threat > 100:
		casualties["ARCHER"] = int(ceil(float(archers) * casualty_severity * 0.10))
		
	var total_dead_soldiers: int = population.apply_casualties(casualties)
	
	# 5.A: Implementasi Ausnya Perlengkapan & Kehilangan Perlengkapan (Equipment Loss)
	var eq_loss_summary: Dictionary = _resolve_equipment_wear_and_loss(warehouse_equipment, casualties, casualty_severity, seed_val)
	
	# 5.B: Evaluasi Kelangsungan Hidup Hero Deterministik (Hero Survival & Death)
	var hero_death_summary: Dictionary = _resolve_hero_survival_and_death(heroes, breach_threat, threat_budget, fortress.is_destroyed(), wave_num, seed_val)
	
	# 5.C: Perolehan EXP Hero yang masih hidup
	var total_battle_exp: int = calculate_battle_exp(wave_num)
	var surviving_heroes: Array = []
	for h in heroes:
		if h is HeroModel and (h as HeroModel).is_alive:
			surviving_heroes.append(h as HeroModel)
	var exp_distribution: Dictionary = distribute_battle_exp(total_battle_exp, surviving_heroes)
	var exp_gained_per_hero: int = total_battle_exp / maxi(1, surviving_heroes.size()) if not surviving_heroes.is_empty() else 0

	# 5.D: Kemitraan (Chemistry) antar pahlawan yang selamat bertarung bersama (tepat 1x per pasangan)
	for i in range(surviving_heroes.size()):
		var h_a: HeroModel = surviving_heroes[i] as HeroModel
		for j in range(i + 1, surviving_heroes.size()):
			var h_b: HeroModel = surviving_heroes[j] as HeroModel
			h_a.add_chemistry(h_b.hero_id, 2)
			h_b.add_chemistry(h_a.hero_id, 2)
			
	# 5.E: Hasil Pertempuran & Loot Emas
	var is_victory: bool = not fortress.is_destroyed() and (breach_threat <= int(fortress.max_hp * 0.40))
	var loot_gold: int = 0
	if is_victory:
		# Battle Loot adalah sumber pendapatan utama ekonomi
		loot_gold = int(floor(float(threat_budget) * 1.30))
		population.morale = clampi(population.morale + 2, 50, 150)
	else:
		population.morale = clampi(population.morale - 12, 30, 150)
		
	return {
		"victory": is_victory,
		"game_over": fortress.is_destroyed(),
		"initial_fortress_hp": initial_fortress_hp,
		"final_fortress_hp": fortress.current_hp,
		"fortress_damage_taken": actual_damage_taken,
		"total_dead_soldiers": total_dead_soldiers,
		"casualties_by_role": casualties,
		"casualties": casualties,
		"breach_threat": breach_threat,
		"loot_gold": loot_gold,
		"exp_per_hero": exp_gained_per_hero,
		"battle_exp_total": total_battle_exp,
		"exp_distribution": exp_distribution,
		"equipment_lost": eq_loss_summary["lost_items"],
		"equipment_damaged": eq_loss_summary["damaged_items"],
		"heroes_killed": hero_death_summary["killed"],
		"heroes_survived": hero_death_summary["survived"]
	}


## Menghitung kekuatan peran berdasarkan distribusi kuantitas equipment secara agregat
## Memastikan 1 item tidak memberikan bonus Tier ke seluruh pasukan!
func calculate_role_power(soldiers_count: int, base_stat: float, role: String, warehouse: Array, morale: int) -> Dictionary:
	if soldiers_count <= 0:
		return {"power": 0.0, "equipped_count": 0, "tier_usage": {}}
		
	# 1. Kumpulkan seluruh equipment yang cocok dan tidak rusak
	var usable_items: Array = []
	for item in warehouse:
		if item is EquipmentModel:
			var eq: EquipmentModel = item as EquipmentModel
			if eq.role_type == role and not eq.is_broken() and eq.quantity > 0:
				usable_items.append(eq)
				
	# 2. Urutkan dari Tier tertinggi ke terendah
	usable_items.sort_custom(func(a: EquipmentModel, b: EquipmentModel) -> bool:
		return a.tier > b.tier
	)
	
	# 3. Alokasikan ke serdadu
	var remaining_soldiers: int = soldiers_count
	var total_power: float = 0.0
	var tier_usage: Dictionary = {}
	var total_equipped: int = 0
	
	for item in usable_items:
		if remaining_soldiers <= 0:
			break
		var eq: EquipmentModel = item as EquipmentModel
		var alloc: int = mini(remaining_soldiers, eq.quantity)
		var mult: float = _get_tier_multiplier(eq.tier)
		total_power += float(alloc) * base_stat * mult
		tier_usage[eq.tier] = int(tier_usage.get(eq.tier, 0)) + alloc
		total_equipped += alloc
		remaining_soldiers -= alloc
		
	# 4. Serdadu yang tidak kebagian equipment menggunakan pengali unequipped (1.0x)
	if remaining_soldiers > 0:
		total_power += float(remaining_soldiers) * base_stat * 1.0
		tier_usage[0] = remaining_soldiers
		
	# 5. Kalikan dengan moral pasukan
	total_power = total_power * (float(morale) / 100.0)
	
	return {
		"power": total_power,
		"equipped_count": total_equipped,
		"tier_usage": tier_usage
	}


func _get_tier_multiplier(tier: int) -> float:
	match tier:
		1: return 1.15
		2: return 1.35
		3: return 1.65
		4: return 2.05
		5: return 2.60
		_: return 1.0


## Resolusi ausnya equipment dan kehilangan equipment deterministik saat ada prajurit gugur
func _resolve_equipment_wear_and_loss(warehouse: Array, casualties: Dictionary, severity: float, seed_val: int) -> Dictionary:
	var lost_count: int = 0
	var damaged_count: int = 0
	var role_map: Dictionary = {
		"SWORDSMAN": "SWORD",
		"SHIELD_INFANTRY": "SHIELD",
		"SPEARMAN": "SPEAR",
		"ARCHER": "BOW",
		"HEAVY_INFANTRY": "HEAVY_ARMOR"
	}
	
	# 1. Sesuai rule baru Phase 3D: Prajurit yang selamat perlengkapannya tetap 100% durability (tidak ada aus normal).
	# Hanya prajurit yang gugur (casualties) yang memicu casualty-equipment resolution (35% destroyed, 65% damaged).
			
	# 2. Kehilangan perlengkapan akibat prajurit yang gugur (Casualty-Equipment Loss)
	for role in casualties:
		var deaths: int = int(casualties[role])
		if deaths <= 0:
			continue
		var eq_role: String = str(role_map.get(role, ""))
		if eq_role.is_empty():
			continue
			
		# Cari equipment yang sesuai
		for i in range(deaths):
			for item in warehouse:
				if item is EquipmentModel:
					var eq: EquipmentModel = item as EquipmentModel
					if eq.role_type == eq_role and eq.quantity > 0:
						# Seeded roll: 35% hilang total, 65% rusak berat diselamatkan
						var roll: float = _seeded_float(seed_val, eq_role, i * 17)
						if roll < 0.35:
							eq.quantity -= 1
							lost_count += 1
						else:
							eq.apply_wear(40)
							damaged_count += 1
						break
						
	return {
		"lost_items": lost_count,
		"damaged_items": damaged_count
	}


## Evaluasi kelangsungan hidup Hero deterministik (Hero Survival & Death)
func _resolve_hero_survival_and_death(heroes: Array, breach_threat: int, threat_budget: int, fortress_destroyed: bool, wave_num: int, seed_val: int) -> Dictionary:
	var killed_heroes: Array = []
	var survived_heroes: Array = []
	
	for h in heroes:
		if not (h is HeroModel):
			continue
		var hero: HeroModel = h as HeroModel
		if not hero.is_alive:
			continue # Hero yang sudah mati tidak diproses lagi
			
		var breach_ratio: float = float(breach_threat) / float(maxi(1, threat_budget))
		var base_danger: float = 0.0
		
		if fortress_destroyed:
			# Benteng runtuh: bahaya tinggi (50% - 90%), TETAPI tidak otomatis 100% mati
			base_danger = 0.50 + 0.40 * clampf(breach_ratio, 0.0, 1.0)
		else:
			if breach_threat <= 0:
				base_danger = 0.0 # Tidak ada bahaya jika musuh tertahan total
			else:
				base_danger = 0.05 + 0.35 * clampf(breach_ratio, 0.0, 1.0)
				
		# Faktor kelelahan hero (fatigue tinggi = risiko kematian bertambah)
		var fatigue_factor: float = 1.0 + (float(hero.fatigue) / 100.0) * 0.60
		# Faktor pertahanan hero (def tinggi memitigasi bahaya)
		var def_factor: float = 80.0 / (80.0 + float(hero.get_effective_def()))
		
		var death_prob: float = clampf(base_danger * fatigue_factor * def_factor, 0.0, 0.85)
		var roll: float = _seeded_float(seed_val, hero.hero_id, wave_num * 31)
		
		if roll < death_prob and base_danger > 0.0:
			hero.mark_dead()
			killed_heroes.append(hero.hero_id)
		else:
			survived_heroes.append(hero.hero_id)
			
	return {
		"killed": killed_heroes,
		"survived": survived_heroes
	}


func _seeded_float(seed_val: int, key: String, step_num: int) -> float:
	var h: int = seed_val ^ (step_num * 1274126177)
	for b in key.to_utf8_buffer():
		h = (h * 31 + int(b)) ^ 0x45d9f3b
	h = (h ^ (h >> 15)) * 0x45d9f3b
	return float(abs(h % 10000)) / 10000.0


# ==============================================================================
# PHASE 4B BATTLE EXP FORMULA & DETERMINISTIC DISTRIBUTION
# ==============================================================================

## Menghitung total EXP pertempuran kanonikal untuk gelombang tertentu:
## floor(60.0 * (1.0 + wave / 15.0))
static func calculate_battle_exp(wave_num: int) -> int:
	return int(floor(60.0 * (1.0 + float(wave_num) / 15.0)))


## Membagikan total battle EXP secara merata dan deterministik kepada hero yang bertahan hidup
static func distribute_battle_exp(total_exp: int, surviving_heroes: Array) -> Dictionary:
	var distribution: Dictionary = {}
	if surviving_heroes.is_empty() or total_exp <= 0:
		return distribution

	var sorted_heroes: Array = surviving_heroes.duplicate()
	sorted_heroes.sort_custom(func(a: HeroModel, b: HeroModel) -> bool:
		return a.hero_id < b.hero_id
	)

	var count: int = sorted_heroes.size()
	var base_share: int = total_exp / count
	var remainder: int = total_exp % count

	var total_distributed: int = 0
	for i in range(count):
		var h: HeroModel = sorted_heroes[i] as HeroModel
		var share: int = base_share + (1 if i < remainder else 0)
		h.add_exp(share)
		distribution[h.hero_id] = share
		total_distributed += share

	assert(total_distributed <= total_exp, "Total distributed EXP melebihi total EXP yang diberikan")
	return distribution
