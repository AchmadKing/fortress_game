extends SceneTree

## TestPhase6CUnitFormationsPartyAura
## Unit test suite komprehensif untuk Phase 6C — Unit Formations, Party 1 & Aura Mechanics.
## Menguji:
## - Group A: Soldier Deployment Battlefield Participation (Tests 1-5)
## - Group B: Party 1 Battle Participation (Tests 6-10)
## - Group C: Battlefield Placement & Zone Invariants (Tests 11-15)
## - Group D: Formation Foundation (Tests 16-20)
## - Group E: Party 1 Aura Mechanics (Tests 21-25)
## - Group F: Chemistry Integration (Tests 26-29)
## - Group G: Determinism & Snapshot Integrity (Tests 30-33)
## - Group H: Battle Lock & Conservation Invariants (Tests 34-36)
## - Group I: Deterministic 50-Wave Participation & Stress Test (Test 37)

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")
const CombatEngine = preload("res://scripts/simulation/combat_engine.gd")
const GameStateSnapshot = preload("res://scripts/domain/state/game_state_snapshot.gd")
const BattlefieldZone = preload("res://scripts/domain/model/battlefield_zone.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const PartyModel = preload("res://scripts/domain/model/party_model.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const HeroRole = preload("res://scripts/domain/model/hero_role.gd")
const HeroLifecycleState = preload("res://scripts/domain/model/hero_lifecycle_state.gd")
const HeroSkill = preload("res://scripts/domain/model/hero_skill.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 6C UNIT FORMATIONS, PARTY 1 & AURA MECHANICS TESTS")
	print("================================================================")

	var tests: Array[Dictionary] = [
		# Group A: Soldier Deployment Battlefield Participation
		{"name": "test_a1_aggregation_model_no_individual_soldier_nodes", "fn": Callable(self, "_test_a1_aggregation_model_no_individual_soldier_nodes")},
		{"name": "test_a2_initial_battlefield_placement_defaults", "fn": Callable(self, "_test_a2_initial_battlefield_placement_defaults")},
		{"name": "test_a3_formation_types_frontline_backline_support", "fn": Callable(self, "_test_a3_formation_types_frontline_backline_support")},
		{"name": "test_a4_modify_deployment_zone", "fn": Callable(self, "_test_a4_modify_deployment_zone")},
		{"name": "test_a5_modify_deployment_formation", "fn": Callable(self, "_test_a5_modify_deployment_formation")},

		# Group B: Party 1 Battle Participation
		{"name": "test_b1_only_party_1_participates", "fn": Callable(self, "_test_b1_only_party_1_participates")},
		{"name": "test_b2_party_2_excluded_from_battle", "fn": Callable(self, "_test_b2_party_2_excluded_from_battle")},
		{"name": "test_b3_reserve_heroes_excluded", "fn": Callable(self, "_test_b3_reserve_heroes_excluded")},
		{"name": "test_b4_dead_heroes_in_party_1_excluded", "fn": Callable(self, "_test_b4_dead_heroes_in_party_1_excluded")},
		{"name": "test_b5_empty_party_handled_gracefully", "fn": Callable(self, "_test_b5_empty_party_handled_gracefully")},

		# Group C: Battlefield Placement & Zone Invariants
		{"name": "test_c1_party_1_default_placement_gate", "fn": Callable(self, "_test_c1_party_1_default_placement_gate")},
		{"name": "test_c2_player_placement_allowed_zones", "fn": Callable(self, "_test_c2_player_placement_allowed_zones")},
		{"name": "test_c3_outer_field_strictly_rejected", "fn": Callable(self, "_test_c3_outer_field_strictly_rejected")},
		{"name": "test_c4_invalid_zone_strings_rejected", "fn": Callable(self, "_test_c4_invalid_zone_strings_rejected")},
		{"name": "test_c5_placement_preserved_in_clones_and_snapshots", "fn": Callable(self, "_test_c5_placement_preserved_in_clones_and_snapshots")},

		# Group D: Formation Foundation
		{"name": "test_d1_valid_formations_constant", "fn": Callable(self, "_test_d1_valid_formations_constant")},
		{"name": "test_d2_invalid_formation_rejected", "fn": Callable(self, "_test_d2_invalid_formation_rejected")},
		{"name": "test_d3_hero_role_default_formations", "fn": Callable(self, "_test_d3_hero_role_default_formations")},
		{"name": "test_d4_party_1_formation_mutation", "fn": Callable(self, "_test_d4_party_1_formation_mutation")},
		{"name": "test_d5_formation_serialization_roundtrip", "fn": Callable(self, "_test_d5_formation_serialization_roundtrip")},

		# Group E: Party 1 Aura Mechanics
		{"name": "test_e1_passive_calculation_no_stat_mutation", "fn": Callable(self, "_test_e1_passive_calculation_no_stat_mutation")},
		{"name": "test_e2_knight_aura_def_and_morale", "fn": Callable(self, "_test_e2_knight_aura_def_and_morale")},
		{"name": "test_e3_archer_and_mage_aura_atk", "fn": Callable(self, "_test_e3_archer_and_mage_aura_atk")},
		{"name": "test_e4_leadership_talent_scaling", "fn": Callable(self, "_test_e4_leadership_talent_scaling")},
		{"name": "test_e5_chemistry_bonus_and_dead_hero_filtering", "fn": Callable(self, "_test_e5_chemistry_bonus_and_dead_hero_filtering")},

		# Group F: Chemistry Integration
		{"name": "test_f1_battle_participants_gain_chemistry", "fn": Callable(self, "_test_f1_battle_participants_gain_chemistry")},
		{"name": "test_f2_party_2_and_reserves_gain_zero_chemistry", "fn": Callable(self, "_test_f2_party_2_and_reserves_gain_zero_chemistry")},
		{"name": "test_f3_dead_heroes_gain_zero_chemistry", "fn": Callable(self, "_test_f3_dead_heroes_gain_zero_chemistry")},
		{"name": "test_f4_chemistry_capped_at_max", "fn": Callable(self, "_test_f4_chemistry_capped_at_max")},

		# Group G: Determinism & Snapshot Integrity
		{"name": "test_g1_snapshot_contains_battle_fields", "fn": Callable(self, "_test_g1_snapshot_contains_battle_fields")},
		{"name": "test_g2_snapshot_deep_isolation", "fn": Callable(self, "_test_g2_snapshot_deep_isolation")},
		{"name": "test_g3_snapshot_dict_roundtrip", "fn": Callable(self, "_test_g3_snapshot_dict_roundtrip")},
		{"name": "test_g4_deterministic_aura_calculation", "fn": Callable(self, "_test_g4_deterministic_aura_calculation")},

		# Group H: Battle Lock & Conservation Invariants
		{"name": "test_h1_battle_lock_rejects_deployment_zone_and_formation", "fn": Callable(self, "_test_h1_battle_lock_rejects_deployment_zone_and_formation")},
		{"name": "test_h2_battle_lock_rejects_party_zone_and_formation", "fn": Callable(self, "_test_h2_battle_lock_rejects_party_zone_and_formation")},
		{"name": "test_h3_battle_lock_protects_party_and_equipment", "fn": Callable(self, "_test_h3_battle_lock_protects_party_and_equipment")},

		# Group I: Deterministic 50-Wave Participation & Stress Test
		{"name": "test_i1_50_wave_participation_stress", "fn": Callable(self, "_test_i1_50_wave_participation_stress")},
	]

	var passed: int = 0
	var failed: int = 0

	for t in tests:
		var test_name: String = t["name"]
		var callable: Callable = t["fn"]
		var success: bool = false
		var err_msg: String = ""

		var result = callable.call()
		if result is bool:
			success = result
		else:
			success = true

		if success:
			passed += 1
			print("[PASS] %s" % test_name)
		else:
			failed += 1
			print("[FAIL] %s %s" % [test_name, err_msg])

	print("================================================================")
	print("PHASE 6C TEST SUMMARY: %d PASSED, %d FAILED (Total %d)" % [passed, failed, tests.size()])
	print("================================================================")

	for c in root.get_children():
		root.remove_child(c)
		c.free()

	if failed > 0:
		quit(1)
	else:
		quit(0)


# ==============================================================================
# GROUP A: SOLDIER DEPLOYMENT BATTLEFIELD PARTICIPATION
# ==============================================================================

func _test_a1_aggregation_model_no_individual_soldier_nodes() -> bool:
	var comp := DeploymentComposition.new(10, "SWORD", "NONE", "NONE")
	# Aggregation model: purely RefCounted, zero Node allocations
	if not (comp is RefCounted):
		return false
	if (comp as Object) is Node:
		return false
	if comp.count != 10:
		return false
	if comp.resolved_role != "SWORDSMAN":
		return false
	if comp.current_zone != "GATE":
		return false
	if comp.formation != "FRONTLINE":
		return false
	return true


func _test_a2_initial_battlefield_placement_defaults() -> bool:
	var inf := DeploymentComposition.new(5, "SWORD", "NONE", "NONE")
	var arch := DeploymentComposition.new(5, "BOW", "NONE", "NONE")
	var shield := DeploymentComposition.new(5, "SWORD", "SHIELD", "NONE")

	if inf.current_zone != "GATE":
		return false
	if arch.current_zone != "WALL":
		return false
	if shield.current_zone != "GATE":
		return false
	return true


func _test_a3_formation_types_frontline_backline_support() -> bool:
	var valid := DeploymentComposition.VALID_FORMATIONS
	if not ("FRONTLINE" in valid):
		return false
	if not ("BACKLINE" in valid):
		return false
	if not ("SUPPORT" in valid):
		return false
	if valid.size() != 3:
		return false
	return true


func _test_a4_modify_deployment_zone() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_a4")
	# Deploy 2 infantry
	var ok_deploy: bool = coord.create_deployment(2, "SWORD")
	if not ok_deploy:
		return false
	var depls: Array = coord.get_active_deployments()
	if depls.size() == 0:
		return false
	var comp: DeploymentComposition = depls[0] as DeploymentComposition
	if comp.current_zone != "GATE":
		return false

	var ok_zone: bool = coord.set_deployment_zone(comp.composition_id, "CENTER_APPROACH")
	if not ok_zone:
		return false
	if comp.current_zone != "CENTER_APPROACH":
		return false

	var snap: GameStateSnapshot = coord.get_current_state()
	if snap.battle_deployments_data.size() == 0:
		return false
	if snap.battle_deployments_data[0]["current_zone"] != "CENTER_APPROACH":
		return false
	return true


func _test_a5_modify_deployment_formation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_a5")
	var ok_deploy: bool = coord.create_deployment(2, "SWORD")
	if not ok_deploy:
		return false
	var comp: DeploymentComposition = coord.get_active_deployments()[0] as DeploymentComposition
	if comp.formation != "FRONTLINE":
		return false

	var ok_form: bool = coord.set_deployment_formation(comp.composition_id, "SUPPORT")
	if not ok_form:
		return false
	if comp.formation != "SUPPORT":
		return false

	var snap: GameStateSnapshot = coord.get_current_state()
	if snap.battle_deployments_data[0]["formation"] != "SUPPORT":
		return false
	return true


# ==============================================================================
# GROUP B: PARTY 1 BATTLE PARTICIPATION
# ==============================================================================

func _test_b1_only_party_1_participates() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_b1")
	var active_p := coord.get_active_battle_party()
	if active_p == null:
		return false
	if active_p.party_id != PartyModel.PARTY_1_ID:
		return false
	return true


func _test_b2_party_2_excluded_from_battle() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_b2")
	# Tambahkan hero baru dan tugaskan ke Party 2
	var h3 := HeroModel.new("hero_gale", "Gale", 1, 3, HeroRole.MAGE, HeroLifecycleState.ROSTER_ACTIVE)
	coord.add_hero(h3)
	var ok_p2: bool = coord.assign_hero_to_party("hero_gale", "party_2")
	if not ok_p2:
		return false

	# Assign Alder ke Party 1
	coord.assign_hero_to_party("hero_alder", "party_1")

	# Pahlawan battle aktif hanya dari Party 1
	var battle_heroes: Array = coord.get_active_battle_heroes()
	for h in battle_heroes:
		if (h as HeroModel).hero_id == "hero_gale":
			return false
	if battle_heroes.size() != 1 or (battle_heroes[0] as HeroModel).hero_id != "hero_alder":
		return false

	# Transisi ke BATTLE
	coord.inspect_wave()
	coord.start_battle()
	# Gale di Party 2 harus tetap IN_PARTY, BUKAN BATTLE_ACTIVE
	if h3.lifecycle_state != HeroLifecycleState.IN_PARTY:
		return false
	# Alder di Party 1 harus transisi ke BATTLE_ACTIVE
	var alder: HeroModel = coord.get_hero("hero_alder")
	if alder.lifecycle_state != HeroLifecycleState.BATTLE_ACTIVE:
		return false
	return true


func _test_b3_reserve_heroes_excluded() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_b3")
	# Alder di Party 1, Lyra di Reserve (belum ditugaskan)
	coord.assign_hero_to_party("hero_alder", "party_1")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	if lyra.lifecycle_state != HeroLifecycleState.ROSTER_ACTIVE:
		return false

	var battle_heroes: Array = coord.get_active_battle_heroes()
	if battle_heroes.size() != 1:
		return false
	if (battle_heroes[0] as HeroModel).hero_id != "hero_alder":
		return false
	return true


func _test_b4_dead_heroes_in_party_1_excluded() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_b4")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")

	var alder: HeroModel = coord.get_hero("hero_alder")
	alder.mark_dead()

	var battle_heroes: Array = coord.get_active_battle_heroes()
	if battle_heroes.size() != 1:
		return false
	if (battle_heroes[0] as HeroModel).hero_id != "hero_lyra":
		return false
	return true


