# PHASE 3 — GAMEPLAY PROTOTYPE IMPLEMENTATION PLAN

**Status**: DRAFT / PLANNING (AWAITING DEVELOPER APPROVAL)  
**Project**: `fortress_game`  
**Repository**: `https://github.com/AchmadKing/fortress_game.git`  
**Branch**: `main`  
**Dependencies**: Phase 0 (Completed), Phase 1 (Completed), Phase 2 (Completed)

> [!IMPORTANT]
> Dokumen ini adalah **Rencana Implementasi Teknis (Technical Implementation Plan / Design Plan)**.
> Sesuai aturan utama `AGENTS.md`: **DILARANG MENULIS KODE GAMEPLAY, MEMBUAT SCENE GAMEPLAY FINAL, MEMBUAT BATTLE SCENE FINAL, MEMBUAT UI FINAL, MAUPUN MEMBUAT ASSET** pada tahap ini. Implementasi teknis hanya akan dimulai setelah developer memberikan persetujuan eksplisit (*Explicit Approval*).

---

## 1. Phase Objective

Tujuan utama dari **Phase 3 — Gameplay Prototype** adalah membangun jembatan teknis yang menghubungkan arsitektur terisolasi (Phase 1) dengan sistem matematika & simulasi deterministik (Phase 2) menjadi sebuah **siklus gameplay prototype yang dapat dimainkan (*playable prototype*)** secara headless maupun dalam Godot Engine 4.x.

Phase 3 bertujuan untuk:
1. Membuktikan bahwa loop gameplay inti (*Core Gameplay Loop*) dapat berjalan secara mulus di Godot tanpa ketergantungan pada rendering frame visual yang berat:
   $$\text{Siklus Normal:} \quad \text{BOOT} \rightarrow \text{PREPARATION} \rightarrow \text{WAVE PREVIEW} \rightarrow \text{BATTLE} \rightarrow \text{RESULT} \rightarrow \text{RECOVERY} \rightarrow \text{PREPARATION}$$
   $$\text{Kondisi Game Over:} \quad \text{BATTLE} \rightarrow \text{RESULT} \rightarrow \text{GAME OVER}$$
2. Memvalidasi transisi state game secara aman dan deterministik melalui **Gameplay State Machine**.
3. Menyediakan kontrol interaksi player dasar (manajemen alokasi pekerja & serdadu pada fase persiapan, kendali kecepatan dan jeda saat pertempuran, serta pengiriman abstraksi perintah komandan).
4. Menyediakan antarmuka telemetri debug (*Debug Telemetry*) berbasis teks murni untuk mengamati state dan menguji stabilitas gameplay pada hardware berspesifikasi rendah (Intel Celeron / 4 GB RAM / Android).
5. Memastikan **zero duplicate simulation logic**: seluruh kalkulasi combat, ekonomi, dan gelombang musuh murni mengeksekusi sistem Phase 2 yang sudah teruji.

---

## 2. Current Architecture Audit

### 2.1 Hasil Audit Phase 1 (Core Architecture)
- **Status Evaluasi**: `NEEDS EXTENSION`
- **Domain Isolation (`PASS`)**: `GameStateSnapshot` beroperasi sebagai `RefCounted` murni tanpa dependensi ke `Node`, `SceneTree`, atau rendering visual. Batas isolasi ini terjaga 100%.
- **Unidirectional Data Flow (`PASS`)**: `GameCoordinator` mengimplementasikan pola aliran data satu arah dengan memancarkan sinyal `state_changed(snapshot)` dan mengembalikan salinan `clone()` dari state internal untuk mencegah mutasi liar dari layer presentasi.
- **Simulation Boundary (`PASS`)**: `SimulationRunner` terbukti dapat berjalan deterministik tanpa mengandalkan `_process()` atau delta rendering frame.
- **Persistence Boundary (`PASS`)**: `SaveSnapshotDto` memvalidasi integritas data plain dictionary dengan validasi `schema_version`.
- **Kebutuhan Ekstensi**:
  - `GameStateSnapshot` Phase 1 saat ini hanya memuat field primitif (`tick`, `session_id`, `state_name`, `metadata`). Untuk Phase 3, snapshot perlu diperluas secara terstruktur untuk mengemas entitas domain Phase 2 (Fortress, Population, Heroes, Equipment, Economy, Wave, State Enum) dengan tetap mempertahankan backward compatibility method `clone()`, `to_dictionary()`, dan `from_dictionary()`.
  - `SimulationRunner` perlu dihubungkan dengan engine simulasi Phase 2 (`WaveGenerator`, `CombatEngine`, `EconomyManager`).
  - `GameCoordinator` perlu diintegrasikan dengan `GameplayStateMachine` dan command handler gameplay.

### 2.2 Hasil Audit Phase 2 (Mathematical Systems Prototype)
- **Status Evaluasi**: `READY FOR INTEGRATION (SINGLE SOURCE OF TRUTH)`
- Seluruh 4 temuan *Conditional Review* Phase 2 telah tervalidasi 100% (21/21 unit & scenario test lulus, 5/5 Phase 1 regression test lulus):
  - Model kuantitas equipment gudang senjata membatasi efektivitas tier secara agregat (Kasus A, B, C, D).
  - Kehilangan equipment akibat gugurnya prajurit (35% destroyed, 65% damaged) dan kelangsungan hidup hero deterministik berbasis bahaya breach, fatigue, dan pertahanan.
  - Penghapusan total *production worker* dan pendapatan pasif (ekonomi bertumpu pada *Battle Loot* gelombang musuh).
  - Konservasi populasi sipil-ke-militer dengan kematian permanen (*permadeath*).
