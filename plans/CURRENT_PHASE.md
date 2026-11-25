# Current Development Phase

## Phase 2 — Mathematical / Systems Prototype

Project saat ini berada pada tahap **Phase 2: Mathematical / Systems Prototype (PLANNING ONLY)**.

---

### Riwayat Status Fase

- **Phase 0 — Workspace & Development Environment Setup**: **COMPLETED**
- **Phase 1 — Core Game Architecture**: **COMPLETED / APPROVED**
  - Architecture Skeleton: COMPLETED
  - Boundary Verification: 5/5 PASSED (test suite headless)
  - Gameplay Implementation: NOT STARTED
  - Developer Approval: APPROVED (Commit `4b7436e`)
- **Phase 2 — Mathematical / Systems Prototype**: **IN PROGRESS — PLANNING ONLY**
  - Mathematical & Systems Design Document: IN PROGRESS ([docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md](docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md))
  - Gameplay Development: NOT STARTED

---

### Status Komponen Phase 2

| Komponen Sistem | Status | Keterangan |
| :--- | :--- | :--- |
| **Population & Manpower Model** | PLANNING | Total Pop, Civilians, Soldiers, Heroes, Casualties |
| **Worker Economy Model** | PLANNING | Salary, Productivity, Maintenance, Morale |
| **Soldier System (Aggregate)** | PLANNING | Army Power, Salary, Morale, Equipment Factor |
| **Hero Progression Formula** | PLANNING | EXP curves, Star rank, Stat scaling, Fatigue |
| **Equipment & Repair Model** | PLANNING | Tiers, Durability, Repair cost, Degradation |
| **Fortress Durability & Repair** | PLANNING | Max HP, Incoming Damage, Worker Repair Rate, Fail Condition |
| **Wave Threat Budget** | PLANNING | Budget scaling, Unit costs, Trait modifiers, Randomness control |
| **Combat Abstraction Model** | PLANNING | Deterministic simulation formula (Input -> Sim -> Output) |
| **100-Wave Economic Validation** | PLANNING | Income vs Expense balance, Loop stability |
| **Gameplay Code / Assets** | NOT STARTED | Belum ada kode gameplay, combat, atau visual |

---

### Rules & Constraints

> **CRITICAL RULE**:
> **No gameplay implementation (combat code, wave spawner, hero mechanics, economy scripts, UI, scenes) is allowed during Phase 2 Planning.**
> Tahap ini murni perancangan formula matematika dan model sistem abstrak untuk memvalidasi kestabilan loop permainan sebelum visual dibuat.