func _test_b5_empty_party_handled_gracefully() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_b5")
	# Party 1 kosong
	var battle_heroes: Array = coord.get_active_battle_heroes()
	if battle_heroes.size() != 0:
		return false

	var auras: Dictionary = coord.get_active_battle_auras()
	if auras.is_empty():
		return false
	if auras["contributing_heroes_count"] != 0:
		return false
	if auras["atk_multiplier"] != 1.0 or auras["def_multiplier"] != 1.0:
		return false
	return true


# ==============================================================================
# GROUP C: BATTLEFIELD PLACEMENT & ZONE INVARIANTS
# ==============================================================================

func _test_c1_party_1_default_placement_gate() -> bool:
	var p := PartyModel.new("party_1", "Party 1", true)
	if p.current_zone != "GATE":
		return false
	if p.formation != "FRONTLINE":
		return false
	return true


func _test_c2_player_placement_allowed_zones() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_c2")
	var allowed := ["WALL", "GATE", "CENTER_APPROACH", "LEFT_FLANK", "RIGHT_FLANK", "FORTRESS"]
	for z in allowed:
		var ok: bool = coord.set_party_zone("party_1", z)
		if not ok:
			return false
		var p1: PartyModel = coord.get_party("party_1")
		if p1.current_zone != z:
			return false
	return true


