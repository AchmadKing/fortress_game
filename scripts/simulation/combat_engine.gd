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
	
	enemies["FLYER"] = int(enemies["FLYER"]) - flyers_killed
	enemies["MINION"] = int(enemies["MINION"]) - minions_killed_ranged
	
	# === FASE 2: FRONTLINE CLASH ===
	# Shield Infantry menahan benturan, Spearman menyerang Brute (+40% bonus)
	var shield_infantry: int = int(population.soldiers.get("SHIELD_INFANTRY", 0))
	var spearman: int = int(population.soldiers.get("SPEARMAN", 0))
	
	var shield_calc: Dictionary = calculate_role_power(shield_infantry, 18.0, "SHIELD", warehouse_equipment, population.morale)
	var spear_calc: Dictionary = calculate_role_power(spearman, 12.0, "SPEAR", warehouse_equipment, population.morale)
	
	var shield_defense: float = float(shield_calc["power"])
	var spear_power: float = float(spear_calc["power"])
	
	var brutes_killed: int = mini(int(enemies.get("BRUTE", 0)), int(floor(spear_power * 1.40 / 16.0)))
	enemies["BRUTE"] = int(enemies["BRUTE"]) - brutes_killed
	
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
			# Tingkatkan chemistry antar hero aktif di party
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
	var exp_gained_per_hero: int = int(floor(60.0 * (1.0 + float(wave_num) / 15.0)))
	for h in heroes:
		if h is HeroModel and (h as HeroModel).is_alive:
			(h as HeroModel).add_exp(exp_gained_per_hero)
			
	# 5.D: Hasil Pertempuran & Loot Emas
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
		"breach_threat": breach_threat,
		"loot_gold": loot_gold,
		"exp_per_hero": exp_gained_per_hero,
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
	
	# 1. Aus standar pertempuran untuk semua equipment di warehouse
	var base_wear: int = 8 + int(severity * 10.0)
	for item in warehouse:
		if item is EquipmentModel:
			(item as EquipmentModel).apply_wear(base_wear)
			
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
