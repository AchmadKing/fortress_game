# Project Roadmap — Fortress Game

High-level roadmap pengembangan proyek `fortress_game`.

> **IMPORTANT**:
> Dokumen ini adalah peta jalan tingkat tinggi (HIGH-LEVEL ONLY).
> Fase berikutnya hanya boleh dimulai setelah ada **explicit approval** dari developer.
> Jangan mengembangkan detail implementasi atau memulai coding untuk fase berikutnya tanpa persetujuan.

---

## Phase 0 — Workspace & Development Environment
- **Status**: COMPLETED
- **Tujuan**:
  - Project directory structure
  - Git / GitHub repository setup & safety
  - Godot project configuration baseline
  - Antigravity ↔ Godot development workflow
  - Development rules (`AGENTS.md`)
  - Planning & documentation structure (`plans/`, `docs/`)

## Phase 1 — Core Game Architecture
- **Status**: COMPLETED
- **Tujuan**:
  - Mendefinisikan arsitektur inti game berdasarkan konsep desain yang disetujui;
  - Menentukan pembagian tanggung jawab (*responsibility boundaries*) antar sistem;
  - Menentukan aliran data (*data flow*) dan hierarki dependensi antar sistem;
  - Menentukan struktur data domain inti yang minimal dan esensial;
  - Menentukan batas tegas antara presentation/UI, game logic, simulasi, data, dan persistence;
  - Menentukan pendekatan komunikasi antar sistem setelah analisis kebutuhan teknis;
  - Membangun baseline arsitektur yang ringan (*lightweight*), hemat memori, dan optimal untuk platform target mobile Android serta hardware development yang terbatas.

## Phase 2 — Mathematical / Systems Prototype
- **Status**: COMPLETED
- **Tujuan**: Memvalidasi formula angka dasar, stat scaling, dan simulasi logic tanpa visual berat.
  - Empat corrective items review selesai (sinkronisasi roadmap, penghapusan passive income & production worker, perbaikan model kuantitas equipment, implementasi equipment loss & survival hero deterministik).
  - Seluruh pengujian headless (21/21 Phase 2 tests, 5/5 Phase 1 regression tests) tervalidasi lulus.
  - Simulasi 100-wave stabil tanpa eksploit ekonomi maupun death spiral.

