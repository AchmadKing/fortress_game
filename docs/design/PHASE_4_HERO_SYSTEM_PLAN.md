# Phase 4 — Hero System Technical Plan & Architecture Specification

## Project Context
- **Project:** `fortress_game`
- **Repository:** `https://github.com/AchmadKing/fortress_game.git`
- **Branch:** `main`
- **Current Phase:** Phase 4 — Hero System
- **Current Status:** AUTHORIZED / PLANNING
- **Previous Phases:** Phase 0–3 COMPLETED & OFFICIALLY CLOSED (Commit `e6c0c97`)

---

## A. Phase Objective

Phase 4 bertujuan membangun **Hero System (Sistem Pahlawan & Komandan)** yang utuh, mendalam, dan modular, memperluas fondasi hero minimal yang telah divalidasi pada Phase 1, Phase 2, dan Phase 3C/3D/3E.

Sistem pahlawan dirancang dengan kedalaman *character-management strategy RPG* yang berfokus pada:
1. Identitas dan perkembangan individual setiap pahlawan (level, EXP, stat, bintang saat ini vs potensi).
2. Peran (*Hero Role*) dan sinergi perlengkapan yang terintegrasi dengan gudang bersama (*Shared Fortress Warehouse*).
3. Pengelolaan stamina, kelelahan (*fatigue*), dan moral (*morale*).
4. Fasilitas pelatihan (*Training Facility*) dan sistem rekrutmen pahlawan (*Mercenary Guild*).
5. Pembentukan regu pahlawan (*Party System*) dan penguatan hubungan kemitraan tempur (*Hero Chemistry*).
6. Fondasi bakat dan kemampuan (*Skills & Talent Foundation*).
7. Konsekuensi kematian permanen (*Permadeath*) yang deterministik dengan jaminan konservasi kepemilikan perlengkapan.

> [!IMPORTANT]
> **Prinsip Utama: EXTEND, DON'T BREAK**
> Phase 4 BUKAN penulisan ulang (*rewrite*). DILARANG membuat `HeroModelV2`, dilarang membuat gudang inventaris kedua khusus hero, dan dilarang mengganti kontrak domain Phase 1–3 yang sudah tervalidasi. Seluruh penambahan dilakukan secara aditif di atas arsitektur yang sudah ada.

---

## B. Existing Hero Foundation Audit & Inviolable Rules

### 1. Existing Hero Foundation (Yang Wajib Dipertahankan)
Repositori pada commit `e6c0c97` telah memiliki fondasi pahlawan fungsional:
- **Model Domain (`scripts/domain/model/hero_model.gd`):**
  - Identitas: `hero_id: String`, `hero_name: String`.
  - Tingkat & EXP: `level: int = 1`, `current_exp: int = 0`.
  - Sistem Bintang: `current_star: int = 1`, `potential_star: int = 3`.
  - Stat Dasar: `base_hp: int = 250`, `base_atk: int = 35`, `base_def: int = 20`.
  - Kondisi: `fatigue: int = 0` (0–100), `morale: int = 100` (0–150), `is_alive: bool = true`.
  - Kemitraan: `chemistry_map: Dictionary` (`partner_hero_id -> points`).
  - Slot Perlengkapan (Phase 3C): `primary_equipment`, `secondary_equipment`, `armor_equipment`.
  - Metode: `equip()`, `unequip()`, `has_equipment()`, `get_equipment()`, `get_equipped_items()`, `clear_equipment()`, `get_required_exp()`, `add_exp()`, `add_fatigue()`, `rest()`, `train()`, `add_chemistry()`, `get_chemistry_bonus()`, `get_fatigue_multiplier()`, `get_effective_atk()`, `get_effective_def()`, `mark_dead()`, `clone()`.
- **Koordinasi Aplikasi (`scripts/application/coordinators/game_coordinator.gd`):**
  - Koleksi pahlawan benteng: `_heroes: Array` (default awal: `hero_alder` dan `hero_lyra`).
  - Slot perlengkapan terintegrasi gudang bersama: `equip_hero()`, `unequip_hero()`, `swap_hero_equipment()`, `get_hero()`.
  - Proteksi Battle Lock: mutasi perlengkapan hero dilarang keras saat state `BATTLE`.
  - Pengembalian perlengkapan hero permadeath tepat 1 kali pada fase `proceed_from_result()`.
  - Pemulihan kelelahan pasca-tempur (`hero.rest(20)` jika `fatigue >= 30`).
  - Serialisasi data pahlawan ke `GameStateSnapshot.heroes_data`.
- **Simulasi Pertempuran (`scripts/simulation/combat_engine.gd`):**
  - Kontribusi ATK hero ke fase pertempuran jarak dekat (*melee engagement*).
  - Penambahan kelelahan pertempuran: `hero.add_fatigue(15)`.
  - Peningkatan sinergi chemistry pahlawan dalam party tempur: `+2` poin per pertempuran.
  - Resolusi kelangsungan hidup / kematian hero deterministik berbasis bahaya jebolan, pertahanan, dan kelelahan.
  - Pembagian EXP tempur rata ke seluruh pahlawan hidup.

### 2. Aturan Penguncian Mutlak (Inviolable Rules)
- **NEVER** membuat `HeroModelV2` atau kelas paralel pengganti `HeroModel`.
- **NEVER** membuat sistem inventaris kedua khusus hero.
- **NEVER** membuat gudang (*Warehouse*) kedua. Gudang senjata benteng bersama (`_warehouse`) adalah satu-satunya sumber kepemilikan fisik perlengkapan.
- **NEVER** menduplikasi kalkulasi chemistry di luar domain `HeroModel`.
- **NEVER** menduplikasi kalkulasi EXP di luar domain `HeroModel`.
- **NEVER** menduplikasi logika kepemilikan perlengkapan hero.
- **NEVER** mengganti API Phase 3 yang sudah berjalan tanpa alasan kompatibilitas yang terbukti melalui pengujian regresi.

---

## C. Architecture Boundary & Stat Ownership

### 1. Batas Tanggung Jawab Lapisan (*Layer Boundaries*)
```
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                      │
│   (GameController, PrototypeDebugView, HeroManagementView)  │
│      - MURNI menampilkan data snapshot                     │
│      - Menangkap input aksi pemain (Train, Rest, Assign)    │
│      - DILARANG menghitung gameplay/rumus stat di UI        │
└──────────────────────────────▲──────────────────────────────┘
                               │ (Commands & Signals)
┌──────────────────────────────┴──────────────────────────────┐
│                     APPLICATION LAYER                       │
│                     (GameCoordinator)                       │
│      - Mengorkestrasi siklus hidup Hero                     │
│      - Mengelola Roster Pahlawan & Penugasan Party          │
│      - Menegakkan Battle Lock & State Transitions           │
│      - Mengkoordinasikan Gudang Bersama & Kas Emas Benteng  │
└──────────────────────────────▲──────────────────────────────┘
                               │ (Calls Simulation / Mutates Models)
┌──────────────────────────────┴──────────────────────────────┐
│                    DOMAIN & SIMULATION                      │
│         (HeroModel, HeroRole, PartyModel, CombatEngine)     │
│      - Single Source of Truth rumus stat, EXP, & kondisi    │
│      - Model data individual murni (RefCounted)             │
│      - Deterministik, bebas dependensi visual/Node          │
└─────────────────────────────────────────────────────────────┘
```

