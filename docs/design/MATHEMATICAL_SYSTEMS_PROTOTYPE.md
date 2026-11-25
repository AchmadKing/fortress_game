# Mathematical & Systems Prototype Design — Fortress Game

**Status**: PLANNING & ARCHITECTURAL DESIGN (PHASE 2)  
**Tujuan**: Memvalidasi model matematika, keseimbangan loop ekonomi, manpower, perkembangan hero, daya tahan benteng, dan kurva ancaman (*threat curve*) sebelum implementasi gameplay visual.  
**Prinsip Utama**: *Mathematical validation first. Code implementation later.*

> [!IMPORTANT]
> Dokumen ini adalah rancangan model matematika abstrak dan simulasi sistem (**PLANNING ONLY**). **TIDAK ADA** kode gameplay, combat engine real-time, kontrol visual, enemy AI, scene, maupun aset grafis yang dibuat pada tahap ini.

---

## 1. Executive Summary & Core Objective

Dalam game *Pixel-Art Fantasy Fortress Management / Strategy Simulation*, stabilitas game loop ditentukan oleh interaksi antara lima pilar utama:
1. **Demografi & Manpower**: Keseimbangan antara pekerja produktif (penghasil sumber daya) dan serdadu (konsumen sumber daya/pelindung benteng).
2. **Ekonomi Sirkular**: Arus masuk emas/material versus biaya pemeliharaan (*upkeep*), perbaikan (*repair*), dan penggantian korban (*replacement*).
3. **Progresi Hero & Pasukan**: Peningkatan kekuatan terukur tanpa memicu *snowballing* tak terkendali.
4. **Integritas Benteng**: Ketahanan benteng sebagai batas akhir pertahanan (*fail condition* mutlak: $HP_{fortress} \le 0 \implies \text{Game Over}$).
5. **Kurva Ancaman Gelombang (*Wave Threat Budget*)**: Peningkatan tantangan yang terprediksi, adil (*no unfair spikes*), dan dinamis sepanjang 100 gelombang.

---

## 2. Model Sistem & Formulasi Matematika

### A. Population & Manpower Model

Populasi total ($P_{total}$) adalah sumber daya terbatas (*scarce finite resource*) yang menjadi pondasi seluruh aktivitas benteng.

```text
               ┌───────────────────────────────┐
               │    Total Population (P_total) │
               └───────────────┬───────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
┌────────────────────────┐             ┌────────────────────────┐
│ Civilian / Worker (P_w)│             │      Soldier (P_s)     │
│ (Produces Gold / Food) │             │  (Consumes Gold/Defends)│
└────────────────────────┘             └────────────────────────┘
```

#### 1. Pembagian Populasi
$$P_{total} = P_w + P_s + P_h$$

- $P_w$: Pekerja / warga sipil (*Civilian Workers*).
- $P_s$: Pasukan reguler (*Garrison Soldiers*).
- $P_h$: Pahlawan terdaftar (*Heroes*, kuantitas kecil: $1 \le P_h \le 6$).

#### 2. Rekrutmen & Konversi
- Merekrut 1 serdadu mengurangi 1 pekerja sipil:
  $$\Delta P_s = +k \implies \Delta P_w = -k$$
  *(Konsekuensi langsung: Memperkuat militer langsung memangkas kapasitas produksi ekonomi).*
- **Tentara Bayaran (*Mercenaries*, $M_{merc}$)**: Pasukan tambahan yang disewa dengan biaya emas tinggi tanpa mengambil jatah populasi warga ($M_{merc} \notin P_{total}$).

#### 3. Pertumbuhan Alami & Korban
- **Kapasitas Hunian ($C_{pop}$)**: Batas maksimum populasi yang dapat ditampung benteng.
- **Laju Pertumbuhan Alami**:
  $$\text{Growth}_{pop} = \max\left(0, \left\lfloor r_{growth} \times (C_{pop} - P_{total}) \times \frac{M_{morale}}{100} \right\rfloor\right)$$
- **Kematian Prajurit**: Prajurit yang gugur dalam pertempuran ($C_{sol}$) mengurangi $P_s$ dan mengurangi $P_{total}$ secara permanen sampai adanya regenerasi alami atau pengungsi baru:
  $$P_{total}^{t+1} = P_{total}^t - C_{sol} + \text{Growth}_{pop}$$