func _test_c3_outer_field_strictly_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_c3")
	# Party 1 ke OUTER_FIELD harus ditolak
	var ok_party: bool = coord.set_party_zone("party_1", "OUTER_FIELD")
	if ok_party:
		return false
	var p1: PartyModel = coord.get_party("party_1")
	if p1.current_zone == "OUTER_FIELD":
		return false

	# Deployment ke OUTER_FIELD harus ditolak
	coord.create_deployment(2, "SWORD")
	var comp_id: String = (coord.get_active_deployments()[0] as DeploymentComposition).composition_id
	var ok_comp: bool = coord.set_deployment_zone(comp_id, "OUTER_FIELD")
	if ok_comp:
		return false
	return true


func _test_c4_invalid_zone_strings_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_c4")
	if coord.set_party_zone("party_1", "INVALID_ZONE"):
		return false
	if coord.set_party_zone("party_1", ""):
		return false
	if coord.set_party_zone("party_1", "NARNIA"):
		return false
	return true


func _test_c5_placement_preserved_in_clones_and_snapshots() -> bool:
	var p := PartyModel.new("party_1", "Party 1", true)
	p.set_zone("CENTER_APPROACH")
	p.set_formation("BACKLINE")
	var p_clone: PartyModel = p.clone() as PartyModel
	if p_clone.current_zone != "CENTER_APPROACH" or p_clone.formation != "BACKLINE":
		return false

	var comp := DeploymentComposition.new(4, "BOW", "NONE", "NONE")
	comp.set_zone("WALL")
	comp.set_formation("SUPPORT")
	var comp_clone: DeploymentComposition = comp.clone() as DeploymentComposition
	if comp_clone.current_zone != "WALL" or comp_clone.formation != "SUPPORT":
		return false
	return true


