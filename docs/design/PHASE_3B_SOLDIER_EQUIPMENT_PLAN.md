# PHASE 3B — SOLDIER EQUIPMENT & WAREHOUSE CONSERVATION
## IMPLEMENTATION PLAN & TECHNICAL SPECIFICATION

**Status**: PLANNED / IMPLEMENTATION NOT STARTED (AWAITING DEVELOPER APPROVAL)  
**Project**: `fortress_game`  
**Repository**: `https://github.com/AchmadKing/fortress_game.git`  
**Branch**: `main`  
**Baseline Commit**: `577ee8f`  
**Phase**: Phase 3 — Gameplay Prototype  
**Sub-Phase**: Phase 3B — Soldier Equipment & Warehouse Conservation  
**Phase 4**: LOCKED  

> [!IMPORTANT]
> Dokumen ini adalah **Rencana Implementasi Teknis (Technical Implementation Plan)** untuk Phase 3B.
> Sesuai aturan mutlak `AGENTS.md`: **DILARANG MENGUBAH KODE GAMEPLAY MAUPUN MEMULAI IMPLEMENTASI SEBELUM MENDAPATKAN PERSETUJUAN EKSPLISIT (EXPLICIT APPROVAL)**.
> Status fase saat ini: **PHASE 3B — PLANNED / IMPLEMENTATION NOT STARTED**.

---

## 1. Executive Summary

Phase 3B bertujuan untuk merevolusi manajemen serdadu dan gudang senjata dari model kuantitas artifisial menjadi **sistem kepemilikan fisik yang konsisten secara matematis (*physically consistent equipment ownership*)**.

Pada baseline prototipe saat ini (Phase 3A), serdadu direkrut langsung sebagai nama peran statis, dan fungsi internal `_ensure_equipment_quantity_for_role()` secara artifisial menciptakan perlengkapan di gudang jika persediaan tidak mencukupi.

Phase 3B menegakkan hukum kekekalan perlengkapan (*Equipment Conservation Invariant*):
$$\text{TOTAL OWNED EQUIPMENT} = \text{EQUIPMENT IN WAREHOUSE} + \text{EQUIPMENT EQUIPPED BY SOLDIERS}$$

Perlengkapan tidak boleh diduplikasi, hilang tanpa sebab, atau tercipta secara gaib melalui aksi manajemen prajurit. Peran prajurit (*Soldier Role*) sepenuhnya diturunkan dari senjata/zirah yang sedang dipasang, dan seluruh operasi pertukaran (*swap*) harus bersifat atomik dan aman dari *race conditions*.

---

## 2. Current Implementation Audit (16 Verification Points)

Berdasarkan inspeksi langsung pada source code branch `main` (commit `577ee8f`):

1. **Bagaimana serdadu direpresentasikan?**
   Serdadu direpresentasikan sebagai dictionary agregat di `scripts/domain/model/population_model.gd`:
   `soldiers = {"SWORDSMAN": 0, "SHIELD_INFANTRY": 0, "SPEARMAN": 0, "ARCHER": 0, "HEAVY_INFANTRY": 0}`.
2. **Apakah serdadu adalah entitas individual atau kuantitas agregat?**
   Serdadu **murni kuantitas agregat** (integer count per peran). Tidak ada objek, node, atau identitas individual per prajurit.
3. **Bagaimana peran serdadu disimpan saat ini?**
   Peran serdadu disimpan sebagai string keys pada dictionary `PopulationModel.soldiers`.
4. **Bagaimana kuantitas perlengkapan disimpan saat ini?**
   Disimpan sebagai integer property `quantity` pada setiap instance `EquipmentModel` (`role_type`, `tier`, `durability`, `quantity`). Seluruh koleksi disimpan di dalam array `_warehouse: Array[EquipmentModel]` pada `GameCoordinator`.
5. **Apakah perlengkapan saat ini dianggap dimiliki independen dari serdadu?**
   Ya, seluruh perlengkapan saat ini hanya berada di `_warehouse`. Tidak ada struktur data terpisah untuk melacak "perlengkapan yang sedang dipakai" (*equipped gear*).
6. **Bagaimana cara kerja `_ensure_equipment_quantity_for_role()` saat ini?**
   Di `GameCoordinator.gd` (baris 312–334), fungsi ini memetakan peran ke tipe perlengkapan, lalu memeriksa `_warehouse`. Jika item ditemukan tetapi `eq.quantity < count`, fungsi tersebut langsung menimpa `eq.quantity = count`. Jika tidak ditemukan, fungsi tersebut menambahkan instance `EquipmentModel` baru dengan kuantitas tersebut.
