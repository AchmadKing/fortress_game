# Technical Plan — Phase 5: Fortress & Management Systems

Dokumen ini adalah cetak biru teknis (*technical architecture plan*) resmi untuk implementasi **Phase 5 — Fortress & Management Systems** pada proyek **fortress_game**.

---

## 1. High-Level Architecture & Principles

### Prinsip Utama
1. **Extend, Don't Break**: Memperluas model dan alur kerja existing dari Phase 1–4 (`FortressModel`, `PopulationModel`, `EconomyManager`, `GameCoordinator`, `GameController`, `GameStateSnapshot`, `PrototypeDebugView`) tanpa merusak backward compatibility atau mengubah kontrak API kanonikal yang sudah ada.
2. **Single Source of Truth**:
   - `FortressModel` adalah satu-satunya pemilik integritas pertahanan benteng (Fortress HP, Wall HP, Gate HP, Armor).
   - `PopulationModel` adalah satu-satunya pemilik data demografi warga benteng (Civilians, Workers, Soldiers).
   - `WorkerModel` adalah domain model agregat untuk alokasi pekerjaan (`IDLE`, `BLACKSMITH`, `REPAIR`, `CONSTRUCTION`) dan moral/produktivitas pekerja.
   - `BuildingModel` adalah representasi status fasilitas benteng.
   - `Shared Warehouse` (Phase 3) tetap menjadi satu-satunya sumber inventaris perlengkapan; tidak ada gudang sekunder.
3. **Conservation Invariants**:
   - Populasi: $\text{Total Population} = \text{Civilians} + \text{Workers} + \text{Soldiers}$.
   - Tenaga Kerja: $\text{Total Workers} = \text{Assigned Workers} + \text{Idle Workers}$, dengan $\text{Assigned} = \text{Blacksmith} + \text{Repair} + \text{Construction}$.
   - Pergudangan: $\text{Total Owned} = \text{USBL} + \text{DMGD} + \text{HERO} + \text{REGD}$.
   - Integritas Fisik: $0 \le \text{current\_hp} \le \text{max\_hp}$, $0 \le \text{wall\_hp} \le \text{wall\_max\_hp}$, $0 \le \text{gate\_hp} \le \text{gate\_max\_hp}$.
4. **Battle Lock Enforcement**: Seluruh mutasi manajemen benteng (alokasi pekerja, konversi populasi, reparasi manual, konstruksi bangunan, alokasi serdadu, alokasi hero) dilarang keras saat status state machine berada pada `STATE_BATTLE`.
5. **No Combat/Wave in Phase 5**: Sistem simulasi gelombang, kalkulasi damage tempur taktis, dan perintah komandan real-time tetap menjadi milik Phase 6. Tombol `Start Battle` dinonaktifkan (*disabled*) pada Phase 5.
6. **Lightweight & Event-Driven**: Tidak ada polling `_process()` pada presentation layer; seluruh pembaharuan UI reaktif terhadap sinyal `state_changed(snapshot)` dari `GameCoordinator`.

---

## 2. Domain Layer Extensions

### A. Fortress Model (`scripts/domain/model/fortress_model.gd`)
Memperluas `FortressModel` yang sudah ada:
- Atribut eksisting: `max_hp`, `current_hp`, `armor`, `upgrade_tier`.
- Atribut baru pertahanan:
  - `wall_max_hp: int = 500`
  - `wall_hp: int = 500`
  - `gate_max_hp: int = 300`
  - `gate_hp: int = 300`
- Invariant & Batasan:
  - $0 \le \text{current\_hp} \le \text{max\_hp}$
  - $0 \le \text{wall\_hp} \le \text{wall\_max\_hp}$
  - $0 \le \text{gate\_hp} \le \text{gate\_max\_hp}$
  - Nilai damage $\ge 0$, nilai repair $\ge 0$.
- Metode Baru:
  - `damage_wall(amount: int) -> int`: mereduksi `wall_hp`, clamp di 0.
  - `repair_wall(amount: int) -> int`: menambah `wall_hp`, clamp di `wall_max_hp`.
  - `damage_gate(amount: int) -> int`: mereduksi `gate_hp`, clamp di 0.
  - `repair_gate(amount: int) -> int`: menambah `gate_hp`, clamp di `gate_max_hp`.
  - `is_wall_breached() -> bool`: return `wall_hp <= 0`.
  - `is_gate_breached() -> bool`: return `gate_hp <= 0`.
- Pembaruan `clone()` menduplikasi seluruh atribut wall dan gate.

