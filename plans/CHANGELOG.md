# Changelog — Fortress Game

Semua perubahan pada proyek dicatat dalam dokumen ini. Format mengacu pada prinsip Keep a Changelog.

---

## [0.3.0] - Phase 2: Mathematical / Systems Prototype (Completed & Validated)

### Fixed & Refactored (Four Corrective Items)
1. **Roadmap & Phase Synchronization**: Seluruh dokumen status (`CURRENT_PHASE.md`, `ROADMAP.md`, `CHANGELOG.md`, `README.md`) disinkronkan ke status resmi `Phase 2 — COMPLETED` dan `Phase 3 — NOT STARTED / LOCKED`.
2. **Worker & Economy Correction**: Menghapus seluruh referensi ke `Production Worker` dan `base_passive_income`. Pekerja sah hanya mencakup `Blacksmith`, `Repair`, `Construction`, dan `Idle`. Sumber pendapatan utama benteng berasal dari Battle Loot kemenangan pertempuran.
3. **Equipment Quantity & Ownership Model**: Memperbaiki kalkulasi efektivitas militer agar kuantitas perlengkapan riil di gudang membatasi jumlah prajurit yang mendapatkan bonus tier. Menguji secara ketat Kasus A, B, C, dan D serta mengecualikan perlengkapan yang rusak (*broken*).
4. **Equipment Loss & Deterministic Hero Survival/Death**:
   - Korban prajurit (*casualties*) secara deterministik menyebabkan peluang kehilangan perlengkapan ($35\%$) dan keausan berat ($65\%$).
   - Kelangsungan hidup hero dievaluasi berdasarkan keparahan breach, kelelahan (*fatigue*), dan pertahanan (*defense*). Keruntuhan benteng tidak otomatis membunuh seluruh hero sekaligus. Hero yang gugur dinyatakan `is_alive = false` dan keluar permanen dari active combat, EXP, chemistry, dan pemulihan stamina.

### Added
- Dokumen desain matematika final ([docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md](docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md)).
- Domain data models: `equipment_model.gd`, `fortress_model.gd`, `hero_model.gd`, `population_model.gd`.
- Simulation modules: `combat_engine.gd`, `economy_manager.gd`, `wave_generator.gd`, `headless_simulator.gd`.
- Automated test suite: `tests/test_mathematical_prototype.gd` (21 tes lulus: 12 unit boundaries, 8 skenario stres A–H, dan simulasi 100 gelombang).

### Verified
- **Phase 1 Architecture Regression**: **5 PASSED, 0 FAILED** (tanpa regresi arsitektur).
- **Phase 2 Mathematical Tests**: **21 PASSED, 0 FAILED**.
- **100-Wave System Stability**: 100 gelombang berhasil diselesaikan tanpa Game Over dengan neraca kas dan populasi yang seimbang di bawah kebijakan otomasi manajemen.

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