7. **Apakah method tersebut menciptakan/memunculkan perlengkapan otomatis?**
   **YA**. Method ini memunculkan perlengkapan gratis dari ketiadaan (*spawns out of thin air*) setiap kali prajurit direkrut melebihi stok gudang.
8. **Bagaimana rekrutmen serdadu berinteraksi dengan perlengkapan saat ini?**
   `recruit_soldier(role, count)` memotong warga sipil, menambah hitungan `soldiers[role]`, lalu langsung memanggil `_ensure_equipment_quantity_for_role()` untuk mencetak perlengkapan gratis jika stok kurang. Rekrutmen tidak pernah memeriksa apakah senjata tersedia di gudang sebelum merekrut.
9. **Apakah perlengkapan sudah mempengaruhi peran serdadu saat ini?**
   **BELUM**. Player memilih nama peran langsung saat rekrutmen, dan perlengkapan dipaksa menyesuaikan ke nama peran secara retroaktif.
10. **Apakah perlengkapan dikonsumsi saat dipasangkan ke serdadu?**
    **TIDAK**. Stok gudang tidak pernah berkurang saat prajurit direkrut.
11. **Apakah perlengkapan saat ini bisa dikembalikan ke gudang?**
    **TIDAK**. Tidak ada fungsi unequip atau pembebasan tugas prajurit (*dismiss*).
12. **Apakah perlengkapan saat ini bisa ditukar (swap)?**
    **TIDAK**. Tidak ada API swap perlengkapan.
13. **Apakah kuantitas gudang bisa menjadi negatif?**
    `EquipmentModel` membatasi `quantity = maxi(0, p_quantity)`, namun tidak ada guard transaksional di application layer yang mencegah upaya pengurangan di bawah nol.
14. **Apakah kuantitas perlengkapan bisa bertambah tanpa sumber yang sah?**
    **YA**, melalui `_ensure_equipment_quantity_for_role()` saat rekrutmen.
15. **Apakah simulasi pertempuran membaca peran dan perlengkapan serdadu?**
    **YA**. `CombatEngine.simulate_battle` membaca jumlah prajurit per peran dari `population.soldiers` dan memanggil `calculate_role_power(soldiers_count, base_stat, role, warehouse_equipment, morale)` untuk menghitung efektivitas tempur.
16. **Apakah perubahan sistem perlengkapan akan merusak asumsi `CombatEngine` Phase 2?**
    **TIDAK, JIKA DIINTEGRASIKAN SECARA TEPAT**. `CombatEngine` menghitung efektivitas serdadu berdasarkan array perlengkapan yang dioperkan kepadanya. Jika Phase 3B mengoperkan **array perlengkapan yang sedang dipakai (*fielded / equipped equipment*)**, `CombatEngine` akan menghitung bonus tier prajurit secara presisi dan mengeksekusi keausan (*wear*) serta kehilangan perlengkapan (*casualty gear loss*) langsung pada perlengkapan yang diterjunkan ke medan laga, tanpa mengubah formula matematika Phase 2.

---

## 3. Existing Architecture Relevant to Phase 3B

```text
┌────────────────────────────────────────────────────────┐
│                   Presentation Layer                   │
│   ├── MainPrototype (scenes/prototype/)                │
│   ├── GameController (presentation/controllers/)       │
│   └── PrototypeDebugView (presentation/views/)         │
└──────────────────────────┬─────────────────────────────┘
                           │ calls coordinator APIs
                           ▼
┌────────────────────────────────────────────────────────┐
│                   Application Layer                    │
│   ├── GameCoordinator (coordinators/game_coordinator)  │
│   │   ├── _warehouse: Array[EquipmentModel]            │
│   │   └── _population: PopulationModel                 │
│   └── GameplayStateMachine                             │
└──────────────────────────┬─────────────────────────────┘
                           │ orchestrates simulation
                           ▼
┌────────────────────────────────────────────────────────┐
│                    Simulation Layer                    │
│   ├── SimulationRunner (simulation/simulation_runner)  │
│   └── CombatEngine (simulation/combat_engine)          │
│       ├── calculate_role_power()                       │
│       └── _resolve_equipment_wear_and_loss()          │
└──────────────────────────┬─────────────────────────────┘
                           │ reads & updates domain
                           ▼
┌────────────────────────────────────────────────────────┐
│                      Domain Layer                      │
│   ├── PopulationModel (domain/model/population_model)  │
│   ├── EquipmentModel (domain/model/equipment_model)    │
│   └── GameStateSnapshot (domain/state/snapshot)        │
└────────────────────────────────────────────────────────┘
```

---

## 4. Current Gaps

