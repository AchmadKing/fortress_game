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
- **Status**: NOT STARTED / LOCKED
- **Tujuan**: Prototipe interaksi gameplay minimum yang dapat dimainkan.

## Phase 4 — Hero System
- **Status**: NOT STARTED
- **Tujuan**: Struktur dan sistem hero/karakter.

## Phase 5 — Fortress & Management Systems
- **Status**: NOT STARTED
- **Tujuan**: Sistem pertahanan benteng, modul/fasilitas benteng, dan manajemen pendukung.

## Phase 6 — Combat & Wave Systems
- **Status**: NOT STARTED
- **Tujuan**: Sistem pertempuran, kalkulasi damage, dan generator gelombang musuh (waves).

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