- Simulasi 100-wave deterministik membuktikan stabilitas sistem tanpa kebocoran alokasi atau death spiral.

---

## 3. Phase 2 Integration Boundary

Phase 3 **TIDAK MEMBUAT COMBAT ENGINE BARU**. Sistem simulasi Phase 2 adalah **satu-satunya sumber kebenaran matematis (*Single Source of Truth*)**.

```text
┌────────────────────────────────────────────────────────┐
│            Presentation / Prototype Input              │
└──────────────────────────┬─────────────────────────────┘
                           │ (sends intent / commands)
                           ▼
┌────────────────────────────────────────────────────────┐
│                    GameCoordinator                     │
│               (Application Orchestrator)               │
└──────────────────────────┬─────────────────────────────┘
                           │ (delegates execution)
                           ▼
┌────────────────────────────────────────────────────────┐
│            Existing Phase 2 Simulation                 │
│  ├── WaveGenerator   (threat curve & enemy budget)     │
│  ├── EconomyManager  (cycle upkeep & worker repair)    │
│  └── CombatEngine    (5-phase deterministic battle)    │
└──────────────────────────┬─────────────────────────────┘
                           │ (returns battle result / cycle)
                           ▼
┌────────────────────────────────────────────────────────┐
│           Domain Models & GameStateSnapshot            │
│  (FortressModel, PopulationModel, HeroModel, Equip)    │
└──────────────────────────┬─────────────────────────────┘
                           │ (state_changed signal)
                           ▼
┌────────────────────────────────────────────────────────┐
│                  Prototype View / HUD                  │
└────────────────────────────────────────────────────────┘
```

### 3.1 Aturan Integrasi Mutlak:
1. **Dilarang membuat `CombatEngineV2` atau `BattleEngine` Baru**: Phase 3 tidak boleh menduplikasi kalkulasi damage, formula casualty, formula equipment loss, formula hero survival, maupun formula threat generation.
2. **Lima Fase Combat Phase 2 adalah Existing Simulation**:
   - Fase 1: Ranged Volley (Archer vs Flyers/Minions)
   - Fase 2: Frontline Clash (Shield & Spearman vs Brutes)
   - Fase 3: Melee & Hero Engagement (Swordsmen, Heavy, Heroes vs Raiders/Minions)
   - Fase 4: Wall Breach & Siege Assault (Residual Threat vs Fortress Wall)
   - Fase 5: Casualties, Gear Loss, Hero Survival, EXP & Loot Resolution
   Phase 3 hanya menjalankan (*run*) dan mengekspos progres simulasi ini secara bertahap via timer untuk kebutuhan interaksi/debug, bukan mendesain ulang atau menulis ulang formulanya.
3. **Enemy Archetype Phase 2 Tetap Utuh**:
   - Archetype internal yang digunakan tetap: `MINION`, `RAIDER`, `BRUTE`, `FLYER`, `SIEGE`, `BOSS`.
   - Tidak ada rename enum atau refactor sistem musuh di Phase 3. Penamaan tematik visual (Goblin, Orc, Troll) adalah *future content mapping* untuk fase produksi konten mendatang.

---

## 4. Gameplay State Machine

State Machine mengontrol otoritas alur permainan. State tidak bergantung pada SceneTree atau UI, dan transisi ilegal wajib ditolak secara tegas.

```text
                  ┌─────────┐
                  │  BOOT   │
                  └────┬────┘
                       │ (initialize_session)
                       ▼
             ┌───────────────────┐  (inspect wave)  ┌───────────────────┐
      ┌────> │    PREPARATION    │ ───────────────> │   WAVE_PREVIEW    │
      │      └───────────────────┘ <─────────────── └─────────┬─────────┘
      │                ▲                 (cancel)             │
      │                │                                      │ (start_battle)
      │                │                                      ▼
      │      ┌───────────────────┐                  ┌───────────────────┐
      │      │     RECOVERY      │                  │      BATTLE       │
      │      └─────────▲─────────┘                  └─────────┬─────────┘
      │                │                                      │ (battle ends)
      │                │ (Fortress HP > 0)                    ▼
      │                └─────────────────────────── ┌───────────────────┐
      │                                             │      RESULT       │
      │                                             └─────────┬─────────┘
      │                                                       │ (Fortress HP <= 0)
      │                                                       ▼
      │                                             ┌───────────────────┐
      │                                             │     GAME_OVER     │
      │                                             └───────────────────┘
      │ (advances to next wave: wave + 1)
      └───────────────────────────────────────────────────────┘
```