---

### B. Worker Economy Model

Pekerja sipil menghasilkan pendapatan per siklus/wave untuk mendanai pemeliharaan benteng dan pasukan.

#### 1. Pendapatan Kotor (*Gross Income*)
$$Income_{gross} = P_w \times Output_{base} \times \left( \frac{Morale_w}{100} \right) \times TechMod$$

- $Output_{base}$: Pendapatan dasar per pekerja (Default: 10 Gold per wave).
- $Morale_w$: Moral warga sipil ($0 \le Morale_w \le 150$, normal = 100).
- $TechMod$: Pengali dari level upgrade fasilitas ekonomi benteng.

#### 2. Biaya Pemeliharaan Pekerja (*Worker Upkeep*)
$$Expense_w = P_w \times Salary_w$$

- $Salary_w$: Gaji/kebutuhan pangan minimum per pekerja (Default: 3 Gold per wave).

#### 3. Pendapatan Bersih Pekerja (*Net Worker Profit*)
$$Profit_w = Income_{gross} - Expense_w$$
*(Pada kondisi normal dengan moral 100%: $Profit_w = P_w \times (10 - 3) = +7 \text{ Gold/pekerja/wave}$).*

---

### C. Soldier System (Aggregate Group-Level)

Pasukan militer dimodelkan secara agregat (kelompok), bukan simulasi individu per prajurit, demi performa ringan pada platform mobile.

#### 1. Kekuatan Tempur Pasukan (*Army Power, $AP$*)
$$AP = P_s \times BasePower_s \times \left(1 + \frac{EquipBonus}{100}\right) \times \left(\frac{Morale_s}{100}\right)$$

- $BasePower_s$: Kekuatan dasar per prajurit (Default: 12).
- $EquipBonus$: Bonus dari tier perlengkapan aktif prajurit.
- $Morale_s$: Moral militer ($50 \le Morale_s \le 150$).

#### 2. Biaya Pasukan (*Soldier Upkeep*)
$$Expense_s = P_s \times Salary_s$$

- $Salary_s$: Biaya gaji & ransum prajurit (Default: 8 Gold per prajurit/wave).
*(Perhatikan rasio ekonomi: 1 prajurit membutuhkan surplus dari setidaknya $1.15$ pekerja untuk menutupi gaji).*

---

### D. Hero Progression Model

Hero adalah unit komandan unik berkekuatan tinggi yang memimpin pertahanan.

#### 1. Kurva EXP Naik Level
Kebutuhan EXP untuk naik dari level $L$ ke level $L+1$:
$$EXP_{req}(L) = \left\lfloor BaseEXP \times L^{1.6} \right\rfloor$$
- $BaseEXP = 100$.
- Contoh progresi:
  - Level 1 $\to$ 2: $100$ EXP
  - Level 5 $\to$ 6: $542$ EXP
  - Level 10 $\to$ 11: $1.584$ EXP
  - Level 20 $\to$ 21: $4.811$ EXP
  - Level 50 (Max): $20.000+$ EXP (Pencegahan *over-leveling* dini).

#### 2. Kekuatan Tempur Hero (*Hero Power, $HPW$*)
$$HPW = BaseHeroPower \times \left(1 + (L - 1) \times 0.15\right) \times \left(1 + (Star_{cur} - 1) \times 0.25\right) \times \left(\frac{100 - Fatigue}{100}\right)$$

- $Star_{cur}$: Peringkat bintang hero ($1 \le Star_{cur} \le Star_{pot}$).
- $Fatigue$: Kelelahan hero ($0 \le Fatigue \le 60$). Bertambah $+15$ per pertempuran, pulih $-20$ jika diistirahatkan/rotasi 1 wave.

---

### E. Equipment & Durability Model

Perlengkapan memberikan pengganda kekuatan tetapi mengalami keausan (*durability decay*) setiap pertempuran.

