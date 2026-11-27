# Changelog — Fortress Game

Semua perubahan pada proyek dicatat dalam dokumen ini. Format mengacu pada prinsip Keep a Changelog.

---

## [0.6.6] - Phase 6F: Tactical Battle UI & Verification Gate

### Added
- **Tactical Battlefield Overview & 7 Canonical Zones UI** (`scripts/presentation/views/prototype_debug_view.gd`):
  - Tata letak lanskap medan tempur 7 zona kanonikal (`OUTER_FIELD`, `LEFT_FLANK`, `CENTER_APPROACH`, `RIGHT_FLANK`, `WALL`, `GATE`, `FORTRESS`).
  - Badge status zona dinamis: `[EMPTY]`, `[FRIENDLY]`, `[ENEMY OCCUPIED]`, `[CONTESTED]`, `[DAMAGED]`, `[BREACHED]`, `[DESTROYED]`.
  - Visualisasi rincian musuh per zona: arketipe, kuantitas, kolam HP agregat, trait khusus, dan indikator `[BOSS]`.
  - Visualisasi pasukan kawan per zona: regu serdadu penempatan aktif, peran turunan (`resolved_role`), jumlah, dan formasi taktis.
- **Pacing & Simulation Tick Controls** (`scripts/presentation/views/prototype_debug_view.gd`, `scripts/presentation/controllers/game_controller.gd`):
  - Tombol Pause / Resume toggle reaktif (`BtnPauseResume`).
  - Tombol Kecepatan 1x / 2x / 4x (`BtnSpeed1x`, `BtnSpeed2x`, `BtnSpeed4x`) dengan visual highlight status aktif (`[1x]`, `[2x]`, `[4x]`).
  - Tombol Step Tick manual (`BtnStepTick`) untuk kontrol per langkah simulasi deterministik.
  - Tombol Selesaikan Pertempuran Seketika (`BtnResolveImmediately`) untuk penyelesaian battle instan secara deterministik.
  - Tampilan telemetri header jam pertempuran (`_lbl_battle_clock`): nomor gelombang aktif dan pencacah `battle_tick` monotonik strictly increasing.
- **Party 1 Tactical Forces & Aura Display** (`scripts/presentation/views/prototype_debug_view.gd`):
  - Ringkasan pasukan Party 1: zona penempatan, formasi taktis, dan intensi komandan aktif.
  - Kartu status pahlawan hidup: HP saat ini, tingkat kelelahan (`fatigue`), moral, penanda peran & pemimpin regu `[LEADER]`, serta penanda `[GUGUR (Permadeath)]`.
  - Telemetri aura pasif kepemimpinan & chemistry aktif (`+X% ATK`, `+Y% DEF`, `+Z Morale`).
  - Isolasi ketat: Party 2 dan Reserve sepenuhnya dikecualikan dari ringkasan tempur medan laga.
- **Fortress Structural Condition & Casualties Telemetry** (`scripts/presentation/views/prototype_debug_view.gd`):
  - Pemantauan real-time HP Benteng, HP Tembok, HP Gerbang, dan Zirah Benteng.
  - Penghitung akumulatif prajurit gugur, pahlawan gugur, dan kerusakan struktural benteng.
- **Commander Tactical Commands Panel & Validation Feedback** (`scripts/presentation/views/prototype_debug_view.gd`):
  - 7 tombol perintah kanonikal: `ADVANCE`, `MOVE`, `HOLD_POSITION`, `RETREAT`, `PROTECT`, `FOCUS_TARGET`, `FOLLOW`.
  - Selektor dinamis sumber (`OptCmdSource`), target zona (`OptCmdTargetZone`), dan target entitas/musuh (`OptCmdTargetEntity`).
  - Banner umpan balik validasi perintah real-time (`LblCmdFeedback`) dengan status sukses dan alasan penolakan.
- **Battle Result & Game Over Overlays** (`scripts/presentation/views/prototype_debug_view.gd`):
  - Overlay hasil pertempuran (`BattleResultPanel`): headline `VICTORY!` vs `DEFEAT / BREACH!`, rekapitulasi kerusakan benteng, korban serdadu, status pahlawan, split perlengkapan gugur (hancur/rusak), serta tombol `Lanjut ke Fase Pemulihan (Recovery)`.
  - Overlay Game Over terminal (`GameOverPanel`): headline `☠ GAME OVER — FORTRESS COLLAPSED ☠`, pesan kehancuran benteng, dan tombol `Mulai Ulang Sesi (Restart)`.
- **Mobile Usability & In-Place Rendering Safety**:
  - Seluruh tombol kontrol tempo dan perintah memenuhi target sentuh minimum $\ge 44 \times 44$ px.
  - Pola pembaruan in-place preserving: data diperbarui pada tick simulasi tanpa merekonstruksi node tree (`BattlefieldPanel` identity preserved across ticks).
- **Automated Verification Suite** (`tests/test_phase6f_tactical_battle_ui.gd`):
  - 75 automated tests komprehensif mencakup Group A s/d W (UI Initialization & Lifecycle, Zone Rendering & Status Mapping, Enemy Group Visualization, Party 1 Tactical Force, Hero Visualization & Permadeath, Fortress Structural Condition, Wall & Gate Condition, Battle Clock & Tick Display, Pause/Resume UI, Speed Controls 1x/2x/4x, Commander Command Buttons, Command Validation & Rejection Feedback, Battle Lock Preservation, Casualty & Damage Telemetry, Hero Death Display, Victory Display, Defeat Display, Game Over Display, Snapshot Reactive Synchronization, Deep-Copy / Read-Model Safety, Determinism, UI Architecture Delegation Integrity, Minimum 44px Touch Targets, dan Full Wave Lifecycle Interactive Smoke Test).
  - Hasil: 75/75 PASS ($100\%$).
  - Full Regression Suite: 977/977 PASS across all 24 test suites.
  - Prototype Scene Smoke Playtest: ALL PASS.

---

## [0.6.5] - Phase 6E: Fortress Damage Routing & Casualty Resolution