### 4.1 Definisi State:
- **`BOOT`**: Inisialisasi awal session, registrasi starter heroes, persediaan gudang awal, dan status benteng baseline.
- **`PREPARATION`**: Player mengatur alokasi pekerja sipil (Repair, Blacksmith, Construction, Idle), merekrut serdadu dari warga sipil, mengatur kesiapan hero (Ready vs Rest), dan melakukan reparasi perlengkapan gudang.
- **`WAVE_PREVIEW`**: Player melihat pratinjau informasi intelijen gelombang musuh yang akan datang, lalu memutuskan untuk memulai pertempuran atau kembali ke persiapan.
- **`BATTLE`**: Simulasi pertempuran berjalan. Player dapat mengatur kecepatan (1x, 2x, 4x), menjeda (pause/resume), dan mengirimkan intensi perintah komandan.
- **`RESULT`**: Penyajian dan evaluasi hasil akhir pertempuran (menang/kalah, kerusakan benteng, korban serdadu gugur, kerusakan/kehilangan perlengkapan, kelangsungan hidup hero, EXP per hero, dan loot emas).
  - Jika Fortress $HP \le 0$: Transisi langsung ke `GAME_OVER` (sesi berakhir, tidak ada fase recovery).
  - Jika Fortress $HP > 0$: Transisi ke `RECOVERY`.
- **`RECOVERY`**: Pemrosesan orkestrasi pasca-tempur (hanya diakses bila benteng bertahan, $HP_{fortress} > 0$): penambahan loot ke kas bendahara, pemotongan gaji rutin/upkeep via EconomyManager, eksekusi reparasi benteng oleh Repair Worker existing, dan pembersihan korban jiwa. Setelah pemrosesan selesai, transisi kembali ke `PREPARATION` untuk gelombang berikutnya (indeks wave bertambah $+1$).
- **`GAME_OVER`**: Kondisi terminal saat benteng hancur ($HP \le 0$), ditransisikan langsung dari `RESULT` tanpa melewati `RECOVERY`. Sesi permainan berhenti dan mencatat pencapaian gelombang akhir.

### 4.2 Aturan Transisi:
- **Transisi Sah (*Valid Transitions*)**:
  - `BOOT` $\rightarrow$ `PREPARATION`
  - `PREPARATION` $\rightarrow$ `WAVE_PREVIEW`
  - `WAVE_PREVIEW` $\rightarrow$ `BATTLE`
  - `WAVE_PREVIEW` $\rightarrow$ `PREPARATION` (batal/kembali)
  - `BATTLE` $\rightarrow$ `RESULT`
  - `RESULT` $\rightarrow$ `RECOVERY` (bila $HP_{fortress} > 0$)
  - `RESULT` $\rightarrow$ `GAME_OVER` (bila $HP_{fortress} \le 0$)
  - `RECOVERY` $\rightarrow$ `PREPARATION` (indeks wave bertambah $+1$)
- **Transisi Ilegal (*Invalid Transitions - Wajib Ditolak*)**:
  - `PREPARATION` $\rightarrow$ `BATTLE` langsung tanpa melalui preview.
  - `BATTLE` $\rightarrow$ `PREPARATION` tanpa melewati Result dan Recovery.
  - `GAME_OVER` $\rightarrow$ `PREPARATION` langsung tanpa re-boot session baru.

---

## 5. GameCoordinator Responsibilities

`GameCoordinator` adalah **Application Orchestration Layer**, BUKAN *God Object*.

```text
┌────────────────────────────────────────────────────────┐
│                   GameCoordinator                      │
│  - Menerima intent/command dari presentation           │
│  - Memvalidasi legalitas command via State Machine     │
│  - Memanggil SimulationRunner / Sub-Systems            │
│  - Mengupdate GameStateSnapshot                        │
│  - Memancarkan state_changed(snapshot)                 │
└────────────────────────────────────────────────────────┘
```

### 5.1 Tanggung Jawab yang Dimiliki:
- Menerima panggilan perintah player dari controller/presentation layer (`recruit_soldier`, `assign_workers`, `start_battle`, `step_battle`, `send_commander_command`).
- Memvalidasi apakah perintah sah dijalankan pada state saat ini menggunakan `GameplayStateMachine`.
- Menginstruksikan `SimulationRunner` untuk mengeksekusi langkah simulasi deterministik.
- Memutasi domain models sesuai hasil simulasi yang valid.
- Menghasilkan salinan immutable `GameStateSnapshot.clone()` dan memancarkannya via sinyal `state_changed`.

### 5.2 Hal yang DILARANG di dalam `GameCoordinator`:
- **DILARANG** memuat formula perhitungan combat, formula damage, formula casualty, atau RNG combat (tanggung jawab `CombatEngine`).
- **DILARANG** memuat formula perhitungan ekonomi, gaji, atau diskon pandai besi (tanggung jawab `EconomyManager`).
- **DILARANG** memuat logika kurva threat gelombang musuh (tanggung jawab `WaveGenerator`).
- **DILARANG** memuat manipulasi Node visual, UI element, font, atau SceneTree (tanggung jawab presentation layer).
- **DILARANG** melakukan I/O file disk langsung (tanggung jawab persistence layer).

---

## 6. Commander Command Abstraction

Sesuai konsep game di mana player berperan sebagai komandan benteng, Phase 3 menyediakan abstraksi perintah komandan sebagai **Commander Intent / Command Data**.

### 6.1 Daftar 6 Perintah Komandan:
Seluruh 6 perintah komandan berikut wajib didukung oleh struktur data `CommanderCommand`:

1. **`HOLD`**: Intensi menahan posisi pertahanan rapat.
2. **`ADVANCE`**: Intensi mendorong garis depan secara agresif.
3. **`RETREAT`**: Intensi menarik pasukan mendekat ke perlindungan benteng.
4. **`PROTECT`**: Intensi mengawal dan melindungi hero yang kelelahan/terancam.
5. **`FOCUS`**: Intensi memusatkan serangan pada target prioritas tertentu.
6. **`FOLLOW`**: Intensi barisan serdadu mengikuti komando hero utama.

### 6.2 Struktur Data Abstraksi (DTO Murni):
```text
class_name CommanderCommand
extends RefCounted

var command_type: String = "HOLD" # HOLD, ADVANCE, RETREAT, PROTECT, FOCUS, FOLLOW
var target_group: String = "ALL"  # ALL, SHIELD, MELEE, ARCHER, HEROES
var target_id: String = ""        # ID entitas target (misal hero_id atau enemy type)
var issued_at_tick: int = 0
```

### 6.3 Aturan Phase 3 Tanpa Formula Combat Final:
- **TIDAK ADA FORMULA COMBAT FINAL DI PHASE 3**: Dilarang menetapkan formula seperti `HOLD = +15% defense`, `ADVANCE = +15% melee`, dsb.
- **Tujuan Phase 3**: Memvalidasi pipeline arsitektur bahwa intensi perintah dapat dikirimkan dan tercatat:
  $$\text{Player Input} \rightarrow \text{Command Intent DTO} \rightarrow \text{GameCoordinator} \rightarrow \text{Simulation Runner} \rightarrow \text{Result}$$
- **Status Eksekusi di Phase 3**:
  - Command diterima oleh coordinator dan dicatat dalam telemetri tempur.
  - Perintah yang belum memiliki efek simulasi di Phase 3 diperlakukan sebagai **deferred / no-op / placeholder behavior** yang terdokumentasi rapi.
  - Implementasi matematis dan perilaku taktis mendalam secara penuh **DITUNDA KE PHASE 6 (Tactical Battle & Battlefield Systems)**.

---

## 7. Gameplay Loop

Loop gameplay Phase 3 membuktikan transisi dan persistensi data antar-fase secara utuh:

```text
[Loop Gelombang Gameplay Phase 3]
1. PREPARATION
   - Player mengalokasikan pekerja sipil (Repair, Blacksmith, Construction, Idle).
   - Player merekrut serdadu (Swordsman, Shield, Archer, Spearman, Heavy) dari warga sipil.
   - Player mengatur kesiapan hero (Ready vs Rest).
   - Player konfirmasi selesai persiapan -> transisi ke WAVE_PREVIEW.

2. WAVE PREVIEW
   - Sistem mengambil data gelombang aktif dari WaveGenerator.
   - Player memeriksa estimasi ancaman dan jenis musuh yang akan datang.
   - Player menekan "Start Battle" -> transisi ke BATTLE.
   - (Atau player menekan "Back" -> kembali ke PREPARATION).

3. BATTLE
   - Simulasi pertempuran 5-fase dijalankan menggunakan CombatEngine Phase 2.
   - Player dapat mengatur kecepatan simulasi (1x, 2x, 4x) atau pause/resume.
   - Player dapat mengirimkan intent perintah komandan (HOLD, ADVANCE, RETREAT, PROTECT, FOCUS, FOLLOW).
   - Pertempuran selesai -> transisi ke RESULT.

4. RESULT
   - Rangkuman pertempuran ditampilkan: status kemenangan, kerusakan benteng, korban serdadu gugur, kerusakan/kehilangan perlengkapan, kelangsungan hidup hero, EXP per hero, dan loot emas.
   - Evaluasi kelangsungan hidup benteng:
     - Jika Fortress HP <= 0 -> Transisi langsung ke GAME_OVER (sesi berakhir, TIDAK menjalankan recovery normal).
     - Jika Fortress HP > 0  -> Transisi ke RECOVERY.

5. RECOVERY (Hanya jika Fortress HP > 0)
   - Menjalankan orkestrasi pasca-tempur murni menggunakan sistem Phase 2 existing:
     - Battle loot ditambahkan ke kas bendahara sebagai sumber ekonomi utama.
     - Upkeep prajurit & warga sipil dipotong dari kas via EconomyManager.process_cycle().
     - Reparasi benteng dieksekusi oleh Repair Worker yang sudah dialokasikan sesuai ketersediaan kas.
     - Pemanggilan pemulihan fatigue hero yang beristirahat (HeroModel.rest()) dan pertumbuhan alami populasi (PopulationModel.grow_population()) diorkestrasikan menggunakan method Phase 2 existing untuk menjaga kontinuitas state.
   - Setelah siklus recovery selesai, indeks wave bertambah (+1) dan permainan kembali ke PREPARATION untuk gelombang berikutnya.
```

---

## 8. Battle Prototype

Prototipe pertempuran Phase 3 berfokus pada pembuktian orkestrasi simulasi pertempuran interaktif tanpa aset visual final.

### 8.1 12 Kriteria Verifikasi Battle Prototype:
1. Pertempuran dapat dimulai dari state `WAVE_PREVIEW`.
2. Simulasi pertempuran berjalan mengeksekusi `CombatEngine` Phase 2.
3. Pertempuran dapat di-pause kapan saja.
4. Pertempuran dapat dilanjutkan kembali (*resume*).
5. Kecepatan simulasi pertempuran dapat diubah secara dinamis:
   - Kecepatan 1x (normal, misal 1.0 detik/fase)
   - Kecepatan 2x (cepat, misal 0.5 detik/fase)
   - Kecepatan 4x (sangat cepat, misal 0.25 detik/fase)