#### 1. Tier Perlengkapan & Kekuatan
| Tier | Nama Tier | Bonus Kekuatan ($EquipBonus$) | Biaya Beli Dasar |
| :---: | :--- | :---: | :---: |
| **T1** | Rusted Iron | $+15\%$ | $50\text{ Gold}$ |
| **T2** | Forged Steel | $+35\%$ | $140\text{ Gold}$ |
| **T3** | Knight's Alloy | $+65\%$ | $350\text{ Gold}$ |
| **T4** | Mithril Weave | $+105\%$ | $850\text{ Gold}$ |
| **T5** | Ancient Runed | $+160\%$ | $2.000\text{ Gold}$ |

#### 2. Keausan (*Durability*) & Biaya Reparasi
- Durabilitas maksimal: $D_{max} = 100$.
- Penurunan durabilitas per pertempuran berat: $\Delta D = 8 \sim 15$.
- **Biaya Perbaikan**:
  $$Cost_{repair} = \lceil (D_{max} - D_{current}) \times RepairRate_{tier} \rceil$$
- Jika $D_{current} = 0$, perlengkapan rusak (*broken*) dan bonusnya turun menjadi $0\%$ hingga diperbaiki.

---

### F. Fortress Durability & Structural Defense

Benteng adalah struktur pertahanan inti dan syarat kelangsungan permainan (*survival core*).

#### 1. Integritas Struktural ($HP_{fort}$)
- $HP_{max}$: Dimulai dari $1.000$, dapat di-upgrade bertahap via fasilitas benteng hingga $15.000$ di wave 100.
- **Kondisi Kalah Mutlak**:
  $$HP_{fort} \le 0 \implies \mathbf{GAME\ OVER}$$

#### 2. Kerusakan Tembok (*Breach Damage*)
Kerusakan pada benteng terjadi saat kekuatan pertahanan (*Total Defense Power*) gagal menahan gelombang musuh secara sempurna:
$$Dmg_{received} = \max\left(0, \left\lfloor (Threat_{residual}) \times (1 - FortressArmorPct) \right\rfloor\right)$$

#### 3. Reparasi Benteng Pasca-Gelombang
- Pekerja dapat ditugaskan untuk memperbaiki benteng ($W_{repair} \subseteq P_w$).
- Kapasitas perbaikan per siklus:
  $$RepairedHP = \min\left(HP_{max} - HP_{fort}, W_{repair} \times RepairPerWorker\right)$$
- Biaya material/emas reparasi:
  $$Cost_{fort\_repair} = RepairedHP \times CostPerHP$$
  *(Default: 1 Gold per 5 HP yang diperbaiki).*

---

### G. Wave Threat Budget System

Untuk mencegah lonjakan kesulitan yang tidak adil (*unfair difficulty spikes*), musuh digenerasikan menggunakan sistem **Threat Budget ($TB$)**.

#### 1. Formula Anggaran Ancaman Wave $W$
Untuk gelombang $1 \le W \le 100$:
- **Wave 1–5 (Early Tutorial Ramp)**:
  $$TB(W) = 20 + (W - 1) \times 15$$
  *(Wave 1 = 20 TB, Wave 2 = 35 TB, ..., Wave 5 = 80 TB)*.
- **Wave 6–100 (Standard Scaling Curve)**:
  $$TB(W) = 80 \times \left( \frac{W}{5} \right)^{1.32}$$

*(Kurva eksponensial halus $1.32$ memberikan tantangan yang meningkat progresif tanpa lonjakan vertikal tiba-tiba).*

#### 2. Kategori Musuh & Biaya Threat
| Kategori Musuh | Bobot Biaya ($Cost_{tb}$) | Karakteristik Peran | Syarat Minimum Wave |
| :--- | :---: | :--- | :---: |
| **Goblin Scout / Minion** | $2\text{ TB}$ | Kuantitas banyak, swarm | Wave 1+ |
| **Orc Raider** | $6\text{ TB}$ | Pejuang lini depan reguler | Wave 3+ |
| **Armored Brute** | $18\text{ TB}$ | Bertahan tinggi, penahan damage | Wave 8+ |
| **Catapult / Siege Engine** | $45\text{ TB}$ | Memberikan damage langsung ke benteng | Wave 15+ |
| **Elite Warlord / Boss** | $120+\text{ TB}$ | Komandan ancaman masif | Wave 10, 20, 30... |

