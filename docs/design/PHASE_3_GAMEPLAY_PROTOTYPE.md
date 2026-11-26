# PHASE 3 — GAMEPLAY PROTOTYPE IMPLEMENTATION PLAN

**Status**: DRAFT / PLANNING (AWAITING DEVELOPER APPROVAL)  
**Project**: `fortress_game`  
**Repository**: `https://github.com/AchmadKing/fortress_game.git`  
**Branch**: `main`  
**Dependencies**: Phase 0 (Completed), Phase 1 (Completed), Phase 2 (Completed)

> [!IMPORTANT]
> Dokumen ini adalah **Rencana Implementasi Teknis (Technical Implementation Plan)**.
> Sesuai aturan utama `AGENTS.md`, **TIDAK ADA KODE GAMEPLAY, SCENE BARU, MAUPUN MODIFIKASI SOURCE CODE** yang diimplementasikan pada tahap audit & perencanaan ini. Implementasi teknis hanya akan dimulai setelah developer memberikan persetujuan eksplisit (*Explicit Approval*).

---

## 1. Objective

Tujuan utama dari **Phase 3 — Gameplay Prototype** adalah membangun jembatan teknis yang menghubungkan arsitektur terisolasi (Phase 1) dengan model matematika & simulasi deterministik (Phase 2) menjadi sebuah **siklus gameplay yang dapat dimainkan (*playable prototype*)** di Godot Engine 4.x.

Phase 3 bertujuan untuk:
1. Membuktikan bahwa loop gameplay inti (*Core Gameplay Loop*) dapat berjalan secara mulus di Godot tanpa ketergantungan pada rendering frame visual yang berat.
2. Memvalidasi transisi state game secara aman dan deterministik melalui Game State Machine.
3. Menyediakan kontrol interaksi player dasar (manajemen alokasi pekerja & serdadu pada fase persiapan, kendali kecepatan dan jeda saat pertempuran, serta abstraksi perintah komandan).
4. Menyediakan antarmuka telemetri debug (*Debug / Prototype View*) berbasis teks murni untuk mengamati state dan menguji stabilitas gameplay pada hardware berspesifikasi rendah.

---

## 2. Current Architecture Audit

### 2.1 Hasil Audit Phase 1 (Core Architecture)
- **Status Evaluasi**: `NEEDS EXTENSION`
- **Domain Isolation**: `GameStateSnapshot` beroperasi sebagai `RefCounted` murni tanpa dependensi ke `Node`, `SceneTree`, atau rendering visual. Batas ini 100% terjaga.
- **Unidirectional Data Flow**: `GameCoordinator` telah mengimplementasikan pola aliran data satu arah dengan memancarkan sinyal `state_changed(snapshot)` dan mengembalikan salinan `clone()` dari state internal untuk mencegah mutasi liar dari layer presentasi.
- **Simulation Boundary**: `SimulationRunner` terbukti dapat berjalan tanpa `_process()` dan frame rate.
- **Persistence DTO**: `SaveSnapshotDto` memvalidasi integritas data plain dictionary dengan validasi `schema_version`.
- **Temuan & Kebutuhan Ekstensi**:
  - `GameStateSnapshot` pada Phase 1 hanya memuat field primitif (`tick`, `session_id`, `state_name`, `metadata`). Untuk Phase 3, snapshot perlu diperluas secara terstruktur untuk mengemas entitas domain Phase 2 (populasi, benteng, hero, gudang senjata, bendahara, indeks wave, dan status state machine).
  - `SimulationRunner` pada Phase 1 hanya melakukan increment `tick`. Perlu dihubungkan dengan engine simulasi Phase 2 (`WaveGenerator`, `CombatEngine`, `EconomyManager`).
  - `GameCoordinator` perlu diperkaya dengan metode penanganan perintah player (*command handlers*) yang divalidasi terhadap state machine.

### 2.2 Hasil Audit Phase 2 (Mathematical Systems Prototype)
- **Status Evaluasi**: `READY FOR INTEGRATION`
- Seluruh 4 temuan *Conditional Review* Phase 2 telah tervalidasi 100% (21/21 test lolos):
  - Model kuantitas equipment gudang senjata membatasi efektivitas tier (Kasus A, B, C, D).
  - Kehilangan equipment akibat gugurnya prajurit (35% hancur, 65% rusak parah) dan kelangsungan hidup hero deterministik berbasis bahaya/fatigue.
  - Penghapusan total *production worker* dan pendapatan pasif (ekonomi bertumpu pada *Battle Loot* gelombang musuh).
  - Konservasi populasi sipil-ke-militer dengan kematian permanen (*permadeath*).
