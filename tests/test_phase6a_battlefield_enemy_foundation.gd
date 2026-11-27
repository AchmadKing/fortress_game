extends SceneTree

## TestPhase6ABattlefieldEnemyFoundation
## Unit test suite untuk Phase 6A — Battlefield Zones & Enemy Foundation.
## Menguji:
## - Group A: Battlefield Zones & Invariants (Tests 1-6)
## - Group B: Zone Adjacency & Topology (Tests 7-12)
## - Group C: Enemy Archetypes & Attributes (Tests 13-18)
## - Group D: WaveGenerator Mapping & Determinism (Tests 19-24)
## - Group E: EnemyGroup Model & Invariants (Tests 25-30)

const BattlefieldZone = preload("res://scripts/domain/model/battlefield_zone.gd")
const EnemyArchetype = preload("res://scripts/domain/model/enemy_archetype.gd")
const EnemyGroup = preload("res://scripts/domain/model/enemy_group.gd")
const WaveGenerator = preload("res://scripts/simulation/wave_generator.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 6A BATTLEFIELD & ENEMY FOUNDATION TESTS")
	print("================================================================")

	var tests: Array[Dictionary] = [
		# Group A: Battlefield Zones & Invariants
		{"name": "test_a1_canonical_zones_exist_and_unique", "fn": Callable(self, "_test_a1_canonical_zones_exist_and_unique")},
		{"name": "test_a2_zone_factory_and_default_properties", "fn": Callable(self, "_test_a2_zone_factory_and_default_properties")},
		{"name": "test_a3_zone_defense_and_range_bonuses", "fn": Callable(self, "_test_a3_zone_defense_and_range_bonuses")},
		{"name": "test_a4_zone_interior_and_deployment_flags", "fn": Callable(self, "_test_a4_zone_interior_and_deployment_flags")},
		{"name": "test_a5_zone_invariants_strictly_enforced", "fn": Callable(self, "_test_a5_zone_invariants_strictly_enforced")},
		{"name": "test_a6_zone_clone_and_serialization_isolation", "fn": Callable(self, "_test_a6_zone_clone_and_serialization_isolation")},

		# Group B: Zone Adjacency & Topology
		{"name": "test_b1_canonical_adjacency_graph_complete", "fn": Callable(self, "_test_b1_canonical_adjacency_graph_complete")},
		{"name": "test_b2_adjacency_symmetry_and_bidirectionality", "fn": Callable(self, "_test_b2_adjacency_symmetry_and_bidirectionality")},
		{"name": "test_b3_no_self_references_in_adjacency", "fn": Callable(self, "_test_b3_no_self_references_in_adjacency")},
		{"name": "test_b4_outer_field_connections", "fn": Callable(self, "_test_b4_outer_field_connections")},
		{"name": "test_b5_barrier_and_core_topology", "fn": Callable(self, "_test_b5_barrier_and_core_topology")},
		{"name": "test_b6_adjacency_helper_methods_and_non_adjacent_detection", "fn": Callable(self, "_test_b6_adjacency_helper_methods_and_non_adjacent_detection")},

		# Group C: Enemy Archetypes & Attributes
		{"name": "test_c1_canonical_archetypes_defined", "fn": Callable(self, "_test_c1_canonical_archetypes_defined")},
		{"name": "test_c2_archetype_factory_and_attribute_verification", "fn": Callable(self, "_test_c2_archetype_factory_and_attribute_verification")},
		{"name": "test_c3_archetype_target_priorities", "fn": Callable(self, "_test_c3_archetype_target_priorities")},
		{"name": "test_c4_archetype_threat_costs_and_speed_ordering", "fn": Callable(self, "_test_c4_archetype_threat_costs_and_speed_ordering")},
		{"name": "test_c5_archetype_invariants_and_invalid_rejection", "fn": Callable(self, "_test_c5_archetype_invariants_and_invalid_rejection")},
		{"name": "test_c6_archetype_clone_and_dictionary_serialization", "fn": Callable(self, "_test_c6_archetype_clone_and_dictionary_serialization")},

		# Group D: WaveGenerator Mapping & Determinism
		{"name": "test_d1_legacy_enemy_type_mapping", "fn": Callable(self, "_test_d1_legacy_enemy_type_mapping")},
		{"name": "test_d2_wave_mapping_creates_enemy_groups", "fn": Callable(self, "_test_d2_wave_mapping_creates_enemy_groups")},
		{"name": "test_d3_wave_mapping_multi_archetype_distribution", "fn": Callable(self, "_test_d3_wave_mapping_multi_archetype_distribution")},
		{"name": "test_d4_wave_mapping_initial_spawn_in_outer_field", "fn": Callable(self, "_test_d4_wave_mapping_initial_spawn_in_outer_field")},
		{"name": "test_d5_wave_mapping_is_strictly_deterministic", "fn": Callable(self, "_test_d5_wave_mapping_is_strictly_deterministic")},
		{"name": "test_d6_wave_mapping_handles_empty_or_zero_counts", "fn": Callable(self, "_test_d6_wave_mapping_handles_empty_or_zero_counts")},

		# Group E: EnemyGroup Model & Invariants
		{"name": "test_e1_enemy_group_initialization_and_hp_pool", "fn": Callable(self, "_test_e1_enemy_group_initialization_and_hp_pool")},
		{"name": "test_e2_enemy_group_damage_absorption_and_casualty", "fn": Callable(self, "_test_e2_enemy_group_damage_absorption_and_casualty")},
		{"name": "test_e3_enemy_group_defeat_detection", "fn": Callable(self, "_test_e3_enemy_group_defeat_detection")},
		{"name": "test_e4_enemy_group_boss_scaling", "fn": Callable(self, "_test_e4_enemy_group_boss_scaling")},
		{"name": "test_e5_enemy_group_invariants_strictly_enforced", "fn": Callable(self, "_test_e5_enemy_group_invariants_strictly_enforced")},
		{"name": "test_e6_enemy_group_clone_and_dictionary_isolation", "fn": Callable(self, "_test_e6_enemy_group_clone_and_dictionary_isolation")}
	]

	var passed: int = 0
	var failed: int = 0

	for t in tests:
		print("[TEST] Running %s..." % t["name"])
		var result: bool = false
		var fn: Callable = t["fn"]
		result = fn.call()
		if result:
			passed += 1
			print("[PASS] %s" % t["name"])
		else:
			failed += 1
			printerr("[FAIL] %s" % t["name"])

	print("================================================================")
	print("PHASE 6A TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("================================================================")

	for c in root.get_children():
		root.remove_child(c)
		c.free()

	if failed == 0:
		quit(0)
	else:
		quit(1)


# ==============================================================================
# GROUP A: BATTLEFIELD ZONES & INVARIANTS
# ==============================================================================

func _test_a1_canonical_zones_exist_and_unique() -> bool:
	if BattlefieldZone.VALID_ZONES.size() != 7:
		printerr("Valid zones count mismatch: %d != 7" % BattlefieldZone.VALID_ZONES.size())
		return false
	var expected: Array[String] = [
		BattlefieldZone.ZONE_OUTER_FIELD,
		BattlefieldZone.ZONE_LEFT_FLANK,
		BattlefieldZone.ZONE_CENTER_APPROACH,
		BattlefieldZone.ZONE_RIGHT_FLANK,
		BattlefieldZone.ZONE_WALL,
		BattlefieldZone.ZONE_GATE,
		BattlefieldZone.ZONE_FORTRESS
	]
	var seen: Dictionary = {}
	for z in expected:
		if not BattlefieldZone.is_valid_zone(z):
			printerr("Zone not valid: %s" % z)
			return false
		if seen.has(z):
			printerr("Duplicate zone found: %s" % z)
			return false
		seen[z] = true
	return true


func _test_a2_zone_factory_and_default_properties() -> bool:
	var all_zones: Array[BattlefieldZone] = BattlefieldZone.get_all_canonical_zones()
	if all_zones.size() != 7:
		printerr("Expected 7 zones from get_all_canonical_zones(), got: %d" % all_zones.size())
		return false
	for z in all_zones:
		if not z.validate_invariants():
			printerr("Zone invariants invalid: %s" % z.zone_id)
			return false
		if z.zone_name.strip_edges().is_empty():
			printerr("Empty zone name for: %s" % z.zone_id)
			return false
	return true


func _test_a3_zone_defense_and_range_bonuses() -> bool:
	var wall: BattlefieldZone = BattlefieldZone.create_canonical_zone(BattlefieldZone.ZONE_WALL)
	var gate: BattlefieldZone = BattlefieldZone.create_canonical_zone(BattlefieldZone.ZONE_GATE)
	var approach: BattlefieldZone = BattlefieldZone.create_canonical_zone(BattlefieldZone.ZONE_CENTER_APPROACH)
	var outer: BattlefieldZone = BattlefieldZone.create_canonical_zone(BattlefieldZone.ZONE_OUTER_FIELD)

	if abs(wall.defense_bonus - 0.25) > 0.001:
		printerr("Wall defense bonus mismatch: %f != 0.25" % wall.defense_bonus)
		return false
	if abs(wall.range_bonus - 0.30) > 0.001:
		printerr("Wall range bonus mismatch: %f != 0.30" % wall.range_bonus)
		return false
	if abs(gate.defense_bonus - 0.40) > 0.001:
		printerr("Gate defense bonus mismatch: %f != 0.40" % gate.defense_bonus)
		return false
	if abs(approach.defense_bonus - 0.0) > 0.001 or abs(outer.defense_bonus - 0.0) > 0.001:
		printerr("Open field defense bonus should be 0.0")
		return false
	return true


func _test_a4_zone_interior_and_deployment_flags() -> bool:
	for zid in BattlefieldZone.VALID_ZONES:
		var z: BattlefieldZone = BattlefieldZone.create_canonical_zone(zid)
		if zid == BattlefieldZone.ZONE_FORTRESS:
			if not z.is_fortress_interior:
				printerr("FORTRESS must have is_fortress_interior == true")
				return false
		else:
			if z.is_fortress_interior:
				printerr("%s must not have is_fortress_interior == true" % zid)
				return false

		if zid == BattlefieldZone.ZONE_OUTER_FIELD:
			if z.allow_player_deployment:
				printerr("OUTER_FIELD must not allow player deployment")
				return false
		else:
			if not z.allow_player_deployment:
				printerr("%s should allow player deployment" % zid)
				return false
	return true


func _test_a5_zone_invariants_strictly_enforced() -> bool:
	# Zone id invalid
	var z1 := BattlefieldZone.new("INVALID_ZONE_ID", "Bad Zone", BattlefieldZone.TYPE_FIELD)
	if z1.validate_invariants():
		printerr("Should reject invalid zone_id")
		return false

	# Empty name
	var z2 := BattlefieldZone.new(BattlefieldZone.ZONE_WALL, "", BattlefieldZone.TYPE_DEFENSE)
	if z2.validate_invariants():
		printerr("Should reject empty zone name")
		return false

	# Self reference in adjacent_zones
	var z3 := BattlefieldZone.new(
		BattlefieldZone.ZONE_GATE,
		"Gate",
		BattlefieldZone.TYPE_DEFENSE,
		[BattlefieldZone.ZONE_GATE]
	)
	if z3.validate_invariants():
		printerr("Should reject self reference in adjacent_zones")
		return false

	# Negative defense bonus
	var z4 := BattlefieldZone.new(
		BattlefieldZone.ZONE_WALL,
		"Wall",
		BattlefieldZone.TYPE_DEFENSE,
		[],
		-0.10
	)
	if z4.validate_invariants():
		printerr("Should reject negative defense bonus")
		return false

	return true


func _test_a6_zone_clone_and_serialization_isolation() -> bool:
	var original: BattlefieldZone = BattlefieldZone.create_canonical_zone(BattlefieldZone.ZONE_WALL)
	var cloned: BattlefieldZone = original.clone()

	if cloned.zone_id != original.zone_id:
		printerr("Clone zone_id mismatch")
		return false
	if cloned.adjacent_zones.size() != original.adjacent_zones.size():
		printerr("Clone adjacent_zones size mismatch")
		return false

	# Mutate clone array to ensure deep copy
	cloned.adjacent_zones.append("NEW_TEMP")
	if original.adjacent_zones.has("NEW_TEMP"):
		printerr("Clone mutated original adjacent_zones!")
		return false

	# Test dictionary serialization
	var dict: Dictionary = original.to_dictionary()
	var restored: BattlefieldZone = BattlefieldZone.from_dictionary(dict)
	if restored == null or not restored.validate_invariants():
		printerr("from_dictionary restoration failed")
		return false
	if restored.zone_id != original.zone_id or restored.defense_bonus != original.defense_bonus:
		printerr("from_dictionary data mismatch")
		return false

	return true


# ==============================================================================
# GROUP B: ZONE ADJACENCY & TOPOLOGY
# ==============================================================================

func _test_b1_canonical_adjacency_graph_complete() -> bool:
	for zid in BattlefieldZone.VALID_ZONES:
		var adj: Array[String] = BattlefieldZone.get_canonical_adjacency(zid)
		if adj.is_empty():
			printerr("Zone %s has empty adjacency list" % zid)
			return false
		for neighbor in adj:
			if not BattlefieldZone.is_valid_zone(neighbor):
				printerr("Zone %s has invalid neighbor: %s" % [zid, neighbor])
				return false
	return true


func _test_b2_adjacency_symmetry_and_bidirectionality() -> bool:
	for u in BattlefieldZone.VALID_ZONES:
		var u_adj: Array[String] = BattlefieldZone.get_canonical_adjacency(u)
		for v in u_adj:
			var v_adj: Array[String] = BattlefieldZone.get_canonical_adjacency(v)
			if not (u in v_adj):
				printerr("Asymmetry detected: %s connects to %s, but %s does not connect to %s" % [u, v, v, u])
				return false
	return true


func _test_b3_no_self_references_in_adjacency() -> bool:
	for zid in BattlefieldZone.VALID_ZONES:
		var adj: Array[String] = BattlefieldZone.get_canonical_adjacency(zid)
		if zid in adj:
			printerr("Self-reference found in zone: %s" % zid)
			return false
	return true


func _test_b4_outer_field_connections() -> bool:
	var outer_adj: Array[String] = BattlefieldZone.get_canonical_adjacency(BattlefieldZone.ZONE_OUTER_FIELD)
	if not (BattlefieldZone.ZONE_LEFT_FLANK in outer_adj):
		printerr("OUTER_FIELD should connect to LEFT_FLANK")
		return false
	if not (BattlefieldZone.ZONE_CENTER_APPROACH in outer_adj):
		printerr("OUTER_FIELD should connect to CENTER_APPROACH")
		return false
	if not (BattlefieldZone.ZONE_RIGHT_FLANK in outer_adj):
		printerr("OUTER_FIELD should connect to RIGHT_FLANK")
		return false
	# Harap tidak langsung terhubung ke Wall, Gate, atau Fortress
	if BattlefieldZone.ZONE_WALL in outer_adj or BattlefieldZone.ZONE_GATE in outer_adj or BattlefieldZone.ZONE_FORTRESS in outer_adj:
		printerr("OUTER_FIELD should not directly connect to WALL, GATE, or FORTRESS")
		return false
	return true


func _test_b5_barrier_and_core_topology() -> bool:
	var fortress_adj: Array[String] = BattlefieldZone.get_canonical_adjacency(BattlefieldZone.ZONE_FORTRESS)
	# FORTRESS hanya boleh terhubung ke WALL dan GATE
	for n in fortress_adj:
		if n != BattlefieldZone.ZONE_WALL and n != BattlefieldZone.ZONE_GATE:
			printerr("FORTRESS connected to unauthorized zone: %s" % n)
			return false

	var gate_adj: Array[String] = BattlefieldZone.get_canonical_adjacency(BattlefieldZone.ZONE_GATE)
	if not (BattlefieldZone.ZONE_CENTER_APPROACH in gate_adj):
		printerr("GATE must connect to CENTER_APPROACH")
		return false
	if not (BattlefieldZone.ZONE_WALL in gate_adj):
		printerr("GATE must connect to WALL")
		return false
	if not (BattlefieldZone.ZONE_FORTRESS in gate_adj):
		printerr("GATE must connect to FORTRESS")
		return false

	return true


func _test_b6_adjacency_helper_methods_and_non_adjacent_detection() -> bool:
	if not BattlefieldZone.are_adjacent(BattlefieldZone.ZONE_OUTER_FIELD, BattlefieldZone.ZONE_CENTER_APPROACH):
		printerr("OUTER_FIELD and CENTER_APPROACH should be adjacent")
		return false
	if BattlefieldZone.are_adjacent(BattlefieldZone.ZONE_OUTER_FIELD, BattlefieldZone.ZONE_FORTRESS):
		printerr("OUTER_FIELD and FORTRESS must not be adjacent")
		return false
	if BattlefieldZone.are_adjacent(BattlefieldZone.ZONE_LEFT_FLANK, BattlefieldZone.ZONE_RIGHT_FLANK):
		printerr("LEFT_FLANK and RIGHT_FLANK must not be directly adjacent")
		return false

	var wall: BattlefieldZone = BattlefieldZone.create_canonical_zone(BattlefieldZone.ZONE_WALL)
	if not wall.is_adjacent_to(BattlefieldZone.ZONE_GATE):
		printerr("Wall should be adjacent to Gate")
		return false
	if wall.is_adjacent_to(BattlefieldZone.ZONE_OUTER_FIELD):
		printerr("Wall should not be adjacent to Outer Field")
		return false

	return true


# ==============================================================================
# GROUP C: ENEMY ARCHETYPES & ATTRIBUTES
# ==============================================================================

func _test_c1_canonical_archetypes_defined() -> bool:
	if EnemyArchetype.VALID_ARCHETYPES.size() != 6:
		printerr("Valid archetypes count mismatch: %d != 6" % EnemyArchetype.VALID_ARCHETYPES.size())
		return false
	var expected: Array[String] = [
		EnemyArchetype.ARCHETYPE_GOBLIN_SWARM,
		EnemyArchetype.ARCHETYPE_ORC_FRONTLINE,
		EnemyArchetype.ARCHETYPE_GOBLIN_ARCHER,
		EnemyArchetype.ARCHETYPE_TROLL_TANK,
		EnemyArchetype.ARCHETYPE_SIEGE_MONSTER,
		EnemyArchetype.ARCHETYPE_FLYING_BYPASS
	]
	for a in expected:
		if not EnemyArchetype.is_valid_archetype(a):
			printerr("Archetype not valid: %s" % a)
			return false
	return true


func _test_c2_archetype_factory_and_attribute_verification() -> bool:
	for aid in EnemyArchetype.VALID_ARCHETYPES:
		var arch: EnemyArchetype = EnemyArchetype.create(aid)
		if arch == null:
			printerr("create failed for archetype: %s" % aid)
			return false
		if not arch.validate_invariants():
			printerr("Archetype invariants invalid for: %s" % aid)
			return false
		if arch.base_hp <= 0 or arch.base_atk < 0 or arch.threat_cost <= 0:
			printerr("Archetype stats non-positive for: %s" % aid)
			return false
	return true


func _test_c3_archetype_target_priorities() -> bool:
	var swarm: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_GOBLIN_SWARM)
	var orc: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_ORC_FRONTLINE)
	var archer: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_GOBLIN_ARCHER)
	var troll: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_TROLL_TANK)
	var siege: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_SIEGE_MONSTER)
	var flyer: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_FLYING_BYPASS)

	if swarm.target_priority != "NEAREST":
		printerr("Swarm target priority mismatch: %s" % swarm.target_priority)
		return false
	if orc.target_priority != "DEFENDER":
		printerr("Orc target priority mismatch: %s" % orc.target_priority)
		return false
	if archer.target_priority != "RANGED":
		printerr("Archer target priority mismatch: %s" % archer.target_priority)
		return false
	if troll.target_priority != "GATE":
		printerr("Troll target priority mismatch: %s" % troll.target_priority)
		return false
	if siege.target_priority != "STRUCTURE":
		printerr("Siege target priority mismatch: %s" % siege.target_priority)
		return false
	if flyer.target_priority != "FORTRESS":
		printerr("Flyer target priority mismatch: %s" % flyer.target_priority)
		return false

	return true


