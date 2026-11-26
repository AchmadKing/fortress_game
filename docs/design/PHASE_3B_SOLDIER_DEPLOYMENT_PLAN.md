# PHASE 3B — SOLDIER DEPLOYMENT & TEMPORARY EQUIPMENT MANAGEMENT
## TECHNICAL SPECIFICATION & IMPLEMENTATION PLAN

**Document**: `docs/design/PHASE_3B_SOLDIER_DEPLOYMENT_PLAN.md`  
**Status**: `PHASE 3B — COMPLETED`  
**Project**: `fortress_game`  
**Repository**: `https://github.com/AchmadKing/fortress_game.git`  
**Branch**: `main`  
**Phase**: Phase 3 — Gameplay Prototype  
**Sub-Phase**: Phase 3B — Soldier Deployment & Temporary Equipment Management  
**Phase 4**: `LOCKED`  

> [!IMPORTANT]
> Dokumen ini adalah **Rencana Implementasi Teknis (Technical Implementation Plan)** yang merevisi arsitektur Phase 3B.
> Konsep kepemilikan perlengkapan permanen individual prajurit **TELAH DIGANTIKAN** secara menyeluruh dengan konsep **Alokasi Perlengkapan Sementara Berbasis Gelombang (Temporary Wave Deployment)**.
> Sesuai aturan mutlak `AGENTS.md`: **DILARANG MENULIS ATAU MENGUBAH KODE GAMEPLAY MAUPUN MEMULAI IMPLEMENTASI SEBELUM MENDAPATKAN PERSETUJUAN EKSPLISIT (EXPLICIT APPROVAL)**.

---

## 1. Executive Summary

Phase 3B menetapkan arsitektur baru untuk manajemen serdadu dan gudang senjata: **Temporary Wave Deployment**.

Alih-alih mengikatkan senjata ke prajurit secara permanen, player mengonfigurasi komposisi regu tempur (*deployment compositions*) khusus untuk menghadapi gelombang musuh aktif (*current wave*). Perlengkapan dari gudang senjata (**Warehouse**) direservasi sementara (*temporary reservation*) untuk regu yang diterjunkan, dibawa bertempur di medan laga, mengalami keausan dan risiko kerusakan/kehilangan sesuai formula deterministik Phase 2, lalu perlengkapan yang selamat dikembalikan seutuhnya ke gudang benteng setelah gelombang berakhir.

Prajurit yang selamat kembali ke kolam prajurit benteng (*Available Soldier Pool*) dan siap dikonfigurasikan dengan persenjataan yang sama sekali berbeda pada persiapan gelombang berikutnya.

Prinsip invariant utama:
$$\text{TOTAL OWNED EQUIPMENT} = \text{EQUIPMENT IN WAREHOUSE} + \text{RESERVED DEPLOYMENT EQUIPMENT}$$

---

## 2. New Design Concept — Temporary Wave Deployment

### 2.1 Siklus Alur Gameplay Phase 3B:
```text
┌────────────────────────────────────────────────────────┐
│                   PREPARATION PHASE                    │
│   Kolam Prajurit: N Prajurit Hidup                     │
│   Gudang Senjata: M Unit Perlengkapan                  │
└──────────────────────────┬─────────────────────────────┘
                           │ Player menyusun regu tempur
                           ▼
┌────────────────────────────────────────────────────────┐
│               DEPLOYMENT CONFIGURATION                 │
│   - Pilih Jumlah Prajurit                              │
│   - Pilih Primary Weapon (Wajib)                       │
│   - Pilih Secondary Weapon & Armor (Opsional)          │
│   - Validasi Stok Gudang & Reservasi Atomik            │
└──────────────────────────┬─────────────────────────────┘
                           │ Player menekan Start Battle
                           ▼
┌────────────────────────────────────────────────────────┐
│                 BATTLE (LOCKED STATE)                  │
│   - Konfigurasi regu terkunci (tidak bisa diubah)      │
│   - CombatEngine Phase 2 mengevaluasi regu             │
│   - Prajurit gugur permanen                            │
│   - Evaluasi keausan & kehilangan gear deterministik   │
└──────────────────────────┬─────────────────────────────┘
                           │ Pertempuran selesai
                           ▼
┌────────────────────────────────────────────────────────┐
│              POST-WAVE EQUIPMENT RETURN                │
│   - Gear hancur (35% korban) musnah permanen           │
│   - Gear rusak (65% korban) kembali ke gudang          │
│   - Gear selamat aus & kembali ke gudang               │
│   - Prajurit selamat kembali ke kolam prajurit         │
│   - Reservasi aktif direset ke 0                       │
└──────────────────────────┬─────────────────────────────┘
                           │ Transisi ke wave berikutnya
                           ▼
┌────────────────────────────────────────────────────────┐
│               NEXT WAVE PREPARATION                    │
│   (Player bebas merombak total persenjataan baru)      │
└────────────────────────────────────────────────────────┘
```