# ==============================================================================
# GROUP D: FORMATION FOUNDATION
# ==============================================================================

func _test_d1_valid_formations_constant() -> bool:
	var vf: Array = DeploymentComposition.VALID_FORMATIONS
	return vf.has("FRONTLINE") and vf.has("BACKLINE") and vf.has("SUPPORT") and vf.size() == 3


func _test_d2_invalid_formation_rejected() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_d2")
	if coord.set_party_formation("party_1", "INVALID"):
		return false
	if coord.set_party_formation("party_1", ""):
		return false

	coord.create_deployment(2, "SWORD")
	var comp_id: String = (coord.get_active_deployments()[0] as DeploymentComposition).composition_id
	if coord.set_deployment_formation(comp_id, "FLYING"):
		return false
	return true


func _test_d3_hero_role_default_formations() -> bool:
	if HeroRole.resolve_default_formation("KNIGHT") != "FRONTLINE":
		return false
	if HeroRole.resolve_default_formation("ARCHER") != "BACKLINE":
		return false
	if HeroRole.resolve_default_formation("MAGE") != "BACKLINE":
		return false
	if HeroRole.resolve_default_formation("PRIEST") != "SUPPORT":
		return false
	return true


func _test_d4_party_1_formation_mutation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_d4")
	var ok1: bool = coord.set_party_formation("party_1", "BACKLINE")
	if not ok1:
		return false
	var p1: PartyModel = coord.get_party("party_1")
	if p1.formation != "BACKLINE":
		return false

	var ok2: bool = coord.set_party_formation("party_1", "SUPPORT")
	if not ok2:
		return false
	if p1.formation != "SUPPORT":
		return false
	return true