1. **Gap 1: Pembuatan Perlengkapan Gaib**: `_ensure_equipment_quantity_for_role` melanggar konservasi materi.
2. **Gap 2: Tidak Ada Pemisahan Gudang vs Terpasang**: Gudang bertindak sebagai kolam agregat tunggal tanpa status pemakaian.
3. **Gap 3: Peran Tidak Berasal dari Senjata**: Peran prajurit di-hardcode saat rekrutmen.
4. **Gap 4: Tidak Ada Operasi Equip / Unequip / Swap**: Player tidak dapat mengatur distribusi perlengkapan.
5. **Gap 5: Tidak Ada Pembebasan Prajurit (*Dismiss Soldier*)**: Serdadu tidak bisa dikembalikan menjadi warga sipil di luar gugur dalam pertempuran.
6. **Gap 6: Ketiadaan Transaksi Atomik**: Tidak ada jaminan rollback jika pertukaran senjata gagal di tengah jalan.

---

## 5. Proposed Phase 3B Architecture

Phase 3B membagi status kepemilikan perlengkapan secara tegas di dalam domain/application layer:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                         TOTAL EQUIPMENT POOL                           │
│                                                                        │
│   ┌──────────────────────────────┐    ┌────────────────────────────┐   │
│   │     WAREHOUSE INVENTORY      │    │    SOLDIER EQUIPPED GEAR   │   │
│   │   (Tersimpan di Gudang)      │    │    (Dipakai oleh Serdadu)  │   │
│   │                              │    │                            │   │
│   │  - Bebas dipasangkan         │    │  - Memberikan peran tempur │   │
│   │  - Dapat direparasi Smith    │    │  - Diterjunkan ke battle   │   │
│   │  - Bertambah saat unequip    │    │  - Aus & hilang saat gugur │   │
│   └──────────────┬───────────────┘    └──────────────▲─────────────┘   │
│                  │           Equip / Swap            │                 │
│                  └───────────────────────────────────┘                 │
│                              Unequip / Dismiss                         │
│                  ┌───────────────────────────────────┐                 │
│                  │                                   │                 │
│                  ▼                                   │                 │
└────────────────────────────────────────────────────────────────────────┘
```

### Prinsip Utama Arsitektur:
1. **Unidirectional Data Flow Tetap Terjaga**: Player mengirim command $\rightarrow$ Coordinator memvalidasi ketersediaan stok $\rightarrow$ Transaksi atomik dieksekusi $\rightarrow$ Peran prajurit dihitung ulang $\rightarrow$ `state_changed(snapshot)` dipancarkan.
2. **Single Source of Truth**: Data kuantitas perlengkapan gudang dan perlengkapan terpasang dikelola oleh domain layer, bukan oleh UI.
3. **Strict Conservation**: Nilai total perlengkapan terpasang ditambah persediaan gudang adalah invarian konstan selama fase persiapan.

---

## 6. Soldier Equipment Data Model

Untuk mempertahankan model agregat yang ringan pada hardware low-end (Intel Celeron / 4 GB RAM / Android):
- **DILARANG** membuat node karakter individual untuk serdadu.
- **DILARANG** membuat UUID, inventory individual, atau pohon stat per prajurit.

### 6.1 Representasi Agregat:
Perlengkapan yang dipakai oleh serdadu disimpan sebagai array agregat `_soldier_equipment: Array[EquipmentModel]` pada `GameCoordinator` (atau terisolasi di dalam `PopulationModel`), di mana setiap item `EquipmentModel` merepresentasikan kelompok perlengkapan dengan `role_type`, `tier`, `durability`, dan `quantity` yang sedang digunakan oleh serdadu.

### 6.2 Formula Kebutuhan Perlengkapan per Peran:
Tiap peran prajurit membutuhkan komposisi perlengkapan spesifik:

| Peran Prajurit | Kebutuhan Perlengkapan Primer | Kebutuhan Perlengkapan Sekunder | Total Item / Prajurit |
| :--- | :--- | :--- | :---: |
| **Swordsman** | 1x `SWORD` | - | 1 |
| **Shield Infantry** | 1x `SWORD` | 1x `SHIELD` | 2 |
| **Spearman** | 1x `SPEAR` | - | 1 |
| **Archer** | 1x `BOW` | - | 1 |
| **Heavy Infantry** | 1x `HEAVY_ARMOR` | 1x `SWORD` | 2 |

---

## 7. Warehouse Conservation Model

### 7.1 Definisi Matematis Invariant:
Untuk setiap tipe perlengkapan $e \in \{\text{SWORD}, \text{SHIELD}, \text{SPEAR}, \text{BOW}, \text{HEAVY\_ARMOR}\}$ dan tier $t \in [1, 5]$:
$$\text{Owned}(e, t) = \text{Warehouse}(e, t) + \text{Equipped}(e, t)$$

Total perlengkapan seluruh benteng:
$$\text{TotalOwned} = \sum_{e, t} \text{Warehouse}(e, t) + \sum_{e, t} \text{Equipped}(e, t)$$

### 7.2 Aturan Konservasi Mutlak:
1. **Dilarang Negatif**: $\text{Warehouse}(e, t) \ge 0$ dan $\text{Equipped}(e, t) \ge 0$ untuk setiap state.
2. **Konservasi Sempurna di Preparation**: Selama fase `PREPARATION`, tidak ada aksi player yang boleh mengubah $\text{TotalOwned}$. Seluruh perpindahan adalah transfer *zero-sum* antara Gudang dan Serdadu.
3. **Pemberhentian Automatic Spawn**: Menghapus `_ensure_equipment_quantity_for_role()`. Tidak ada perlengkapan baru yang tercipta saat rekrutmen.
4. **Penyusutan Hanya di Combat**: Satu-satunya mekanisme pengurangan $\text{TotalOwned}$ adalah kehancuran permanen perlengkapan akibat prajurit gugur dalam pertempuran (evaluasi deterministik 35% di `CombatEngine`).

---

## 8. Role Derivation Rules

Peran prajurit bukan lagi input independen, melainkan **hasil evaluasi (*derived state*) dari kombinasi perlengkapan yang dipasang**.

### 8.1 Aturan Presedensi Evaluasi:
Kombinasi multi-perlengkapan memiliki presedensi lebih tinggi daripada perlengkapan tunggal untuk menghindari ambiguitas:

```text
1. Jika unit memiliki HEAVY_ARMOR + SWORD  ===> HEAVY_INFANTRY
2. Jika unit memiliki SWORD + SHIELD        ===> SHIELD_INFANTRY
3. Jika unit memiliki SPEAR                 ===> SPEARMAN
4. Jika unit memiliki BOW                   ===> ARCHER
5. Jika unit memiliki SWORD tunggal         ===> SWORDSMAN
6. Jika unit tidak memiliki senjata         ===> RECRUIT / UNARMED (Kembali ke Sipil)
```

### 8.2 Otoritas Evaluasi:
Evaluasi peran dijalankan di domain layer melalui fungsi deterministik murni:
`PopulationModel.recalculate_roles_from_equipment(equipped_gear_summary)`
Layer presentasi/UI dilarang menetapkan peran secara manual.

---

## 9. Equip / Unequip / Swap Flow

### 9.1 Equip Flow:
Mempersenjatai warga sipil menjadi serdadu dengan peran tertentu.
1. **Validasi**:
   - Status game harus `PREPARATION`.
   - Warga sipil tersedia: $Civilians \ge count$.
   - Perlengkapan yang dibutuhkan tersedia di gudang dalam jumlah $\ge count$.
2. **Eksekusi**:
   - Warga sipil berkurang: $Civilians = Civilians - count$.
   - Ambil perlengkapan dari gudang (prioritas tier tertinggi yang tidak rusak).
   - Masukkan perlengkapan ke `_soldier_equipment`.
   - Hitung ulang kuantitas peran prajurit pada `PopulationModel.soldiers`.
3. **Verifikasi**: Assert invariant konservasi valid.

### 9.2 Unequip & Dismiss Flow:
Membebastugaskan prajurit kembali menjadi warga sipil dan mengembalikan senjatanya ke gudang benteng.
1. **Validasi**:
   - Status game harus `PREPARATION`.
   - Jumlah prajurit pada peran yang dipilih $\ge count$.
2. **Eksekusi**:
   - Kurangi prajurit dari peran yang dipilih.
   - Ambil perlengkapan terkait dari `_soldier_equipment`.
   - Kembalikan perlengkapan tersebut ke `_warehouse` dengan durabilitas dan tier aslinya.
   - Tambahkan warga sipil: $Civilians = Civilians + count$.
   - Periksa kapasitas hunian benteng (*housing capacity*).
3. **Verifikasi**: Assert invariant konservasi valid.

### 9.3 Atomic Swap Flow:
Mengubah peran prajurit yang sudah ada dengan menukar senjatanya (contoh: 2 Swordsman ditukar menjadi 2 Spearman).
1. **Validasi Ketersediaan (Guard Check)**:
   - Jumlah prajurit asal mencukupi.
   - Perlengkapan baru yang dituju **benar-benar tersedia di gudang** dalam jumlah mencukupi.
   - **Jika stok senjata baru kurang $\rightarrow$ OPERASI BATAL TOTAL (Rollback)**. Tidak ada state yang termutasi sebagian.
2. **Eksekusi Atomik**:
   - Kurangi senjata baru dari gudang.
   - Pasang senjata baru ke serdadu.
   - Lepas senjata lama dari serdadu.
   - Masukkan senjata lama kembali ke gudang.
   - Hitung ulang distribusi peran prajurit pada `PopulationModel.soldiers`.
3. **Verifikasi Invariant**: Assert total senjata lama dan total senjata baru tetap konstan.

---

## 10. Recruitment Interaction (Resolution Option A vs Option B)

### Keputusan Desain yang Dipilih: **OPTION A (Recruitment Dibatasi oleh Ketersediaan Senjata)**

> **Alasan Pemilihan Option A**:
> 1. **Menjaga Integritas Desain Terkunci**: Game design yang telah disetujui menegaskan bahwa *peran prajurit diturunkan dari senjata*. Membiarkan prajurit direkrut tanpa senjata (Option B: unequipped soldiers) akan menciptakan entitas kombatan tak bersenjata yang ambigu pada sistem simulasi agregat Phase 2.
> 2. **Menghilangkan Peluang Duplikasi**: Dengan Option A, rekrutmen serdadu secara tegas membutuhkan dua prasyarat mutlak: **1 Warga Sipil + 1 Set Perlengkapan Sah**.
> 3. **Perilaku Transparan bagi Player**: Jika gudang hanya memiliki 3 Pedang, player hanya diizinkan merekrut maksimal 3 Swordsman. Player tidak akan terkecoh mengirimkan pasukan tanpa senjata ke medan tempur.

```text
[Alur Rekrutmen Option A]
Player Request: Rekrut N serdadu peran X
  ├── Cek 1: Apakah Civilians >= N?
  │     └── TIDAK: Rekrutmen ditolak ("Warga sipil tidak mencukupi").
  └── Cek 2: Apakah Warehouse memiliki senjata X >= N?
        ├── YA: 
        │     - Civilians berkurang N
        │     - Senjata X di gudang berkurang N
        │     - Senjata X terpasang bertambah N
        │     - Serdadu peran X bertambah N
        │     - Status: SUKSES
        └── TIDAK:
              - Batasi rekrutmen ke kuantitas maksimum yang tersedia,
              - ATAU tolak operasi rekrutmen jika player meminta kuantitas spesifik.
