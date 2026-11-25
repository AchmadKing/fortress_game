class_name WaveGenerator
extends RefCounted

## WaveGenerator
## Generator komposisi ancaman gelombang musuh (Wave 1 - 100).
## Menggunakan kurva ancaman deterministik dengan variasi terkontrol (anti-spike).


func calculate_threat_budget(wave: int, seed_val: int = 0) -> int:
	assert(wave >= 1, "wave harus >= 1")
	if wave <= 5:
		# Wave 1 - 5: Ramp tutorial linier terkendali
		return 25 + (wave - 1) * 15 # 25, 40, 55, 70, 85
		
	# Wave 6+: Power scaling halus (1.30)
	var base_tb: float = 85.0 * pow(float(wave) / 5.0, 1.30)
	
	# Variasi terkontrol deterministik (+- 6%) berbasis hash
	var pseudo_rand: float = _pseudo_random_range(wave, seed_val, -0.06, 0.06)
	return int(floor(base_tb * (1.0 + pseudo_rand)))


func generate_wave(wave: int, seed_val: int = 12345) -> Dictionary:
	var budget: int = calculate_threat_budget(wave, seed_val)
	var enemies: Dictionary = {
		"MINION": 0,
		"RAIDER": 0,
		"BRUTE": 0,
		"FLYER": 0,
		"SIEGE": 0,
		"BOSS": 0
	}
	
	var remaining: int = budget
	
	# Boss wave (tiap kelipatan 10 wave)
	if wave % 10 == 0:
		var boss_count: int = wave / 10
		var boss_cost: int = 100 + (wave - 10) * 8
		enemies["BOSS"] = boss_count
		remaining = maxi(0, remaining - (boss_count * boss_cost))
		
	# Siege engine (mulai wave 12+)
	if wave >= 12 and remaining >= 40:
		var siege_share: int = int(floor(float(remaining) * 0.20))
		var num_siege: int = siege_share / 40
		enemies["SIEGE"] = num_siege
		remaining -= num_siege * 40
		
	# Flyer (mulai wave 6+)
	if wave >= 6 and remaining >= 24:
		var flyer_share: int = int(floor(float(remaining) * 0.25))
		var num_flyers: int = flyer_share / 12
		enemies["FLYER"] = num_flyers
		remaining -= num_flyers * 12
		
	# Brute (mulai wave 6+)
	if wave >= 6 and remaining >= 32:
		var brute_share: int = int(floor(float(remaining) * 0.30))
		var num_brutes: int = brute_share / 16
		enemies["BRUTE"] = num_brutes
		remaining -= num_brutes * 16
		
	# Raider (mulai wave 3+)
	if wave >= 3 and remaining >= 12:
		var raider_share: int = int(floor(float(remaining) * 0.50))
		var num_raiders: int = raider_share / 6
		enemies["RAIDER"] = num_raiders
		remaining -= num_raiders * 6
		
	# Minion (sisa budget)
	var minions: int = remaining / 2
	enemies["MINION"] = minions
	
	return {
		"wave": wave,
		"threat_budget": budget,
		"enemies": enemies
	}


func _pseudo_random_range(wave: int, seed_val: int, min_val: float, max_val: float) -> float:
	# Hash deterministik murni tanpa memanggil modul global Random
	var hash_val: int = (wave * 374761393 + seed_val * 668265263) ^ 0x5bf03635
	hash_val = (hash_val ^ (hash_val >> 13)) * 1274126177
	var normalized: float = float(abs(hash_val % 10000)) / 10000.0
	return min_val + normalized * (max_val - min_val)