---

## 3. Soldiers Remain Aggregate (No Individual Units)

Sistem serdadu tetap dipertahankan sebagai **sistem populasi agregat murni**:
- **DILARANG** membuat instance Node karakter individual untuk serdadu.
- **DILARANG** membuat UUID, stat individu, level individu, skill tree, atau inventaris unik per prajurit.
- Pasukan direpresentasikan sebagai kelompok numerik:
  - Total Serdadu Hidup (*Total Living Soldiers*): integer.
  - Serdadu Tersedia (*Available Soldiers*): integer.
  - Serdadu Diterjunkan (*Deployed Soldiers*): integer.

Contoh:
Tersedia 30 prajurit di benteng. Player membentuk:
- 10x regu Shield Infantry
- 8x regu Archer
- 12x regu Spearman
Ini adalah 3 entri regu deployment agregat, bukan 30 objek simulasi independen.

---

## 4. Deployment Composition Model

Setiap regu tempur (*Deployment Group*) dibentuk dari parameter spesifik:

```text
┌────────────────────────────────────────────────────────┐
│             DEPLOYMENT COMPOSITION SCHEMA              │
├─────────────────────┬──────────────┬───────────────────┤
│ Parameter           │ Sifat        │ Keterangan        │
├─────────────────────┼──────────────┼───────────────────┤
│ soldier_count       │ REQUIRED     │ Integer > 0       │
│ primary_weapon      │ REQUIRED     │ String identifier │
│ secondary_weapon    │ OPTIONAL     │ String / "NONE"   │
│ armor               │ OPTIONAL     │ String / "NONE"   │
└─────────────────────┴──────────────┴───────────────────┘
```

### 4.1 Primary Weapon is Mandatory:
- Setiap prajurit yang diterjunkan **wajib** memegang Primary Weapon.
- Prajurit tanpa senjata (*unarmed*) **TIDAK SAH** sebagai regu tempur di Phase 3B.
- Dilarang membuat peran "Unarmed Combatant" hanya untuk menghindari kewajiban membawa senjata primer.

### 4.2 Secondary Weapon & Armor are Optional:
- Secondary weapon (misal: `SHIELD`) dan Armor (misal: `HEAVY_ARMOR`) bersifat pelengkap opsional.
- Jika dipilih, gudang harus memiliki stok yang mencukupi untuk seluruh prajurit di regu tersebut.

---

## 5. Stock-Aware Equipment Selection & Reservation

Gudang senjata (*Warehouse*) adalah sumber daya strategis yang terbatas:

```text
Contoh Stok Gudang:
- Sword: 20
- Shield: 10
- Spear: 15
- Bow: 10
- Heavy Armor: 5
```

### 5.1 Aturan Seleksi Sadar Stok (Stock-Aware Selection):
Untuk regu dengan ukuran $N$ prajurit:
1. **Primary Weapon**: Hanya dapat dipilih jika $\text{Stock}(Primary) \ge N$.
2. **Secondary Weapon**: Hanya dapat dipilih jika $\text{Stock}(Secondary) \ge N$.
3. **Armor**: Hanya dapat dipilih jika $\text{Stock}(Armor) \ge N$.

> [!NOTE]
> **Keputusan Perilaku UI**:
> Opsi perlengkapan yang stoknya kurang dari $N$ **dinonaktifkan (*disabled / grayed-out*)** di UI daripada disembunyikan secara diam-diam. Hal ini memberi tahu player secara transparan bahwa barang tersebut ada di gudang namun jumlahnya belum mencukupi untuk ukuran regu yang diminta.

### 5.2 Reservasi Seketika (Immediate Reservation):
Saat regu tempur berhasil dibentuk:
- Stok gudang **seketika dipotong**:
  $$\text{Warehouse Stock} = \text{Warehouse Stock} - N$$
