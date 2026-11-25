# Changelog — Fortress Game

Semua perubahan pada proyek dicatat dalam dokumen ini. Format mengacu pada prinsip Keep a Changelog.

---

## [Unreleased] - Phase 2: Mathematical / Systems Prototype (Completed & Awaiting Review)

### Added
- Dokumen desain sistem matematika final ([docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md](docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md)) yang memisahkan Core Mathematical Formulas dari Balance Tuning Parameters.
- Domain data models untuk simulasi matematika:
  - `scripts/domain/model/population_model.gd`: Model demografi (konservasi populasi, konversi militer, kematian permanen prajurit, isolasi tentara bayaran).
  - `scripts/domain/model/hero_model.gd`: Model pahlawan individual (EXP scaling, star constraints, fatigue/rest, chemistry party, permadeath).
  - `scripts/domain/model/equipment_model.gd`: Model perlengkapan (tier 1-5, durabilitas, degradasi per battle, penalti broken, biaya perbaikan).
  - `scripts/domain/model/fortress_model.gd`: Model integritas benteng (HP persisten, reduksi damage armor, Game Over saat $HP \le 0$).
- Modul simulasi headless:
  - `scripts/simulation/economy_manager.gd`: Manajer alokasi kerja (produksi, reparasi, pandai besi, konstruksi), neraca kas, dan pemeliharaan upah.
  - `scripts/simulation/wave_generator.gd`: Generator ancaman gelombang 1–100 berbasis threat budget deterministik dengan anti-spike wave 1–5.
  - `scripts/simulation/combat_engine.gd`: Engine pertempuran multi-fase deterministik (Ranged Volley, Frontline Clash, Melee & Heroes, Wall Breach, Resolution) tanpa mengandalkan Battle Power tunggal.
  - `scripts/simulation/headless_simulator.gd`: Simulator komprehensif untuk pengujian multi-gelombang hingga 100 wave.
- Test suite otomatis Phase 2 ([tests/test_mathematical_prototype.gd](tests/test_mathematical_prototype.gd)) yang memvalidasi 18 tes (9 unit boundary, 8 skenario stres A-H, dan kestabilan 100-wave) dengan hasil **18 PASSED, 0 FAILED**.

### Verified
- Phase 1 Architecture Regression: **5 PASSED, 0 FAILED** (tanpa regresi arsitektur).
- 100-Wave Simulation Stability: Berhasil menyelesaikan 100 gelombang berturut-turut tanpa Game Over, tanpa eksploit infinite gold, dan tanpa death spiral.

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
- Persetujuan resmi Developer: APPROVED (Commit `4b7436e`).

---

## [0.1.0] - Phase 0: Workspace & Development Environment Setup (Completed)
