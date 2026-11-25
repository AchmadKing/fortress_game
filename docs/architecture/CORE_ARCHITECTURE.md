# Core Game Architecture — Fortress Game

**Status**: PROPOSED (Architecture Discovery & Technical Design)  
**Target Platform**: Mobile (Android) — Lightweight, Battery-Friendly  
**Development Environment**: PC (Windows / Godot Engine 4.x / VS Code / Antigravity AI)

> [!IMPORTANT]
> Dokumen ini adalah rancangan arsitektur tingkat tinggi (*Architecture Proposal*). Seluruh keputusan teknis berstatus `PROPOSED` dan belum dikunci. Implementasi skrip, scene, maupun gameplay DILARANG dimulai sebelum dokumen ini direview dan disetujui secara eksplisit oleh developer.

---

## 1. Architecture Goals

Arsitektur inti game dirancang untuk memenuhi sasaran berikut:

1. **Lightweight & High Performance**: Meminimalkan beban CPU, alokasi memori dinamis (GC overhead), dan konsumsi baterai pada perangkat mobile Android.
2. **Decoupled Architecture**: Memisahkan secara tegas antara logika game/simulasi dengan layer visual/presentasi (UI, sprite, particle, sound).
3. **Deterministic & Testable Simulation**: Logika simulasi (kalkulasi damage, wave, stat) dapat dijalankan dan diuji secara independen tanpa ketergantungan pada rendering frame atau scene tree.
4. **Data-Driven & Extensible**: Penambahan konten (hero, tower, monster, wave) dilakukan melalui konfigurasi data terstruktur tanpa perlu mengubah kode inti logika.
5. **No Premature Over-Engineering**: Menghindari kompleksitas framework berat (seperti ECS skala penuh atau dependency injection container rumit) yang tidak proporsional untuk proyek mobile 2D.

---

## 2. System Boundaries

Arsitektur dibagi ke dalam 5 lapisan (*layers*) dengan batas tanggung jawab (*boundary*) yang tegas:

```text
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION / UI                      │
│   (HUD, Screens, Dialogs, HealthBars, Floating Text, VFX)   │
└──────────────────────────────┬──────────────────────────────┘
                               │  (Observes State / Sends Commands)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    GAMEPLAY LOGIC & SYSTEMS                 │
│  (GameCoordinator, FortressSystem, WaveSystem, HeroSystem)  │
└──────────────────────────────┬──────────────────────────────┘
                               │  (Executes Simulation / Mutates Data)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      SIMULATION LAYER                       │
│    (DamageCalculator, StatFormulas, TickScheduler, Rules)   │
└──────────────────────────────┬──────────────────────────────┘
                               │  (Operates On)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN DATA MODELS                     │
│    (FortressData, HeroData, WaveData, EconomyData, Items)   │
└──────────────────────────────┬──────────────────────────────┘
                               ▲
                               │  (Serializes / Deserializes)
┌──────────────────────────────┴──────────────────────────────┐
│                  PERSISTENCE & INFRASTRUCTURE               │
│     (SaveManager, FileIO, DeviceSettings, AudioAdapter)     │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Responsibility Tiap Sistem

| Layer / Sistem | Tanggung Jawab Utama | Hal yang Dilarang |
| :--- | :--- | :--- |
| **Presentation / UI** | Menerima input sentuhan pemain, merender visual benteng, unit, dan UI, memutar animasi/suara, menampilkan angka damage. | Menyimpan state otoritatif, menghitung formula damage, mengubah data ekonomi secara langsung. |
| **Gameplay Systems** | Mengorkestrasi aturan main: mengontrol flow wave, memvalidasi perintah upgrade benteng/hero, memicu aksi combat. | Mengakses langsung node UI spesifik, memuat visual texture atau aset grafis. |
| **Simulation Layer** | Menyediakan fungsi kalkulasi murni (*pure mathematical functions*): formula armor/damage, kalkulasi stat multiplier, tick timing. | Menyimpan referensi Node, mengakses SceneTree, melakukan I/O file. |
| **Domain Data** | Merepresentasikan kondisi data game (*game state snapshot*), nilai HP, level, inventori, konfigurasi stat unit. | Memiliki logika rendering, memiliki dependensi ke scene visual. |
| **Persistence / Storage** | Menyimpan dan memuat snapshot state ke penyimpanan lokal perangkat (save/load), mengelola migrasi format data. | Memanipulasi state aktif tanpa melalui sistem yang berwenang. |

---

## 4. Data Flow

Prinsip aliran data yang diusulkan adalah **Unidirectional Data Flow**:

```text
[Pemain] 
   │ Input (Touch / Click)
   ▼