func _test_c4_archetype_threat_costs_and_speed_ordering() -> bool:
	var swarm: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_GOBLIN_SWARM)
	var troll: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_TROLL_TANK)
	var siege: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_SIEGE_MONSTER)
	var flyer: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_FLYING_BYPASS)

	if swarm.threat_cost != 2:
		printerr("Swarm threat cost mismatch: %d != 2" % swarm.threat_cost)
		return false
	if troll.threat_cost != 16:
		printerr("Troll threat cost mismatch: %d != 16" % troll.threat_cost)
		return false
	if siege.threat_cost != 40:
		printerr("Siege threat cost mismatch: %d != 40" % siege.threat_cost)
		return false
	if flyer.threat_cost != 12:
		printerr("Flyer threat cost mismatch: %d != 12" % flyer.threat_cost)
		return false

	# Cek ticks kecepatan (1 = sangat cepat/cepat, 4 = sangat lambat)
	if swarm.move_speed_ticks != 1 or flyer.move_speed_ticks != 1:
		printerr("Swarm/Flyer speed should be 1 tick per zone")
		return false
	if siege.move_speed_ticks != 4:
		printerr("Siege speed should be 4 ticks per zone")
		return false

	return true


func _test_c5_archetype_invariants_and_invalid_rejection() -> bool:
	# Unknown archetype
	var a1 := EnemyArchetype.new("UNKNOWN_ENEMY", "Unknown", "MELEE", 1, 10, 1, 0, 1, "NEAREST")
	if a1.validate_invariants():
		printerr("Should reject unknown archetype ID")
		return false

	# Zero HP
	var a2 := EnemyArchetype.new(EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, "Swarm", "MELEE", 2, 0, 1, 0, 1, "NEAREST")
	if a2.validate_invariants():
		printerr("Should reject archetype with 0 HP")
		return false

	# Negative threat cost
	var a3 := EnemyArchetype.new(EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, "Swarm", "MELEE", -5, 20, 1, 0, 1, "NEAREST")
	if a3.validate_invariants():
		printerr("Should reject negative threat cost")
		return false

	return true