- Perlengkapan tersebut diberi status **`RESERVED FOR ACTIVE DEPLOYMENT`**.
- Perlengkapan ini tidak dapat dialokasikan ke regu deployment lain, sehingga mencegah alokasi ganda (*double allocation*).

---

## 6. Multiple Deployment Groups & Canonical Identity

Sistem mendukung banyak regu deployment aktif secara simultan selama mematuhi batas total serdadu dan total stok senjata.

### 6.1 Identitas Kanonikal Regu (*Canonical Composition Identity*):
Setiap regu deployment memiliki identitas unik berdasarkan kombinasi lengkap perlengkapannya:
$$\text{CompositionKey} = \text{Primary} \,|\, \text{Secondary} \,|\, \text{Armor}$$

Contoh:
- `SWORD|SHIELD|NONE` $\neq$ `SWORD|NONE|NONE`
- `SWORD|SHIELD|NONE` $\neq$ `SWORD|SHIELD|HEAVY_ARMOR`
- `SWORD|NONE|HEAVY_ARMOR` $\neq$ `SWORD|SHIELD|NONE`

Jika ada parameter yang berbeda, regu tersebut diperlakukan sebagai komposisi terpisah. Jika player menambahkan prajurit dengan kombinasi yang persis sama, kuantitas regu kanonikal tersebut digabungkan (*merged*).

---

## 7. Dynamic Role Derivation (Temporary Loadout)

Peran prajurit (*Soldier Role*) **diturunkan secara dinamis** dari komposisi perlengkapan regu yang aktif pada gelombang tersebut:

```text
┌──────────────────────────────┬─────────────────────────┐
│ Deployment Composition       │ Derived Combat Role     │
├──────────────────────────────┼─────────────────────────┤
│ SWORD + SHIELD + Any/None    │ SHIELD_INFANTRY         │
│ SWORD + HEAVY_ARMOR          │ HEAVY_INFANTRY          │
│ SPEAR + Any/None             │ SPEARMAN                │
│ BOW + Any/None               │ ARCHER                  │
│ SWORD + NONE + NONE          │ SWORDSMAN               │
└──────────────────────────────┴─────────────────────────┘
```

Peran ini murni menentukan bagaimana regu tersebut berkontribusi pada kalkulasi 5-fase `CombatEngine` Phase 2. Setelah pertempuran usai, peran tersebut luruh bersamaan dengan kembalinya perlengkapan ke gudang.

---

## 8. Reconfiguration Before Battle & Atomic Operations

### 8.1 Fleksibilitas Fase Persiapan:
Selama berada di state `PREPARATION` dan `WAVE_PREVIEW`, player bebas merombak, mengedit, atau membatalkan deployment.

### 8.2 Alur Modifikasi / Pembatalan Regu (Atomic Reconfiguration):
Ketika regu diedit atau dibatalkan:
1. Kembalikan perlengkapan yang direservasi regu tersebut ke gudang.
2. Kembalikan prajurit regu tersebut ke kolam prajurit tersedia (*Available Soldiers*).
3. Validasi konfigurasi baru.
4. Jika konfigurasi baru sah: reservasi perlengkapan baru dan komit regu baru.
5. **Jika konfigurasi baru gagal**: lakukan **rollback penuh**—kembalikan regu lama ke status reservasi aslinya tanpa mutasi parsial.

---

## 9. Battle Lock

Ketika permainan berpindah ke state **`BATTLE`**:
- Seluruh konfigurasi regu deployment **DIKUNCI SECARA MUTLAK (*LOCKED*)**.
- Player dilarang menambah, mengedit, menghapus, atau mengubah alokasi senjata regu selama simulasi pertempuran berjalan.
- Snapshot deployment aktif diteruskan ke engine pertempuran untuk diproses.

---

## 10. Combat Engine Integration

Phase 3B **TIDAK MENDUPLIKASI FORMULA COMBAT PHASE 2**.

`CombatEngine` tetap menjadi satu-satunya sumber kebenaran (*Single Source of Truth*).

