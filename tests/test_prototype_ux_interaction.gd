extends SceneTree

## TestPrototypeUxInteraction
## Test suite otomatis untuk memvalidasi implementasi Phase 3D (Prototype UX & Interaction Polish).
## Memvalidasi:
## 1. State / Phase header contextual guidance text across all states (BOOT, PREP, PREVIEW, BATTLE, RESULT, RECOVERY, GAME_OVER).
## 2. Soldier Deployment Builder: role derivation preview, stock verification, and dynamic count.
## 3. Deployment Reconfiguration: atomic update and rollback on failure.
## 4. Hero Equipment UI interaction & Battle Lock enforcement.
## 5. Shared Warehouse Transparency & conservation equation invariant: Total = WH + Hero + Soldier.
## 6. Dead-end prevention & actionable feedback banners for successful/rejected operations.
## 7. Result & Recovery outcome reporting completeness.
## 8. Full regression compatibility across Phase 1, Phase 2, Phase 3A, 3B, and 3C.

const GameCoordinator = preload("res://scripts/application/coordinators/game_coordinator.gd")
const GameController = preload("res://scripts/presentation/controllers/game_controller.gd")
const PrototypeDebugView = preload("res://scripts/presentation/views/prototype_debug_view.gd")
const DeploymentComposition = preload("res://scripts/domain/model/deployment_composition.gd")
const HeroModel = preload("res://scripts/domain/model/hero_model.gd")
const EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
const GameplayStateMachine = preload("res://scripts/application/state_machine/gameplay_state_machine.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PHASE 3D PROTOTYPE UX & INTERACTION POLISH TESTS")
	print("================================================================")

	var passed: int = 0
	var failed: int = 0

	var test_list: Array = [
		{"name": "test_phase_guidance_text_across_all_states", "fn": Callable(self, "_test_phase_guidance_text_across_all_states")},
		{"name": "test_soldier_deployment_builder_role_preview", "fn": Callable(self, "_test_soldier_deployment_builder_role_preview")},
		{"name": "test_soldier_deployment_stock_validation", "fn": Callable(self, "_test_soldier_deployment_stock_validation")},
		{"name": "test_deployment_reconfiguration_atomic_success_and_rollback", "fn": Callable(self, "_test_deployment_reconfiguration_atomic_success_and_rollback")},
		{"name": "test_hero_equipment_interaction_and_battle_lock", "fn": Callable(self, "_test_hero_equipment_interaction_and_battle_lock")},
		{"name": "test_shared_warehouse_conservation_invariant", "fn": Callable(self, "_test_shared_warehouse_conservation_invariant")},
		{"name": "test_hero_permadeath_equipment_return_display", "fn": Callable(self, "_test_hero_permadeath_equipment_return_display")},
		{"name": "test_dead_end_prevention_and_actionable_feedback", "fn": Callable(self, "_test_dead_end_prevention_and_actionable_feedback")},
		{"name": "test_result_and_recovery_outcome_reporting", "fn": Callable(self, "_test_result_and_recovery_outcome_reporting")},
		{"name": "test_view_and_controller_integration", "fn": Callable(self, "_test_view_and_controller_integration")}
	]

	for t in test_list:
		if _run_test(str(t["name"]), t["fn"]):
			passed += 1
		else:
			failed += 1

	print("================================================================")
	print("PHASE 3D TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("================================================================")

	if failed == 0:
		quit(0)
	else:
		quit(1)


func _run_test(test_name: String, test_fn: Callable) -> bool:
	print("[TEST] Running %s..." % test_name)
	var ok: bool = bool(test_fn.call())
	if ok:
		print("[PASS] %s" % test_name)
	else:
		printerr("[FAIL] %s" % test_name)
	return ok


# Helper setup
func _create_test_session() -> Dictionary:
	var coord := GameCoordinator.new()
	var ctrl := GameController.new()
	var view := PrototypeDebugView.new()
	root.add_child(ctrl)
	root.add_child(view)
	coord.start_new_session("test_ux_session", 999)
	ctrl.setup(coord)
	view.setup(coord, ctrl)
	return {"coordinator": coord, "controller": ctrl, "view": view}


func _cleanup_session(session: Dictionary) -> void:
	var ctrl: GameController = session.get("controller")
	var view: PrototypeDebugView = session.get("view")
	if ctrl != null and is_instance_valid(ctrl):
		ctrl.queue_free()
	if view != null and is_instance_valid(view):
		view.queue_free()


# 1. Header Phase Guidance across all states
func _test_phase_guidance_text_across_all_states() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]

	var phases := ["BOOT", "PREPARATION", "WAVE_PREVIEW", "BATTLE", "RESULT", "RECOVERY", "GAME_OVER"]
	for p in phases:
		var text: String = view._get_phase_guidance_text(p)
		if text.is_empty():
			_cleanup_session(s)
			return false
		if text == "Status fase tidak diketahui.":
			_cleanup_session(s)
			return false

	# Verify specific contextual guidance
	if not ("Persiapan" in view._get_phase_guidance_text("PREPARATION")):
		_cleanup_session(s)
		return false
	if not ("Battle Lock" in view._get_phase_guidance_text("BATTLE")):
		_cleanup_session(s)
		return false
	if not ("Pemulihan" in view._get_phase_guidance_text("RECOVERY")):
		_cleanup_session(s)
		return false
	if not ("Benteng Runtuh" in view._get_phase_guidance_text("GAME_OVER")):
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