func _test_c6_archetype_clone_and_dictionary_serialization() -> bool:
	var orig: EnemyArchetype = EnemyArchetype.create(EnemyArchetype.ARCHETYPE_TROLL_TANK)
	var cln: EnemyArchetype = orig.clone()

	if cln.archetype_id != orig.archetype_id or cln.base_hp != orig.base_hp:
		printerr("Archetype clone mismatch")
		return false

	var dict: Dictionary = orig.to_dictionary()
	var restored: EnemyArchetype = EnemyArchetype.from_dictionary(dict)
	if restored == null or not restored.validate_invariants():
		printerr("Archetype restoration from dictionary failed")
		return false
	if restored.display_name != orig.display_name or restored.threat_cost != orig.threat_cost:
		printerr("Archetype restored fields mismatch")
		return false

	return true


# ==============================================================================
# GROUP D: WAVEGENERATOR MAPPING & DETERMINISM
# ==============================================================================

func _test_d1_legacy_enemy_type_mapping() -> bool:
	if EnemyArchetype.map_legacy_enemy_type("MINION") != EnemyArchetype.ARCHETYPE_GOBLIN_SWARM:
		printerr("MINION should map to GOBLIN_SWARM")
		return false
	if EnemyArchetype.map_legacy_enemy_type("RAIDER") != EnemyArchetype.ARCHETYPE_ORC_FRONTLINE:
		printerr("RAIDER should map to ORC_FRONTLINE")
		return false
	if EnemyArchetype.map_legacy_enemy_type("BRUTE") != EnemyArchetype.ARCHETYPE_TROLL_TANK:
		printerr("BRUTE should map to TROLL_TANK")
		return false
	if EnemyArchetype.map_legacy_enemy_type("FLYER") != EnemyArchetype.ARCHETYPE_FLYING_BYPASS:
		printerr("FLYER should map to FLYING_BYPASS")
		return false
	if EnemyArchetype.map_legacy_enemy_type("SIEGE") != EnemyArchetype.ARCHETYPE_SIEGE_MONSTER:
		printerr("SIEGE should map to SIEGE_MONSTER")
		return false
	if EnemyArchetype.map_legacy_enemy_type("BOSS") != EnemyArchetype.ARCHETYPE_TROLL_TANK:
		printerr("BOSS should map to TROLL_TANK")
		return false
	if EnemyArchetype.map_legacy_enemy_type("GOBLIN_ARCHER") != EnemyArchetype.ARCHETYPE_GOBLIN_ARCHER:
		printerr("GOBLIN_ARCHER should map to GOBLIN_ARCHER")
		return false
	if EnemyArchetype.map_legacy_enemy_type("INVALID_TYPE") != "":
		printerr("INVALID_TYPE should map to empty string")
		return false
	return true