6. Player dapat mengirimkan abstraksi intent perintah komandan (HOLD, ADVANCE, RETREAT, PROTECT, FOCUS, FOLLOW).
7. Hasil pertempuran (*Battle Result DTO*) dikembalikan secara utuh dan deterministik.
8. Korban serdadu (*casualties*) diterapkan dan memotong populasi secara permanen.
9. Kerusakan benteng (*fortress damage*) diterapkan pada HP benteng persisten.
10. Hasil kelangsungan hidup/kematian hero (*hero survival/death*) diterapkan pada model hero.
11. Pertempuran dapat berakhir secara bersih tanpa *infinite loop*.
12. Sesi permainan berpindah secara sah ke state `RESULT`.

### 8.2 Representasi Visual Prototipe:
- Menggunakan visual teks telemetri sederhana (CanvasLayer dengan label log status per fase).
- Dilarang membuat sprite animasi, battlefield grid, atau efek partikel tempur pada tahap ini.

---

## 9. Wave Preview

Konsep "Scout / Scouting System" **DIHAPUS SEPENUHNYA** dari Phase 3. Player langsung menerima informasi pratinjau gelombang (**Wave Preview / Threat Preview**).

### Informasi Minimal pada Wave Preview:
1. **Wave Number**: Nomor gelombang yang akan dihadapi (misal: Wave 3 / 100).
2. **Arrival Time / Interval**: Indikasi gelombang telah tiba di gerbang benteng.
3. **Threat / Difficulty Budget**: Total poin ancaman gelombang (dihitung oleh `WaveGenerator.calculate_threat_budget`).
4. **Enemy Types & Estimated Quantities**: Rincian komposisi musuh berdasarkan archetype Phase 2:
   - `MINION`: Pasukan kecil pengganggu.
   - `RAIDER`: Pasukan penyerang cepat.
   - `BRUTE`: Pasukan berdaya tahan tinggi.
   - `FLYER`: Pasukan udara yang memotong langsung ke benteng.
   - `SIEGE`: Mesin pengepung tembok.
   - `BOSS`: Pemimpin ancaman besar (hadir setiap kelipatan 10 wave).
5. **Special Traits / Warnings**: Penanda gelombang khusus (misal: "Boss Wave Detected", "High Flyer Concentration").

---

## 10. Recovery Prototype (Post-Battle Orchestration / Integration Proof)

Fase Recovery pada Phase 3 dirancang secara ketat sebagai **Post-Battle Orchestration / Integration Proof**, BUKAN implementasi sistem manajemen baru.

Tujuannya adalah membuktikan bahwa konsekuensi pertempuran dapat dialirkan kembali ke state domain secara tertib melalui koordinasi sistem Phase 2 yang sudah ada:
$$\text{Battle} \rightarrow \text{Result} \rightarrow \text{Recovery} \rightarrow \text{Preparation} \rightarrow \text{Next Wave}$$

### 10.1 Alur Orkestrasi Recovery:
1. **Konsekuensi Pertempuran Dihasilkan di Result**: Evaluasi `CombatEngine` menghasilkan DTO hasil pertempuran (damage benteng, korban serdadu gugur, equipment wear/loss, hero survival, loot emas).
2. **Aplikasi ke Domain State**: Konsekuensi tersebut diaplikasikan langsung ke instance domain models (`FortressModel`, `PopulationModel`, `HeroModel`, `EquipmentModel`).
3. **Pemanggilan `EconomyManager` Existing**: `EconomyManager.process_cycle(population, fortress)` dipanggil untuk memproses siklus rutin upkeep militer/sipil dan reparasi benteng sesuai ketersediaan kas.
4. **Reparasi via Repair Worker Phase 2**:
   $$\text{Worker} + \text{Repair Job} + \text{Material/Budget} + \text{Duration} \rightarrow \text{Fortress HP Recovery}$$
   Reparasi benteng HANYA mengandalkan alokasi pekerja pada tugas `REPAIR` yang telah ditetapkan sejak Phase 2. Tidak ada formula atau sistem reparasi baru.
5. **Aplikasi Loot Pertempuran**: Loot emas dari pertempuran ditambahkan ke bendahara sebagai sumber pendapatan ekonomi utama (tanpa pendapatan pasif).
6. **Kontinuitas ke Gelombang Berikutnya**: Setelah seluruh pemrosesan recovery selesai dan benteng masih bertahan ($HP > 0$), state bertransisi kembali ke `PREPARATION` gelombang berikutnya ($Wave = Wave + 1$).
7. **Pemisahan Tegas dari Keruntuhan Benteng**: Jika Fortress $HP \le 0$ pada evaluasi pertempuran, game bertransisi langsung dari `RESULT` ke `GAME_OVER`. Fase Recovery **TIDAK PERNAH DIJALANKAN** saat benteng hancur, memastikan tidak ada recovery loop yang secara tidak sengaja menghidupkan kembali benteng yang telah runtuh.

### 10.2 Batasan Hero Recovery dan Pertumbuhan Populasi (Orchestration Only):
Source code Phase 2 telah memiliki fungsi bawaan:
- `HeroModel.rest(recovery_amount)`: Pemulihan fatigue hero yang tidak bertarung.
- `PopulationModel.grow_population(growth_rate)`: Pertumbuhan alami warga sipil jika kapasitas hunian mencukupi.