- Simulasi 100-wave deterministik membuktikan tidak adanya keruntuhan benteng (*fortress survived*), tidak ada eksploitasi ekonomi, dan tidak ada kebocoran alokasi.

---

## 3. Existing Systems Reused

Phase 3 **TIDAK AKAN MEMBUAT DUPLIKASI IMPLEMENTASI** dari sistem-sistem yang telah teruji di Phase 2. Seluruh sistem berikut akan digunakan kembali (*reused*) secara langsung:

| Sistem / File Existing | Peran dalam Phase 3 |
| :--- | :--- |
| `scripts/domain/model/population_model.gd` | Mengelola demografi sipil, alokasi peran serdadu, serdadu bayaran, dan pemrosesan korban pertempuran. |
| `scripts/domain/model/fortress_model.gd` | Melacak HP benteng persisten, mitigasi kerusakan armor, dan trigger Game Over saat HP $\le 0$. |
| `scripts/domain/model/hero_model.gd` | Mengelola atribut stat hero, level/EXP, penumpukan fatigue per battle, dan status hidup/mati (*permadeath*). |
| `scripts/domain/model/equipment_model.gd` | Mengelola inventaris kuantitas senjata/armor di gudang, degradasi durabilitas, dan penalti barang rusak. |
| `scripts/simulation/economy_manager.gd` | Mengelola gaji pekerja/militer, alokasi 4 tugas pekerja (Repair, Blacksmith, Construction, Idle), dan reparasi benteng. |
| `scripts/simulation/wave_generator.gd` | Menghasilkan komposisi ancaman musuh (Minion, Raider, Brute, Flyer, Siege, Boss) dengan kurva anti-spike. |
| `scripts/simulation/combat_engine.gd` | Mengeksekusi resolusi pertempuran 5-fase deterministik, pembagian EXP, attrition equipment, dan loot hasil pertempuran. |
| `scripts/infrastructure/persistence/save_snapshot_dto.gd` | Standar serialisasi DTO berbasis `schema_version`. |

---

## 4. Required Extensions

Untuk menghubungkan gameplay loop tanpa merusak sistem existing, ekstensi berikut direncanakan:

### 4.1 Ekstensi `GameStateSnapshot` (`scripts/domain/state/game_state_snapshot.gd`)
Menyediakan wadah terstruktur untuk data runtime game:
- `current_wave: int`
- `game_phase: String` (BOOT, PREPARATION, WAVE_PREVIEW, BATTLE, RESULT, RECOVERY, GAME_OVER)
- `fortress_data: Dictionary` (snapshot FortressModel)
- `population_data: Dictionary` (snapshot PopulationModel)
- `heroes_data: Array` (array snapshot HeroModel)
- `warehouse_data: Array` (array snapshot EquipmentModel)
- `economy_data: Dictionary` (treasury_gold, worker_allocation)
- `current_wave_data: Dictionary` (ancaman & komposisi musuh aktif)
- `last_battle_result: Dictionary` (hasil pertempuran terkini)
- *Catatan backward compatibility*: Seluruh field Phase 1 (`tick`, `session_id`, `state_name`, `metadata`) tetap dipertahankan agar test Phase 1 tetap 100% lulus.

### 4.2 Game State Machine (`scripts/application/state_machine/gameplay_state_machine.gd`)
State machine terisolasi yang mengontrol otoritas transisi fase game dan memvalidasi perintah yang masuk.

### 4.3 Ekstensi `SimulationRunner` (`scripts/simulation/simulation_runner.gd`)
Menyediakan method eksekusi deterministik untuk:
- Mengorkestrasi siklus ekonomi & pemulihan benteng (`run_economy_cycle`).
- Menggenerasi data wave terkini (`prepare_wave`).
- Mengeksekusi langkah pertempuran multi-fase (`execute_battle_phase` atau `run_full_battle`).

### 4.4 Abstraksi Perintah Komandan (`scripts/domain/command/commander_command.gd`)
Struktur data ringan (DTO) untuk menangkap intensi taktis komandan:
- Enum: `HOLD`, `ADVANCE`, `RETREAT`, `PROTECT`, `FOCUS`, `FOLLOW`.

---

## 5. Game State Machine