### 2. Otoritas Tunggal Kalkulasi Stat (*Stat Calculation Ownership*)
DILARANG KERAS membiarkan `HeroModel`, `GameCoordinator`, `CombatEngine`, dan `UI` masing-masing menghitung stat versinya sendiri.

**Single Source of Truth Rules:**
- **`HeroModel`** adalah pemilik tunggal dan otoritas absolut untuk seluruh formula stat pahlawan:
  - `get_effective_atk()` mengintegrasikan `base_atk`, level scaling, star scaling, chemistry bonus, fatigue multiplier, dan gear multiplier.
  - `get_effective_def()` mengintegrasikan `base_def`, level scaling, star scaling, fatigue multiplier, dan gear def multiplier.
  - `get_fatigue_multiplier()` adalah otoritas tunggal penalti kelelahan.
  - `get_chemistry_bonus()` adalah otoritas tunggal pengali sinergi kemitraan.
- **`CombatEngine`** MURNI membaca hasil `hero.get_effective_atk(party_ids)` dan `hero.get_effective_def()` dari domain. Tidak boleh menghitung ulang formula pengali stat hero secara terpisah.
- **`GameCoordinator`** hanya meneruskan nilai stat efektif ke `GameStateSnapshot` untuk keperluan telemetri.
- **`Presentation / UI`** hanya menampilkan nilai dari snapshot tanpa kalkulasi ulang.

---

## D. Domain Models & Equipment/Role Scope

### 1. Pemisahan Tegas Perlengkapan Existing vs Rencana Masa Depan
- **Perlengkapan Sah Existing (Phase 3 Equipment — UNTOUCHED):**
  - Senjata: `SWORD`, `SPEAR`, `BOW`.
  - Sekunder: `SHIELD`, `NONE`.
  - Zirah: `HEAVY_ARMOR`, `NONE`.
  - Seluruh perlengkapan ini berada di gudang bersama dan berlaku untuk serdadu maupun pahlawan.
- **Kategori Perlengkapan Masa Depan (*Future Data Extensions Only*):**
  - Konsep perlengkapan seperti `STAFF`, `MACE`, `LIGHT_ARMOR`, `CLOTH` adalah rencana data masa depan.
  - **Sub-Phase 4A DILARANG** membuat sistem inventaris baru atau menginstansiasi item jenis baru tersebut.
  - Pada Phase 4, peran pahlawan menggunakan aturan kompatibilitas perlengkapan kanonikal:
    - `KNIGHT`: `SWORD` (Primary), `SHIELD` (Secondary), `HEAVY_ARMOR` (Armor).
    - `ARCHER`: `BOW` (Primary), `NONE` (Secondary), `LIGHT_ARMOR` (Armor, future); `HEAVY_ARMOR` dilarang.
    - `MAGE`: Perlengkapan masa depan (`STAFF`, `WAND` Primary, `ROBE` Armor; seluruh perlengkapan Phase 3 tidak kompatibel).
    - `PRIEST`: Perlengkapan masa depan (`STAFF` Primary, `HOLY_EQUIPMENT` Secondary, `ROBE` Armor; seluruh perlengkapan Phase 3 tidak kompatibel).
- **Aturan Gudang & Durabilitas:**
  - Perlengkapan pahlawan tetap mengambil fisik dari gudang bersama benteng (`_warehouse`).
  - Perlengkapan pahlawan **TIDAK TERPENGARUH** oleh formula keausan serdadu maupun resolusi korban serdadu (35% hancur / 65% rusak). Perlengkapan pahlawan tetap utuh selama pahlawan hidup.

### 2. Ekstensi `HeroModel` (`scripts/domain/model/hero_model.gd`)
Mempertahankan 100% kompatibilitas backward, menambahkan field secara modular:
- `role: String = "KNIGHT"`: Nilai peran kanonikal (`KNIGHT`, `MAGE`, `ARCHER`, `PRIEST`).
- `lifecycle_state: String = "ROSTER_ACTIVE"`: Status siklus hidup pahlawan.
- `party_id: String = ""` (`"party_1"`, `"party_2"`, atau `""` jika Reserve).
- `unlocked_skills: Array[String] = []`: Daftar ID skill aktif/pasif.
- `talent_points: int = 0`: Poin bakat yang tersedia.
- `allocated_talents: Dictionary = {}`: Peta bakat teralokasi (`talent_id -> level`).
- `training_sessions_wave: int = 0`: Pelacak anti-exploit latihan per gelombang.

### 3. Peran Pahlawan Kanonikal (`HeroRole`)
Didefinisikan sebagai konstanta data-driven murni:
- Konstanta: `ROLE_KNIGHT = "KNIGHT"`, `ROLE_MAGE = "MAGE"`, `ROLE_ARCHER = "ARCHER"`, `ROLE_PRIEST = "PRIEST"`.
- Validasi peran melalui method statis: `HeroRole.is_valid_role(role: String) -> bool`.
- Kompatibilitas slot senjata/zirah diperiksa secara deterministik tanpa duplikasi kode.

### 4. Model Regu Pahlawan (`PartyModel`)
- Model data murni (`RefCounted`):
  - `party_id: String` (misal: `"party_1"`, `"party_2"`).
  - `party_name: String`.
  - `leader_hero_id: String`.
  - `member_hero_ids: Array[String]`.
  - `is_deployed_to_battle: bool`.

---

## E. Data Ownership

| Komponen Data | Otoritas Kepemilikan (*Owner*) | Hak Mutasi |
| :--- | :--- | :--- |
| **Identitas, Stat, & EXP Hero** | `HeroModel` | Murni internal `HeroModel` via metode domain. |
| **Peralatan Terpasang** | `HeroModel` (Referensi) | Dikendalikan via `GameCoordinator` (Single Source Gudang Bersama). |
| **Roster Pahlawan Benteng** | `GameCoordinator` (`_heroes`) | `recruit_hero()`, `dismiss_hero()`, `proceed_from_result()`. |
| **Penugasan Party** | `GameCoordinator` / `PartyModel` | `assign_hero_to_party()`, `remove_hero_from_party()`. |
| **Fasilitas Latihan** | `GameCoordinator` & `EconomyManager` | `train_hero()`, konsumsi Gold dan kelelahan. |
| **Perhitungan Tempur** | `CombatEngine` | Murni membaca stat efektif pahlawan saat pertempuran. |

---

## F. Hero Lifecycle & States

### 1. State Siklus Hidup Pahlawan (`HeroLifecycleState`)
- `RECRUITABLE`: Berada di bursa Mercenary Guild, belum menjadi bagian benteng.
- `ROSTER_ACTIVE`: Terdaftar resmi di benteng sebagai cadangan (*Reserve*) atau bertugas di barak.
- `IN_PARTY`: Ditugaskan ke dalam salah satu regu tempur pahlawan.
- `IN_TRAINING`: Sedang menjalani sesi latihan pada fase persiapan.
- `BATTLE_ACTIVE`: Sedang berada di medan laga aktif (berlaku Battle Lock).
- `PERMADEATH`: Gugur di medan laga; seluruh perlengkapan dikembalikan ke gudang, status `is_alive = false`.