func _test_d2_wave_mapping_creates_enemy_groups() -> bool:
	var wg := WaveGenerator.new()
	var wave_1: Dictionary = wg.generate_wave(1, 12345)
	var groups: Array = EnemyArchetype.map_wave_to_enemy_groups(wave_1)

	if groups.is_empty():
		printerr("Wave 1 should produce at least one enemy group")
		return false

	var first: EnemyGroup = groups[0] as EnemyGroup
	if first == null:
		printerr("Group element is not an EnemyGroup")
		return false
	if first.enemy_type != EnemyArchetype.ARCHETYPE_GOBLIN_SWARM:
		printerr("Wave 1 first group should be GOBLIN_SWARM, got: %s" % first.enemy_type)
		return false
	if first.quantity <= 0:
		printerr("Wave 1 quantity should be positive, got: %d" % first.quantity)
		return false
	if not first.validate_invariants():
		printerr("Mapped group invariants failed")
		return false

	return true


func _test_d3_wave_mapping_multi_archetype_distribution() -> bool:
	var wg := WaveGenerator.new()
	# Wave 12 memiliki BOSS (karena wave kelipatan 10 ada boss, wave 12 ada siege & flyer & brute & raider & minion)
	var wave_12: Dictionary = wg.generate_wave(12, 54321)
	var groups: Array = EnemyArchetype.map_wave_to_enemy_groups(wave_12)

	var found_types: Dictionary = {}
	for g in groups:
		var eg: EnemyGroup = g as EnemyGroup
		if eg != null:
			found_types[eg.enemy_type] = eg.quantity
			if not eg.validate_invariants():
				printerr("Wave 12 group invalid invariants: %s" % eg.group_id)
				return false

	# Wave 12 harus memiliki MINION, RAIDER, BRUTE, FLYER, SIEGE
	if not found_types.has(EnemyArchetype.ARCHETYPE_GOBLIN_SWARM):
		printerr("Missing GOBLIN_SWARM in wave 12")
		return false
	if not found_types.has(EnemyArchetype.ARCHETYPE_ORC_FRONTLINE):
		printerr("Missing ORC_FRONTLINE in wave 12")
		return false
	if not found_types.has(EnemyArchetype.ARCHETYPE_TROLL_TANK):
		printerr("Missing TROLL_TANK in wave 12")
		return false
	if not found_types.has(EnemyArchetype.ARCHETYPE_FLYING_BYPASS):
		printerr("Missing FLYING_BYPASS in wave 12")
		return false
	if not found_types.has(EnemyArchetype.ARCHETYPE_SIEGE_MONSTER):
		printerr("Missing SIEGE_MONSTER in wave 12")
		return false

	return true


