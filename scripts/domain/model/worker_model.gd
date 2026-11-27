class_name WorkerModel
extends RefCounted

## WorkerModel
## Model tenaga kerja agregat benteng (domain layer).
## Mengelola alokasi 4 tugas kanonikal (IDLE, BLACKSMITH, REPAIR, CONSTRUCTION)
## serta pelestarian invarian tenaga kerja dan moral/produktivitas.

const JOB_IDLE = "IDLE"
const JOB_BLACKSMITH = "BLACKSMITH"
const JOB_REPAIR = "REPAIR"
const JOB_CONSTRUCTION = "CONSTRUCTION"

const VALID_JOBS: Array[String] = [JOB_IDLE, JOB_BLACKSMITH, JOB_REPAIR, JOB_CONSTRUCTION]

var total_workers: int = 0
var blacksmith_workers: int = 0
var repair_workers: int = 0
var construction_workers: int = 0
var idle_workers: int = 0

var morale: int = 100 # 0 - 100


func _init(p_total: int = 0, p_morale: int = 100) -> void:
	total_workers = maxi(0, p_total)
	idle_workers = total_workers
	blacksmith_workers = 0
	repair_workers = 0
	construction_workers = 0
	morale = clampi(p_morale, 0, 100)


func get_assigned_workers() -> int:
	return blacksmith_workers + repair_workers + construction_workers


func get_productivity() -> float:
	# Produktivitas deterministik: 1.0 pada moral 100, batas bawah 0.5 pada moral 0
	return clampf(float(morale) / 100.0, 0.5, 1.25)


func sync_total_workers(new_total: int) -> void:
	if new_total < 0:
		return
	total_workers = new_total
	var assigned: int = get_assigned_workers()
	if assigned <= total_workers:
		idle_workers = total_workers - assigned
	else:
		# Penskalaan turun aman jika total berkurang di bawah pekerja tertugaskan
		var overflow: int = assigned - total_workers
		var red_constr: int = mini(construction_workers, overflow)
		construction_workers -= red_constr
		overflow -= red_constr
		var red_smith: int = mini(blacksmith_workers, overflow)
		blacksmith_workers -= red_smith
		overflow -= red_smith
		var red_rep: int = mini(repair_workers, overflow)
		repair_workers -= red_rep
		idle_workers = 0


func set_allocations(rep: int, smith: int, constr: int) -> bool:
	if rep < 0 or smith < 0 or constr < 0:
		return false
	var assigned: int = rep + smith + constr
	if assigned > total_workers:
		return false
	repair_workers = rep
	blacksmith_workers = smith
	construction_workers = constr
	idle_workers = total_workers - assigned
	return true


func get_job_count(job: String) -> int:
	match job.to_upper().strip_edges():
		JOB_IDLE:
			return idle_workers
		JOB_BLACKSMITH:
			return blacksmith_workers
		JOB_REPAIR:
			return repair_workers
		JOB_CONSTRUCTION:
			return construction_workers
		_:
			return 0


func _add_job_count(job: String, delta: int) -> void:
	match job.to_upper().strip_edges():
		JOB_IDLE:
			idle_workers += delta
		JOB_BLACKSMITH:
			blacksmith_workers += delta
		JOB_REPAIR:
			repair_workers += delta
		JOB_CONSTRUCTION:
			construction_workers += delta


func reassign(from_job: String, to_job: String, count: int = 1) -> bool:
	if count <= 0:
		return false
	var f: String = from_job.to_upper().strip_edges()
	var t: String = to_job.to_upper().strip_edges()
	if f == t:
		return true
	if not (f in VALID_JOBS) or not (t in VALID_JOBS):
		return false
	if get_job_count(f) < count:
		return false
	_add_job_count(f, -count)
	_add_job_count(t, count)
	return true


func modify_morale(delta: int) -> void:
	morale = clampi(morale + delta, 0, 100)


func validate_invariants() -> bool:
	if total_workers < 0:
		return false
	if blacksmith_workers < 0 or repair_workers < 0 or construction_workers < 0 or idle_workers < 0:
		return false
	if (blacksmith_workers + repair_workers + construction_workers + idle_workers) != total_workers:
		return false
	if morale < 0 or morale > 100:
		return false
	return true


func clone() -> WorkerModel:
	var w := WorkerModel.new(total_workers, morale)
	w.blacksmith_workers = blacksmith_workers
	w.repair_workers = repair_workers
	w.construction_workers = construction_workers
	w.idle_workers = idle_workers
	return w


func to_dictionary() -> Dictionary:
	return {
		"total_workers": total_workers,
		"assigned_workers": get_assigned_workers(),
		"idle_workers": idle_workers,
		"blacksmith_workers": blacksmith_workers,
		"repair_workers": repair_workers,
		"construction_workers": construction_workers,
		"morale": morale,
		"productivity": get_productivity()
	}


static func from_dictionary(dict: Dictionary) -> WorkerModel:
	var total: int = int(dict.get("total_workers", 0))
	var p_morale: int = int(dict.get("morale", 100))
	var w := WorkerModel.new(total, p_morale)
	w.blacksmith_workers = int(dict.get("blacksmith_workers", 0))
	w.repair_workers = int(dict.get("repair_workers", 0))
	w.construction_workers = int(dict.get("construction_workers", 0))
	w.idle_workers = int(dict.get("idle_workers", total - w.get_assigned_workers()))
	return w