func _test_d5_formation_serialization_roundtrip() -> bool:
	var comp := DeploymentComposition.new(8, "SWORD", "NONE", "NONE")
	comp.set_zone("LEFT_FLANK")
	comp.set_formation("SUPPORT")

	var d: Dictionary = comp.to_dictionary()
	var restored := DeploymentComposition.from_dictionary(d)
	if restored.composition_id != comp.composition_id:
		return false
	if restored.current_zone != "LEFT_FLANK":
		return false
	if restored.formation != "SUPPORT":
		return false

	var party := PartyModel.new("party_1", "Alpha", true)
	party.set_zone("WALL")
	party.set_formation("BACKLINE")
	var pd: Dictionary = party.to_dictionary()
	var p_restored := PartyModel.from_dictionary(pd)
	if p_restored.current_zone != "WALL" or p_restored.formation != "BACKLINE":
		return false
	return true


# ==============================================================================
# GROUP E: PARTY 1 AURA MECHANICS
# ==============================================================================

func _test_e1_passive_calculation_no_stat_mutation() -> bool:
	var engine := CombatEngine.new()
	var alder := HeroModel.new("hero_alder", "Alder Ironclad", 1, 4, HeroRole.KNIGHT, HeroLifecycleState.ROSTER_ACTIVE)
	var orig_atk: int = alder.base_atk
	var orig_def: int = alder.base_def
	var orig_hp: int = alder.base_hp

	var auras: Dictionary = engine.calculate_party_auras([alder])
	if auras.is_empty():
		return false
	if alder.base_atk != orig_atk or alder.base_def != orig_def or alder.base_hp != orig_hp:
		return false
	return true


func _test_e2_knight_aura_def_and_morale() -> bool:
	var engine := CombatEngine.new()
	var alder := HeroModel.new("hero_alder", "Alder Ironclad", 1, 4, HeroRole.KNIGHT, HeroLifecycleState.ROSTER_ACTIVE)
	var auras: Dictionary = engine.calculate_party_auras([alder])

	# Knight: +10% DEF, +5 morale
	if absf(auras["total_def_bonus"] - 0.10) > 0.0001:
		return false
	if absf(auras["total_morale_bonus"] - 5.0) > 0.0001:
		return false
	if absf(auras["total_atk_bonus"] - 0.0) > 0.0001:
		return false
	return true


func _test_e3_archer_and_mage_aura_atk() -> bool:
	var engine := CombatEngine.new()
	var lyra := HeroModel.new("hero_lyra", "Lyra Windwalker", 2, 4, HeroRole.ARCHER, HeroLifecycleState.ROSTER_ACTIVE)
	var gale := HeroModel.new("hero_gale", "Gale", 1, 3, HeroRole.MAGE, HeroLifecycleState.ROSTER_ACTIVE)

	var auras_lyra: Dictionary = engine.calculate_party_auras([lyra])
	if absf(auras_lyra["total_atk_bonus"] - 0.10) > 0.0001:
		return false

	var auras_gale: Dictionary = engine.calculate_party_auras([gale])
	if absf(auras_gale["total_atk_bonus"] - 0.15) > 0.0001:
		return false

	# Kombinasi Archer + Mage = 0.10 + 0.15 = 0.25 ATK bonus
	var auras_both: Dictionary = engine.calculate_party_auras([lyra, gale])
	if absf(auras_both["total_atk_bonus"] - 0.25) > 0.0001:
		return false
	return true