func _test_d4_wave_mapping_initial_spawn_in_outer_field() -> bool:
	var wg := WaveGenerator.new()
	for w in [1, 5, 10, 20]:
		var wave_data: Dictionary = wg.generate_wave(w, 999)
		var groups: Array = EnemyArchetype.map_wave_to_enemy_groups(wave_data)
		for g in groups:
			var eg: EnemyGroup = g as EnemyGroup
			if eg.current_zone != BattlefieldZone.ZONE_OUTER_FIELD:
				printerr("Wave %d enemy group %s not spawned in OUTER_FIELD: %s" % [w, eg.group_id, eg.current_zone])
				return false
	return true


func _test_d5_wave_mapping_is_strictly_deterministic() -> bool:
	var wg := WaveGenerator.new()
	var wave_10_a: Dictionary = wg.generate_wave(10, 777)
	var wave_10_b: Dictionary = wg.generate_wave(10, 777)

	var groups_a: Array = EnemyArchetype.map_wave_to_enemy_groups(wave_10_a)
	var groups_b: Array = EnemyArchetype.map_wave_to_enemy_groups(wave_10_b)

	if groups_a.size() != groups_b.size():
		printerr("Deterministic size mismatch: %d != %d" % [groups_a.size(), groups_b.size()])
		return false

	for i in range(groups_a.size()):
		var ga: EnemyGroup = groups_a[i] as EnemyGroup
		var gb: EnemyGroup = groups_b[i] as EnemyGroup
		if ga.group_id != gb.group_id:
			printerr("Group id mismatch at index %d" % i)
			return false
		if ga.enemy_type != gb.enemy_type or ga.quantity != gb.quantity or ga.current_hp_pool != gb.current_hp_pool:
			printerr("Group state mismatch at index %d" % i)
			return false

	return true


