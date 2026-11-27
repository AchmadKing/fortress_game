# Current Development Phase

## Phase 6 — Tactical Battle & Battlefield Systems

### Status Sub-Fase
- **Phase 6A — Battlefield Zones & Enemy Foundation**: **COMPLETED / VERIFIED**
- **Phase 6B — Simulation Tick Loop & Pacing Controls**: **COMPLETED / VERIFIED**
- **Phase 6C — Unit Formations, Party 1 & Aura Mechanics**: **COMPLETED / VERIFIED**
- **Phase 6D — Commander Commands Execution**: **COMPLETED / VERIFIED**
- **Phase 6E — Fortress Damage Routing & Casualty Resolution**: **COMPLETED / VERIFIED**
- **Phase 6F — Tactical Battle UI & Verification Gate**: **NEXT / LOCKED** (Menunggu persetujuan eksplisit developer)
- **Phase 7+**: **LOCKED**

Dokumen perencanaan teknis dan arsitektur komprehensif Phase 6 tersedia di [plans/PHASE_6_TACTICAL_BATTLE_PLAN.md](file:///d:/fortress_game/plans/PHASE_6_TACTICAL_BATTLE_PLAN.md).

---

### Riwayat Status Fase

- **Phase 0 — Workspace & Development Environment Setup**: **COMPLETED**
- **Phase 1 — Core Game Architecture**: **COMPLETED / APPROVED** (Commit `4b7436e`)
- **Phase 2 — Mathematical / Systems Prototype**: **COMPLETED** (Commit `dd74512`)
- **Phase 3 — Gameplay Prototype**: **COMPLETED** (Commits `2452397`, `4f01bfe`, `1d3d51d`, `463f91c`, `ba3c0c5`, `e6c0c97`)
- **Phase 4 — Hero System**: **COMPLETED / CLOSED** (Sub-Phases 4A through 4H COMPLETED / VERIFIED)
- **Phase 5 — Fortress & Management Systems**: **COMPLETED / CLOSED** (Commit `e765c6e`)
- **Phase 6 — Tactical Battle & Battlefield Systems**: **IN PROGRESS**
  - **Phase 6A — Battlefield Zones & Enemy Foundation**: **COMPLETED / VERIFIED**
    - 7 Zona Medan Tempur Kanonikal: `OUTER_FIELD`, `LEFT_FLANK`, `CENTER_APPROACH`, `RIGHT_FLANK`, `WALL`, `GATE`, `FORTRESS` (`BattlefieldZone`).
    - Graf Ketetanggaan Deterministik Simetris (bidirectional, no self-reference).
    - 6 Arketipe Musuh Kanonikal: `GOBLIN_SWARM`, `ORC_FRONTLINE`, `GOBLIN_ARCHER`, `TROLL_TANK`, `SIEGE_MONSTER`, `FLYING_BYPASS` (`EnemyArchetype`).
    - Pemetaan Deterministik Komposisi Gelombang `WaveGenerator` $\to$ `EnemyGroup`.
    - Model Regu Agregat Musuh (`EnemyGroup`), kolam HP agregat, penyesuaian kuantitas proporsional, scaling bos, tanpa instansiasi node individual.
    - Test Suite Phase 6A: 30/30 PASS (`tests/test_phase6a_battlefield_enemy_foundation.gd`).
    - Full Regression Suite: 707/707 PASS (18 test suites).
    - Prototype Scene Smoke Playtest: ALL PASS.
  - **Phase 6B — Simulation Tick Loop & Pacing Controls**: **COMPLETED / VERIFIED**
    - Simulation Tick Counter kanonikal: `battle_tick` integer monotonik strictly increasing.
    - Kontrol Eksekusi: `step_simulation()` memajukan tick tepat satu kali per pemanggilan.
    - Kontrol Jeda & Lanjut: `pause_battle()` dan `resume_battle()` memblokir eksekusi langkah tanpa mereset tick, speed, maupun domain state.
    - Kontrol Kecepatan Kanonikal: `SPEED_1X` (1.0), `SPEED_2X` (2.0), `SPEED_4X` (4.0) dengan penolakan ketat kecepatan non-kanonikal.
    - Akumulator Waktu Deterministik: `advance_simulation_time(delta)` menjalankan langkah simulasi proporsional terhadap kecepatan tanpa ketergantungan frame rate.
    - Validasi State Ketat: Simulasi tick hanya diizinkan pada `STATE_BATTLE` (ditolak pada `PREPARATION`, `WAVE_PREVIEW`, `RESULT`, `RECOVERY`, `GAME_OVER`).
    - Proteksi Battle Lock: Mutasi hero, equipment, party, pekerja, dan konstruksi tetap terblokir selama battle aktif.
    - Integrasi Snapshot Read-Model: `battle_tick`, `battle_paused`, `battle_speed` terserialisasi ke `GameStateSnapshot`.
    - Unit Tests Phase 6B: 33/33 PASS (`tests/test_phase6b_simulation_tick_pacing.gd`).
    - Deterministic 10,000-Tick Stress Simulation: PASS tanpa kebocoran, crash, atau angka negatif.
    - Full Regression Suite: 740/740 PASS (19 test suites).
    - Prototype Scene Smoke Playtest: ALL PASS.
  - **Phase 6C — Unit Formations, Party 1 & Aura Mechanics**: **COMPLETED / VERIFIED**
    - Penempatan Medan Tempur Regu Serdadu Agregat: penempatan zona medan perang kanonikal (`GATE`, `WALL`, `CENTER_APPROACH`, `LEFT_FLANK`, `RIGHT_FLANK`, `FORTRESS`) dan formasi taktis (`FRONTLINE`, `BACKLINE`, `SUPPORT`) pada model `DeploymentComposition` tanpa instansiasi node individual.
    - Partisipasi Pertempuran Party 1 Eksklusif: hanya Party 1 yang berpartisipasi dalam pertempuran taktis. Pahlawan Party 2 dan Reserve terisolasi penuh dari bahaya medan perang, tidak bertransisi ke `BATTLE_ACTIVE`, dan tidak memicu aura. Pahlawan gugur di Party 1 otomatis tereksklusi.
    - Penempatan Taktis Party 1: posisi zona default `GATE` dan formasi default `FRONTLINE`. Penempatan ke `OUTER_FIELD` dan zona non-kanonikal ditolak secara ketat.
    - Fondasi Formasi & Resolver Peran: resolusi otomatis Knight $\to$ `FRONTLINE`, Archer/Mage $\to$ `BACKLINE`, Priest $\to$ `SUPPORT`.
    - Fondasi Mekanika Aura Party 1: perhitungan pasif murni tanpa mutasi basis stat (`base_hp`, `base_atk`, `base_def`). Bonus peran pasif (Knight +10% DEF/+5 morale, Archer +10% ATK, Mage +15% ATK, Priest +10% DEF/+5 morale), penskalaan bakat Leadership (+1% ATK/DEF per level), dan kontribusi Chemistry (+0.5% efektivitas per poin kemitraan).
    - Integrasi Kemitraan (Chemistry): kenaikan kemitraan mutual (+2 poin per pertempuran, batas 50) hanya diberikan kepada pahlawan Party 1 yang bertarung bersama dalam keadaan hidup.
    - Penegakan Battle Lock: seluruh perubahan zona penempatan serdadu, formasi serdadu, zona Party 1, dan formasi Party 1 ditolak keras selama `STATE_BATTLE`.
    - Integrasi Snapshot Read-Model: kolom `battle_deployments_data`, `battle_party_data`, dan `battle_aura_data` terserialisasi penuh dengan isolasi kloning deep-copy pada `GameStateSnapshot`.
    - Unit Tests Phase 6C: 37/37 PASS (`tests/test_phase6c_unit_formations_party_aura.gd`).
    - Deterministic 50-Wave Participation & Stress Test: PASS tanpa degradasi, kebocoran, atau inkonsistensi konservasi prajurit.
    - Full Regression Suite: 777/777 PASS (20 test suites).
    - Prototype Scene Smoke Playtest: ALL PASS.
  - **Phase 6D — Commander Commands Execution**: **COMPLETED / VERIFIED**
    - 7 Perintah Taktis Kanonikal: `ADVANCE`, `MOVE`, `HOLD_POSITION`, `RETREAT`, `PROTECT`, `FOCUS_TARGET`, `FOLLOW`, beserta alias kanonikal (`HOLD`, `FOCUS`) via `CommanderCommand`.
    - Aturan Mundur Kanonikal Deterministik (`get_retreat_target_zone`): `CENTER_APPROACH -> GATE`, `LEFT_FLANK -> WALL`, `RIGHT_FLANK -> WALL`, `GATE -> FORTRESS`, `WALL -> FORTRESS`, `FORTRESS -> FORTRESS`, `OUTER_FIELD -> GATE`.
    - Validasi Topologi Pergerakan: Perintah `MOVE` dan `ADVANCE` mematuhi graf ketetanggaan `BattlefieldZone.CANONICAL_ADJACENCY`, penolakan pergerakan melompat, penolakan pindah ke zona yang sama, dan larangan mutlak masuk zona musuh `OUTER_FIELD`.
    - Validasi State Ketat: Perintah komandan HANYA boleh dieksekusi saat fase `STATE_BATTLE`. Ditolak keras pada fase `BOOT`, `PREPARATION`, `WAVE_PREVIEW`, `RESULT`, `RECOVERY`, dan `GAME_OVER`.
    - Isolasi Penuh Party 2: Seluruh perintah komandan yang menargetkan atau bersumber dari Party 2 ditolak keras.
    - Pelestarian Battle Lock & Invarian Konservasi: Eksekusi perintah komandan tidak mengubah status penguncian peralatan, tidak memutasi populasi, tidak mengubah HP benteng, dan tidak menimbulkan korban serdadu atau jarahan.
    - Integrasi Snapshot Read-Model: Riwayat urutan perintah berstempel `battle_tick` monotonik (`command_history`) dan pemetaan intensi aktif kawan (`active_commander_intents`) terserialisasi penuh pada `GameStateSnapshot`.
    - Unit Tests Phase 6D: 50/50 PASS (`tests/test_phase6d_commander_commands.gd`), termasuk determinisme eksekusi dan simulasi stres 1.000 perintah/tick.
    - Full Regression Suite: 827/827 PASS across 21 test suites.
    - Prototype Scene Smoke Playtest: ALL PASS.
  - **Phase 6E — Fortress Damage Routing & Casualty Resolution**: **COMPLETED / VERIFIED**
    - Perhitungan Tekanan Musuh per Zona: komputasi deterministik berbasis kuantitas, statistik serangan arketipe musuh (`base_atk`), dan pelipat trait khusus (Siege/Structure +50%, Boss +25%).
    - Perutean Defensif Berbasis Zona: musuh maju secara bertahap `OUTER_FIELD` -> `APPROACH` / `FLANK` -> `GATE` / `WALL` -> `FORTRESS`. Perpindahan langsung (teleportasi) ke `FORTRESS` ditolak keras.
    - Perutean Kerusakan Struktural Benteng: musuh di zona `GATE` merusak `gate_hp`, musuh di zona `WALL` merusak `wall_hp`. Selama gerbang atau tembok belum roboh (unbreached), struktur menyerap kerusakan dan melindungi benteng (`current_hp`).
    - Kerusakan Tembus & Mitigasi Zirah: ketika gerbang roboh (`gate_hp <= 0`) atau tembok jebol (`wall_hp <= 0`), tekanan musuh merembes masuk ke `FORTRESS` dan langsung merusak `current_hp` benteng setelah dimitigasi oleh zirah benteng (`armor`).
    - Kerusakan Balasan Pertahanan (Fortification Counter-Damage): tembakan dan pertahanan benteng memberikan recoil balasan kepada kelompok musuh penyerang gerbang, tembok, dan benteng.
    - Resolusi Korban Serdadu Agregat: korban jiwa serdadu dipicu ketika akumulasi tekanan zona mencapai ambang batas (`CASUALTY_PRESSURE_THRESHOLD = 50`), dipengaruhi oleh formasi taktis (`FRONTLINE` menyerap kerusakan dengan +20% pertahanan, `BACKLINE` mendapatkan proteksi ambang batas 1.4x (70), `SUPPORT` memperkuat pertahanan zona) dan aura pahlawan. Total populasi terbukti berkurang secara atomik dan zero-sum.
    - Bahaya Pahlawan & Permadeath: pahlawan Party 1 yang bertarung di zona benturan mengakumulasi kelelahan (`fatigue`) dan dapat gugur (permadeath) jika terpapar tekanan ekstrem. Pahlawan Party 2 dan Reserve terisolasi penuh dengan 0 bahaya pertempuran.
    - Pengembalian Perlengkapan Pahlawan Permadeath Tepat 1x: seluruh perlengkapan pahlawan yang gugur dikembalikan secara utuh ke gudang bersama tepat satu kali tanpa duplikasi pada tick simulasi berikutnya.
    - Resolusi Perlengkapan Serdadu Gugur: serdadu selamat mempertahankan durabilitas perlengkapan 100%; perlengkapan serdadu gugur diresolusi via split deterministik 35% hancur permanen dan 65% rusak (durabilitas 60%) masuk ke stok Damaged gudang.
    - Fondasi Hasil Pertempuran: status kemenangan tercapai jika seluruh musuh tereliminasi dan benteng masih hidup; status kekalahan tercapai jika HP benteng $\le 0$ dan memicu transisi ke terminal `GAME_OVER`.
    - Integrasi Snapshot Read-Model: bidang telemetri `enemy_groups_data`, `battle_zone_pressure`, `accumulated_pressure`, `battle_casualties`, `wall_hp`, `gate_hp`, `fortress_hp`, `battle_heroes_killed`, `battle_is_finished`, dan `battle_victory` terserialisasi penuh pada `GameStateSnapshot`.
    - Unit Tests Phase 6E: 75/75 PASS (`tests/test_phase6e_fortress_damage_casualty.gd`).
    - Tactical Battle 1,000-Tick Stress Simulation: PASS tanpa kebocoran memori, tanpa angka negatif, dan tanpa desinkronisasi.
    - Full Regression Suite: 902/902 PASS across 22 test suites.
    - Prototype Scene Smoke Playtest: ALL PASS.
  - **Phase 6F — Tactical Battle UI & Verification Gate**: **NEXT / LOCKED**
- **Phase 7 — Economy & Progression**: **LOCKED**
- **Phase 8 — Content Implementation**: **LOCKED**
- **Phase 9 — Visual / UI / Pixel Art Integration**: **LOCKED**
- **Phase 10 — Save/Load, Mobile Optimization & Polish**: **LOCKED**

---

### Aturan & Batasan Saat Ini

> [!IMPORTANT]
> **PHASE 6E TELAH SELESAI DAN TERVERIFIKASI (COMPLETED & VERIFIED).**
> **PHASE 6F MASIH TERKUNCI (LOCKED)**: DILARANG memulai implementasi Tactical Battle UI sebelum developer memberikan izin/arahan eksplisit (*explicit developer approval*).
> **PHASE 7+ TETAP LOCKED**: Seluruh fase lanjut tetap terkunci.