### B. Population Model (`scripts/domain/model/population_model.gd`)
Memperluas `PopulationModel` yang sudah ada:
- Atribut eksisting: `civilians`, `housing_capacity`, `morale`, `mercenaries`, `soldiers` dictionary.
- Atribut baru tenaga kerja:
  - `workers: int = 0`
- Persamaan Konservasi:
  $$\text{get\_total\_population}() = \text{civilians} + \text{workers} + \text{get\_total\_soldiers}()$$
- Metode Konversi Zero-Sum:
  - `civilian_to_worker(count: int) -> bool`: memindahkan `count` dari `civilians` ke `workers` (gagal jika `civilians < count` atau `count <= 0`).
  - `worker_to_civilian(count: int) -> bool`: memindahkan `count` dari `workers` ke `civilians` (gagal jika `workers < count` or `count <= 0`).
  - `get_civilian_count() -> int`: mengembalikan `civilians`.
  - `get_worker_count() -> int`: mengembalikan `workers`.
  - `get_soldier_count() -> int`: mengembalikan `get_total_soldiers()`.
- Validasi Invarian: seluruh nilai populasi $\ge 0$.
- Pembaruan `clone()` menduplikasi `workers`.

### C. Worker Model (`scripts/domain/model/worker_model.gd`)
Model domain murni baru turunan `RefCounted` untuk mengelola tenaga kerja agregat:
- Pekerjaan Kanonikal MVP:
  - `JOB_IDLE = "IDLE"`
  - `JOB_BLACKSMITH = "BLACKSMITH"`
  - `JOB_REPAIR = "REPAIR"`
  - `JOB_CONSTRUCTION = "CONSTRUCTION"`
- State Atribut:
  - `total_workers: int = 0`
  - `blacksmith_workers: int = 0`
  - `repair_workers: int = 0`
  - `construction_workers: int = 0`
  - `idle_workers: int = 0`
  - `morale: int = 100` ($0 \le \text{morale} \le 100$)
- Produktivitas Turunan:
  $$\text{Productivity} = \text{clampf}(\text{float}(\text{morale}) / 100.0, 0.5, 1.25)$$
- Invarian Pekerja:
  $$\text{assigned\_workers} + \text{idle\_workers} == \text{total\_workers}$$
  $$\text{assigned\_workers} = \text{blacksmith\_workers} + \text{repair\_workers} + \text{construction\_workers}$$
- Metode:
  - `sync_total_workers(new_total: int) -> void`: menyesuaikan `total_workers` dan mengarahkan selisih ke `idle_workers` (atau mereduksi penugasan secara aman jika total mengecil).
  - `set_allocations(rep: int, smith: int, constr: int) -> bool`: validasi atomik total $\le \text{total\_workers}$.
  - `reassign(from_job: String, to_job: String, count: int) -> bool`: mutasi atomik antar-job.
  - `modify_morale(delta: int) -> void`: pergeseran moral dalam batas $0–100$.
  - `clone() -> WorkerModel`, `to_dictionary() -> Dictionary`, `from_dictionary(dict: Dictionary) -> WorkerModel`.

### D. Building Model (`scripts/domain/model/building_model.gd`)
Model domain murni baru turunan `RefCounted` untuk mewakili fasilitas benteng:
- Tipe Bangunan Kanonikal MVP:
  - `FORTRESS` (Benteng Utama)
  - `WALL` (Tembok Pertahanan)
  - `GATE` (Gerbang Benteng)
  - `BARRACKS` (Barak Militer)
  - `BLACKSMITH` (Pandai Besi)
  - `WAREHOUSE` (Gudang Senjata)
  - `TRAINING_FACILITY` (Fasilitas Latihan Pahlawan)
  - `MERCENARY_GUILD` (Guild Tentara Bayaran & Rekrutmen Pahlawan)
  - `CONSTRUCTION_AREA` (Area Pembangunan)
- Atribut:
  - `building_id: String`
  - `building_type: String`
  - `building_name: String`
  - `level: int = 1`
  - `is_built: bool = true`
  - `max_level: int = 5`
- Metode:
  - `can_upgrade() -> bool`, `upgrade() -> bool`.
  - `clone() -> BuildingModel`, `to_dictionary() -> Dictionary`, `from_dictionary(dict: Dictionary) -> BuildingModel`.

### E. Repair & Construction Task Models
- **RepairTask**: target struktur (`FORTRESS`, `WALL`, `GATE`), HP yang diperbaiki, kebutuhan pekerja perbaikan, biaya emas per HP ($0.15 \text{ Gold/HP}$ konsisten dengan Phase 2), status aktif/selesai.
- **ConstructionTask**: ID tugas, target gedung (`target_building_id`), pekerja yang ditugaskan, progres saat ini, target progres, biaya emas konstruksi, status aktif/selesai.