func _test_d6_wave_mapping_handles_empty_or_zero_counts() -> bool:
	var empty_wave: Dictionary = {}
	var empty_res: Array = EnemyArchetype.map_wave_to_enemy_groups(empty_wave)
	if not empty_res.is_empty():
		printerr("Empty wave should produce empty array")
		return false

	var zero_wave: Dictionary = {
		"wave": 1,
		"threat_budget": 0,
		"enemies": {
			"MINION": 0,
			"RAIDER": 0,
			"BRUTE": 0
		}
	}
	var zero_res: Array = EnemyArchetype.map_wave_to_enemy_groups(zero_wave)
	if not zero_res.is_empty():
		printerr("Zero-count wave should produce empty array")
		return false

	return true


# ==============================================================================
# GROUP E: ENEMYGROUP MODEL & INVARIANTS
# ==============================================================================

func _test_e1_enemy_group_initialization_and_hp_pool() -> bool:
	var eg := EnemyGroup.new("grp_1", EnemyArchetype.ARCHETYPE_ORC_FRONTLINE, 10, BattlefieldZone.ZONE_OUTER_FIELD)
	if not eg.validate_invariants():
		printerr("EnemyGroup invariants failed on init")
		return false

	# Orc Frontline base_hp = 65. Quantity = 10 -> max_hp_pool = 650.
	if eg.max_hp_pool != 650 or eg.current_hp_pool != 650:
		printerr("HP pool calculation mismatch: %d != 650" % eg.current_hp_pool)
		return false
	if eg.ticks_until_advance != 2:
		printerr("Orc Frontline speed ticks should be 2, got: %d" % eg.ticks_until_advance)
		return false

	return true


