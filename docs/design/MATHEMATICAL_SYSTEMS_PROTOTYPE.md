# Mathematical & Systems Prototype Design — Fortress Game (Final Validated)

**Status**: COMPLETED & VALIDATED (PHASE 2)  
**Tujuan**: Memvalidasi model matematika, keseimbangan loop ekonomi, manajemen tenaga kerja (manpower), progresi pahlawan, ketahanan benteng, dan kurva ancaman gelombang secara deterministik dan headless.  
**Prinsip Utama**: *Inspect Before Modify. Extend, Don't Break. No Scope Creep.*

> [!IMPORTANT]
> Dokumen ini mencerminkan sistem matematika final yang telah tervalidasi melalui pengujian headless deterministik. Seluruh formula memisahkan **Core Mathematical Relations** (rumus dasar) dari **Balance Parameters** (parameter penyetelan).
> **Catatan Kritis**: Hasil simulasi 100-wave adalah pengujian stabilitas sistem otomatis (*automated management policy*), BUKAN bukti bahwa balancing final untuk pemain manusia sudah sempurna.

---

## 1. System Architecture & Component Mapping

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        FORTRESS MANAGEMENT LOOP                        │
├───────────────────────────────┬────────────────────────────────────────┤
│ 1. Demography & Manpower      │ Total Pop = Civilians + Soldiers       │
│ 2. Worker Allocation          │ Blacksmith, Repair, Construction, Idle │
│ 3. Military & Equipment       │ Equipment defines Soldier Roles & Qty  │
│ 4. Hero Formation & Survival  │ Individual Heroes, Fatigue, Permadeath │
│ 5. Fortress Integrity         │ Persistent HP, Armor, Worker Repair    │
├───────────────────────────────┴────────────────────────────────────────┤
│                         HEADLESS COMBAT ENGINE                         │
├────────────────────────────────────────────────────────────────────────┤
│ Phase 1: Ranged Volley (Archers vs Enemy Swarms/Flying)             │
│ Phase 2: Frontline Clash (Shield & Spear vs Brutes/Beasts)             │
│ Phase 3: Hero & Melee Engagement (Hero Stats, Chemistry, Fatigue)      │
│ Phase 4: Fortress Wall Breach (Residual Siege Damage vs Wall Armor)    │
│ Phase 5: Resolution (Casualties, Equipment Loss/Wear, EXP, Loot)       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Core Formulas vs Balance Parameters

### A. Population & Manpower Model

#### 1. Core Mathematical Relations
- **Populasi Total**:
  $$P_{total} = P_{civ} + P_{sol}$$
  *(Hero adalah komandan khusus yang tidak mengambil kuota warga sipil biasa).*
- **Rekrutmen Serdadu**:
  $$\Delta P_{sol} = +k \implies \Delta P_{civ} = -k$$
- **Kematian Pasukan (Permanent Population Loss)**:
  $$P_{total}^{t+1} = P_{total}^t - Casualties_{sol} + Growth_{civ}$$
  *(Prajurit yang gugur tidak pernah kembali menjadi warga sipil).*
- **Tentara Bayaran (*Mercenaries*, $M_{merc}$)**:
  Disewa langsung menggunakan emas tanpa mengurangi kuota warga sipil:
  $$M_{merc} \notin P_{total}, \quad Upkeep_{merc} = M_{merc} \times Salary_{merc}$$
- **Pertumbuhan Populasi Alami (Logistic Growth)**:
  $$Growth_{civ} = \max\left(0, \left\lfloor r_{growth} \times (C_{pop} - P_{total}) \times \frac{Morale_{civ}}{100} \right\rfloor\right)$$

#### 2. Balance Parameters
- `base_growth_rate` ($r_{growth}$): $0.08$
- `default_housing_capacity` ($C_{pop}$): $30$
- `min_morale_for_growth`: $60$

---

### B. Worker Economy & Job Allocation Model

**Koreksi Resmi**: TIDAK ADA PRODUCTION WORKER dan TIDAK ADA PASSIVE INCOME.  
Pekerja ($P_{civ}$) dialokasikan secara agregat ke 4 peran sah:

$$P_{civ} = W_{blacksmith} + W_{repair} + W_{construction} + W_{idle}$$

#### 1. Core Mathematical Relations
- **Pendapatan Bersih Siklus (*Gross Cycle Income*)**:
  $$GrossIncome = 0\text{ (Tidak ada passive gold)}$$
  *Sumber pendapatan kas bendahara berasal murni dari Battle Loot pertempuran.*
- **Pandai Besi (*Blacksmith*, $W_{blacksmith}$)**:
  Memberikan efisiensi dan diskon perbaikan perlengkapan di gudang senjata:
  $$\text{SmithDiscount} = \min(0.60, W_{blacksmith} \times 0.12)$$
- **Reparasi Benteng (*Repair*, $W_{repair}$)**:
  Memulihkan ketahanan benteng ($HP_{fort}$) pasca-pertempuran:
  $$HP_{repaired} = \min\left(HP_{max} - HP_{fort}, W_{repair} \times RepairPerWorker\right)$$
  $$Cost_{repair\_mat} = \lceil HP_{repaired} \times CostPerHP \rceil$$
- **Konstruksi (*Construction*, $W_{construction}$)**:
  Menangani ekspansi kapasitas hunian benteng dan upgrade dinding benteng.
- **Biaya Pemeliharaan Warga (*Worker Upkeep*)**:
  $$Expense_{civ} = P_{civ} \times Salary_{civ}$$

#### 2. Balance Parameters
- `worker_salary`: $3\text{ Gold}$
- `repair_hp_per_worker`: $25\text{ HP/wave}$
- `repair_cost_per_hp`: $0.15\text{ Gold}$

---

### C. Soldier System & Role Differentiation via Equipment

Pasukan dimodelkan secara agregat berdasarkan perlengkapan yang tersedia di gudang (*Warehouse*).

#### 1. Core Mathematical Relations
- **Model Kepemilikan & Kuantitas Perlengkapan (Equipment Quantity Model)**:
  Jumlah serdadu yang memperoleh bonus Tier perlengkapan dibatasi secara ketat oleh kuantitas perlengkapan ($Q$) di gudang senjata.
  Untuk peran $R$ dengan $N$ prajurit dan perlengkapan dengan tier $t$:
  $$N_{equipped}(t) = \min(N_{remaining}, Q_t)$$
  $$Power = \left(\sum_t N_{equipped}(t) \times BaseStat \times Mult(t) + N_{unequipped} \times BaseStat \times 1.0\right) \times \frac{Morale}{100}$$
  *(Equipment rusak ($Durability \le 0$) tidak dapat digunakan dan tidak memberikan bonus tier).*

Total biaya pemeliharaan militer:
$$Expense_{sol} = \sum_k (N_k \times Salary_{sol\_k}) + (M_{merc} \times Salary_{merc})$$

#### 2. Balance Parameters
- `swordsman_base_atk`: $14$, `salary`: $5$
- `shield_infantry_base_def`: $18$, `salary`: $6$
- `spearman_base_atk`: $12$, `salary`: $5$
- `archer_base_atk`: $16$, `salary`: $6$
- `heavy_infantry_base_atk`: $20$, `salary`: $10$
- `mercenary_salary`: $18$

---

### D. Hero Progression, Fatigue, Chemistry, & Deterministic Permadeath

#### 1. Core Mathematical Relations
- **Kurva Kebutuhan EXP**:
  $$EXP_{req}(L) = \left\lfloor 120 \times L^{1.55} \right\rfloor$$
- **Kekuatan Stat Hero**:
  $$Stat(L, S_{cur}) = BaseStat \times (1 + (L - 1) \times 0.12) \times (1 + (S_{cur} - 1) \times 0.20) \times Mod_{fatigue} \times Bonus_{chem}$$
- **Kelelahan (*Fatigue*, $F \in [0, 100]$)**:
  Bertambah $+15$ per pertempuran, pulih $-35$ saat istirahat.