State Machine memastikan alur permainan bergerak secara tertib tanpa kemungkinan terjadinya *state desynchronization*.

```
   ┌─────────┐
   │  BOOT   │
   └────┬────┘
        │ (initialize_session)
        ▼
 ┌───────────────┐        (inspect wave)        ┌────────────────┐
 │  PREPARATION  │ ───────────────────────────> │  WAVE_PREVIEW  │
 └───────▲───────┘ <─────────────────────────── └───────┬────────┘
         │               (cancel / back)                │
         │                                              │ (start_battle)
         │                                              ▼
 ┌───────┴───────┐        (battle ends)         ┌────────────────┐
 │   RECOVERY    │ <─────────────────────────── │     BATTLE     │
 └───────────────┘                              └───────┬────────┘
                                                        │ (fortress HP <= 0)
                                                        ▼
                                                ┌────────────────┐
                                                │   GAME_OVER    │
                                                └────────────────┘
```

### 5.1 Definisi State
1. **BOOT**: Inisialisasi session baru, pembacaan starter heroes, persediaan gudang awal, dan benteng baseline.
2. **PREPARATION**: Player melakukan rekrutmen serdadu, pengaturan alokasi pekerja sipil (Repair, Blacksmith, Construction, Idle), istirahat hero, dan reparasi perlengkapan gudang.
3. **WAVE_PREVIEW**: Player memeriksa laporan intelijen/scouting ancaman musuh (Threat Budget, jenis musuh yang akan datang), menyusun komandan hero, dan menekan tombol konfirmasi tempur.
4. **BATTLE**: Pertempuran berlangsung. Simulasi berjalan per tick/fase. Player dapat mengatur kecepatan (1x, 2x, 4x), menjeda (pause/resume), dan mengeluarkan perintah taktis dasar.
5. **RESULT**: Menampilkan rangkuman pertempuran: status kemenangan, kerusakan benteng, korban serdadu gugur, kerusakan/kehilangan senjata, status kelangsungan hidup hero, EXP didapat, dan loot emas.
6. **RECOVERY**: Pemrosesan konsekuensi pertempuran: penerimaan loot emas ke kas, pemotongan gaji rutin/upkeep, pembersihan slot korban jiwa, dan perbaikan benteng otomatis oleh pekerja reparasi. Jika benteng runtuh, transisi ke `GAME_OVER`. Jika selamat, transisi kembali ke `PREPARATION` gelombang berikutnya.
7. **GAME_OVER**: Kondisi terminal benteng hancur ($HP \le 0$). Menampilkan statistik gelombang akhir yang dicapai dan opsi memulai sesi baru.

### 5.2 Otoritas & Validasi Transisi
- **Otoritas Tunggal**: Hanya `GameCoordinator` (melalui `GameplayStateMachine`) yang berhak mengubah state.
- **Transisi Sah (*Valid Transitions*)**:
  - `BOOT` $\rightarrow$ `PREPARATION`
  - `PREPARATION` $\rightarrow$ `WAVE_PREVIEW`
  - `WAVE_PREVIEW` $\rightarrow$ `BATTLE` atau `WAVE_PREVIEW` $\rightarrow$ `PREPARATION`
  - `BATTLE` $\rightarrow$ `RESULT`
  - `RESULT` $\rightarrow$ `RECOVERY` (bila $HP > 0$)
  - `RESULT` $\rightarrow$ `GAME_OVER` (bila $HP \le 0$)
  - `RECOVERY` $\rightarrow$ `PREPARATION` (indeks wave bertambah $+1$)
- **Transisi Ilegal (*Invalid Transitions*)**:
  - `PREPARATION` $\rightarrow$ `BATTLE` langsung tanpa melalui preview.
  - `BATTLE` $\rightarrow$ `PREPARATION` tanpa resolusi result & recovery.
  - `GAME_OVER` $\rightarrow$ `PREPARATION` langsung tanpa re-boot session.

---

## 6. Gameplay Loop

Loop inti gameplay Phase 3 menjamin kontinuitas state antar-gelombang:

```text
[Loop Gelombang Gameplay]
1. PREPARATION
   - Player mengalokasikan pekerja: Repair, Blacksmith, Construction.
   - Player merekrut serdadu dari warga sipil.
   - Player memilih hero yang aktif bertarung vs beristirahat.
   - Konfirmasi persiapan selesai.

2. WAVE PREVIEW
   - Sistem men-generate ancaman gelombang musuh (WaveGenerator).
   - Player melihat komposisi musuh dan threat level.
   - Player menekan tombol "Start Wave".

3. BATTLE
   - Simulasi 5-fase dijalankan (Ranged -> Frontline -> Melee/Heroes -> Breach -> Resolution).
   - Timer simulasi mengeksekusi tick langkah pertempuran.
   - Player mengamati log/status pertempuran.
   - Player dapat pause, ubah kecepatan (1x/2x/4x), atau kirim basic command.

4. RESULT
   - Hasil pertempuran dievaluasi: Kemenangan, Kerusakan Benteng, Korban Jiwa, Equipment Loss, Kelangsungan Hero.

5. RECOVERY
   - Kas bertambah dari Battle Loot.
   - Siklus ekonomi diproses (Gaji prajurit & pekerja dipotong).
   - Pekerja reparasi memperbaiki HP benteng jika kas mencukupi.
   - Moral warga sipil diperbarui.
   - Pertumbuhan alami populasi diproses jika kapasitas hunian mencukupi.

6. EVALUASI GAME OVER vs NEXT WAVE
   - Jika Fortress HP <= 0 -> GAME OVER.
   - Jika Fortress HP > 0 -> Wave Counter bertambah (+1), kembali ke PREPARATION.
```

---

## 7. Scene Architecture

Arsitektur scene prototipe dirancang minimal, ringan, dan bebas dari aset visual berat:

```text
res://scenes/prototype/
└── main_prototype.tscn (Root: Node)
    ├── GameController (Node: scripts/presentation/controllers/game_controller.gd)
    ├── SimulationTimer (Timer: pengendali tick rate pertempuran & speed)
    └── PrototypeDebugView (CanvasLayer: scripts/presentation/views/prototype_debug_view.gd)
        └── MarginContainer
            └── HBoxContainer
                ├── LeftPanel (VBoxContainer: Status benteng, ekonomi, populasi)
                ├── CenterPanel (VBoxContainer: Status pertempuran, log phase, battle controls)
                └── RightPanel (VBoxContainer: Hero party, gudang perlengkapan, tombol aksi)
```

### Tanggung Jawab Node:
1. **`main_prototype.tscn` (Root)**:
   - Node root pembungkus session prototype. Bertanggung jawab menginisialisasi `GameCoordinator`.
2. **`GameController` (`game_controller.gd`)**:
   - Menangkap input player (tombol UI/shortcut keyboard), memetakannya menjadi command, dan memanggil method `GameCoordinator`.
   - Mengontrol `SimulationTimer` untuk fitur pause, resume, dan kecepatan (1x = 1.0s/tick, 2x = 0.5s/tick, 4x = 0.25s/tick).
3. **`PrototypeDebugView` (`prototype_debug_view.gd`)**:
   - Menghubungkan dirinya ke sinyal `GameCoordinator.state_changed`.
   - Menampilkan data teks langsung (*reactive label updating*) tanpa polling di `_process()`.

---

## 8. Coordinator Responsibilities

Untuk mencegah `GameCoordinator` menjadi *God Object*, tanggung jawab dibagi secara tegas:

```text
┌────────────────────────────────────────────────────────┐
│                   GameCoordinator                      │
│  - Otoritas orchestrasi application layer              │
│  - Menampung instance Domain Models & Sub-Systems      │
│  - Memvalidasi perintah via GameplayStateMachine       │
│  - Memancarkan state_changed(snapshot)                 │
└───────┬───────────────────┬───────────────────┬────────┘
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ State Machine │   │  Simulation   │   │ Domain Models │
│  - Validasi   │   │  - Wave Gen   │   │  - Fortress   │
│    transisi   │   │  - Combat     │   │  - Population │
│    state game │   │  - Economy    │   │  - Heroes     │
└───────────────┘   └───────────────┘   └───────────────┘
```

- **Yang dilakukan `GameCoordinator`**:
  - Menerima intent dari `GameController` (`recruit_soldier`, `assign_workers`, `start_battle`, dll).
  - Memverifikasi apakah aksi diizinkan pada state aktif.
  - Memutasi domain model atau memanggil service simulasi terkait.
  - Menghasilkan `GameStateSnapshot` baru dan memancarkannya ke listener via sinyal.
- **Yang TIDAK dilakukan `GameCoordinator`**:
  - Tidak memuat logika perhitungan damage atau formula matematika (milik `CombatEngine`).
  - Tidak mengelola rendering frame, timer Godot, atau manipulasi node visual (milik presentation).
  - Tidak melakukan file I/O langsung (milik persistence).