### 2. Diagram Transisi Siklus Hidup
```mermaid
stateDiagram-v2
    [*] --> RECRUITABLE: Pool Mercenary Guild
    RECRUITABLE --> ROSTER_ACTIVE: recruit_hero() (Kas Emas Terpotong)
    
    state ROSTER_ACTIVE {
        [*] --> RESERVE: Berada di Barak
        RESERVE --> IN_TRAINING: train_hero() (+EXP, +Fatigue)
        IN_TRAINING --> RESERVE: Selesai Latihan
        RESERVE --> IN_PARTY: assign_hero_to_party()
        IN_PARTY --> RESERVE: remove_hero_from_party()
    }
    
    IN_PARTY --> BATTLE_ACTIVE: Wave Preview -> Start Battle
    
    state BATTLE_ACTIVE {
        [*] --> FIGHTING: Battle Lock Aktif
        FIGHTING --> SURVIVED: Resolusi Bertahan
        FIGHTING --> CASUALTY: Resolusi Kematian Deterministik
    }
    
    SURVIVED --> IN_PARTY: Recovery Phase (+EXP, +Chemistry, Rest)
    CASUALTY --> PERMADEATH: proceed_from_result()
    
    state PERMADEATH {
        [*] --> RETURN_GEAR: Kembalikan Gear ke Gudang (Tepat 1x)
        RETURN_GEAR --> REMOVED: Dikeluarkan dari Roster Aktif
    }
    
    REMOVED --> [*]
```

---

## G. Recruitment Flow (Mercenary Guild)

1. **Penyegaran Kandidat Deterministik:**
   - Awal fase `PREPARATION`: `GameCoordinator` menyediakan 2–3 kandidat hero di bursa sewa.
   - Kandidat dibuat secara deterministik berbasis `_session_seed + current_wave`.
2. **Biaya Rekrutmen (Gold):**
   - Biaya Rekrutmen Kanonikal MVP: `500 Gold` (`GameCoordinator.HERO_RECRUITMENT_COST_DEFAULT`).
   - Biaya bersifat mutlak dan otoritatif dari domain/coordinator. Pemanggil (`recruit_hero`) **tidak dapat meng-override** biaya rekrutmen.
3. **Validasi:**
   - Kas benteng mencukupi ($\text{Treasury Gold} \ge 500 \text{ Gold}$).
   - Roster pahlawan benteng belum penuh (maksimal 6 pahlawan pada MVP).
   - `hero_id` unik terverifikasi (mencegah ID duplikat).

---

## H. Progression Flow & Level Caps

1. **Kenaikan Level (*Level Up*):**
   - Saat $\text{current\_exp} \ge \text{ReqEXP}(\text{level})$, level pahlawan naik $+1$.
   - Kelebihan EXP diteruskan (*carry-over*) ke tingkat berikutnya.
   - Peningkatan stat otomatis: $+12\%$ ATK dan $+10\%$ DEF per level.
   - Mendapatkan $+1$ Poin Bakat (*Talent Point*) setiap level ganjil.
2. **Batas Level Maksimal Berbasis Bintang (*Star Level Cap*):**
   - Bintang 1: Level Maksimal $10$.
   - Bintang 2: Level Maksimal $20$.
   - Bintang 3: Level Maksimal $30$.
   - Bintang 4: Level Maksimal $40$.
   - Bintang 5: Level Maksimal $50$.
   - Pahlawan yang mencapai level cap tidak dapat memperoleh EXP lebih lanjut sampai melakukan kenaikan bintang (*Ascension*).

---

## I. EXP Formulas

### 1. Kebutuhan EXP per Level
$$\text{ReqEXP}(L) = \lfloor 120.0 \times L^{1.55} \rfloor$$
- Lv 1 $\rightarrow$ 2: $120$ EXP
- Lv 2 $\rightarrow$ 3: $351$ EXP
- Lv 3 $\rightarrow$ 4: $658$ EXP
- Lv 4 $\rightarrow$ 5: $1,028$ EXP

### 2. Perolehan EXP Tempur
Dibagikan secara merata kepada seluruh pahlawan yang bertarung dan bertahan hidup:
$$\text{EXP}_{\text{battle}} = \left\lfloor 60.0 \times \left(1.0 + \frac{\text{Wave}}{15.0}\right) \right\rfloor$$

---

## J. Star / Potential Progression Rules (Ascension)

1. **Integritas Bintang:**
   $$1 \le \text{current\_star} \le \text{potential\_star} \le 5$$
2. **Syarat Kenaikan Bintang (*Ascension*):**
   - Pahlawan mencapai level cap pada bintangnya saat ini ($\text{level} == \text{current\_star} \times 10$).
   - Pahlawan belum mencapai batas potensi ($\text{current\_star} < \text{potential\_star}$).
   - Membayar biaya emas benteng: $\text{Ascension Cost} = \text{current\_star} \times 150 \text{ Gold}$.
3. **Efek Ascension:**
   - `current_star` bertambah $+1$.
   - Batas level terbuka ke tingkat berikutnya.
   - Pengali stat tempur bertambah $+20\%$ per bintang:
     $$\text{Star Multiplier} = 1.0 + (\text{current\_star} - 1) \times 0.20$$

---

## K. Fatigue Rules

1. **Batas Nilai:** Integer $0$ hingga $100$.
2. **Penumpukan Kelelahan:**
   - Bertempur di medan laga: $+15$ poin per pertempuran.
   - Sesi latihan di benteng: $+25$ poin per sesi latihan.
3. **Dampak Kelelahan:**
   - **Kinerja Tempur:** Jika $\text{fatigue} > 20$, daya serang dan pertahanan tereduksi linier hingga batas bawah $40\%$ ($\text{fatigue} = 100$).
   - **Risiko Permadeath:** Kelelahan memperbesar peluang gugur deterministik saat tembok benteng jebol hingga $+60\%$.
   - **Kesiapan Latihan:** Jika $\text{fatigue} \ge 75$, pahlawan dilarang berlatih (*exhausted*).
4. **Pemulihan Kelelahan:**
   - Istirahat pasca-tempur normal (fase RECOVERY): $-20$ poin.
   - Istirahat penuh di barak (status `RESERVE`): $-40$ poin.

---

## L. Morale Rules

1. **Batas Nilai:** Integer $0$ hingga $150$ (baseline normal = $100$).
2. **Dinamika Moral:**
   - Kemenangan gelombang: $+5$ poin.
   - Jebolan tembok parah: $-10$ poin.
   - Rekan pahlawan gugur permanen: $-25$ poin.
3. **Efek Moral:**
   - **Tinggi ($\text{morale} \ge 120$):** Bonus $+5\%$ efektivitas stat.
   - **Normal ($80 \le \text{morale} < 120$):** Tanpa modifikator.
   - **Rendah ($\text{morale} < 80$):** Penalti $-10\%$ efektivitas stat.

---

## M. Training Rules (Training Facility)

1. **Waktu Akses:** Dilakukan secara interaktif pada fase `PREPARATION`.
2. **Biaya & Hasil:**
   - Biaya: $25$ Gold dari kas bendahara benteng.
   - Hasil: $+150$ EXP seketika dan $+25$ poin kelelahan (*fatigue*).
3. **Syarat & Larangan:**
   - Pahlawan dalam keadaan hidup dan $\text{fatigue} < 75$.
   - Kas benteng mencukupi ($\ge 25$ Gold).
   - Pahlawan belum mencapai level cap bintang saat ini.