### 10.1 Pemetaan Adapter Deployment ke CombatEngine:
Sebelum memanggil `SimulationRunner.run_battle()`, coordinator memetakan regu deployment aktif ke dalam input standar Phase 2:
1. **Agregasi Peran**: Menghitung total serdadu per peran turunan:
   - Total `ARCHER` = jumlah prajurit di regu yang menghasilkan peran Archer.
   - Total `SHIELD_INFANTRY` = jumlah prajurit di regu Shield Infantry.
   - Total `SPEARMAN` = jumlah prajurit di regu Spearman.
   - Total `SWORDSMAN` = jumlah prajurit di regu Swordsman.
   - Total `HEAVY_INFANTRY` = jumlah prajurit di regu Heavy Infantry.
2. **Koleksi Perlengkapan Aktif**: Mengoperkan seluruh perlengkapan yang sedang direservasi oleh regu aktif ke parameter `warehouse_equipment` pada `simulate_battle()`.
3. `CombatEngine.calculate_role_power` mengevaluasi efektivitas tempur prajurit berdasarkan senjata yang mereka bawa ke medan laga.

---

## 11. Post-Wave Equipment Processing & Return

Setelah pertempuran diselesaikan di `RESULT` dan berlanjut ke `RECOVERY`:

```text
[Alur Pemrosesan Pasca-Wave]
Active Reserved Equipment
        ↓
CombatEngine Phase 2 Resolution:
  ├── Aus Tempur Standar (base wear diterapkan ke gear yang dipakai)
  └── Evaluasi Korban Jiwa (Casualty Gear Resolution):
        ├── 35% Gear Korban: Musnah Permanen (Lost/Destroyed)
        └── 65% Gear Korban: Rusak Berat Diselamatkan (Damaged Gear)
        ↓
Kembalikan Seluruh Gear yang Selamat (Damaged + Intact) ke Warehouse
        ↓
Reset Active Reserved Equipment = 0
```

### 11.1 Aturan Pengembalian:
1. **Gear Selamat**: Seluruh perlengkapan dari serdadu yang bertahan hidup mengalami aus normal dan dikembalikan ke stok gudang.
2. **Gear Korban Rusak (65%)**: Mengalami pengurangan durabilitas berat (-40 durabilitas per Phase 2) dan kembali ke gudang sebagai perlengkapan rusak yang siap diperbaiki oleh pekerja Blacksmith.
3. **Gear Korban Musnah (35%)**: Dihapus permanen dari sistem kepemilikan benteng.
4. **Reservasi Bersih**: Koleksi deployment aktif dikosongkan.

---

## 12. Equipment & Soldier Accounting Invariants

### 12.1 Invariant Perlengkapan (Equipment Conservation):
- **Sebelum Deployment**:
  $$\text{TotalOwned}(e) = \text{WarehouseStock}(e)$$
- **Saat Deployment Aktif (Preparation / Battle)**:
  $$\text{TotalOwned}(e) = \text{WarehouseStock}(e) + \text{ReservedEquipment}(e)$$
- **Pasca-Pertempuran (Recovery Selesai)**:
  $$\text{ReservedEquipment}(e) = 0$$
  $$\text{WarehouseStock}_{\text{after}}(e) = \text{WarehouseStock}_{\text{before}}(e) + \text{ReturnedGear}(e) - \text{DestroyedGear}(e)$$
  $$\text{TotalOwned}_{\text{after}}(e) = \text{TotalOwned}_{\text{before}}(e) - \text{DestroyedGear}(e)$$

### 12.2 Invariant Serdadu (Soldier Accounting):
- **Sebelum Pertempuran**:
  $$\text{TotalLivingSoldiers} = \text{AvailableSoldiers} + \text{DeployedSoldiers}$$
- **Pasca-Pertempuran**:
  $$\text{DeadSoldiers} = \text{Casualties Evaluated by CombatEngine}$$
  $$\text{TotalLivingSoldiers}_{\text{new}} = \text{TotalLivingSoldiers}_{\text{old}} - \text{DeadSoldiers}$$
  $$\text{DeployedSoldiers} = 0$$
  $$\text{AvailableSoldiers} = \text{TotalLivingSoldiers}_{\text{new}}$$

> [!IMPORTANT]
> **Prajurit Gugur vs Deployment**:
> - Prajurit yang gugur dihapus permanen dari populasi benteng (tidak kembali ke warga sipil).
> - Prajurit yang selamat kembali ke kolam prajurit benteng (*Available Soldiers*).
> - Tidak ada mekanisme pembebasan prajurit (*dismiss soldier*) rumit yang dibutuhkan pada siklus temporary deployment ini.

---

## 13. UI & Debug Prototype Requirement

