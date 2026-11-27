# Fortress Main Screen — Low-Fi Wireframe

## Metadata

- **Name**: Fortress Main Screen — Low-Fi Wireframe (`Layar Utama — Benteng (Landscape)`)
- **Status**: Design Reference / Low-Fi Mockup (NOT Production Code)
- **Resolution**: 960 × 440
- **Orientation**: Landscape
- **Source Files**:
  - `Main.dc.html`: Visual artboard & layout component reference
  - `support.js`: Standalone browser viewer support logic
  - `vendor/react.js`, `vendor/react-dom.js`: Offline viewer dependencies

## Purpose

Dokumen dan file mockup ini adalah **design reference / low-fi mockup** resmi untuk struktur dan hierarki visual layar utama manajemen benteng (*Fortress Management Screen*). File ini diarsipkan di repository agar tidak hilang dan dapat dirujuk secara konsisten oleh Phase 5 hingga Phase 10.

> [!WARNING]
> **BUKAN KODE PRODUKSI**: File HTML, JavaScript, dan CSS dalam folder ini **BUKAN** kode runtime game. Dilarang mengimpor atau mengeksekusi HTML/React di dalam Godot Engine. Implementasi antarmuka pada game wajib dibangun ulang secara murni menggunakan native Godot UI nodes (`Control`, `VBoxContainer`, `HBoxContainer`, `PanelContainer`, dll.).

---

## Main Layout Structure

```text
┌─────────────────────────────────────────────┐
│ Sidebar │ Header                            │
├─────────┼──────────────────────┬────────────┤
│         │                      │            │
│ Sidebar │ Fortress / Map Area  │ Management │
│         │                      │ Panel      │
│         │                      │            │
├─────────┴──────────────────────┴────────────┤
│                 Bottom Action Bar            │
└─────────────────────────────────────────────┘
```

### Elemen Utama Antarmuka

1. **Left Sidebar**:
   - `Kembali`: Navigasi kembali / keluar
   - `Benteng`: Tab/layar utama kondisi benteng & pertahanan
   - `Bangun`: Fasilitas konstruksi & manajemen bangunan benteng
   - `Rakyat`: Manajemen populasi sipil dan alokasi pekerja
   - `Pasukan`: Manajemen serdadu benteng & komposisi penugasan tempur
   - `Riset`: Penelitian teknologi benteng (placeholder Phase 7+)
   - `Misi`: Quest dan penugasan luar benteng (placeholder Phase 8+)
   - `Atur`: Pengaturan game / audio / kontrol

2. **Header Bar**:
   - Icon benteng & Nama Benteng (`Benteng Utama`)
   - Label konteks lokasi / status (`Peta & Pertahanan`)
   - Kas Emas (`Gold` - bersumber dari kas bendahara kanonikal)
   - Jumlah Sipil (`Civilian` - bersumber dari populasi sipil kanonikal)
   - Indikator Waktu / Hari (`Hari / Waktu` placeholder)
   - Menu Cepat & Tombol `LANJUT`

3. **Center — Main Fortress / Map Area**:
   - Representasi visual benteng (*Fortress*), dinding pertahanan (*Wall*), gerbang (*Gate*), dan menara pertahanan (*Towers*)
   - Indikator arah pergerakan musuh (*Enemy Direction Reference*)
   - Panel status kondisi benteng: Durabilitas Benteng (Fortress HP), Durabilitas Tembok (Wall HP), Gerbang (Gate HP)
   - Status konstruksi & perbaikan aktif
   - Kontrol navigasi / zoom sederhana

4. **Right Management Panel**:
   - **Tab Deployed Unit**: Ringkasan komposisi regu prajurit yang ditugaskan (Phase 3)
   - **Tab Hero**: Integrasi data pahlawan kanonikal dari Phase 4 (Level, Bintang, Peran, Lifecycle, Regu, Moral, Fatigue)
   - **Tab Gudang Senjata**: Integrasi inventaris Shared Warehouse kanonikal (Senjata, Perisai, Zirah, Usable vs Damaged)

5. **Bottom Action Bar**:
   - Tombol `Start Battle`: Memulai pertempuran gelombang (**DISABLED** pada Phase 5; tanggung jawab Phase 6)
   - Tombol `Aksi`: Menu aksi kontekstual benteng (Perbaikan darurat, pergantian tugas, inspeksi)

---

## Important Gameplay Disclaimer

> [!IMPORTANT]
> **Wireframe is a visual reference only. Visual elements shown in the mockup do not automatically define gameplay mechanics or domain data.**

### Larangan Implementasi Spesifik:
1. **Level Serdadu (`Lv 0`)**: Mockup wireframe menampilkan label contoh visual seperti `Lv 0` pada unit serdadu. **DILARANG KERAS mengimplementasikan sistem level untuk serdadu.** Aturan desain kanonikal menetapkan:
   - Serdadu (*Soldier*) adalah **aggregate unit** tanpa level individu, tanpa skill tree, dan tanpa kepribadian (*personality*).
   - Hanya Pahlawan (*Hero*) yang memiliki level individual, peran, bakat, keahlian, dan progresi.
2. **Duplikasi Gudang Senjata**: Tab "Gudang Senjata" wajib merujuk langsung ke **Shared Warehouse** kanonikal tunggal dari Phase 3. Tidak boleh ada gudang sekunder atau duplikasi inventaris.
3. **Ekonomi**: Emas di header wajib membaca kas bendahara kanonikal `_economy.treasury_gold`. Tidak boleh membuat sistem ekonomi paralel.

---

## Phase Implementation Mapping

| Fase | Cakupan Implementasi Terkait Wireframe |
| :--- | :--- |
| **Phase 5** | - Pondasi layout Fortress Management UI functional prototype di Godot<br>- Integrasi data kondisi Benteng, Wall, Gate, dan HP<br>- Integrasi akuntansi Populasi (Civilian, Worker, Soldier)<br>- Integrasi manajemen Pekerja (Assignment 4 tugas sah) & Fasilitas Bangunan<br>- Integrasi display-only tab Hero (Phase 4) dan Shared Warehouse (Phase 3)<br>- Tombol `Start Battle` dinonaktifkan (disabled) |
| **Phase 6** | - Informasi pertempuran & gelombang monster aktif<br>- Visualisasi medan tempur (*Battlefield / Tactical Zone*)<br>- Fungsionalitas tombol `Start Battle`<br>- Perintah komandan taktis (*Commander Commands*) real-time<br>- Status & pergerakan AI musuh |
| **Phase 7** | - Integrasi ekonomi komprehensif, riset benteng, dan progresi jangka panjang |
| **Phase 8** | - Konten misi, variasi monster, dan ekspansi naratif |
| **Phase 9** | - Visual styling pixel-art final, paket ikon kustom, shader visual, animasi gerak, dan pemolesan UI mobile responsif |
| **Phase 10** | - Sistem Save/Load persisten, optimalisasi performa ekstrem, dan rilis final |

---

## Offline Viewing Instructions

Untuk membuka dan melihat mockup visual wireframe di browser secara offline:
1. Jalankan web server lokal sederhana pada folder ini:
   ```bash
   python -m http.server 8000
   ```
2. Buka peramban pada alamat:
   ```text
   http://localhost:8000/Main.dc.html
   ```