---

## 9. Input Model

Model input prototipe berfokus pada kelengkapan fungsional, bukan estetika UI:

### 9.1 Kontrol Fase Persiapan & Preview
- **Tombol / Aksi**:
  - `[+] / [-]` Alokasi Pekerja (Repair, Blacksmith, Construction).
  - `[Recruit]` Rekrut serdadu spesifik (Swordsman, Shield, Archer, Spearman, Heavy).
  - `[Rest / Ready]` Toggle status istirahat hero.
  - `[Inspect Wave]` Melanjutkan dari `PREPARATION` ke `WAVE_PREVIEW`.
  - `[Start Battle]` Memulai pertempuran dari `WAVE_PREVIEW`.
  - `[Cancel]` Kembali dari `WAVE_PREVIEW` ke `PREPARATION`.

### 9.2 Kontrol Pertempuran
- **Tombol / Shortcut Keyboard**:
  - `Space`: Pause / Resume simulasi pertempuran.
  - `1`: Kecepatan normal (1x).
  - `2`: Kecepatan ganda (2x).
  - `3` / `4`: Kecepatan tinggi (4x).
  - `[Hold]`, `[Advance]`, `[Retreat]`: Tombol perintah taktis komandan dasar.

---

## 10. Battle Prototype

Prototipe pertempuran Phase 3 membuktikan jalannya simulasi pertempuran secara interaktif tanpa memerlukan aset sprite atau animasi:

1. **Resolusi Multi-Tick Interaktif**:
   - Daripada menyelesaikan seluruh pertempuran dalam 1 frame instan, `SimulationTimer` menjalankan resolusi pertempuran langkah-demi-langkah:
     - *Tick 1*: Ranged Volley (Archer vs Flyers/Minions).
     - *Tick 2*: Frontline Clash (Shield & Spearman vs Brutes).
     - *Tick 3*: Melee & Hero Engagement (Swordsmen, Heavy, Heroes vs Raiders/Minions).
     - *Tick 4*: Wall Breach Assault (Sisa ancaman menyerang benteng).
     - *Tick 5*: Casualty & Aftermath Resolution (Evaluasi korban jiwa, gear loss, hero survival, loot).
2. **Keterlibatan Player**:
   - Player dapat mengamati jalannya fase di log telemetri teks.
   - Player dapat mengubah kecepatan atau menjeda jalannya fase pertempuran kapan saja.
3. **Penggunaan Sistem Phase 2 Utuh**:
   - Menggunakan formula `CombatEngine` dan `_seeded_float()` yang sama persis sehingga hasil pertempuran tetap 100% deterministik dan teruji.

---

## 11. Commander Command Abstraction

Sesuai konsep desain game, player adalah seorang komandan benteng:

### 11.1 Abstraksi Phase 3 (Minimal Command Modifier)
Dibuat kelas DTO `CommanderCommand` dengan tipe:
- `HOLD`: Memerintahkan pasukan bertahan rapat di gerbang. Efek: Pertahanan Shield $+15\%$, serangan jarak dekat $-10\%$.
- `ADVANCE`: Serangan ofensif agresif. Efek: Serangan melee $+15\%$, namun risiko korban prajurit gugur meningkat $+10\%$.
- `RETREAT`: Pasukan mundur ke balik perlindungan benteng. Efek: Menghindari korban serdadu, namun residual threat langsung menghantam tembok benteng.
- `PROTECT`: Seluruh barisan mengawal hero yang kelelahan. Efek: Hero survival rate meningkat $+25\%$.

### 11.2 Batasan Scope
- Di Phase 3, perintah ini hanya memodifikasi koefisien pengali kalkulasi pertempuran di `CombatEngine`.
- Implementasi penuh medan tempur multi-zona, pergerakan unit real-time, dan AI musuh ditunda ke **Phase 6 (Tactical Battle & Battlefield Systems)**.

---

## 12. Debug / Prototype View

Antarmuka prototipe dibangun menggunakan node bawaan UI Godot (`Label`, `Button`, `VBoxContainer`, `HBoxContainer`) tanpa custom shader, gambar tekstur, atau font eksternal:

```text
================================================================================
FORTRESS GAME — PHASE 3 GAMEPLAY PROTOTYPE (DEBUG VIEW)
================================================================================
State: [PREPARATION]     | Wave: 3 / 100          | Speed: [1x] [2x] [4x] [PAUSE]
--------------------------------------------------------------------------------
[FORTRESS]               | [POPULATION & WORKERS] | [MILITARY & WAREHOUSE]
HP: 850 / 1000           | Civilians: 12          | Swordsmen: 4  (Sword T1: 10)
Armor: 40                | Repair: 2              | Shield:    3  (Shield T1: 10)
Status: INTACT           | Blacksmith: 1          | Archers:   3  (Bow T1: 10)
Treasury: 180 Gold       | Construction: 0        | Spearman:  2  (Spear T1: 10)
Upkeep/Cycle: 45 Gold    | Idle: 9                | Mercenaries: 0
--------------------------------------------------------------------------------
[HERO ROSTER]
- Alder Ironclad (Lv 2) | Fatigue: 15/100 | Morale: 100 | Status: ALIVE [READY]
- Lyra Windwalker (Lv 1)| Fatigue: 45/100 | Morale: 95  | Status: ALIVE [REST]
--------------------------------------------------------------------------------
[BATTLE / EVENT TELEMETRY LOG]
> Wave 2 Cleared. Battle Loot: +65 Gold. Fortress took 45 damage (Repaired +25).
> 1 Shield Infantry casualty reported. Gear salvaged with heavy wear.
--------------------------------------------------------------------------------
[ACTIONS]
[Allocate Workers] [Recruit Soldier] [Manage Equipment] [INSPECT NEXT WAVE]
================================================================================
```

---

## 13. Data Flow

Seluruh interaksi mematuhi arsitektur aliran data satu arah (*Unidirectional Data Flow*):

```text
      [User Action / Input Event]
                   │
                   ▼
       [GameController (Node)]
                   │ (calls coordinator command API)
                   ▼
     [GameCoordinator (RefCounted)]
                   │
                   ├──> [GameplayStateMachine] (validates transition legality)
                   │
                   ├──> [SimulationRunner] (executes deterministic step)
                   │          │
                   │          ├──> CombatEngine
                   │          ├──> WaveGenerator
                   │          └──> EconomyManager
                   │
                   ├──> [Domain Models Mutated] (Fortress, Population, Heroes, Equipment)
                   │
                   └──> [Generates GameStateSnapshot.clone()]
                               │
                               ▼ (emits state_changed signal)
               [PrototypeDebugView (CanvasLayer)]
                               │ (updates UI text labels)
                               ▼
                        [User Observes]
```

---

## 14. Testing Strategy

Setiap komponen yang dibangun di Phase 3 wajib divalidasi dengan rangkaian pengujian headless otomatis:

### 14.1 Unit Tests (`tests/test_gameplay_prototype.gd`)
- `test_state_machine_valid_transitions`: Menguji seluruh rantai transisi sah.
- `test_state_machine_invalid_transitions`: Memastikan transisi ilegal ditolak keras.
- `test_preparation_worker_allocation`: Menguji alokasi pekerja dan validasi batas kapasitas warga sipil.
- `test_soldier_recruitment_conservation`: Memastikan rekrutmen memotong sipil dan menambah prajurit dengan benar.
- `test_battle_step_execution`: Menguji eksekusi simulasi pertempuran per langkah.
- `test_recovery_cycle_application`: Menguji penambahan loot, pemotongan gaji, reparasi benteng, dan pertumbuhan warga.
- `test_game_over_trigger`: Memastikan runtuhnya benteng ($HP = 0$) menghentikan game loop dan mengunci state ke `GAME_OVER`.
- `test_commander_command_modifiers`: Menguji pengaruh perintah taktis komandan pada kalkulasi power/survival.

### 14.2 Integration Tests
- **Full Wave Cycle Test**: Menjalankan 5 gelombang penuh berturut-turut melalui `GameCoordinator` dari `BOOT -> PREP -> PREVIEW -> BATTLE -> RESULT -> RECOVERY -> PREP`.
- **State Persistence Test**: Memverifikasi bahwa data antar-state tidak bocor atau reset di tengah gelombang.

### 14.3 Regression Tests (Zero Regression Guarantee)
- `tests/test_architecture_boundaries.gd` (Phase 1): Wajib **5 PASSED, 0 FAILED**.
- `tests/test_mathematical_prototype.gd` (Phase 2): Wajib **21 PASSED, 0 FAILED**.

---

## 15. Performance Constraints (Low-End Hardware)