4. **Klarifikasi Batasan Anti-Exploit:**
   - Aturan `maksimal 1 sesi latihan per pahlawan per gelombang` adalah **aturan pembatasan anti-exploit** agar pemain tidak menghabiskan seluruh kas emas untuk menaikkan level instan dalam satu gelombang.
   - Ini **BUKAN** batasan kapasitas gedung fasilitas latihan benteng. Fasilitas benteng itu sendiri tidak memiliki batasan kapasitas kuota pahlawan pada MVP.

---

## N. Chemistry Rules & Ownership

1. **Otoritas Tunggal Chemistry:**
   - `HeroModel` adalah pemilik tunggal peta kemitraan (`chemistry_map`) dan kalkulasi bonus (`get_chemistry_bonus`).
   - Dilarang membuat peta chemistry paralel di `CombatEngine` maupun `GameCoordinator`.
2. **Mekanik Perkembangan Positif:**
   - Pasangan pahlawan yang bertarung bersama dalam satu party memperoleh $+2$ poin per pertempuran (maksimal $50$ poin per pasangan).
   - Bonus efektivitas tempur:
     $$\text{Chemistry Multiplier} = 1.0 + (\text{Total Chemistry Points with Active Party} \times 0.005)$$
   - Murni mekanik sinergi positif tanpa penalti kecemburuan atau permusuhan.
   - Pahlawan yang gugur permanen menghapus catatan kemitraannya.

---

## O. Party Model Scope & Limitations

1. **Batasan Manajemen Regu Phase 4:**
   - Maksimal **2 regu** dalam fondasi manajemen (`Party 1` dan `Party 2`).
   - Maksimal **3 pahlawan** per regu.
   - Setiap pahlawan hanya boleh terdaftar di maksimal satu regu.
   - Pahlawan yang tidak ditugaskan ke regu berstatus `RESERVE` (istirahat di barak).
2. **Batasan Tempur Sementara Phase 4 (*Temporary Management Limitation*):**
   - Pada Phase 4, **hanya `Party 1` yang diteruskan ke `CombatEngine` sebagai regu tempur aktif**.
   - `Party 2` berfungsi murni sebagai struktur data organisasi cadangan dan persiapan rotasi pemain di barak. `Party 2` belum memiliki fungsi taktis medan laga di Phase 4.
3. **Batas Tegas (Out of Scope untuk Phase 4):**
   - DILARANG mengimplementasikan pergerakan taktis medan tempur, pergantian party saat pertempuran berlangsung (*mid-battle party switching*), pathfinding, formasi fisik visual, dan perintah taktis party. Seluruh aspek tersebut milik Phase 6.

---

## P. Skill & Talent Foundation

1. **Arsitektur Ringan:**
   - Model data `HeroSkill` mewarisi `RefCounted`.
   - Menampung nama, peran, syarat level, tipe (Pasif Stat / Aura), dan pengali kekuatan.
2. **Pohon Bakat Sederhana (*Simple Talent Tree*):**
   - Tiga cabang bakat dasar per peran (contoh Knight: *Offense, Defense, Leadership*).
   - Alokasi menggunakan Poin Bakat (*Talent Points*) yang diperoleh saat naik level ganjil.

---

## Q. Equipment Integration & Shared Warehouse Invariant

1. **Konservasi Kepemilikan Fisik:**
   $$\text{Total Owned} = \text{Warehouse Usable} + \text{Warehouse Damaged} + \text{Hero Held} + \text{Soldier Reserved}$$
2. **Persistensi Pahlawan Selamat:**
   - Perlengkapan pahlawan yang selamat tetap terpasang lintas gelombang dan tidak kembali ke gudang kecuali dilepas manual.
3. **Isolasi dari Aturan Aus Serdadu:**
   - Perlengkapan pahlawan tidak mengalami degradasi keausan tempur rutin dan tidak terkena aturan korban 35% musnah / 65% rusak.
4. **Proteksi Battle Lock:**
   - Seluruh mutasi perlengkapan hero (`equip`, `unequip`, `swap`) dilarang keras saat state `BATTLE`.

---

## R. Death / Permadeath Handling

1. **Evaluasi Deterministik:**
   - Dihitung saat pertempuran di `CombatEngine._resolve_hero_survival_and_death`.
2. **Prosedur Pasca-Kematian:**
   - Status diubah menjadi `is_alive = false`.
   - Pada fase `proceed_from_result()`:
     - Seluruh perlengkapan yang terpasang pada pahlawan gugur dikembalikan ke gudang benteng **tepat satu kali**.
     - Slot perlengkapan pahlawan dikosongkan (`clear_equipment()`).
     - Pahlawan dikeluarkan dari regu tempur.
     - Invariant gudang bersama terbukti tetap seimbang.

---

## S. UI & Interaction Scope (Prototype Debug View)

Perluasan visual interaktif pada `prototype_debug_view.gd` dirancang fungsional dan modular:
1. **Hero Roster List:** Menampilkan kartu pahlawan, level, EXP, bintang/potensi, kelelahan, moral, peran, dan perlengkapan.
2. **Party Management Panel:** Penugasan pahlawan ke `Party 1`, `Party 2`, atau `Reserve`.
3. **Training & Ascension Controls:** Tombol `[Latih Pahlawan]` dan `[Ascension Bintang]`.
4. **Mercenary Guild Board:** Daftar pahlawan yang dapat disewa pada fase PREPARATION.

---

## T. Test Strategy

Setiap sub-fase Phase 4 wajib menyertakan automated headless test suite:
1. **Unit Test Domain:** Logika stat, EXP curve, batas kelelahan, dan alokasi poin bakat.
2. **Integration Test:** Perekrutan, penugasan party, eksekusi latihan, dan persistensi perlengkapan lintas gelombang.
3. **Permadeath & Conservation Test:** Pengembalian perlengkapan hero gugur dan integritas invarian gudang bersama.
4. **Stress & Stability Test:** Menjalankan multi-wave hero progression tanpa kebocoran memori atau loop tak terbatas.

---

## U. Regression Strategy & Inviolable Baseline

- **Baseline Pengujian Wajib (100% PASS):**
  - Phase 1 Architecture Boundaries: **5/5 PASS**
  - Phase 2 Mathematical Systems: **21/21 PASS**
  - Phase 3A Gameplay Baseline: **11/11 PASS**
  - Phase 3B Soldier Deployment: **27/27 PASS**
  - Phase 3C Hero Equipment Foundation: **22/22 PASS**
  - Phase 3D Prototype UX & Polish: **10/10 PASS**
  - Phase 3D Follow-up Corrections: **23/23 PASS**
  - Phase 3E Final Verification: **15/15 PASS**
  - Scene Smoke Playtest: **ALL PASS**
- **Total Baseline:** **134 Unit & Integration Tests + 1 Smoke Playtest Suite (100% PASS)**.
- Dilarang menghapus atau mengubah pengujian existing hanya agar kode Phase 4 terlihat lulus.

---

## V. Performance Constraints

1. Pahlawan direpresentasikan sebagai objek domain ringan (`RefCounted`).
2. Dilarang menghitung stat pahlawan setiap frame (`_process` / `_physics_process`). Kalkulasi hanya dilakukan secara reaktif saat ada mutasi state.
3. Kapasitas roster pahlawan benteng dibatasi maksimal 6 pahlawan pada MVP.
4. Perekrutan Mercenary Guild dibatasi maksimal 3 kandidat per gelombang.