- **Kimiawi Pasukan (*Party Chemistry*, $C_{chem}$)**:
  Bertambah $+2$ poin antar-hero aktif saat bertarung bersama (bonus $+0.5\%$ efektivitas per poin).
- **Model Kelangsungan Hidup & Kematian Hero Deterministik (Hero Survival & Death)**:
  Hero death TIDAK otomatis membunuh semua hero saat benteng runtuh, dan hero yang lelah dapat gugur pada breach parah.
  $$P_{death} = \text{clampf}\left(BaseDanger \times FatigueFactor \times DefFactor, 0.0, 0.85\right)$$
  - Jika benteng runtuh: $BaseDanger = 0.50 + 0.40 \times \text{clampf}(\frac{BreachThreat}{TB}, 0, 1)$ (tidak otomatis 100% mati).
  - Jika benteng bertahan: $BaseDanger = 0.05 + 0.35 \times \text{clampf}(\frac{BreachThreat}{TB}, 0, 1)$ jika ada breach.
  - $FatigueFactor = 1.0 + \frac{Fatigue}{100} \times 0.60$.
  - $DefFactor = \frac{80}{80 + EffectiveDef}$.
  - Hero yang gugur dinyatakan `is_alive = false`, keluar permanen dari pertempuran, tidak mendapat EXP, tidak pulih fatigue, dan tidak memberi chemistry (Permadeath mutlak).

---

### E. Equipment Durability, Loss & Degradation

#### 1. Core Mathematical Relations
- **Aus Rutin Pertempuran**: $\Delta D = 8 + \lfloor Severity \times 10 \rfloor$.
- **Kehilangan Perlengkapan Pasca-Korban (Casualty Equipment Loss)**:
  Saat prajurit gugur, perlengkapan yang dibawa dievaluasi secara seeded:
  - Peluang $35\%$: Perlengkapan hancur/hilang total (kuantitas di gudang berkurang 1).
  - Peluang $65\%$: Perlengkapan berhasil diselamatkan dalam kondisi rusak berat ($D = \max(0, D - 40)$).

---

### F. Fortress Durability & Fail Condition

- Absorpsi Kerusakan Armor:
  $$Reduction = \frac{Armor}{Armor + 150}$$
- Syarat Kalah Mutlak:
  $$HP_{fort} \le 0 \implies \mathbf{GAME\ OVER}$$

---

### G. Wave Threat Budget & Multi-Phase Combat

- **Anggaran Ancaman ($TB$)**:
  - Wave 1–5 (Anti-Spike Tutorial Ramp): $TB(W) = 25 + (W - 1) \times 15$.
  - Wave 6–100: $TB(W) = \lfloor 85 \times (W / 5)^{1.30} \times (1 \pm 0.06) \rfloor$.
- **Combat Multi-Fase**:
  - Fase 1: Ranged Volley (Archer memfilter Flyer & Minion).
  - Fase 2: Frontline Clash (Shield menahan benturan, Spear menusuk Brute).
  - Fase 3: Melee & Heroes (Swordsman, Heavy, Hero ATK/DEF, bonus chemistry).
  - Fase 4: Wall Breach (Sisa ancaman yang lolos menyerang tembok).
  - Fase 5: Resolusi Korban, Equipment Loss/Damage, Hero Survival, EXP, dan Battle Loot.

---

## 3. Catatan Pengujian Stabilitas 100 Gelombang

Simulasi 100 gelombang dijalankan dengan fixed seed `98765`:
- **Hasil**: 100 gelombang berhasil dieksekusi tanpa Game Over.
- **Kondisi Kas**: Stabil tanpa eksploit *infinite gold* (kas bergerak dari 112 gold di awal hingga 1.200 gold di wave 100).
- **Populasi**: Tumbuh stabil dari 18 hingga 471 warga tanpa kolaps demografi.
- **Disclaimer**: Simulasi ini adalah pengujian kestabilan sistem otomatis (*automated management policy test*), bukan bukti final bahwa balancing pemain manusia sudah sempurna.