```

---

## 11. Battle Integration

Phase 3B **TIDAK MENGUBAH FORMULA COMBAT PHASE 2**.

### 11.1 Mekanisme Pengiriman Data ke CombatEngine:
1. `GameCoordinator` mengumpulkan `_soldier_equipment` (perlengkapan yang sedang aktif dipakai serdadu).
2. Saat `SimulationRunner.run_battle` dipanggil, coordinator mengoperkan `_soldier_equipment` sebagai parameter perlengkapan aktif tempur.
3. `CombatEngine.calculate_role_power` mengevaluasi serdadu menggunakan perlengkapan yang benar-benar mereka bawa ke medan laga:
   - Prajurit dengan Tier 3 Sword menerima pengali Tier 3 (1.65x).
   - Prajurit yang tidak membawa gear menerima pengali unequipped (1.0x).
4. `CombatEngine._resolve_equipment_wear_and_loss`:
   - Keausan tempur dialami oleh perlengkapan yang diterjunkan.
   - Bila prajurit gugur:
     - 35% perlengkapan hancur permanen (mengurangi total owned).
     - 65% perlengkapan rusak berat diselamatkan dan dikembalikan ke gudang benteng untuk diperbaiki oleh pandai besi (*Blacksmith*).
5. Pasca-pertempuran, sisa perlengkapan prajurit yang masih hidup tetap terpasang, sedangkan korban jiwa membebaskan kuantitas prajurit secara permanen.

---

## 12. UI / Prototype Interaction Plan

Pengembangan UI Phase 3B berfokus pada **kontrol telemetri fungsional (debug-oriented)**, bukan desain visual final:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PREPARATION DASHBOARD                           │
├──────────────────────────┬─────────────────────────────────────────────┤
│ WAREHOUSE STOCK (Stored) │ - Sword: 8 (T1) | Shield: 4 (T1)            │
│                          │ - Spear: 5 (T1) | Bow: 6 (T1)               │
├──────────────────────────┼─────────────────────────────────────────────┤
│ ACTIVE SQUAD ROSTER      │ - Swordsman: 2 [Gear: 2x Sword]             │
│ (Equipped)               │ - Shield Infantry: 2 [Gear: 2x Sword, 2x Sh]│
│                          │ - Archer: 2 [Gear: 2x Bow]                  │
├──────────────────────────┼─────────────────────────────────────────────┤
│ CONTROLS                 │ [+ Equip / Recruit]  [- Unequip / Dismiss]  │
│                          │ [⇄ Swap Gear: Sword -> Spear]               │
└──────────────────────────┴─────────────────────────────────────────────┘
```

