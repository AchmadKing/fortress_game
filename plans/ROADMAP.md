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
- **Status**: IN PROGRESS (PHASE 3A COMPLETED / ITERATIONS 3B–3E PLANNED)
- **Tujuan**: Prototipe interaksi gameplay minimum yang dapat dimainkan (*playable prototype*) di Godot Editor berbasis arsitektur Phase 1 dan sistem matematika Phase 2.
  - **Phase 3A — Baseline & Stabilization**: **COMPLETED** (Commit `2452397`)
    - Gameplay State Machine terintegrasi (`BOOT` s/d `GAME_OVER`).
    - Kontrol persiapan (alokasi pekerja 4 tugas sah, rekrutmen serdadu zero-sum).
    - Kontrol tempo battle (pause, resume, speed 1x/2x/4x) dan pengiriman 6 commander commands intent.
    - Scene prototype playable (`scenes/prototype/main_prototype.tscn`) & debug HUD.
    - Seluruh pengujian regression Phase 1 (5/5), Phase 2 (21/21), Phase 3 (11/11), dan Playtest Smoke 100% PASS.
  - **Phase 3B — Soldier Deployment & Temporary Equipment Management**: **PLANNED**
    - Alokasi perlengkapan sementara berbasis gelombang (*temporary wave deployment*), bukan kepemilikan permanen.
    - Konfigurasi regu agregat: Soldier Count, Primary Weapon (Wajib), Secondary Weapon (Opsional), Armor (Opsional).
    - Seleksi perlengkapan sadar stok (*stock-aware selection*) dan reservasi seketika (*immediate reservation*).
    - Derivasi peran prajurit dinamis per gelombang (Sword $\rightarrow$ Swordsman, Sword+Shield $\rightarrow$ Shield Infantry, dll.).
    - Kembalinya gear selamat ke gudang pasca-wave (aus normal & 65% gear korban rusak kembali; 35% gear korban hancur permanen per Phase 2).
    - Prajurit selamat kembali ke kolam prajurit benteng; prajurit gugur terpotong permanen.
    - Penegakan ketat invariant konservasi: $\text{Total Owned} = \text{Warehouse} + \text{Reserved Deployment}$.
  - **Phase 3C — Hero Equipment Foundation**: **PLANNED**
    - Slot perlengkapan minimal Hero (Weapon, Armor).
    - Integrasi equip/unequip/swap hero dengan gudang benteng.
    - Pengembalian perlengkapan hero ke gudang secara otomatis saat permadeath.
  - **Phase 3D — Prototype UX & Interaction Polish**: **PLANNED**
    - Kontrol UI untuk pasang/tukar gear prajurit & hero serta dismiss prajurit.
    - Eliminasi gameplay dead-ends dan transparansi telemetri inventaris.
  - **Phase 3E — Final Prototype Verification & Phase 3 Exit Gate**: **PLANNED**
    - Automated tests untuk konservasi gear dan derivasi peran.
    - Stres playtest 20 wave berturut-turut pada hardware berspesifikasi rendah.
    - Verifikasi gerbang keluar sebelum pembukaan Phase 4.

## Phase 4 — Hero System
- **Status**: LOCKED (AWAITING PHASE 3 COMPLETION)
- **Tujuan**: Struktur dan sistem hero/karakter mendalam (talent tree, active/passive skills, recruitment/tavern, ascension).

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
