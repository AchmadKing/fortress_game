# Changelog — Fortress Game

Semua perubahan pada proyek dicatat dalam dokumen ini. Format mengacu pada prinsip Keep a Changelog.

---

## [Unreleased] - Phase 2: Mathematical / Systems Prototype (Planning)

### Added
- Dokumen desain sistem dan pemodelan matematika ([docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md](docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md)) yang mencakup model populasi, ekonomi pekerja, agregat pasukan, progresi hero, equipment & durability, wave threat budget, abstraksi combat deterministik, simulasi ekonomi 100-wave, scenario testing, serta pemisahan core formulas dan balance parameters.
- Inisiasi tahap perencanaan sistem matematika Phase 2.

---

## [0.2.0] - Phase 1: Core Game Architecture (Completed & Approved)

### Added
- Implementasi skeleton arsitektur minimal Phase 1 yang membuktikan pemisahan lapisan:
  - `scripts/domain/state/game_state_snapshot.gd`: Domain state container murni berbasis `RefCounted` tanpa dependensi visual.
  - `scripts/domain/config/game_config_resource.gd`: Wadah konfigurasi statis berbasis Godot `Resource`.
  - `scripts/simulation/simulation_runner.gd`: Runner simulasi deterministik tanpa ketergantungan pada `_process()`.
  - `scripts/application/coordinators/game_coordinator.gd`: Coordinator aliran data satu arah (*unidirectional data flow*) dengan sinyal reaktif.
  - `scripts/infrastructure/persistence/save_snapshot_dto.gd`: DTO serialisasi save/load dengan validasi `schema_version`.
- Test suite arsitektur headless ([tests/test_architecture_boundaries.gd](tests/test_architecture_boundaries.gd)) yang memvalidasi ke-5 boundary secara otomatis (5 lulus, 0 gagal).
- Pembaruan dokumen arsitektur [docs/architecture/CORE_ARCHITECTURE.md](docs/architecture/CORE_ARCHITECTURE.md).

### Verified & Approved
- Boundary verification: 5/5 PASSED, 0 FAILED.
- Domain state murni terisolasi dari Node/SceneTree.
- Simulation boundary deterministik dan frame-independent.
- Persistence plain DTO + schema version.
- Gameplay implementation: NOT STARTED.
- Persetujuan resmi Developer: APPROVED (Commit `4b7436e`).

---

## [0.1.0] - Phase 0: Workspace & Development Environment Setup (Completed)

### Added
- Inisialisasi struktur direktori proyek (`plans/`, `docs/`, `scenes/`, `scripts/`, `systems/`, `ui/`, `assets/`, `tests/`).
- Konfigurasi dasar project Godot (`project.godot`).
- Konfigurasi `.gitignore` untuk Godot Engine dan lingkungan development.
- Dokumen roadmap pengembangan tingkat tinggi (`plans/ROADMAP.md`).
- Dokumen status fase aktif (`plans/CURRENT_PHASE.md`).
- Dokumen aturan kerja dan protokol AI Antigravity (`AGENTS.md`).

### Changed
- Pembaruan `README.md` dengan deskripsi genre yang tepat (*Pixel-Art Fantasy Fortress Management / Strategy Simulation*), perbaikan link menjadi relative paths, serta penghapusan sementara klaim lisensi yang belum terverifikasi.