Mengingat target hardware development dan mobile Android yang sangat terbatas:
- **Zero Real-Time Unit Entities**: Tidak ada node sprite atau physics body individual per prajurit. Serdadu tetap disimulasikan secara agregat (*aggregate simulation*).
- **Zero Per-Frame Polling**: Tidak ada node yang menjalankan kalkulasi logika pada `_process(delta)`. Seluruh pembaruan tampilan murni digerakkan oleh event/sinyal `state_changed`.
- **Low Memory Footprint**: Seluruh domain model berbasis `RefCounted`. Alokasi memori dinamis dijaga minimal dan dibebaskan secara otomatis oleh engine.
- **Lightweight Scene Tree**: Jumlah total node pada scene prototipe kurang dari 25 node UI standar.

---

## 16. File Changes

### 16.1 Files Planned to Change (Extending Existing)
1. `scripts/domain/state/game_state_snapshot.gd`:
   - Menambahkan field terstruktur untuk snapshot domain models (`fortress`, `population`, `heroes`, `warehouse`, `economy`, `wave`, `phase`).
   - Menjaga backward compatibility method `clone()`, `to_dictionary()`, dan `from_dictionary()`.
2. `scripts/application/coordinators/game_coordinator.gd`:
   - Mengintegrasikan `GameplayStateMachine` dan engine simulasi Phase 2.
   - Menambahkan command API publik untuk interaksi gameplay.
3. `scripts/simulation/simulation_runner.gd`:
   - Memperluas runner untuk mengorkestrasi eksekusi `WaveGenerator`, `CombatEngine`, dan `EconomyManager`.

### 16.2 Files Planned to Add (New Minimal Files)
1. `scripts/application/state_machine/gameplay_state_machine.gd`: State machine transisi fase game.
2. `scripts/domain/command/commander_command.gd`: Abstraksi intent perintah komandan.
3. `scripts/presentation/controllers/game_controller.gd`: Controller penghubung input player ke coordinator.
4. `scripts/presentation/views/prototype_debug_view.gd`: Script render dashboard telemetri teks.
5. `scenes/prototype/main_prototype.tscn`: Scene prototipe minimal.
6. `tests/test_gameplay_prototype.gd`: Test suite otomatis untuk validasi Phase 3.

---

## 17. Implementation Order

Urutan implementasi dirancang bertahap dan aman (*step-by-step*) agar setiap langkah dapat diverifikasi sebelum melanjutkan:

```text
Step 1  — Ekstensi GameStateSnapshot (domain data models serialization support).
Step 2  — Implementasi GameplayStateMachine (state transitions & authority validation).
Step 3  — Implementasi CommanderCommand DTO (Hold, Advance, Retreat, Protect).
Step 4  — Ekstensi SimulationRunner (integrasi orkestrasi engine Phase 2).
Step 5  — Ekstensi GameCoordinator (integrasi state machine, runner, dan command handlers).
Step 6  — Pembuatan Unit Test Suite test_gameplay_prototype.gd (verifikasi headless state & loop).
Step 7  — Pembuatan script GameController & SimulationTimer (input & battle speed logic).
Step 8  — Pembuatan script PrototypeDebugView (CanvasLayer & reactive labels).
Step 9  — Perakitan scene main_prototype.tscn di Godot.
Step 10 — Verifikasi integrasi end-to-end playable prototype di Godot editor & console headless.
Step 11 — Verifikasi regresi arsitektur Phase 1 (5/5 PASS) dan matematika Phase 2 (21/21 PASS).
Step 12 — Dokumentasi penutupan Phase 3 dan pelaporan ke developer.
```

---

## 18. Phase Boundary

Untuk mencegah *scope creep*, batas tanggung jawab Phase 3 ditetapkan sebagai berikut:

### Dalam Scope Phase 3:
- Siklus gameplay loop inti (Boot, Prep, Preview, Battle, Result, Recovery, Game Over).
- Game State Machine deterministik.
- Integrasi GameCoordinator dengan engine simulasi Phase 2.
- Kontrol player dasar: alokasi pekerja, rekrutmen prajurit, pause/resume, speed 1x/2x/4x.
- Abstraksi dasar perintah komandan (Hold, Advance, Retreat, Protect).
- Debug / Prototype Dashboard berbasis teks murni.
- Pengujian unit dan integrasi headless otomatis.