---

## 3. Application & Orchestration Layer (`GameCoordinator`)

Memperluas `GameCoordinator`:
1. **Inisialisasi Fasilitas Benteng**:
   Inisialisasi 9 gedung kanonikal pada kamus `_buildings: Dictionary`:
   - `fortress_main` (`FORTRESS`, Lv 1)
   - `wall_outer` (`WALL`, Lv 1)
   - `gate_main` (`GATE`, Lv 1)
   - `barracks` (`BARRACKS`, Lv 1)
   - `blacksmith` (`BLACKSMITH`, Lv 1)
   - `warehouse` (`WAREHOUSE`, Lv 1)
   - `training_facility` (`TRAINING_FACILITY`, Lv 1)
   - `mercenary_guild` (`MERCENARY_GUILD`, Lv 1)
   - `construction_area` (`CONSTRUCTION_AREA`, Lv 1)
2. **Koordinasi Pekerja & Populasi**:
   - Sinkronisasi `_worker_model` dengan `_population.workers`.
   - `convert_civilian_to_worker(count: int) -> bool`: dilindungi Battle Lock, transaksi zero-sum atomik.
   - `convert_worker_to_civilian(count: int) -> bool`: dilindungi Battle Lock, transaksi zero-sum atomik.
   - `allocate_workers(repair: int, blacksmith: int, construction: int) -> bool`: memperbarui `_worker_model` dan `_economy` secara sinkron.
3. **Koordinasi Reparasi Fisik Benteng**:
   - `repair_structure(target: String, amount: int) -> bool`:
     - Target sah: `FORTRESS`, `WALL`, `GATE`.
     - Dilindungi Battle Lock (hanya pada `STATE_PREPARATION` atau transisi recovery).
     - Mengharuskan `repair_workers > 0`.
     - Validasi kas bendahara benteng ($\lceil \text{amount} \times 0.15 \rceil \text{ Gold}$).
     - Transaksi atomik: potong emas kas $\rightarrow$ eksekusi reparasi pada model struktur $\rightarrow$ rollback kas jika reparasi gagal.
4. **Koordinasi Konstruksi Bangunan**:
   - `start_construction(target_building_id: String, gold_cost: int, target_progress: int) -> bool`:
     - Dilindungi Battle Lock.
     - Mengharuskan `construction_workers > 0` dan saldo kas mencukupi.
     - Transaksi atomik pemotongan kas awal dan registrasi task konstruksi aktif.
   - `advance_construction(progress_delta: int) -> bool`:
     - Dilakukan secara deterministik berdasarkan alokasi pekerja konstruksi.
     - Otomatis memicu penyelesaian gedung (`building.upgrade()`) saat progres mencapai target.
   - `cancel_construction() -> bool`:
     - Membatalkan proyek aktif dan mengembalikan saldo kas yang belum terpakai secara aman.
5. **Snapshot Synchronization**:
   Memperbarui `_update_snapshot()` untuk menserialisasikan:
   - Data pertahanan benteng (`fortress_data`: `wall_hp`, `wall_max_hp`, `gate_hp`, `gate_max_hp`).
   - Data populasi (`population_data`: `workers`, `civilian_count`, `worker_count`, `soldier_count`).
   - Data tenaga kerja (`worker_data`: alokasi detail, moral, produktivitas).
   - Data fasilitas bangunan (`buildings_data`).
   - Data perbaikan & konstruksi aktif (`active_repair_data`, `active_construction_data`).

---

## 4. Presentation & UI Integration (`PrototypeDebugView` & `GameController`)

### A. GameController Delegation
Menambahkan metode pembantu delegasi ke `GameCoordinator`:
- Kueri & Mutasi Populasi: `get_civilian_count()`, `get_worker_count()`, `get_soldier_count()`, `convert_civilian_to_worker(count)`, `convert_worker_to_civilian(count)`.
- Kueri & Mutasi Pekerja: `get_worker_allocations()`, `get_worker_morale()`, `get_worker_productivity()`.
- Kueri & Mutasi Pertahanan/Reparasi: `get_fortress_defense_data()`, `repair_structure(target, amount)`.
- Kueri & Mutasi Fasilitas: `get_buildings()`, `get_building(id)`, `upgrade_building(id)`, `start_construction(target_id, cost, progress)`.