#### 3. Kontrol Randomisasi
Setiap gelombang dialokasikan variasi acak terkendali sebesar $\pm 7\%$:
$$TB_{actual} = TB(W) \times (1 + \text{rand}(-0.07, +0.07))$$
Ini menjamin variabilitas antar-permainan tanpa merusak batas aman kalkulasi.

---

### H. Combat Abstraction Model (Headless & Deterministic)

Pertempuran diabstraksikan murni menjadi kalkulasi matematis tanpa visualisasi frame-by-frame:

```text
[Input Data Pertempuran]
  - Army Power (AP)
  - Hero Power (HPW)
  - Fortress Defensive Modifier
  - Wave Actual Threat (TB_actual)
  - Tactical Stance Modifier (e.g. Defensive, Balanced, Aggressive)
              │
              ▼
    [Combat Calculator]
              │
              ▼
[Output Hasil Simulasi]
  - Victory Status (True / False)
  - Power Margin Ratio (R_power)
  - Soldier Casualties (C_sol)
  - Fortress Damage Taken (Dmg_fort)
  - Loot Generated (Gold, Materials)
  - Hero EXP Earned
  - Morale Delta
```

#### 1. Rasio Kekuatan (*Power Ratio, $R_p$*)
$$TotalDefPower = (AP + HPW) \times TacticalMod_{def}$$
$$R_p = \frac{TotalDefPower}{TB_{actual}}$$

#### 2. Resolusi Kemenangan & Kerusakan
- **Kemenangan Sempurna (*Decisive Victory*, $R_p \ge 1.35$)**:
  - Musuh dihancurkan total di luar jangkauan benteng.
  - Korban prajurit: $C_{sol} = \lfloor P_s \times 0.02 \rfloor$ (minimal).
  - Kerusakan benteng: $Dmg_{fort} = 0$.
  - Bonus Moral: $+5$.
- **Kemenangan Rata-Rata (*Pyhrric Victory*, $1.00 \le R_p < 1.35$)**:
  - Musuh berhasil ditekan namun mencapai perimeter.
  - Korban prajurit: $C_{sol} = \lfloor P_s \times (0.18 - 0.10 \times (R_p - 1.0)) \rfloor$.
  - Kerusakan benteng: $Dmg_{fort} = \lfloor TB_{actual} \times (1.35 - R_p) \times 0.15 \rfloor$.
- **Kekalahan / Tembok Ditembus (*Defeat / Breach*, $R_p < 1.00$)**:
  - Pasukan bertahan dipukul mundur ke dalam benteng.
  - Korban prajurit: $C_{sol} = \lfloor P_s \times \min(0.50, 0.25 + 0.25 \times (1.0 - R_p)) \rfloor$.
  - Kerusakan benteng besar:
    $$Dmg_{fort} = \lfloor (TB_{actual} - TotalDefPower) \times 1.25 \rfloor$$
  - Penurunan Moral: $-15$.

---

## 3. Analisis Loop Ekonomi & Stabilitas

Loop ekonomi satu gelombang dirumuskan sebagai:

$$\Delta Gold_{net} = \underbrace{(Profit_w + Loot_{wave})}_{\text{Pemasukan}} - \underbrace{(Expense_s + Cost_{repair} + Cost_{recruit})}_{\text{Pengeluaran}}$$

```text
       ┌────────────────────────┐
       │   Wave Victory & Loot  │
       └───────────┬────────────┘
                   │ + Gold / Drops
                   ▼
       ┌────────────────────────┐
       │     Treasury Pool      │
       └───────────┬────────────┘
                   │
    ┌──────────────┼──────────────┬──────────────┐
    ▼              ▼              ▼              ▼
Soldier        Fortress       Hero & Eq      Worker
Upkeep          Repair         Upgrade       Upkeep
```

### Mekanisme Pencegahan Kegagalan Sistemik:

1. **Anti-Snowball (Pencegahan Pemain Terlalu Kaya)**:
   - Upkeep prajurit tier tinggi meningkat non-linear ($S_{sol}$ naik bertahap seiring bertambahnya ukuran pasukan).
   - Pajak logistik benteng (*Logistics Decay*): Jika kas emas melebihi batas simpanan aman, biaya perawatan benteng meningkat $+5\%$.