[Presentation / UI Controller]
   │ Request Command (e.g., UpgradeFacility, DeployHero)
   ▼
[Gameplay System]
   │ Validate Rules & Cost
   ▼
[Simulation / Data Mutation]
   │ Mutate Domain State Snapshot
   ▼
[State Notification / Signals]
   │ Notify changes (e.g., on_health_changed, on_resource_updated)
   ▼
[Presentation / UI View]
   │ Reactive Redraw (Update Text, Play VFX/SFX)
   ▼
[Pemain Melihat Feedback Visual]
```

- **Aturan Otoritas**: UI tidak pernah mengubah state langsung. UI hanya mengirimkan *Intent/Command* ke System.
- **Aturan Reaktif**: Visual diperbarui sebagai respons atas perubahan state melalui signal/event, bukan dengan polling di `_process` setiap frame.

---

## 5. Core Game State & Lifecycle

Siklus hidup aplikasi (*Game Lifecycle*) dikelola secara terstruktur:

1. **Bootstrapping**: Inisialisasi engine, pembacaan konfigurasi dasar perangkat/resolusi.
2. **Main Menu State**: Menunggu input pemain, opsi pengaturan (audio, bahasa).
3. **Save Loading State**: Memvalidasi integritas save file, menginisialisasi domain data.
4. **Active Stage / Loop State**:
   - **Preparation / Management Phase**: Pemain mengatur fasilitas benteng, upgrade, dan komposisi tim/hero.
   - **Wave / Combat Phase**: Wave musuh bergerak, simulasi combat aktif, kalkulasi benteng & unit.
   - **Stage Resolution Phase**: Kondisi kemenangan (*Victory*) atau kekalahan (*Defeat* / Benteng runtuh).
5. **Mobile Lifecycle Handling**:
   - `NOTIFICATION_APPLICATION_PAUSED` / `FOCUS_OUT`: Otomatis menjeda game, menyimpan progres sementara jika diperlukan.
   - `NOTIFICATION_APPLICATION_RESUMED`: Mengembalikan konteks game.

---

## 6. Domain Data vs Presentation/UI

Untuk memastikan modularitas dan kemudahan pengujian:

- **Domain Data**:
  - Berisi atribut numerik murni, string ID, enum tipe, dan flag status (misal: `current_hp: int`, `max_hp: int`, `level: int`).
  - Tidak memiliki dependensi ke node Godot seperti `Sprite2D`, `AnimationPlayer`, atau `AudioStreamPlayer2D`.
  - Berbentuk kelas data murni (`RefCounted` / `Resource` / Dictionary terstruktur).
- **Presentation / UI**:
  - Mengikat (*bind*) visual ke Domain Data melalui ID atau instance data.
  - Membaca data untuk menentukan tampilan, memancarkan signal saat pemain berinteraksi.

---

## 7. Simulation Boundary

Simulasi game (kalkulasi pertempuran, laju damage, kalkulasi wave):

- **Decoupled from Render Frame**: Logika simulasi tidak boleh bergantung pada fluktuasi frame rate rendering (`delta` pada `_process`).
- **Fixed Tick / Deterministic Approach**: Jika diperlukan simulasi kalkulasi kontinu, gunakan fixed delta (`_physics_process` atau tick internal) agar hasil simulasi konsisten di semua spesifikasi perangkat Android.
- **Headless Capable**: Formula simulasi harus dapat dijalankan dalam unit test tanpa perlu membuka scene atau merender window.

---

## 8. Save/Load Boundary (High-Level)

- **DTO / State Snapshot**: Data yang disimpan hanyalah *plain data* (ID benteng, level fasilitas, jumlah koin, progres wave tertinggi).
- **No Node Serialization**: Scene tree, node visual, atau objek runtime dinamis dilarang diserialisasi langsung ke disk.
- **Schema Versioning**: Format penyimpanan menyertakan field `version: int` untuk memudahkan migrasi data saat ada update versi game di masa mendatang.

---

## 9. Dependency Rules

1. **Upper layers may depend on Lower layers**: Presentation boleh mengenal System; System boleh mengenal Simulation & Domain Data.
2. **Lower layers MUST NOT depend on Upper layers**: Domain Data & Simulation DILARANG mengenal Presentation atau Scene Tree.
3. **No Circular Dependencies**: Sistem A tidak boleh saling memanggil langsung dengan Sistem B secara melingkar (*no tight mutual coupling*).

---

## 10. Extension Strategy

- Penambahan konten baru (tipe tower baru, tipe monster baru, variasi wave) dirancang berbasis data (*data-driven definitions*).
- Setiap entitas didefinisikan melalui ID unik dan data parameter, bukan dengan membuat puluhan skrip unik yang menduplikasi logika.

---

## 11. Lightweight & Mobile (Android) Considerations

1. **Memory Allocation**: Hindari instansiasi objek berulang kali dalam loop `_process` untuk mencegah lag akibat Garbage Collector / Memory Churn.
2. **Object Pooling (Proposed for Later)**: Untuk entitas yang sering muncul dan hancur (proyektil, monster, pop-up damage text), siapkan arsitektur yang mendukung pooling pada fase implementasi.
3. **Typed GDScript (GDScript 2.0)**: Wajib menggunakan *static typing* (`var health: int = 100`, `func take_damage(amount: int) -> void`). Ini memberikan performa eksekusi lebih cepat pada Godot 4 dan mengurangi error runtime.
4. **Draw Calls & Texture Atlases**: Arsitektur UI dan visual dipersiapkan agar ramah batching pada renderer mobile Godot.

---

## 12. Risks and Trade-offs

| Risiko | Dampak | Strategi Mitigasi |
| :--- | :--- | :--- |
| **Over-Engineering** | Waktu development lambat, kode sulit dibaca | Gunakan arsitektur seminimal mungkin yang memenuhi prinsip pemisahan data-view. Tolak framework eksternal yang tidak esensial. |
| **Coupling Acak di Godot** | Akses node dengan path string (`get_node("../../../")`) rapuh saat scene diubah | Larang penggunaan *hardcoded relative node paths*. Gunakan dependency injection sederhana atau signal. |
| **Performa Mobile Rendah** | Frame drop dan konsumsi baterai boros pada HP spek rendah | Utamakan typed GDScript, hindari loop berat di `_process`, batasi kalkulasi per frame. |

---

## 13. Keputusan Teknis yang Memerlukan Approval Developer

Berikut adalah daftar opsi teknis yang diajukan (**PROPOSED**) dan membutuhkan arahan/persetujuan developer:

### Keputusan 1: Service Coordination & System Access
- **Opsi A (Recommended)**: *Minimal Autoload Coordinators*. Menggunakan 1-2 Autoload esensial (misal: `GameManager` / `EventBus`) untuk orkestrasi global, sementara sistem spesifik di-attach pada scene aktif.
- **Opsi B**: *Pure Scene Tree Injection*. Tidak ada Autoload; semua dependensi dioper dari root scene ke child node secara eksplisit.
- **Trade-off**: Opsi A sangat praktis dan natural di Godot namun perlu dijaga agar tidak menjadi "God Object". Opsi B sangat bersih secara isolasi tetapi membutuhkan wiring manual yang lebih rumit saat scene berganti.

### Keputusan 2: Komunikasi Antar-Sistem
- **Opsi A (Recommended)**: *Hybrid Signals*. Gunakan signal langsung (*local signals*) untuk hubungan parent-child (misal UI widget ke container-nya), dan *Domain Event Bus* ringan untuk komunikasi antar sistem besar (misal Combat System mengabarkan Fortress System).
- **Opsi B**: *Pure Local Signals Only*. Semua komunikasi harus merambat melalui hierarki node tree.
- **Trade-off**: Opsi A mencegah *signal chaining* yang terlalu dalam dan rapuh melintasi banyak hierarki.

### Keputusan 3: Format Definisi Data Domain
- **Opsi A (Recommended)**: *Custom Godot Resources (`.tres`)*. Mendefinisikan class `Resource` khusus (misal: `HeroConfig`, `WaveConfig`). Sangat terintegrasi dengan Godot Editor GUI, memudahkan developer melakukan visual tuning parameter stat.
- **Opsi B**: *Pure GDScript Dictionaries / JSON*. Menggunakan data table berbasis file JSON atau dictionary GDScript.
- **Trade-off**: Opsi A memanfaatkan kekuatan native Godot 4 Inspector dan static typing, Opsi B lebih independen dari engine tetapi minim validasi editor.

---

> **STATUS: PROPOSED & AWAITING DEVELOPER REVIEW**  
> Tidak ada implementasi teknis yang dimulai sebelum developer memberikan persetujuan terhadap poin-poin keputusan di atas.
