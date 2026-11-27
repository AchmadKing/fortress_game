# Current Development Phase

## Phase 6 — Tactical Battle & Battlefield Systems

### Status Sub-Fase
- **Phase 6A — Battlefield Zones & Enemy Foundation**: **COMPLETED / VERIFIED**
- **Phase 6B — Simulation Tick Loop & Pacing Controls**: **COMPLETED / VERIFIED**
- **Phase 6C — Unit Formations, Party 1 & Aura Mechanics**: **COMPLETED / VERIFIED**
- **Phase 6D — Commander Commands Execution**: **COMPLETED / VERIFIED**
- **Phase 6E — Fortress Damage Routing & Casualty Resolution**: **NEXT / LOCKED** (Menunggu persetujuan eksplisit developer)
- **Phase 6F — Tactical Battle UI & Verification Gate**: **LOCKED**
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
  - **Phase 6E — Fortress Damage Routing & Casualty Resolution**: **NEXT / LOCKED**
- **Phase 7 — Economy & Progression**: **LOCKED**
- **Phase 8 — Content Implementation**: **LOCKED**
- **Phase 9 — Visual / UI / Pixel Art Integration**: **LOCKED**
- **Phase 10 — Save/Load, Mobile Optimization & Polish**: **LOCKED**

---

### Aturan & Batasan Saat Ini

> [!IMPORTANT]
> **PHASE 6D TELAH SELESAI DAN TERVERIFIKASI (COMPLETED & VERIFIED).**
> **PHASE 6E MASIH TERKUNCI (LOCKED)**: DILARANG memulai implementasi perutean kerusakan benteng dan resolusi korban (Damage Routing & Casualty Resolution) sebelum developer memberikan izin/arahan eksplisit (*explicit developer approval*).
> **PHASE 7+ TETAP LOCKED**: Seluruh fase lanjut tetap terkunci.
