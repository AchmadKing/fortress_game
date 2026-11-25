# Mathematical & Systems Prototype Design — Fortress Game (Audited & Refined)

**Status**: APPROVED DESIGN BASELINE (PHASE 2)  
**Tujuan**: Memvalidasi model matematika, keseimbangan loop ekonomi, manajemen tenaga kerja (manpower), progresi pahlawan, ketahanan benteng, dan kurva ancaman gelombang secara deterministik dan headless.  
**Prinsip Utama**: *Inspect Before Modify. Extend, Don't Break. No Scope Creep.*

> [!IMPORTANT]
> Dokumen ini adalah hasil audit dan penyempurnaan terhadap draf awal sistem matematika. Seluruh formula memisahkan **Core Mathematical Relations** (rumus dasar) dari **Balance Parameters** (parameter penyetelan). Tidak ada penyederhanaan berlebih seperti "Single Battle Power", dan seluruh sistem diimplementasikan secara headless tanpa visual/gameplay scene.

---

## 1. System Architecture & Component Mapping

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        FORTRESS MANAGEMENT LOOP                        │
├───────────────────────────────┬────────────────────────────────────────┤
│ 1. Demography & Manpower      │ Total Pop = Civilians + Soldiers       │
│ 2. Worker Allocation          │ Blacksmith, Repair, Construction, Econ │
│ 3. Military & Equipment       │ Equipment defines Soldier Roles        │
│ 4. Hero Formation & Chemistry │ Individual Heroes, Fatigue, Permadeath │
│ 5. Fortress Integrity         │ Persistent HP, Armor, Repair Loop      │
├───────────────────────────────┴────────────────────────────────────────┤
│                         HEADLESS COMBAT ENGINE                         │
├────────────────────────────────────────────────────────────────────────┤
│ Phase 1: Ranged / Volley (Archers vs Enemy Swarms/Flying)             │
│ Phase 2: Frontline Clash (Shield & Spear vs Brutes/Beasts)             │
│ Phase 3: Hero & Melee Engagement (Hero Stats, Chemistry, Skills)       │
│ Phase 4: Fortress Wall Breach (Residual Siege Damage vs Wall Armor)    │
│ Phase 5: Resolution (Casualties, Equipment Wear, EXP, Fatigue, Loot)   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Core Formulas vs Balance Parameters

### A. Population & Manpower Model

#### 1. Core Mathematical Relations
- **Populasi Total**:
  $$P_{total} = P_{civ} + P_{sol}$$
  *(Hero $H_i$ adalah entitas individual berstatus komandan khusus yang tidak diambil dari pool warga sipil biasa).*
- **Rekrutmen Serdadu**:
  $$\Delta P_{sol} = +k \implies \Delta P_{civ} = -k$$
- **Kematian Pasukan (Permanent Population Loss)**:
  $$P_{total}^{t+1} = P_{total}^t - Casualties_{sol} + Growth_{civ}$$
  *(Prajurit yang gugur tidak pernah kembali menjadi warga sipil. Kematian prajurit langsung memotong populasi total).*
- **Tentara Bayaran (*Mercenaries*, $M_{merc}$)**:
  Disewa langsung menggunakan emas tanpa mengurangi warga sipil:
  $$M_{merc} \notin P_{total}, \quad Upkeep_{merc} = M_{merc} \times Cost_{merc\_upkeep}$$
- **Pertumbuhan Populasi Alami (Logistic Growth)**:
  $$Growth_{civ} = \max\left(0, \left\lfloor r_{growth} \times (C_{pop} - P_{total}) \times \frac{Morale_{civ}}{100} \right\rfloor\right)$$
  *(Pertumbuhan melambat saat mendekati kapasitas hunian $C_{pop}$ dan berhenti total jika $P_{total} \ge C_{pop}$).*

#### 2. Balance Parameters
- `base_growth_rate` ($r_{growth}$): $0.08$
- `default_housing_capacity` ($C_{pop}$): $30$ (dapat diperluas via konstruksi)
- `min_morale_for_growth`: $60$