## Phase 3 — Gameplay Prototype
- **Status**: COMPLETED
- **Tujuan**: Prototipe interaksi gameplay minimum yang dapat dimainkan (*playable prototype*) di Godot Editor berbasis arsitektur Phase 1 dan sistem matematika Phase 2.
  - **Phase 3A — Baseline & Stabilization**: **COMPLETED** (Commit `2452397`)
    - Gameplay State Machine terintegrasi (`BOOT` s/d `GAME_OVER`).
    - Kontrol persiapan (alokasi pekerja 4 tugas sah, rekrutmen serdadu zero-sum).
    - Kontrol tempo battle (pause, resume, speed 1x/2x/4x) dan pengiriman 6 commander commands intent.
    - Scene prototype playable (`scenes/prototype/main_prototype.tscn`) & debug HUD.
    - Seluruh pengujian regression Phase 1 (5/5), Phase 2 (21/21), Phase 3 (11/11), dan Playtest Smoke 100% PASS.
  - **Phase 3B — Soldier Deployment & Temporary Equipment Management**: **COMPLETED** (Commit `4f01bfe`)
    - Alokasi perlengkapan sementara berbasis gelombang (*temporary wave deployment*), bukan kepemilikan permanen.
    - Konfigurasi regu agregat: Soldier Count, Primary Weapon (Wajib), Secondary Weapon (Opsional), Armor (Opsional).
    - Seleksi perlengkapan sadar stok (*stock-aware selection*) dan reservasi seketika (*immediate reservation*).
    - Derivasi peran prajurit dinamis per gelombang (Sword $\rightarrow$ Swordsman, Sword+Shield $\rightarrow$ Shield Infantry, dll.).
    - Kembalinya gear selamat ke gudang pasca-wave (aus normal & 65% gear korban rusak kembali; 35% gear korban hancur permanen per Phase 2).
    - Prajurit selamat kembali ke kolam prajurit benteng; prajurit gugur terpotong permanen.
    - Penegakan ketat invariant konservasi: $\text{Total Owned} = \text{Warehouse} + \text{Reserved Deployment}$.
    - Test Suite Phase 3B: 27/27 PASSED, 0 FAILED. Zero regression pada Phase 1, Phase 2, dan Phase 3A.
  - **Phase 3C — Hero Equipment Foundation**: **COMPLETED** (Commit `1d3d51d`)
    - Slot perlengkapan minimal Hero (Primary Weapon, Secondary, Armor) terintegrasi dengan gudang senjata benteng bersama.
    - Kepemilikan perlengkapan persisten lintas gelombang bagi hero yang bertahan hidup.
    - Pengembalian perlengkapan hero ke gudang benteng secara otomatis saat permadeath (tepat 1 kali).
    - Proteksi Battle Lock selama simulasi pertempuran aktif.
    - Test Suite Phase 3C: 22/22 PASSED, 0 FAILED. Zero regression pada seluruh fase sebelumnya.
  - **Phase 3D — Prototype UX & Interaction Polish**: **COMPLETED (INCL. FOLLOW-UP CORRECTIONS)** (Commits `463f91c`, `ba3c0c5`)
    - State & Phase guidance banner kontekstual pada header (`BOOT`, `PREPARATION`, `WAVE_PREVIEW`, `BATTLE`, `RESULT`, `RECOVERY`, `GAME_OVER`).
    - Soldier Deployment Builder: custom count, primary weapon, secondary weapon, armor, preview derivasi peran dinamis, dan verifikasi ketersediaan stok & prajurit seketika.
    - Active Deployment Groups List: tampilan transparan rincian regu, tombol Edit/Reconfigure atomik dengan rollback otomatis jika gagal, dan tombol Cancel/Remove untuk pengembalian instan.
    - Hero Equipment UX: Hero roster interaktif dengan tombol Equip, Unequip, dan Swap sadar stok gudang bersama serta proteksi Battle Lock.
    - Shared Warehouse Transparency: tabel telemetri konservasi gudang bersama membuktikan $\text{Warehouse} + \text{Hero-held} + \text{Soldier-reserved} == \text{Total Owned}$.
    - Eliminasi dead-end interaction & feedback banner aksi sukses/gagal yang informatif.
    - Hasil dan pemulihan (Result & Recovery) komprehensif: evaluasi kerusakan benteng, korban serdadu, status pahlawan, return gear hero permadeath, dan kepastian gear serdadu bersifat sementara.
    - Follow-up corrections: tampilan `Deployed Soldiers: <sum>` terpisah dari kolam cadangan prajurit; aturan durabilitas serdadu selamat (kembali 100% usable); resolusi korban (35% musnah, 65% rusak berat); reparasi Pandai Besi berbasis Gold dengan diskon alokasi pekerja; penegakan invariant konservasi stok usable vs damaged.
    - Test Suites: Phase 3D interaction (10/10 PASS) + Follow-up corrections (23/23 PASS).
  - **Phase 3E — Final Prototype Verification & Phase 3 Exit Gate**: **COMPLETED**
    - Verifikasi ketat 15 kriteria integritas fungsional melalui `tests/test_phase3e_final_verification.gd` (15/15 PASS, 0 FAIL).
    - Simulasi stres 20 wave berturut-turut lulus 100% tanpa crash, kebocoran memori, pertumbuhan array tak terbatas, atau pelanggaran invariant gudang bersama.
    - Scene Smoke Playtest terintegrasi di Godot SceneTree: ALL PASS, 0 ERRORS.
    - Full regression across all 9 suites: 134 unit/integration tests PASSED + 1 Scene Smoke Playtest suite (100% PASS).
    - Seluruh 16 kriteria gerbang keluar (*Phase 3 Exit Gate*) terpenuhi.
    - Phase 3 resmi DITUTUP (*CLOSED*).

## Phase 4 — Hero System
- **Status**: COMPLETED / CLOSED
- **Tujuan**: Struktur dan sistem hero/karakter mendalam (talent tree, active/passive skills, recruitment/tavern, ascension). Spesifikasi teknis: [docs/design/PHASE_4_HERO_SYSTEM_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_4_HERO_SYSTEM_PLAN.md).
  - **Phase 4A — Hero Domain & Lifecycle Foundation**: COMPLETED / VERIFIED
  - **Phase 4B — Hero Progression & EXP**: COMPLETED / VERIFIED
  - **Phase 4C — Hero Recruitment & Roster Management**: COMPLETED / VERIFIED / CLOSED
  - **Phase 4D — Hero Training / Fatigue / Morale**: COMPLETED / VERIFIED
  - **Phase 4E — Hero Skills & Talent Foundation**: COMPLETED / VERIFIED
  - **Phase 4F — Hero Chemistry & Party Management**: COMPLETED / VERIFIED / CLOSED
  - **Phase 4G — Hero Management UX**: COMPLETED / VERIFIED
  - **Phase 4H — Hero System Integration & Verification**: COMPLETED / VERIFIED / CLOSED

