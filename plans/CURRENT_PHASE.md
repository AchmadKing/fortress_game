# Current Development Phase

## Phase 3 — Gameplay Prototype

Project saat ini berada pada tahap **Phase 3: Gameplay Prototype — Sub-Phases 3A–3D: COMPLETED / Sub-Phase 3E: PLANNED**.
Spesifikasi teknis implementasi Phase 3B tersedia di [docs/design/PHASE_3B_SOLDIER_DEPLOYMENT_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_3B_SOLDIER_DEPLOYMENT_PLAN.md).
Spesifikasi teknis implementasi Phase 3C tersedia di [docs/design/PHASE_3C_HERO_EQUIPMENT_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_3C_HERO_EQUIPMENT_PLAN.md).

---

### Riwayat Status Fase

- **Phase 0 — Workspace & Development Environment Setup**: **COMPLETED**
- **Phase 1 — Core Game Architecture**: **COMPLETED / APPROVED** (Commit `4b7436e`)
- **Phase 2 — Mathematical / Systems Prototype**: **COMPLETED** (Commit `dd74512`)
- **Phase 3 — Gameplay Prototype**: **IN PROGRESS**
  - **Phase 3A — Current Prototype Baseline & Stabilization**: **COMPLETED** (Commit `2452397`)
    - Architecture & Mathematical Systems Integration: **COMPLETED**
    - Gameplay State Machine: **COMPLETED** (`BOOT -> PREPARATION -> WAVE_PREVIEW -> BATTLE -> RESULT -> RECOVERY -> PREPARATION / GAME_OVER`)
    - GameCoordinator Application Layer: **COMPLETED** (Unidirectional Data Flow)
    - Simulation Runner Orchestration: **COMPLETED** (Zero duplicate Phase 2 logic)
    - Commander Command Abstraction: **COMPLETED** (6 intents: Hold, Advance, Retreat, Protect, Focus, Follow — `LOGGED_PHASE3_DEFERRED`)
    - Prototype Scene & Debug HUD: **COMPLETED** (`scenes/prototype/main_prototype.tscn`)
    - Phase 1 Architecture Regression: **5/5 PASSED, 0 FAILED** ([tests/test_architecture_boundaries.gd](tests/test_architecture_boundaries.gd))
    - Phase 2 Mathematical Regression: **21/21 PASSED, 0 FAILED** ([tests/test_mathematical_prototype.gd](tests/test_mathematical_prototype.gd))
    - Phase 3 Gameplay Unit & Integration Test Suite: **11/11 PASSED, 0 FAILED** ([tests/test_gameplay_prototype.gd](tests/test_gameplay_prototype.gd))
    - Prototype Scene Smoke Playtest: **ALL PASSED, 0 ERRORS** ([tests/test_playtest_smoke.gd](tests/test_playtest_smoke.gd))
  - **Phase 3B — Soldier Deployment & Temporary Equipment Management**: **COMPLETED** (Commit `4f01bfe`)
    - Model regu agregat sementara `DeploymentComposition` dengan identitas kanonikal `make_composition_id(p, s, a)` dan derivasi peran deterministik.
    - Seleksi perlengkapan sadar stok (*stock-aware selection*) dan reservasi atomik seketika dari gudang senjata bersama.
    - Penghapusan 100% pembuatan equipment otomatis (`_ensure_equipment_quantity_for_role` terhapus total).
    - Snapshot perlengkapan terisolasi diteruskan ke `CombatEngine`; perlengkapan gudang yang tidak dibawa bertempur terlindungi 100% dari aus/kehilangan.
    - Multi-slot equipment wear and casualty loss accounting (35% hancur permanen, 65% rusak berat diselamatkan) sesuai formula Phase 2.
    - Seluruh gear selamat kembali ke gudang pasca-wave; seluruh serdadu selamat kembali ke kolam prajurit benteng.
    - Prajurit gugur permanen memotong total populasi hidup.
    - Invariant konservasi $\text{Warehouse} + \text{Reserved} == \text{Total Owned}$ terjaga 100%.
    - Test Suite Phase 3B: **27/27 PASSED, 0 FAILED** ([tests/test_soldier_deployment_temporary.gd](tests/test_soldier_deployment_temporary.gd)).
  - **Phase 3C — Hero Equipment Foundation**: **COMPLETED** (Commit `1d3d51d`)
    - Integrasi perlengkapan Hero dengan gudang senjata bersama benteng (*Shared Fortress Warehouse*).
    - Slot perlengkapan hero minimal: Primary Weapon (`SWORD`, `SPEAR`, `BOW`), Secondary (`SHIELD`), dan Armor (`HEAVY_ARMOR`).
    - Kepemilikan perlengkapan persisten lintas gelombang bagi hero yang bertahan hidup.
    - Mekanisme pengembalian otomatis seluruh perlengkapan hero yang gugur saat permadeath tepat 1 kali ke gudang benteng.
    - Proteksi Battle Lock: mutasi perlengkapan hero dilarang keras saat state `BATTLE`.
    - Invariant konservasi global: $\text{Warehouse} + \text{Hero-held} + \text{Soldier-reserved} == \text{Total Owned}$.
    - Test Suite Phase 3C: **22/22 PASSED, 0 FAILED** ([tests/test_hero_equipment_foundation.gd](tests/test_hero_equipment_foundation.gd)).
    - Regression Suites: Phase 1 (5/5), Phase 2 (21/21), Phase 3A (11/11), Phase 3B (27/27), Scene Smoke (ALL PASS).
  - **Phase 3D — Prototype UX & Interaction Polish**: **COMPLETED**
    - State & Phase guidance banner kontekstual pada header (`BOOT`, `PREPARATION`, `WAVE_PREVIEW`, `BATTLE`, `RESULT`, `RECOVERY`, `GAME_OVER`).
    - Soldier Deployment Builder: custom count, primary weapon, secondary weapon, armor, preview derivasi peran dinamis, dan verifikasi ketersediaan stok & prajurit seketika.
    - Active Deployment Groups List: tampilan transparan rincian regu, tombol Edit/Reconfigure atomik dengan rollback otomatis jika gagal, dan tombol Cancel/Remove untuk pengembalian instan.
    - Hero Equipment UX: Hero roster interaktif dengan tombol Equip, Unequip, dan Swap sadar stok gudang bersama serta proteksi Battle Lock.
    - Shared Warehouse Transparency: tabel telemetri konservasi gudang bersama membuktikan $\text{Warehouse} + \text{Hero-held} + \text{Soldier-reserved} == \text{Total Owned}$.
    - Eliminasi dead-end interaction & feedback banner aksi sukses/gagal yang informatif.
    - Hasil dan pemulihan (Result & Recovery) komprehensif: evaluasi kerusakan benteng, korban serdadu, status pahlawan, return gear hero permadeath, dan kepastian gear serdadu bersifat sementara.
    - Test Suite Phase 3D: **10/10 PASSED, 0 FAILED** ([tests/test_prototype_ux_interaction.gd](tests/test_prototype_ux_interaction.gd)).
    - Full Regression: 96 unit/integration tests PASS (Phase 1 5/5, Phase 2 21/21, Phase 3A 11/11, Phase 3B 27/27, Phase 3C 22/22, Phase 3D 10/10) + Scene Smoke Playtest ALL PASS.
  - **Phase 3E — Final Prototype Verification & Phase 3 Exit Gate**: **PLANNED**
