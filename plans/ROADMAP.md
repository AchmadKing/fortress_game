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
- **Status**: AUTHORIZED / PLANNING (SUB-PHASES 4A–4H ESTABLISHED)
- **Tujuan**: Struktur dan sistem hero/karakter mendalam (talent tree, active/passive skills, recruitment/tavern, ascension). Spesifikasi teknis: [docs/design/PHASE_4_HERO_SYSTEM_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_4_HERO_SYSTEM_PLAN.md).
  - **Phase 4A — Hero Domain & Lifecycle Foundation**: PLANNED
  - **Phase 4B — Hero Progression & EXP**: PLANNED
  - **Phase 4C — Hero Recruitment & Roster Management**: PLANNED
  - **Phase 4D — Hero Training / Fatigue / Morale**: PLANNED
  - **Phase 4E — Hero Skills & Talent Foundation**: PLANNED
  - **Phase 4F — Hero Chemistry & Party Management**: PLANNED
  - **Phase 4G — Hero Management UX**: PLANNED
  - **Phase 4H — Hero System Integration & Verification**: PLANNED

## Phase 5 — Fortress & Management Systems
- **Status**: LOCKED
- **Tujuan**: Sistem pertahanan benteng, modul/fasilitas benteng, dan manajemen pendukung.

## Phase 6 — Tactical Battle & Battlefield Systems
- **Status**: LOCKED
- **Tujuan**: Sistem pertarungan taktis mendalam, efek numerik 6 perintah komandan, visual battlefield, pathfinding serdadu & AI musuh.

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