Tampilan UI telemetri pada `PrototypeDebugView` dirancang fungsional dan berbasis teks murni:

```text
================================================================================
DEPLOYMENT CONFIGURATION (Wave Preview / Preparation)
================================================================================
Available Soldiers: 18 / 18

[ Create Deployment Group ]
- Count:    [ < ] 6 [ > ]
- Primary:  [ SWORD (Avail: 10) ▼ ]    (REQUIRED)
- Second:   [ SHIELD (Avail: 4) ▼ ]   (OPTIONAL)
- Armor:    [ NONE ▼ ]                (OPTIONAL)
[ + DEPLOY GROUP ]

--------------------------------------------------------------------------------
ACTIVE DEPLOYMENT GROUPS:
1. [6x] SWORD + SHIELD  ==> SHIELD_INFANTRY  [Edit] [Cancel]
2. [4x] BOW             ==> ARCHER           [Edit] [Cancel]

Total Deployed: 10 / 18 | Remaining Available: 8

--------------------------------------------------------------------------------
RESERVED GEAR:
- Sword: 6 | Shield: 6 | Bow: 4

REMAINING WAREHOUSE STOCK:
- Sword: 4 | Shield: 0 (EMPTY) | Spear: 10 | Bow: 6 | Heavy Armor: 10
================================================================================
```

---

## 14. Detailed Validation Rules & Error Handling

Setiap aksi pembuatan atau modifikasi deployment wajib mematuhi rantai validasi ketat:

1. **Aturan 1 (State Check)**: Aksi hanya sah pada state `PREPARATION` dan `WAVE_PREVIEW`. Jika dipanggil saat `BATTLE` $\rightarrow$ Tolak keras (`return false`).
2. **Aturan 2 (Count Check)**: $N > 0$.
3. **Aturan 3 (Soldier Capacity Check)**: $N \le AvailableSoldiers$.
4. **Aturan 4 (Primary Weapon Check)**: Primary weapon tidak boleh kosong/null dan harus berupa senjata primer yang sah (`SWORD`, `SPEAR`, `BOW`).
5. **Aturan 5 (Stock Check)**:
   - $\text{Warehouse}(Primary) \ge N$
   - Jika Secondary dipilih: $\text{Warehouse}(Secondary) \ge N$
   - Jika Armor dipilih: $\text{Warehouse}(Armor) \ge N$
6. **Aturan 6 (Duplicate Equipment Slot Check)**: Dilarang memilih jenis perlengkapan yang sama pada slot Primary dan Secondary (misal: Primary Sword + Secondary Sword ditolak).
7. **Aturan 7 (Atomicity Guarantee)**: Jika salah satu validasi di atas gagal, **tidak ada state yang dimutasi sama sekali** (*Zero State Mutation*).

---

## 15. Comprehensive Test Plan

Suite pengujian otomatis baru `tests/test_soldier_deployment_temporary.gd` wajib memvalidasi skenario berikut:

| ID | Nama Skenario Uji | Kriteria Keberhasilan |
| :-: | :--- | :--- |
| **A** | `test_basic_valid_deployment` | Regu berhasil dibentuk, stok gudang berkurang, prajurit tersedia berkurang. |
| **B** | `test_primary_weapon_mandatory` | Upaya deployment tanpa senjata primer ditolak mentah-mentah. |
| **C** | `test_insufficient_equipment_rejected` | Deployment dengan $N > Stock$ ditolak tanpa memotong sumber daya. |
| **D** | `test_stock_aware_ui_state` | Verifikasi bahwa opsi perlengkapan dengan stok $< N$ ditandai tidak tersedia. |
| **E** | `test_soldier_shortage_rejected` | Upaya mendeploy prajurit melebihi prajurit tersedia ditolak. |
| **F** | `test_multiple_deployment_groups` | 3 regu berbeda (Swordsman, Shield, Archer) dapat aktif bersamaan. |
| **G** | `test_equipment_conservation_invariant` | $\text{Warehouse} + \text{Reserved} == \text{TotalOwned}$ valid sebelum pertempuran. |
| **H** | `test_no_double_allocation` | Perlengkapan yang sudah direservasi regu 1 tidak bisa dipakai regu 2. |
| **I** | `test_failed_transaction_atomic_rollback` | Kegagalan deployment tidak meninggalkan reservasi yatim (*no orphan gear*). |
| **J** | `test_reconfiguration_before_battle` | Mengedit regu melepaskan reservasi lama dan mengompres reservasi baru. |
| **K** | `test_reconfiguration_failure_preserves_original` | Kegagalan edit regu mengembalikan regu asli secara utuh. |
| **L** | `test_composition_canonical_identity` | `SWORD|SHIELD|NONE` $\neq$ `SWORD|NONE|NONE`. |
| **M** | `test_battle_lock_enforced` | Pemanggilan deploy/edit saat state `BATTLE` ditolak keras. |
| **N** | `test_post_wave_equipment_return` | Perlengkapan dari prajurit yang selamat kembali ke stok gudang. |
| **O** | `test_equipment_loss_phase2_deterministic` | 35% gear prajurit gugur musnah permanen; 65% kembali rusak. |
| **P** | `test_surviving_soldiers_return_to_pool` | Prajurit yang selamat kembali ke kolam prajurit tersedia. |
| **Q** | `test_soldier_casualties_permanent` | Prajurit gugur memotong total populasi prajurit hidup secara permanen. |
| **R** | `test_regression_existing_suites` | Phase 1 (5/5), Phase 2 (21/21), Phase 3A (11/11), Smoke (ALL PASS). |