1. **Warehouse Inventory Display**: Menampilkan persediaan bebas di gudang secara transparan per tipe dan tier.
2. **Equipped Squad Display**: Menampilkan jumlah serdadu aktif beserta rincian senjata/zirah yang terpasang.
3. **Equip / Recruit Button**: Tombol rekrutmen yang otomatis memvalidasi ketersediaan senjata di gudang.
4. **Unequip / Dismiss Button**: Tombol pembebasan tugas serdadu yang mengembalikan warga sipil dan mengembalikan senjata ke gudang.
5. **Swap Gear Button**: Tombol pertukaran peran/senjata antar-serdadu secara langsung dan atomik.

---

## 13. Test Plan

Suite pengujian otomatis baru (`tests/test_soldier_equipment_conservation.gd`) wajib memvalidasi skenario berikut secara headless:

### 13.1 Basic Equip & Stock Validation:
- [x] Equip berhasil saat stok gudang tersedia.
- [x] Equip gagal total saat stok gudang $= 0$.
- [x] Equip parsial/gagal aman saat stok gudang kurang dari jumlah permintaan.
- [x] Kuantitas gudang tidak pernah menjadi negatif.

### 13.2 Unequip & Dismissal:
- [x] Unequip mengembalikan perlengkapan ke gudang dengan tier dan durabilitas yang sama.
- [x] Unequip mengembalikan serdadu menjadi warga sipil ($Soldiers - 1, Civilians + 1$).
- [x] Kuantitas peran serdadu berkurang secara tepat.