# 2. Soldier Deployment Builder: Role Preview
func _test_soldier_deployment_builder_role_preview() -> bool:
	# SWORD tunggal -> SWORDSMAN
	if DeploymentComposition.resolve_role("SWORD", "NONE", "NONE") != "SWORDSMAN":
		return false
	# SWORD + SHIELD -> SHIELD_INFANTRY
	if DeploymentComposition.resolve_role("SWORD", "SHIELD", "NONE") != "SHIELD_INFANTRY":
		return false
	# SWORD + HEAVY_ARMOR (tanpa shield) -> HEAVY_INFANTRY
	if DeploymentComposition.resolve_role("SWORD", "NONE", "HEAVY_ARMOR") != "HEAVY_INFANTRY":
		return false
	# SPEAR (+ ANY) -> SPEARMAN
	if DeploymentComposition.resolve_role("SPEAR", "NONE", "NONE") != "SPEARMAN":
		return false
	if DeploymentComposition.resolve_role("SPEAR", "SHIELD", "NONE") != "SPEARMAN":
		return false
	# BOW (+ ANY) -> ARCHER
	if DeploymentComposition.resolve_role("BOW", "NONE", "NONE") != "ARCHER":
		return false

	return true


# 3. Soldier Deployment Stock Validation
func _test_soldier_deployment_stock_validation() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]

	var init_avail: int = ctrl.get_available_soldiers()
	var init_sword: int = ctrl.get_warehouse_stock("SWORD")

	# Deploy melebihi serdadu tersedia -> GAGAL
	var fail_too_many: bool = ctrl.create_deployment(init_avail + 5, "SWORD")
	if fail_too_many:
		_cleanup_session(s)
		return false

	# Deploy melebihi stok gudang -> GAGAL
	var fail_stock: bool = ctrl.create_deployment(init_sword + 10, "SWORD")
	if fail_stock:
		_cleanup_session(s)
		return false

	# Deploy sah -> SUKSES
	var ok_deploy: bool = ctrl.create_deployment(2, "SWORD")
	if not ok_deploy:
		_cleanup_session(s)
		return false

	if ctrl.get_available_soldiers() != init_avail - 2:
		_cleanup_session(s)
		return false
	if ctrl.get_warehouse_stock("SWORD") != init_sword - 2:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


