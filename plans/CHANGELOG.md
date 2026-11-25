# Changelog — Fortress Game

Semua perubahan pada proyek dicatat dalam dokumen ini. Format mengacu pada prinsip Keep a Changelog.

---

## [Unreleased] - Phase 1: Core Game Architecture

### Added
- Dokumen rancangan arsitektur inti awal ([docs/architecture/CORE_ARCHITECTURE.md](docs/architecture/CORE_ARCHITECTURE.md)) yang mencakup tujuan arsitektur, batasan sistem, pemisahan layer (Presentation, Logic, Simulation, Data, Persistence), aliran data unidirectional, lifecycle aplikasi, mitigasi performa mobile, serta opsi keputusan teknis yang berstatus `PROPOSED`.
- Inisiasi **Phase 1 — Core Game Architecture** (fokus terbatas pada Architecture Discovery & Design).

### Changed
- Pembaruan [plans/ROADMAP.md](plans/ROADMAP.md): Phase 0 ditandai `COMPLETED`; Phase 1 dialihkan menjadi tujuan arsitektur tingkat tinggi tanpa mengunci implementasi spesifik (Autoload/Event Bus/Singleton).
- Pembaruan [plans/CURRENT_PHASE.md](plans/CURRENT_PHASE.md): Phase 0 resmi ditandai `COMPLETED` setelah verifikasi audit; Phase 1 aktif sebagai `IN PROGRESS` (Discovery & Design Only).

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