---

### B. Worker Economy & Job Allocation Model

Pekerja ($P_{civ}$) tidak menghasilkan emas gaib secara pasif, melainkan dialokasikan ke pos kerja nyata:

$$P_{civ} = W_{blacksmith} + W_{repair} + W_{construction} + W_{production} + W_{idle}$$

#### 1. Core Mathematical Relations
- **Pos Produksi / Ekonomi ($W_{production}$)**:
  Menghasilkan pendapatan emas dan material perdagangan:
  $$Gold_{produced} = W_{production} \times Output_{base} \times \left(\frac{Morale_{civ}}{100}\right) \times FacilityEff_{econ}$$
- **Pos Bengkel / Pandai Besi ($W_{blacksmith}$)**:
  Menghasilkan material perawatan senjata dan meningkatkan efisiensi perbaikan perlengkapan:
  $$SmithingOutput = W_{blacksmith} \times CraftRate_{base} \times FacilityEff_{forge}$$
- **Pos Reparasi ($W_{repair}$)**:
  Memulihkan ketahanan benteng ($HP_{fort}$) pasca-pertempuran:
  $$HP_{repaired} = \min\left(HP_{max} - HP_{fort}, W_{repair} \times RepairPerWorker \times FacilityEff_{repair}\right)$$
- **Pos Konstruksi ($W_{construction}$)**:
  Membangun atau meng-upgrade fasilitas benteng (menaikkan $C_{pop}$, $HP_{max}$, atau efisiensi fasilitas).
- **Biaya Pemeliharaan Warga (*Worker Upkeep*)**:
  $$Expense_{civ} = P_{civ} \times Salary_{civ}$$

#### 2. Balance Parameters
- `worker_base_output`: $12\text{ Gold}$
- `worker_salary`: $4\text{ Gold}$
- `repair_hp_per_worker`: $25\text{ HP/wave}$
- `repair_cost_per_hp`: $0.15\text{ Gold}$ (material repair)

---

### C. Soldier System & Role Differentiation via Equipment

Pasukan dimodelkan secara agregat berdasarkan perlengkapan yang diberikan dari gudang senjata (*Warehouse*).

#### 1. Core Mathematical Relations
Perlengkapan mendefinisikan peran taktis serdadu:
- **Pedang Ringan**: *Swordsman* (Melee DPS tinggi, efektif melawan Swarm/Unarmored).
- **Pedang + Perisai**: *Shield Infantry* (Mitigasi damage tinggi, penahan lini depan, menyerap serangan proyektil/panah).
- **Tombak**: *Spearman* (Bonus anti-kavaleri / monster besar, jangkauan serang menengah).
- **Busur & Panah**: *Archer* (Serangan jarak jauh, melemahkan musuh sebelum mencapai dinding, anti-flying).
- **Armor Berat + Pedang Besar**: *Heavy Infantry* (Shock infantry garis depan berkekuatan destruktif tinggi).

Kekuatan serdadu per grup peran $k$:
$$Power_k = N_k \times BaseStat_k \times \left(1 + \frac{TierMod_{eq}}{100}\right) \times \left(\frac{Morale_{sol}}{100}\right)$$

Total biaya pemeliharaan militer:
$$Expense_{sol} = \sum_k (N_k \times Salary_{sol\_k}) + (M_{merc} \times Salary_{merc})$$

#### 2. Balance Parameters
- `swordsman_base_atk`: $14$, `def`: $6$, `salary`: $6$
- `shield_infantry_base_atk`: $8$, `def`: $18$, `salary`: $7$
- `spearman_base_atk`: $12$, `def`: $10$, `salary`: $6$
- `archer_base_atk`: $16$, `def`: $4$, `salary`: $7$
- `heavy_infantry_base_atk`: $20$, `def`: $16$, `salary`: $11$
- `mercenary_salary`: $18$

---

### D. Hero Progression & Party Chemistry