---

## 16. State & Persistence Impact (`GameStateSnapshot`)

`GameStateSnapshot` diperluas dengan field:
- `warehouse_data: Array` (hanya memuat perlengkapan yang saat ini ada di gudang).
- `active_deployments_data: Array` (memuat daftar regu deployment aktif dan perlengkapan yang sedang direservasi).
- `available_soldiers_count: int` (jumlah serdadu yang siap diterjunkan).

### Backward Compatibility:
- Serialization `to_dictionary()` dan `from_dictionary()` menyediakan fallback default aman.
- Schema version `SaveSnapshotDto` tetap versi `1`.

---

## 17. Exact File Change List

### Files to Modify (Saat Implementasi Dibuka):
1. `scripts/domain/model/population_model.gd`:
   - Penyesuaian tracking kolam prajurit tersedia (*available soldiers*) vs deployed.
2. `scripts/application/coordinators/game_coordinator.gd`:
   - Hapus `_ensure_equipment_quantity_for_role()`.
   - Implementasikan sistem reservasi regu tempur sementara: `create_deployment()`, `cancel_deployment()`, `reconfigure_deployment()`.
   - Logika pengembalian gear pasca-wave di `proceed_from_result()`.
3. `scripts/domain/state/game_state_snapshot.gd`:
   - Tambahkan `active_deployments_data` dan `available_soldiers_count`.
4. `scripts/presentation/controllers/game_controller.gd`:
   - Tambahkan API dispatch untuk deployment regu tempur.
5. `scripts/presentation/views/prototype_debug_view.gd`:
   - Perbarui tampilan HUD dengan dashboard konfigurasi regu dan status reservasi gear.
6. `plans/CURRENT_PHASE.md`, `plans/ROADMAP.md`, `plans/CHANGELOG.md`:
   - Dokumentasi sinkronisasi Phase 3B.

### Files to Create:
1. `docs/design/PHASE_3B_SOLDIER_DEPLOYMENT_PLAN.md` (Dokumen spesifikasi ini).
2. `tests/test_soldier_deployment_temporary.gd` (Test suite otomatis saat implementasi).

### Files to Delete:
- `docs/design/PHASE_3B_SOLDIER_EQUIPMENT_PLAN.md` (Dokumen lama yang mengasumsikan kepemilikan permanen dihapus/digantikan).

### Files that Must NOT be Modified:
- `scripts/simulation/combat_engine.gd` (Phase 2 Single Source of Truth).
- `scripts/simulation/economy_manager.gd` (Phase 2 Economy).
- `scripts/simulation/wave_generator.gd` (Phase 2 Threat ramp).
- `scripts/domain/model/hero_model.gd` (Batas Phase 4 / Phase 3C).
- Seluruh script arsitektur Phase 1.

---

## 18. Implementation Sequence (Rekomendasi Bertahap)

