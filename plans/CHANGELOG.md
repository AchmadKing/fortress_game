# Changelog — Fortress Game

Semua perubahan pada proyek dicatat dalam dokumen ini. Format mengacu pada prinsip Keep a Changelog.

---

## [0.4.2] - Phase 3B Plan Revision: Temporary Soldier Deployment & Equipment Management

### Changed (Design Plan Only)
- **Phase 3B Architectural Revision**:
  - Merevisi dokumen perencanaan Phase 3B ([docs/design/PHASE_3B_SOLDIER_DEPLOYMENT_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_3B_SOLDIER_DEPLOYMENT_PLAN.md)) menggantikan konsep kepemilikan perlengkapan permanen individual prajurit dengan konsep **Alokasi Perlengkapan Sementara Berbasis Gelombang (*Temporary Wave Deployment*)**.
  - Mengonfigurasi regu tempur agregat (*Deployment Compositions*): `Soldier Count`, `Primary Weapon` (Wajib), `Secondary Weapon` (Opsional), `Armor` (Opsional).
  - Menerapkan seleksi perlengkapan sadar stok (*stock-aware selection*) dengan menonaktifkan opsi jika stok gudang $< N$, serta reservasi seketika (*immediate reservation*).
  - Menetapkan aturan presedensi derivasi peran dinamis per gelombang (Sword $\rightarrow$ Swordsman, Sword+Shield $\rightarrow$ Shield Infantry, dll.).
  - Mendefinisikan siklus pengembalian gear pasca-wave ke gudang benteng dengan preservasi penuh aturan Phase 2 (aus normal & 65% gear korban rusak kembali; 35% gear korban hancur permanen).
  - Menegaskan pemisahan prajurit gugur (terpotong permanen dari populasi) dengan prajurit selamat (kembali ke kolam prajurit benteng).
  - Menghapus dokumen usang `PHASE_3B_SOLDIER_EQUIPMENT_PLAN.md`.

---

## [0.4.1] - Phase 3: Comprehensive Audit & Finalized Iterative Roadmap (3A–3E)

### Planned & Audited
- **Phase 3 Comprehensive Audit**:
  - Melakukan audit menyeluruh terhadap branch `main` pada commit `2452397` untuk memvalidasi isolasi arsitektur, integrasi simulasi Phase 2, dan kelengkapan konsep gameplay.
  - Menyusun tabel analisis kesenjangan (*15-Area Gap Analysis*) yang mencakup Preparation, Soldier, Equipment, Warehouse, Hero, Worker, Wave Preview, Battle, Commander Commands, Result, Recovery, Game Over, Persistence, Tests, dan Prototype UI.
- **Finalized Phase 3 Iterative Roadmap (3A–3E)**:
  - **Phase 3A — Current Prototype Baseline & Stabilization**: Dinyatakan **COMPLETED** (Seluruh 41 pengujian otomatis lulus 100%, prototype playable stabil di Godot Editor).
  - **Phase 3B — Soldier Equipment & Warehouse Conservation**: Direncanakan untuk mengimplementasikan derivasi peran prajurit dari senjata (Sword, Shield, Spear, Bow, Heavy Armor), pembebasan prajurit (*dismiss soldier*), dan penegakan invariant konservasi gudang ($\text{Total} = \text{Warehouse} + \text{Equipped}$).
  - **Phase 3C — Hero Equipment Foundation**: Direncanakan untuk mengimplementasikan slot perlengkapan minimal hero (Weapon, Armor), integrasi equip/unequip dengan gudang benteng, dan pengembalian gear otomatis saat permadeath.
  - **Phase 3D — Prototype UX & Interaction Polish**: Direncanakan untuk melengkapi kontrol UI pada fase persiapan dan mengeliminasi gameplay dead-ends.
  - **Phase 3E — Final Prototype Verification & Phase 3 Exit Gate**: Pengujian regresi otomatis akhir, playtest stres 20 wave, dan validasi penutupan resmi Phase 3.
- **Phase Boundary & Lock Enforcement**:
  - Mengunci secara tegas **Phase 4 (Hero System)** dengan status **LOCKED** hingga Phase 3 menyelesaikan seluruh iterasi 3A–3E.
  - Mendokumentasikan daftar *Explicit Non-Goals & Deferrals* ke Phase 4, Phase 5, Phase 6, Phase 7, Phase 8, Phase 9, dan Phase 10.

---

## [0.4.0] - Phase 3: Playable Gameplay Prototype (Implemented & Validated)

### Added
- **Gameplay State Machine** (`scripts/application/state_machine/gameplay_state_machine.gd`):
  - State deterministik: `BOOT`, `PREPARATION`, `WAVE_PREVIEW`, `BATTLE`, `RESULT`, `RECOVERY`, `GAME_OVER`.
  - Validasi transisi ketat, menolak transisi ilegal.
- **Commander Command DTO** (`scripts/domain/command/commander_command.gd`):
  - 6 intensi perintah komandan: `HOLD`, `ADVANCE`, `RETREAT`, `PROTECT`, `FOCUS`, `FOLLOW`.
- **GameCoordinator Application Orchestration** (`scripts/application/coordinators/game_coordinator.gd`):
  - Mengorkestrasi aliran data satu arah (*unidirectional data flow*), memvalidasi aksi player, memanggil engine simulasi Phase 2, dan memancarkan `state_changed(snapshot)`.
- **Domain Snapshot Extension** (`scripts/domain/state/game_state_snapshot.gd`):
  - Payload terstruktur untuk model benteng, populasi, hero, gudang equipment, bendahara, gelombang, dan telemetry tempur dengan backward compatibility penuh ke Phase 1.
- **Simulation Runner Extension** (`scripts/simulation/simulation_runner.gd`):
  - Orchestration methods untuk `WaveGenerator`, `CombatEngine`, dan `EconomyManager` tanpa menduplikasi formula matematika Phase 2.
- **Presentation Controller & View** (`scripts/presentation/controllers/game_controller.gd`, `scripts/presentation/views/prototype_debug_view.gd`):
  - Controller tempo pertempuran (Pause/Resume, Speed 1x, 2x, 4x) dan pemetaan input keyboard/UI.
  - Reactive text-based debug telemetry HUD yang pasif mengamati snapshot tanpa polling `_process()`.
- **Prototype Scene** (`scenes/prototype/main_prototype.tscn`, `scripts/presentation/scenes/main_prototype.gd`):
  - Playable scene minimal yang dapat dijalankan langsung di Godot Editor.
- **Automated Test Suites**:
  - `tests/test_gameplay_prototype.gd`: 11 unit & integration tests Phase 3 (100% PASS).
  - `tests/test_playtest_smoke.gd`: Automated smoke playtest scene integration (ALL PASS, 0 ERRORS).

### Verified
- **Phase 1 Architecture Regression**: **5/5 PASSED, 0 FAILED**.
- **Phase 2 Mathematical Regression**: **21/21 PASSED, 0 FAILED**.
- **Phase 3 Gameplay Prototype Tests**: **11/11 PASSED, 0 FAILED**.
- **Prototype Smoke Playtest**: **ALL PASSED, 0 ERRORS**.

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