---

## W. Phase 4 Sub-Phases & Explicit Dependencies

### 1. Rantai Ketergantungan (*Dependency Chain*)
```
[4A: Domain Foundation] 
       └──> [4B: Progression & Ascension] 
                 └──> [4C: Recruitment & Roster] 
                           └──> [4D: Training & Fatigue] 
                                     └──> [4E: Skills & Talents] 
                                               └──> [4F: Party & Chemistry] 
                                                         └──> [4G: Management UX] 
                                                                   └──> [4H: Integration & Verification]
```

### 2. Aturan Kerja Wajib Setiap Sub-Fase (8-Step Workflow):
1. **Inspect First:** Periksa kondisi kode dan ketergantungan existing terlebih dahulu.
2. **Define Exact Scope:** Batasi cakupan secara ketat sesuai rencana sub-fase.
3. **Implement Only That Scope:** Kerjakan hanya cakupan yang disepakati tanpa mendahului sub-fase berikutnya.
4. **Add Tests:** Buat test suite baru khusus untuk sub-fase tersebut.
5. **Run Regression:** Jalankan seluruh pengujian lama (baseline 134 test) dan test baru.
6. **Verify Smoke Playtest:** Pastikan scene prototipe tetap berfungsi tanpa regresi.
7. **Commit:** Buat git commit dengan pesan yang jelas dan terstandarisasi.
8. **Stop & Report:** Berhenti dan tunggu tinjauan/persetujuan developer sebelum membuka sub-fase berikutnya.

### 3. Batas Eksplisit Sub-Phase 4A (Hero Domain & Lifecycle Foundation) — IMPLEMENTED
- **STATUS: COMPLETED / VERIFIED (Correction Gate passed, 38/38 Tests PASS, Full Regression 172/172 Tests PASS)**
- **IN SCOPE FOR 4A (IMPLEMENTED):**
  - Definisi peran kanonikal (`HeroRole`: `KNIGHT`, `MAGE`, `ARCHER`, `PRIEST`).
  - Representasi state siklus hidup pahlawan (`HeroLifecycleState`: `RECRUITABLE`, `ROSTER_ACTIVE`, `IN_PARTY`, `IN_TRAINING`, `BATTLE_ACTIVE`, `PERMADEATH`).
  - Validasi transisi legal dan penegakan `PERMADEATH` sebagai state terminal mutlak.
  - Validasi domain hero (memastikan ID sah, nama tidak kosong, peran valid, bintang $\le$ potensi $\le 5$ tanpa silent normalization).
  - Validasi kompatibilitas peran kanonikal terhadap perlengkapan Phase 3 existing dan kontrak data future equipment (`is_equipment_compatible`).
  - Ekstensi aman pada `HeroModel` tanpa mematahkan API atau field existing.
  - Test suite mandiri `tests/test_phase4a_hero_domain_lifecycle.gd` (38/38 PASS).
  - Sinkronisasi dokumentasi teknis.
- **OUT OF SCOPE FOR 4A (DILARANG PADA 4A):**
  - Rekrutmen dan bursa Mercenary Guild (Milik 4C).
  - UI rekrutmen dan roster (Milik 4G).
  - Perubahan EXP curve dan leveling (Milik 4B).
  - Kenaikan bintang / ascension (Milik 4B).
  - Aksi latihan fasilitas benteng (Milik 4D).
  - Redesain kelelahan atau moral (Milik 4D).
  - Sistem skill dan pohon bakat (Milik 4E).
  - Model party dan chemistry baru (Milik 4F).
  - Taktik pertempuran dan AI musuh baru (Milik Phase 6).
  - Inventaris atau jenis perlengkapan baru (Dilarang).
  - Pixel art dan visual mobile final (Milik Phase 9).

### 4. Batas Eksplisit Sub-Phase 4B (Hero Progression & EXP) — IMPLEMENTED
- **STATUS: COMPLETED / VERIFIED (47/47 Tests PASS, Full Regression 219/219 Tests PASS, Scene Smoke Playtest ALL PASS)**
- **IN SCOPE FOR 4B (IMPLEMENTED):**
  - Formula kebutuhan EXP kanonikal: $\text{ReqEXP}(L) = \lfloor 120.0 \times L^{1.55} \rfloor$.
  - Progresi level hero dengan akumulasi carry-over EXP dan dukungan kenaikan multi-level seketika.
  - Batas level maksimal berbasis bintang saat ini: $\text{Level Cap} = \text{current\_star} \times 10$ ($1\star=10, 2\star=20, 3\star=30, 4\star=40, 5\star=50$). Hero di level cap tidak dapat naik level lagi.
  - Formula dan aturan kelayakan Ascension: $1 \le \text{current\_star} < \text{potential\_star} \le 5$, hero hidup, tidak permadeath, dan $\text{level} \ge \text{current\_star} \times 10$.
  - Formula biaya Ascension: $\text{current\_star} \times 150 \text{ Gold}$.
  - Transaksi atomik Ascension di `GameCoordinator`: validasi status non-BATTLE (Battle Lock), ketersediaan kas bendahara, deduksi Gold atomik, dan mutasi kenaikan bintang $+1$.
  - Formula Battle EXP kanonikal di `CombatEngine`: $\lfloor 60.0 \times (1.0 + \text{Wave} / 15.0) \rfloor$.
  - Distribusi Battle EXP deterministik kepada pahlawan yang bertahan hidup dengan pembagian rata dan alokasi sisa (*remainder*) berbasis urutan alfabetik `hero_id`.
  - Telemetri snapshot: integrasi atribut `potential_star`, `level_cap`, `can_ascend`, dan `ascension_cost` pada `GameStateSnapshot.heroes_data`.
  - Test suite mandiri `tests/test_phase4b_hero_progression.gd` (47/47 PASS).
- **OUT OF SCOPE FOR 4B (DILARANG PADA 4B):**
  - Bursa Mercenary Guild, penawaran kandidat hero, batas kapasitas roster pahlawan (Milik 4C).
  - Aksi latihan fasilitas benteng (*Training Facility*), interaksi latihan dan batas kelelahan $\ge 75$ (Milik 4D).
  - Redesain kelelahan atau dinamika moral (Milik 4D).
  - Sistem skill dan pohon bakat (Milik 4E).
  - Model party dan chemistry baru (Milik 4F).
  - Hero Management UI & Ascension UI (Milik 4G).
  - Taktik pertempuran dan AI musuh baru (Milik Phase 6).
  - Inventaris atau jenis perlengkapan baru (Dilarang).
  - Pixel art dan visual mobile final (Milik Phase 9).