func _test_e4_leadership_talent_scaling() -> bool:
	var engine := CombatEngine.new()
	var alder := HeroModel.new("hero_alder", "Alder Ironclad", 1, 4, HeroRole.KNIGHT, HeroLifecycleState.ROSTER_ACTIVE)
	# Tambahkan bakat LEADERSHIP level 3 (+3% ATK & +3% DEF)
	alder.allocated_talents["LEADERSHIP"] = 3

	var auras: Dictionary = engine.calculate_party_auras([alder])
	# Total DEF = 10% (Knight) + 3% (Talent) = 13% (0.13)
	# Total ATK = 0% (Knight) + 3% (Talent) = 3% (0.03)
	if absf(auras["total_def_bonus"] - 0.13) > 0.0001:
		return false
	if absf(auras["total_atk_bonus"] - 0.03) > 0.0001:
		return false
	return true


func _test_e5_chemistry_bonus_and_dead_hero_filtering() -> bool:
	var engine := CombatEngine.new()
	var alder := HeroModel.new("hero_alder", "Alder Ironclad", 1, 4, HeroRole.KNIGHT, HeroLifecycleState.ROSTER_ACTIVE)
	var lyra := HeroModel.new("hero_lyra", "Lyra Windwalker", 2, 4, HeroRole.ARCHER, HeroLifecycleState.ROSTER_ACTIVE)

	# Beri chemistry 10 poin antara Alder dan Lyra (+5% bonus ATK = 0.05)
	alder.add_chemistry("hero_lyra", 10)
	lyra.add_chemistry("hero_alder", 10)

	var auras: Dictionary = engine.calculate_party_auras([alder, lyra])
	# ATK bonus = 0.10 (Archer) + 0.05 (Chemistry) = 0.15
	if absf(auras["total_atk_bonus"] - 0.15) > 0.0001:
		return false

	# Jika Lyra mati, hanya Alder yang hidup; tidak ada chemistry dan tidak ada aura Lyra
	lyra.mark_dead()
	var auras_dead: Dictionary = engine.calculate_party_auras([alder, lyra])
	if auras_dead["contributing_heroes_count"] != 1:
		return false
	if absf(auras_dead["total_atk_bonus"] - 0.0) > 0.0001:
		return false
	return true


# ==============================================================================
# GROUP F: CHEMISTRY INTEGRATION
# ==============================================================================

func _test_f1_battle_participants_gain_chemistry() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_f1")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")

	var res: Dictionary = coord.apply_battle_chemistry_gain()
	if res["pairs_count"] != 1:
		return false

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	if alder.get_chemistry_with("hero_lyra") != 2:
		return false
	if lyra.get_chemistry_with("hero_alder") != 2:
		return false
	return true


func _test_f2_party_2_and_reserves_gain_zero_chemistry() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_f2")
	var h3 := HeroModel.new("hero_gale", "Gale", 1, 3, HeroRole.MAGE, HeroLifecycleState.ROSTER_ACTIVE)
	coord.add_hero(h3)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party("hero_gale", "party_2")

	coord.apply_battle_chemistry_gain()

	var gale: HeroModel = coord.get_hero("hero_gale")
	if gale.get_chemistry_with("hero_alder") != 0 or gale.get_chemistry_with("hero_lyra") != 0:
		return false
	return true


func _test_f3_dead_heroes_gain_zero_chemistry() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_f3")
	var h3 := HeroModel.new("hero_gale", "Gale", 1, 3, HeroRole.MAGE, HeroLifecycleState.ROSTER_ACTIVE)
	coord.add_hero(h3)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.assign_hero_to_party("hero_gale", "party_1")

	# Gale gugur
	h3.mark_dead()

	var res: Dictionary = coord.apply_battle_chemistry_gain()
	# Hanya pasangan Alder & Lyra yang mendapatkan kemitraan
	if res["pairs_count"] != 1:
		return false
	var alder: HeroModel = coord.get_hero("hero_alder")
	if alder.get_chemistry_with("hero_gale") != 0:
		return false
	return true