Hero adalah komandan independen unik dengan atribut individual dan potensi kematian permanen (*Permadeath*).

#### 1. Core Mathematical Relations
- **Kurva Kebutuhan EXP**:
  $$EXP_{req}(L) = \left\lfloor 120 \times L^{1.55} \right\rfloor$$
- **Kekuatan Stat Hero**:
  $$Stat(L, S_{cur}) = BaseStat \times \left(1 + (L - 1) \times GrowthRate\right) \times \left(1 + (S_{cur} - 1) \times 0.20\right)$$
  *(Syarat bintang: $S_{cur} \le S_{pot}$. Bintang saat ini tidak boleh melampaui potensi bintang).*
- **Kelelahan (*Fatigue*, $F \in [0, 100]$)**:
  - Bertempur menambah $+15$ Fatigue.
  - Berlatih di Camp menambah $+25$ Fatigue dan memberikan EXP terukur.
  - Beristirahat (rotasi cadangan) memulihkan $-30$ Fatigue.
  - Efektivitas tempur terpengaruh oleh penalti fatigue:
    $$Mod_{fatigue} = \max\left(0.40, 1.0 - \frac{Fatigue}{100} \times 0.75\right)$$
- **Kimiawi Pasukan (*Party Chemistry*, $C_{chem} \in [0, 50]$)**:
  - Meningkat $+2$ poin setiap kali 2 atau lebih hero bertempur bersama dalam satu formasi pertempuran.
  - Memberikan bonus koordinasi taktis:
    $$Bonus_{chem} = 1.0 + \frac{C_{chem}}{100}$$
- **Kematian Permanen Hero**:
  Jika hero terluka fatal dalam pertempuran dan benteng tertembus parah, hero memiliki probabilitas kematian permanen berdasarkan sisa HP dan skala kekalahan. Hero yang mati dihapus permanen dari daftar komandan.

#### 2. Balance Parameters
- `hero_base_hp`: $250$, `atk`: $35$, `def`: $20$
- `hero_growth_rate`: $0.12$ per level
- `max_level_cap`: $50$
- `fatigue_penalty_threshold`: $40$

---

### E. Equipment & Durability Model

Perlengkapan disimpan di gudang (*Warehouse*) dan mengalami keausan per pertempuran.

#### 1. Core Mathematical Relations
- **Degradasi Durabilitas**:
  $$D^{t+1} = \max\left(0, D^t - \Delta D_{battle}\right)$$
  $$\Delta D_{battle} = \lfloor BaseDecay \times Intensity_{clash} \rfloor$$
- **Penalti Kerusakan**:
  Jika $D = 0$, perlengkapan dianggap *Broken*; bonus peran dan statistik turun menjadi $10\%$ dari nilai normal.
- **Biaya Reparasi**:
  $$Cost_{repair} = \lceil (100 - D) \times Rate_{tier} \times \text{Diskon}_{blacksmith} \rceil$$
- **Kehilangan Perlengkapan (*Equipment Loss*)**:
  Jika prajurit pembawa gugur, perlengkapan memiliki peluang $35\%$ hancur/hilang dan $65\%$ dipulihkan kembali ke gudang dalam kondisi rusak ($D \le 20$).

#### 2. Balance Parameters
- `base_durability_decay`: $10$ per battle
- `t1_repair_rate`: $0.20\text{ Gold/durability}$
- `t2_repair_rate`: $0.50\text{ Gold/durability}$
- `t3_repair_rate`: $1.10\text{ Gold/durability}$
- `t4_repair_rate`: $2.20\text{ Gold/durability}$
- `t5_repair_rate`: $4.50\text{ Gold/durability}$

---

### F. Fortress Durability & Structural Mechanics

Benteng adalah jantung pertahanan dan penentu kelangsungan permainan (*survival core*).

#### 1. Core Mathematical Relations
- **Kondisi Kalah Mutlak (*Absolute Fail Condition*)**:
  $$HP_{fort} \le 0 \implies \mathbf{GAME\ OVER}$$