2. **Anti-Death Spiral (Pencegahan Kemiskinan Permanen)**:
   - **Bantuan Pengungsi Darurat (*Emergency Militia*)**: Jika prajurit $P_s \le 2$ dan kas emas $< 20$, benteng secara otomatis menerima 3 warga milisi gratis (*Town Watch*) dengan kekuatan dasar untuk mencegah kemacetan total.
   - **Batas Minimum Pendapatan**: Benteng selalu memiliki pendapatan dasar pasif dari perburuan sekitar sebesar minimal $15\text{ Gold/wave}$ meskipun seluruh pekerja sipil tewas.

---

## 4. Model Progresi 100 Gelombang (100-Wave Progression Model)

Tabel berikut menunjukkan proyeksi matematis acuan pada tonggak gelombang utama (*milestones*):

| Wave ($W$) | Threat Budget ($TB$) | Target Total Defense Power | Estimasi Populasi ($P_{total}$) | Prajurit ($P_s$) | Pekerja ($P_w$) | Net Gold Surplus/Wave | Status Benteng ($HP_{max}$) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | $20$ | $30$ | $15$ | $3$ | $12$ | $+60\text{ Gold}$ | $1.000$ |
| **5** | $80$ | $110$ | $22$ | $6$ | $15$ | $+85\text{ Gold}$ | $1.200$ |
| **10** | $201$ | $260$ | $32$ | $10$ | $20$ | $+115\text{ Gold}$ | $1.600$ |
| **20** | $504$ | $650$ | $50$ | $18$ | $29$ | $+180\text{ Gold}$ | $2.500$ |
| **35** | $1.050$ | $1.350$ | $80$ | $30$ | $46$ | $+290\text{ Gold}$ | $4.000$ |
| **50** | $1.860$ | $2.400$ | $120$ | $45$ | $70$ | $+420\text{ Gold}$ | $6.500$ |
| **75** | $3.350$ | $4.200$ | $180$ | $68$ | $106$ | $+610\text{ Gold}$ | $10.000$ |
| **100** | $5.180$ | $6.500$ | $250$ | $95$ | $148$ | $+850\text{ Gold}$ | $15.000$ |

---

## 5. Uji Skenario Stres Matematika (*Scenario Stress Testing*)

Untuk memastikan rancangan tidak rapuh, 5 skenario ekstrem diuji secara teoritis:

### Skenario A — Healthy Run (Pemain Ahli / Optimal)
- Karakteristik: Pemain mempertahankan rasio $P_w : P_s \approx 2 : 1$, rutin memperbaiki equipment, dan menjaga fatigue hero $< 20$.
- Hasil: $R_p$ stabil di kisaran $1.20 \sim 1.45$. Kas emas tumbuh sehat dengan surplus akumulatif, memungkinkan investasi upgrade fasilitas tanpa penundaan.

### Skenario B — Average Run (Pemain Normal / Standar)
- Karakteristik: Pemain terkadang terlambat upgrade, $R_p$ berfluktuasi antara $1.00 \sim 1.15$, menderita korban prajurit $5 \sim 10\%$ per wave berat.
- Hasil: Pertumbuhan kas moderat. Pemain harus memilih antara merekrut kembali serdadu yang gugur atau membeli tier senjata baru. Loop bertahan stabil tanpa crash ekonomi.

### Skenario C — Poor Management (Pemain Salah Alokasi Sumber Daya)
- Karakteristik: Pemain merekrut serdadu terlalu banyak ($P_s > P_w$) sehingga kas tertekan upkeep militer, atau mengabaikan durabilitas senjata.
- Hasil: Kas emas defisit sementara. Namun berkat *Militia Fallback* dan pendapatan dasar benteng, pemain dapat memotong jumlah pasukan atau membiarkan prajurit kembali menjadi pekerja sipil untuk memulihkan ekonomi dalam $2 \sim 3$ gelombang.

