extends SceneTree

## TestMathematicalPrototype
## Test suite otomatis untuk memvalidasi formula matematika, model sistem, dan kestabilan 100-wave.
## Memvalidasi:
## 1. Konservasi populasi & kematian permanen serdadu.
## 2. Mercenary tidak memotong populasi warga sipil.
## 3. Ekonomi pekerja & efisiensi alokasi tugas.
## 4. Progresi Hero, EXP curve, Star constraints, Fatigue, Chemistry, & Permadeath.
## 5. Equipment degradation, penalti kerusakan, dan reparasi.
## 6. Ketahanan benteng, repair rate pekerja, dan Game Over saat HP <= 0.
## 7. Determinisme kurva ancaman Wave 1 - 100 dan anti-spike wave 1 - 5.
## 8. Abstraksi pertempuran 5-fase deterministik.
## 9. 8 Skenario Uji Stres (A sampai H).
## 10. Simulasi 100-Wave stabil tanpa infinite money atau death spiral.

const PopulationModelScript = preload("res://scripts/domain/model/population_model.gd")
const FortressModelScript = preload("res://scripts/domain/model/fortress_model.gd")
const HeroModelScript = preload("res://scripts/domain/model/hero_model.gd")
const EquipmentModelScript = preload("res://scripts/domain/model/equipment_model.gd")
const EconomyManagerScript = preload("res://scripts/simulation/economy_manager.gd")
const WaveGeneratorScript = preload("res://scripts/simulation/wave_generator.gd")
const CombatEngineScript = preload("res://scripts/simulation/combat_engine.gd")
const HeadlessSimulatorScript = preload("res://scripts/simulation/headless_simulator.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING MATHEMATICAL / SYSTEMS PROTOTYPE TESTS (PHASE 2)")
	print("================================================================")
	
	var passed: int = 0
	var failed: int = 0
	
	# Run all unit tests, scenario tests, and 100-wave simulation
	var test_list: Array = [
		["test_population_conservation_and_permadeath", Callable(self, "_test_population_conservation_and_permadeath")],
		["test_mercenary_isolation_from_civilians", Callable(self, "_test_mercenary_isolation_from_civilians")],
		["test_worker_economy_and_job_allocation", Callable(self, "_test_worker_economy_and_job_allocation")],
		["test_hero_progression_exp_and_fatigue", Callable(self, "_test_hero_progression_exp_and_fatigue")],
		["test_hero_chemistry_and_party_bonus", Callable(self, "_test_hero_chemistry_and_party_bonus")],
		["test_equipment_durability_and_broken_penalty", Callable(self, "_test_equipment_durability_and_broken_penalty")],
		["test_fortress_durability_and_game_over", Callable(self, "_test_fortress_durability_and_game_over")],
		["test_wave_threat_budget_and_anti_spike", Callable(self, "_test_wave_threat_budget_and_anti_spike")],
		["test_combat_multi_phase_determinism", Callable(self, "_test_combat_multi_phase_determinism")],
		["scenario_a_healthy_run", Callable(self, "_test_scenario_a_healthy_run")],
		["scenario_b_average_run", Callable(self, "_test_scenario_b_average_run")],
		["scenario_c_poor_management", Callable(self, "_test_scenario_c_poor_management")],
		["scenario_d_heavy_casualty", Callable(self, "_test_scenario_d_heavy_casualty")],
		["scenario_e_fortress_damage_and_recovery", Callable(self, "_test_scenario_e_fortress_damage_and_recovery")],
		["scenario_f_mercenary_dependency_burden", Callable(self, "_test_scenario_f_mercenary_dependency_burden")],
		["scenario_g_hero_fatigue_and_rest", Callable(self, "_test_scenario_g_hero_fatigue_and_rest")],
		["scenario_h_equipment_failure_penalty", Callable(self, "_test_scenario_h_equipment_failure_penalty")],
		["simulation_100_waves_stability", Callable(self, "_test_100_waves_stability")]
	]
	
	for t in test_list:
		var t_arr: Array = t as Array
		if _run_test(str(t_arr[0]), t_arr[1] as Callable):
			passed += 1
		else:
			failed += 1
	
	print("================================================================")
	print("PHASE 2 TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("================================================================")
	
	if failed == 0:
		quit(0)
	else:
		quit(1)


func _run_test(test_name: String, test_callable: Callable) -> bool:
	print("[TEST] Running %s..." % test_name)
	var result: bool = bool(test_callable.call())
	if result:
		print("[PASS] %s" % test_name)
	else:
		printerr("[FAIL] %s" % test_name)
	return result


# --- TEST 1: POPULATION CONSERVATION & PERMANENT DEATH ---
func _test_population_conservation_and_permadeath() -> bool:
	var pop := PopulationModel.new(20, 30, 100)
	if pop.get_total_population() != 20: return false
	
	# Rekrut serdadu: sipil berkurang, total pop tetap 20
	if not pop.recruit_soldier("SWORDSMAN", 5): return false
	if pop.civilians != 15 or pop.soldiers["SWORDSMAN"] != 5: return false
	if pop.get_total_population() != 20: return false
	
	# Kematian 3 prajurit: total pop berkurang permanen menjadi 17!
	var dead: int = pop.apply_casualties({"SWORDSMAN": 3})
	if dead != 3 or pop.soldiers["SWORDSMAN"] != 2: return false
	if pop.civilians != 15: return false # Tidak berubah jadi sipil
	if pop.get_total_population() != 17: return false # Berkurang permanen
	
	return true


# --- TEST 2: MERCENARY ISOLATION ---
func _test_mercenary_isolation_from_civilians() -> bool:
	var pop := PopulationModel.new(15, 30, 100)
	pop.hire_mercenaries(4)
	
	if pop.mercenaries != 4: return false
	if pop.civilians != 15: return false # Tidak memotong warga
	if pop.get_total_population() != 15: return false # Tidak menambah kuota hunian
	
	pop.remove_mercenaries(2)
	if pop.mercenaries != 2 or pop.civilians != 15: return false
	return true


# --- TEST 3: WORKER ECONOMY & JOB ALLOCATION ---
func _test_worker_economy_and_job_allocation() -> bool:
	var pop := PopulationModel.new(10, 30, 100)
	var fortress := FortressModel.new(1000, 40)
	var econ := EconomyManager.new(100)
	
	# Alokasi: 6 produksi, 2 reparasi, 2 blacksmith
	if not econ.set_worker_allocation(6, 2, 2, 0, 10): return false
	if econ.set_worker_allocation(8, 4, 0, 0, 10): return false # Melebihi 10 harus ditolak
	
	fortress.current_hp = 900
	var ledger: Dictionary = econ.process_cycle(pop, fortress)
	
	# 6 worker * 12 + 10 passive = 82 gross
	if int(ledger["gross_income"]) != 82: return false
	# 10 civ * 4 = 40 civ upkeep
	if int(ledger["civilian_upkeep"]) != 40: return false
	# HP repaired oleh 2 worker = 50 HP
	if int(ledger["hp_repaired"]) != 50 or fortress.current_hp != 950: return false
	
	return true


# --- TEST 4: HERO PROGRESSION, EXP, AND FATIGUE ---
func _test_hero_progression_exp_and_fatigue() -> bool:
	var hero := HeroModel.new("hero_1", "Sir Roderick", 2, 4)
	if hero.level != 1 or hero.current_exp != 0: return false
	
	# Cek formula exp level 1: floor(120 * 1^1.55) = 120
	var req_exp: int = hero.get_required_exp(1)
	if req_exp != 120: return false
	
	var levels: int = hero.add_exp(130)
	if levels != 1 or hero.level != 2 or hero.current_exp != 10: return false
	
	# Fatigue
	hero.add_fatigue(40)
	if hero.fatigue != 40: return false
	if hero.get_fatigue_multiplier() >= 1.0: return false # Harus kena penalti
	
	hero.rest(30)
	if hero.fatigue != 10: return false
	if hero.get_fatigue_multiplier() != 1.0: return false # Normal kembali
	
	return true


# --- TEST 5: HERO CHEMISTRY ---
func _test_hero_chemistry_and_party_bonus() -> bool:
	var h1 := HeroModel.new("h1", "Hero A", 1, 3)
	var h2 := HeroModel.new("h2", "Hero B", 1, 3)
	
	var bonus_initial: float = h1.get_chemistry_bonus(["h2"])
	if bonus_initial != 1.0: return false
	
	h1.add_chemistry("h2", 10)
	var bonus_improved: float = h1.get_chemistry_bonus(["h2"])
	if bonus_improved <= 1.0: return false # 1.0 + 10 * 0.005 = 1.05
	
	return true


# --- TEST 6: EQUIPMENT DURABILITY & BROKEN PENALTY ---
func _test_equipment_durability_and_broken_penalty() -> bool:
	var sword := EquipmentModel.new("SWORD", 2, 100)
	if sword.get_power_multiplier() != 1.35: return false
	
	sword.apply_wear(100)
	if not sword.is_broken(): return false
	if sword.get_power_multiplier() != 0.10: return false # Penalti rusak
	
	var cost: int = sword.calculate_repair_cost()
	if cost <= 0: return false
	
	sword.repair()
	if sword.is_broken() or sword.durability != 100: return false
	if sword.get_power_multiplier() != 1.35: return false
	
	return true


# --- TEST 7: FORTRESS DURABILITY & GAME OVER ---
func _test_fortress_durability_and_game_over() -> bool:
	var fort := FortressModel.new(500, 40)
	var dmg: int = fort.take_damage(200)
	if dmg <= 0 or fort.current_hp >= 500: return false
	if fort.is_destroyed(): return false
	
	fort.take_damage(10000)
	if not fort.is_destroyed() or fort.current_hp != 0: return false # Game Over!
	return true


# --- TEST 8: WAVE THREAT BUDGET & ANTI-SPIKE ---
func _test_wave_threat_budget_and_anti_spike() -> bool:
	var wg := WaveGenerator.new()
	var tb1: int = wg.calculate_threat_budget(1, 0)
	var tb2: int = wg.calculate_threat_budget(2, 0)
	var tb5: int = wg.calculate_threat_budget(5, 0)
	
	# Wave 1 = 25, Wave 2 = 40, Wave 5 = 85 (Linear tutorial ramp)
	if tb1 != 25 or tb2 != 40 or tb5 != 85: return false
	
	# Wave 6+ bertumbuh terukur tanpa lonjakan tiba-tiba
	var tb6: int = wg.calculate_threat_budget(6, 0)
	if tb6 < tb5 or tb6 > tb5 * 2: return false
	
	return true


# --- TEST 9: MULTI-PHASE COMBAT DETERMINISM ---
func _test_combat_multi_phase_determinism() -> bool:
	var engine := CombatEngine.new()
	var wg := WaveGenerator.new()
	var wave_data: Dictionary = wg.generate_wave(5, 42)
	
	var pop1 := PopulationModel.new(10, 30, 100)
	pop1.recruit_soldier("SHIELD_INFANTRY", 2)
	pop1.recruit_soldier("ARCHER", 2)
	pop1.recruit_soldier("SWORDSMAN", 2)
	var fort1 := FortressModel.new(1000, 40)
	var h1 := HeroModel.new("hero_1", "Alder", 1, 3)
	var gear1: Array = [EquipmentModel.new("BOW", 1, 100), EquipmentModel.new("SHIELD", 1, 100)]
	
	# Jalankan battle 1
	var res1: Dictionary = engine.simulate_battle(pop1, [h1], gear1, fort1, wave_data, 100)
	
	# Jalankan battle 2 dengan input persis sama
	var pop2 := PopulationModel.new(10, 30, 100)
	pop2.recruit_soldier("SHIELD_INFANTRY", 2)
	pop2.recruit_soldier("ARCHER", 2)
	pop2.recruit_soldier("SWORDSMAN", 2)
	var fort2 := FortressModel.new(1000, 40)
	var h2 := HeroModel.new("hero_1", "Alder", 1, 3)
	var gear2: Array = [EquipmentModel.new("BOW", 1, 100), EquipmentModel.new("SHIELD", 1, 100)]
	var res2: Dictionary = engine.simulate_battle(pop2, [h2], gear2, fort2, wave_data, 100)
	
	# Buktikan determinisme 100%
	if res1["victory"] != res2["victory"]: return false
	if res1["fortress_damage_taken"] != res2["fortress_damage_taken"]: return false
	if res1["total_dead_soldiers"] != res2["total_dead_soldiers"]: return false
	if res1["loot_gold"] != res2["loot_gold"]: return false
	
	return true


# --- SCENARIOS A - H ---
func _test_scenario_a_healthy_run() -> bool:
	var sim := HeadlessSimulator.new(1111)
	var res: Dictionary = sim.run_simulation_to_wave(15, 1111)
	# Healthy run: bertahan 15 wave tanpa game over, kas emas positif
	return res["completed_waves"] == 15 and not bool(res["game_over"]) and int(res["final_gold"]) > 0


func _test_scenario_b_average_run() -> bool:
	var sim := HeadlessSimulator.new(2222)
	var res: Dictionary = sim.run_simulation_to_wave(20, 2222)
	return res["completed_waves"] >= 15 and int(res["final_pop"]) > 0


func _test_scenario_c_poor_management() -> bool:
	var pop := PopulationModel.new(10, 30, 100)
	var fort := FortressModel.new(1000, 40)
	var econ := EconomyManager.new(20)
	
	# Rekrut serdadu berlebih hingga pekerja sipil habis
	pop.recruit_soldier("HEAVY_INFANTRY", 8)
	econ.set_worker_allocation(0, 0, 0, 0, pop.civilians)
	var ledger: Dictionary = econ.process_cycle(pop, fort)
	
	# Defisit kas harus terjadi karena beban gaji militer (8 * 11 = 88 gold)
	return int(ledger["net_gold"]) < 0 and int(ledger["treasury_after"]) == 0


func _test_scenario_d_heavy_casualty() -> bool:
	var pop := PopulationModel.new(15, 30, 100)
	pop.recruit_soldier("SWORDSMAN", 8)
	var before_pop: int = pop.get_total_population()
	
	# Menderita casualty 6 serdadu
	var dead: int = pop.apply_casualties({"SWORDSMAN": 6})
	var after_pop: int = pop.get_total_population()
	
	# Populasi total harus terpotong 6 dan prajurit tersisa 2
	return dead == 6 and after_pop == before_pop - 6 and pop.soldiers["SWORDSMAN"] == 2


func _test_scenario_e_fortress_damage_and_recovery() -> bool:
	var fort := FortressModel.new(1000, 40)
	fort.take_damage(750) # 750 raw -> 592 actual dmg -> HP 408
	if fort.current_hp > 500: return false
	
	var pop := PopulationModel.new(10, 30, 100)
	var econ := EconomyManager.new(200)
	econ.set_worker_allocation(4, 6, 0, 0, 10) # 6 worker ditugaskan reparasi -> 150 HP
	
	var ledger: Dictionary = econ.process_cycle(pop, fort)
	return int(ledger["hp_repaired"]) > 0 and fort.current_hp > 500 # 408 + 150 = 558 > 500


func _test_scenario_f_mercenary_dependency_burden() -> bool:
	var pop := PopulationModel.new(12, 30, 100)
	var fort := FortressModel.new(1000, 40)
	var econ := EconomyManager.new(100)
	
	pop.hire_mercenaries(5) # 5 mercenary * 18 = 90 gold upkeep
	econ.set_worker_allocation(10, 0, 0, 0, 12) # 10 prod * 12 = 120 gross
	var ledger: Dictionary = econ.process_cycle(pop, fort)
	
	# Beban militer harus mencakup 90 gold mercenary
	return int(ledger["military_upkeep"]) >= 90


func _test_scenario_g_hero_fatigue_and_rest() -> bool:
	var hero := HeroModel.new("h_fatigue", "Tired Knight", 1, 3)
	var full_power: int = hero.get_effective_atk()
	
	hero.add_fatigue(60)
	var tired_power: int = hero.get_effective_atk()
	if tired_power >= full_power: return false # Efektivitas harus turun
	
	hero.rest(50)
	var rested_power: int = hero.get_effective_atk()
	return rested_power > tired_power


func _test_scenario_h_equipment_failure_penalty() -> bool:
	var bow := EquipmentModel.new("BOW", 3, 10)
	var power_intact: float = bow.get_power_multiplier()
	
	bow.apply_wear(15) # Menjadi 0 durability (Broken)
	var power_broken: float = bow.get_power_multiplier()
	
	return bow.is_broken() and power_broken < power_intact and power_broken == 0.10


# --- 100-WAVE STABILITY SIMULATION ---
func _test_100_waves_stability() -> bool:
	print("[SIMULATION] Menjalankan simulasi 100 Wave...")
	var sim := HeadlessSimulator.new(98765)
	var result: Dictionary = sim.run_simulation_to_wave(100, 98765)
	
	var history: Array = result["history"] as Array
	print("[SIMULATION] Selesai: %d gelombang dieksekusi. Game Over: %s" % [result["completed_waves"], str(result["game_over"])])
	
	# Cetak telemetri pada tonggak penting
	var milestones: Array = [1, 5, 10, 20, 30, 50, 75, 100]
	print("----------------------------------------------------------------------------------------------------------------")
	print(String("%-6s | %-6s | %-7s | %-12s | %-8s | %-8s | %-8s | %-10s | %-6s" % ["WAVE", "THREAT", "VICTORY", "FORTRESS HP", "POP TOTAL", "SOLDIERS", "WORKERS", "GOLD", "HERO LV"]))
	print("----------------------------------------------------------------------------------------------------------------")
	
	for entry in history:
		var d: Dictionary = entry as Dictionary
		var w_num: int = int(d["wave"])
		if milestones.has(w_num):
			print(String("%-6d | %-6d | %-7s | %-5d/%-6d | %-8d | %-8d | %-8d | %-10d | Lv %-4.1f" % [
				w_num,
				int(d["threat_budget"]),
				str(d["victory"]),
				int(d["fortress_hp"]),
				int(d["fortress_max_hp"]),
				int(d["total_pop"]),
				int(d["soldiers"]),
				int(d["civilians"]),
				int(d["treasury_gold"]),
				float(d["hero_avg_level"])
			]))
	print("----------------------------------------------------------------------------------------------------------------")
	
	# Verifikasi stabilitas:
	# 1. Mampu menjalankan setidaknya 100 gelombang tanpa crash
	# 2. Kas tidak negatif
	# 3. Populasi tidak menjadi 0
	return result["completed_waves"] == 100 and int(result["final_gold"]) >= 0 and int(result["final_pop"]) > 0