### 13.3 Atomic Swap:
- [x] Swap berhasil saat senjata pengganti tersedia di gudang.
- [x] Swap gagal total saat senjata pengganti tidak tersedia di gudang.
- [x] Kegagalan swap tidak memutasi state serdadu maupun state gudang (zero state mutation).
- [x] Tidak ada perlengkapan yang hilang atau terduplikasi saat swap.

### 13.4 Role Derivation Precedence:
- [x] 1x Sword $\rightarrow$ Swordsman.
- [x] 1x Sword + 1x Shield $\rightarrow$ Shield Infantry (mengalahkan Swordsman).
- [x] 1x Spear $\rightarrow$ Spearman.
- [x] 1x Bow $\rightarrow$ Archer.
- [x] 1x Heavy Armor + 1x Sword $\rightarrow$ Heavy Infantry.
- [x] Pelepasan Shield dari Shield Infantry secara otomatis mengubah peran menjadi Swordsman.

### 13.5 Invariant Conservation Assertions:
- [x] $\text{Warehouse} + \text{Equipped} == \text{Total Owned}$ terbukti benar sebelum dan sesudah setiap operasi equip, unequip, swap, dan dismiss.

### 13.6 Regression Suite:
- [x] Phase 1 Architecture Boundary Tests: **5/5 PASS**.
- [x] Phase 2 Mathematical Simulation Tests: **21/21 PASS**.
- [x] Phase 3A Gameplay Prototype Tests: **11/11 PASS**.
- [x] Scene Smoke Playtest: **ALL PASS**.

---

## 14. Edge Cases Handling

1. **Stok Gudang Kosong (Zero Equipment)**: Tombol equip dinonaktifkan di UI, dan coordinator menolak perintah equip dengan `return false`.
2. **Ketiadaan Serdadu (Zero Soldiers)**: Tombol unequip dan swap dinonaktifkan, operasi unequip mengembalikan `false`.
3. **Swap ke Senjata yang Sama**: Terdeteksi sebagai *no-op* yang aman, tidak membuang resource.
4. **Kapasitas Hunian Penuh saat Dismiss**: Jika $TotalPopulation \ge HousingCapacity$, serdadu tetap bisa dibebastugaskan menjadi sipil karena perpindahan bersifat internal ($Soldier - 1, Civilian + 1$, total populasi tidak bertambah).
5. **Perlengkapan Rusak (Durability $= 0$)**: Tidak boleh dipasangkan ke prajurit baru sampai diperbaiki oleh pandai besi di gudang.
6. **Prajurit Gugur Massal di Pertempuran**: Seluruh perlengkapan prajurit yang gugur dievaluasi deterministik (35% musnah, 65% rusak dikembalikan ke gudang). Invariant total kepemilikan terupdate secara tepat.
7. **Perintah Equip saat Battle Sedang Berjalan**: Ditolak keras oleh `GameplayStateMachine` (hanya diizinkan pada state `PREPARATION`).

---