**Batasan Mutlak Phase 3**:
- Phase 3 **TIDAK MENGEMBANGKAN ATAU MEMPERLUAS** mekanisme-mekanisme tersebut.
- Keberadaan fungsi existing ini dipertahankan, dan Phase 3 **HANYA MENGORKESTRASIKAN PEMANGGILAN BEHAVIOR EXISTING** tersebut demi menjaga kontinuitas state antar-gelombang.
- **DILARANG MEMBUAT**:
  - Formula fatigue recovery baru.
  - Formula pertumbuhan populasi baru.
  - Balancing atau re-tuning ekonomi baru.
  - UI manajemen detail untuk hero recovery atau demografi.
- Prinsip utama: **Existing Phase 2 Behavior $\rightarrow$ Dipanggil/Diorgestrasikan oleh Phase 3**, bukan Phase 3 menciptakan behavior management baru.

### 10.3 Larangan Penambahan Sub-Sistem Manajemen Baru:
Pada Phase 3, secara tegas **DILARANG MEMBUAT**:
- Formula reparasi benteng baru di luar Phase 2.
- Sistem ekonomi atau sumber mata uang baru di luar kas bendahara emas.
- Sistem manajemen populasi atau penugasan tenaga kerja mendalam (*detailed workforce management*).
- Sistem manajemen fasilitas benteng (*facility/room management*).
- Sistem manajemen inventaris sumber daya material (*resource/warehouse inventory management*).
Seluruh perluasan sistem manajemen tersebut ditunda ke fase-fase berikutnya sesuai roadmap (Phase 4 untuk Hero System, Phase 5 untuk Fortress Management, Phase 7 untuk Economy).

---

## 11. Debug Telemetry

Phase 3 menyediakan modul telemetri debug teks yang ringan dan dapat dinyalakan/dimatikan (*toggable*).

### Data Telemetri yang Ditampilkan:
- **Current State**: Nama state aktif (BOOT, PREPARATION, WAVE_PREVIEW, BATTLE, RESULT, RECOVERY, GAME_OVER).
- **Current Wave**: Nomor gelombang saat ini dan total gelombang target.
- **Battle Status & Speed**: Status pertempuran (Idle / Running / Paused) dan kecepatan aktif (1x, 2x, 4x).
- **Fortress Status**: HP saat ini / HP maksimum, nilai Armor, dan status integritas.
- **Enemy Composition**: Sisa musuh aktif per archetype (Minion, Raider, Brute, Flyer, Siege, Boss).
- **Soldier Casualties**: Jumlah korban prajurit gugur per peran pada gelombang terakhir.
- **Hero Roster Status**: Level, EXP, Fatigue (0–100), Morale, dan status hidup/mati (*Alive/Dead*).
- **Equipment & Warehouse**: Kuantitas perlengkapan gudang per peran dan rata-rata durabilitas.
- **Economy Balance**: Kas bendahara saat ini, estimasi pengeluaran gaji/upkeep, dan biaya reparasi.
- **Last Commander Command**: Perintah komandan terakhir yang dikirimkan player.

> [!NOTE]
> Telemetri ini adalah alat bantu pengujian bagi developer, bukan sistem analitik data atau backend telemetry server.

---

## 12. Save / Load Boundary

Phase 3 **TIDAK MENGIMPLEMENTASIKAN SAVE/LOAD PENUH KE DISK**. Phase 3 hanya mendefinisikan batas arsitektur (*Persistence Boundary*).

```text
Game State (Runtime) ──> GameStateSnapshot (Plain DTO) ──> SaveSnapshotDto (schema_version = 1)
```

- `GameStateSnapshot` menyediakan fungsi `to_dictionary()` dan `from_dictionary()` yang serializable.
- `SaveSnapshotDto` dari Phase 1 digunakan sebagai penjaga schema version.
- Implementasi penyimpanan ke disk (file I/O, binary serialization, enkripsi) secara penuh **DITUNDA KE PHASE 10**.

---

## 13. Testing Plan

Rencana pengujian Phase 3 mencakup verifikasi headless otomatis menyeluruh:

### 13.1 State Transition Tests (`test_gameplay_prototype.gd`):
- Menguji seluruh transisi sah:
  - `BOOT` $\rightarrow$ `PREPARATION`
  - `PREPARATION` $\rightarrow$ `WAVE_PREVIEW`
  - `WAVE_PREVIEW` $\rightarrow$ `BATTLE`
  - `BATTLE` $\rightarrow$ `RESULT`
  - `RESULT` $\rightarrow$ `RECOVERY`
  - `RECOVERY` $\rightarrow$ `PREPARATION` (wave bertambah $+1$)
  - `RESULT` $\rightarrow$ `GAME_OVER` (saat Fortress $HP \le 0$)
- Menguji penolakan keras terhadap transisi ilegal (misal: `PREPARATION` langsung lompat ke `BATTLE`, atau `GAME_OVER` lompat ke `PREPARATION`).

### 13.2 Command Abstraction Tests:
- Memverifikasi bahwa seluruh 6 perintah komandan dapat direpresentasikan secara valid:
  `HOLD`, `ADVANCE`, `RETREAT`, `PROTECT`, `FOCUS`, `FOLLOW`.
