extends SceneTree

## TestPlaytestSmoke
## Automated smoke playtest runner yang menguji scene main_prototype.tscn:
## Menjalankan seluruh alur pengguna riil di dalam SceneTree Godot:
## BOOT -> PREPARATION -> recruit soldier -> assign worker -> WAVE_PREVIEW
## -> START BATTLE -> pause/resume -> 1x/2x/4x -> commander command
## -> RESULT -> RECOVERY -> NEXT WAVE -> GAME OVER path -> RESTART

const MainPrototype = preload("res://scripts/presentation/scenes/main_prototype.gd")


func _init() -> void:
	print("================================================================")
	print("RUNNING PROTOTYPE SCENE SMOKE PLAYTEST (UI & SCENE INTEGRATION)")
	print("================================================================")

	var scene_res: PackedScene = load("res://scenes/prototype/main_prototype.tscn")
	assert(scene_res != null, "Scene main_prototype.tscn gagal di-load")

	var instance: Node = scene_res.instantiate()
	root.add_child(instance)

	var proto: MainPrototype = instance as MainPrototype
	assert(proto != null, "Instance bukan MainPrototype")
	proto.setup_session()
	assert(proto.coordinator != null, "Coordinator null")
	assert(proto.controller != null, "Controller null")
	assert(proto.debug_view != null, "DebugView null")

	print("[PLAYTEST] Scene instantiated successfully. Initial state: %s" % proto.coordinator.get_current_state().game_phase)
	assert(proto.coordinator.get_current_state().game_phase == "PREPARATION", "State awal harus PREPARATION")

	# 1. Alokasi pekerja
	print("[PLAYTEST] 1. Mengubah alokasi pekerja...")
	var ok_alloc: bool = proto.controller.allocate_workers(2, 1, 1)
	assert(ok_alloc, "Alokasi pekerja gagal")
	var snap1: GameStateSnapshot = proto.coordinator.get_current_state()
	assert(int(snap1.economy_data["repair_workers"]) == 2, "Repair workers tidak sesuai")

	# 2. Rekrut serdadu
	print("[PLAYTEST] 2. Merekrut serdadu...")
	var ok_rec: bool = proto.controller.recruit_soldier("SWORDSMAN", 1)
	assert(ok_rec, "Rekrut serdadu gagal")

	# 2b. Buat deployment prajurit & verifikasi Deployed Soldiers
	print("[PLAYTEST] 2b. Membuat penempatan serdadu & verifikasi Deployed Soldiers...")
	var ok_deploy: bool = proto.controller.create_soldier_deployment(3, "SWORD", "SHIELD", "NONE")
	assert(ok_deploy, "Penempatan serdadu gagal")
	assert(proto.controller.get_total_deployed_soldiers() == 3, "Total deployed soldiers harus 3")

	# 2c. Pasang perlengkapan Hero
	print("[PLAYTEST] 2c. Memasang perlengkapan hero...")
	var ok_hero_eq: bool = proto.controller.equip_hero("hero_alder", "PRIMARY", "SWORD")
	assert(ok_hero_eq, "Equip hero gagal")

	# 3. Wave Preview
	print("[PLAYTEST] 3. Masuk ke WAVE_PREVIEW...")
	var ok_prev: bool = proto.controller.inspect_wave()
	assert(ok_prev, "Inspect wave gagal")
	assert(proto.coordinator.get_current_state().game_phase == "WAVE_PREVIEW", "State harus WAVE_PREVIEW")

	# 4. Start Battle
	print("[PLAYTEST] 4. Memulai Pertempuran...")
	var ok_start: bool = proto.controller.start_battle()
	assert(ok_start, "Start battle gagal")
	assert(proto.coordinator.get_current_state().game_phase == "BATTLE", "State harus BATTLE")

	# 5. Kontrol tempo: Pause, Speed 2x, 4x, 1x
	print("[PLAYTEST] 5. Menguji kontrol tempo (Pause, Resume, Speed)...")
	proto.controller.toggle_pause()
	assert(proto.coordinator.get_current_state().battle_paused, "Harus paused")
	proto.controller.toggle_pause()
	assert(not proto.coordinator.get_current_state().battle_paused, "Harus unpaused")
	proto.controller.set_speed(2.0)
	assert(proto.coordinator.get_current_state().battle_speed == 2.0, "Speed harus 2x")
	proto.controller.set_speed(4.0)
	assert(proto.coordinator.get_current_state().battle_speed == 4.0, "Speed harus 4x")
	proto.controller.set_speed(1.0)
	assert(proto.coordinator.get_current_state().battle_speed == 1.0, "Speed harus 1x")

	# 6. Kirim Commander Command
	print("[PLAYTEST] 6. Mengirimkan Commander Commands...")
	var ok_cmd: bool = proto.controller.send_commander_command("HOLD")
	assert(ok_cmd, "Gagal kirim command HOLD")
	proto.controller.send_commander_command("ADVANCE")
	proto.controller.send_commander_command("PROTECT")

	# 7. Selesaikan Battle
	print("[PLAYTEST] 7. Menyelesaikan pertempuran...")
	var res: Dictionary = proto.controller.resolve_battle_immediately()
	assert(not res.is_empty(), "Hasil pertempuran kosong")
	assert(proto.coordinator.get_current_state().game_phase == "RESULT", "State harus RESULT")

	# 8. Proceed (Recovery -> Next wave)
	print("[PLAYTEST] 8. Melanjutkan ke RECOVERY lalu WAVE 2...")
	var ok_proc: bool = proto.controller.proceed_from_result()
	assert(ok_proc, "Proceed gagal")
	assert(proto.coordinator.get_current_state().game_phase == "PREPARATION", "State harus kembali ke PREPARATION")
	assert(proto.coordinator.get_current_state().current_wave == 2, "Harus Wave 2")

	# 8b. Uji reparasi Pandai Besi (Blacksmith Repair)
	print("[PLAYTEST] 8b. Menguji reparasi Pandai Besi...")
	var EquipmentModel = preload("res://scripts/domain/model/equipment_model.gd")
	proto.coordinator._return_equipment_to_warehouse(EquipmentModel.new("SWORD", 1, 60, 1))
	assert(proto.controller.get_warehouse_damaged_stock("SWORD") >= 1, "Harus ada damaged sword")
	var repair_cost: int = proto.controller.get_equipment_repair_cost("SWORD", 1)
	assert(repair_cost > 0, "Biaya perbaikan harus > 0")
	var gold_pre: int = proto.coordinator.get_treasury_gold()
	var ok_rep: bool = proto.controller.repair_equipment("SWORD", 1)
	assert(ok_rep, "Reparasi Pandai Besi gagal")
	assert(proto.coordinator.get_treasury_gold() == (gold_pre - repair_cost), "Kas emas harus berkurang sesuai biaya reparasi")

	# 9. Uji kondisi Game Over
	print("[PLAYTEST] 9. Menguji kondisi Game Over...")
	proto.coordinator._fortress.current_hp = 0
	proto.controller.inspect_wave()
	proto.controller.start_battle()
	proto.controller.resolve_battle_immediately()
	assert(proto.coordinator.get_current_state().game_phase == "RESULT", "State harus RESULT")
	proto.controller.proceed_from_result()
	assert(proto.coordinator.get_current_state().game_phase == "GAME_OVER", "State harus GAME_OVER")
	print("[PLAYTEST] Game Over berhasil dipicu.")

	# 10. Restart Session
	print("[PLAYTEST] 10. Menguji Restart Session...")
	proto.controller.restart_session()
	assert(proto.coordinator.get_current_state().game_phase == "PREPARATION", "State harus kembali ke PREPARATION setelah restart")
	assert(proto.coordinator.get_current_state().current_wave == 1, "Wave harus kembali ke 1 setelah restart")

	print("================================================================")
	print("PROTOTYPE SCENE SMOKE PLAYTEST: ALL PASS, 0 ERRORS")
	print("================================================================")

	instance.queue_free()
	quit(0)