### 5. Batas Eksplisit Sub-Phase 4C (Hero Recruitment & Roster Management) — COMPLETED / VERIFIED / CLOSED
- **STATUS: COMPLETED / VERIFIED / CLOSED (51/51 Tests PASS, Full Regression 270/270 Tests PASS, Scene Smoke Playtest ALL PASS)**
- **IN SCOPE FOR 4C (IMPLEMENTED & LOCKED):**
  - Biaya rekrutmen kanonikal MVP mutlak: `500 Gold` (`GameCoordinator.HERO_RECRUITMENT_COST_DEFAULT`).
  - Single source of truth biaya: `GameCoordinator.recruit_hero()` memanggil `get_hero_recruitment_cost()` secara internal dan tidak menerima parameter override biaya.
  - Alur rekrutmen hero atomik: validasi request, validasi invarian hero, validasi duplikasi ID, validasi kas emas, deduksi emas, transisi state `RECRUITABLE` $\rightarrow$ `ROSTER_ACTIVE`, penambahan ke roster `_heroes`, dan pembaruan snapshot.
  - Penolakan rekrutmen saat state `BATTLE` (Battle Lock).
  - Generator identitas pahlawan deterministik dan unik (`generate_unique_hero_id`, `generate_hero_candidate`).
  - Pencegahan duplikasi identitas hero di seluruh state game (`get_hero(id) != null`).
  - Kepemilikan dan manajemen roster benteng pada `GameCoordinator` (`get_roster_count`, `get_roster`, `get_heroes`, `has_hero`, `add_hero`, `dismiss_hero`, `remove_hero`).
  - Keamanan konservasi gudang bersama: hero hasil rekrutmen selalu berperlengkapan kosong (`PRIMARY = null, SECONDARY = null, ARMOR = null`), tidak ada pembuatan/duplikasi gear gratis.
  - Pelepasan pahlawan (`dismiss_hero`) mengembalikan seluruh perlengkapan terpasang ke gudang bersama secara aman, mempertahankan invarian konservasi $\text{Total} = \text{USBL} + \text{DMGD} + \text{HERO} + \text{REGD}$.
  - Integrasi snapshot telemetri lengkap (`heroes_data` memuat `hero_id`, `hero_name`, `role`, `lifecycle_state`, `level`, `current_exp`, `current_star`, `potential_star`, `base_hp`, `base_atk`, `base_def`, `fatigue`, `morale`, `chemistry_map`, equipment slots).
  - Test suite mandiri `tests/test_phase4c_hero_recruitment.gd` (51/51 PASS).
- **OUT OF SCOPE FOR 4C (DILARANG PADA 4C):**
  - Fasilitas latihan benteng (*Training Facility*), aksi latihan, dan batas kelelahan $\ge 75$ (Milik 4D).
  - Redesain kelelahan atau dinamika moral (Milik 4D).
  - Sistem skill aktif/pasif dan pohon bakat (Milik 4E).
  - Model party dan chemistry baru (Milik 4F).
  - Hero Management UI & Recruitment UI (Milik 4G).
  - Taktik pertempuran dan AI musuh baru (Milik Phase 6).
  - Inventaris atau jenis perlengkapan baru (Dilarang).
  - Pixel art dan visual mobile final (Milik Phase 9).

### 6. Batas Eksplisit Sub-Phase 4D (Hero Training, Fatigue & Morale) — COMPLETED / VERIFIED
- **STATUS: COMPLETED / VERIFIED (54/54 Tests PASS, Full Regression 324/324 Tests PASS, Scene Smoke Playtest ALL PASS)**
- **IN SCOPE FOR 4D (IMPLEMENTED):**
  - Reward latihan kanonikal MVP: `40 EXP` (`HeroModel.add_exp()` digunakan ulang secara penuh tanpa duplikasi).
  - Akumulasi kelelahan latihan: `+15 fatigue` per sesi latihan.
  - Batasan sesi latihan per gelombang: maksimum 1 sesi latihan per pahlawan per gelombang (`GameCoordinator.has_hero_trained_this_wave()`). Status pelacakan direset saat berpindah ke gelombang berikutnya.
  - Batas mutlak kelelahan: rentang `0–100`. Latihan ditolak mutlak jika fatigue akhir $> 100$ (misal: fatigue 85 menjadi 100 berhasil; fatigue 86 atau 100 gagal tanpa perubahan state atau EXP).
  - Aksi pemulihan istirahat (*Rest*): `GameCoordinator.rest_hero()` dan `HeroModel.rest()` memulihkan kelelahan `-25 fatigue` (minimum 0) dan menaikkan moral `+5 morale` (maksimum 150) secara atomik. Istirahat tidak merubah EXP, level, bintang, perlengkapan, chemistry, maupun kas emas.
  - Proteksi Battle Lock: Aksi latihan dan istirahat dilarang keras saat state `BATTLE`.
  - Formula multiplier kelelahan kanonikal: $\text{FatigueMultiplier} = 1.0 - (\text{fatigue} / 200.0)$ ($0 \rightarrow 1.00, 20 \rightarrow 0.90, 50 \rightarrow 0.75, 100 \rightarrow 0.50$).
  - Formula multiplier moral kanonikal: $\text{MoraleMultiplier} = 0.75 + (\text{morale} / 200.0)$ ($0 \rightarrow 0.75, 50 \rightarrow 1.00, 100 \rightarrow 1.25, 150 \rightarrow 1.50$).
  - Urutan efektivitas stat: $\text{BaseStat} \times \text{LevelMultiplier} \times \text{StarMultiplier} \times \text{FatigueMultiplier} \times \text{MoraleMultiplier} \times \text{GearMultiplier}$.
  - Integrasi snapshot telemetri lengkap (`heroes_data` memuat `trained_this_wave`, `fatigue`, `morale`, `effective_atk`, `effective_def`).
  - Test suite mandiri `tests/test_phase4d_hero_training_fatigue_morale.gd` (54/54 PASS).
- **OUT OF SCOPE FOR 4D (DILARANG PADA 4D):**
  - Sistem skill aktif/pasif dan pohon bakat (Milik 4E).
  - Model party dan chemistry baru (Milik 4F).
  - Hero Management UI & Training UI (Milik 4G).
  - Taktik pertempuran dan AI musuh baru (Milik Phase 6).
  - Bangunan benteng baru selain integrasi logika latihan (Milik Phase 5).
  - Inventaris atau jenis perlengkapan baru (Dilarang).
  - Pixel art dan visual mobile final (Milik Phase 9).