### B. PrototypeDebugView Layout (Mengacu Low-Fi Wireframe)
Mengadaptasi tata letak wireframe 960×440 secara fungsional dan modular:
1. **Left Sidebar Panel**:
   - Tombol Navigasi: `Benteng` (Aktif), `Bangun`, `Rakyat`, `Pasukan`, `Riset` (Placeholder), `Misi` (Placeholder), `Atur` (Placeholder).
2. **Header Bar**:
   - Nama Benteng: `Benteng Utama`
   - Label Konteks: `Peta & Pertahanan`
   - Telemetri Sumber Daya: `Gold: <kas>`, `Civilian: <sipil>`, `Workers: <pekerja>`, `Soldiers: <serdadu>`
   - Status Fase: `PREPARATION / WAVE_PREVIEW / BATTLE / ...`
3. **Center — Main Fortress Screen**:
   - Status Pertahanan:
     - Benteng Utama: `<current_hp> / <max_hp>` + Bar Indikator
     - Tembok Pertahanan (Wall): `<wall_hp> / <wall_max_hp>` + Bar Indikator
     - Gerbang Utama (Gate): `<gate_hp> / <gate_max_hp>` + Bar Indikator
   - Kontrol Reparasi Cepat: Tombol reparasi benteng, tembok, dan gerbang berbasis ketersediaan pekerja reparasi dan kas emas.
   - Status Bangunan / Konstruksi: Daftar fasilitas dan progres pembangunan aktif.
   - Status Alokasi Pekerja: Pengaturan cepat alokasi 4 pekerjaan (`IDLE`, `BLACKSMITH`, `REPAIR`, `CONSTRUCTION`).
4. **Right Management Panel (Tabs)**:
   - **Tab Deployed Unit**: Menampilkan regu prajurit yang ditugaskan (Phase 3).
   - **Tab Hero**: Menampilkan ringkasan pahlawan kanonikal Phase 4 (Level, Bintang, Peran, Status Regu, Moral, Fatigue, Chemistry) secara read-only.
   - **Tab Gudang Senjata**: Menampilkan stok Shared Warehouse kanonikal Phase 3 (Usable vs Damaged) secara read-only.
5. **Bottom Action Bar**:
   - Tombol `Start Battle`: **DISABLED** (Phase 5 bukan Combat; dialihkan ke Phase 6).
   - Tombol `Aksi / Bantuan`: Tombol pintasan kontekstual.
   - Banner Umpan Balik (`_lbl_feedback_banner`): Konfirmasi sukses atau alasan penolakan transaksi.

---

## 5. Testing & Verification Architecture

### A. Test Suite Mandiri (`tests/test_phase5_fortress_management.gd`)
Menyediakan minimal 70 pengujian terstruktur:
1. **Group A: Fortress & Wall/Gate Defense (10+ tests)**:
   - Inisialisasi awal valid, invarian $0 \le \text{hp} \le \text{max}$, damage wall/gate, repair wall/gate, pencegahan over-repair, deteksi breach, penolakan damage/repair negatif.
2. **Group B: Population Accounting & Conservation (10+ tests)**:
   - Inisialisasi hitungan awal, konversi civilian $\rightarrow$ soldier, konversi civilian $\rightarrow$ worker, konversi worker $\rightarrow$ civilian, pelestarian persamaan konservasi $\text{Civilians} + \text{Workers} + \text{Soldiers} == \text{Total}$, penolakan over-allocation, penolakan nilai negatif, pengurangan korban perang permanen.
3. **Group C: Worker Allocation, Jobs & Productivity (15+ tests)**:
   - Penugasan 4 pekerjaan sah (`IDLE`, `BLACKSMITH`, `REPAIR`, `CONSTRUCTION`), pembuktian `assigned + idle == total`, mutasi perpindahan antar-job, penolakan penugasan melebihi total pekerja, ketiadaan duplikasi pekerja, penyesuaian otomatis saat total pekerja berubah, moral pekerja $0–100$, dan derivasi produktivitas deterministik.
4. **Group D: Building & Facility Foundation (10+ tests)**:
   - Inisialisasi 9 gedung kanonikal, validasi tipe sah vs tidak sah, kueri fasilitas, kenaikan level gedung, batas maksimal level gedung, deep copy kloning dan serialisasi snapshot.
5. **Group E: Repair System Foundation (10+ tests)**:
   - Validasi target perbaikan (`FORTRESS`, `WALL`, `GATE`), penolakan perbaikan jika tidak ada `repair_workers`, validasi kecukupan kas emas, kalkulasi biaya perbaikan tepat $0.15 \text{ Gold/HP}$, transaksi atomik perbaikan, rollback kas saat gagal, pencegahan perbaikan melampaui max HP.