- Memastikan pengiriman command tidak merusak state simulasi atau memicu crash runtime.

### 13.3 Integration Tests:
- Memvalidasi loop utuh:
  $$\text{Player Input} \rightarrow \text{Coordinator} \rightarrow \text{Phase 2 Simulation} \rightarrow \text{Result} \rightarrow \text{State Update}$$
- Menjalankan 5 gelombang berturut-turut untuk memastikan kontinuitas state antar-gelombang tanpa kebocoran memori atau reset state mendadak.

### 13.4 Regression Tests (Zero Regression Guarantee):
- `tests/test_architecture_boundaries.gd` (Phase 1): Wajib **5 PASSED, 0 FAILED**.
- `tests/test_mathematical_prototype.gd` (Phase 2): Wajib **21 PASSED, 0 FAILED**.

---

## 14. Performance Constraints (Low-End Hardware)

Target hardware pengembangan dan rilis adalah perangkat berspesifikasi rendah:
- RAM: 4 GB
- CPU: Intel Celeron / Pentium / Dual-Core Mobile
- Target OS: Android & Windows Dev Environment

### Batasan Arsitektur & Kinerja:
- **Aggregate Simulation Only**: Pasukan serdadu disimulasikan sebagai kuantitas agregat di domain state. Dilarang menginstansiasi Node terpisah untuk setiap prajurit.
- **Zero Real-Time Enemy Nodes**: Ratusan musuh disimulasikan sebagai counter ancaman numerik di `CombatEngine`, bukan Node karakter individual.
- **Zero Per-Frame Logic Polling**: Dilarang meletakkan logika kalkulasi atau state check di dalam loop `_process(delta)`. Seluruh pembaruan UI murni digerakkan oleh event sinyal `state_changed`.
- **Minimal Node Hierarchy**: Scene prototipe hanya terdiri dari node kontrol dasar tanpa hierarki bersarang yang berat.
- **Deterministic Headless Ready**: Seluruh logika game dapat dijalankan tanpa window rendering.

---

## 15. Scope Boundary

| Fitur / Komponen | IN SCOPE (Phase 3) | OUT OF SCOPE (Fase Berikutnya) |
| :--- | :---: | :---: |
| **Gameplay State Machine** | Ya (Boot s/d Game Over) | - |
| **GameCoordinator Orchestration** | Ya (Application layer) | - |
| **Preparation & Worker Allocation** | Ya (Model Phase 2) | Sistem room/building mendalam (Phase 5) |
| **Wave Preview & Threat Display** | Ya (Threat & enemy counts) | Sistem intelijen/scouting terpisah |
| **Battle Simulation Execution** | Ya (CombatEngine Phase 2) | Formula battle power baru |
| **Battle Speed & Pause Control** | Ya (Pause, 1x, 2x, 4x) | - |
| **Commander Command Abstraction** | Ya (6 Intent DTOs) | Tactical AI & formasi mendalam (Phase 6) |
| **Result & Recovery Loop** | Ya (Post-battle result application, existing economy cycle orchestration, existing Repair Worker behavior, existing loot application, state continuity ke persiapan berikutnya) | Advanced economy, facility management, detailed workforce management, advanced population simulation, advanced hero recovery, formula reparasi baru, formula ekonomi baru, sistem resource baru |
| **Debug Telemetry HUD** | Ya (Label teks murni) | UI/HUD artistik final (Phase 9) |
| **Unit & Integration Tests** | Ya (Headless suite) | - |
| **Visual Art, Sprite, & Animasi** | **TIDAK** | Pixel art, VFX, animasi (Phase 9) |
| **Audio, SFX, & Musik** | **TIDAK** | Sound design & music (Phase 7–8) |
| **Disk Save / Load Persistence** | **TIDAK** | File I/O & binary storage (Phase 10) |

---

## 16. Planned Files

### 16.1 Files Planned to Change (Extending Existing):
1. `scripts/domain/state/game_state_snapshot.gd`:
   - Memperluas penampung data domain (fortress, population, heroes, warehouse, economy, wave, phase).
   - Menjaga backward compatibility penuh terhadap schema Phase 1.
2. `scripts/application/coordinators/game_coordinator.gd`:
   - Mengintegrasikan `GameplayStateMachine` dan engine simulasi Phase 2.
   - Menambahkan API penerima command dari presentation layer.
3. `scripts/simulation/simulation_runner.gd`:
   - Mengorkestrasi pemanggilan `WaveGenerator`, `CombatEngine`, dan `EconomyManager`.

### 16.2 Files Planned to Add (New Minimal Files):
1. `scripts/application/state_machine/gameplay_state_machine.gd`: Modul pengatur transisi state game.
2. `scripts/domain/command/commander_command.gd`: Kelas DTO intent perintah komandan (HOLD, ADVANCE, RETREAT, PROTECT, FOCUS, FOLLOW).
3. `scripts/presentation/controllers/game_controller.gd`: Controller penerima input keyboard/tombol UI dan pengatur timer simulasi battle.
4. `scripts/presentation/views/prototype_debug_view.gd`: Script render dashboard teks telemetri.
5. `scenes/prototype/main_prototype.tscn`: Scene prototipe minimal di Godot.
6. `tests/test_gameplay_prototype.gd`: Test suite otomatis untuk validasi Phase 3.