- **Ketahanan Persisten**: Nilai $HP_{fort}$ diteruskan antar-gelombang. Kerusakan yang belum diperbaiki akan tetap ada di gelombang berikutnya.
- **Formula Penyerapan Kerusakan Tembok**:
  $$Damage_{fort} = \max\left(0, \left\lfloor Threat_{breach} \times (1.0 - ArmorReduction_{wall}) \right\rfloor\right)$$
  $$ArmorReduction_{wall} = \frac{Armor_{fort}}{Armor_{fort} + 150}$$

#### 2. Balance Parameters
- `base_fortress_hp`: $1.000$
- `base_fortress_armor`: $40$ (mereduksi $\approx 21\%$ damage tembus)
- `fortress_upgrade_hp_step`: $+350\text{ HP per tier}$
- `fortress_upgrade_armor_step`: $+15\text{ Armor per tier}$

---

### G. Wave Threat Budget ($TB$) & Enemy Composition Generator

Threat budget digunakan sebagai **generator komposisi musuh**, bukan hasil pertempuran.

#### 1. Core Mathematical Relations
- **Kurva Anggaran Ancaman Wave $W \in [1, 100]$**:
  - Wave 1–5 (Early Tutorial Ramp, Linier & Ramah):
    $$TB(W) = 25 + (W - 1) \times 15 \quad \implies [25, 40, 55, 70, 85]$$
  - Wave 6–100 (Power Law Scaling):
    $$TB(W) = \left\lfloor 85 \times \left(\frac{W}{5}\right)^{1.30} \times (1 + \text{rand}(-0.06, +0.06)) \right\rfloor$$
- **Generator Komposisi Musuh**:
  Anggaran $TB$ dibelanjakan untuk membeli kombinasi kategori musuh:
  - *Swarm Minion* ($Cost = 2$, Kecepatan tinggi, Unarmored)
  - *Raider Infantry* ($Cost = 6$, Seimbang)
  - *Armored Brute* ($Cost = 16$, Armor tinggi, lambat)
  - *Flying Screamer* ($Cost = 12$, Mengabaikan garis depan, rentan panah)
  - *Siege Ram/Catapult* ($Cost = 40$, Target khusus tembok benteng)
  - *Boss Warlord* ($Cost = 100+$, Hadir di wave kelipatan 10)

#### 2. Balance Parameters
- `wave_exponent`: $1.30$
- `variance_bound`: $\pm 6\%$
- `min_wave_for_flying`: Wave 6
- `min_wave_for_siege`: Wave 12
- `boss_wave_interval`: Setiap 10 Wave

---

### H. Multi-Phase Deterministic Combat Engine

Pertempuran TIDAK ditentukan oleh satu angka "Battle Power". Pertempuran dieksekusi melalui **5 fase kalkulasi deterministik bertahap**:

```text
Phase 1: Ranged Volley (Pemanah & Artileri Benteng vs Musuh Terbuka)
   │
   ▼
Phase 2: Frontline Clash (Shield & Spearman vs Brute & Raiders)
   │
   ▼
Phase 3: Melee Engagement & Hero Intervention (Swordsman, Heavy, Hero Skills)
   │
   ▼
Phase 4: Wall Breach & Siege Assault (Sisa Ancaman vs Ketahanan Tembok)
   │
   ▼
Phase 5: Casualty, Wear, and Loot Resolution
```

#### Rincian Fase:
1. **Fase 1 (Ranged Volley)**:
   - Pemanah pemain menembak musuh yang mendekat. Musuh terbang (*flying*) dan swarm menerima damage $+50\%$ lebih besar dari panah. Musuh bershield menerima damage $-40\%$.
   - Sisa ancaman musuh yang lolos masuk ke Fase 2.
2. **Fase 2 (Frontline Clash)**:
   - Pasukan perisai (*Shield Infantry*) menyerap benturan utama, mengurangi damage tembusan.
   - Pasukan tombak (*Spearman*) memberikan damage ekstra $+40\%$ terhadap musuh bertipe Brute/Monster.