6. **Group F: Construction System Foundation (5+ tests)**:
   - Pendaftaran tugas konstruksi, validasi `construction_workers > 0`, penambahan progres bertahap, deteksi penyelesaian dan peningkatan level gedung, pembatalan konstruksi secara aman.
7. **Group G: UI, Controller, Snapshot & Battle Lock (10+ tests)**:
   - Delegasi `GameController` ke `GameCoordinator`, serialisasi & isolasi memori snapshot `GameStateSnapshot`, penegakan mutlak Battle Lock (seluruh mutasi diblokir saat `STATE_BATTLE`), ketiadaan mutasi langsung dari presentasi.
8. **Group H: Deterministic 100-Cycle Management Stress Test (1 test)**:
   - Menjalankan 100 siklus manajemen berturut-turut yang mensimulasikan konversi populasi, rotasi pekerja, perbaikan struktur, konstruksi gedung, integrasi hero/gudang, dan verifikasi snapshot.
   - Memvalidasi di setiap siklus: tidak ada nilai negatif, tidak ada pelanggaran konservasi populasi, tidak ada pelanggaran konservasi gudang, tidak ada kerusakan state machine, dan tidak ada kebocoran referensi snapshot.

---

## 6. Execution Plan & Checklist

- [x] Simpan dan arsipkan low-fi wireframe di `docs/design/wireframes/fortress-main-screen/`
- [x] Dokumentasikan indeks wireframe di `docs/design/WIREFRAME_INDEX.md`
- [x] Buat dokumen rancangan teknis `docs/design/PHASE_5_FORTRESS_MANAGEMENT_PLAN.md`
- [x] Implementasikan ekstensi domain:
  - [x] Perluas `FortressModel` (Wall HP, Gate HP, repair/damage methods, invarian)
  - [x] Perluas `PopulationModel` (Workers accounting, civilian $\leftrightarrow$ worker conversions)
  - [x] Buat `WorkerModel` (4 pekerjaan sah, moral, produktivitas)
  - [x] Buat `BuildingModel` (9 fasilitas kanonikal, upgrade logic)
- [x] Implementasikan ekstensi orkestrasi `GameCoordinator`:
  - [x] Inisialisasi fasilitas & worker model
  - [x] API populasi & alokasi pekerja
  - [x] API reparasi struktur atomik
  - [x] API konstruksi gedung
  - [x] Penegakan Battle Lock pada seluruh API baru
- [x] Perluas `GameStateSnapshot` (Fortress defense, population, workers, buildings, repair/construction)
- [x] Perluas `GameController` (metode delegasi presentasi)
- [x] Perbarui `PrototypeDebugView` mengadopsi tata letak Wireframe (Sidebar, Header, Center Fortress, Right Tabs, Bottom Bar)
- [x] Buat test suite komprehensif `tests/test_phase5_fortress_management.gd` (82 tests inklusif 100-cycle stress test)
- [x] Jalankan verifikasi test suite Phase 5, Full Regression (17 suite), Scene Smoke Playtest
- [x] Perbarui dokumentasi: `plans/CURRENT_PHASE.md`, `plans/ROADMAP.md`, `plans/CHANGELOG.md`
- [x] Commit dan push ke `origin/main`
- [x] Laporkan hasil dan STOP (tunggu approval Phase 6)

---

## 7. Verification Summary & Test Metrics

- **Phase 5 Dedicated Test Suite (`tests/test_phase5_fortress_management.gd`)**:
  - Total Tests: **82 / 82 PASSED (100%)**, 0 FAILED.
  - Group A (Fortress & Wall/Gate Defense): 14/14 PASS.
  - Group B (Population Accounting & Conservation): 11/11 PASS.
  - Group C (Worker Allocation, Jobs & Productivity): 16/16 PASS.
  - Group D (Building & Facility Foundation): 10/10 PASS.
  - Group E (Repair System Foundation): 11/11 PASS.
  - Group F (Construction System Foundation): 7/7 PASS.
  - Group G (UI, Controller, Snapshot & Battle Lock): 12/12 PASS.
  - Group H (Deterministic 100-Cycle Management Stress Test): 1/1 PASS.
- **Full Automated Regression Suite**:
  - **677 / 677 PASSED (100%)** across 17 test suites (Phase 1 through Phase 5).
  - Regressions: **0**.
- **Scene Smoke Playtest (`tests/test_playtest_smoke.gd`)**:
  - **ALL PASS, 0 ERRORS** on Godot SceneTree.
- **Phase 5 Status**: **COMPLETED / CLOSED**. Phase 6 is **LOCKED**.