### 7. Batas Eksplisit Sub-Phase 4E (Hero Skills & Talent Foundation) — COMPLETED / VERIFIED
- **STATUS: COMPLETED / VERIFIED (62/62 Tests PASS, Full Regression 386/386 Tests PASS, Scene Smoke Playtest ALL PASS)**
- **IN SCOPE FOR 4E (IMPLEMENTED):**
  - Model data murni `HeroSkill` (`scripts/domain/model/hero_skill.gd`) turunan `RefCounted` dengan validasi invarian ketat.
  - Katalog skill kanonikal 4 peran (`HeroRole.KNIGHT`, `ARCHER`, `MAGE`, `PRIEST`) dengan tipe `PASSIVE_STAT` dan `AURA`.
  - Validasi pembukaan skill hero: kesesuaian peran, pemenuhan level minimum, pencegahan skill duplikat, dan penolakan skill non-kanonikal.
  - Perolehan Poin Bakat (*Talent Points*) berbasis tingkat ganjil (*Odd-Level Rule*): $+1$ poin setiap mencapai level ganjil (3, 5, 7, 9, dst.) saat naik level melalui `HeroModel.add_exp()`; tidak ada perolehan retroaktif saat hero dibuat di level 1; mendukung kenaikan multi-tingkat seketika.
  - Pohon bakat modular dengan 3 cabang kanonikal: `OFFENSE`, `DEFENSE`, `LEADERSHIP`, dibatasi maksimal tingkat 3 per cabang.
  - Pengali stat bakat deterministik:
    - `OFFENSE`: $+2\%$ ATK per tingkat (Lv1: 1.02, Lv2: 1.04, Lv3: 1.06).
    - `DEFENSE`: $+2\%$ DEF per tingkat (Lv1: 1.02, Lv2: 1.04, Lv3: 1.06).
    - `LEADERSHIP`: $+1\%$ ATK dan $+1\%$ DEF per tingkat (Lv1: 1.01, Lv2: 1.02, Lv3: 1.03).
    - Pengali gabungan: $\text{AtkMultiplier} = (1.0 + \text{off\_lvl} \times 0.02) \times (1.0 + \text{ldr\_lvl} \times 0.01)$, $\text{DefMultiplier} = (1.0 + \text{def\_lvl} \times 0.02) \times (1.0 + \text{ldr\_lvl} \times 0.01)$.
  - Integrasi stat efektif pahlawan: `get_effective_atk()` dan `get_effective_def()` mengalikan pengali bakat dengan backward compatibility penuh (default multiplier 1.0 saat bakat 0).
  - Proteksi Battle Lock: Aksi pembukaan skill (`unlock_hero_skill`) dan alokasi bakat (`allocate_hero_talent`) dilarang keras saat state `BATTLE`.
  - Snapshot Telemetri: Serialisasi `unlocked_skills`, `talent_points`, `allocated_talents`, `talent_atk_multiplier`, dan `talent_def_multiplier` ke dalam `GameStateSnapshot.heroes_data`.
  - Pelestarian deep-copy clone: `HeroModel.clone()` menduplikasi `unlocked_skills`, `talent_points`, dan `allocated_talents`.
  - Test suite mandiri `tests/test_phase4e_hero_skills_talents.gd` (62/62 PASS).
- **OUT OF SCOPE FOR 4E (DILARANG PADA 4E):**
  - Model party dan chemistry baru (Milik 4F).
  - Hero Management UI & Skill/Talent UI (Milik 4G).
  - Eksekusi skill tempur aktif real-time, projectile, cooldown, mana, animasi tempur (Milik Phase 6 & Phase 9).
  - Inventaris atau jenis perlengkapan baru (Dilarang).
  - Pixel art dan visual mobile final (Milik Phase 9).

### 8. Batas Eksplisit Sub-Phase 4F (Hero Chemistry & Party Management) — IMPLEMENTED & VERIFIED
- **DELIVERABLES FOR 4F (TELAH TERLAKSANA & TERVERIFIKASI):**
  - Model domain murni `PartyModel` (`scripts/domain/model/party_model.gd`, `class_name PartyModel extends RefCounted`) dengan id kanonikal `party_1` dan `party_2`, kapasitas maksimal 3 pahlawan per regu, pengelolaan anggota dan ketua regu (*leader*), kloning mendalam, serta validasi invarian.
  - Perluasan `HeroModel`: atribut `party_id: String = ""` ("" = RESERVE, "party_1", "party_2"), metode pembantu (`is_in_party`, `get_party_id`, `set_party_id`, `clear_party_assignment`), sinkronisasi status invarian dengan `HeroLifecycleState`, pembersihan otomatis saat gugur (`mark_dead()`), serta perlindungan terhadap self-chemistry (`p_id == hero_id`).
  - Refaktor `CombatEngine`: penghapusan kenaikan chemistry dari perulangan melee Phase 3, dialihkan ke satu-satunya jalur resmi pada Fase 5 pasca-kelangsungan hidup pertempuran (+2 poin per pasang hero hidup yang bertarung bersama di Party 1, batas maksimal 50, bersifat simetris mutlak).
  - Perluasan `GameStateSnapshot`: penambahan serialisasi `parties_data: Array` pada `_init`, `clone()`, `to_dictionary()`, dan `from_dictionary()`.
  - Manajemen Regu di `GameCoordinator`: inisialisasi tepat 2 regu (`party_1` dan `party_2`), API kueri, alokasi/pelepasan hero menggunakan canonical domain method `hero.set_party_id(party.party_id)` dengan transaksi atomik dan rollback penuh, penetapan ketua regu, penegakan Battle Lock selama `STATE_BATTLE`, perutean tempur eksklusif Party 1, dan pembersihan komprehensif saat permadeath (pelepasan keanggotaan regu, penghapusan ketua regu, dan penghapusan referensi chemistry secara simetris).
  - Test suite mandiri `tests/test_phase4f_hero_chemistry_party.gd` (68/68 PASS).
- **OUT OF SCOPE FOR 4F (DILARANG PADA 4F):**
  - Hero Management UI, Party Management UI, dan visual drag-and-drop (Milik 4G).
  - Formasi taktis medan tempur dan pergerakan unit real-time (Milik Phase 6).
  - Inventaris atau jenis perlengkapan baru (Dilarang).
  - Pixel art dan visual mobile final (Milik Phase 9).

### 9. Batas Eksplisit Sub-Phase 4G (Hero Management UX) — IMPLEMENTED & VERIFIED
- **DELIVERABLES FOR 4G (TELAH TERLAKSANA & TERVERIFIKASI):**
  - Integrasi antarmuka Prototype/Debug View (`scripts/presentation/views/prototype_debug_view.gd`) yang fungsional, responsif, dan ringan tanpa polling `_process()`.
  - Panel Rekrutmen Mercenary Guild: penampil biaya kanonikal (500 Gold mutlak) & kas emas, pemilih peran kandidat (Knight, Archer, Mage, Priest), dan penegakan proteksi Battle Lock serta validasi saldo kas.
  - Panel Manajemen Regu: tampilan status Party 1 (Active Battle Party) & Party 2 (Management Reserve), anggota, dan cadangan (RESERVE) dengan tombol alokasi regu, pelepasan regu, serta penetapan pemimpin regu (*Leader*).
  - Panel Roster Pahlawan: daftar pahlawan terdaftar dengan status identitas, peran, bintang/potensi, level, EXP saat ini/syarat, fatigue, morale, lifecycle state, status regu, dan indikator permadeath beserta seleksi pahlawan interaktif.
  - Panel Detail Pahlawan Terpilih:
    - Identitas & Combat Stats: HP dasar, ATK & DEF efektif beserta nilai dasar.
    - Aksi Progresi: tombol Ascension (+1★ seharga kanonikal emas), tombol Latihan (+40 EXP, +15 Fatigue), dan tombol Istirahat (-25 Fatigue, +5 Morale).
    - Katalog Keahlian Kanonikal: daftar skill peran dengan status terbuka/terkunci dan tombol pembukaan skill berbasis level minimum.
    - Pohon Bakat: 3 cabang bakat (OFFENSE, DEFENSE, LEADERSHIP), poin bakat tersedia, multiplier aktif, dan tombol alokasi poin bakat (maksimal tingkat 3).
    - Status Kemitraan (Chemistry): display-only interaktif menampilkan pasangan mitra tempur di Party 1, poin akumulasi (maks 50), dan bonus efektivitas (+0.5%/pt).
    - Kontrol Perlengkapan: aksi pasang (equip) dan lepas (unequip) senjata primer, sekunder, dan zirah terintegrasi stok gudang bersama (Shared Warehouse).
  - Penegakan Battle Lock menyeluruh: seluruh kontrol mutasi pahlawan dinonaktifkan secara ketat selama fase `BATTLE`.
  - Delegasi GameController: penambahan 20 metode delegasi pada `GameController` menghubungkan presentasi ke `GameCoordinator`.
  - Banner Umpan Balik (*Feedback Banner*): pesan konfirmasi yang jelas dan informatif untuk setiap aksi sukses atau penolakan transaksi.
  - Test suite mandiri `tests/test_phase4g_hero_management_ux.gd` (60/60 PASS mencakup Group A s/d Group J).