# 4. Deployment Reconfiguration Atomic Success & Rollback
func _test_deployment_reconfiguration_atomic_success_and_rollback() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]

	# Buat 2x SWORD
	var ok1: bool = ctrl.create_deployment(2, "SWORD")
	if not ok1:
		_cleanup_session(s)
		return false

	var old_cid: String = "SWORD|NONE|NONE"
	var prev_avail: int = ctrl.get_available_soldiers()
	var prev_bow: int = ctrl.get_warehouse_stock("BOW")
	var prev_sword: int = ctrl.get_warehouse_stock("SWORD")

	# Kasus GAGAL: Reconfigure meminta stok yang tidak ada (misal BOW 99)
	var fail_reconf: bool = ctrl.reconfigure_deployment(old_cid, 99, "BOW")
	if fail_reconf:
		_cleanup_session(s)
		return false

	# Verifikasi rollback atomik: grup awal tetap utuh
	var deps: Array = ctrl.get_active_deployments()
	if deps.size() != 1:
		_cleanup_session(s)
		return false
	if deps[0].composition_id != old_cid:
		_cleanup_session(s)
		return false
	if ctrl.get_available_soldiers() != prev_avail:
		_cleanup_session(s)
		return false
	if ctrl.get_warehouse_stock("SWORD") != prev_sword:
		_cleanup_session(s)
		return false

	# Kasus SUKSES: Reconfigure dari 2x SWORD menjadi 2x BOW
	var ok_reconf: bool = ctrl.reconfigure_deployment(old_cid, 2, "BOW")
	if not ok_reconf:
		_cleanup_session(s)
		return false

	var new_deps: Array = ctrl.get_active_deployments()
	if new_deps.size() != 1:
		_cleanup_session(s)
		return false
	if new_deps[0].composition_id != "BOW|NONE|NONE":
		_cleanup_session(s)
		return false
	if ctrl.get_warehouse_stock("SWORD") != prev_sword + 2:
		_cleanup_session(s)
		return false
	if ctrl.get_warehouse_stock("BOW") != prev_bow - 2:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


# 5. Hero Equipment Interaction & Battle Lock
func _test_hero_equipment_interaction_and_battle_lock() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]
	var coord: GameCoordinator = s["coordinator"]

	var init_wh_sword: int = ctrl.get_warehouse_stock("SWORD")
	var ok_equip: bool = ctrl.equip_hero("hero_alder", "PRIMARY", "SWORD")
	if not ok_equip:
		_cleanup_session(s)
		return false
	if ctrl.get_warehouse_stock("SWORD") != init_wh_sword - 1:
		_cleanup_session(s)
		return false

	# Masuk ke WAVE_PREVIEW lalu ke BATTLE
	ctrl.inspect_wave()
	ctrl.start_battle()

	if coord.get_current_state().game_phase != "BATTLE":
		_cleanup_session(s)
		return false

	# Uji Battle Lock: equip, unequip, swap harus DITOLAK
	var lock_equip: bool = ctrl.equip_hero("hero_alder", "SECONDARY", "SHIELD")
	var lock_unequip: bool = ctrl.unequip_hero("hero_alder", "PRIMARY")
	var lock_swap: bool = ctrl.swap_hero_equipment("hero_alder", "PRIMARY", "BOW")

	if lock_equip or lock_unequip or lock_swap:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


# 6. Shared Warehouse Conservation Invariant
func _test_shared_warehouse_conservation_invariant() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]

	var types := ["SWORD", "SHIELD", "SPEAR", "BOW", "HEAVY_ARMOR"]

	# Catat total owned awal
	var initial_totals := {}
	for t in types:
		initial_totals[t] = ctrl.get_total_owned_stock(t)

	# Lakukan kombinasi aksi: hero equip + soldier deployment
	ctrl.equip_hero("hero_alder", "PRIMARY", "SWORD")
	ctrl.equip_hero("hero_alder", "SECONDARY", "SHIELD")
	ctrl.create_deployment(2, "SWORD", "SHIELD")

	for t in types:
		var wh: int = ctrl.get_warehouse_stock(t)
		var hero: int = ctrl.get_hero_held_equipment_stock(t)
		var reg: int = ctrl.get_reserved_equipment_stock(t)
		var tot: int = ctrl.get_total_owned_stock(t)

		# Invariant mutlak
		if wh + hero + reg != tot:
			_cleanup_session(s)
			return false
		if tot != initial_totals[t]:
			_cleanup_session(s)
			return false

	_cleanup_session(s)
	return true