3. **Fase 3 (Melee Engagement & Hero Skills)**:
   - Swordsman dan Heavy Infantry bertarung di pertempuran jarak dekat.
   - Hero mengaplikasikan stat serangan, status fatigue, dan bonus kimiawi (*Chemistry*).
4. **Fase 4 (Wall Breach)**:
   - Jika total daya tangkal pada fase 1–3 belum mampu menghabisi seluruh ancaman musuh, sisa ancaman dan unit Siege Engine menyerang langsung tembok benteng, dikurangi oleh Armor benteng.
5. **Fase 5 (Resolusi Pasca-Pertempuran)**:
   - Perhitungan korban prajurit ($Casualties_{sol}$).
   - Perhitungan durabilitas equipment yang aus.
   - Perolehan EXP dan penambahan Fatigue hero.
   - Perhitungan loot emas dan material yang dirampas dari musuh.
   - Penyesuaian moral benteng (+3 jika menang tanpa korban, -10 jika tembok tertembus).

---

## 3. Analisis Stabilitas 100 Gelombang & Uji 8 Skenario

### Proyeksi Stabilitas Ekonomi & Ancaman (Tonggak Wave)

| Wave | Threat ($TB$) | Target Pasukan ($P_s$) | Pekerja ($P_w$) | Net Gold/Wave | Tembok ($HP_{max}$) | Hero Avg Level | Status Keseimbangan |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | $25$ | $3$ | $12$ | $+55$ | $1.000$ | Lv $1$ | Awal aman, surplus ekonomi stabil |
| **5** | $85$ | $6$ | $18$ | $+88$ | $1.200$ | Lv $3$ | Pembentukan peran pasukan |
| **10** | $210$ | $10$ | $24$ | $+110$ | $1.550$ | Lv $6$ | Boss Wave 1, butuh perisai & hero |
| **20** | $520$ | $18$ | $34$ | $+165$ | $2.400$ | Lv $11$ | Variasi musuh terbang & siege |
| **35** | $1.080$ | $30$ | $50$ | $+260$ | $4.000$ | Lv $18$ | Butuh Tier 3 equipment & chemistry |
| **50** | $1.910$ | $45$ | $75$ | $+390$ | $6.500$ | Lv $26$ | Pertengahan game, ancaman brute masif |
| **75** | $3.440$ | $68$ | $110$ | $+580$ | $10.000$ | Lv $38$ | Tekanan logistik & rotasi hero |
| **100** | $5.320$ | $95$ | $150$ | $+810$ | $15.000$ | Lv $48$ | Ujian akhir pertahanan benteng |

---

## 4. Rencana Implementasi Modul Headless (Phase 2)

Seluruh logika di atas akan diterjemahkan ke dalam modul simulasi deterministik murni:

1. `scripts/domain/model/population_model.gd`: Representasi domain data populasi, serdadu, dan pekerja.
2. `scripts/domain/model/hero_model.gd`: Representasi domain data individual hero, level, EXP, fatigue, chemistry.
3. `scripts/domain/model/equipment_model.gd`: Model perlengkapan, tier, peran, durabilitas.
4. `scripts/domain/model/fortress_model.gd`: Model benteng, HP persisten, armor, repair worker allocation.
5. `scripts/simulation/wave_generator.gd`: Generator deterministik wave 1–100 berbasis threat budget dan seed.
6. `scripts/simulation/combat_engine.gd`: Engine kalkulasi 5-fase deterministik tanpa SceneTree.
7. `scripts/simulation/economy_manager.gd`: Kalkulator alokasi kerja pekerja, biaya, dan perolehan material.
8. `tests/test_mathematical_prototype.gd`: Test suite otomatis untuk memvalidasi ke-8 skenario stres dan simulasi 100 gelombang.

---

> **STATUS: REFINED DESIGN DOCUMENT READY FOR SCRIPT IMPLEMENTATION**