- **OUT OF SCOPE FOR 4G (DILARANG PADA 4G):**
  - Eksekusi skill tempur aktif real-time (cooldown, targeting, mana, projectile) (Milik Phase 6/9).
  - Aset visual final pixel-art, animasi karakter, shader visual, atau styling mobile khusus (Milik Phase 9).
  - Perubahan aturan matematis formula EXP, Ascension cost, বা batasan domain Phase 4A–4F.

### 10. Batas Eksplisit Sub-Phase 4H (Hero System Integration & Verification) — COMPLETED / VERIFIED / CLOSED
- **STATUS: COMPLETED / VERIFIED / CLOSED (81/81 Tests PASS, Full Regression 595/595 Tests PASS across 16 test suites, Scene Smoke Playtest ALL PASS)**
- **DELIVERABLES FOR 4H (TELAH TERLAKSANA & TERVERIFIKASI):**
  - **Audit Arsitektur Menyeluruh**:
    - Validasi single-source-of-truth ownership di domain, application, dan presentation layer.
    - Tidak ada duplicate manager/controller/chemistry-map (`HeroModel` adalah single source of truth untuk party_id, chemistry, dan attributes).
    - Konservasi Shared Warehouse terjaga mutlak: $\text{Total Owned} = \text{USBL} + \text{DMGD} + \text{HERO} + \text{REGD}$.
    - Penegakan Battle Lock mutlak pada 12 metode mutasi `GameCoordinator` selama status `STATE_BATTLE`.
    - Isolasi tempur Party 1 terverifikasi 100%: hanya Party 1 hero hidup yang memasuki `CombatEngine`, berkontribusi ATK, menerima EXP tempur, dan mengakumulasi fatigue tempur. Party 2 dan Reserve sepenuhnya terisolasi dari medan laga.
    - Penanganan terminal Permadeath: almarhum dilepas dari regu, dibersihkan dari posisi leader, seluruh gear dikembalikan ke gudang bersama tepat 1x, dan seluruh referensi chemistry dihapus simetris dari pahlawan lain.
  - **Comprehensive Phase 4H Test Suite** (`tests/test_phase4h_hero_system_integration.gd`):
    - 81 pengujian integrasi lintas-subsistem mencakup:
      - Group A: Hero Domain & Lifecycle Integration (Tests 1-10)
      - Group B: Party Management & Combat Routing Integration (Tests 11-20)
      - Group C: Chemistry System Integrity & Single-Path Verification (Tests 21-30)
      - Group D: Progression, EXP & Ascension Integration (Tests 31-40)
      - Group E: Fatigue, Morale & Training Integration (Tests 41-48)
      - Group F: Skills & Talents Integration (Tests 49-56)
      - Group G: Equipment & Warehouse Conservation Integration (Tests 57-66)
      - Group H: Recruitment & Ascension Economy Integration (Tests 67-72)
      - Group I: State Machine, Snapshot & Presentation Sync (Tests 73-76)
      - Group J: Permadeath End-to-End Resolution (Tests 77-80)
      - Group K: Deterministic 50-Wave Multi-System Stress Simulation (Test 81)
  - **50-Wave Multi-System Deterministic Stress Simulation**:
    - Simulasi 50 gelombang tempur penuh tanpa henti mengintegrasikan rekrutmen, penugasan regu, pembagian EXP tempur, perolehan chemistry bertahap hingga cap 50, latihan anti-exploit, kenaikan tingkat & ascension, pembukaan skill & alokasi bakat, permadeath recovery & rotasi cadangan di gelombang 25, serta penegakan konservasi perlengkapan gudang bersama di setiap gelombang.
- **OUT OF SCOPE FOR 4H (DILARANG PADA 4H):**
  - Fitur gameplay baru di luar Phase 4 (Milik Phase 5+).
  - Role pahlawan atau tipe perlengkapan baru.
  - Bangunan atau modul benteng baru (Milik Phase 5).
  - Taktik pertempuran dan AI musuh baru (Milik Phase 6).
  - Pixel art dan visual mobile final (Milik Phase 9).

---

## X. Acceptance Criteria Phase 4

Phase 4 dinyatakan selesai hanya jika seluruh kriteria berikut terpenuhi:
- [x] Model `HeroModel` telah diperluas mencakup peran kanonikal, bakat, keahlian, dan regu tanpa merusak API Phase 3.
- [x] Sistem rekrutmen Mercenary Guild berfungsi deterministik dan terintegrasi dengan kas emas benteng.
- [x] Sistem progresi level, kenaikan bintang (*Ascension*), dan pembatasan level berbasis bintang berjalan akurat.
- [x] Fasilitas latihan (*Training*) berfungsi dengan batas anti-exploit per gelombang dan penambahan kelelahan yang adil.
- [x] Pemisahan stamina (kelelahan) dan moral berfungsi independen dan mempengaruhi performa tempur.
- [x] Sistem Party memisahkan pahlawan tempur dan cadangan secara transparan.
- [x] Invariant konservasi gudang bersama $\text{Total} = \text{USBL} + \text{DMGD} + \text{HERO} + \text{REGD}$ tetap valid 100%.
- [x] Seluruh perlengkapan pahlawan permadeath kembali ke gudang bersama tepat 1 kali.
- [x] Seluruh 134 baseline test existing tetap PASS 100%.
- [x] Test suite baru untuk seluruh sub-fase Phase 4 lulus 100% (4A: 38, 4B: 47, 4C: 51, 4D: 54, 4E: 62, 4F: 68, 4G: 60, 4H: 81).
- [x] Simulasi stres multi-sistem 50 gelombang berturut-turut lulus 100% deterministik tanpa kebocoran memori, regresi, atau inkonsistensi invariant.
- [x] Scene Smoke Playtest terintegrasi lulus tanpa error di Godot Editor.
- [x] Full Automated Regression lulus 100% (595/595 PASSED across 16 test suites).
- [x] Phase 4 (Hero System) resmi DITUTUP (COMPLETED / CLOSED).

---

## Y. Explicit Exclusions (Batas Tegas di Luar Phase 4)

Hal-hal berikut **DILARANG KERAS** diimplementasikan pada Phase 4:
- ❌ Pergerakan taktis unit hero di medan tempur real-time (Milik Phase 6).
- ❌ Navigasi pathfinding dan formasi fisik di lapangan (Milik Phase 6).
- ❌ Animasi pertempuran visual kompleks, sprite pixel art final, dan visual effect (Milik Phase 9).
- ❌ Fasilitas bangunan benteng baru selain integrasi logika fasilitas latihan (Milik Phase 5).
- ❌ Sistem ekonomi lanjutan, pasar perdagangan, pajak sipil mendalam (Milik Phase 5 & 7).
- ❌ Sistem gacha berbayar, mikrotransaksi, atau mekanik real-money (Ditolak permanen dari desain game).
- ❌ Overhaul sistem save/load persistence ke database eksternal (Milik Phase 10).