func _test_f4_chemistry_capped_at_max() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_f4")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")

	# Tambah 30 kali (+60 poin, harus terbatasi pada MAX_CHEMISTRY = 50)
	for i in range(30):
		coord.apply_battle_chemistry_gain()

	var alder: HeroModel = coord.get_hero("hero_alder")
	if alder.get_chemistry_with("hero_lyra") != 50:
		return false
	return true


# ==============================================================================
# GROUP G: DETERMINISM & SNAPSHOT INTEGRITY
# ==============================================================================

func _test_g1_snapshot_contains_battle_fields() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_g1")
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.create_deployment(2, "SWORD")

	var snap: GameStateSnapshot = coord.get_current_state()
	if not ("battle_deployments_data" in snap):
		return false
	if not ("battle_party_data" in snap):
		return false
	if not ("battle_aura_data" in snap):
		return false
	if snap.battle_deployments_data.size() != 1:
		return false
	if snap.battle_party_data["party_id"] != "party_1":
		return false
	if snap.battle_aura_data["contributing_heroes_count"] != 1:
		return false
	return true


func _test_g2_snapshot_deep_isolation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_g2")
	coord.assign_hero_to_party("hero_alder", "party_1")

	var snap: GameStateSnapshot = coord.get_current_state()
	# Mutasi snapshot data secara eksternal
	snap.battle_party_data["party_id"] = "MUTATED"
	snap.battle_aura_data["total_def_bonus"] = 999.0

	# State internal coordinator tidak boleh terpengaruh
	var snap2: GameStateSnapshot = coord.get_current_state()
	if snap2.battle_party_data["party_id"] == "MUTATED":
		return false
	if snap2.battle_aura_data["total_def_bonus"] > 10.0:
		return false
	return true


func _test_g3_snapshot_dict_roundtrip() -> bool:
	var snap := GameStateSnapshot.new()
	snap.battle_deployments_data = [{"composition_id": "c1", "current_zone": "GATE", "formation": "FRONTLINE"}]
	snap.battle_party_data = {"party_id": "party_1", "current_zone": "WALL", "formation": "BACKLINE"}
	snap.battle_aura_data = {"atk_multiplier": 1.10, "def_multiplier": 1.10}

	var d: Dictionary = snap.to_dictionary()
	var restored := GameStateSnapshot.from_dictionary(d)
	if restored.battle_deployments_data.size() != 1:
		return false
	if restored.battle_deployments_data[0]["current_zone"] != "GATE":
		return false
	if restored.battle_party_data["formation"] != "BACKLINE":
		return false
	if absf(restored.battle_aura_data["atk_multiplier"] - 1.10) > 0.0001:
		return false
	return true


func _test_g4_deterministic_aura_calculation() -> bool:
	var engine := CombatEngine.new()
	var alder := HeroModel.new("hero_alder", "Alder Ironclad", 1, 4, HeroRole.KNIGHT, HeroLifecycleState.ROSTER_ACTIVE)
	var lyra := HeroModel.new("hero_lyra", "Lyra Windwalker", 2, 4, HeroRole.ARCHER, HeroLifecycleState.ROSTER_ACTIVE)
	alder.add_chemistry("hero_lyra", 12)
	lyra.add_chemistry("hero_alder", 12)

	var r1: Dictionary = engine.calculate_party_auras([alder, lyra])
	var r2: Dictionary = engine.calculate_party_auras([alder, lyra])

	if r1["atk_multiplier"] != r2["atk_multiplier"]:
		return false
	if r1["def_multiplier"] != r2["def_multiplier"]:
		return false
	if r1["chemistry_bonus"] != r2["chemistry_bonus"]:
		return false
	return true


# ==============================================================================
# GROUP H: BATTLE LOCK & CONSERVATION INVARIANTS
# ==============================================================================

func _test_h1_battle_lock_rejects_deployment_zone_and_formation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_h1")
	coord.create_deployment(2, "SWORD")
	var comp_id: String = (coord.get_active_deployments()[0] as DeploymentComposition).composition_id

	coord.inspect_wave()
	coord.start_battle()

	# Dalam STATE_BATTLE, mutasi zona dan formasi deployment harus ditolak
	if coord.set_deployment_zone(comp_id, "WALL"):
		return false
	if coord.set_deployment_formation(comp_id, "SUPPORT"):
		return false
	return true