### Di Luar Scope Phase 3 (Ditunda ke Fase Berikutnya):
- **Phase 4**: Sistem gacha/rekrutmen hero kompleks, skill tree hero, equipment khusus hero, UI detail hero.
- **Phase 5**: Sistem manajemen benteng mendalam, konstruksi ruangan benteng, sistem cuaca.
- **Phase 6**: Sistem pertarungan taktis mendalam, pergerakan unit medan perang real-time, zona pertempuran, AI musuh kompleks.
- **Phase 7–8**: Audio, SFX, musik latar, efek suara pertempuran.
- **Phase 9**: Pixel art final, animasi sprite, efek partikel, shader visual, UI polish final.
- **Phase 10**: Sistem penyimpanan file Save/Load disk penuh ke format biner/enkripsi.

---

## 19. Acceptance Criteria

Implementasi Phase 3 hanya akan dinyatakan selesai jika seluruh kriteria berikut terpenuhi:

- [ ] Project Godot dapat memuat dan menjalankan `main_prototype.tscn` tanpa error.
- [ ] Fase `PREPARATION` berfungsi: player dapat mengalokasikan pekerja dan merekrut serdadu dari warga sipil.
- [ ] Fase `WAVE_PREVIEW` berfungsi: menampilkan perkiraan ancaman gelombang musuh berikutnya.
- [ ] Fase `BATTLE` dapat dimulai dan menggunakan logika `CombatEngine` Phase 2 yang sudah ada (tanpa duplikasi logika).
- [ ] Hasil pertempuran (`RESULT`) dilaporkan secara akurat dan memutasi state benteng, populasi, dan hero.
- [ ] Fase `RECOVERY` memproses loot emas, biaya gaji rutin, dan reparasi benteng secara otomatis.
- [ ] Gelombang berikutnya dapat dimulai dan state bertahan secara konsisten (*state persistence across waves*).
- [ ] Keruntuhan benteng ($HP \le 0$) memicu kondisi `GAME_OVER` secara tepat.
- [ ] Fitur Pause / Resume dan pengatur kecepatan (1x, 2x, 4x) berfungsi saat pertempuran berlangsung.
- [ ] Tidak ada duplikasi logika simulasi antara Phase 2 dan Phase 3.
- [ ] Seluruh test Phase 1 tetap lulus (**5/5 PASSED, 0 FAILED**).
- [ ] Seluruh test Phase 2 tetap lulus (**21/21 PASSED, 0 FAILED**).
- [ ] Seluruh test Phase 3 yang baru dibuat lulus (**100% PASSED**).
- [ ] Performa prototipe tetap ringan dan responsif pada target spesifikasi hardware rendah.

---

## 20. Risks & Mitigation

| Potensi Risiko | Dampak | Strategi Mitigasi |
| :--- | :--- | :--- |
| **State Desynchronization** | Data di UI tidak mencerminkan data aktual di domain state. | Terapkan isolasi ketat: UI tidak boleh menyimpan state lokal, melainkan murni me-render salinan `GameStateSnapshot` yang dipancarkan via sinyal `state_changed`. |
| **Scope Creep ke Fitur Visual** | Waktu habis untuk membuat art/animasi alih-alih memvalidasi loop gameplay. | Dilarang keras membuat sprite, tekstur, atau animasi di Phase 3. Tampilan murni menggunakan node `Label` dan `Button` default Godot. |
| **Duplikasi Logika Simulasi** | Terjadi inkonsistensi formula pertempuran antara Phase 2 dan Phase 3. | `GameCoordinator` dan `SimulationRunner` diwajibkan memanggil class Phase 2 (`CombatEngine`, `EconomyManager`, `WaveGenerator`) secara langsung. Dilarang menulis kalkulasi combat baru. |
| **Beban Performa pada CPU Lemah** | Frame drop atau stutter pada hardware development Intel Celeron. | Gunakan simulasi agregat serdadu (tanpa instansiasi node unit individual), dan hilangkan loop `_process` polling. |

---

## 21. Out of Scope

Secara tegas ditegaskan bahwa hal-hal berikut **DILARANG DIKERJAKAN** pada Phase 3:
- Pembuatan pixel art karakter, monster, serdadu, atau benteng.
- Pembuatan animasi sprite sheet atau particle effect visual.
- Penulisan naskah cerita, dialog, atau quest lore.
- Pembuatan sistem inventory visual drag-and-drop.
- Penambahan sound effect (SFX) atau background music (BGM).
- Implementasi save/load file system ke disk (Save/Load tetap ditunda ke Phase 10).
- Penambahan plugin eksternal pihak ketiga ke dalam project Godot.