func _test_e2_enemy_group_damage_absorption_and_casualty() -> bool:
	var eg := EnemyGroup.new("grp_dmg", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 5, BattlefieldZone.ZONE_OUTER_FIELD)
	# Goblin Swarm base_hp = 20. Total HP = 100.
	if eg.current_hp_pool != 100 or eg.quantity != 5:
		printerr("Initial HP mismatch")
		return false

	# Damage 25 -> HP sisa 75. Kuantitas sisa ceil(75 / 20) = 4.
	var absorbed: int = eg.apply_damage(25)
	if absorbed != 25:
		printerr("Damage absorbed mismatch: %d != 25" % absorbed)
		return false
	if eg.current_hp_pool != 75:
		printerr("Remaining HP mismatch: %d != 75" % eg.current_hp_pool)
		return false
	if eg.quantity != 4:
		printerr("Remaining quantity mismatch: %d != 4" % eg.quantity)
		return false
	if not eg.validate_invariants():
		printerr("Invariants failed after damage")
		return false

	# Damage 75 -> sisa 0. Kuantitas = 0.
	eg.apply_damage(75)
	if eg.current_hp_pool != 0 or eg.quantity != 0:
		printerr("Zero HP / quantity mismatch: HP=%d, Qty=%d" % [eg.current_hp_pool, eg.quantity])
		return false
	if not eg.validate_invariants():
		printerr("Invariants failed at zero HP")
		return false

	return true


