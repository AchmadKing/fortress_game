# Changelog — Fortress Game

Semua perubahan pada proyek dicatat dalam dokumen ini. Format mengacu pada prinsip Keep a Changelog.

---

## [0.5.7] - Phase 4F: Hero Chemistry & Party Management (Implemented, Verified & Closed)

### Added
- **Canonical PartyModel Pure Domain Model** (`scripts/domain/model/party_model.gd`):
  - Model data murni `PartyModel` (`class_name PartyModel extends RefCounted`) dengan konstanta id kanonikal `PARTY_1_ID = "party_1"`, `PARTY_2_ID = "party_2"`, `MAX_PARTIES = 2`, dan `MAX_MEMBERS = 3`.
  - Operasi keanggotaan regu: `add_member()`, `remove_member()`, `has_member()`, `is_full()`, `get_member_count()`, `get_members()`.
  - Operasi kepemimpinan regu (*Party Leader*): `set_leader()`, `get_leader_id()`, `has_leader()`, `clear_leader()`.
  - Kloning mendalam (`clone()`) dan validasi invarian ketat (`validate_invariants()`).
- **HeroModel Party Assignment & Chemistry Protection** (`scripts/domain/model/hero_model.gd`):
  - Properti `party_id: String = ""` ("" merepresentasikan status RESERVE; sah untuk `party_1` dan `party_2`).
  - Metode pembantu domain: `is_in_party()`, `get_party_id()`, `set_party_id()`, dan `clear_party_assignment()`.
  - Sinkronisasi invarian lifecycle: pahlawan mati/gugur dilarang memiliki `party_id` non-kosong, pembersihan otomatis `clear_party_assignment()` saat `mark_dead()`, serta kloning mendalam `party_id` di `clone()`.
  - Perlindungan invarian chemistry: `add_chemistry()` menolak penambahan chemistry ke diri sendiri (`p_id == hero_id`) atau ID kosong.
- **Single Canonical Chemistry Gain Path** (`scripts/simulation/combat_engine.gd`):
  - Menghapus kenaikan chemistry spekulatif dari perulangan melee Phase 3.
  - Memusatkan kenaikan chemistry pada satu-satunya jalur resmi di Fase 5 pasca-kelangsungan hidup pertempuran: $+2$ poin per pasang hero hidup yang bertarung bersama di Party 1 (`surviving_heroes`), dibatasi maksimal 50 poin, dan bersifat simetris mutlak (`h1` dan `h2` saling memperoleh poin identik).