## Phase 5 — Fortress & Management Systems
- **Status**: COMPLETED / CLOSED
- **Tujuan**: Membangun fondasi sistem manajemen benteng inti sebelum pertempuran Phase 6. Spesifikasi teknis: [docs/design/PHASE_5_FORTRESS_MANAGEMENT_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_5_FORTRESS_MANAGEMENT_PLAN.md).
  - Pengarsipan dan indeks wireframe low-fi layar utama benteng (`docs/design/wireframes/fortress-main-screen/`).
  - Pertahanan benteng: integritas struktural, Tembok Pertahanan (Wall HP), dan Gerbang Utama (Gate HP).
  - Manajemen populasi zero-sum: konservasi mutlak $\text{Total} = \text{Civilians} + \text{Workers} + \text{Soldiers}$.
  - Model tenaga kerja `WorkerModel`: alokasi 4 tugas kanonikal (`IDLE`, `BLACKSMITH`, `REPAIR`, `CONSTRUCTION`), pelestarian invarian, moral, dan derivasi produktivitas ($0.50$ s/d $1.25$).
  - Fasilitas & gedung `BuildingModel`: 9 fasilitas kanonikal (`FORTRESS`, `WALL`, `GATE`, `BARRACKS`, `BLACKSMITH`, `WAREHOUSE`, `TRAINING_FACILITY`, `MERCENARY_GUILD`, `CONSTRUCTION_AREA`), level $1–5$.
  - Sistem reparasi struktur atomik: pemotongan emas kas ($0.15 \text{ Gold/HP}$) dan pemulihan HP struktur seketika dengan rollback.
  - Sistem konstruksi gedung: proyek pembangunan bertahap dengan pekerja konstruksi, auto-upgrade saat rampung, dan refund 100% saat dibatalkan.
  - Prototipe antarmuka manajemen berbasis tata letak wireframe pada `PrototypeDebugView` dengan tombol `Start Battle` dinonaktifkan (milik Phase 6).
  - Integrasi serialisasi telemetri `GameStateSnapshot` dan isolasi memori kloning mendalam.
  - Verifikasi: 82/82 tests PASS (inklusif 100-cycle management stress test), 677/677 Full Regression PASS across 17 suites, Scene Smoke Playtest ALL PASS.

## Phase 6 — Tactical Battle & Battlefield Systems
- **Status**: IN PROGRESS
- **Tujuan**: Membangun sistem simulasi pertempuran taktis real-time yang dapat diamati dan diarahkan (Football Manager style) berbasis 7 zona medan perang, 6 perintah taktis komandan, dan integrasi penuh integritas benteng, pahlawan Party 1, serdadu agregat, perlengkapan gudang bersama, dan 6 arketipe musuh deterministik. Spesifikasi teknis: [plans/PHASE_6_TACTICAL_BATTLE_PLAN.md](file:///d:/fortress_game/plans/PHASE_6_TACTICAL_BATTLE_PLAN.md).
  - **Phase 6A — Battlefield Zones & Enemy Foundation**: COMPLETED / VERIFIED (Commit `bd75c12`, 30 tests PASS).
  - **Phase 6B — Simulation Tick Loop & Pacing Controls**: COMPLETED / VERIFIED (33 tests PASS, 10.000-tick stress PASS).
  - **Phase 6C — Unit Formations, Party 1 & Aura Mechanics**: COMPLETED / VERIFIED (37 tests PASS, 50-wave participation stress PASS).
  - **Phase 6D — Commander Commands Execution**: COMPLETED / VERIFIED (50 tests PASS, 1.000-command stress test PASS).
  - **Phase 6E — Fortress Damage Routing & Casualty Resolution**: COMPLETED / VERIFIED (75 tests PASS, 1.000-tick tactical stress PASS).
  - **Phase 6F — Tactical Battle UI & Verification Gate**: NEXT / LOCKED
  - Topologi medan perang 7 zona kanonikal (`OUTER_FIELD`, `LEFT_FLANK`, `CENTER_APPROACH`, `RIGHT_FLANK`, `WALL`, `GATE`, `FORTRESS`).
  - Loop simulasi real-time berbasis tick deterministik dengan kontrol tempo (Pause, 1x, 2x, 4x) ringan tanpa physics engine.
  - Penempatan serdadu agregat (bukan unit individual) dan integrasi Party 1 pahlawan aktif.
  - Implementasi operasional 6 perintah komandan (`HOLD`, `ADVANCE`, `RETREAT`, `PROTECT`, `FOCUS`, `FOLLOW`) pada tingkat regu/zona.
  - Perutean kerusakan bertingkat ke Gate HP, Wall HP, dan Fortress HP dengan kondisi kekalahan saat Fortress HP $\le 0$.
  - Penegakan aturan korban serdadu & perlengkapan Phase 3D ($35\%$ hancur, $65\%$ rusak) dan kembalinya gear pahlawan permadeath tepat 1x ke gudang bersama.
  - UI taktis fungsional pada `PrototypeDebugView` berbasis wireframe Phase 5.
  - Pengujian: minimal 85 tests dan simulasi stres deterministik 50–100 gelombang.

## Phase 7 — Economy & Progression
- **Status**: NOT STARTED
- **Tujuan**: Mata uang, resource loop, upgrade progression, dan reward loop.

## Phase 8 — Content Implementation
- **Status**: NOT STARTED
- **Tujuan**: Penambahan variasi konten musuh, hero, tower, stage/level, dan data tables.

## Phase 9 — Visual / UI / Pixel Art Integration
- **Status**: NOT STARTED
- **Tujuan**: Integrasi aset visual final, UI polish, animasi, vfx, dan sfx.

## Phase 10 — Save/Load, Mobile Optimization & Polish
- **Status**: NOT STARTED
- **Tujuan**: Sistem penyimpanan data, optimasi performa mobile Android, pengujian build, dan final polishing.