# 7. Hero Permadeath Equipment Return
func _test_hero_permadeath_equipment_return_display() -> bool:
	var s := _create_test_session()
	var coord: GameCoordinator = s["coordinator"]
	var ctrl: GameController = s["controller"]

	# Equip hero_alder dengan SWORD dan SHIELD
	ctrl.equip_hero("hero_alder", "PRIMARY", "SWORD")
	ctrl.equip_hero("hero_alder", "SECONDARY", "SHIELD")

	if ctrl.get_warehouse_stock("SWORD") != 9:
		_cleanup_session(s)
		return false
	if ctrl.get_warehouse_stock("SHIELD") != 9:
		_cleanup_session(s)
		return false

	# Simulasikan kematian hero_alder
	var hero: HeroModel = coord.get_hero("hero_alder")
	hero.mark_dead()

	ctrl.inspect_wave()
	ctrl.start_battle()
	ctrl.resolve_battle_immediately()
	ctrl.proceed_from_result()

	# Seluruh gear hero_alder harus kembali ke gudang
	if ctrl.get_warehouse_stock("SWORD") != 10:
		_cleanup_session(s)
		return false
	if ctrl.get_warehouse_stock("SHIELD") != 10:
		_cleanup_session(s)
		return false
	if hero.has_equipment("PRIMARY") or hero.has_equipment("SECONDARY"):
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


# 8. Dead-end Prevention & Actionable Feedback
func _test_dead_end_prevention_and_actionable_feedback() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]

	# Habiskan 12 sipil dengan merekrut 12 serdadu
	for i in range(12):
		view._recruit("SWORDSMAN")

	# Sekarang sipil == 0. Rekrut lagi harus GAGAL dan menghasilkan pesan DITOLAK
	view._recruit("SWORDSMAN")
	if not ("DITOLAK" in view._lbl_feedback_banner.text):
		_cleanup_session(s)
		return false

	# Coba deployment melebihi serdadu
	view._action_create_deployment(99, "SWORD", "NONE", "NONE")
	if not ("DITOLAK" in view._lbl_feedback_banner.text):
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


# 9. Result and Recovery Outcome Reporting
func _test_result_and_recovery_outcome_reporting() -> bool:
	var s := _create_test_session()
	var ctrl: GameController = s["controller"]
	var coord: GameCoordinator = s["coordinator"]

	ctrl.create_deployment(2, "SWORD")
	ctrl.inspect_wave()
	ctrl.start_battle()
	var res: Dictionary = ctrl.resolve_battle_immediately()

	var required_keys := [
		"victory", "fortress_damage_taken", "total_dead_soldiers",
		"equipment_lost", "equipment_damaged", "loot_gold", "exp_per_hero"
	]
	for k in required_keys:
		if not res.has(k):
			_cleanup_session(s)
			return false

	if coord.get_current_state().game_phase != "RESULT":
		_cleanup_session(s)
		return false

	var ok_proc: bool = ctrl.proceed_from_result()
	if not ok_proc:
		_cleanup_session(s)
		return false

	# Setelah proceed, harus kembali ke PREPARATION Wave 2
	if coord.get_current_state().game_phase != "PREPARATION":
		_cleanup_session(s)
		return false
	if coord.get_current_state().current_wave != 2:
		_cleanup_session(s)
		return false

	# Perlengkapan serdadu selamat harus sudah kembali ke gudang
	if coord.get_active_deployments().size() != 0:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true


# 10. View and Controller Integration
func _test_view_and_controller_integration() -> bool:
	var s := _create_test_session()
	var view: PrototypeDebugView = s["view"]
	var coord: GameCoordinator = s["coordinator"]

	# Verifikasi komponen UI terikat dengan benar
	if view._lbl_state_badge == null or view._lbl_wave_indicator == null or view._lbl_phase_guidance == null:
		_cleanup_session(s)
		return false
	if view._lbl_fortress_hp == null or view._lbl_treasury == null or view._lbl_warehouse == null:
		_cleanup_session(s)
		return false

	# Trigger update alokasi pekerja via view
	view._adjust_workers(1, 1, 1)
	if coord.get_current_state().economy_data["repair_workers"] != 1:
		_cleanup_session(s)
		return false

	_cleanup_session(s)
	return true