- **Phase 4 — Hero System**: **LOCKED**
- **Phase 5 — Fortress & Management Systems**: **LOCKED**
- **Phase 6 — Tactical Battle & Battlefield Systems**: **LOCKED**

---

### Aturan & Batasan Saat Ini

> [!IMPORTANT]
> **PHASE 3 ITERATIVE ROADMAP TELAH SELESAI DISUSUN DAN DIAUDIT.**
> Status pengerjaan saat ini adalah **PLANNING ONLY — TIDAK ADA PERUBAHAN KODE GAMEPLAY**.
> **PHASE 4 BERSTATUS LOCKED**: DILARANG memulai implementasi Phase 4 sebelum seluruh gerbang keluar (*Exit Gate*) Phase 3 dipenuhi dan menerima persetujuan eksplisit (*Explicit Approval*) dari developer.

---

### Hasil Audit Komponen Teknis Phase 3 Baseline

| Komponen Sistem | Status | Evaluasi & Rencana Iterasi |
| :--- | :---: | :--- |
| **Gameplay State Machine** | COMPLETED | Siklus deterministik normal dan percabangan terminal Game Over terbukti berfungsi penuh tanpa kebocoran alokasi. |
| **Worker Economy** | COMPLETED | 4 pekerjaan sah (Repair, Smith, Constr, Idle). Bebas passive income dan production worker. Pendapatan murni dari Battle Loot. |
| **Soldier Management** | PARTIAL | Rekrutmen zero-sum berjalan. Derivasi peran dari senjata dan fitur dismiss prajurit dijadwalkan pada **Phase 3B**. |
| **Equipment & Warehouse** | PARTIAL | Model durabilitas/kehilangan berfungsi. Invariant konservasi gudang & pencegahan stok $= 0$ dijadwalkan pada **Phase 3B**. |
| **Hero Foundation** | PARTIAL | Stat, level, fatigue, chemistry, dan permadeath berfungsi. Slot equipment hero dijadwalkan pada **Phase 3C**. |
| **Commander Commands** | COMPLETED | 6 intent command DTO diterima dan dicatat ke telemetri (`LOGGED_PHASE3_DEFERRED`). Efek taktis ke **Phase 6**. |
| **Wave Preview & Battle** | COMPLETED | Threat budget & enemy counts via `WaveGenerator`. Pertempuran multi-fase via `CombatEngine` dengan tempo 1x/2x/4x/Pause. |
| **Result & Recovery** | COMPLETED | Post-battle orchestration via method Phase 2 existing tanpa formula manajemen baru. Sesi berhenti mutlak saat benteng hancur. |
| **Automated Test Suites** | COMPLETED | 41 pengujian otomatis lulus 100% (Phase 1: 5/5, Phase 2: 21/21, Phase 3: 11/11, Smoke: ALL PASS). |
