class_name CombatEngine
extends RefCounted

## CombatEngine
## Engine kalkulasi pertempuran headless deterministik multi-fase (Phase 1 - 5).
## Dilarang mereduksi pertempuran menjadi satu angka Battle Power tunggal!

const PopulationModelScript = preload("res://scripts/domain/model/population_model.gd")
const FortressModelScript = preload("res://scripts/domain/model/fortress_model.gd")
const HeroModelScript = preload("res://scripts/domain/model/hero_model.gd")
const EquipmentModelScript = preload("res://scripts/domain/model/equipment_model.gd")


func simulate_battle(population: PopulationModel, heroes: Array, warehouse_equipment: Array, fortress: FortressModel, wave: Dictionary, seed_val: int = 42) -> Dictionary:
	assert(population != null, "population tidak boleh null")
	assert(fortress != null, "fortress tidak boleh null")
	assert(wave.has("enemies"), "wave harus memiliki dictionary enemies")
	
	var enemies: Dictionary = (wave["enemies"] as Dictionary).duplicate(true)
	var initial_fortress_hp: int = fortress.current_hp
	
	# === FASE 1: RANGED VOLLEY ===
	# Pemanah menembak musuh sebelum mendekati tembok.
	var archers: int = int(population.soldiers.get("ARCHER", 0))
	var archer_gear_tier: int = _get_best_tier_for_role(warehouse_equipment, "BOW")
	var archer_power: float = float(archers * 16) * _get_tier_multiplier(archer_gear_tier) * (float(population.morale) / 100.0)
	
	# Panah memprioritaskan Flyer (+50% dmg) dan Minion (+30% dmg)
	var flyer_threat: int = int(enemies.get("FLYER", 0)) * 12
	var minion_threat: int = int(enemies.get("MINION", 0)) * 2
	
	var flyer_damage_capacity: float = archer_power * 0.60
	var minion_damage_capacity: float = archer_power * 0.40
	
	var flyers_killed: int = mini(int(enemies.get("FLYER", 0)), int(floor(flyer_damage_capacity / 12.0 * 1.50)))
	var minions_killed_ranged: int = mini(int(enemies.get("MINION", 0)), int(floor(minion_damage_capacity / 2.0 * 1.30)))
	
	enemies["FLYER"] = int(enemies["FLYER"]) - flyers_killed
	enemies["MINION"] = int(enemies["MINION"]) - minions_killed_ranged
	
	# === FASE 2: FRONTLINE CLASH ===
	# Shield Infantry menahan benturan, Spearman menyerang Brute (+40% bonus)
	var shield_infantry: int = int(population.soldiers.get("SHIELD_INFANTRY", 0))
	var spearman: int = int(population.soldiers.get("SPEARMAN", 0))
	
	var shield_tier: int = _get_best_tier_for_role(warehouse_equipment, "SHIELD")
	var spear_tier: int = _get_best_tier_for_role(warehouse_equipment, "SPEAR")
	
	var shield_defense: float = float(shield_infantry * 18) * _get_tier_multiplier(shield_tier) * (float(population.morale) / 100.0)
	var spear_power: float = float(spearman * 12) * _get_tier_multiplier(spear_tier) * (float(population.morale) / 100.0)
	
	var brutes_killed: int = mini(int(enemies.get("BRUTE", 0)), int(floor(spear_power * 1.40 / 16.0)))
	enemies["BRUTE"] = int(enemies["BRUTE"]) - brutes_killed
	
	# === FASE 3: MELEE & HERO ENGAGEMENT ===
	# Swordsman, Heavy Infantry, dan Hero melawan Raiders & sisa musuh
	var swordsmen: int = int(population.soldiers.get("SWORDSMAN", 0))
	var heavy_infantry: int = int(population.soldiers.get("HEAVY_INFANTRY", 0))
	var mercenaries: int = population.mercenaries
	
	var sword_tier: int = _get_best_tier_for_role(warehouse_equipment, "SWORD")
	var heavy_tier: int = _get_best_tier_for_role(warehouse_equipment, "HEAVY_ARMOR")
	
	var sword_power: float = float(swordsmen * 14) * _get_tier_multiplier(sword_tier) * (float(population.morale) / 100.0)
	var heavy_power: float = float(heavy_infantry * 20) * _get_tier_multiplier(heavy_tier) * (float(population.morale) / 100.0)
	var merc_power: float = float(mercenaries * 15)
	
	# Kontribusi Hero
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
			# Tingkatkan chemistry antar hero di party
			for other_id in party_hero_ids:
				if str(other_id) != hero_obj.hero_id:
					hero_obj.add_chemistry(str(other_id), 2)
					
	var melee_total_power: float = sword_power + heavy_power + merc_power + hero_total_atk
	
	var raiders_killed: int = mini(int(enemies.get("RAIDER", 0)), int(floor(melee_total_power * 0.60 / 6.0)))
	var minions_killed_melee: int = mini(int(enemies.get("MINION", 0)), int(floor(melee_total_power * 0.40 / 2.0)))
	
	enemies["RAIDER"] = int(enemies["RAIDER"]) - raiders_killed
	enemies["MINION"] = int(enemies["MINION"]) - minions_killed_melee
	
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
		
	# === FASE 5: RESOLUSI KORBAN, WEAR, EXP, DAN LOOT ===
	var casualties: Dictionary = {
		"SWORDSMAN": 0,
		"SHIELD_INFANTRY": 0,
		"SPEARMAN": 0,
		"ARCHER": 0,
		"HEAVY_INFANTRY": 0
	}
	
	# Lini depan (Shield, Swordsman, Spearman) mengambil porsi korban terbesar
	var casualty_severity: float = float(breach_threat) / float(maxi(1, int(wave.get("threat_budget", 100))))
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
	
	# Ausnya perlengkapan
	_apply_equipment_wear(warehouse_equipment, 10 + int(casualty_severity * 10.0))
	
	# Perolehan EXP Hero
	var wave_num: int = int(wave.get("wave", 1))
	var exp_gained_per_hero: int = int(floor(60.0 * (1.0 + float(wave_num) / 15.0)))
	for h in heroes:
		if h is HeroModel and (h as HeroModel).is_alive:
			(h as HeroModel).add_exp(exp_gained_per_hero)
			
	# Cek Permadeath Hero jika benteng hancur atau breach bencana alam
	if fortress.is_destroyed():
		for h in heroes:
			if h is HeroModel:
				(h as HeroModel).mark_dead()
				
	# Loot emas
	var is_victory: bool = not fortress.is_destroyed() and (breach_threat <= int(fortress.max_hp * 0.40))
	var loot_gold: int = 0
	if is_victory:
		loot_gold = int(floor(float(wave.get("threat_budget", 50)) * 0.35))
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
		"breach_threat": breach_threat,
		"loot_gold": loot_gold,
		"exp_per_hero": exp_gained_per_hero
	}


func _get_best_tier_for_role(warehouse: Array, role: String) -> int:
	var best_tier: int = 1
	for item in warehouse:
		if item is EquipmentModel and (item as EquipmentModel).role_type == role:
			var eq: EquipmentModel = item as EquipmentModel
			if not eq.is_broken():
				best_tier = maxi(best_tier, eq.tier)
	return best_tier


func _get_tier_multiplier(tier: int) -> float:
	match tier:
		1: return 1.15
		2: return 1.35
		3: return 1.65
		4: return 2.05
		5: return 2.60
		_: return 1.0


func _apply_equipment_wear(warehouse: Array, wear_amount: int) -> void:
	for item in warehouse:
		if item is EquipmentModel:
			(item as EquipmentModel).apply_wear(wear_amount)