```text
Tahap 1: Data Model & Canonical Identity
  └── Definisikan kelas DTO / struct DeploymentComposition di domain layer.
Tahap 2: Coordinator Temporary Reservation Logic
  └── Hapus _ensure_equipment_quantity_for_role().
  └── Terapkan create_deployment(), cancel_deployment() dengan reservasi gudang seketika.
  └── Terapkan assertion invariant konservasi peralatan.
Tahap 3: CombatEngine Adapter Integration
  └── Petakan active deployments ke dalam format input CombatEngine Phase 2.
  └── Sambungkan pengembalian gear pasca-wave (wear & loss Phase 2) di recovery.
Tahap 4: Controller & Snapshot Wiring
  └── Hubungkan GameController dan GameStateSnapshot.
Tahap 5: Prototype Debug View HUD
  └── Tambahkan panel seleksi regu sadar-stok pada PrototypeDebugView.
Tahap 6: Automated Test Suite (A s/d R)
  └── Implementasikan tests/test_soldier_deployment_temporary.gd.
Tahap 7: Regression Verification
  └── Jalankan seluruh pengujian Phase 1, 2, 3A, dan Smoke test.
```

---

## 19. Acceptance Criteria

Phase 3B hanya dinyatakan **COMPLETED** apabila:
1. [ ] Tidak ada lagi perlengkapan yang tercipta otomatis (`_ensure_equipment_quantity_for_role` terhapus 100%).
2. [ ] Perlengkapan bersifat sementara (*temporary wave deployment*), bukan kepemilikan permanen.
3. [ ] Senjata primer (*Primary Weapon*) wajib dipilih pada setiap regu; prajurit tanpa senjata ditolak.
4. [ ] Opsi perlengkapan di UI dinonaktifkan jika stok gudang $< N$.
5. [ ] Pembentukan regu seketika mereservasi perlengkapan dan memotong ketersediaan gudang.
6. [ ] Banyak regu deployment dapat aktif bersamaan tanpa alokasi ganda (*no double allocation*).
7. [ ] Regu dapat diedit/dibatalkan sebelum battle dengan pengembalian reservasi secara atomik.
8. [ ] Regu terkunci secara mutlak saat memasuki state `BATTLE`.
9. [ ] `CombatEngine` mengevaluasi regu aktif tanpa modifikasi formula matematika Phase 2.
10. [ ] Perlengkapan yang selamat kembali ke gudang pasca-wave; gear musnah (35% korban) terhapus permanen.
11. [ ] Prajurit yang selamat kembali ke kolam prajurit benteng; prajurit gugur terpotong permanen.
12. [ ] Invariant $\text{Warehouse} + \text{Reserved} == \text{TotalOwned}$ valid 100%.
13. [ ] Test suite baru `test_soldier_deployment_temporary.gd` lulus 100%.
14. [ ] Seluruh 4 test suite existing tetap **100% PASS (Zero Regression)**.
15. [ ] Tidak ada implementasi sistem Hero (Phase 3C & Phase 4 tetap terkunci).

---

## 20. Explicit Non-Goals

- Tidak ada sistem kepemilikan senjata permanen prajurit.
- Tidak ada simulasi prajurit individu.
- Tidak ada slot equipment hero (milik Phase 3C).
- Tidak ada sistem crafting, merchant, atau gacha (milik Phase 7).
- Tidak ada visual sprite atau animasi battlefield (milik Phase 6 & Phase 9).

---

## 21. Risks & Mitigations

| Risiko Teknis | Dampak | Strategi Mitigasi |
| :--- | :--- | :--- |
| **Reservasi Yatim (*Orphaned Reservation*)** | Perlengkapan tertahan di reservasi jika terjadi error di tengah battle. | Pastikan `proceed_from_result()` di coordinator selalu membersihkan dan mengembalikan reservasi yang tersisa ke gudang. |
| **State Desynchronization saat Reconfiguration** | Regu lama terhapus tetapi regu baru gagal dibentuk karena stok kurang. | Terapkan pola transaksi atomik: validasi ketersediaan regu baru secara menyeluruh sebelum melepaskan reservasi lama. |
| **Kebingungan Player terhadap Stok** | Player bingung mengapa tombol deploy tidak aktif. | Tampilkan indikator stok riil di samping nama senjata pada UI debug. |

---

## 22. Final Recommendation & Status

> **STATUS RESMI**:
> `PHASE 3B — PLANNED / IMPLEMENTATION NOT STARTED`  
> `PHASE 4 — LOCKED`
> 
> Seluruh kode permainan (`.gd`) tetap utuh dan tidak dimodifikasi. Rencana ini siap untuk ditinjau oleh developer sebelum persetujuan implementasi diberikan.
