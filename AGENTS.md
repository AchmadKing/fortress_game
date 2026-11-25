# Development Rules & Workflow for Antigravity AI

Dokumen ini adalah aturan kerja utama (Operational Rules) untuk Antigravity AI dalam proyek **fortress_game**. Semua instruksi dan kontribusi kode wajib mematuhi aturan di bawah ini.

---

## 1. Inspect Before Modify
Sebelum mengubah atau membuat file:
- Selalu inspect file terkait terlebih dahulu.
- Pahami struktur existing dan dependensinya.
- Jangan pernah melakukan perubahan berdasarkan asumsi.

## 2. Extend, Don't Break
- Jangan merusak sistem yang sudah ada (existing system).
- Jika ada sistem existing yang perlu diubah:
  - Jelaskan alasan perubahan kepada developer.
  - Identifikasi dampak (impact analysis).
  - Gunakan cakupan perubahan sekecil mungkin.
  - Pastikan backward compatibility tetap terjaga.

## 3. Approval Gate
- Developer memegang kendali dan keputusan akhir.
- Jangan pernah berpindah ke fase berikutnya tanpa persetujuan eksplisit (explicit approval).
- Keberadaan file roadmap atau dokumen rencana **bukan** merupakan approval untuk mulai eksekusi.

## 4. Plan Before Implementation
Untuk setiap pekerjaan yang signifikan:
1. **Inspect**: Periksa kondisi dan dependensi saat ini.
2. **Propose Plan**: Ajukan rencana kerja dan rancangan teknis.
3. **Developer Review**: Berikan kesempatan developer meninjau.
4. **Approval**: Tunggu izin eksplisit dari developer.
5. **Implementation**: Terapkan perubahan sesuai rencana yang disetujui.
6. **Verification**: Verifikasi hasil kerja dan laporkan status.

## 5. No Scope Creep
- Kerjakan hanya apa yang diminta secara eksplisit.
- Jangan menambahkan fitur spekulatif atau sistem tambahan hanya karena dianggap "akan berguna nanti".
- Pertahankan solusi tetap sederhana, modular, dan terfokus.

## 6. Godot Responsibility
Pembagian tanggung jawab teknis:
- **Antigravity**:
  - Arsitektur sistem & arsitektur script
  - Penulisan skrip (`.gd`)
  - Logika sistem (`systems/`)
  - Struktur scene dan konfigurasi node (`.tscn`)
  - Konfigurasi proyek (`project.godot`)
  - Implementasi teknis & unit test
- **Developer (via Godot Editor GUI)**:
  - Visual inspection & layout visual
  - Penyesuaian animasi & kurva pergerakan
  - Penyesuaian particle & shader visual
  - Visual tuning & styling
  - Playtesting & evaluasi feel permainan

*Catatan: Pembagian peran ini bukan alasan bagi AI untuk membuat fitur gameplay di luar approval.*

## 7. Lightweight Development
- Proyek ini menargetkan hardware development yang terbatas dan platform mobile (Android).
- Utamakan efisiensi performa, memori, dan ukuran file.
- Hindari dependensi pihak ketiga, plugin berat, atau aset yang tidak perlu tanpa justifikasi yang jelas.

## 8. Documentation
- Dokumentasi teknis harus mencerminkan keputusan yang telah disepakati dan diimplementasikan.
- Jangan mencatat desain atau arsitektur sebagai "final" jika belum disetujui developer.
- Perbarui `plans/CHANGELOG.md` dan `plans/CURRENT_PHASE.md` setiap kali ada milestone selesai.

## 9. Do Not Start Game Development During Setup
Selama **Phase 0**, DILARANG KERAS mengimplementasikan:
- Combat system & battle simulation
- Wave system & enemy spawners
- Hero, soldier, atau worker system
- Ekonomi, resource, & currency
- Monster AI & behavioral trees
- Fortress gameplay logic & upgrade interaction
- Story, lore, & quests
- Progression & leveling formulas
- Pixel art & aset gameplay final
- Gameplay UI & HUD elements