### Added
- **Zone Enemy Pressure & Tactical Defensive Routing** (`scripts/simulation/combat_engine.gd`, `scripts/domain/model/enemy_group.gd`, `scripts/domain/model/enemy_archetype.gd`):
  - Perhitungan tekanan zona musuh deterministik `calculate_zone_enemy_pressure(enemy_groups, zone)` dengan pelipat trait arketipe: Siege/Structure (+50%), Boss (+25%).
  - Alur pergerakan defensif berurutan bertahap: `OUTER_FIELD` -> `CENTER_APPROACH` / `FLANKS` -> `GATE` / `WALL` -> `FORTRESS`. Pencegahan keras teleportasi langsung ke `FORTRESS`.
  - Properti `target_priority` pada `EnemyGroup` tersinkronisasi dari definisi kanonikal `EnemyArchetype`.
- **Fortress Structural Damage Routing & Fortification Recoil** (`scripts/simulation/combat_engine.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Perutean kerusakan bergradasi: musuh di zona `GATE` merusak `gate_hp`, musuh di zona `WALL` merusak `wall_hp`.
  - Proteksi struktur: selama gerbang dan tembok belum jebol, benteng utama terlindungi ($0$ kerusakan ke `current_hp`).
  - Penetrasi & mitigasi zirah: saat gerbang atau tembok jebol (`hp <= 0`), sisa tekanan mengalir ke benteng utama dengan pengurangan zirah benteng (`armor`).
  - Kerusakan balasan (counter-damage recoil): pertahanan gerbang, tembok, dan benteng memberikan tembakan balasan kepada musuh penyerang struktur.
- **Aggregate Soldier Casualties & Formation Thresholds** (`scripts/simulation/combat_engine.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Akumulasi tekanan zona memicu korban serdadu agregat pada ambang batas kanonikal `CASUALTY_PRESSURE_THRESHOLD = 50`.
  - Modifikasi formasi taktis: `FRONTLINE` (+20% def, menyerap tekanan), `BACKLINE` (ambang batas 1.4x / 70 untuk proteksi dari korban), `SUPPORT` (+10% def zona), dan aura pahlawan Party 1.
  - Pengurangan korban pada populasi serdadu secara atomik dan zero-sum (`PopulationModel.apply_casualties()`).
- **Hero Danger, Fatigue & Permadeath Equipment Return** (`scripts/simulation/combat_engine.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Pahlawan Party 1 aktif mengakumulasi kelelahan (`fatigue`) saat benturan terjadi di zonanya dan menghadapi risiko permadeath saat terpapar tekanan ekstrem.
  - Pahlawan Party 2 dan Reserve terisolasi mutlak dengan $0$ bahaya tempur dan $0$ mutasi fatigue/state.
  - Pengembalian perlengkapan pahlawan permadeath tepat 1 kali ke gudang bersama via `clear_equipment()` tanpa duplikasi pada tick selanjutnya.
- **Soldier Equipment Casualty Resolution** (`scripts/simulation/combat_engine.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Perlengkapan serdadu selamat kembali 100% utuh dengan durabilitas penuh ke stok Usable gudang bersama.
  - Perlengkapan serdadu gugur diresolusi via split deterministik: 35% musnah permanen dari kepemilikan (`Total Owned`), 65% rusak berat (durabilitas 60%) masuk ke stok Damaged gudang.
- **Battle Result & Defeat Conditions** (`scripts/simulation/combat_engine.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Status kemenangan (`victory`) terpicu jika seluruh musuh gugur dan benteng masih berdiri.
  - Status kekalahan (`defeat`) terpicu jika `fortress.current_hp <= 0`, memicu transisi sah via `GameplayStateMachine` menuju state terminal `GAME_OVER`.
- **Snapshot Read-Model Telemetry** (`scripts/domain/state/game_state_snapshot.gd`, `scripts/application/coordinators/game_coordinator.gd`, `scripts/presentation/controllers/game_controller.gd`):
  - Penambahan bidang telemetri Phase 6E: `enemy_groups_data`, `battle_zone_pressure`, `accumulated_pressure`, `battle_casualties`, `wall_hp`, `gate_hp`, `fortress_hp`, `battle_heroes_killed`, `battle_is_finished`, `battle_victory`.
  - Kloning deep-copy dan serialisasi dictionary round-trip pada `GameStateSnapshot`.
- **Automated Verification Suite** (`tests/test_phase6e_fortress_damage_casualty.gd`):
  - 75 automated tests komprehensif mencakup Group A s/d W (Pressure Calculation, Topological Advance, Cadence, Formations, Soldier Casualties, Population Conservation, Wall/Gate Damage, Fortress Routing, Hero Danger & Party Isolation, Permadeath & Gear Return, Soldier Gear Split, Battle Result & Victory/Defeat, Commander Commands, Clock Progression, Snapshot Telemetry, Determinism, Boundary Safety, dan Tactical Battle 1.000-Tick Stress Simulation).
  - Full Regression Suite: 902/902 PASS across 22 test suites.
  - Prototype Scene Smoke Playtest: ALL PASS.

---

## [0.6.4] - Phase 6D: Commander Commands Execution

### Added
- **Commander Command DTO & Canonical Types** (`scripts/domain/command/commander_command.gd`):
  - 7 perintah taktis kanonikal: `ADVANCE`, `MOVE`, `HOLD_POSITION`, `RETREAT`, `PROTECT`, `FOCUS_TARGET`, `FOLLOW`, beserta alias kanonikal `HOLD` dan `FOCUS`.
  - Normalisasi deterministik `CommanderCommand.normalize_type()` dan validasi `is_valid_type()`.
  - Bidang DTO komprehensif: `command_type`, `source_id`, `target_zone`, `target_enemy_id`, `target_enemy_type`, `target_entity_id`, `target_id`, `issued_at_battle_tick`, `issued_at_tick`, `sequence_id`, `status`.
  - Serialisasi round-trip `to_dictionary()` dan `from_dictionary()` serta duplikasi mendalam `clone()`.
- **Domain Tactical Intent State** (`scripts/domain/model/party_model.gd`, `scripts/domain/model/deployment_composition.gd`):
  - Bidang intensi taktis pada model `PartyModel` dan `DeploymentComposition`: `tactical_intent`, `protected_target`, `focus_target`, `following_target`.
  - Metode domain `set_tactical_intent()` dan `reset_tactical_intent()`.
  - Dukungan serialisasi dan kloning penuh.
- **Commander Command Pipeline & Orchestration** (`scripts/application/coordinators/game_coordinator.gd`, `scripts/presentation/controllers/game_controller.gd`):
  - Metode `send_commander_command(command)` pada `GameCoordinator` dengan validasi ketat:
    - Perintah hanya diizinkan saat `GameplayStateMachine.STATE_BATTLE`.
    - Resolusi entitas asal: `party_1` atau ID regu `DeploymentComposition` yang valid.
    - Isolasi total Party 2: perintah yang melibatkan `party_2` ditolak keras.
    - Validasi topologi perpindahan: `MOVE` dan `ADVANCE` harus menuju zona bertetangga kanonikal (`BattlefieldZone.CANONICAL_ADJACENCY`), dilarang melompat zona, dilarang masuk ke `OUTER_FIELD`, dan dilarang berpindah ke zona yang sama.
    - Aturan mundur terarah kanonikal (`get_retreat_target_zone`): `CENTER_APPROACH -> GATE`, `LEFT_FLANK -> WALL`, `RIGHT_FLANK -> WALL`, `GATE -> FORTRESS`, `WALL -> FORTRESS`, `FORTRESS -> FORTRESS`, `OUTER_FIELD -> GATE`.
    - Perintah `HOLD_POSITION`: menetapkan intensi bertahan pada zona saat ini tanpa mengubah zona.
    - Perintah `PROTECT`: menetapkan target perlindungan kawan (zona atau entitas) tanpa memutasi zona.
    - Perintah `FOCUS_TARGET`: menetapkan fokus prioritas arketipe atau kelompok musuh.
    - Perintah `FOLLOW`: menetapkan target kawalan entitas kawan yang sah, menolak menargetkan diri sendiri.
  - Logging urutan eksekusi berstempel `battle_tick` dan penomoran ID sekuensial monotonik.
  - Helper methods pada `GameController`: `command_advance()`, `command_move()`, `command_hold()`, `command_retreat()`, `command_protect()`, `command_focus_target()`, `command_follow()`.
- **Snapshot Integration & UI Telemetry** (`scripts/domain/state/game_state_snapshot.gd`, `scripts/presentation/views/prototype_debug_view.gd`):
  - Penambahan `command_history` (riwayat perintah berstempel waktu) dan `active_commander_intents` (pemetaan intensi aktif per entitas kawan) ke dalam `GameStateSnapshot`.
  - Tombol aksi `MOVE` ditambahkan pada panel perintah `PrototypeDebugView`.
- **Automated Verification Suite** (`tests/test_phase6d_commander_commands.gd`):
  - 50 automated tests komprehensif mencakup Group A (Command Creation & DTO), Group B (Validation & Rejection), Group C (State Machine & Battle Phase Enforcement), Group D (Move & Advance Execution), Group E (Retreat Rule & Topology), Group F (Hold Position), Group G (Protect Intent), Group H (Focus Target Intent), Group I (Follow Intent), Group J (Domain Integrity & Battle Lock), Group K (Simulation Tick Ordering & Pacing), Group L (Snapshot & Telemetry), Group M (Determinism & Monotonicity), dan Group N (1.000-Command / Tick Stress Simulation).
  - 1.000-command/tick stress simulation: PASS tanpa desinkronisasi atau inkonsistensi.
  - Full Regression Suite: 827/827 PASS across 21 test suites.
  - Prototype Scene Smoke Playtest: ALL PASS.

---

## [0.6.3] - Phase 6C: Unit Formations, Party 1 & Aura Mechanics

### Added
- **Soldier Deployment Battlefield Participation & Formations** (`scripts/domain/model/deployment_composition.gd`, `scripts/application/coordinators/game_coordinator.gd`, `scripts/presentation/controllers/game_controller.gd`):
  - Model agregat prajurit berpartisipasi langsung pada pertempuran taktis tanpa instansiasi node per prajurit (*No Individual Soldier Entity*).
  - Penempatan zona medan tempur kanonikal (`current_zone`): default `GATE` untuk Infanteri/Perisai dan `WALL` untuk Pemanah.
  - Formasi taktis kanonikal (`formation`): `FRONTLINE`, `BACKLINE`, `SUPPORT` (`VALID_FORMATIONS`).
  - Metode pengaturan `set_deployment_zone(composition_id, zone)` dan `set_deployment_formation(composition_id, formation)` pada `GameCoordinator` dan `GameController`.
  - Penolakan ketat penempatan ke `OUTER_FIELD` dan string zona tidak sah.
- **Party 1 Exclusive Battle Participation** (`scripts/domain/model/party_model.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Hanya Party 1 yang diizinkan bertempur secara aktif di medan laga (`get_active_battle_party()`).
  - Party 2 dan Pahlawan Cadangan (Reserve) terisolasi penuh: tidak berpindah ke `BATTLE_ACTIVE`, tidak menerima aura musuh, dan tidak terpapar bahaya.
  - Pahlawan gugur di Party 1 otomatis tereksklusi dari komputasi tempur aktif.
  - Penempatan zona dan formasi Party 1 (`set_party_zone()`, `set_party_formation()`), default zona `GATE` dan formasi `FRONTLINE`.
- **Party 1 Aura Foundation & Mechanics** (`scripts/simulation/combat_engine.gd`, `scripts/domain/model/hero_role.gd`, `scripts/domain/model/hero_model.gd`):
  - Perhitungan pasif deterministik murni `calculate_party_auras(battle_heroes, target_zone)` tanpa mutasi stat dasar pahlawan (`base_hp`, `base_atk`, `base_def`).
  - Bonus aura peran: Knight (+10% DEF, +5 Morale), Archer (+10% ATK), Mage (+15% ATK), Priest (+10% DEF, +5 Morale).
  - Penskalaan bakat Leadership (Phase 4E): +1% ATK dan +1% DEF per tingkat bakat pemimpin regu.
  - Integrasi Chemistry Party 1 (Phase 4F): kontribusi kemitraan +0.5% per poin chemistry antar pasangan pahlawan hidup.
  - Getter kanonikal `get_chemistry_with(partner_hero_id)` pada `HeroModel`.
  - Penambahan kemitraan pasca-tempur `apply_battle_chemistry_gain()` (+2 poin mutual, dibatasi maksimal 50) eksklusif untuk partisipan Party 1 hidup.
- **Strict Battle Lock & Domain Protection**:
  - Seluruh mutasi taktis (zona deployment, formasi deployment, zona Party 1, formasi Party 1) diblokir keras selama `STATE_BATTLE`.
  - Proteksi penuh terhadap mutasi keanggotaan regu (`assign_hero_to_party`, `remove_hero_from_party`) dan perlengkapan (`equip_hero`, `unequip_hero`).
- **Snapshot Integration & UI Telemetry** (`scripts/domain/state/game_state_snapshot.gd`, `scripts/application/coordinators/game_coordinator.gd`):
  - Bidang snapshot baru: `battle_deployments_data`, `battle_party_data`, dan `battle_aura_data` terserialisasi penuh dengan isolasi memori kloning mendalam (*deep-copy*).
- **Automated Verification Suite** (`tests/test_phase6c_unit_formations_party_aura.gd`):
  - 37 automated tests komprehensif mencakup Group A (Soldier Formations), Group B (Party 1 Participation), Group C (Battlefield Placement), Group D (Formations), Group E (Aura Mechanics), Group F (Chemistry Integration), Group G (Determinism & Snapshot), Group H (Battle Lock & Conservation), dan Group I (Deterministic 50-Wave Participation & Stress Test).
  - 50-wave participation stress test: PASS dengan pelestarian invarian konservasi serdadu dan determinisme aura.
  - Full Regression Suite: 777/777 PASS (20 test suites).
  - Prototype Scene Smoke Playtest: ALL PASS.

---

## [0.6.2] - Phase 6B: Simulation Tick Loop & Pacing Controls

### Added
- **Deterministic Simulation Tick Counter** (`scripts/application/coordinators/game_coordinator.gd`, `scripts/simulation/combat_engine.gd`):
  - Pelacak waktu diskrit monotonik kanonikal: `battle_tick` (integer, dimulai dari 0 saat pertempuran dimulai, tidak pernah negatif).
  - Eksekusi deterministik `step_simulation()`: memajukan `battle_tick` tepat 1 unit per pemanggilan tunggal.
  - Metode `CombatEngine.step_simulation_tick(current_tick)` untuk fondasi komputasi tick headless.
- **Pacing & Speed Controls (1x / 2x / 4x)** (`scripts/simulation/combat_engine.gd`, `scripts/application/coordinators/game_coordinator.gd`, `scripts/presentation/controllers/game_controller.gd`):
  - Konstanta kanonikal: `SPEED_1X` (1.0), `SPEED_2X` (2.0), `SPEED_4X` (4.0).
  - Validasi ketat `CombatEngine.is_valid_speed(speed)`: menolak nilai non-kanonikal (seperti 0.5x, 3.0x, 5.0x, negatif) tanpa mengubah speed saat ini.
  - Akumulator waktu deterministik `advance_simulation_time(delta_seconds)`: mengonversi akumulasi delta detik menjadi langkah simulasi diskrit proporsional kecepatan tanpa ketergantungan frame rate FPS.
- **Pause & Resume Controls** (`scripts/application/coordinators/game_coordinator.gd`, `scripts/presentation/controllers/game_controller.gd`):
  - Metode kanonikal `pause_battle()` dan `resume_battle()` beserta backward-compatibility wrapper `set_battle_paused()`.
  - Saat dijeda (*paused*): eksekusi langkah simulasi diblokir (`can_step_simulation() == false`), `battle_tick` tidak berubah, dan tidak ada state domain yang termutasi.
  - Status jeda tidak mereset nilai tick, speed, maupun posisi/kondisi musuh di medan tempur.
- **State Machine Validation & Battle Lock Integrity**:
  - Validasi ketat: simulasi tick hanya diizinkan pada `GameplayStateMachine.STATE_BATTLE`. Ditolak keras pada fase `BOOT`, `PREPARATION`, `WAVE_PREVIEW`, `RESULT`, `RECOVERY`, dan `GAME_OVER`.
  - Pelestarian Battle Lock penuh: mutasi hero, peralatan, party, pekerja, perbaikan, dan konstruksi tetap terblokir selama fase pertempuran.
- **Snapshot Integration & UI Telemetry** (`scripts/domain/state/game_state_snapshot.gd`, `scripts/presentation/views/prototype_debug_view.gd`):
  - Kolom snapshot read-model: `battle_tick`, `battle_paused`, `battle_speed` terserialisasi penuh pada isolasi kloning deep-copy.
  - Penampil status HUD antarmuka prototipe menampilkan tick waktu nyata: `Speed: %.1fx (%s) | Tick: %d`.
- **Automated Verification Suite** (`tests/test_phase6b_simulation_tick_pacing.gd`):
  - 32 automated tests komprehensif mencakup Group A (Tick), Group B (Pause/Resume), Group C (Speed 1x/2x/4x), Group D (State Machine), Group E (Determinism), Group F (Battle Lock & Integrity), dan Group G (Deterministic 10,000-Tick Stress Simulation).
  - Stress test 10.000 tick: PASS tanpa kebocoran memori, tanpa crash, dan tanpa angka negatif.
  - Full Regression Suite: 739/739 PASS (19 test suites).
  - Prototype Scene Smoke Playtest: ALL PASS.

---

## [0.6.1] - Phase 6A: Battlefield Zones & Enemy Foundation

### Added
- **Battlefield Zones Domain Model** (`scripts/domain/model/battlefield_zone.gd`):
  - Model domain murni `BattlefieldZone` (`RefCounted`) untuk representasi zona medan tempur taktis.
  - 7 Zona Kanonikal: `ZONE_OUTER_FIELD` (Open Approach), `ZONE_LEFT_FLANK` (Tactical Flank), `ZONE_CENTER_APPROACH` (Frontline Highway), `ZONE_RIGHT_FLANK` (Tactical Flank), `ZONE_WALL` (Elevated Rampart), `ZONE_GATE` (Chokepoint Barrier), `ZONE_FORTRESS` (Inner Core).
  - Graf Ketetanggaan Kanonikal Deterministik Dua Arah (Symmetric & Bidirectional) tanpa perulangan mandiri (*no self-reference*).
  - Atribut & Pengali Taktis: bonus pertahanan tembok (+25% DEF) dan jangkauan (+30% RNG), bonus chokepoint gerbang (+40% DEF).
  - Flag interior benteng (`is_fortress_interior`, eksklusif hanya untuk `ZONE_FORTRESS`) dan perizinan penempatan pasukan (`allow_player_deployment`, non-aktif untuk `ZONE_OUTER_FIELD`).
  - Validasi invarian zona ketat, isolasi kloning mendalam (*deep-copy*), dan serialisasi dictionary (`to_dictionary()` / `from_dictionary()`).
- **Enemy Archetypes Domain Model** (`scripts/domain/model/enemy_archetype.gd`):
  - Model domain murni `EnemyArchetype` (`RefCounted`) untuk mendefinisikan 6 arketipe musuh kanonikal:
    1. `GOBLIN_SWARM`: Threat 2, HP 20, ATK 4, DEF 2, Speed 1 tick/zona, Target "NEAREST", Trait "SWARM".
    2. `ORC_FRONTLINE`: Threat 6, HP 65, ATK 12, DEF 8, Speed 2 ticks/zona, Target "DEFENDER", Trait "FRONTLINE".
    3. `GOBLIN_ARCHER`: Threat 8, HP 35, ATK 14, DEF 4, Speed 2 ticks/zona, Target "RANGED", Trait "RANGED".
    4. `TROLL_TANK`: Threat 16, HP 220, ATK 25, DEF 18, Speed 3 ticks/zona, Target "GATE", Trait "HIGH_DURABILITY".
    5. `SIEGE_MONSTER`: Threat 40, HP 450, ATK 60, DEF 25, Speed 4 ticks/zona, Target "STRUCTURE", Trait "STRUCTURE_DAMAGE".
    6. `FLYING_BYPASS`: Threat 12, HP 50, ATK 16, DEF 5, Speed 1 tick/zona, Target "FORTRESS", Trait "BYPASS_BARRIER".
  - Pemetaan Deterministik Gelombang Musuh: metode kanonikal `map_legacy_enemy_type()` dan `map_wave_to_enemy_groups()` menerjemahkan keluaran `WaveGenerator` (`MINION`, `RAIDER`, `BRUTE`, `FLYER`, `SIEGE`, `BOSS`) ke instance `EnemyGroup` yang berposisi awal di `OUTER_FIELD`.
- **Enemy Group Aggregate Model** (`scripts/domain/model/enemy_group.gd`):
  - Model agregat musuh `EnemyGroup` (`RefCounted`) mematuhi prinsip *No Individual Entity* (musuh tidak pernah diinstansiasi sebagai node terpisah).
  - Manajemen kolam HP agregat (`max_hp_pool = base_hp_per_unit * quantity`), penyusutan bertahap kuantitas hidup secara proporsional via `apply_damage()`, dan deteksi kekalahan `is_defeated()`.
  - Dukungan scaling khusus unit Bos (`is_boss = true`): peningkatan HP dasar ($2.5\times$), ATK ($1.5\times$), DEF ($1.25\times$), dan label trait `BOSS_ELITE`.
  - Validasi invarian konsistensi data (larangan kuantitas negatif, larangan HP > 0 saat kuantitas 0, validitas zona saat ini & target).
- **Automated Verification Suite** (`tests/test_phase6a_battlefield_enemy_foundation.gd`):
  - 30 unit tests komprehensif mencakup 5 grup:
    - Group A: Battlefield Zones & Invariants (Tests 1–6)
    - Group B: Zone Adjacency & Topology (Tests 7–12)
    - Group C: Enemy Archetypes & Attributes (Tests 13–18)
    - Group D: WaveGenerator Mapping & Determinism (Tests 19–24)
    - Group E: EnemyGroup Model & Invariants (Tests 25–30)
  - Hasil Uji: 30/30 PASS (100%).
  - Full Regression Suite: 707/707 PASS di 18 test suites tanpa regresi.
  - Prototype Scene Smoke Playtest: ALL PASS.

---

## [0.6.0] - Phase 5: Fortress & Management Systems (Completed & Closed)

### Added
- **Low-Fi Wireframe Archival & Indexing** (`docs/design/wireframes/fortress-main-screen/`):
  - Pengarsipan bundle low-fi wireframe antarmuka benteng (`Main.dc.html`, `support.js`, dependensi React).
  - Dokumentasi README panduan struktur wireframe dan `docs/design/WIREFRAME_INDEX.md`.
- **Fortress Defense Foundation** (`scripts/domain/model/fortress_model.gd`):
  - Perluasan integritas benteng dengan sub-komponen Tembok Pertahanan (`wall_max_hp = 500`, `wall_hp = 500`) dan Gerbang Utama (`gate_max_hp = 300`, `gate_hp = 300`).
  - Metode domain: `damage_wall()`, `repair_wall()`, `damage_gate()`, `repair_gate()`, `is_wall_breached()`, `is_gate_breached()`.
  - Validasi invarian struktural: penolakan damage/reparasi negatif, batas HP $0 \le \text{hp} \le \text{max}$, dan isolasi kloning.
- **Population Accounting & Zero-Sum Conservation** (`scripts/domain/model/population_model.gd`):
  - Pengelolaan populasi tenaga kerja (`workers`) di samping warga sipil (`civilians`) dan tentara (`soldiers`).
  - Metode konversi dua arah: `civilian_to_worker()` dan `worker_to_civilian()`.
  - Penegakan ketat invarian konservasi populasi: $\text{Total Population} = \text{Civilians} + \text{Workers} + \text{Soldiers}$.
  - Penolakan over-allocation, konversi melebihi stok, dan kuantitas negatif.
  - Penanganan korban perang: serdadu gugur mengurangi total populasi secara permanen tanpa mengganggu warga sipil dan tenaga kerja.
- **Worker Management & Productivity Foundation** (`scripts/domain/model/worker_model.gd`):
  - Model domain baru `WorkerModel` turunan `RefCounted` untuk mengelola tenaga kerja agregat benteng.
  - Alokasi 4 tugas kanonikal: `IDLE`, `BLACKSMITH`, `REPAIR`, `CONSTRUCTION`.
  - Invarian ketat konservasi pekerja: $\text{Total Workers} = \text{Blacksmith} + \text{Repair} + \text{Construction} + \text{Idle}$.
  - Realokasi dinamis antar-pekerjaan: `reassign(from_job, to_job, count)` dengan validasi ketersediaan dan penolakan job ilegal.
  - Sinkronisasi tenaga kerja aman: `sync_total_workers()` mengalirkan pekerja baru ke `IDLE` dan menyusutkan alokasi secara proporsional jika jumlah pekerja berkurang.
  - Pengelolaan moral tenaga kerja ($0–100$) dan derivasi produktivitas deterministik: $\text{Productivity} = 0.50 + (\text{morale} / 100.0) \times 0.75$ (rentang $0.50$ s/d $1.25$).
  - Serialisasi dictionary dan isolasi kloning mendalam (*deep-copy*).
- **Building & Facility Foundation** (`scripts/domain/model/building_model.gd`):
  - Model domain baru `BuildingModel` turunan `RefCounted` untuk merepresentasikan modul dan fasilitas benteng.
  - 9 Fasilitas Kanonikal: `FORTRESS`, `WALL`, `GATE`, `BARRACKS`, `BLACKSMITH`, `WAREHOUSE`, `TRAINING_FACILITY`, `MERCENARY_GUILD`, `CONSTRUCTION_AREA`.
  - Tingkat fasilitas ($1–5$), batas maksimal level, validasi tipe sah, metode `upgrade()`, serialisasi dictionary, dan isolasi kloning.
- **Structure Repair System Foundation** (`scripts/application/coordinators/game_coordinator.gd`):
  - Orkestrasi perbaikan struktur fisik (`FORTRESS`, `WALL`, `GATE`) via `can_repair_structure()` dan `repair_structure()`.
  - Prasyarat sah: alokasi pekerja perbaikan > 0 (`repair_workers > 0`), emas kas mencukupi, tidak melebihi HP maksimal, dan proteksi Battle Lock.
  - Biaya perbaikan kanonikal: $0.15 \text{ Gold per HP}$ yang dipulihkan ($\lfloor \text{amount} \times 0.15 \rfloor$).
  - Transaksi atomik: pemotongan kas emas dan pemulihan HP terjadi serentak dengan rollback kas jika gagal.
- **Construction System Foundation** (`scripts/application/coordinators/game_coordinator.gd`):
  - Pengelolaan proyek konstruksi fasilitas via `can_start_construction()`, `start_construction()`, `advance_construction()`, dan `cancel_construction()`.
  - Prasyarat: pekerja konstruksi > 0 (`construction_workers > 0`), kas emas mencukupi, dan proteksi Battle Lock.
  - Transaksi penyelesaian proyek otomatis meningkatkan tingkat gedung target (+1 level).
  - Pembatalan proyek mengembalikan biaya emas kas secara utuh (100% refund).
- **Presentation Integration & Wireframe Layout** (`scripts/presentation/views/prototype_debug_view.gd`, `scripts/presentation/controllers/game_controller.gd`):
  - Penerapan tata letak wireframe: Header, Sidebar, Area Tengah Benteng, Right Tabs, dan Bottom Action Bar.
  - Panel Pertahanan & Reparasi: penampil Wall HP dan Gate HP beserta tombol perbaikan cepat.
  - Panel Populasi & Tenaga Kerja: penampil rincian populasi dan tombol konversi sipil $\leftrightarrow$ pekerja.
  - Panel Fasilitas Benteng: daftar 9 fasilitas dengan level dan tombol upgrade.
  - Panel Status Konstruksi: pelacak progres proyek aktif.
  - Non-aktifkan tombol `Start Battle`: dinonaktifkan secara eksplisit (`disabled = true`) untuk menjaga kepemilikan Wave/Combat pada Phase 6.
  - Metode delegasi presentasi pada `GameController`.
- **State Snapshot Telemetri** (`scripts/domain/state/game_state_snapshot.gd`):
  - Serialisasi data pertahanan (`wall_hp`, `gate_hp`), populasi (`workers`), tenaga kerja (`worker_data`), fasilitas (`buildings_data`), dan proyek konstruksi/reparasi.
  - Deep-copy clone menjamin isolasi memori 100% pada seluruh atribut baru.
- **Dedicated Phase 5 Automated Test Suite** (`tests/test_phase5_fortress_management.gd`):
  - 82 pengujian otomatis terdistribusi ke dalam 8 grup (Group A s/d Group H).
  - Termasuk simulasi stres deterministik 100 siklus manajemen tanpa pelanggaran invarian populasi, pekerja, pertahanan, maupun gudang bersama.

### Verified
- **Phase 5 Dedicated Test Suite**: 82/82 PASSED (100%).
- **Full Automated Regression Suite**: 677/677 PASSED across all 17 test suites (Phase 1 through Phase 5) with 0 regressions.
- **Prototype Scene Smoke Playtest**: ALL PASS (0 errors) on Godot SceneTree.
- **Phase 5 (Fortress & Management Systems)**: RESMI DITUTUP (**COMPLETED / CLOSED**). Phase 6 berstatus **LOCKED**.

---

## [0.5.9] - Phase 4H: Hero System Integration & Verification (Completed & Closed)

### Added
- **Phase 4H Comprehensive Integration Test Suite** (`tests/test_phase4h_hero_system_integration.gd`):
  - 81 pengujian integrasi lintas sistem terdistribusi ke dalam 11 kelompok terstruktur:
    - **Group A (Tests 1-10)**: Hero Domain & Lifecycle Integration — transisi `RECRUITABLE` $\rightarrow$ `ROSTER_ACTIVE` $\rightarrow$ `IN_PARTY` $\rightarrow$ `BATTLE_ACTIVE` $\rightarrow$ `IN_PARTY` / `PERMADEATH`; penegakan `PERMADEATH` sebagai state terminal mutlak dan sinkronisasi reaktif ke snapshot.
    - **Group B (Tests 11-20)**: Party Management & Combat Routing Integration — pembatasan 2 regu kanonikal (`party_1`, `party_2`), batas kapasitas 3 pahlawan per regu, isolasi penuh Party 2 dan Reserve dari pertempuran, penegakan kontribusi ATK hanya dari Party 1, penanganan Party 1 kosong dengan graceful fallback, dan rollback atomik penugasan regu saat gagal.
    - **Group C (Tests 21-30)**: Chemistry System Integrity & Single-Path Verification — validasi jalur tunggal kanonikal di `CombatEngine` pasca-survival (+2 chemistry per pasangan Party 1 hidup), simetri mutlak kemitraan, batas atas (*hard cap*) 50 poin, pemblokiran *self-chemistry*, persistensi saat pahlawan keluar/masuk regu, dan konfirmasi zero chemistry gain saat tidak ada pertempuran atau saat refresh snapshot.
    - **Group D (Tests 31-40)**: Progression, EXP & Ascension Integration — pembagian EXP tempur deterministik dan terbatas pada Party 1 hidup, formula EXP kanonikal $\lfloor 120.0 \times L^{1.55} \rfloor$, level cap berbasis bintang ($\text{star} \times 10$), pelestarian carry-over EXP di level cap, aturan kenaikan poin bakat pada level ganjil (*odd-level rule*), dan non-interferensi EXP latihan vs tempur.
    - **Group E (Tests 41-48)**: Fatigue, Morale & Training Integration — akumulasi fatigue tempur (+15) eksklusif pada Party 1, batasan latihan 1x per pahlawan per gelombang, batas kelelahan 100 tanpa silent clamping, aksi istirahat (-25 fatigue, +5 morale), dan pengaruh multiplier kelelahan dan moral pada stat tempur efektif.
    - **Group F (Tests 49-56)**: Skills & Talents Integration — katalog skill 4 peran kanonikal (`KNIGHT`, `ARCHER`, `MAGE`, `PRIEST`), validasi syarat peran & level pada pembukaan skill, pembukaan idempoten (pencegahan duplikasi), alokasi bakat 3 cabang (`OFFENSE`, `DEFENSE`, `LEADERSHIP`) dengan batas level 3 per cabang, pengali stat gabungan deterministik, dan pelestarian data saat kloning.
    - **Group G (Tests 57-66)**: Equipment & Shared Warehouse Conservation Integration — penegakan ketat invarian konservasi $\text{Total Owned} = \text{USBL} + \text{DMGD} + \text{HERO} + \text{REGD}$, validasi kompatibilitas slot & peran, transaksi atomik equip/unequip, kelestarian gear pada pahlawan yang bertahan hidup, pengembalian seluruh gear pahlawan permadeath ke gudang bersama tepat 1x tanpa pengembalian ganda, dan kebebasan mutasi regu tanpa merusak gear terpasang.
    - **Group H (Tests 67-72)**: Recruitment & Ascension Economy Integration — biaya rekrutmen kanonikal mutlak 500 Gold tanpa override, penolakan saat kas < 500 Gold, gear awal pahlawan baru kosong (konservasi gudang), biaya ascension kanonikal $\text{star} \times 150 \text{ Gold}$, dan pelestarian seluruh atribut progresi pahlawan saat ascension.
    - **Group I (Tests 73-76)**: State Machine, Snapshot & Presentation Sync — deep-copy kloning `HeroModel`, `PartyModel`, dan `GameStateSnapshot` membuktikan isolasi memori penuh, serta sinkronisasi reaktif snapshot dan emisi sinyal `state_changed` pada setiap mutasi pahlawan.
    - **Group J (Tests 77-80)**: Permadeath End-to-End Resolution — pelepasan otomatis pahlawan permadeath dari regu, pengosongan status ketua regu, pembersihan referensi chemistry secara simetris dari pahlawan lain, dan pemblokiran total pahlawan permadeath dari aksi rekrutmen, latihan, istirahat, ascension, equip, alokasi bakat, pembukaan skill, maupun penugasan regu.
    - **Group K (Test 81)**: Deterministic 50-Wave Multi-System Stress Simulation — simulasi ketahanan 50 gelombang tempur tanpa henti membuktikan stabilitas siklus `PREPARATION` $\rightarrow$ `WAVE_PREVIEW` $\rightarrow$ `BATTLE` $\rightarrow$ `RESULT` $\rightarrow$ `RECOVERY` $\rightarrow$ `PREPARATION`, batas atas chemistry $\le 50$, perutean isolasi tempur Party 1, eksekusi gugur permadeath di gelombang 25 dengan pembersihan regu dan penggantian oleh pahlawan cadangan di gelombang 26, serta pelestarian invarian konservasi gudang bersama di setiap gelombang.
- **Architectural & Safety Verification**:
  - Audit cross-layer membuktikan kepatuhan single-source-of-truth ownership di `HeroModel` dan `GameCoordinator`.
  - Penegakan Battle Lock terverifikasi pada 12 metode mutasi `GameCoordinator` selama status `STATE_BATTLE`.

### Verified
- **Phase 4H Test Suite**: 81/81 PASSED (100%).
- **Full Automated Regression Suite**: 595/595 PASSED across all 16 test suites (Phase 1 through Phase 4H) with 0 regressions.
- **Scene Smoke Playtest**: ALL PASS (0 errors) on Godot SceneTree.
- **Phase 4 (Hero System)**: RESMI DITUTUP (**COMPLETED / CLOSED**).

---

## [0.5.8] - Phase 4G: Hero Management UX (Implemented & Verified)

### Added
- **Functional Prototype Hero Management UX** (`scripts/presentation/views/prototype_debug_view.gd`):
  - Arsitektur antarmuka prototype yang diperluas secara modular pada kolom kanan (`right_vbox`), mempertahankan keterpisahan lapisan presentasi dan bebas dari polling `_process()`.
  - **Mercenary Guild Recruitment Panel**:
    - Tampilan kas emas benteng dan biaya rekrutmen kanonikal mutlak 500 Gold (`HERO_RECRUITMENT_COST_DEFAULT = 500`).
    - Role picker interaktif (`KNIGHT`, `ARCHER`, `MAGE`, `PRIEST`) dengan status seleksi peran dan pratinjau kandidat pahlawan (1★ / Potensi 3★).
    - Proteksi Battle Lock dan validasi kecukupan kas benteng: tombol rekrutmen dinonaktifkan secara reaktif saat kas < 500 Gold atau selama fase `BATTLE`.
    - Auto-selection: pahlawan yang baru direkrut langsung terpilih secara otomatis pada panel detail.
  - **Party Management Panel (Phase 4F Integration)**:
    - Visualisasi status Party 1 (Active Battle Party) dan Party 2 (Management Reserve) dengan kapasitas maksimal 3 pahlawan.
    - Indikator ketua regu (`[LEADER]`), tombol jadikan pemimpin (`Jadikan Leader`), dan tombol lepas dari regu (`Lepas`).
    - Visualisasi pahlawan cadangan (RESERVE) dengan tombol penugasan ke Party 1 (`+ Party 1`) dan Party 2 (`+ Party 2`).
    - Proteksi otomatis: tombol penugasan dinonaktifkan saat regu penuh (3/3) atau selama fase `BATTLE`.
  - **Hero Roster Panel**:
    - Kartu ringkasan setiap pahlawan terdaftar: nama, level, peran, bintang/potensi, status kehidupan (`ALIVE` / `DEAD (Permadeath)`), EXP saat ini/syarat, fatigue, morale, lifecycle state, dan regu penugasan (`RESERVE` / `PARTY_1` / `PARTY_2`).
    - Tombol seleksi pahlawan interaktif (`Pilih / Lihat Detail`) untuk menampilkan detail lengkap pahlawan terpilih.
  - **Comprehensive Hero Detail Panel**:
    - **Identitas & Statistik Tempur**: Bintang, potensi, level cap, EXP bar, status hidup, HP dasar, ATK & DEF efektif beserta nilai dasar, kelelahan (fatigue 0-100), dan moral (morale 0-150).
    - **Aksi Progresi & Pemulihan**:
      - Tombol *Ascension* (+1★): memvalidasi level cap, potensi bintang, dan kecukupan kas emas kanonikal.
      - Tombol *Latihan* (+40 EXP, +15 Fatigue): memvalidasi batas 1x latihan per gelombang dan batas fatigue $\le 100$.
      - Tombol *Istirahat* (-25 Fatigue, +5 Morale): pemulihan kelelahan dan moral secara aman.
    - **Katalog Keahlian Kanonikal (Phase 4E)**: Menampilkan keahlian kanonikal sesuai peran pahlawan (`Iron Edge`, `Iron Guard`, `Battle Leadership` untuk Knight, dll.) dengan status terbuka/terkunci dan tombol pembukaan keahlian berbasis level minimum.
    - **Pohon Bakat (Phase 4E)**: Visualisasi 3 cabang bakat (`OFFENSE`, `DEFENSE`, `LEADERSHIP`), pengali bakat aktif, poin bakat tersedia, dan tombol alokasi bakat (maksimal tingkat 3).
    - **Status Kemitraan (Chemistry - Phase 4F)**: Tampilan display-only interaktif untuk pasangan mitra tempur di Party 1, poin kemitraan (cap 50), dan bonus efektivitas bersama (+0.5%/pt) tanpa tombol mutasi manual.
    - **Kontrol Perlengkapan (Phase 3C)**: Aksi pasang (equip) dan lepas (unequip) senjata primer, sekunder, dan zirah yang terintegrasi dengan stok Shared Warehouse, serta pemblokiran total pada hero permadeath.
  - **Actionable Feedback Banner**: Banner umpan balik visual terpadu (`_lbl_feedback_banner`) yang mengonfirmasi keberhasilan aksi (`[REKRUTMEN]`, `[ASCENSION]`, `[LATIHAN]`, `[ISTIRAHAT]`, `[SKILL]`, `[BAKAT]`, `[REGU]`, `[LEADER]`) serta memberikan alasan penolakan jika transaksi tidak valid (`[DITOLAK]`).
- **GameController Presentation Forwarding APIs** (`scripts/presentation/controllers/game_controller.gd`):
  - Penambahan 20 metode pembantu delegasi ke `GameCoordinator`: `get_heroes()`, `can_recruit_hero()`, `recruit_hero()`, `can_ascend_hero()`, `ascend_hero()`, `can_train_hero()`, `train_hero()`, `can_rest_hero()`, `rest_hero()`, `can_unlock_hero_skill()`, `unlock_hero_skill()`, `can_allocate_hero_talent()`, `allocate_hero_talent()`, `get_party()`, `get_parties()`, `can_assign_hero_to_party()`, `assign_hero_to_party()`, `can_remove_hero_from_party()`, `remove_hero_from_party()`, `can_set_party_leader()`, `set_party_leader()`.
- **GameCoordinator Query Helpers & Snapshot Telemetry** (`scripts/application/coordinators/game_coordinator.gd`):
  - Penambahan metode kueri validasi UI: `can_ascend_hero(hero_id: String) -> bool` dan `can_recruit_hero() -> bool`.
  - Serialisasi atribut `required_exp` pada setiap entri `heroes_data` di `_update_snapshot()` untuk transparansi progresi pada antarmuka pengguna tanpa kalkulasi ulang di presentation layer.
- **Phase 4G Automated Test Suite** (`tests/test_phase4g_hero_management_ux.gd`):
  - 60 pengujian fungsional dan reaktif terstruktur dalam 10 kelompok:
    - Group A: Hero Roster UX Tests (1-6)
    - Group B: Hero Detail Panel UX Tests (7-12)
    - Group C: Hero Recruitment UX Tests (13-18)
    - Group D: Ascension UX Tests (19-24)
    - Group E: Training & Rest UX Tests (25-30)
    - Group F: Skills & Talents UX Tests (31-38)
    - Group G: Party Management UX Tests (39-45)
    - Group H: Chemistry UX Tests (46-49)
    - Group I: Equipment UX & Permadeath Tests (50-54)
    - Group J: Integration, Reactive Sync & Feedback Tests (55-60)

### Verified
- **Phase 4G Test Suite**: 60/60 PASSED (100%).
- **Full Automated Regression Suite**: 514/514 PASSED across 15 test suites (Phase 1 s/d Phase 4G) with 0 regressions.
- **Scene Smoke Playtest**: ALL PASS (0 errors) on Godot SceneTree.

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