- **Snapshot Telemetry Serialization for Parties** (`scripts/domain/state/game_state_snapshot.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Penambahan properti `parties_data: Array` pada `GameStateSnapshot` dengan dukungan penuh pada `_init`, `clone()`, `to_dictionary()`, dan `from_dictionary()`.
  - Serialisasi `party_id` di setiap entri `heroes_data`.
- **Coordinator Party Orchestration & Lifecycle Security** (`scripts/application/coordinators/game_coordinator.gd`):
  - Koleksi regu benteng: `_parties = []` dengan inisialisasi tepat 2 regu (`party_1` sebagai regu tempur aktif utama, `party_2` sebagai regu cadangan/manajemen).
  - Kueri regu: `get_party()`, `get_parties()`, `get_party_members()`, `get_hero_party_id()`, `is_hero_in_party()`, `get_active_battle_party()`, `get_active_battle_hero_ids()`, `get_active_battle_heroes()`.
  - Mutasi keanggotaan dan kepemimpinan: `can_assign_hero_to_party()`, `assign_hero_to_party()`, `can_remove_hero_from_party()`, `remove_hero_from_party()`, `can_set_party_leader()`, `set_party_leader()`.
  - Proteksi Battle Lock: mutasi anggota regu dan penetapan ketua regu dilarang keras saat state `BATTLE`.
  - Perutean tempur aktif: hanya pahlawan Party 1 yang dikirim ke `CombatEngine.simulate_battle()`; Party 2 dan hero cadangan tidak berkontribusi serangan, tidak menerima kelelahan tempur, dan tidak memperoleh EXP tempur.
  - Pembersihan permadeath komprehensif pada `proceed_from_result()`: pahlawan gugur dilepas dari regu, status kepemimpinan regu dibersihkan, dan referensi chemistry pada pahlawan lain dihapus secara simetris tanpa merusak integritas gudang bersama.
- **Correction Gate — Canonical Party Assignment Mutation Authority** (`scripts/application/coordinators/game_coordinator.gd`):
  - Refaktor `GameCoordinator.assign_hero_to_party()` agar menggunakan canonical domain method `hero.set_party_id(party.party_id)` menggantikan direct field assignment (`hero.party_id = ...`).
  - Penegakan urutan transaksi aman dan atomik: (1) validasi via `can_assign_hero_to_party()`, (2) simpan `prev_party_id` dan `prev_lifecycle`, (3) transisi lifecycle ke `IN_PARTY`, (4) mutasi domain via `hero.set_party_id()`, (5) penambahan anggota ke `PartyModel`, (6) rollback atomik tanpa meninggalkan mutasi parsial jika salah satu tahap gagal.
  - Penambahan 2 regression tests pada suite Phase 4F: `test_assign_party_uses_canonical_hero_party_assignment` dan `test_assign_party_rolls_back_atomically_when_mutation_fails`.
- **Phase 4F Automated Test Suite** (`tests/test_phase4f_hero_chemistry_party.gd`):
  - 68 pengujian headless mencakup:
    - Group A: PartyModel Pure Domain & Invariant Tests (1-12)
    - Group B: HeroModel Party Attributes & Invariant Tests (13-24)
    - Group C: GameCoordinator Party Lifecycle & Battle Lock Tests (25-38)
    - Group D: Chemistry Progression & Rules Tests (39-50)
    - Group E: Combat Integration & Party 1 vs Party 2 Tests (51-60)
    - Group F: Permadeath Cleanup, Snapshot & 20-Wave Stress Tests (61-66)
    - Group G: Phase 4F Correction Gate Tests (67-68)

### Verified
- **Phase 4F Test Suite**: 68/68 PASSED (100%).
- **Full Automated Regression Suite**: 454/454 PASSED across 14 test suites (Phase 1 s/d Phase 4F) with 0 regressions.
- **Scene Smoke Playtest**: ALL PASS (0 errors) on Godot SceneTree.

---

## [0.5.6] - Phase 4E: Hero Skills & Talent Foundation (Implemented & Verified)

### Added
- **Canonical HeroSkill Domain Model** (`scripts/domain/model/hero_skill.gd`):
  - Model data murni `HeroSkill` (`RefCounted`) dengan properti `skill_id`, `skill_name`, `required_role`, `required_level`, `skill_type`, dan `power_multiplier`.
  - Konstanta tipe skill kanonikal: `TYPE_PASSIVE_STAT = "PASSIVE_STAT"` dan `TYPE_AURA = "AURA"`.
  - Metode validasi invarian `validate_invariants()`: id non-kosong, nama non-kosong, peran valid (`HeroRole`), level disyaratkan $\ge 1$, tipe terdaftar, dan multiplier $> 0.0$.
  - Katalog skill kanonikal deterministik 4 peran (KNIGHT, ARCHER, MAGE, PRIEST) menyediakan 3 skill spesifik per peran (total 12 skill).
- **Hero Skill Acquisition & Lifecycle Integration** (`scripts/domain/model/hero_model.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Properti `unlocked_skills: Array` di `HeroModel`.
  - Metode domain: `has_skill(skill_id)`, `can_unlock_skill(skill_id)`, `unlock_skill(skill_id)`, dan `get_unlocked_skills()`.
  - Validasi ketat pembukaan skill: kesesuaian peran kanonikal hero, pencapaian level minimum, pencegahan skill duplikat, dan penolakan hero gugur/permadeath.
  - Orkesstrasi di `GameCoordinator`: `can_unlock_hero_skill(hero_id, skill_id)` dan `unlock_hero_skill(hero_id, skill_id)` dengan proteksi Battle Lock.
- **Odd-Level Talent Point Rule** (`scripts/domain/model/hero_model.gd`):
  - Pahlawan memperoleh $+1$ Poin Bakat (*Talent Point*) setiap kali naik ke tingkat ganjil ($3, 5, 7, 9, \dots$) pada `add_exp()`.
  - Hero tingkat 1 awal memiliki 0 talent points (tidak ada pemberian retroaktif).
  - Kenaikan multi-tingkat seketika (misal: Lv 1 ke Lv 5) memberikan poin secara kumulatif untuk setiap tingkat ganjil yang dilalui (+2 poin: Lv 3 dan Lv 5).
  - Invarian bahwa kenaikan bintang (*Ascension*) maupun penumpukan EXP pada level cap tidak mengubah poin bakat.
- **Three-Branch Talent Tree & Deterministic Scaling** (`scripts/domain/model/hero_model.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Tiga cabang bakat kanonikal: `TALENT_BRANCH_OFFENSE = "OFFENSE"`, `TALENT_BRANCH_DEFENSE = "DEFENSE"`, `TALENT_BRANCH_LEADERSHIP = "LEADERSHIP"`.
  - Batas maksimal level bakat: `MAX_TALENT_BRANCH_LEVEL = 3` per cabang.
  - Metode alokasi bakat: `can_allocate_talent(branch_id)`, `allocate_talent(branch_id)`, `get_talent_level(branch_id)`, `get_offense_talent_level()`, `get_defense_talent_level()`, `get_leadership_talent_level()`.
  - Formula pengali bakat:
    - OFFENSE: $+2\%$ ATK per tingkat (Lv1: 1.02, Lv2: 1.04, Lv3: 1.06).
    - DEFENSE: $+2\%$ DEF per tingkat (Lv1: 1.02, Lv2: 1.04, Lv3: 1.06).
    - LEADERSHIP: $+1\%$ ATK dan $+1\%$ DEF per tingkat (Lv1: 1.01, Lv2: 1.02, Lv3: 1.03).
    - Formula gabungan: $\text{get\_talent\_atk\_multiplier}() = (1.0 + \text{off\_lvl} \times 0.02) \times (1.0 + \text{ldr\_lvl} \times 0.01)$ dan $\text{get\_talent\_def\_multiplier}() = (1.0 + \text{def\_lvl} \times 0.02) \times (1.0 + \text{ldr\_lvl} \times 0.01)$.
  - Integrasi stat efektif: `get_effective_atk()` dan `get_effective_def()` mengalikan pengali bakat; kompatibilitas mundur 100% (pengali = 1.0 jika alokasi 0).
  - Orkesstrasi di `GameCoordinator`: `can_allocate_hero_talent(hero_id, branch_id)` dan `allocate_hero_talent(hero_id, branch_id)` dengan proteksi Battle Lock.
- **Deep-Copy Clone & Invariant Validation** (`scripts/domain/model/hero_model.gd`):
  - `HeroModel.clone()` menduplikasi `unlocked_skills`, `talent_points`, dan `allocated_talents`.
  - `validate_invariants()` memvalidasi `talent_points >= 0` dan tingkat setiap cabang antara $0 \le \text{level} \le 3$.
- **Snapshot Telemetry Integration** (`scripts/application/coordinators/game_coordinator.gd`):
  - `GameStateSnapshot.heroes_data` memuat atribut: `unlocked_skills`, `talent_points`, `allocated_talents`, `talent_atk_multiplier`, dan `talent_def_multiplier`.
- **Phase 4E Automated Test Suite** (`tests/test_phase4e_hero_skills_talents.gd`):
  - 62 pengujian headless mencakup:
    - HeroSkill Model & Catalog Tests (1-12)
    - Skill Unlocking Domain & Coordinator Tests (13-26)
    - Talent Points Acquisition & Odd-Level Rule Tests (27-38)
    - Talent Allocation & Branch Integrity Tests (39-50)
    - Stat Scaling, Multipliers, Invariants & Persistence Tests (51-62)

### Verified
- **Full Regression Suite**:
  - Phase 1 Architecture: 5/5 PASSED
  - Phase 2 Mathematical Systems: 21/21 PASSED
  - Phase 3A Gameplay Baseline: 11/11 PASSED
  - Phase 3B Soldier Deployment: 27/27 PASSED
  - Phase 3C Hero Equipment Foundation: 22/22 PASSED
  - Phase 3D Prototype UX & Polish: 10/10 PASSED
  - Phase 3D Follow-up Corrections: 23/23 PASSED
  - Phase 3E Final Verification: 15/15 PASSED
  - Phase 4A Hero Domain & Lifecycle: 38/38 PASSED
  - Phase 4B Hero Progression & EXP: 47/47 PASSED
  - Phase 4C Hero Recruitment & Roster: 51/51 PASSED
  - Phase 4D Hero Training, Fatigue & Morale: 54/54 PASSED
  - Phase 4E Hero Skills & Talents: 62/62 PASSED
  - Total: **386 / 386 PASSED (100%)**
  - Scene Smoke Playtest: **ALL PASS (0 ERRORS)**
- **Phase Status Transition**:
  - Sub-Phase 4E: **COMPLETED / VERIFIED**.
  - Sub-Phase 4F: **NEXT / LOCKED**.

---

## [0.5.5] - Phase 4D: Hero Training, Fatigue & Morale (Implemented & Verified)

### Added
- **Canonical Hero Training Logic** (`scripts/domain/model/hero_model.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Sesi latihan kanonikal MVP memberikan reward deterministik `40 EXP` dan menambahkan `+15 fatigue`.
  - Integrasi penuh dengan sistem progresi Phase 4B (`add_exp()`) dengan mempertahankan kenaikan level multi-tingkat, carry-over EXP, dan pembatasan level cap bintang.
  - Validasi ketat batas kelelahan: jika kelelahan akhir melebihi 100 (misal: fatigue 86 atau 100), latihan gagal secara atomik tanpa memutasi EXP atau kelelahan.
- **Wave-Based Anti-Exploit Training Enforcement** (`scripts/application/coordinators/game_coordinator.gd`):
  - Penegakan aturan anti-exploit maksimal 1 sesi latihan per pahlawan per gelombang (`_hero_training_wave_tracker`).
  - Latihan kedua pada gelombang yang sama ditolak tanpa EXP dan tanpa kelelahan.
  - Pelacakan gelombang terhubung ke nomor gelombang otoritatif benteng (`_current_wave_num`), mereset kelayakan latihan otomatis saat naik ke gelombang berikutnya.
- **Atomic Fatigue & Morale Recovery (Rest Action)** (`scripts/domain/model/hero_model.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Metode `rest_hero(hero_id, recovery)` dan `HeroModel.rest(recovery)` memulihkan `-25 fatigue` (minimum 0) dan menambah `+5 morale` (maksimum 150) secara simultan dan atomik.
  - Aksi istirahat tidak merubah EXP, level, bintang, perlengkapan, chemistry, maupun kas emas benteng.
- **Morale Management & Effective Stat Multipliers** (`scripts/domain/model/hero_model.gd`):
  - Rentang nilai moral otoritatif `0–150` (baseline `100`).
  - Metode penyesuaian moral `adjust_morale(delta)` dengan batas bawah 0 dan batas atas 150.
  - Formula multiplier kelelahan kanonikal: $\text{FatigueMultiplier} = 1.0 - (\text{fatigue} / 200.0)$ ($0 \rightarrow 1.00, 20 \rightarrow 0.90, 50 \rightarrow 0.75, 100 \rightarrow 0.50$).
  - Formula multiplier moral kanonikal: $\text{MoraleMultiplier} = 0.75 + (\text{morale} / 200.0)$ ($0 \rightarrow 0.75, 50 \rightarrow 1.00, 100 \rightarrow 1.25, 150 \rightarrow 1.50$).
  - Urutan efektivitas stat akhir pahlawan pada `get_effective_atk()` dan `get_effective_def()` mengintegrasikan $\text{BaseStat} \times \text{LevelScale} \times \text{StarScale} \times \text{FatigueMultiplier} \times \text{MoraleMultiplier} \times \text{GearScale}$.
- **Battle Lock Protection**:
  - Aksi `train_hero()` dan `rest_hero()` diblokir keras selama fase `BATTLE`.
- **Snapshot Telemetry Preservation** (`scripts/application/coordinators/game_coordinator.gd`):
  - Serialisasi status `trained_this_wave`, `fatigue`, `morale`, `effective_atk`, dan `effective_def` ke dalam `GameStateSnapshot.heroes_data`.
- **Phase 4D Automated Test Suite** (`tests/test_phase4d_hero_training_fatigue_morale.gd`):
  - 54 pengujian otomatis mencakup:
    - Training Tests (1-20): keberhasilan latihan, 40 EXP, +15 fatigue, level up, carry-over, star level cap, penolakan latihan kedua di wave sama, zero EXP/fatigue pada penolakan, latihan aktif kembali di wave berikutnya, penolakan hero mati/permadeath/battle/invalid, batas fatigue 85 vs 86 vs 100, invariansi kas emas dan perlengkapan.
    - Fatigue Tests (21-33): awal di 0, akumulasi +15, transisi 85 -> 100, penolakan di 86 dan 100, rest -25, batas bawah 0, rest di 0 tetap 0, proteksi battle lock, rest tidak merubah EXP/level/star/gear.
    - Morale Tests (34-42): awal di 100, penyesuaian positif dan negatif, clamp 0 dan 150, rest +5 morale, atomisitas rest, independensi moral dari fatigue dan EXP.
    - Effective Stat Tests (43-54): multiplier fatigue (0=1.00, 50=0.75, 100=0.50), multiplier moral (0=0.75, 50=1.00, 100=1.25, 150=1.50), kombinasi stat, scaling level/star tetap utuh, determinisme ATK dan DEF.

### Verified
- **Full Regression Suite**:
  - Phase 1 Architecture: 5/5 PASSED
  - Phase 2 Mathematical Systems: 21/21 PASSED
  - Phase 3A Gameplay Baseline: 11/11 PASSED
  - Phase 3B Soldier Deployment: 27/27 PASSED
  - Phase 3C Hero Equipment Foundation: 22/22 PASSED
  - Phase 3D Prototype UX & Polish: 10/10 PASSED
  - Phase 3D Follow-up Corrections: 23/23 PASSED
  - Phase 3E Final Verification: 15/15 PASSED
  - Phase 4A Hero Domain & Lifecycle: 38/38 PASSED
  - Phase 4B Hero Progression & EXP: 47/47 PASSED
  - Phase 4C Hero Recruitment & Roster: 51/51 PASSED
  - Phase 4D Hero Training, Fatigue & Morale: 54/54 PASSED
  - Total: **324 / 324 PASSED (100%)**
  - Scene Smoke Playtest: **ALL PASS (0 ERRORS)**
- **Phase Status Transition**:
  - Sub-Phase 4D: **COMPLETED / VERIFIED**.
  - Sub-Phase 4E: **NEXT / LOCKED**.

---

## [0.5.4] - Phase 4C Final Correction Gate: Locked Recruitment Cost Authority & Closed Phase 4C

### Fixed
- **Single Canonical Recruitment Cost Authority** (`scripts/application/coordinators/game_coordinator.gd`):
  - Menghapus parameter override biaya pada `recruit_hero(candidate_or_role, cur_star, pot_star, p_id, p_name)` sehingga biaya rekrutmen diputuskan mutlak oleh `get_hero_recruitment_cost()` (`HERO_RECRUITMENT_COST_DEFAULT = 500`).
  - Pemanggil tidak dapat lagi meng-override biaya rekrutmen.

### Added
- **Strengthened Canonical Pricing Tests** (`tests/test_phase4c_hero_recruitment.gd`):
  - Pengujian deduksi tepat 500 Gold.
  - Pengujian saldo pas 500 Gold sukses dan menyisakan 0 Gold.
  - Pengujian saldo 499 Gold gagal dan kas 499 Gold tetap utuh tak berubah.
  - Pengujian saldo 501 Gold sukses dan menyisakan tepat 1 Gold.
  - Pengujian refleksi method memastikan tidak ada parameter override biaya pada `recruit_hero`.
  - Pengujian pelepasan pahlawan (`dismiss_hero`) mengembalikan perlengkapan ke gudang senjata bersama dan menjaga invarian konservasi perlengkapan.

### Verified
- **Automated Test Suites**:
  - Test Suite Phase 4C: **51/51 PASSED, 0 FAILED** (`tests/test_phase4c_hero_recruitment.gd`).
  - Full Regression Suite: **270 PASSED, 0 FAILED** (100% pass across 11 test suites) + Scene Smoke Playtest ALL PASS.
- **Phase Status Transition**:
  - Sub-Phase 4C: **COMPLETED / VERIFIED / CLOSED**.
  - Sub-Phase 4D: **NEXT / LOCKED**.

---

## [0.5.3] - Phase 4C: Hero Recruitment & Roster Management (Implemented & Verified)

### Added
- **Canonical Hero Recruitment Cost** (`scripts/application/coordinators/game_coordinator.gd`):
  - Ditetapkan biaya rekrutmen kanonikal MVP default: `500 Gold` (`const HERO_RECRUITMENT_COST_DEFAULT: int = 500`).
  - Single source of truth via metode `get_hero_recruitment_cost() -> int`.
- **Atomic Hero Recruitment Transaction** (`scripts/application/coordinators/game_coordinator.gd`):
  - Metode `recruit_hero(candidate_or_role, cur_star, pot_star, p_id, p_name, cost) -> HeroModel`.
  - Dilindungi Battle Lock (dilarang saat state `BATTLE`).
  - Validasi invarian hero, validasi duplikasi ID di roster, validasi lifecycle state (`RECRUITABLE` atau `ROSTER_ACTIVE`), dan validasi slot perlengkapan awal harus kosong.
  - Deduksi emas kas bendahara benteng dan transisi `RECRUITABLE` $\rightarrow$ `ROSTER_ACTIVE` secara atomik (dengan rollback otomatis jika mutasi gagal).
  - Penambahan pahlawan ke dalam roster benteng `_heroes` dan pembaruan snapshot reaktif.
- **Deterministic Unique Hero Identity Generator** (`scripts/application/coordinators/game_coordinator.gd`):
  - Metode `generate_unique_hero_id(prefix)` menghasilkan ID unik deterministik yang belum ada di roster.
  - Metode `generate_hero_candidate(role, cur_star, pot_star, p_id, p_name)` menghasilkan instance `HeroModel` berstatus `RECRUITABLE` untuk persiapan bursa sewa atau pengujian.
  - Menjamin tidak ada ID hero duplikat yang dapat memasuki roster benteng.
- **Roster Ownership & Management Methods** (`scripts/application/coordinators/game_coordinator.gd`):
  - Metode otoritatif roster: `get_roster_count() -> int`, `get_roster() -> Array`, `get_heroes() -> Array`, `has_hero(hero_id: String) -> bool`.
  - Metode penambahan langsung `add_hero(hero: HeroModel) -> bool` yang memvalidasi invarian dan menolak ID duplikat.
  - Metode pelepasan pahlawan `dismiss_hero(hero_id: String) -> bool` dan `remove_hero(hero_id: String) -> bool` yang dilindungi Battle Lock dan secara otomatis mengembalikan seluruh perlengkapan terpasang ke gudang bersama (menjaga invarian konservasi).
- **Hero Domain Invariant Expansion** (`scripts/domain/model/hero_model.gd`):
  - Memperluas `validate_invariants()` untuk memvalidasi batas level ($1 \le \text{level} \le \text{get\_level\_cap()}$), EXP non-negatif, batas kelelahan ($0 \le \text{fatigue} \le 100$), dan batas moral ($0 \le \text{morale} \le 150$).
- **Complete Snapshot Telemetry Preservation** (`scripts/application/coordinators/game_coordinator.gd`):
  - Memperluas serialisasi entri hero pada `GameStateSnapshot.heroes_data` mencakup `base_hp`, `base_atk`, `base_def`, dan `chemistry_map`.
- **Phase 4C Automated Test Suite** (`tests/test_phase4c_hero_recruitment.gd`):
  - 48 pengujian unit dan integrasi otomatis mencakup:
    - Recruitment (keberhasilan rekrutmen, transisi ke ROSTER_ACTIVE, deduksi 500 Gold, nominal emas pas, penolakan emas kurang, invariansi kas dan roster saat gagal, pertumbuhan ukuran roster).
    - Identity (generasi ID unik, penolakan ID duplikat, resistensi reordering roster, lookup stabil berdasarkan ID, penanganan aman ID tidak ditemukan).
    - Validation (penolakan peran tidak valid, penolakan bintang < 1 atau > 5, penolakan potensi < bintang atau > 5, penolakan level invalid, penolakan kandidat invalid, penerimaan progresi bintang-potensi legal).
    - Initial State (awal di level 1, 0 EXP, perlengkapan kosong, fatigue 0, morale 100, chemistry map kosong).
    - Roster Ownership (hanya hero valid di roster, penolakan duplikasi add_hero, lookup stabil banyak hero, dismiss_hero menjaga integritas sisa hero).
    - Snapshot (pelestarian identitas, progresi, status siklus hidup, status perlengkapan, dan peta chemistry).
    - Transaction Safety (kegagalan tidak memotong emas, deduksi emas tepat 1 kali, penambahan pahlawan tepat 1 kali, pencegahan request ganda).
    - Supplementary Constraints (proteksi Battle Lock, penolakan kandidat dengan gear ilegal, penolakan kandidat dengan state awal invalid seperti PERMADEATH/BATTLE_ACTIVE).

### Verified
- **Full Regression Suite**:
  - Phase 1 Architecture: 5/5 PASSED
  - Phase 2 Mathematical Systems: 21/21 PASSED
  - Phase 3A Gameplay Baseline: 11/11 PASSED
  - Phase 3B Soldier Deployment: 27/27 PASSED
  - Phase 3C Hero Equipment Foundation: 22/22 PASSED
  - Phase 3D Prototype UX & Polish: 10/10 PASSED
  - Phase 3D Follow-up Corrections: 23/23 PASSED
  - Phase 3E Final Verification: 15/15 PASSED
  - Phase 4A Hero Domain & Lifecycle: 38/38 PASSED
  - Phase 4B Hero Progression & EXP: 47/47 PASSED
  - Phase 4C Hero Recruitment & Roster: 48/48 PASSED
  - Prototype Scene Smoke Playtest: ALL PASS, 0 ERRORS
  - **Total: 267 unit/integration tests + 1 Scene Smoke Playtest suite PASSED 100%**.
- **Phase 4 Status**:
  - Sub-Phase 4A: COMPLETED / VERIFIED
  - Sub-Phase 4B: COMPLETED / VERIFIED
  - Sub-Phase 4C: IMPLEMENTED / VERIFIED
  - Sub-Phase 4D: NEXT / LOCKED (terkunci hingga tinjauan developer)

---

## [0.5.2] - Phase 4B: Hero Progression & EXP (Completed & Verified)

### Added
- **Canonical EXP Requirement Formula** (`scripts/domain/model/hero_model.gd`):
  - Formula kebutuhan EXP kanonikal: $\text{ReqEXP}(L) = \lfloor 120.0 \times L^{1.55} \rfloor$.
  - Nilai eksak kanonikal diverifikasi penuh: $Lv1 \rightarrow Lv2 = 120$, $Lv2 \rightarrow Lv3 = 351$, $Lv3 \rightarrow Lv4 = 658$, $Lv4 \rightarrow Lv5 = 1028$.
  - Akumulasi carry-over EXP dan dukungan kenaikan multi-level seketika saat menerima EXP dalam jumlah besar.
  - Penanganan nilai EXP non-positif (nilai negatif dan nol diabaikan tanpa efek samping).
- **Star-Based Level Cap System** (`scripts/domain/model/hero_model.gd`):
  - Metode `get_level_cap() -> int` menghitung batas level berdasarkan bintang aktif: $\text{current\_star} \times 10$ ($1\star=10, 2\star=20, 3\star=30, 4\star=40, 5\star=50$).
  - Hero di batas level cap tidak dapat naik level lagi dengan penambahan EXP; carry-over EXP dibatasi pada nilai kebutuhan level cap saat ini.
- **Hero Ascension Domain Validation & Mutation** (`scripts/domain/model/hero_model.gd`):
  - Metode `get_ascension_cost() -> int` menghitung biaya kenaikan bintang: $\text{current\_star} \times 150 \text{ Gold}$.
  - Metode `can_ascend() -> bool` memvalidasi kelayakan: hero hidup, tidak permadeath, $1 \le \text{current\_star} < \text{potential\_star} \le 5$, dan $\text{level} \ge \text{current\_star} \times 10$.
  - Metode `ascend() -> bool` memutasi kenaikan bintang tepat $+1$ (`current_star += 1`) tanpa merusak atau mengubah level, current EXP, perlengkapan terpasang, fatigue, morale, maupun potential star.
- **Atomic Ascension Transaction with Battle Lock** (`scripts/application/coordinators/game_coordinator.gd`):
  - Metode `ascend_hero(hero_id: String) -> bool` mengeksekusi transaksi kenaikan bintang secara aman dan atomik.
  - Dilindungi oleh Battle Lock: dilarang keras dieksekusi selama state `BATTLE`.
  - Memverifikasi kecukupan kas bendahara benteng (`_economy.treasury_gold >= cost`).
  - Pemotongan kas bendahara dan kenaikan bintang dijalankan secara atomik dengan rollback otomatis jika mutasi domain gagal.
  - Pembaruan snapshot dan pemancaran sinyal reaktif `state_changed`.
- **Deterministic Battle EXP Calculation & Distribution** (`scripts/simulation/combat_engine.gd`):
  - Metode statis `calculate_battle_exp(wave_num: int) -> int`: $\lfloor 60.0 \times (1.0 + \text{Wave} / 15.0) \rfloor$ (Wave 1 = 64, Wave 15 = 120, Wave 30 = 180).
  - Metode statis `distribute_battle_exp(total_exp: int, surviving_heroes: Array) -> Dictionary`: membagikan total EXP secara merata dan deterministik kepada hero yang bertahan hidup; sisa (*remainder*) dialokasikan deterministik berdasarkan urutan alfabetik `hero_id`. Total terdistribusi tidak pernah melebihi nilai total EXP yang diberikan.
  - Hero yang gugur tidak menerima perolehan EXP tempur.
- **Application Telemetry Snapshot Extension** (`scripts/application/coordinators/game_coordinator.gd`):
  - Serialisasi atribut progresi `potential_star`, `level_cap`, `can_ascend`, dan `ascension_cost` ke dalam setiap entri hero di `GameStateSnapshot.heroes_data`.
- **Phase 4B Automated Test Suite** (`tests/test_phase4b_hero_progression.gd`):
  - 47 pengujian unit dan integrasi otomatis mencakup:
    - EXP formula (ReqEXP Lv1, Lv2, Lv3, Lv4).
    - Level progression (level up Lv1->Lv2, carry-over, multi-level up, negative/zero EXP handling, level cap 1★/2★/5★, pencegahan kenaikan level melampaui cap).
    - Stat integration (+12% ATK per level, +10% DEF per level, +20% per bintang, pengali senjata & zirah tetap utuh).
    - Ascension rules & costs (kelayakan Lv10 pada 1★, pencegahan di bawah cap / di batas potential star / untuk hero gugur / di 5★, biaya 1★=150, 2★=300, 3★=450, 4★=600, mutasi bintang tepat +1, persistensi data lain).
    - Atomic Gold transaction (penolakan kas tidak mencukupi, kas & bintang tidak termutasi saat gagal, pemotongan kas presisi dan mutasi bintang saat sukses).
    - Battle EXP (kalkulasi Wave 1, 15, 30, pemberian EXP ke hero selamat, penolakan ke hero mati, determinisme distribusi remainder, jaminan total tidak melebihi alokasi).
    - Supplementary tests: penolakan `ascend_hero` saat Battle Lock dan verifikasi snapshot telemetri.

### Verified
- **Full Regression Suite**:
  - Phase 1 Architecture: 5/5 PASSED
  - Phase 2 Mathematical Systems: 21/21 PASSED
  - Phase 3A Gameplay Baseline: 11/11 PASSED
  - Phase 3B Soldier Deployment: 27/27 PASSED
  - Phase 3C Hero Equipment Foundation: 22/22 PASSED
  - Phase 3D Prototype UX & Polish: 10/10 PASSED
  - Phase 3D Follow-up Corrections: 23/23 PASSED
  - Phase 3E Final Verification: 15/15 PASSED
  - Phase 4A Hero Domain & Lifecycle: 38/38 PASSED
  - Phase 4B Hero Progression & EXP: 47/47 PASSED
  - Prototype Scene Smoke Playtest: ALL PASS, 0 ERRORS
  - **Total: 219 unit/integration tests + 1 Scene Smoke Playtest suite PASSED 100%**.
- **Phase 4 Status**:
  - Sub-Phase 4A: COMPLETED / VERIFIED
  - Sub-Phase 4B: IMPLEMENTED / VERIFIED
  - Sub-Phase 4C: PLANNED / LOCKED (terkunci hingga tinjauan developer)

---

## [0.5.1] - Phase 4A: Hero Domain & Lifecycle Foundation (Implemented & Corrected)

### Added
- **Canonical Hero Roles Domain Representation** (`scripts/domain/model/hero_role.gd`):
  - Model domain ringan (`RefCounted`) mendefinisikan 4 peran kanonikal: `KNIGHT`, `MAGE`, `ARCHER`, `PRIEST`.
  - Otoritas tunggal validasi peran melalui `HeroRole.is_valid_role()`.
  - Matriks kompatibilitas perlengkapan kanonikal:
    - `KNIGHT`: `SWORD` (Primary), `SHIELD` (Secondary), `HEAVY_ARMOR` (Armor).
    - `ARCHER`: `BOW` (Primary), `LIGHT_ARMOR` (Armor, future); `HEAVY_ARMOR` dilarang.
    - `MAGE`: Perlengkapan masa depan (`STAFF`, `WAND` Primary, `ROBE` Armor); seluruh perlengkapan Phase 3 tidak kompatibel.
    - `PRIEST`: Perlengkapan masa depan (`STAFF` Primary, `HOLY_EQUIPMENT` Secondary, `ROBE` Armor; seluruh perlengkapan Phase 3 tidak kompatibel).
- **Hero Lifecycle State Domain Representation** (`scripts/domain/model/hero_lifecycle_state.gd`):
  - Model domain ringan (`RefCounted`) mendefinisikan 6 state siklus hidup: `RECRUITABLE`, `ROSTER_ACTIVE`, `IN_PARTY`, `IN_TRAINING`, `BATTLE_ACTIVE`, `PERMADEATH`.
  - Aturan transisi legal (`can_transition()`) dan penegakan `PERMADEATH` sebagai state terminal mutlak (pahlawan gugur tidak dapat aktif kembali).
- **HeroModel Extension & Correction** (`scripts/domain/model/hero_model.gd`):
  - Menambahkan atribut kanonikal `role` (default: `KNIGHT`) dan `lifecycle_state` (default: `ROSTER_ACTIVE`).
  - Menghilangkan *silent normalization* / *silent clamping* pada constructor `_init()`: nilai bintang, peran, dan state invalid tidak diubah diam-diam menjadi valid melainkan dipertahankan mentah dan diverifikasi secara otoritatif via `validate_invariants()`.
  - Menambahkan metode validasi domain: `validate_identity()`, `validate_stars()`, `transition_lifecycle_state()`, `set_role()`, `is_role_valid()`, `is_lifecycle_state_valid()`, `is_equipment_compatible()`, dan `validate_invariants()`.
  - Mempertahankan 100% kompatibilitas backward terhadap seluruh API, slot perlengkapan, EXP, fatigue, chemistry, dan penanganan kematian Phase 1–3.
- **Application & Telemetry Integration** (`scripts/application/coordinators/game_coordinator.gd`):
  - Inisialisasi peran kanonikal starter: Alder (`KNIGHT`, `ROSTER_ACTIVE`) dan Lyra (`ARCHER`, `ROSTER_ACTIVE`).
  - Serialisasi metadata `role` dan `lifecycle_state` ke dalam snapshot `heroes_data` pada `_update_snapshot()`.
- **Phase 4A Automated Test Suite** (`tests/test_phase4a_hero_domain_lifecycle.gd`):
  - 38 pengujian otomatis komprehensif (100% PASS):
    - Role tests (6 test): KNIGHT, MAGE, ARCHER, PRIEST valid, penolakan peran tidak dikenal/kosong.
    - Lifecycle tests (6 test): validitas seluruh 6 state siklus hidup.
    - Transition tests (10 test): seluruh transisi legal dari perekrutan, penugasan regu, latihan, pertempuran, hingga kematian permanen dan penolakan transisi ilegal.
    - Invariant tests (7 test): penolakan ID/nama kosong, validasi bintang $\le$ potensi $\le 5$, terminalitas permadeath, persistensi equipment.
    - Canonical role equipment compatibility tests (4 test): pengujian kepatuhan izin/larangan perlengkapan Knight, Mage, Archer, dan Priest.
    - Constructor no-silent-normalization test (1 test): verifikasi bahwa input invalid tidak di-clamp otomatis.
    - Supplementary tests (4 test): kompatibilitas perlengkapan, safe defaults backward compatibility, case-insensitivity, deep clone.

### Verified
- **Full Regression Suite**:
  - Phase 1 Architecture: 5/5 PASSED
  - Phase 2 Mathematical Systems: 21/21 PASSED
  - Phase 3A Gameplay Baseline: 11/11 PASSED
  - Phase 3B Soldier Deployment: 27/27 PASSED
  - Phase 3C Hero Equipment Foundation: 22/22 PASSED
  - Phase 3D Prototype UX & Polish: 10/10 PASSED
  - Phase 3D Follow-up Corrections: 23/23 PASSED
  - Phase 3E Final Verification: 15/15 PASSED
  - Phase 4A Hero Domain & Lifecycle: 38/38 PASSED
  - Prototype Scene Smoke Playtest: ALL PASS, 0 ERRORS
  - **Total: 172 unit/integration tests + 1 Scene Smoke Playtest suite PASSED 100%**.
- **Phase 4 Status**:
  - Sub-Phase 4A: IMPLEMENTED / VERIFIED (Correction Gate passed).
  - Sub-Phase 4B: PLANNED (terkunci hingga tinjauan developer).

---

## [0.5.0] - Phase 4: Hero System (Planning & Architecture Specification)

### Added
- **Phase 4 Hero System Detailed Technical Plan & Roadmap Finalization** (`docs/design/PHASE_4_HERO_SYSTEM_PLAN.md`):
  - Audit dan finalisasi dokumen arsitektur dan perencanaan menyeluruh sebelum implementasi dimulai:
    - **Lock Existing Hero Foundation**: Mengunci fondasi Hero Phase 3 (`HeroModel`, `CombatEngine`, `GameCoordinator`, `GameStateSnapshot`). Dilarang membuat `HeroModelV2`, inventaris terpisah, atau gudang kedua.
    - **Single Source of Truth**: Menetapkan domain `HeroModel` sebagai otoritas tunggal untuk seluruh kalkulasi stat efektif, EXP, bintang, fatigue, moral, dan bonus chemistry. Application mengoordinasikan, `CombatEngine` mengonsumsi, dan UI hanya menampilkan.
    - **Equipment Scope**: Menegaskan item perlengkapan kanonikal Phase 3 (`SWORD`, `SPEAR`, `BOW`, `SHIELD`, `HEAVY_ARMOR`) tetap dipertahankan; tipe baru (`STAFF`, `MACE`, `LIGHT_ARMOR`, `CLOTH`) adalah ekstensi data non-breaking di masa depan.
    - **Party Management Scope**: Maksimal 2 party dalam manajemen (Party 1 dan Party 2), maksimal 3 hero per party, hero hanya boleh berada di maksimal 1 party, hero yang tidak ditugaskan berstatus `RESERVE`. Pembatasan sementara Phase 4: hanya Party 1 yang diteruskan ke simulasi pertempuran `CombatEngine`.
    - **Training Anti-Exploit Rule**: Mengklarifikasi bahwa batas maksimal 1 sesi pelatihan per hero per wave adalah aturan anti-eksploit game balance (bukan limitasi kapasitas bangunan barak/fasilitas).
    - **Strict 4A Scope & Out-of-Scope**: Menetapkan batasan ketat Sub-Phase 4A (lifecycle domain model, star cap/potential, in-memory roster foundation) dan secara eksplisit melarang ekspansi premature ke tavern UI, skill tree, atau save/load.
    - **Strict Sub-Phase Workflow**: Menerapkan 8 langkah wajib untuk setiap sub-fase (Inspect -> Plan -> Test Spec -> Approval Gate -> Implementation -> Verification -> Documentation -> Commit) dengan rantai dependensi sekuensial (4A -> 4B -> ... -> 4H).
    - **Preserved Baseline Verification**: Menjaga baseline 134 unit/integration tests dan Scene Smoke Playtest agar tetap 100% PASS tanpa regresi.
- **Project Phase Status Transition**:
  - Phase 3 (Gameplay Prototype) resmi berstatus COMPLETED / CLOSED.
  - Phase 4 (Hero System) resmi berstatus AUTHORIZED / PLANNING (implementasi belum dimulai).

---

## [0.4.7] - Phase 3E: Final Prototype Verification & Phase 3 Exit Gate (Completed)

### Added
- **Phase 3E Verification Test Suite** (`tests/test_phase3e_final_verification.gd`):
  - 15 pengujian otomatis komprehensif menguji seluruh invariant dan gerbang keluar Phase 3:
    1. `test_complete_state_machine_cycle`: Siklus penuh state machine dari BOOT s/d PREPARATION gelombang berikutnya.
    2. `test_legal_and_illegal_state_transitions`: Penolakan seluruh transisi ilegal di seluruh state.
    3. `test_soldier_deployment_conservation`: Reservasi atomik dan pengembalian instan serdadu dan perlengkapan.
    4. `test_soldier_casualty_equipment_resolution`: Verifikasi resolusi korban 35% musnah / 65% rusak berat.
    5. `test_surviving_soldier_gear_returns_at_100`: Verifikasi perlengkapan serdadu selamat kembali 100% durabilitas tanpa aus.
    6. `test_damaged_equipment_remains_non_usable`: Perlengkapan rusak ditolak dari builder penempatan.
    7. `test_destroyed_equipment_is_permanently_removed`: Perlengkapan hancur dihapus permanen dari kepemilikan.
    8. `test_blacksmith_repair_restores_durability`: Pemulihan durabilitas ke 100% dan status usable.
    9. `test_repair_gold_validation`: Validasi kas emas dan penolakan atomik saat kas tidak mencukupi.
    10. `test_hero_equipment_persistence`: Persistensi perlengkapan Hero yang selamat melintasi gelombang.
    11. `test_hero_death_equipment_return_exactly_once`: Pengembalian perlengkapan hero permadeath tepat 1 kali.
    12. `test_shared_warehouse_conservation_across_all_actions`: Invariant kepemilikan gudang bersama $\text{Total} = \text{USBL} + \text{DMGD} + \text{HERO} + \text{REGD}$ terbukti valid di setiap aksi.
    13. `test_duplicate_result_and_recovery_prevention`: Penolakan eksekusi ganda pada pertempuran dan recovery.
    14. `test_multi_deployment_soldier_accounting`: Akuntansi akurat penempatan serdadu di berbagai regu agregat.
    15. `test_deterministic_20_wave_stress_simulation`: Simulasi stres deterministik 20 wave berturut-turut dengan verifikasi invariant setiap gelombang.
- **Enhanced Prototype Scene Smoke Playtest** (`tests/test_playtest_smoke.gd`):
  - Memperluas skenario smoke test UI untuk mencakup penempatan serdadu, verifikasi tampilan Deployed Soldiers, pasang perlengkapan Hero, dan reparasi Pandai Besi di dalam SceneTree Godot.

### Verified
- **Full Regression Suite**:
  - Phase 1 Architecture Boundaries: 5/5 PASSED
  - Phase 2 Mathematical Systems: 21/21 PASSED
  - Phase 3A Gameplay Baseline: 11/11 PASSED
  - Phase 3B Soldier Deployment: 27/27 PASSED
  - Phase 3C Hero Equipment Foundation: 22/22 PASSED
  - Phase 3D Prototype UX & Polish: 10/10 PASSED
  - Phase 3D Follow-up Corrections: 23/23 PASSED
  - Phase 3E Final Verification: 15/15 PASSED
  - Prototype Scene Smoke Playtest: ALL PASS, 0 ERRORS
  - **Total: 134 unit/integration tests + 1 Smoke Playtest suite PASSED 100%**.
- **Phase 3 Exit Gate**:
  - Seluruh 16 kriteria gerbang keluar terpenuhi tanpa pengecualian.
  - Phase 3 (Gameplay Prototype) resmi ditutup (**CLOSED**).
  - Phase 4 tetap terkunci (**LOCKED**).

---

## [0.4.6] - Phase 3D: Follow-up Corrections (Deployed Soldier Status & Durability/Repair)

### Added
- **Dedicated Blacksmith Repair Panel & Controller Dispatcher** (`scripts/presentation/views/prototype_debug_view.gd`, `scripts/presentation/controllers/game_controller.gd`):
  - Area reparasi Pandai Besi minimal pada kolom kanan prototipe: menampilkan jumlah pekerja Pandai Besi aktif, persentase diskon reparasi (`worker * 12%`, maks 60%), dan daftar item rusak yang tersedia di gudang bersama.
  - Tombol reparasi dinamis (*Repair 1x*) dengan perhitungan biaya Gold transparan (`missing_durability * rate * (1 - discount)`).
  - Validasi kecukupan Gold seketika dengan feedback banner jika kas benteng tidak mencukupi, mencegah mutasi parsial atau *silent fail*.
- **Equipment Usability & Damage Predicates** (`scripts/domain/model/equipment_model.gd`):
  - Menambahkan method pembantu kanonikal: `is_usable() -> bool` (`durability >= max_durability`) dan `is_damaged() -> bool` (`durability < max_durability`).
- **Phase 3D Follow-up Automated Test Suite** (`tests/test_phase3d_followup_corrections.gd`):
  - 23 pengujian otomatis baru mencakup 4 domain utama:
    1. UI Prajurit Ditempatkan (4 test): status `-` saat kosong, kesesuaian total regu aktif, dukungan multi-regu, pemisahan dari kolam prajurit benteng.
    2. Durabilitas & Korban (8 test): serdadu selamat kembali 100% durabilitas, status usable serdadu selamat, gear korban rusak 65%, gear korban hancur 35%, item rusak non-usable, pengecualian item rusak dari builder penempatan, item hancur terhapus dari kepemilikan, item rusak tetap tercatat dalam total kepemilikan.
    3. Reparasi Pandai Besi (6 test): pemulihan durabilitas 100%, konsumsi Gold sesuai formula Phase 2, konservasi kepemilikan total saat reparasi, penolakan saat Gold kurang, item hasil reparasi siap ditempatkan, tidak ada duplikasi item.
    4. Konservasi Gudang Bersama (5 test): invariant berlaku pasca-kembalinya serdadu selamat, pasca-kembalinya gear rusak, pasca-kehancuran gear, pasca-reparasi, dan persistensi perlengkapan Hero.

### Changed
- **Soldier Status Area Display** (`scripts/presentation/views/prototype_debug_view.gd`):
  - Mengubah tampilan status prajurit di kolom kiri menjadi `=== DEPLOYED SOLDIERS ===`.
  - Menampilkan `Deployed Soldiers: -` saat tidak ada penempatan aktif pada fase PREPARATION / WAVE_PREVIEW / RECOVERY.
  - Menampilkan `Deployed Soldiers: <sum>` saat penempatan aktif dibuat, dihitung murni dari `SUM(all active deployment soldier_count)`.
  - Kolam prajurit benteng (`_available_soldiers`) tetap berjalan normal di domain dan tidak lagi ditampilkan sebagai status prajurit penempatan.
- **Soldier Equipment Durability Rule & Casualty Resolution** (`scripts/simulation/combat_engine.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Perlengkapan prajurit yang selamat dari pertempuran kembali ke gudang bersama pada durabilitas utuh 100% (`durability = 100.0`, `is_usable() == true`) tanpa dikenakan penalti keausan tempur rutin.
  - Resolusi korban pertempuran: perlengkapan yang dibawa prajurit gugur menjalani roll acak deterministik (35% hancur permanen / dihapus dari kepemilikan, 65% rusak berat diselamatkan dengan durabilitas 60).
  - Seluruh alur pembuatan penempatan, editing, rekonfigurasi, dan validasi stok kini hanya mengambil item usable (`durability == 100%`).
  - Single-pass resolution pada `proceed_from_result()` mencegah bug perhitungan ganda pada item multi-slot.
- **Shared Warehouse Conservation Invariant Formulation**:
  - Invariant konservasi diperluas secara eksplisit: $\text{Total Owned} = \text{Warehouse Usable} + \text{Warehouse Damaged} + \text{Hero Equipped} + \text{Soldier Reserved}$.
  - Tabel visual telemetri gudang di prototipe kini menampilkan kolom: `USBL` (Usable), `DMGD` (Damaged), `HERO` (Hero Equipped), `REGD` (Soldier Reserved), dan `TOTAL` (Total Kepemilikan).
- **Regression Verification**:
  - Full regression 100% PASS: 119 pengujian unit/sistem (Phase 1 5/5, Phase 2 21/21, Phase 3A 11/11, Phase 3B 27/27, Phase 3C 22/22, Phase 3D 10/10, Follow-up Corrections 23/23) + Scene Smoke Playtest ALL PASS.

---

## [0.4.5] - Phase 3D: Prototype UX & Interaction Polish (Completed)

### Added
- **State & Phase Guidance Contextual Banner** (`scripts/presentation/views/prototype_debug_view.gd`):
  - Sub-header guidance interaktif dan jelas untuk seluruh 7 fase gameplay (`BOOT`, `PREPARATION`, `WAVE_PREVIEW`, `BATTLE`, `RESULT`, `RECOVERY`, `GAME_OVER`).
- **Interactive Soldier Deployment Builder**:
  - Konfigurasi regu dinamis: pemilih jumlah prajurit (count 1-5), senjata primer (`SWORD`, `SPEAR`, `BOW`), senjata sekunder (`NONE`, `SHIELD`), dan zirah (`NONE`, `HEAVY_ARMOR`).
  - Preview derivasi peran seketika (`Role Preview: %dx %s`) melalui `DeploymentComposition.resolve_role()`.
  - Validasi stok sadar-gudang seketika dengan pesan penolakan yang jelas sebelum submit jika stok atau prajurit tidak mencukupi.
  - Tombol pintas cepat (*Quick Presets 2x*) untuk kenyamanan playtesting.
- **Active Deployment Groups Management**:
  - Tampilan mendalam setiap regu aktif (jumlah, peran turunan, gear yang dibawa, ID kanonikal).
  - Form rekonfigurasi (*inline reconfigure*) atomik: memungkinkan penyesuaian jumlah dan gear dengan jaminan rollback utuh jika stok/kuota tidak memenuhi.
  - Tombol batal (*Cancel / Remove*) untuk mengembalikan prajurit ke kolam cadangan dan senjata ke gudang bersama seketika.
- **Interactive Hero Equipment Controls & Battle Lock**:
  - Panel roster hero interaktif: slot Primary, Secondary, dan Armor menampilkan status terkini serta tombol pasang (*Equip*), lepas (*Unequip*), dan tukar (*Swap*) sadar stok.
  - Penegakan ketat Battle Lock: seluruh kontrol gear hero dan penempatan serdadu dinonaktifkan secara eksplisit selama fase `BATTLE`.
  - Penanganan visual hero permadeath: indikator pahlawan gugur permanen dengan konfirmasi pengembalian seluruh gear ke gudang.
- **Shared Warehouse Conservation Transparency**:
  - Tabel telemetri konservasi gudang bersama (`SWORD`, `SHIELD`, `SPEAR`, `BOW`, `HEAVY_ARMOR`) menampilkan kolom `WH` (stok gudang), `HERO` (terpasang di hero), `REGD` (direservasi regu serdadu), dan `TOTAL` (total kepemilikan fisik).
  - Membuktikan secara kasat mata invariant: $\text{Warehouse} + \text{Hero-held} + \text{Soldier-reserved} == \text{Total Owned}$.
- **Dead-end Prevention & Actionable Feedback**:
  - Banner umpan balik visual `_lbl_feedback_banner` menampilkan status jelas `[SUKSES]`, `[DITOLAK]`, atau `[INFO]` untuk setiap aksi pemain tanpa kegagalan diam (*silent fail*).
  - Peringatan dini pada `WAVE_PREVIEW` jika ada serdadu menganggur yang belum ditempatkan ke regu tempur.
- **Detailed Result & Recovery Breakdown**:
  - Laporan komprehensif pasca-tempur: damage benteng, korban serdadu permanen, rincian gear hancur/rusak, status hero, dan pengingat bahwa gear prajurit selamat telah kembali ke gudang benteng.
- **Phase 3D Automated Test Suite** (`tests/test_prototype_ux_interaction.gd`):
  - 10 pengujian otomatis tervalidasi 100% lulus (10/10 PASS, 0 FAIL) menguji seluruh alur interaksi, validasi stok, rollback atomik, Battle Lock, konservasi gudang, dan umpan balik dead-end.
  - Full regression: 96 unit/integration tests PASS + Scene Smoke Playtest ALL PASS.

---

## [0.4.4] - Phase 3C: Hero Equipment Foundation (Completed)

### Added
- **Hero Equipment Slots & Domain Integration** (`scripts/domain/model/hero_model.gd`):
  - Slot perlengkapan: `primary_equipment`, `secondary_equipment`, `armor_equipment`.
  - Metode manajemen: `equip()`, `unequip()`, `has_equipment()`, `get_equipment()`, `get_equipped_items()`, `clear_equipment()`.
  - Skalasi stat tempur: `get_effective_atk()` mengalikan bonus pengali weapon (`get_power_multiplier()`); `get_effective_def()` mengalikan bonus armor dan secondary shield.
  - Dukungan kloning mendalam slot perlengkapan pada `HeroModel.clone()`.
- **Shared Warehouse & Hero Equipment Coordination** (`scripts/application/coordinators/game_coordinator.gd`):
  - API koordinasi: `equip_hero()`, `unequip_hero()`, `swap_hero_equipment()`, `get_hero()`.
  - Integrasi stok gudang bersama: hero dan prajurit bersaing secara deterministik atas persediaan yang sama di `_warehouse`.
  - Penegakan Battle Lock: equip, unequip, dan swap dilarang keras saat state `BATTLE`.
  - Hero Permadeath Equipment Return: seluruh perlengkapan pahlawan yang gugur dikembalikan otomatis tepat 1 kali ke gudang bersama pada fase `proceed_from_result()`.
  - Hero Survival Persistence: pahlawan yang bertahan hidup mempertahankan perlengkapannya lintas gelombang.
- **Phase 3C Automated Test Suite** (`tests/test_hero_equipment_foundation.gd`):
  - 22 pengujian otomatis tervalidasi 100% lulus (22/22 PASS, 0 FAIL) mencakup seluruh skenario B16.
  - Zero regression pada seluruh suite: Phase 1 (5/5), Phase 2 (21/21), Phase 3A (11/11), Phase 3B (27/27), dan Playtest Scene Smoke (Total 86 unit/integration tests).

---

## [0.4.3] - Phase 3B: Temporary Soldier Deployment & Equipment Management (Completed)

### Added
- **Deployment Composition Domain Model** (`scripts/domain/model/deployment_composition.gd`):
  - Model agregat regu tempur sementara berbasis gelombang dengan identitas kanonikal `make_composition_id(p, s, a)` dan aturan presedensi derivasi peran deterministik (`resolve_role`).
- **Temporary Soldier Deployment & Equipment Reservation**:
  - `GameCoordinator.create_deployment()`, `remove_deployment()`, `reconfigure_deployment()`.
  - Reservasi atomik perlengkapan dari gudang bersama seketika (*immediate reservation*).
  - API seleksi sadar-stok: `get_warehouse_stock()`, `get_reserved_equipment_stock()`, `get_total_owned_stock()`, `is_equipment_option_available()`.
  - Penghapusan 100% pembentukan perlengkapan gratis otomatis (`_ensure_equipment_quantity_for_role` terhapus total).
- **Combat Adapter & Wear/Loss Accounting**:
  - `execute_battle` mengeksekusi pertempuran menggunakan snapshot terisolasi HANYA dari perlengkapan yang direservasi regu aktif; perlengkapan di gudang terlindungi 100% dari aus/kehilangan.
  - Multi-slot equipment casualty wear and loss processing (A11) untuk Primary, Secondary, dan Armor sesuai probabilitas deterministik Phase 2 (35% musnah, 65% rusak berat).
  - Pengembalian seluruh gear selamat ke gudang dan serdadu selamat ke kolam prajurit benteng pada `proceed_from_result()`.
- **Presentation Layer Updates**:
  - `GameController` dispatch methods untuk deployment.
  - `PrototypeDebugView` dashboard pemantauan serdadu (Total, Available, Deployed), status reservasi perlengkapan, tombol aksi deployment sadar stok, dan indikator Battle Lock.
- **Phase 3B Automated Test Suite** (`tests/test_soldier_deployment_temporary.gd`):
  - 27 pengujian otomatis tervalidasi 100% lulus (27/27 PASS, 0 FAIL) mencakup seluruh skenario A15.
  - Zero regression pada test suite Phase 1 (5/5), Phase 2 (21/21), Phase 3A (11/11), dan Playtest Scene Smoke.

---

## [0.4.2] - Phase 3B Plan Revision: Temporary Soldier Deployment & Equipment Management

### Changed (Design Plan Only)
- **Phase 3B Architectural Revision**:
  - Merevisi dokumen perencanaan Phase 3B ([docs/design/PHASE_3B_SOLDIER_DEPLOYMENT_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_3B_SOLDIER_DEPLOYMENT_PLAN.md)) menggantikan konsep kepemilikan perlengkapan permanen individual prajurit dengan konsep **Alokasi Perlengkapan Sementara Berbasis Gelombang (*Temporary Wave Deployment*)**.
  - Mengonfigurasi regu tempur agregat (*Deployment Compositions*): `Soldier Count`, `Primary Weapon` (Wajib), `Secondary Weapon` (Opsional), `Armor` (Opsional).
  - Menerapkan seleksi perlengkapan sadar stok (*stock-aware selection*) dengan menonaktifkan opsi jika stok gudang $< N$, serta reservasi seketika (*immediate reservation*).
  - Menetapkan aturan presedensi derivasi peran dinamis per gelombang (Sword $\rightarrow$ Swordsman, Sword+Shield $\rightarrow$ Shield Infantry, dll.).
  - Mendefinisikan siklus pengembalian gear pasca-wave ke gudang benteng dengan preservasi penuh aturan Phase 2 (aus normal & 65% gear korban rusak kembali; 35% gear korban hancur permanen).
  - Menegaskan pemisahan prajurit gugur (terpotong permanen dari populasi) dengan prajurit selamat (kembali ke kolam prajurit benteng).
  - Menghapus dokumen usang `PHASE_3B_SOLDIER_EQUIPMENT_PLAN.md`.

---

## [0.4.1] - Phase 3: Comprehensive Audit & Finalized Iterative Roadmap (3A–3E)

### Planned & Audited
- **Phase 3 Comprehensive Audit**:
  - Melakukan audit menyeluruh terhadap branch `main` pada commit `2452397` untuk memvalidasi isolasi arsitektur, integrasi simulasi Phase 2, dan kelengkapan konsep gameplay.
  - Menyusun tabel analisis kesenjangan (*15-Area Gap Analysis*) yang mencakup Preparation, Soldier, Equipment, Warehouse, Hero, Worker, Wave Preview, Battle, Commander Commands, Result, Recovery, Game Over, Persistence, Tests, dan Prototype UI.
- **Finalized Phase 3 Iterative Roadmap (3A–3E)**:
  - **Phase 3A — Current Prototype Baseline & Stabilization**: Dinyatakan **COMPLETED** (Seluruh 41 pengujian otomatis lulus 100%, prototype playable stabil di Godot Editor).
  - **Phase 3B — Soldier Equipment & Warehouse Conservation**: Direncanakan untuk mengimplementasikan derivasi peran prajurit dari senjata (Sword, Shield, Spear, Bow, Heavy Armor), pembebasan prajurit (*dismiss soldier*), dan penegakan invariant konservasi gudang ($\text{Total} = \text{Warehouse} + \text{Equipped}$).
  - **Phase 3C — Hero Equipment Foundation**: Direncanakan untuk mengimplementasikan slot perlengkapan minimal hero (Weapon, Armor), integrasi equip/unequip dengan gudang benteng, dan pengembalian gear otomatis saat permadeath.
  - **Phase 3D — Prototype UX & Interaction Polish**: Direncanakan untuk melengkapi kontrol UI pada fase persiapan dan mengeliminasi gameplay dead-ends.
  - **Phase 3E — Final Prototype Verification & Phase 3 Exit Gate**: Pengujian regresi otomatis akhir, playtest stres 20 wave, dan validasi penutupan resmi Phase 3.
- **Phase Boundary & Lock Enforcement**:
  - Mengunci secara tegas **Phase 4 (Hero System)** dengan status **LOCKED** hingga Phase 3 menyelesaikan seluruh iterasi 3A–3E.
  - Mendokumentasikan daftar *Explicit Non-Goals & Deferrals* ke Phase 4, Phase 5, Phase 6, Phase 7, Phase 8, Phase 9, dan Phase 10.

---

## [0.4.0] - Phase 3: Playable Gameplay Prototype (Implemented & Validated)

### Added
- **Gameplay State Machine** (`scripts/application/state_machine/gameplay_state_machine.gd`):
  - State deterministik: `BOOT`, `PREPARATION`, `WAVE_PREVIEW`, `BATTLE`, `RESULT`, `RECOVERY`, `GAME_OVER`.
  - Validasi transisi ketat, menolak transisi ilegal.
- **Commander Command DTO** (`scripts/domain/command/commander_command.gd`):
  - 6 intensi perintah komandan: `HOLD`, `ADVANCE`, `RETREAT`, `PROTECT`, `FOCUS`, `FOLLOW`.
- **GameCoordinator Application Orchestration** (`scripts/application/coordinators/game_coordinator.gd`):
  - Mengorkestrasi aliran data satu arah (*unidirectional data flow*), memvalidasi aksi player, memanggil engine simulasi Phase 2, dan memancarkan `state_changed(snapshot)`.
- **Domain Snapshot Extension** (`scripts/domain/state/game_state_snapshot.gd`):
  - Payload terstruktur untuk model benteng, populasi, hero, gudang equipment, bendahara, gelombang, dan telemetry tempur dengan backward compatibility penuh ke Phase 1.
- **Simulation Runner Extension** (`scripts/simulation/simulation_runner.gd`):
  - Orchestration methods untuk `WaveGenerator`, `CombatEngine`, dan `EconomyManager` tanpa menduplikasi formula matematika Phase 2.
- **Presentation Controller & View** (`scripts/presentation/controllers/game_controller.gd`, `scripts/presentation/views/prototype_debug_view.gd`):
  - Controller tempo pertempuran (Pause/Resume, Speed 1x, 2x, 4x) dan pemetaan input keyboard/UI.
  - Reactive text-based debug telemetry HUD yang pasif mengamati snapshot tanpa polling `_process()`.
- **Prototype Scene** (`scenes/prototype/main_prototype.tscn`, `scripts/presentation/scenes/main_prototype.gd`):
  - Playable scene minimal yang dapat dijalankan langsung di Godot Editor.
- **Automated Test Suites**:
  - `tests/test_gameplay_prototype.gd`: 11 unit & integration tests Phase 3 (100% PASS).
  - `tests/test_playtest_smoke.gd`: Automated smoke playtest scene integration (ALL PASS, 0 ERRORS).

### Verified
- **Phase 1 Architecture Regression**: **5/5 PASSED, 0 FAILED**.
- **Phase 2 Mathematical Regression**: **21/21 PASSED, 0 FAILED**.
- **Phase 3 Gameplay Prototype Tests**: **11/11 PASSED, 0 FAILED**.
- **Prototype Smoke Playtest**: **ALL PASSED, 0 ERRORS**.

---

## [0.3.0] - Phase 2: Mathematical / Systems Prototype (Completed & Validated)

### Fixed & Refactored (Four Corrective Items)
1. **Roadmap & Phase Synchronization**: Seluruh dokumen status (`CURRENT_PHASE.md`, `ROADMAP.md`, `CHANGELOG.md`, `README.md`) disinkronkan ke status resmi `Phase 2 — COMPLETED` dan `Phase 3 — NOT STARTED / LOCKED`.
2. **Worker & Economy Correction**: Menghapus seluruh referensi ke `Production Worker` dan `base_passive_income`. Pekerja sah hanya mencakup `Blacksmith`, `Repair`, `Construction`, dan `Idle`. Sumber pendapatan utama benteng berasal dari Battle Loot kemenangan pertempuran.
3. **Equipment Quantity & Ownership Model**: Memperbaiki kalkulasi efektivitas militer agar kuantitas perlengkapan riil di gudang membatasi jumlah prajurit yang mendapatkan bonus tier. Menguji secara ketat Kasus A, B, C, dan D serta mengecualikan perlengkapan yang rusak (*broken*).
4. **Equipment Loss & Deterministic Hero Survival/Death**:
   - Korban prajurit (*casualties*) secara deterministik menyebabkan peluang kehilangan perlengkapan ($35\%$) dan keausan berat ($65\%$).
   - Kelangsungan hidup hero dievaluasi berdasarkan keparahan breach, kelelahan (*fatigue*), dan pertahanan (*defense*). Keruntuhan benteng tidak otomatis membunuh seluruh hero sekaligus. Hero yang gugur dinyatakan `is_alive = false` dan keluar permanen dari active combat, EXP, chemistry, dan pemulihan stamina.

### Added
- Dokumen desain matematika final ([docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md](docs/design/MATHEMATICAL_SYSTEMS_PROTOTYPE.md)).
- Domain data models: `equipment_model.gd`, `fortress_model.gd`, `hero_model.gd`, `population_model.gd`.
- Simulation modules: `combat_engine.gd`, `economy_manager.gd`, `wave_generator.gd`, `headless_simulator.gd`.
- Automated test suite: `tests/test_mathematical_prototype.gd` (21 tes lulus: 12 unit boundaries, 8 skenario stres A–H, dan simulasi 100 gelombang).

### Verified
- **Phase 1 Architecture Regression**: **5 PASSED, 0 FAILED** (tanpa regresi arsitektur).
- **Phase 2 Mathematical Tests**: **21 PASSED, 0 FAILED**.
- **100-Wave System Stability**: 100 gelombang berhasil diselesaikan tanpa Game Over dengan neraca kas dan populasi yang seimbang di bawah kebijakan otomasi manajemen.

---

## [0.2.0] - Phase 1: Core Game Architecture (Completed & Approved)

### Added
- Implementasi skeleton arsitektur minimal Phase 1 yang membuktikan pemisahan lapisan:
  - `scripts/domain/state/game_state_snapshot.gd`: Domain state container murni berbasis `RefCounted` tanpa dependensi visual.
  - `scripts/domain/config/game_config_resource.gd`: Wadah konfigurasi statis berbasis Godot `Resource`.
  - `scripts/simulation/simulation_runner.gd`: Runner simulasi deterministik tanpa ketergantungan pada `_process()`.
  - `scripts/application/coordinators/game_coordinator.gd`: Coordinator aliran data satu arah (*unidirectional data flow*) dengan sinyal reaktif.
  - `scripts/infrastructure/persistence/save_snapshot_dto.gd`: DTO serialisasi save/load dengan validasi `schema_version`.
- Test suite arsitektur headless ([tests/test_architecture_boundaries.gd](tests/test_architecture_boundaries.gd)) yang memvalidasi ke-5 boundary secara otomatis (5 lulus, 0 gagal).
- Pembaruan dokumen arsitektur [docs/architecture/CORE_ARCHITECTURE.md](docs/architecture/CORE_ARCHITECTURE.md).

### Verified & Approved
- Boundary verification: 5/5 PASSED, 0 FAILED.
- Persetujuan resmi Developer: APPROVED (Commit `4b7436e`).

---

## [0.1.0] - Phase 0: Workspace & Development Environment Setup (Completed)