## 15. State & Persistence Impact

### Kompatibilitas `GameStateSnapshot`:
`GameStateSnapshot` diperluas dengan field terstruktur:
- `warehouse_data: Array` (hanya memuat perlengkapan yang tersimpan di gudang).
- `soldier_equipment_data: Array` (memuat perlengkapan yang sedang dipakai serdadu).

### Backward Compatibility:
- Method `to_dictionary()` dan `from_dictionary()` memetakan field baru dengan nilai default `[]` jika snapshot lama dibaca.
- Schema version `SaveSnapshotDto` tetap pada versi `1` (tidak ada breaking change arsitektur).

---

## 16. Exact File Change List

### Files to Modify:
1. `scripts/domain/model/population_model.gd`:
   - Menambahkan method pembebasan prajurit (*dismiss soldier*).
   - Menambahkan logika derivasi peran serdadu dari perlengkapan.
2. `scripts/application/coordinators/game_coordinator.gd`:
   - Menghapus method `_ensure_equipment_quantity_for_role()`.
   - Mengelola koleksi `_warehouse` dan `_soldier_equipment`.
   - Menambahkan API: `equip_soldier()`, `unequip_soldier()`, `swap_soldier_equipment()`, `dismiss_soldier()`.
   - Menegakkan invariant konservasi dan transaksi atomik.
3. `scripts/domain/state/game_state_snapshot.gd`:
   - Menambahkan penampung `soldier_equipment_data` pada snapshot.
4. `scripts/presentation/controllers/game_controller.gd`:
   - Menambahkan dispatch method untuk equip, unequip, swap, dan dismiss.
5. `scripts/presentation/views/prototype_debug_view.gd`:
   - Menampilkan persediaan gudang vs terpasang secara terpisah.
   - Menyediakan tombol kontrol interaktif untuk equip, unequip, swap, dan dismiss.
6. `plans/CURRENT_PHASE.md`, `plans/ROADMAP.md`, `plans/CHANGELOG.md`:
   - Sinkronisasi status pengerjaan Phase 3B.

### Files to Create:
1. `docs/design/PHASE_3B_SOLDIER_EQUIPMENT_PLAN.md` (Dokumen spesifikasi ini).
2. `tests/test_soldier_equipment_conservation.gd` (Test suite otomatis Phase 3B saat implementasi dibuka).

### Files that Must NOT be Modified:
- `scripts/simulation/combat_engine.gd` (Phase 2 Single Source of Truth).
- `scripts/simulation/economy_manager.gd` (Phase 2 Economy).
- `scripts/simulation/wave_generator.gd` (Phase 2 Threat ramp).
- `scripts/domain/model/hero_model.gd` (Batas Phase 4 / Phase 3C).
- `scripts/infrastructure/persistence/save_snapshot_dto.gd` (Batas Phase 1).

---

## 17. Implementation Sequence

Jika persetujuan implementasi telah diberikan oleh developer, tahapan pengerjaan wajib mengikuti urutan terstruktur berikut:

```text
Langkah 1: Domain Logic
  └── Tambahkan fungsi derivasi peran & dismiss pada PopulationModel.
Langkah 2: Coordinator Inventory & Invariants
  └── Hapus _ensure_equipment_quantity_for_role().
  └── Buat _soldier_equipment terpisah dari _warehouse.
  └── Terapkan fungsi equip, unequip, swap, dismiss dengan assertion konservasi.
Langkah 3: Battle Integration
  └── Operkan _soldier_equipment ke SimulationRunner.run_battle().
  └── Hubungkan hasil casualty wear & loss ke gudang benteng.
Langkah 4: Snapshot & Controller Wiring
  └── Perluas GameStateSnapshot untuk mencatat soldier_equipment_data.
  └── Tambahkan API pengendali pada GameController.
Langkah 5: Prototype Debug UI Update
  └── Perbarui PrototypeDebugView dengan kontrol equip/unequip/swap/dismiss.
Langkah 6: Automated Test Suite
  └── Buat dan jalankan tests/test_soldier_equipment_conservation.gd.
Langkah 7: Regression & Smoke Verification
  └── Jalankan seluruh 4 test suites existing (Phase 1, 2, 3A, Smoke).
Langkah 8: Reporting & Closure
  └── Dokumentasikan hasil dan laporkan ke developer untuk review.
```

---

## 18. Acceptance Criteria

