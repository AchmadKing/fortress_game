# Fortress Game

Sebuah game bergenre **Pixel-Art Fantasy Fortress Management / Strategy Simulation** yang dirancang untuk platform mobile Android dengan prinsip arsitektur yang bersih, modular, dan performan.

---

## 📌 Ringkasan Proyek

- **Nama Proyek**: Fortress Game (`fortress_game`)
- **Genre**: Pixel-Art Fantasy Fortress Management / Strategy Simulation
- **Engine**: Godot Engine (Godot 4)
- **Target Platform**: Mobile Android (*PC digunakan sebagai development/testing environment*)
- **Development Environment**: VS Code, Antigravity AI, Godot Editor, Git + GitHub
- **Repository**: [https://github.com/AchmadKing/fortress_game.git](https://github.com/AchmadKing/fortress_game.git)

---

## ⚙️ Development Principle

> **"Setup first. Development later."**

Tujuan tahap ini adalah membuat proyek mudah dikembangkan, mudah dipahami AI, mudah dipelihara, dan memiliki urutan pekerjaan yang terstruktur secara jelas.

---

## 🚦 Status Pengembangan

- **Fase Selesai**:
  - `Phase 0 — Workspace & Development Environment Setup`: **COMPLETED**
  - `Phase 1 — Core Game Architecture`: **COMPLETED / APPROVED**
  - `Phase 2 — Mathematical / Systems Prototype`: **COMPLETED**
  - `Phase 3 — Gameplay Prototype`: **COMPLETED**
  - `Phase 4 — Hero System`: **COMPLETED / CLOSED**
  - `Phase 5 — Fortress & Management Systems`: **COMPLETED / CLOSED**
  - `Phase 6 — Tactical Battle & Battlefield Systems`: **COMPLETED / CLOSED**
    - 7 zona kanonikal medan laga (`OUTER_FIELD` s/d `FORTRESS`).
    - Simulasi battle deterministik berbasis tick clock & kontrol tempo (Pause, Speed 1x/2x/4x, Step Tick, Instant Resolve).
    - Formasi taktis (`BALANCED`, `DEFENSIVE`, `AGGRESSIVE`), partisipasi eksklusif Party 1, dan mekanika aura kepemimpinan & chemistry.
    - Eksekusi 7 perintah komandan (`ADVANCE`, `MOVE`, `HOLD_POSITION`, `RETREAT`, `PROTECT`, `FOCUS_TARGET`, `FOLLOW`).
    - *Damage routing* struktural (Tembok $\rightarrow$ Gerbang $\rightarrow$ Benteng Utama) dan resolusi korban serdadu & pahlawan (*permadeath*).
    - Tactical Battle UI terintegrasi (`PrototypeDebugView`) dengan validasi interaktif dan telemetri real-time.
- **Fase Aktif (In Progress)**:
  - `Phase 7 — Economy & Progression`: **IN PROGRESS**
    - `Sub-Phase 7A — Resource Authority & Economy Domain Model`: **COMPLETED / VERIFIED** (27/27 tests PASS).
      - Single Source of Truth otoritas sumber daya benteng (`ResourceLedger`).
      - 5 Sumber Daya Kanonikal: Gold (kas awal 150), Monster Core, Monster Material, Basic Material, Rare Material.
      - Transaksi atomik multi-resource dengan *strict rollback* saat saldo tidak mencukupi.
      - Penegakan kunci transaksi saat `GAME_OVER` (*freeze* mutlak).
      - Sinkronisasi nol desinkronisasi antara `GameCoordinator`, `EconomyManager`, dan `GameStateSnapshot`.
    - `Sub-Phase 7B — Battle Reward Settlement & Loot Engine`: **COMPLETED / VERIFIED** (35/35 tests PASS).
      - Kontrak `BattleResult` deterministik (Gold kanonikal $\text{floor}(B \times 1.30)$, Monster Core provisi, Monster Material provisi).
      - Settlement atomik multi-resource ke `ResourceLedger` benteng saat status Victory.
      - Isolasi mutlak 0 jarahan saat Defeat dan pembekuan transaksi saat Game Over.
      - Proteksi eksekusi berulang (*duplicate settlement protection*) via tracking ID settlement unik.
      - Sinkronisasi telemetri HUD dan dialog hasil pertempuran pada `PrototypeDebugView`.
    - `Sub-Phase 7C — Expense Normalization & Dynamic Sinks`: **NEXT / LOCKED (PENDING APPROVAL)**
    - `Sub-Phase 7D — Merchant & Supply Depot System`: **PLANNED / LOCKED**
    - `Sub-Phase 7E — Fortress & Hero Progression Economy`: **PLANNED / LOCKED**
    - `Sub-Phase 7F — Economy & Merchant UX Integration`: **PLANNED / LOCKED**
    - `Sub-Phase 7G — Full Economy Verification & Phase 7 Exit Gate`: **PLANNED / LOCKED**
- **Fase Berikutnya (Locked)**:
  - `Phase 8 — Content Implementation`: **LOCKED**
  - `Phase 9 — Visual / UI / Pixel Art Integration`: **LOCKED**
  - `Phase 10 — Save/Load, Mobile Optimization & Polish`: **LOCKED**

> [!NOTE]
> **Catatan Visual Pertempuran (Phase 6/7 vs Phase 9):**
> Implementasi Phase 6 dan Phase 7 fokus pada simulasi logika taktis, otoritas perbendaharaan, pacing, dan visualisasi debug telemetry (`PrototypeDebugView`). Lapisan visual akhir (pixel-art sprite, animasi unit berjalan/menyerang, proyektil panah/sihir, particle VFX, dan audio) dirancang secara terpisah pada **Phase 9** dan akan diintegrasikan di atas fondasi simulasi ini tanpa merusak atau mengubah logika pertempuran kanonikal.

Rincian perencanaan dan aturan proyek dapat dilihat pada:
- [Roadmap Pengembangan](plans/ROADMAP.md)
- [Status Fase Aktif](plans/CURRENT_PHASE.md)
- [Rencana Arsitektur Phase 7 (Ekonomi & Progresi)](plans/PHASE_7_ECONOMY_PROGRESSION_PLAN.md)
- [Rencana Arsitektur Phase 6 (Tactical Battle)](plans/PHASE_6_TACTICAL_BATTLE_PLAN.md)
- [Aturan Kerja Pengembangan (AGENTS.md)](AGENTS.md)
- [Changelog Proyek](plans/CHANGELOG.md)

---

## 🚀 Rencana Fitur Utama (High-Level Future Concept)
- Sistem pertahanan benteng
- Manajemen sumber daya & fasilitas
- Mekanik strategi pertahanan gelombang musuh (*wave strategy*)

---

## 🛠️ Instalasi & Menjalankan
1. Clone repository:
   ```bash
   git clone https://github.com/AchmadKing/fortress_game.git
   ```
2. Buka folder proyek di **Godot Engine 4.x**.
3. Buka proyek di editor atau VS Code untuk development.
