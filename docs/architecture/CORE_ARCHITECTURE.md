# Core Game Architecture — Fortress Game

**Status**: ARCHITECTURE SKELETON IMPLEMENTED (AWAITING DEVELOPER REVIEW)  
**Target Platform**: Mobile (Android) — Lightweight, Battery-Friendly  
**Development Environment**: PC (Windows / Godot Engine 4.x / VS Code / Antigravity AI)

> [!IMPORTANT]
> Arsitektur skeleton minimal telah diimplementasikan untuk membuktikan batas (*boundaries*) teknis antar-layer. **Belum ada implementasi gameplay, combat, wave, hero, maupun UI**. Keputusan implementasi tetap dijaga seringan dan se-modular mungkin agar dapat disesuaikan pada fase prototipe berikutnya.

---

## 1. Architecture Goals

Arsitektur inti game dirancang untuk memenuhi sasaran berikut:

1. **Lightweight & High Performance**: Meminimalkan beban CPU, alokasi memori dinamis (GC overhead), dan konsumsi baterai pada perangkat mobile Android.
2. **Decoupled Architecture**: Memisahkan secara tegas antara logika game/simulasi dengan layer visual/presentasi (UI, sprite, particle, sound).
3. **Deterministic & Testable Simulation**: Logika simulasi (kalkulasi damage, wave, stat) dapat dijalankan dan diuji secara independen tanpa ketergantungan pada rendering frame atau scene tree.
4. **Data-Driven & Extensible**: Penambahan konten (hero, tower, monster, wave) dilakukan melalui konfigurasi data terstruktur tanpa perlu mengubah kode inti logika.
5. **No Premature Over-Engineering**: Menghindari kompleksitas framework berat (seperti ECS skala penuh atau dependency injection container rumit) yang tidak proporsional untuk proyek mobile 2D.

---

## 2. Actual Implemented Architecture Skeleton

Berdasarkan persetujuan bersyarat Phase 1, skeleton arsitektur minimal telah dibangun dengan struktur file berikut:

```text
scripts/
├── domain/
│   ├── state/
│   │   └── game_state_snapshot.gd     # Domain State murni (RefCounted, zero Node/SceneTree)
│   └── config/
│       └── game_config_resource.gd    # Data definition berbasis Godot Resource (.tres)
├── simulation/
│   └── simulation_runner.gd          # Boundary simulasi deterministik (tanpa _process)
├── application/
│   └── coordinators/
│       └── game_coordinator.gd       # Coordinator aliran data satu arah (unidirectional data flow)
└── infrastructure/
    └── persistence/
        └── save_snapshot_dto.gd       # DTO Save/Load dengan schema_version & plain data

tests/
└── test_architecture_boundaries.gd   # Test suite headless membuktikan isolasi kelima boundary
```

---

## 3. System Boundaries & Layer Responsibilities

```text
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION / UI                      │
│   (HUD, Screens, Dialogs, HealthBars, Floating Text, VFX)   │
└──────────────────────────────┬──────────────────────────────┘
                               │  (Observes State / Sends Commands)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 APPLICATION / COORDINATORS                  │
│       (GameCoordinator: orchestrates flow & signals)        │
└──────────────────────────────┬──────────────────────────────┘
                               │  (Executes Simulation / Mutates Data)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      SIMULATION LAYER                       │
│    (SimulationRunner: pure calculation, tick, headless)     │
└──────────────────────────────┬──────────────────────────────┘
                               │  (Operates On)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN DATA MODELS                     │
│    (GameStateSnapshot: pure RefCounted data container)      │
│    (GameConfigResource: static configuration Resource)      │
└──────────────────────────────┬──────────────────────────────┘
                               ▲
                               │  (Serializes / Deserializes)
┌──────────────────────────────┴──────────────────────────────┐
│                  PERSISTENCE & INFRASTRUCTURE               │
│         (SaveSnapshotDto: schema_version, plain DTO)        │
└─────────────────────────────────────────────────────────────┘
```

| Layer / File | Tanggung Jawab Nyata yang Diimplementasikan | Hal yang Dilarang & Dijaga |
| :--- | :--- | :--- |
| **Domain State** (`game_state_snapshot.gd`) | Menyimpan snapshot data game murni, menyediakan method `clone()`, `to_dictionary()`, dan `from_dictionary()`. | Dilarang mewarisi `Node`, memanggil SceneTree, melakukan I/O file, atau memuat resource visual. |
| **Domain Config** (`game_config_resource.gd`) | Menyediakan wadah parameter konfigurasi statis berbasis `Resource` untuk Inspector Godot. | Dilarang memuat logika simulasi atau manipulasi state runtime. |
| **Simulation** (`simulation_runner.gd`) | Melakukan perhitungan langkah (*step/tick*) deterministik secara murni dari snapshot A ke snapshot B. | Dilarang mengandalkan `_process()`, delta rendering frame, atau window visual. |
| **Application Coordinator** (`game_coordinator.gd`) | Mengorkestrasi aliran data satu arah: menerima perintah UI, memanggil simulasi, memancarkan signal `state_changed`. | Mengembalikan clone state ke pemanggil agar state internal tidak dimutasi sembarangan oleh UI. |
| **Persistence DTO** (`save_snapshot_dto.gd`) | Serialisasi/deserialisasi plain dictionary dengan validasi `schema_version`. | Dilarang melakukan serialisasi Node visual atau hierarki SceneTree. |