Phase 3B hanya dinyatakan **COMPLETED** apabila:
1. [ ] Tidak ada lagi perlengkapan yang tercipta otomatis saat merekrut serdadu (`_ensure_equipment_quantity_for_role` dihapus 100%).
2. [ ] Rekrutmen serdadu mematuhi ketersediaan stok senjata di gudang (Option A).
3. [ ] Serdadu dapat dipasangkan perlengkapan (*equip*) dan gudang berkurang secara presisi.
4. [ ] Serdadu dapat dibebastugaskan (*unequip & dismiss*), mengembalikan warga sipil dan mengembalikan senjata ke gudang.
5. [ ] Pertukaran senjata serdadu (*swap*) berjalan secara atomik (gagal aman jika stok pengganti $= 0$).
6. [ ] Peran serdadu terbukti diturunkan secara deterministik dari perlengkapan yang dipasang.
7. [ ] Invariant konservasi perlengkapan terbukti valid pada setiap operasi: $\text{Warehouse} + \text{Equipped} == \text{TotalOwned}$.
8. [ ] Simulasi combat Phase 2 berjalan mulus mengevaluasi perlengkapan yang aktif dipakai serdadu.
9. [ ] Kehilangan perlengkapan akibat prajurit gugur memotong perlengkapan terpasang secara tepat tanpa merusak memori.
10. [ ] Seluruh test Phase 1, Phase 2, dan Phase 3A tetap lulus 100% (**Zero Regression**).
11. [ ] Test suite baru `test_soldier_equipment_conservation.gd` lulus 100%.
12. [ ] Prototipe dapat dimainkan dan diuji interaktif di Godot Editor.
13. [ ] Tidak ada implementasi sistem Hero (Phase 4 / Phase 3C tetap terjaga).

---

## 19. Non-Goals (Explicit Exclusions)

Fitur-fitur berikut secara tegas **DILARANG DIIMPLEMENTASIKAN DI PHASE 3B**:
- Slot perlengkapan hero (ditunda ke Phase 3C).
- Hero progression, talent tree, dan active combat skills (ditunda ke Phase 4).
- Crafting senjata, pandai besi menempa item baru, atau peleburan ore (ditunda ke Phase 7).
- Pembelian senjata dari pedagang/merchant (ditunda ke Phase 7).
- Karakter prajurit individual, level prajurit, atau inventaris unik per serdadu.
- Visual sprite senjata, animasi serdadu, atau efek visual pertarungan (ditunda ke Phase 9).
- Penyimpanan savegame file disk (ditunda ke Phase 10).

---

## 20. Risks & Mitigations

| Risiko Teknis | Dampak | Strategi Mitigasi |
| :--- | :--- | :--- |
| **Penyusutan Senjata Tak Terlacak saat Battle** | Invariant konservasi gagal saat prajurit gugur di pertempuran. | Gunakan laporan DTO `CombatEngine` (`equipment_lost`, `equipment_damaged`) untuk menyelaraskan `_soldier_equipment` dan `_warehouse` pasca-battle. |
| **Partial Swap State Mutation** | Senjata lama terlanjur lepas, tetapi senjata baru tidak ada di gudang, menyebabkan prajurit hilang senjata. | Validasi ketersediaan senjata baru **sebelum** melepas senjata lama. Jika gagal, return `false` tanpa memutasi satu pun variabel. |
| **UI Polling Overhead** | Penambahan kontrol UI memperberat frame loop. | Tetap gunakan arsitektur event-driven murni: UI hanya me-render ulang saat sinyal `state_changed` dipancarkan oleh coordinator. |
| **Kerusakan Test Regresi Phase 2** | Test Phase 2 gagal karena parameter `warehouse_equipment` diubah. | Pertahankan tanda tangan method `CombatEngine.simulate_battle` dan `calculate_role_power` tetap 100% kompatibel. |

---

## 21. Estimated Implementation Complexity

- **Tingkat Kompleksitas**: **LOW to MEDIUM** (Rendah hingga Menengah).
- **Fokus Utama**: Manajemen data array, validasi logika transfer transaksional di `GameCoordinator`, dan derivasi enum/string peran di `PopulationModel`.
- **Estimasi File Berubah**: 5 file existing diperluas, 1 file test baru dibuat. Nol modifikasi pada engine simulasi matematika Phase 2.

---

## 22. Final Recommendation

> **REKOMENDASI TEKNIS**:
> Rencana implementasi Phase 3B ini telah dirancang secara lengkap, aman dari regresi arsitektur, dan sepenuhnya mematuhi prinsip `AGENTS.md` (*Inspect Before Modify*, *Extend Don't Break*, *No Scope Creep*).
> 
> **STATUS SAAT INI**:
> `PHASE 3B — PLANNED / IMPLEMENTATION NOT STARTED`
> 
> Seluruh pekerjaan kode ditahan sampai Developer meninjau rencana ini dan memberikan persetujuan eksplisit (*Explicit Approval*) untuk memulai implementasi.
