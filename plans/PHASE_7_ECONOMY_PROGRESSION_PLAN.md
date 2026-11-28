# Technical Architecture & Implementation Plan — Phase 7: Economy & Progression

Dokumen ini adalah cetak biru teknis (*technical architecture plan*) resmi untuk implementasi **Phase 7 — Economy & Progression** pada proyek **fortress_game**.
Dokumen ini disusun sebelum penulisan kode apa pun untuk Phase 7, mematuhi prinsip kehati-hatian (*Inspect Before Modify* dan *Extend, Don't Break*), dan menjadi rujukan otoritatif bagi seluruh sub-fase Phase 7.

---

## 1. Tujuan & Filosofi Desain Phase 7

Phase 7 bertujuan membangun sistem **ekonomi dan progresi benteng** yang kohesif, deterministik, terukur, dan terintegrasi secara mulus dengan sistem-sistem yang telah selesai dan diverifikasi:
- **Phase 1–2**: Core Architecture, Event Bus, Game State Machine, Mathematical Engine.
- **Phase 3**: Soldier Allocation, Shared Warehouse Conservation, Equipment Resolution.
- **Phase 4**: Hero Model, Lifecycle, Stars/Ascension, Talents, Chemistry, Party Management.
- **Phase 5**: Fortress Defense (Gate/Wall/Fortress HP), Population Accounting, Worker Model, 9 Building Models, Repair & Construction Tasks.
- **Phase 6**: Tactical Battle 7 Zones, 6 Enemy Archetypes, Pacing Controls, Formations & Auras, Commander Commands, Damage Routing, Casualty Resolution.

### Filosofi Inti: "Fortress Management Simulator"
1. **Extend, Don't Break**: Memperluas kontrak dan model yang sudah ada tanpa membuat subsystem paralel atau menduplikasi kepemilikan data (*no duplicate inventory, no second gold storage, no shadow economy*).
2. **Single Source of Truth**: Seluruh kas bendahara dan perbendaharaan material benteng dikelola di bawah satu otoritas domain yang dikoordinasikan oleh `GameCoordinator`.
3. **No Infinite Passive Income**: Pendapatan emas utama diperoleh secara aktif melalui **Battle Victory Loot** dan perdagangan jarahan monster. Tidak ada tambang pasif otomatis tanpa biaya risiko.
4. **Conservation & Zero-Sum Accounting**: Seluruh aliran sumber daya mematuhi invarian kekekalan: pendapatan masuk, pengeluaran keluar, dan sisa kas selalu dapat diaudit secara matematis ($Kas_{t+1} = Kas_t + Pendapatan - Pengeluaran$).
5. **Deterministic & Testable**: Seluruh kurva hadiah, perputaran stok pedagang, dan degradasi biaya diatur oleh seed sesi (`session_seed + current_wave`), menjamin reproducibility 100% pada unit test dan stress test.
6. **Controlled Inflation & Bankruptcy Prevention**: Mencegah *economic death spiral* melalui mekanisme amortisasi, denda moral, atau penundaan perbaikan saat kas menipis tanpa membuat simulasi macet (*crash*).

---

## 2. Audit Komprehensif Basis Kode Eksisting (Phase 1–6)

Sebelum merancang sistem ekonomi Phase 7, audit menyeluruh terhadap kode domain, simulasi, aplikasi, dan presentasi telah dilakukan:

| Sub-Sistem / Parameter | Nilai / Formula Eksisting | Lokasi Berkas | Kategori Status | Tindakan Phase 7 |
| :--- | :--- | :--- | :--- | :--- |
| **Initial Treasury Gold** | `150 Gold` | `scripts/simulation/economy_manager.gd:14`, `scripts/application/coordinators/game_coordinator.gd:2192` | **Canonical Rule** | Dipertahankan sebagai modal awal sesi standar. |
| **Hero Recruitment Cost** | `500 Gold` mutlak | `scripts/application/coordinators/game_coordinator.gd:34` (`HERO_RECRUITMENT_COST_DEFAULT`) | **Canonical Rule** | Dipertahankan mutlak. Wajib divalidasi atomik via kas. |
| **Hero Ascension Cost** | `current_star * 150 Gold` (150, 300, 450, 600) | `scripts/domain/model/hero_model.gd:321` (`get_ascension_cost`) | **Canonical Rule** | Dipertahankan mutlak. Terintegrasi ke perbendaharaan. |
| **Hero Training** | 40 EXP, 15 Fatigue, `0 Gold` | `scripts/domain/model/hero_model.gd:407` (`train`) | **Prototype Placeholder** | Dipertahankan basis gratis fatigue; biaya fasilitas training opsional/tiering. |
| **Structure Repair Cost** | $\lceil \text{HP} \times 0.15 \rceil \text{ Gold}$ ($0.15 \text{ Gold/HP}$) | `scripts/application/coordinators/game_coordinator.gd:2064`, `scripts/simulation/economy_manager.gd:23` | **Canonical Rule** | Dipertahankan. Mengharuskan `repair_workers > 0`. |
| **Equipment Repair Cost** | $\lceil \text{Missing} \times \text{CostPerPoint} \times (1 - \text{Discount}) \times \text{Count} \rceil$ | `scripts/domain/model/equipment_model.gd:61` | **Canonical Rule** | Dipertahankan (Tier 1: 0.20, T2: 0.50, T3: 1.10, T4: 2.20, T5: 4.50). |
| **Blacksmith Discount** | $\min(0.60, \text{smith\_workers} \times 0.12)$ | `scripts/simulation/economy_manager.gd:72` | **Canonical Rule** | Dipertahankan. Hingga $60\%$ diskon biaya reparasi equipment. |
| **Construction Cost** | Default parameter `50 Gold` | `scripts/application/coordinators/game_coordinator.gd:2127` | **Prototype Placeholder** | **Distandarisasi** ke tabel/formula biaya upgrade gedung kanonikal. |
| **Civilian Upkeep** | `civilians * 3 Gold` | `scripts/simulation/economy_manager.gd:83` | **Canonical Rule** | Dipertahankan saat siklus recovery. |
| **Soldier Salaries** | `SWORDSMAN: 5`, `SHIELD: 6`, `SPEARMAN: 5`, `ARCHER: 6`, `HEAVY: 10` | `scripts/simulation/economy_manager.gd:25` | **Canonical Rule** | Dipertahankan saat siklus recovery. |
| **Mercenary Salary** | `18 Gold` per tentara bayaran | `scripts/simulation/economy_manager.gd:32` | **Canonical Rule** | Dipertahankan saat siklus recovery. |
| **Battle Loot Gold** | $\lfloor \text{threat\_budget} \times 1.30 \rfloor$ (hanya saat Victory) | `scripts/simulation/combat_engine.gd:768` | **Canonical Rule** | Dipertahankan sebagai basis; diperluas dengan drop core/material. |
| **Defeat Loot Gold** | `0 Gold` | `scripts/simulation/combat_engine.gd:765` | **Canonical Rule** | Dipertahankan mutlak. Kekalahan tidak memberikan jarahan emas. |
| **Game Over State** | Transisi ke `GAME_OVER`, ekonomi dibekukan | `scripts/application/coordinators/game_coordinator.gd:1817` | **Canonical Rule** | Dipertahankan mutlak. Mutasi ekonomi ditolak saat Game Over. |
| **Shared Warehouse** | Single shared array `EquipmentModel` | `scripts/application/coordinators/game_coordinator.gd:48` | **Canonical Rule** | Tidak boleh dibuat inventory/warehouse kedua. |

---

## 3. Arsitektur Otoritas & Aliran Data

### Pola Kepemilikan Tunggal (Single Authority)
```
                    ┌─────────────────────────┐
                    │   PrototypeDebugView    │ (Presentation / UI)
                    └────────────┬────────────┘
                                 │ Memanggil Command / Action
                                 ▼
                    ┌─────────────────────────┐
                    │     GameController      │ (API Wrapper / Controller)
                    └────────────┬────────────┘
                                 │ Mendelegasikan Transaksi
                                 ▼
                    ┌─────────────────────────┐
                    │     GameCoordinator     │ (Single Central Authority)
                    └────────────┬────────────┘
         ┌───────────────────────┼────────────────────────┐
         ▼                       ▼                        ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   EconomyState   │    │   CombatEngine   │    │  Warehouse / Wh  │
│  (Resource Pool) │    │  (Battle Result) │    │ (Equipment/Items)│
└────────┬─────────┘    └────────┬─────────┘    └──────────────────┘
         │                       │
         └───────────┬───────────┘
                     │ Menyusun Read-Model Terisolasi
                     ▼
        ┌─────────────────────────┐
        │    GameStateSnapshot    │ (Immutable DTO Snapshot)
        └────────────┬────────────┘
                     │ Dipancarkan via signal state_changed(snapshot)
                     ▼
        ┌─────────────────────────┐
        │   PrototypeDebugView    │ (Re-render in-place)
        └─────────────────────────┘
```

### Aturan Kepemilikan & Larangan Keras:
1. **Dilarang membuat `EconomyManagerV2`, `BattleEconomyEngine`, `ResourceController`, atau `SecondaryWarehouse`**.
2. **Satu-satunya sumber kebenaran saldo kas dan material** adalah komponen ekonomi terpadu yang dipimpin oleh `GameCoordinator`.
3. **Simulasi pertempuran (`CombatEngine`) tidak boleh memutasi kas langsung**. `CombatEngine` hanya menghasilkan kontrak data DTO `BattleResult` (misal: `loot_gold`, `loot_cores`, `loot_materials`).
4. **Penyelesaian Ekonomi (`Settlement`)** dilakukan secara aman dan atomik oleh `GameCoordinator` pada fase `RECOVERY`.

---

## 4. Spesifikasi 5 Sumber Daya Kanonikal

Untuk menjaga kompleksitas tetap terfokus dan menghindari *bloat* sistem RPG yang berlebihan (*No 30+ Resources*), Phase 7 menetapkan **tepat 5 kategori sumber daya**:

```
                              ┌─────────────────────────┐
                              │     PERBENDAHARAAN      │
                              │     BENTENG (ASSETS)    │
                              └────────────┬────────────┘
             ┌─────────────────────────────┼─────────────────────────────┐
             ▼                             ▼                             ▼
   ┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
   │     1. GOLD      │          │ 2. MONSTER CORE  │          │3. MONSTER MATS   │
   │   (Mata Uang)    │          │  (Inti Monster)  │          │  (Bahan Monster) │
   └─────────┬────────┘          └─────────┬────────┘          └─────────┬────────┘
             │                             │                             │
             │ Belanja / Upkeep            │ Dijual ke Merchant          │ Dilebur Pandai Besi
             ▼                             ▼                             ▼
   ┌──────────────────┐          ┌──────────────────────────────────────────────┐
   │ Operasional &    │          │            MERCHANT / PASOKAN PASAR          │
   │ Infrastruktur    │          └──────────────────────┬───────────────────────┘
   └──────────────────┘                                 │
                                   ┌────────────────────┴────────────────────┐
                                   ▼                                         ▼
                         ┌──────────────────┐                      ┌──────────────────┐
                         │4. BASIC MATERIAL │                      │ 5. RARE MATERIAL │
                         │ (Kayu/Batu/Besi) │                      │(Mithril/Kristal) │
                         └──────────────────┘                      └──────────────────┘
```

### A. 1. Gold (Emas)
- **Peran**: Mata uang universal benteng.
- **Sumber Utama**: Battle Victory Loot, penjualan Monster Core/Material ke Merchant.
- **Penggunaan Utama**:
  - Gaji warga sipil & serdadu (Upkeep).
  - Biaya reparasi fisik (Benteng, Dinding, Gerbang).
  - Biaya reparasi perlengkapan di Pandai Besi.
  - Rekrutmen pahlawan (500 Gold) & serdadu.
  - Ascension pahlawan (`current_star * 150 Gold`).
  - Biaya pembangunan/upgrade fasilitas benteng.
  - Pembelian bahan baku dari Merchant.

### B. 2. Monster Core (Inti Monster)
- **Peran**: Harta jarahan berharga tinggi dari monster elit/pemimpin gelombang.
- **Sumber**: Diperoleh dari pertempuran gelombang yang memiliki musuh berbobot berat (`TROLL_TANK`, `SIEGE_MONSTER`, `BOSS`).
- **Penggunaan**:
  - Dijual ke Merchant untuk mendapatkan suntikan Emas dalam jumlah besar (*liquid asset*).
  - Digunakan sebagai katalisator ascension pahlawan bintang tinggi (Bintang 4 $\rightarrow$ 5).
  - Anchor upgrade fasilitas tingkat tinggi (Level 4 $\rightarrow$ 5).

### C. 3. Monster Material (Bahan Baku Monster)
- **Peran**: Sisa-sisa bagian tubuh monster penyerang (taring goblin, kulit orc, lempeng chitin).
- **Sumber**: Drop deterministik pertempuran berdasarkan jumlah serdadu musuh yang dikalahkan.
- **Penggunaan**:
  - Dijual ke Merchant untuk mendapatkan Emas reguler.
  - Digunakan di Pandai Besi untuk menaikkan Tier perlengkapan (*Equipment Forging/Upgrading* Tier 1 $\rightarrow$ Tier 2/3).

### D. 4. Basic Merchant Material (Bahan Bangunan Standar)
- **Peran**: Komoditas logistik esensial (misal: *Lumber & Quarried Stone*).
- **Sumber**: Dibeli dari Merchant menggunakan Emas, atau reward minor pertempuran.
- **Penggunaan**:
  - Syarat material untuk proyek konstruksi dan peningkatan level gedung (Level 1 $\rightarrow$ 3).
  - Bahan pendukung perbaikan besar struktur benteng.

### E. 5. Rare Merchant Material (Material Langka)
- **Peran**: Komoditas perdagangan eksotis berharga tinggi (misal: *Enchanted Ingot & Refined Crystal*).
- **Sumber**: Dibeli terbatas dari Merchant rotasi berkala, atau jarahan bos pertempuran kelipatan 10 wave.
- **Penggunaan**:
  - Syarat material upgrade gedung tingkat lanjut (Level 4 $\rightarrow$ 5).
  - Bahan peningkatan perlengkapan ke Tier 4 dan Tier 5.

---

## 5. Reward Loop & Kontrak Penyelesaian Pertempuran

Alur pertukaran sumber daya dari pertempuran menuju ekonomi benteng dirancang secara ketat tanpa jeda desinkronisasi:

```
[BATTLE SELESAI]
       │
       ▼
[Kompilasi BattleResult] (CombatEngine)
       │ - victory: bool
       │ - loot_gold: int
       │ - loot_monster_cores: int
       │ - loot_monster_materials: int
       │ - casualties & equipment loss
       ▼
[Penyelesaian Transisi RESULT -> RECOVERY] (GameCoordinator)
       │
       ├─► 1. Verifikasi Status Kemenangan:
       │      • VICTORY: Kreditkan loot_gold, cores, materials ke EconomyState.
       │      • DEFEAT / BREACH: loot_gold = 0, no cores, reduced scrap materials.
       │      • GAME_OVER: Pembekuan mutlak seluruh mutasi ekonomi.
       │
       ├─► 2. Pemulihan & Korban Pasukan:
       │      • Kurangi populasi serdadu gugur secara zero-sum.
       │      • Kembalikan gear survivor 100% usable ke Warehouse.
       │      • Resolusi gear korban: 35% musnah, 65% rusak masuk stok Damaged.
       │      • Kembalikan gear pahlawan permadeath tepat 1x ke Warehouse.
       │
       ├─► 3. Siklus Beban Operasional Benteng (Upkeep & Salaries):
       │      • Potong gaji sipil: civilians * 3 Gold.
       │      • Potong gaji serdadu: count * role_salary.
       │      • Eksekusi reparasi otomatis jika ada pekerja Repair.
       │      • Jika kas < biaya upkeep: Picu defisit kas (Moral penalti, bukan crash).
       │
       └─► 4. Transisi ke PREPARATION (Wave + 1):
              • Buka interaksi Merchant, Pandai Besi, Rekrutmen, dan Konstruksi.
```

### Formula Reward Pertempuran Deterministik:
1. **Gold Loot**:
   $$\text{Loot Gold} = \begin{cases} \lfloor \text{Threat Budget} \times 1.30 \rfloor + \text{Bonus Boss}, & \text{jika Victory} \\ 0, & \text{jika Defeat} \end{cases}$$
2. **Monster Core Loot**:
   $$\text{Monster Cores} = \begin{cases} \lfloor \text{Boss Count} \times 1 \rfloor + (\text{Threat Budget} \ge 200 \text{ ? } 1 : 0), & \text{jika Victory} \\ 0, & \text{jika Defeat} \end{cases}$$
3. **Monster Material Loot**:
   $$\text{Monster Materials} = \begin{cases} \lfloor \text{Enemy Casualties} \times 0.40 \rfloor, & \text{jika Victory} \\ \lfloor \text{Enemy Casualties} \times 0.15 \rfloor, & \text{jika Defeat} \end{cases}$$

---

## 6. Model Pengeluaran (*Resource Sinks*) & Neraca Biaya

Seluruh biaya dan pengeluaran benteng diatur dalam konfigurasi terpusat agar seimbang dan mudah disesuaikan:

```
Total Pengeluaran Benteng = Upkeep Warga + Upkeep Serdadu + Biaya Reparasi + Biaya Rekrutmen + Biaya Konstruksi + Biaya Dagang
```

### A. Neraca Operasional (Setiap Siklus Recovery)
- **Gaji Warga Sipil**: $3 \text{ Gold}$ per warga sipil hidup.
- **Gaji Serdadu Reguler**:
  - `SWORDSMAN`: $5 \text{ Gold}$
  - `SHIELD_INFANTRY`: $6 \text{ Gold}$
  - `SPEARMAN`: $5 \text{ Gold}$
  - `ARCHER`: $6 \text{ Gold}$
  - `HEAVY_INFANTRY`: $10 \text{ Gold}$
- **Gaji Tentara Bayaran (`Mercenary`)**: $18 \text{ Gold}$ per tentara.
- **Aturan Kas Defisit (Grace Period / Penalti Moral)**:
  - Jika kas bendahara tidak mencukupi untuk membayar upah penuh, kas dijepit di $0 \text{ Gold}$ (`maxi(0, treasury_gold)`).
  - Selisih upah yang tidak terbayar mengurangi moral populasi benteng:
    $$\Delta \text{Morale} = -\min(25, \lceil \text{Unpaid Gold} / 10 \rceil)$$
  - Penurunan moral mereduksi produktivitas pekerja benteng ($0.50$ s/d $1.25$) tanpa merusak state machine.

### B. Neraca Pemeliharaan Fisik (On-Demand & Auto)
- **Reparasi Struktur (Benteng, Tembok, Gerbang)**:
  $$\text{Biaya Emas} = \lceil \text{HP Direparasi} \times 0.15 \rceil \text{ Gold}$$
  Memerlukan alokasi `repair_workers > 0`.
- **Reparasi Perlengkapan Pandai Besi**:
  $$\text{Biaya Emas} = \lceil \text{Missing Durability} \times \text{CostPerTier} \times (1.0 - \text{Blacksmith Discount}) \times \text{Kuantitas} \rceil$$
  Diskon Pandai Besi: $\text{clampf}(\text{blacksmith\_workers} \times 0.12, 0.0, 0.60)$.

### C. Neraca Rekrutmen & Pengembangan Pahlawan
- **Rekrutmen Pahlawan**: $500 \text{ Gold}$ per pahlawan baru di Mercenary Guild.
- **Ascension Bintang Pahlawan**:
  - Bintang $1 \rightarrow 2$: $150 \text{ Gold}$
  - Bintang $2 \rightarrow 3$: $300 \text{ Gold}$
  - Bintang $3 \rightarrow 4$: $450 \text{ Gold}$ + 1 Monster Core
  - Bintang $4 \rightarrow 5$: $600 \text{ Gold}$ + 2 Monster Core + 1 Rare Material
- **Latihan Pahlawan (Training Facility)**:
  - Latihan reguler: $0 \text{ Gold}$ (biaya 15 Fatigue, +40 EXP).
  - Latihan intensif berbayar (Fasilitas Level 2+): $30 \text{ Gold}$ (biaya 25 Fatigue, +100 EXP).

### D. Neraca Konstruksi & Peningkatan Fasilitas (Level 1 $\rightarrow$ 5)
Standarisasi biaya peningkatan 9 gedung benteng:

| Target Level | Kebutuhan Tenaga Kerja | Biaya Emas | Kebutuhan Material | Target Progres Tick |
| :---: | :---: | :---: | :---: | :---: |
| **Level 2** | $\ge 1$ Konstruksi | $75 \text{ Gold}$ | 10 Basic Material | 100 |
| **Level 3** | $\ge 2$ Konstruksi | $160 \text{ Gold}$ | 25 Basic Material | 180 |
| **Level 4** | $\ge 2$ Konstruksi | $320 \text{ Gold}$ | 50 Basic Material + 2 Monster Core | 280 |
| **Level 5** | $\ge 3$ Konstruksi | $600 \text{ Gold}$ | 100 Basic Material + 5 Monster Core + 2 Rare Material | 400 |

*Catatan: Pembatalan konstruksi mengembalikan $100\%$ Emas dan Material yang belum terpakai.*

---

## 7. Sistem Pedagang Sederhana (*Supply Depot & Wandering Merchant*)

Untuk menyediakan saluran pertukaran material tanpa membuat sistem marketplace yang rumit, dirancang sistem pedagang sederhana berbasis rotasi deterministik:

### Fitur Pedagang:
1. **Ukuran Stok Terbatas**: Tepat 4–6 slot penawaran per gelombang.
2. **Kategori Penawaran**:
   - **Beli dari Pedagang**: Basic Material, Rare Material, Perlengkapan Tier 1–2 (jika stok gudang menipis).
   - **Jual ke Pedagang**: Monster Core ($80 \text{ Gold}$ per unit), Monster Material ($5 \text{ Gold}$ per unit).
3. **Penyegaran Stok Deterministik**:
   - Stok pedagang diperbarui otomatis setiap kali memasuki fase `PREPARATION` gelombang baru menggunakan seed deterministik:
     $$\text{Merchant Seed} = \text{session\_seed} \times 31 + \text{current\_wave} \times 101$$
   - Opsi penyegaran manual (*Reroll Stock*): Biaya $25 \text{ Gold}$.
4. **Isolasi Transaksi**: Transaksi bersifat atomik seketika. Pembelian memotong Emas kas dan menambahkan material/item ke inventaris; penjualan memotong material dan menambahkan Emas ke kas bendahara.

---

## 8. Integrasi Progresi Benteng (*Progression Vectors*)

Sistem progresi terikat langsung pada level fasilitas benteng (Level 1–5):

1. **Benteng Utama (`FORTRESS`)**:
   - Peningkatan level menaikkan Max HP benteng (+250 HP/level, dasar 1000) dan Zirah benteng (+10 Armor/level, dasar 40).
2. **Tembok Pertahanan (`WALL`)**:
   - Peningkatan level menaikkan Max HP Tembok (+150 HP/level, dasar 500) dan batas absorpsi benturan.
3. **Gerbang Utama (`GATE`)**:
   - Peningkatan level menaikkan Max HP Gerbang (+100 HP/level, dasar 300) dan efisiensi pertahanan gerbang.
4. **Barak Militer (`BARRACKS`)**:
   - Level 1: Kapasitas serdadu 10.
   - Level 2: Kapasitas serdadu 18 (+8).
   - Level 3: Kapasitas serdadu 28 (+10).
   - Level 4: Kapasitas serdadu 40 (+12).
   - Level 5: Kapasitas serdadu 55 (+15).
5. **Pandai Besi (`BLACKSMITH`)**:
   - Peningkatan level membuka kemampuan menempa perlengkapan Tier lebih tinggi dan meningkatkan efisiensi diskon reparasi.
6. **Gudang Senjata (`WAREHOUSE`)**:
   - Peningkatan level memperluas batas kapasitas inventaris material dan perlengkapan.
7. **Fasilitas Latihan (`TRAINING_FACILITY`)**:
   - Peningkatan level membuka opsi pelatihan intensif pahlawan dan mempercepat pemulihan kelelahan (*fatigue recovery*).
8. **Guild Tentara Bayaran (`MERCENARY_GUILD`)**:
   - Peningkatan level meningkatkan jumlah kandidat rekrutmen pahlawan dan membuka perekrutan tentara bayaran elit.

---

## 9. Rencana Pemecahan Sub-Fase (Sub-Phase Breakdown)

Untuk memastikan implementasi terisolasi, aman, dan dapat diverifikasi bertahap, Phase 7 dipecah menjadi **7 sub-fase terstruktur**:

```
[Phase 7A: Resource Authority & Economy Domain Model]
                     │
                     ▼
[Phase 7B: Battle Reward Settlement & Loot Engine]
                     │
                     ▼
[Phase 7C: Expense Normalization & Dynamic Sink Reconciliation]
                     │
                     ▼
[Phase 7D: Merchant & Supply Depot System]
                     │
                     ▼
[Phase 7E: Fortress & Hero Progression Economy]
                     │
                     ▼
[Phase 7F: Economy & Merchant UX Integration]
                     │
                     ▼
[Phase 7G: Full Economy Verification & Phase 7 Exit Gate]
```

---

### Sub-Phase 7A: Resource Authority & Economy Domain Model
- **Tujuan**: Membangun model domain perbendaharaan terpadu (`ResourceLedger` / penyempurnaan `EconomyManager`) yang menjadi *single source of truth* untuk 5 sumber daya (Gold, Monster Core, Monster Material, Basic Material, Rare Material), serta integrasi snapshot serialisasi.
- **Scope**:
  - Model domain sumber daya, validasi nilai $\ge 0$, pencegahan mutasi langsung tanpa otorisasi.
  - Integrasi metode penambahan (`credit`), pemotongan atomik (`debit`), dan pengecekan kecukupan (`has_sufficient`).
  - Pemeliharaan backward compatibility untuk API eksisting: `get_treasury_gold()`, `set_treasury_gold()`.
  - Serialisasi mendalam pada `GameStateSnapshot.economy_data` dan field inventaris material.
- **Berkas yang Berubah**:
  - `scripts/domain/model/resource_ledger.gd` (Model baru) atau penyempurnaan `scripts/simulation/economy_manager.gd`.
  - `scripts/application/coordinators/game_coordinator.gd`.
  - `scripts/domain/state/game_state_snapshot.gd`.
- **Existing API yang Digunakan**: `get_treasury_gold()`, `set_treasury_gold()`, `_update_snapshot()`.
- **Formula**:
  $$\text{Balance}_{t+1} = \text{Balance}_t + \Delta, \quad \text{Constraint: } \text{Balance} \ge 0$$
- **UI**: Belum ada perubahan visual (domain & snapshot only).
- **Test Plan**: Minimal 20 tests memvalidasi penambahan, pemotongan, penolakan defisit, deep-copy snapshot, dan determinisme kloning.
- **Risiko**: Risiko regresi pada pemanggilan eksisting `_economy.treasury_gold`. Mitigasi: buat alias getter/setter transparan.
- **Tingkat Kesulitan**: 3 / 10.
- **Dependensi**: Tidak ada (fondasi pertama).
- **Explicit Out-of-Scope**: Tidak membuat UI pedagang, tidak mengubah formula battle.

---

### Sub-Phase 7B: Battle Reward Settlement & Loot Engine
- **Tujuan**: Memformalkan kontrak DTO `BattleResult` untuk jarahan Emas, Monster Core, dan Monster Material, serta mengintegrasikan eksekusi kredit jarahan pada transisi `RESULT -> RECOVERY` di `GameCoordinator`.
- **Scope**:
  - Ekstensi kalkulasi hadiah pada `CombatEngine` berdasarkan `threat_budget`, nomor gelombang, arketipe musuh gugur, dan status bos.
  - Aturan mutlak: $0$ loot gold dan $0$ monster core saat kekalahan (`is_victory == false`).
  - Pembekuan total mutasi jarahan saat status `GAME_OVER`.
  - Eksekusi penambahan ke `ResourceLedger` di `GameCoordinator.proceed_from_result()`.
- **Berkas yang Berubah**:
  - `scripts/simulation/combat_engine.gd`.
  - `scripts/application/coordinators/game_coordinator.gd`.
  - `scripts/presentation/controllers/game_controller.gd`.
- **Existing API yang Digunakan**: `execute_battle()`, `proceed_from_result()`, `_last_battle_result`.
- **Formula**:
  - Loot Emas: $\lfloor \text{Threat Budget} \times 1.30 \rfloor + \text{Boss Bonus}$.
  - Monster Core: $\lfloor \text{Boss Count} \times 1 \rfloor + (\text{Threat} \ge 200 \text{ ? } 1 : 0)$.
  - Monster Material: $\lfloor \text{Casualties} \times 0.40 \rfloor$ saat Victory; $\lfloor \text{Casualties} \times 0.15 \rfloor$ saat Defeat.
- **UI**: Telemetri hadiah terbaca di `_lbl_result_body` pada `PrototypeDebugView`.
- **Test Plan**: Minimal 20 tests memvalidasi kalkulasi hadiah berbagai gelombang, isolasi kekalahan, pembekuan game over, dan konsistensi kredit kas.
- **Risiko**: Inflasi pendapatan berlebihan pada gelombang tinggi. Mitigasi: kurva pangkat threat budget dibatasi.
- **Tingkat Kesulitan**: 4 / 10.
- **Dependensi**: Sub-Phase 7A.
- **Explicit Out-of-Scope**: Tidak mengubah mekanika tempur fisik, tidak mengubah damage routing Phase 6.

---

### Sub-Phase 7C: Expense Normalization & Dynamic Sink Reconciliation
- **Tujuan**: Menstandarisasi seluruh titik pengeluaran kas (Gaji/Upkeep, Reparasi Fisik, Reparasi Equipment, Rekrutmen Pahlawan, Ascension) ke dalam transaksi atomik terpadu dan menangani kondisi defisit kas secara elegan tanpa crash.
- **Scope**:
  - Penegasan siklus pemotongan upah sipil, serdadu, dan tentara bayaran di `process_cycle()`.
  - Integrasi penalti moral proporsional jika kas tidak mencukupi untuk upah penuh tanpa menyebabkan kas bernilai negatif.
  - Validasi ketat saldo sebelum eksekusi reparasi benteng ($0.15 \text{ Gold/HP}$) dan perlengkapan pandai besi.
  - Penegakan biaya rekrutmen pahlawan kanonikal ($500 \text{ Gold}$) dan ascension (`current_star * 150 Gold`).
- **Berkas yang Berubah**:
  - `scripts/simulation/economy_manager.gd` / `ResourceLedger`.
  - `scripts/application/coordinators/game_coordinator.gd`.
- **Existing API yang Digunakan**: `process_cycle()`, `repair_structure()`, `repair_equipment()`, `recruit_hero()`, `ascend_hero()`.
- **Formula**:
  $$\text{Deficit Penalty} = -\min(25, \lceil \text{Unpaid Gold} / 10 \rceil \text{ Morale})$$
- **UI**: Banner umpan balik penolakan aksi jika dana tidak mencukupi.
- **Test Plan**: Minimal 20 tests memvalidasi seluruh sink biaya, penolakan transaksi saat dana kurang, rollback kegagalan, dan resolusi defisit upah.
- **Risiko**: Kebuntuan ekonomi (*economic deadlock*). Mitigasi: berikan diskon pekerja pandai besi dan batas bawah moral $30$.
- **Tingkat Kesulitan**: 4 / 10.
- **Dependensi**: Sub-Phase 7A, 7B.
- **Explicit Out-of-Scope**: Tidak mengubah rumus durabilitas equipment Phase 3.

---

### Sub-Phase 7D: Merchant & Supply Depot System
- **Tujuan**: Mengimplementasikan model pedagang sederhana (`MerchantModel`) dengan penawaran slot terbatas, rotasi stok berbasis gelombang dan seed deterministik, serta transaksi jual/beli material atomik.
- **Scope**:
  - Model domain `MerchantModel` dengan 4–6 slot penawaran.
  - Penjualan Monster Core ($80 \text{ Gold}$) dan Monster Material ($5 \text{ Gold}$) ke pedagang.
  - Pembelian Basic Material ($15 \text{ Gold}$) dan Rare Material ($120 \text{ Gold}$) dari pedagang.
  - Penyegaran stok otomatis per gelombang dan penyegaran manual berbayar ($25 \text{ Gold}$).
  - API koordinasi di `GameCoordinator` dan controller di `GameController`.
- **Berkas yang Berubah**:
  - `scripts/domain/model/merchant_model.gd` (Berkas baru).
  - `scripts/application/coordinators/game_coordinator.gd`.
  - `scripts/presentation/controllers/game_controller.gd`.
  - `scripts/domain/state/game_state_snapshot.gd`.
- **Existing API yang Digunakan**: `_state_machine.current_state`, `_update_snapshot()`.
- **Formula**:
  $$\text{Seed Pedagang} = \text{session\_seed} \times 31 + \text{current\_wave} \times 101$$
- **UI**: Integrasi data pedagang ke snapshot untuk konsumsi UI.
- **Test Plan**: Minimal 20 tests memvalidasi pembelian, penjualan, batas stok, validasi dana, determinisme rotasi, dan pembatalan transaksi.
- **Risiko**: Eksploitasi arbitrase jual-beli (*infinite money glitch*). Mitigasi: harga beli selalu lebih tinggi dari harga jual bahan sejenis.
- **Tingkat Kesulitan**: 5 / 10.
- **Dependensi**: Sub-Phase 7A, 7C.
- **Explicit Out-of-Scope**: Tidak membuat UI toko interaktif kompleks atau sistem lelang.

---

### Sub-Phase 7E: Fortress & Hero Progression Economy
- **Tujuan**: Menghubungkan ekonomi sumber daya dengan sistem peningkatan fasilitas benteng (Level 1–5), pembukaan kapasitas serdadu/gudang, penempaan tingkat perlengkapan, dan katalisator ascension pahlawan bintang tinggi.
- **Scope**:
  - Menghubungkan konstruksi bangunan dengan konsumsi Emas dan Material (Basic/Rare/Cores) sesuai tabel progresi Level 1–5.
  - Dampak fungsional peningkatan level gedung:
    - Barak: peningkatan kapasitas serdadu maksimum.
    - Gudang: peningkatan kapasitas simpan inventaris.
    - Pandai Besi: peningkatan efisiensi reparasi dan pembukaan resep forging perlengkapan.
    - Benteng/Tembok/Gerbang: penambahan Max HP dan pertahanan.
  - Penggunaan Monster Core dan Rare Material pada syarat ascension pahlawan bintang 4 dan 5.
- **Berkas yang Berubah**:
  - `scripts/domain/model/building_model.gd`.
  - `scripts/application/coordinators/game_coordinator.gd`.
  - `scripts/presentation/controllers/game_controller.gd`.
- **Existing API yang Digunakan**: `start_construction()`, `advance_construction()`, `can_start_construction()`, `ascend_hero()`.
- **Formula**: Tabel biaya bertingkat Level 1 s/d Level 5 sesuai Bab 6.D.
- **UI**: Data persyaratan material ditampilkan pada DTO snapshot.
- **Test Plan**: Minimal 20 tests memvalidasi konsumsi material konstruksi, peningkatan kapasitas barak, pembukaan tier, dan refund pembatalan proyek.
- **Risiko**: Desinkronisasi antara alokasi pekerja konstruksi dan pemotongan material. Mitigasi: pemotongan atomik saat proyek dimulai.
- **Tingkat Kesulitan**: 5 / 10.
- **Dependensi**: Sub-Phase 7A, 7C, 7D.
- **Explicit Out-of-Scope**: Tidak membuat skill tree bercabang atau animasi konstruksi.

---

### Sub-Phase 7F: Economy & Merchant UX Integration
- **Tujuan**: Mengintegrasikan seluruh visualisasi data ekonomi, perbendaharaan material, panel interaksi pedagang, dan dialog upgrade fasilitas ke dalam antarmuka prototipe fungsional `PrototypeDebugView` secara responsif, in-place, dan ramah sentuhan mobile ($\ge 44 \times 44$ px).
- **Scope**:
  - Penambahan kartu Ringkasan Perbendaharaan Benteng (*Fortress Treasury & Material Ledger*): Emas, Monster Core, Monster Material, Basic Material, Rare Material.
  - Penambahan panel Merchant sederhana pada kolom aksi fase `PREPARATION`: daftar penawaran stok barang, tombol Beli/Jual, dan tombol Reroll stok.
  - Tampilan perincian pengeluaran berkala (*Upkeep Telemetry*): estimasi upah sipil, serdadu, dan pemeliharaan per gelombang.
  - Dialog informasi biaya dan kebutuhan material pada tombol upgrade fasilitas benteng.
  - Penegakan target sentuh minimum $\ge 44 \times 44$ px pada seluruh tombol ekonomi baru.
  - Pembaruan in-place tanpa merekonstruksi seluruh container UI secara destruktif.
- **Berkas yang Berubah**:
  - `scripts/presentation/views/prototype_debug_view.gd`.
  - `scripts/presentation/controllers/game_controller.gd`.
- **Existing API yang Digunakan**: `_on_state_changed()`, `_render_stage_actions()`, `controller.setup()`.
- **UI**: Widget Label, Button, dan OptionButton terintegrasi di `PrototypeDebugView`.
- **Test Plan**: Minimal 20 tests memvalidasi visibilitas kartu perbendaharaan, klik tombol beli/jual pedagang, banner umpan balik dana tidak cukup, pembaruan in-place, dan ukuran tombol $\ge 44 \times 44$ px.
- **Risiko**: Kerusakan layout tata letak kolom wireframe Phase 5. Mitigasi: letakkan kartu ekonomi di scroll container kiri dan aksi pedagang di tab aksi tengah.
- **Tingkat Kesulitan**: 4 / 10.
- **Dependensi**: Sub-Phase 7A s/d 7E.
- **Explicit Out-of-Scope**: Tidak mengimplementasikan pixel art, animasi koin berhamburan, atau visual polish (milik Phase 9).

---

### Sub-Phase 7G: Full Economy Verification & Phase 7 Exit Gate
- **Tujuan**: Menjalankan pengujian regresi menyeluruh, verifikasi integritas invarian konservasi 100%, simulasi stres ekonomi 50 gelombang, playtest smoke interaktif, serta penutupan resmi Phase 7.
- **Scope**:
  - Eksekusi suite pengujian komprehensif Phase 7 (`tests/test_phase7_economy_progression.gd`) dengan target $\ge 100$ tests.
  - Simulasi stres deterministik 50 gelombang (*50-Wave Economic Simulation Stress Test*): memvalidasi tidak ada kas bernilai negatif, tidak ada inflasi eksponensial liar, dan tidak ada kebocoran memori.
  - Menjalankan Full Automated Regression Suite (seluruh 24 suite eksisting + suite Phase 7 = 25 suites) dengan hasil $100\%$ PASS tanpa satu pun kegagalan.
  - Menjalankan Scene Smoke Playtest pada `main_prototype.tscn`.
  - Pembaruan dokumentasi resmi (`CURRENT_PHASE.md`, `CHANGELOG.md`, `ROADMAP.md`).
- **Berkas yang Berubah**:
  - `tests/test_phase7_economy_progression.gd` (Berkas baru).
  - `plans/CURRENT_PHASE.md`.
  - `plans/CHANGELOG.md`.
  - `plans/ROADMAP.md`.
- **Existing API yang Digunakan**: Seluruh API Phase 1–7.
- **Test Plan**: $\ge 100$ tests Phase 7, 50-wave simulation test, 25 regression suites PASS.
- **Tingkat Kesulitan**: 4 / 10.
- **Dependensi**: Sub-Phase 7A s/d 7F.
- **Explicit Out-of-Scope**: Tidak memulai Phase 8.

---

## 10. Ringkasan Tingkat Kesulitan & Peta Ketergantungan

| Sub-Fase | Nama Sub-Fase | Tingkat Kesulitan (1–10) | Dependensi Utama | Estimasi Target Tests |
| :---: | :--- | :---: | :--- | :---: |
| **7A** | Resource Authority & Economy Domain Model | 3 / 10 | Tidak ada (Fondasi) | 20 tests |
| **7B** | Battle Reward Settlement & Loot Engine | 4 / 10 | 7A | 20 tests |
| **7C** | Expense Normalization & Dynamic Sinks | 4 / 10 | 7A, 7B | 20 tests |
| **7D** | Merchant & Supply Depot System | 5 / 10 | 7A, 7C | 20 tests |
| **7E** | Fortress & Hero Progression Economy | 5 / 10 | 7A, 7C, 7D | 20 tests |
| **7F** | Economy & Merchant UX Integration | 4 / 10 | 7A, 7B, 7C, 7D, 7E | 20 tests |
| **7G** | Full Verification & Exit Gate | 4 / 10 | 7A s/d 7F | 100+ tests |

```
Peta Ketergantungan:
7A ──► 7B ──► 7C ──► 7D ──► 7E ──► 7F ──► 7G (Gate)
```

---

## 11. Target Pengujian & Kriteria Keberhasilan (*Acceptance Criteria*)

### Target Pengujian:
- **Suite Pengujian Phase 7**: Minimal **100 tests** PASS $100\%$ pada `tests/test_phase7_economy_progression.gd`.
- **Simulasi Stres Ekonomi 50 Gelombang**: Memvalidasi perputaran ekonomi selama 50 gelombang pertempuran berturut-turut tanpa saldo negatif, tanpa dividen tak terhingga, dan invarian konservasi terjaga $100\%$.
- **Full Regression Suite**: 25 test suites ($\ge 1.077$ tests) PASS $100\%$ tanpa regresi.
- **Prototype Scene Smoke Playtest**: PASS dengan 0 error pada Godot SceneTree.

### Kriteria Keberhasilan (Acceptance Criteria):
1. [ ] Seluruh 5 sumber daya kanonikal (Gold, Monster Core, Monster Material, Basic Material, Rare Material) memiliki satu sumber kebenaran data tanpa duplikasi.
2. [ ] Hadiah pertempuran (Emas, Core, Material) terkreditkan secara presisi hanya saat status Victory, dan bernilai 0 saat Defeat.
3. [ ] Siklus pemotongan upah (sipil, serdadu, tentara bayaran) berjalan konsisten pada transisi Recovery, dengan penalti moral terukur saat kas mengalami defisit.
4. [ ] Seluruh titik pengeluaran (rekrutmen hero 500 gold, ascension, reparasi benteng $0.15 \text{ Gold/HP}$, reparasi perlengkapan, konstruksi) mematuhi validasi saldo atomik.
5. [ ] Merchant berfungsi deterministik dengan batasan stok, harga beli/jual seimbang tanpa arbitrase tak terbatas, dan penyegaran per gelombang.
6. [ ] Peningkatan fasilitas benteng Level 1–5 terhubung dengan konsumsi Emas dan Material yang terbukti mengurangi saldo secara atomik.
7. [ ] UI menampilkan perbendaharaan dan kontrol perdagangan pedagang secara fungsional dengan ukuran tombol sentuh mobile $\ge 44 \times 44$ px.
8. [ ] Seluruh mutasi ekonomi terbukti dibekukan (*locked*) saat fase `BATTLE` dan terminal `GAME_OVER`.
9. [ ] Suite pengujian Phase 7 ($\ge 100$ tests) lulus $100\%$.
10. [ ] Full Automated Regression Suite lulus $100\%$ dengan 0 regresi.

---

## 12. Analisis Risiko & Strategi Mitigasi

| Risiko Potensial | Dampak | Probabilitas | Strategi Mitigasi Arsitektur |
| :--- | :---: | :---: | :--- |
| **1. Runaway Inflation (Hiperinflasi)** | Tinggi | Sedang | Batasi pengganda loot per gelombang dengan kurva logaritmik/pangkat teredam; seimbangkan dengan kenaikan upah serdadu dan biaya material bangunan bertingkat. |
| **2. Bankruptcy Death Spiral (Kebuntuan Kas)** | Kritis | Sedang | Jangan biarkan kas menjadi negatif. Jika kas tidak cukup untuk upah, terapkan denda moral penurunan produktivitas alih-alih merusak alur permainan. Pemain selalu bisa menjual Monster Material untuk mendapatkan Emas darurat. |
| **3. Duplikasi Sumber Daya / Shadow Inventory** | Kritis | Rendah | Tegakkan kepemilikan tunggal di bawah `GameCoordinator`. Merchant tidak memiliki gudang fisik terpisah; pembelian langsung masuk ke perbendaharaan benteng. |
| **4. Arbitrase Dagang Tak Terbatas** | Tinggi | Rendah | Terapkan spread harga jual-beli yang ketat (misal: harga beli material $15 \text{ Gold}$, harga jual ke pedagang $5 \text{ Gold}$). |
| **5. Pelanggaran Batas Visual Phase 9** | Sedang | Rendah | Tegakkan larangan implementasi aset pixel art, efek partikel koin, atau animasi UI final di Phase 7. Seluruh UI Phase 7 wajib menggunakan kontrol standar Godot Engine. |

---

## 13. Konfirmasi Status Fase & Aturan Penghentian Mutlak (*Hard Stop Rule*)

### Status Fase Proyek:
- **Phase 0–6**: **COMPLETED / CLOSED**
- **Phase 7 — Economy & Progression**: **PLANNED / READY FOR IMPLEMENTATION** (Menunggu persetujuan eksplisit developer)
- **Phase 8 — Content Implementation**: **LOCKED**
- **Phase 9 — Visual / UI / Pixel Art Integration**: **LOCKED**
- **Phase 10 — Save/Load, Mobile Optimization & Polish**: **LOCKED**

> [!CAUTION]
> **EXPLICIT PHASE GATE & HARD STOP RULE**:
> Dokumen ini adalah dokumen perencanaan arsitektur murni (**PLANNING DOCUMENT ONLY**).
> **DILARANG KERAS**:
> - Mengimplementasikan kode atau skrip domain, aplikasi, simulasi, atau UI apa pun.
> - Mengubah `GameCoordinator.gd`, `CombatEngine.gd`, `EconomyManager.gd`, atau `PrototypeDebugView.gd`.
> - Memulai sub-fase 7A sebelum developer memberikan instruksi dan persetujuan eksplisit.
>
> Pekerjaan berhenti total (*HARD STOP*) setelah komitmen dokumen perencanaan ini.
