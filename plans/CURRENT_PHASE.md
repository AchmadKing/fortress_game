# Current Development Phase

## Phase 1 — Core Game Architecture

Project saat ini berada pada tahap **Phase 1: Core Game Architecture (Architecture Discovery & Design)**.

---

### Riwayat Fase Sebelumnya

- **Phase 0 — Workspace & Development Environment Setup**: **COMPLETED**
  - Seluruh audit fondasi workspace telah berhasil diverifikasi (struktur direktori, integrasi Git, konfigurasi `project.godot`, dokumen perencanaan `plans/`, aturan `AGENTS.md`, dan konfirmasi nol implementasi gameplay).

---

### Status Komponen Phase 1 (Architecture Discovery)

| Komponen | Status | Keterangan |
| :--- | :--- | :--- |
| **Architecture Goals & Constraints** | PROPOSED | Target mobile Android, clean boundaries, lightweight |
| **System Boundaries & Responsibilities** | PROPOSED | Pemisahan Presentation, Logic, Simulation, Data, Persistence |
| **Data Flow & Dependency Rules** | PROPOSED | Unidirectional flow, UI depends on Domain (Domain bebas UI) |
| **Core Game State Lifecycle** | PROPOSED | Boot, Menu, Gameplay Loop, Pause, Stage End |
| **Communication Paradigm** | UNDER REVIEW | Evaluasi Autoload vs Injection, Event Bus vs Local Signals |
| **Data Architecture Model** | UNDER REVIEW | Evaluasi Custom Resources (`.tres`) vs Pure GDScript Classes |
| **Simulation Loop Pattern** | UNDER REVIEW | Evaluasi Tick-based vs Engine frame-based |
| **Gameplay Implementation** | NOT STARTED | Belum ada script gameplay, scene, atau aset |

---

### Rules & Constraints

> **CRITICAL RULE**:
> **No gameplay implementation (scripts, scenes, mechanics, combat, entities) is allowed until Phase 1 Architecture Design is reviewed and explicitly approved by the developer.**

- Fase ini hanya mencakup **Architecture Discovery & Technical Design**.
- Seluruh keputusan teknis berstatus `PROPOSED` dan membutuhkan approval sebelum dianggap `FINAL`.
