# Changelog — Fortress Game

Semua perubahan pada proyek dicatat dalam dokumen ini. Format mengacu pada prinsip Keep a Changelog.

---

## [Unreleased] - Phase 1: Core Game Architecture

### Added
- Implementasi skeleton arsitektur minimal Phase 1 yang membuktikan pemisahan lapisan:
  - `scripts/domain/state/game_state_snapshot.gd`: Domain state container murni berbasis `RefCounted` tanpa dependensi visual.
  - `scripts/domain/config/game_config_resource.gd`: Wadah konfigurasi statis berbasis Godot `Resource`.
  - `scripts/simulation/simulation_runner.gd`: Runner simulasi deterministik tanpa ketergantungan pada `_process()`.
  - `scripts/application/coordinators/game_coordinator.gd`: Coordinator aliran data satu arah (*unidirectional data flow*) dengan sinyal reaktif.
  - `scripts/infrastructure/persistence/save_snapshot_dto.gd`: DTO serialisasi save/load dengan validasi `schema_version`.
- Test suite arsitektur headless ([tests/test_architecture_boundaries.gd](tests/test_architecture_boundaries.gd)) yang memvalidasi ke-5 boundary secara otomatis (5 lulus, 0 gagal).
- Pembaruan menyeluruh pada dokumen [docs/architecture/CORE_ARCHITECTURE.md](docs/architecture/CORE_ARCHITECTURE.md) mendokumentasikan struktur skeleton aktual, keputusan teknis, opsi reversible, serta batasan gameplay yang belum diimplementasikan.

### Changed
- Pembaruan [plans/CURRENT_PHASE.md](plans/CURRENT_PHASE.md): Mencatat penyelesaian implementasi skeleton arsitektur Phase 1 dan hasil pengujian boundary, berstatus menunggu approval developer sebelum melangkah ke Phase 2.

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