---

## 4. Unidirectional Data Flow

Pola aliran data yang diterapkan dan telah diverifikasi melalui pengujian:

1. **Presentation / UI** mengirimkan panggilan metode / perintah (misal: `coordinator.request_step(delta_tick)`).
2. **Coordinator** memvalidasi dan meneruskan state ke **SimulationRunner**.
3. **SimulationRunner** menghasilkan snapshot state baru secara deterministik tanpa efek samping ke rendering.
4. **Coordinator** memperbarui state internal dan memancarkan signal reaktif `state_changed(new_snapshot)`.
5. **Presentation / UI** merespons signal untuk memperbarui tampilan visualnya.

---

## 5. Keputusan Teknis yang Dipilih & Alasannya

1. **Pure `RefCounted` untuk Domain State**:
   - *Alasan*: Ringan, memori dikelola otomatis oleh Godot tanpa overhead node SceneTree, sangat cepat di mobile Android, dan memfasilitasi unit test headless.
2. **Deterministic Step Function untuk Simulasi**:
   - *Alasan*: Memisahkan logika perhitungan game dari refresh rate layar perangkat mobile (60Hz, 90Hz, 120Hz). Menghindari inkonsistensi formula matematis.
3. **Save/Load DTO dengan `schema_version` eksplisit**:
   - *Alasan*: Menjamin backward compatibility format penyimpanan saat ada update versi aplikasi di Android, serta mencegah ketergantungan rapuh pada node tree.
4. **Typed GDScript Konsisten**:
   - *Alasan*: Seluruh parameter dan return type didefinisikan secara statis. Menghindari runtime type error dan memberikan optimasi kecepatan eksekusi pada Godot 4.

---

## 6. Keputusan yang Masih Bersifat Reversible (Belum Dikunci)

1. **Autoload vs Scene Injection**:
   - Belum ada Autoload yang didaftarkan di `project.godot`. `GameCoordinator` saat ini berupa kelas modular yang dapat di-inject ke scene atau didaftarkan sebagai Autoload jika nanti terbukti diperlukan.
2. **Central Event Bus vs Local Signals**:
   - Saat ini menggunakan direct signals pada coordinator. Belum dibuat Event Bus global besar guna menghindari kompleksitas dini.
3. **Mekanisme Tick Simulasi (Fixed Physics vs Internal Accumulator)**:
   - Abstraksi `SimulationRunner.step()` saat ini independen dari loop engine. Keputusan apakah akan dikendalikan oleh `_physics_process` atau timer internal akan ditentukan saat prototipe Phase 2.

---

## 7. Bagian yang Sengaja Belum Diimplementasikan

Sesuai aturan `AGENTS.md` dan batasan ACC Bersyarat Phase 1, hal berikut **DILARANG dan SENGAJA BELUM DIIMPLEMENTASIKAN**:
- ❌ Logika combat, damage formula riil, dan battle state.
- ❌ Wave generator dan monster spawning.
- ❌ Hero, soldier, dan worker mechanics.
- ❌ Sistem ekonomi, currency, dan inventori.
- ❌ Scene gameplay, level map, dan battlefield.
- ❌ UI/HUD gameplay nyata.
- ❌ Pixel art, sprites, dan audio assets.

---

## 8. Verifikasi Pengujian

Suite pengujian headless pada `tests/test_architecture_boundaries.gd` telah dijalankan menggunakan executable resmi Godot 4.7 Console dengan hasil:

```text
========================================
RUNNING ARCHITECTURE BOUNDARY TESTS (PHASE 1)
========================================
[TEST] Running test_domain_isolation...
[PASS] test_domain_isolation
[TEST] Running test_simulation_determinism...
[PASS] test_simulation_determinism
[TEST] Running test_unidirectional_coordination...
[PASS] test_unidirectional_coordination
[TEST] Running test_persistence_dto_serialization...
[PASS] test_persistence_dto_serialization
[TEST] Running test_config_resource_isolation...
[PASS] test_config_resource_isolation
========================================
TEST RESULTS: 5 PASSED, 0 FAILED
========================================
```
