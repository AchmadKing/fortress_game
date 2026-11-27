# Current Development Phase

## Phase 4 — Hero System (IN PROGRESS / SUB-PHASE 4A IMPLEMENTED)

Project saat ini berada pada tahap **Phase 4 — Hero System (Sub-Phase 4A: IMPLEMENTED / COMPLETED; Sub-Phase 4B: PLANNED)**.
Phase 3 (Gameplay Prototype) telah resmi ditutup (**COMPLETED / CLOSED**) pada commit `e6c0c97`.

Roadmap teknis dan spesifikasi arsitektur komprehensif Phase 4 tersedia di [docs/design/PHASE_4_HERO_SYSTEM_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_4_HERO_SYSTEM_PLAN.md).

---

### Riwayat Status Fase

- **Phase 0 — Workspace & Development Environment Setup**: **COMPLETED**
- **Phase 1 — Core Game Architecture**: **COMPLETED / APPROVED** (Commit `4b7436e`)
- **Phase 2 — Mathematical / Systems Prototype**: **COMPLETED** (Commit `dd74512`)
- **Phase 3 — Gameplay Prototype**: **COMPLETED** (Commits `2452397`, `4f01bfe`, `1d3d51d`, `463f91c`, `ba3c0c5`, `e6c0c97`)
- **Phase 4 — Hero System**: **IN PROGRESS**
  - Dokumen Roadmap & Spesifikasi Arsitektur: **ESTABLISHED** ([docs/design/PHASE_4_HERO_SYSTEM_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_4_HERO_SYSTEM_PLAN.md))
  - **Sub-Phase 4A — Hero Domain & Lifecycle Foundation**: **IMPLEMENTED / VERIFIED (CORRECTION GATE PASSED)**
    - Peran Kanonikal Domain: `KNIGHT`, `MAGE`, `ARCHER`, `PRIEST` via `HeroRole` (`scripts/domain/model/hero_role.gd`).
    - Matriks Kompatibilitas Perlengkapan Kanonikal: Knight (`SWORD`, `SHIELD`, `HEAVY_ARMOR`), Archer (`BOW`, `LIGHT_ARMOR`, no `HEAVY_ARMOR`), Mage & Priest (future gear only; seluruh Phase 3 gear non-kompatibel).
    - State Siklus Hidup Pahlawan: `RECRUITABLE`, `ROSTER_ACTIVE`, `IN_PARTY`, `IN_TRAINING`, `BATTLE_ACTIVE`, `PERMADEATH` via `HeroLifecycleState` (`scripts/domain/model/hero_lifecycle_state.gd`).
    - Validasi transisi legal dan penegakan `PERMADEATH` sebagai state terminal mutlak.
    - Eliminasi silent normalization pada `HeroModel._init()`: input bintang, peran, dan state invalid tidak di-clamp diam-diam melainkan tertangkap oleh `validate_invariants()`.
    - Test Suite Phase 4A: **38/38 PASSED, 0 FAILED** ([tests/test_phase4a_hero_domain_lifecycle.gd](file:///d:/fortress_game/tests/test_phase4a_hero_domain_lifecycle.gd)).
    - Full Regression: **172 tests PASSED (134 baseline Phase 1-3 + 38 Phase 4A)** + Scene Smoke Playtest ALL PASS.
  - Sub-Phase 4B — Hero Progression & EXP: **PLANNED** (Locked until review)
  - Sub-Phase 4C — Hero Recruitment & Roster Management: **PLANNED**
  - Sub-Phase 4D — Hero Training / Fatigue / Morale: **PLANNED**
  - Sub-Phase 4E — Hero Skills & Talent Foundation: **PLANNED**
  - Sub-Phase 4F — Hero Chemistry & Party Management: **PLANNED**
  - Sub-Phase 4G — Hero Management UX: **PLANNED**
  - Sub-Phase 4H — Hero System Integration & Verification: **PLANNED**
- **Phase 5 — Fortress & Management Systems**: **LOCKED**
- **Phase 6 — Tactical Battle & Battlefield Systems**: **LOCKED**

---

### Aturan & Batasan Saat Ini

> [!IMPORTANT]
> **PHASE 3 TELAH RESMI DITUTUP (OFFICIALLY CLOSED).**
> **PHASE 4 TELAH DIBUKA (AUTHORIZED TO START)**: Pengembangan Phase 4 wajib mematuhi rencana kerja terstruktur (Sub-Phases 4A–4H), prinsip *Extend, Don't Break*, dan tidak boleh merusak baseline 134 pengujian Phase 1–3 yang telah lulus.
> **PHASE 5 & 6 TETAP LOCKED**: DILARANG memulai implementasi sistem pertarungan taktis mendalam, battlefield physics, maupun konstruksi modul benteng.

---

### Verifikasi Gerbang Keluar Phase 3 (Phase 3 Exit Gate Checklist)

- [x] Seluruh existing regression tests PASS (Phase 1: 5/5, Phase 2: 21/21, Phase 3A: 11/11, Phase 3B: 27/27, Phase 3C: 22/22, Phase 3D: 10/10, Follow-up: 23/23)
- [x] Seluruh Phase 3E verification tests PASS (15/15 PASS)
- [x] 20-wave stress verification PASS (100% stabilitas tanpa crash / memory leak)
- [x] Tidak ada critical crash
- [x] Tidak ada duplikasi equipment
- [x] Tidak ada kehilangan equipment yang tidak sah (non-casualty)
- [x] Tidak ada nilai resource atau prajurit negatif
- [x] Tidak ada bug kalkulasi jumlah serdadu
- [x] Tidak ada transisi state ilegal
- [x] Tidak ada eksekusi ganda pada result / recovery
- [x] Konservasi gudang bersama selalu valid di setiap aksi
- [x] Persistensi equipment Hero bekerja lintas gelombang
- [x] Aturan durabilitas serdadu & resolusi korban 35%/65% terverifikasi
- [x] Reparasi Pandai Besi bekerja presisi dan atomik
- [x] Scene Smoke Playtest PASS di Godot SceneTree
- [x] Dokumentasi status dan changelog diperbarui
- [x] Phase 4 tetap LOCKED

---

### Hasil Audit Komponen Teknis Phase 3 Final

| Komponen Sistem | Status | Evaluasi & Status Akhir |
| :--- | :---: | :--- |
| **Gameplay State Machine** | COMPLETED | Rantai siklus `BOOT -> PREP -> PREVIEW -> BATTLE -> RESULT -> RECOVERY -> PREP` dan terminal `GAME_OVER` 100% stabil. Menolak transisi ilegal. |
| **Worker Economy** | COMPLETED | 4 pekerjaan sah (Repair, Smith, Constr, Idle). Bebas passive income dan production worker. Pendapatan murni dari Battle Loot. |
| **Soldier Deployment** | COMPLETED | Alokasi sementara per gelombang, derivasi peran deterministik, pemisahan dari kolam prajurit benteng, reservasi atomik. |
| **Equipment & Warehouse** | COMPLETED | Segregasi usable vs damaged, formula durabilitas prajurit selamat (100%), resolusi korban (35% hancur, 65% rusak), konservasi fisik 100%. |
| **Blacksmith Repair** | COMPLETED | Reparasi item rusak menjadi 100% durabilitas menggunakan Gold dengan diskon alokasi pekerja Pandai Besi. Atomik dan bebas duplikasi. |
| **Hero Foundation** | COMPLETED | Stat, level, fatigue, chemistry, slot perlengkapan persistent lintas gelombang, dan pengembalian gear permadeath tepat 1 kali. |
| **Commander Commands** | COMPLETED | 6 intent command DTO diterima dan dicatat ke telemetri (`LOGGED_PHASE3_DEFERRED`). Efek taktis mendalam ke Phase 6. |
| **Wave Preview & Battle** | COMPLETED | Threat budget & enemy counts via `WaveGenerator`. Pertempuran multi-fase via `CombatEngine` dengan tempo 1x/2x/4x/Pause. |
| **Result & Recovery** | COMPLETED | Pasca-tempur atomik tanpa eksekusi ganda. Kembalinya prajurit selamat dan gear sementara ke gudang benteng. |
| **Automated Test Suites** | COMPLETED | 134 pengujian unit/sistem + 1 Scene Smoke Playtest suite lulus 100% tanpa kegagalan (100% PASS). |
