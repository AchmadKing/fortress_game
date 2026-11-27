# Wireframe Index

Dokumen ini adalah indeks katalog resmi dari seluruh artefak wireframe dan desain referensi (*Design References*) untuk proyek **fortress_game**.

---

## 1. Fortress Main Screen (Layar Utama Benteng)

- **Path**: [`docs/design/wireframes/fortress-main-screen/`](file:///d:/fortress_game/docs/design/wireframes/fortress-main-screen/)
- **Status**: Design Reference / Low-Fi Mockup
- **Resolution**: 960 × 440
- **Orientation**: Landscape
- **Primary Usage**: Phase 5 – Phase 9
- **Description**:
  Desain referensi tata letak (*layout*) beresolusi 960×440 lanskap untuk layar utama manajemen benteng (*Fortress Management Screen*). Mengatur pembagian wilayah visual antara Left Sidebar, Header Bar, Main Fortress/Map Center, Right Management Panel (Tabs), dan Bottom Action Bar.
- **Implementation Rule**:
  Desain ini diimplementasikan ulang secara murni menggunakan native Godot UI controls (`Control`, `VBoxContainer`, `HBoxContainer`, `PanelContainer`, dll.). Dilarang mengimpor atau mengeksekusi file HTML/React di dalam Godot runtime.
- **Important Disclaimer**:
  Wireframe ini adalah panduan tata letak visual, bukan spesifikasi mekanik domain game. Elemen contoh seperti label `Lv 0` pada prajurit tidak boleh diadopsi sebagai mekanik game (serdadu tetap merupakan aggregate unit tanpa individual level).

---

## Indeks Penambahan Masa Depan

Seluruh wireframe baru yang diberikan developer untuk fase mendatang (misal: Layar Pertempuran Taktis Phase 6, Pohon Riset Phase 7, dsb.) wajib dicatat dan diarsipkan pada folder `docs/design/wireframes/<nama-layar>/` serta didaftarkan ke indeks ini sebelum implementasi.
