# Current Development Phase

## Phase 2 — Mathematical / Systems Prototype

Project saat ini berada pada tahap **Phase 2: Mathematical / Systems Prototype (COMPLETED — AWAITING DEVELOPER REVIEW)**.

---

### Riwayat Status Fase

- **Phase 0 — Workspace & Development Environment Setup**: **COMPLETED**
- **Phase 1 — Core Game Architecture**: **COMPLETED / APPROVED** (Commit `4b7436e`)
- **Phase 2 — Mathematical / Systems Prototype**: **COMPLETED — AWAITING DEVELOPER REVIEW**
  - Mathematical Design Document: **AUDITED & REFINED** ([docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md](docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md))
  - Mathematical Domain Models: **IMPLEMENTED** (Population, Hero, Equipment, Fortress)
  - Headless Simulation Modules: **IMPLEMENTED** (Economy, Wave Generator, 5-Phase Combat Engine, Headless Simulator)
  - Automated Test Suite: **18/18 PASSED, 0 FAILED** ([tests/test_mathematical_prototype.gd](tests/test_mathematical_prototype.gd))
  - Phase 1 Regression Check: **5/5 PASSED, 0 FAILED** ([tests/test_architecture_boundaries.gd](tests/test_architecture_boundaries.gd))
  - 100-Wave Deterministic Simulation: **100/100 WAVES COMPLETED WITHOUT GAME OVER**
- **Phase 3 — Gameplay Prototype**: **NOT STARTED / LOCKED**

---

### Hasil Verifikasi Komponen Phase 2

| Komponen Sistem | Status | Hasil Pengujian & Validasi |
| :--- | :--- | :--- |
| **Population & Manpower Model** | COMPLETED | Konversi sipil -> prajurit, kematian permanen terbukti, tentara bayaran terisolasi dari kuota warga |
| **Worker Economy Model** | COMPLETED | Alokasi kerja (Blacksmith, Repair, Construction, Production), pemeliharaan gaji, reparasi proporsional |
| **Soldier Role Differentiation** | COMPLETED | Peran ditentukan oleh equipment (Swordsman, Shield, Spear, Archer, Heavy), combat multi-faktor |
| **Hero Progression & Permadeath** | COMPLETED | Kurva EXP $120 \times L^{1.55}$, Fatigue $0 \sim 100$, rest recovery, Chemistry antar-hero, permadeath saat kalah total |
| **Equipment & Durability** | COMPLETED | Degradasi durabilitas per battle, penalti rusak $10\%$, biaya perbaikan proporsional tier |
| **Fortress Durability & Failure** | COMPLETED | HP persisten, reduksi damage oleh armor tembok, Game Over saat $HP \le 0$ |
| **Wave Threat Budget** | COMPLETED | Wave 1–5 linear tutorial ramp (25-85), Wave 6–100 power curve deterministik dengan kontrol variasi $\pm 6\%$ |
| **Multi-Phase Combat Engine** | COMPLETED | 5-Fase deterministik (Ranged, Clash, Melee/Heroes, Breach, Resolution), bukan Battle Power tunggal |
| **8 Scenario Stress Tests** | COMPLETED | Skenario A s/d H lulus verifikasi headless (Healthy, Average, Poor, Casualty, Breach, Merc, Fatigue, Gear) |
| **100-Wave Simulation Stability** | COMPLETED | 100 wave berjalan mulus tanpa crash, kas seimbang, tidak ada infinite money maupun death spiral |
| **Gameplay Code / Assets / UI** | NOT STARTED | Nol implementasi gameplay visual, combat scene, maupun spawner visual |

---

### Rules & Constraints

> **CRITICAL RULE**:
> **No gameplay prototype, visual scenes, combat UI, or sprite assets are allowed until Phase 2 Mathematical Prototype is explicitly reviewed and approved by the developer.**
> Phase 3 remains locked.