---

## 17. Acceptance Criteria

Implementasi Phase 3 hanya dapat dinyatakan selesai jika seluruh checklist berikut terpenuhi:

- [ ] Project Godot dapat memuat dan menjalankan `main_prototype.tscn` tanpa error atau peringatan kebocoran memori.
- [ ] Fase `PREPARATION` berfungsi: alokasi pekerja dan rekrutmen serdadu mematuhi batas populasi sipil secara zero-sum.
- [ ] Fase `WAVE_PREVIEW` berfungsi: menyajikan pratinjau ancaman musuh berikutnya secara akurat tanpa konsep scout.
- [ ] Fase `BATTLE` mengeksekusi simulasi pertempuran menggunakan `CombatEngine` Phase 2 tanpa duplikasi logika.
- [ ] Kontrol pertempuran berfungsi lancar: Pause, Resume, Kecepatan 1x, Kecepatan 2x, dan Kecepatan 4x.
- [ ] Keenam perintah komandan (`HOLD`, `ADVANCE`, `RETREAT`, `PROTECT`, `FOCUS`, `FOLLOW`) dapat dikirimkan ke coordinator dan dicatat pada telemetri.
- [ ] Hasil pertempuran (`RESULT`) dilaporkan dan memutasi state benteng, populasi, dan hero secara tepat.
- [ ] Evaluasi terminal di `RESULT`: jika Fortress $HP \le 0$, game langsung masuk ke `GAME_OVER` tanpa melewati Recovery (tidak ada recovery loop yang secara tidak sengaja menghidupkan kembali benteng yang sudah hancur).
- [ ] Fase `RECOVERY` murni mengorkestrasi sistem Phase 2 yang ada (`EconomyManager`, `FortressModel`, `PopulationModel`): mengaplikasikan loot battle, memotong upkeep rutin, mereparasi benteng via Repair Worker existing, dan memanggil existing rest/growth behavior tanpa formula ekonomi/reparasi/manajemen baru.
- [ ] State dapat kembali ke `PREPARATION` untuk gelombang berikutnya setelah recovery selesai (kontinuitas state terjaga, indeks wave bertambah +1).
- [ ] Tidak ada pembuatan `CombatEngine` baru, duplikasi formula, atau refactor terhadap archetype musuh Phase 2.
- [ ] Seluruh test Phase 1 tetap lulus (**5/5 PASSED, 0 FAILED**).
- [ ] Seluruh test Phase 2 tetap lulus (**21/21 PASSED, 0 FAILED**).
- [ ] Seluruh test Phase 3 yang baru dibuat lulus (**100% PASSED**).
- [ ] Performa prototipe tetap ringan dan responsif pada target spesifikasi hardware rendah.

---

## 18. Risks & Mitigation

| Potensi Risiko | Dampak | Strategi Mitigasi |
| :--- | :--- | :--- |
| **State Desynchronization** | Data di UI tidak mencerminkan data aktual di domain state. | UI dilarang keras menyimpan state lokal. UI murni me-render salinan `GameStateSnapshot` yang dipancarkan via sinyal `state_changed`. |
| **Scope Creep ke Fitur Visual** | Waktu terbuang untuk grafis alih-alih memvalidasi loop gameplay. | Dilarang keras membuat sprite, tekstur, atau animasi di Phase 3. Tampilan murni menggunakan node `Label` dan `Button` bawaan Godot. |
| **Duplikasi Logika Simulasi** | Terjadi inkonsistensi formula pertempuran antara Phase 2 dan Phase 3. | `GameCoordinator` dan `SimulationRunner` diwajibkan memanggil class Phase 2 (`CombatEngine`, `EconomyManager`, `WaveGenerator`) secara langsung. |
| **Beban Kinerja pada CPU Lemah** | Frame drop atau stutter pada hardware development Intel Celeron. | Gunakan simulasi agregat serdadu (tanpa instansiasi node unit individual), dan hilangkan loop polling pada `_process`. |
| **Kerusakan Backward Compatibility** | Test arsitektur Phase 1 gagal karena perubahan snapshot. | Semua field Phase 1 pada `GameStateSnapshot` tetap dipertahankan dan diuji dengan test regresi. |

---

## 19. Explicit Phase 4 & Phase 6 Deferrals

Untuk menjaga batasan pengembangan tetap ramping dan terarah, fitur-fitur berikut secara eksplisit ditunda:

### Ditunda ke Phase 4 (Hero System):
- Sistem rekrutmen hero kompleks (Tavern / Gacha / Hero Market).
- Pohon bakat hero (*Hero Talent Trees*), equipment khusus hero, dan sistem skill aktif/pasif hero.
- Hubungan chemistry lanjutan dan dialog antar-hero.
- UI manajemen hero mendalam.

### Ditunda ke Phase 6 (Tactical Battle & Battlefield Systems):
- Formula combat lanjutan untuk keenam perintah komandan (efek taktis detail HOLD, ADVANCE, RETREAT, PROTECT, FOCUS, FOLLOW).
- Pembagian zona medan tempur (Frontline, Midfield, Walls, Backline).
- AI musuh taktis, formasi tempur serdadu, dan penargetan dinamis.
- Pergerakan unit real-time dan pathfinding di medan laga.
- Battle visual scene dan combat HUD interaktif.