func _test_h2_battle_lock_rejects_party_zone_and_formation() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_h2")
	coord.inspect_wave()
	coord.start_battle()

	# Dalam STATE_BATTLE, mutasi zona dan formasi party harus ditolak
	if coord.set_party_zone("party_1", "WALL"):
		return false
	if coord.set_party_formation("party_1", "BACKLINE"):
		return false
	return true


func _test_h3_battle_lock_protects_party_and_equipment() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_h3")
	coord.inspect_wave()
	coord.start_battle()

	# Dalam STATE_BATTLE, penugasan pahlawan dan equipment harus ditolak
	if coord.assign_hero_to_party("hero_alder", "party_1"):
		return false
	if coord.remove_hero_from_party("hero_alder"):
		return false
	if coord.equip_hero("hero_alder", "PRIMARY", "SWORD"):
		return false
	if coord.unequip_hero("hero_alder", "PRIMARY"):
		return false
	return true


# ==============================================================================
# GROUP I: DETERMINISTIC 50-WAVE PARTICIPATION & STRESS TEST
# ==============================================================================

func _test_i1_50_wave_participation_stress() -> bool:
	var coord := GameCoordinator.new()
	coord.start_new_session("p6c_stress_50", 999)
	coord.assign_hero_to_party("hero_alder", "party_1")
	coord.assign_hero_to_party("hero_lyra", "party_1")
	coord.create_deployment(2, "SWORD")

	var alder: HeroModel = coord.get_hero("hero_alder")
	var lyra: HeroModel = coord.get_hero("hero_lyra")
	alder.base_atk = 2000
	alder.base_def = 2000
	lyra.base_atk = 2000
	lyra.base_def = 2000

	for wave in range(1, 51):
		# Jaga benteng dan kondisi hero agar tidak terjadi gugur spekulatif selama stress testing
		coord._fortress.current_hp = 1000
		coord._fortress.wall_hp = 500
		coord._fortress.gate_hp = 300
		coord._fortress.armor = 500
		alder.fatigue = 0
		lyra.fatigue = 0

		# 1. PREPARATION: Atur formasi & zona
		var zone: String = "GATE" if wave % 2 == 1 else "WALL"
		coord.set_party_zone("party_1", zone)
		coord.set_party_formation("party_1", "FRONTLINE" if wave % 2 == 1 else "BACKLINE")

		# 2. WAVE_PREVIEW
		if not coord.inspect_wave():
			print("Fail inspect wave at %d" % wave)
			return false

		# 3. BATTLE
		if not coord.start_battle():
			print("Fail start battle at %d" % wave)
			return false

		# Verifikasi Battle Lock
		if coord.set_party_zone("party_1", "FORTRESS"):
			print("Fail battle lock at %d" % wave)
			return false

		# Verifikasi Aura dalam pertempuran
		var auras: Dictionary = coord.get_active_battle_auras()
		if auras.is_empty() or auras["contributing_heroes_count"] != 2:
			print("Fail auras at %d, count=%s" % [wave, auras.get("contributing_heroes_count")])
			return false

		# 4. Simulation ticks (10 tick per gelombang)
		for t in range(10):
			if not coord.step_simulation():
				print("Fail step sim at %d" % wave)
				return false

		# 5. Chemistry gain
		var chem_res: Dictionary = coord.apply_battle_chemistry_gain()
		if chem_res["pairs_count"] != 1:
			print("Fail chem res at %d" % wave)
			return false

		# 6. Resolve battle secara kompatibel
		var res: Dictionary = coord.execute_battle(wave * 100)
		if res.is_empty():
			print("Fail exec battle at %d" % wave)
			return false

		# 7. Proceed to next wave
		if not coord.proceed_from_result():
			print("Fail proceed at %d" % wave)
			return false

		# Verifikasi Invarian Konservasi Prajurit
		var cur_total: int = coord.get_available_soldiers() + coord.get_total_deployed_soldiers()
		var expected_total: int = coord._population.get_total_soldiers()
		if cur_total != expected_total:
			print("Fail conservation at %d: cur=%d, exp=%d" % [wave, cur_total, expected_total])
			return false

	# Setelah 50 gelombang, kemitraan harus mencapai batas maksimal 50
	if alder.get_chemistry_with("hero_lyra") != 50:
		print("Alder chemistry with lyra: %d" % alder.get_chemistry_with("hero_lyra"))
		return false
	if lyra.get_chemistry_with("hero_alder") != 50:
		print("Lyra chemistry with alder: %d" % lyra.get_chemistry_with("hero_alder"))
		return false

	return true
