# Current Development Phase

## Phase 4 — Hero System (IN PROGRESS / SUB-PHASE 4F COMPLETED & VERIFIED)

Project saat ini berada pada tahap **Phase 4 — Hero System (Sub-Phase 4A: COMPLETED / VERIFIED; Sub-Phase 4B: COMPLETED / VERIFIED; Sub-Phase 4C: COMPLETED / VERIFIED / CLOSED; Sub-Phase 4D: COMPLETED / VERIFIED; Sub-Phase 4E: COMPLETED / VERIFIED; Sub-Phase 4F: COMPLETED / VERIFIED; Sub-Phase 4G: NEXT / LOCKED)**.
Phase 3 (Gameplay Prototype) telah resmi ditutup (**COMPLETED / CLOSED**) pada commit `e6c0c97`.

Roadmap teknis dan spesifikasi arsitektur komprehensif Phase 4 tersedia di [docs/design/PHASE_4_HERO_SYSTEM_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_4_HERO_SYSTEM_PLAN.md).

---

### Riwayat Status Fase

- **Phase 0 — Workspace & Development Environment Setup**: **COMPLETED**
- **Phase 1 — Core Game Architecture**: **COMPLETED / APPROVED** (Commit `4b7436e`)
- **Phase 2 — Mathematical / Systems Prototype**: **COMPLETED** (Commit `dd74512`)
- **Phase 3 — Gameplay Prototype**: **COMPLETED** (Commits `2452397`, `4f01bfe`, `1d3d51d`, `463f91c`, `ba3c0c5`, `e6c0c97`)
- **Phase 4 — Hero System**: **IN PROGRESS**
  - Dokumen Roadmap & Spesifikasi Arsitektur: **ESTABLISHED** ([docs/design/PHASE_4_HERO_SYSTEM_PLAN.md](file:///d:/fortress_game/docs/design/PHASE_4_HERO_SYSTEM_PLAN.md))
  - **Sub-Phase 4A — Hero Domain & Lifecycle Foundation**: **COMPLETED / VERIFIED (CORRECTION GATE PASSED)**
    - Peran Kanonikal Domain: `KNIGHT`, `MAGE`, `ARCHER`, `PRIEST` via `HeroRole` (`scripts/domain/model/hero_role.gd`).
    - Matriks Kompatibilitas Perlengkapan Kanonikal: Knight (`SWORD`, `SHIELD`, `HEAVY_ARMOR`), Archer (`BOW`, `LIGHT_ARMOR`, no `HEAVY_ARMOR`), Mage & Priest (future gear only; seluruh Phase 3 gear non-kompatibel).
    - State Siklus Hidup Pahlawan: `RECRUITABLE`, `ROSTER_ACTIVE`, `IN_PARTY`, `IN_TRAINING`, `BATTLE_ACTIVE`, `PERMADEATH` via `HeroLifecycleState` (`scripts/domain/model/hero_lifecycle_state.gd`).
    - Validasi transisi legal dan penegakan `PERMADEATH` sebagai state terminal mutlak.
    - Eliminasi silent normalization pada `HeroModel._init()`: input bintang, peran, dan state invalid tidak di-clamp diam-diam melainkan tertangkap oleh `validate_invariants()`.
    - Test Suite Phase 4A: **38/38 PASSED, 0 FAILED** ([tests/test_phase4a_hero_domain_lifecycle.gd](file:///d:/fortress_game/tests/test_phase4a_hero_domain_lifecycle.gd)).
    - Full Regression: **172 tests PASSED (134 baseline Phase 1-3 + 38 Phase 4A)** + Scene Smoke Playtest ALL PASS.
  - **Sub-Phase 4B — Hero Progression & EXP**: **COMPLETED / VERIFIED**
    - Formula EXP Kanonikal: $\text{ReqEXP}(L) = \lfloor 120.0 \times L^{1.55} \rfloor$ dengan nilai eksak $Lv1=120, Lv2=351, Lv3=658, Lv4=1028$.
    - Progresi level hero dengan akumulasi carry-over EXP dan dukungan kenaikan multi-level seketika.
    - Level Cap berbasis bintang saat ini: $\text{current\_star} \times 10$ ($1\star=10, 2\star=20, 3\star=30, 4\star=40, 5\star=50$). Hero di level cap tidak bertambah levelnya saat menerima EXP lebih lanjut.
    - Kelayakan & Validasi Ascension: $1 \le \text{current\_star} < \text{potential\_star} \le 5$, hero hidup, tidak permadeath, dan $\text{level} \ge \text{current\_star} \times 10$.
    - Biaya Ascension: $\text{current\_star} \times 150 \text{ Gold}$ ($1\star\rightarrow2\star=150, 2\star\rightarrow3\star=300, 3\star\rightarrow4\star=450, 4\star\rightarrow5\star=600$).
    - Transaksi Atomik Kas Emas & Mutasi Bintang di `GameCoordinator.ascend_hero()`: dilindungi Battle Lock, kas benteng mencukupi, mutasi tepat $+1$ bintang, rollback jika gagal.
    - Formula Battle EXP Kanonikal di `CombatEngine`: $\lfloor 60.0 \times (1.0 + \text{Wave} / 15.0) \rfloor$.
    - Distribusi Battle EXP deterministik: pembagian rata kepada seluruh hero hidup yang bertarung, sisa (*remainder*) dialokasikan deterministik berdasarkan urutan alfabetik `hero_id`. Total terdistribusi tidak pernah melebihi nilai EXP yang diberikan.
    - Telemetri Snapshot: Atribut `potential_star`, `level_cap`, `can_ascend`, dan `ascension_cost` diserialisasikan ke `GameStateSnapshot.heroes_data`.
    - Test Suite Phase 4B: **47/47 PASSED, 0 FAILED** ([tests/test_phase4b_hero_progression.gd](file:///d:/fortress_game/tests/test_phase4b_hero_progression.gd)).
    - Full Regression: **219 tests PASSED (134 baseline Phase 1-3 + 38 Phase 4A + 47 Phase 4B)** + Scene Smoke Playtest ALL PASS.
  - **Sub-Phase 4C — Hero Recruitment & Roster Management**: **COMPLETED / VERIFIED / CLOSED**
    - Biaya Rekrutmen Kanonikal Mutlak: 500 Gold (`GameCoordinator.HERO_RECRUITMENT_COST_DEFAULT`). Tidak ada parameter override biaya pada `recruit_hero()`.
    - Alur Transaksi Atomik `GameCoordinator.recruit_hero()`: dilindungi Battle Lock, validasi invarian hero, validasi duplikasi ID, pemotongan kas 500 Gold, transisi `RECRUITABLE` $\rightarrow$ `ROSTER_ACTIVE`, penambahan ke `_heroes`, rollback jika gagal.
    - Identitas Pahlawan Deterministik & Unik: `generate_unique_hero_id()` dan `generate_hero_candidate()`, pencegahan duplikasi ID di seluruh roster.
    - Kepemilikan & Manajemen Roster: `get_roster_count()`, `get_roster()`, `get_heroes()`, `has_hero()`, `add_hero()`, `dismiss_hero()`, `remove_hero()`.
    - Keamanan Gudang Bersama: pahlawan rekrutan selalu berperlengkapan kosong (`PRIMARY/SECONDARY/ARMOR = null/NONE`), tidak ada duplikasi atau bypassing perlengkapan gudang benteng. Pelepasan pahlawan (`dismiss_hero`) mengembalikan seluruh perlengkapan terpasang ke gudang bersama secara aman, menjaga invarian konservasi.
    - Snapshot Telemetri Komprehensif: pelestarian `base_hp`, `base_atk`, `base_def`, `fatigue`, `morale`, `chemistry_map`, dan slot perlengkapan ke `heroes_data`.
    - Test Suite Phase 4C: **51/51 PASSED, 0 FAILED** ([tests/test_phase4c_hero_recruitment.gd](file:///d:/fortress_game/tests/test_phase4c_hero_recruitment.gd)).
    - Full Regression: **270 tests PASSED (134 baseline Phase 1-3 + 38 Phase 4A + 47 Phase 4B + 51 Phase 4C)** + Scene Smoke Playtest ALL PASS.
  - **Sub-Phase 4D — Hero Training, Fatigue & Morale**: **COMPLETED / VERIFIED**
    - Sesi Latihan Kanonikal MVP: `GameCoordinator.train_hero()` memberikan reward deterministik `40 EXP` dan menambahkan `+15 fatigue` (memanfaatkan `HeroModel.add_exp()` Phase 4B secara penuh).
    - Batasan Anti-Exploit Gelombang: Dibatasi maksimal 1 kali sesi latihan per pahlawan per gelombang (`has_hero_trained_this_wave`). Pelacakan direset secara otomatis saat nomor gelombang naik.
    - Batas Kelelahan (*Fatigue Boundary*): Rentang `0–100`. Latihan ditolak mutlak jika fatigue akhir melebihi 100 (misal: fatigue 85 menjadi 100 sukses; fatigue 86 atau 100 ditolak tanpa perubahan state dan tanpa clamping diam-diam).
    - Aksi Pemulihan Istirahat (*Rest*): `GameCoordinator.rest_hero()` memulihkan kelelahan `-25 fatigue` (minimum 0) dan menambah `+5 morale` (maksimum 150) secara atomik. Istirahat tidak merubah EXP, level, bintang, perlengkapan, chemistry, maupun kas emas.
    - Proteksi Battle Lock: Aksi latihan dan istirahat dilarang keras saat state `BATTLE`.
    - Formula Multiplier Kelelahan: $\text{FatigueMultiplier} = 1.0 - (\text{fatigue} / 200.0)$ ($0 \rightarrow 1.00, 20 \rightarrow 0.90, 50 \rightarrow 0.75, 100 \rightarrow 0.50$).
    - Formula Multiplier Moral: $\text{MoraleMultiplier} = 0.75 + (\text{morale} / 200.0)$ ($0 \rightarrow 0.75, 50 \rightarrow 1.00, 100 \rightarrow 1.25, 150 \rightarrow 1.50$).
    - Urutan Efektivitas Stat: $\text{BaseStat} \times \text{LevelScale} \times \text{StarScale} \times \text{FatigueMultiplier} \times \text{MoraleMultiplier} \times \text{GearScale}$.
    - Snapshot Telemetri: Serialisasi `trained_this_wave`, `fatigue`, `morale`, `effective_atk`, dan `effective_def` ke `GameStateSnapshot.heroes_data`.
    - Test Suite Phase 4D: **54/54 PASSED, 0 FAILED** ([tests/test_phase4d_hero_training_fatigue_morale.gd](file:///d:/fortress_game/tests/test_phase4d_hero_training_fatigue_morale.gd)).
    - Full Regression: **324 tests PASSED (134 baseline Phase 1-3 + 38 Phase 4A + 47 Phase 4B + 51 Phase 4C + 54 Phase 4D)** + Scene Smoke Playtest ALL PASS.
  - **Sub-Phase 4E — Hero Skills & Talent Foundation**: **COMPLETED / VERIFIED**
    - Model data murni `HeroSkill` (`scripts/domain/model/hero_skill.gd`) turunan `RefCounted` dengan validasi invarian identitas, nama, peran, syarat level, tipe skill, dan pengali kekuatan.
    - Katalog skill kanonikal 4 peran (`KNIGHT`, `ARCHER`, `MAGE`, `PRIEST`) bertipe `PASSIVE_STAT` dan `AURA`.
    - Validasi kelayakan pembukaan skill (`can_unlock_skill`, `unlock_skill`): peran cocok, level memenuhi, tidak duplikat, hero hidup dan non-permadeath.
    - Perolehan Poin Bakat (*Talent Points*) berbasis kenaikan tingkat ganjil (*Odd-Level Rule*): $+1$ poin saat mencapai level ganjil (3, 5, 7, 9, dst.) melalui `HeroModel.add_exp()`; tidak ada perolehan retroaktif saat hero dibuat di level 1; multi-level jump terakomodasi akurat.
    - Tiga cabang bakat kanonikal per peran: `OFFENSE`, `DEFENSE`, `LEADERSHIP` dengan batas maksimal tingkat 3 per cabang.
    - Multiplier bakat deterministik:
      - `OFFENSE`: $+2\%$ ATK per level (1.02, 1.04, 1.06).
      - `DEFENSE`: $+2\%$ DEF per level (1.02, 1.04, 1.06).
      - `LEADERSHIP`: $+1\%$ ATK dan $+1\%$ DEF per level (1.01, 1.02, 1.03).
      - Formula komposit: $\text{AtkMultiplier} = (1.0 + \text{off} \times 0.02) \times (1.0 + \text{ldr} \times 0.01)$, $\text{DefMultiplier} = (1.0 + \text{def} \times 0.02) \times (1.0 + \text{ldr} \times 0.01)$.
    - Integrasi stat efektif pahlawan: `get_effective_atk()` dan `get_effective_def()` mengintegrasikan pengali bakat dengan backward compatibility mutlak (multiplier 1.0 jika alokasi 0).
    - Proteksi Battle Lock di `GameCoordinator`: `unlock_hero_skill()` dan `allocate_hero_talent()` diblokir keras saat status `STATE_BATTLE`.
    - Deep-copy clone: `HeroModel.clone()` menduplikasi `unlocked_skills`, `talent_points`, dan `allocated_talents`.
    - Snapshot Telemetri: Serialisasi `unlocked_skills`, `talent_points`, `allocated_talents`, `talent_atk_multiplier`, dan `talent_def_multiplier` ke dalam `GameStateSnapshot.heroes_data`.
    - Test Suite Phase 4E: **62/62 PASSED, 0 FAILED** ([tests/test_phase4e_hero_skills_talents.gd](file:///d:/fortress_game/tests/test_phase4e_hero_skills_talents.gd)).
    - Full Regression: **386 tests PASSED (134 baseline Phase 1-3 + 38 Phase 4A + 47 Phase 4B + 51 Phase 4C + 54 Phase 4D + 62 Phase 4E)** + Scene Smoke Playtest ALL PASS.
  - **Sub-Phase 4F — Hero Chemistry & Party Management**: **COMPLETED / VERIFIED**
    - Model domain murni `PartyModel` (`scripts/domain/model/party_model.gd`, `class_name PartyModel extends RefCounted`) dengan id regu kanonikal `party_1` dan `party_2`, kapasitas maksimal 3 pahlawan per regu, manajemen anggota, penetapan ketua regu (*leader*), kloning mendalam, serta validasi invarian.
    - Perluasan `HeroModel`: atribut `party_id: String = ""` ("" = RESERVE, "party_1", "party_2"), metode pembantu (`is_in_party`, `get_party_id`, `set_party_id`, `clear_party_assignment`), sinkronisasi status invarian dengan `HeroLifecycleState`, pembersihan otomatis saat gugur (`mark_dead()`), serta proteksi terhadap self-chemistry (`p_id == hero_id`).
    - Jalur tunggal akumulasi chemistry di `CombatEngine`: dihapus dari perulangan melee Phase 3, dialihkan ke satu-satunya jalur resmi pada Fase 5 pasca-kelangsungan hidup pertempuran (+2 poin per pasang hero hidup yang bertarung bersama di Party 1, batas maksimal 50 poin, penambahan bersifat simetris mutlak).
    - Serialisasi Snapshot di `GameStateSnapshot`: penambahan serialisasi `parties_data: Array` pada `_init`, `clone()`, `to_dictionary()`, dan `from_dictionary()`.
    - Manajemen Regu di `GameCoordinator`: inisialisasi tepat 2 regu (`party_1` dan `party_2`), API kueri, alokasi/pelepasan hero, penetapan ketua regu, proteksi Battle Lock selama `STATE_BATTLE`, perutean tempur eksklusif Party 1 (kontribusi serangan, kelelahan tempur, dan EXP tempur hanya untuk Party 1), dan pembersihan komprehensif saat permadeath (pelepasan keanggotaan regu, penghapusan ketua regu, dan penghapusan referensi chemistry secara simetris).
    - Test Suite Phase 4F: **66/66 PASSED, 0 FAILED** ([tests/test_phase4f_hero_chemistry_party.gd](file:///d:/fortress_game/tests/test_phase4f_hero_chemistry_party.gd)).
    - Full Regression: **452 tests PASSED (134 baseline Phase 1-3 + 38 Phase 4A + 47 Phase 4B + 51 Phase 4C + 54 Phase 4D + 62 Phase 4E + 66 Phase 4F)** + Scene Smoke Playtest ALL PASS.
  - Sub-Phase 4G — Hero Management UX: **NEXT / LOCKED** (Terkunci hingga tinjauan developer)
  - Sub-Phase 4G — Hero Management UX: **PLANNED**
  - Sub-Phase 4H — Hero System Integration & Verification: **PLANNED**
- **Phase 5 — Fortress & Management Systems**: **LOCKED**
- **Phase 6 — Tactical Battle & Battlefield Systems**: **LOCKED**

---

### Aturan & Batasan Saat Ini

> [!IMPORTANT]
> **PHASE 3 TELAH RESMI DITUTUP (OFFICIALLY CLOSED).**
> **PHASE 4 TELAH DIBUKA (AUTHORIZED TO START)**: Pengembangan Phase 4 wajib mematuhi rencana kerja terstruktur (Sub-Phases 4A–4H), prinsip *Extend, Don't Break*, dan tidak boleh merusak baseline 134 pengujian Phase 1–3 yang telah lulus.
> **PHASE 5 & 6 TETAP LOCKED**: DILARANG memulai implementasi sistem pertarungan taktis mendalam, battlefield physics, maupun konstruksi modul benteng.

---

### Verifikasi Gerbang Keluar Phase 3 (Phase 3 Exit Gate Checklist)

- [x] Seluruh existing regression tests PASS (Phase 1: 5/5, Phase 2: 21/21, Phase 3A: 11/11, Phase 3B: 27/27, Phase 3C: 22/22, Phase 3D: 10/10, Follow-up: 23/23)
- [x] Seluruh Phase 3E verification tests PASS (15/15 PASS)
- [x] 20-wave stress verification PASS (100% stabilitas tanpa crash / memory leak)
- [x] Tidak ada critical crash
- [x] Tidak ada duplikasi equipment
- [x] Tidak ada kehilangan equipment yang tidak sah (non-casualty)
- [x] Tidak ada nilai resource atau prajurit negatif
- [x] Tidak ada bug kalkulasi jumlah serdadu
- [x] Tidak ada transisi state ilegal
- [x] Tidak ada eksekusi ganda pada result / recovery
- [x] Konservasi gudang bersama selalu valid di setiap aksi
- [x] Persistensi equipment Hero bekerja lintas gelombang
- [x] Aturan durabilitas serdadu & resolusi korban 35%/65% terverifikasi
- [x] Reparasi Pandai Besi bekerja presisi dan atomik
- [x] Scene Smoke Playtest PASS di Godot SceneTree
- [x] Dokumentasi status dan changelog diperbarui
- [x] Phase 4 tetap LOCKED

---

### Hasil Audit Komponen Teknis Phase 3 Final

| Komponen Sistem | Status | Evaluasi & Status Akhir |
| :--- | :---: | :--- |
| **Gameplay State Machine** | COMPLETED | Rantai siklus `BOOT -> PREP -> PREVIEW -> BATTLE -> RESULT -> RECOVERY -> PREP` dan terminal `GAME_OVER` 100% stabil. Menolak transisi ilegal. |
| **Worker Economy** | COMPLETED | 4 pekerjaan sah (Repair, Smith, Constr, Idle). Bebas passive income dan production worker. Pendapatan murni dari Battle Loot. |
| **Soldier Deployment** | COMPLETED | Alokasi sementara per gelombang, derivasi peran deterministik, pemisahan dari kolam prajurit benteng, reservasi atomik. |
| **Equipment & Warehouse** | COMPLETED | Segregasi usable vs damaged, formula durabilitas prajurit selamat (100%), resolusi korban (35% hancur, 65% rusak), konservasi fisik 100%. |
| **Blacksmith Repair** | COMPLETED | Reparasi item rusak menjadi 100% durabilitas menggunakan Gold dengan diskon alokasi pekerja Pandai Besi. Atomik dan bebas duplikasi. |
| **Hero Foundation** | COMPLETED | Stat, level, fatigue, chemistry, slot perlengkapan persistent lintas gelombang, dan pengembalian gear permadeath tepat 1 kali. |
| **Commander Commands** | COMPLETED | 6 intent command DTO diterima dan dicatat ke telemetri (`LOGGED_PHASE3_DEFERRED`). Efek taktis mendalam ke Phase 6. |
| **Wave Preview & Battle** | COMPLETED | Threat budget & enemy counts via `WaveGenerator`. Pertempuran multi-fase via `CombatEngine` dengan tempo 1x/2x/4x/Pause. |
| **Result & Recovery** | COMPLETED | Pasca-tempur atomik tanpa eksekusi ganda. Kembalinya prajurit selamat dan gear sementara ke gudang benteng. |
| **Automated Test Suites** | COMPLETED | 134 pengujian unit/sistem + 1 Scene Smoke Playtest suite lulus 100% tanpa kegagalan (100% PASS). |