func _test_e3_enemy_group_defeat_detection() -> bool:
	var eg := EnemyGroup.new("grp_def", EnemyArchetype.ARCHETYPE_GOBLIN_ARCHER, 2, BattlefieldZone.ZONE_OUTER_FIELD)
	if eg.is_defeated():
		printerr("Should not be defeated initially")
		return false

	# Sisa 1 unit
	eg.apply_damage(35)
	if eg.is_defeated():
		printerr("Should not be defeated while HP remains")
		return false

	# Habis seluruhnya
	eg.apply_damage(100)
	if not eg.is_defeated():
		printerr("Should be defeated when HP pool is 0")
		return false

	return true


func _test_e4_enemy_group_boss_scaling() -> bool:
	var normal_troll := EnemyGroup.new("troll_norm", EnemyArchetype.ARCHETYPE_TROLL_TANK, 1, BattlefieldZone.ZONE_OUTER_FIELD, false)
	var boss_troll := EnemyGroup.new("troll_boss", EnemyArchetype.ARCHETYPE_TROLL_TANK, 1, BattlefieldZone.ZONE_OUTER_FIELD, true)

	if not boss_troll.is_boss:
		printerr("Boss flag not set")
		return false
	if boss_troll.base_hp_per_unit <= normal_troll.base_hp_per_unit:
		printerr("Boss HP should be scaled higher: %d <= %d" % [boss_troll.base_hp_per_unit, normal_troll.base_hp_per_unit])
		return false
	if boss_troll.base_atk_per_unit <= normal_troll.base_atk_per_unit:
		printerr("Boss ATK should be scaled higher: %d <= %d" % [boss_troll.base_atk_per_unit, normal_troll.base_atk_per_unit])
		return false
	if not ("BOSS" in boss_troll.special_trait):
		printerr("Boss special trait should contain BOSS tag: %s" % boss_troll.special_trait)
		return false

	return true


func _test_e5_enemy_group_invariants_strictly_enforced() -> bool:
	# Empty group_id
	var eg1 := EnemyGroup.new("", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 1)
	if eg1.validate_invariants():
		printerr("Should reject empty group_id")
		return false

	# Invalid zone
	var eg2 := EnemyGroup.new("g2", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 1, "UNKNOWN_ZONE")
	if eg2.validate_invariants():
		printerr("Should reject invalid current_zone")
		return false

	# Invalid target zone
	var eg3 := EnemyGroup.new("g3", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 1, BattlefieldZone.ZONE_OUTER_FIELD)
	eg3.target_zone = "BAD_TARGET_ZONE"
	if eg3.validate_invariants():
		printerr("Should reject invalid target_zone")
		return false

	# Inconsistent quantity and HP
	var eg4 := EnemyGroup.new("g4", EnemyArchetype.ARCHETYPE_GOBLIN_SWARM, 5)
	eg4.current_hp_pool = 0 # quantity = 5 but HP = 0
	if eg4.validate_invariants():
		printerr("Should reject quantity > 0 with HP == 0")
		return false

	return true


func _test_e6_enemy_group_clone_and_dictionary_isolation() -> bool:
	var eg := EnemyGroup.new("grp_iso", EnemyArchetype.ARCHETYPE_SIEGE_MONSTER, 3, BattlefieldZone.ZONE_OUTER_FIELD)
	eg.apply_damage(100)
	var cln: EnemyGroup = eg.clone()

	if cln.group_id != eg.group_id or cln.current_hp_pool != eg.current_hp_pool or cln.quantity != eg.quantity:
		printerr("EnemyGroup clone attribute mismatch")
		return false

	cln.apply_damage(200)
	if eg.current_hp_pool == cln.current_hp_pool:
		printerr("EnemyGroup clone mutated original HP!")
		return false

	var dict: Dictionary = eg.to_dictionary()
	var restored: EnemyGroup = EnemyGroup.from_dictionary(dict)
	if restored == null or not restored.validate_invariants():
		printerr("EnemyGroup restoration from dictionary failed")
		return false
	if restored.group_id != eg.group_id or restored.current_hp_pool != eg.current_hp_pool:
		printerr("Restored fields mismatch")
		return false

	return true