### Skenario D — Heavy Casualties (Satu Gelombang Sangat Buruk)
- Karakteristik: Pada wave boss (misal Wave 30), pemain salah taktik sehingga kehilangan $40\%$ pasukan ($C_{sol} = 10$).
- Hasil: Karena populasi dasar pekerja ($P_w$) tetap utuh, kapasitas penghasil emas tidak runtuh. Pemain menggunakan surplus emas untuk merekrut kembali prajurit dalam tempo 2 gelombang. **Terbukti: 1 kekalahan pertempuran tidak memicu game over instan.**

### Skenario E — Heavy Fortress Damage (Benteng Hampir Runtuh)
- Karakteristik: Benteng menderita $80\%$ damage ($HP_{fort}$ tersisa $200 / 1.000$).
- Hasil: Pemain menugaskan $50\%$ pekerja menjadi tim reparasi ($W_{repair}$). Benteng pulih $35\%$ HP per wave dengan biaya $70\text{ Gold}$. Dalam 3 wave damai/normal, integritas benteng kembali ke atas $80\%$.

---

## 6. Master Formula & Parameter Tuning Table

### 1. Tabel Formula Utama (*Master Formula Table*)

| Variabel | Rumus Matematika | Input Data | Output Data | Fungsi / Tujuan |
| :--- | :--- | :--- | :--- | :--- |
| **Threat Budget** | $TB(W) = 80 \times (W / 5)^{1.32}$ | Wave $W$ | Angka Ancaman ($TB$) | Menentukan kuota total kekuatan musuh per wave |
| **Worker Net Income** | $P_w \times (O_{base} \times M_w/100 - S_w)$ | $P_w, Morale, Salary$ | Emas bersih | Sumber daya utama kas benteng |
| **Army Power** | $P_s \times BasePow \times EquipMod \times MoraleMod$ | Prajurit, Gear, Moral | Angka Pertahanan | Daya tangkal utama terhadap gelombang musuh |
| **Hero Power** | $Base \times (1 + 0.15(L-1)) \times StarMod \times FatigueMod$ | Level, Bintang, Fatigue | Daya Pukul Hero | Kontributor kekuatan berkualitas tinggi |
| **Hero EXP Req** | $\lfloor 100 \times L^{1.6} \rfloor$ | Level $L$ | Kebutuhan EXP | Kurva progresi leveling terukur |
| **Combat Margin** | $R_p = (AP + HPW) / TB_{actual}$ | Total Power vs Threat | Rasio Desimal | Menentukan kemenangan, korban, dan damage tembok |
| **Fortress Damage** | $\max(0, \lfloor (TB - TotalPower) \times 1.25 \rfloor)$ | Selisih daya jebol | Pengurangan $HP_{fort}$ | Mengurangi HP benteng jika pertahanan kalah |

---

### 2. Parameter Tuning (*Adjustable Parameters vs Core Formulas*)

Untuk mempermudah developer melakukan penyesuaian *game feel* melalui konfigurasi tanpa mengubah rumus logika:

```ini
[Population_Balance]
base_growth_rate = 0.05
refugee_chance = 0.15
default_housing_cap = 25

[Economy_Balance]
worker_base_output = 10
worker_salary = 3
soldier_salary = 8
fortress_base_passive_income = 15

[Combat_Balance]
soldier_base_power = 12
decisive_victory_ratio = 1.35
breach_damage_multiplier = 1.25
hero_fatigue_per_battle = 15
hero_fatigue_recovery_rate = 20

[Wave_Balance]
wave_threat_exponent = 1.32
wave_random_variance = 0.07
```

---

## 7. Status Pengawasan Batasan Gameplay

Sesuai aturan `AGENTS.md` dan batas kerja Phase 2:
- ❌ **TIDAK ADA** skrip pertempuran real-time
- ❌ **TIDAK ADA** enemy spawner atau AI pergerakan monster
- ❌ **TIDAK ADA** UI gameplay, HUD, tombol rekrutmen interaktif
- ❌ **TIDAK ADA** scene visual gameplay atau arena pertarungan
- ❌ **TIDAK ADA** aset pixel art atau animasi

---

> **STATUS: PHASE 2 PLANNING COMPLETED & AWAITING DEVELOPER REVIEW**  
> Seluruh model sistem dan formula matematika telah dirancang. Antigravity berhenti dan menunggu evaluasi developer sebelum melangkah ke implementasi prototype matematika.
