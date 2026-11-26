# PHASE 3C — HERO EQUIPMENT FOUNDATION
## TECHNICAL SPECIFICATION & IMPLEMENTATION REPORT

**Document**: `docs/design/PHASE_3C_HERO_EQUIPMENT_PLAN.md`  
**Status**: `PHASE 3C — COMPLETED`  
**Project**: `fortress_game`  
**Repository**: `https://github.com/AchmadKing/fortress_game.git`  
**Branch**: `main`  
**Phase**: Phase 3 — Gameplay Prototype  
**Sub-Phase**: Phase 3C — Hero Equipment Foundation  
**Phase 4**: `LOCKED`  

---

## 1. Executive Summary

Phase 3C mengintegrasikan sistem perlengkapan Hero dengan gudang senjata bersama benteng (*Shared Fortress Warehouse*).
Sistem ini melengkapi model agregat serdadu sementara (Phase 3B) dengan kepemilikan perlengkapan persisten pada hero individual (*HeroModel*).

Prinsip fundamental:
1. **Shared Equipment Pool**: Tidak ada inventaris senjata terpisah untuk Hero. Hero dan regu prajurit mengambil perlengkapan dari gudang senjata yang sama (`_warehouse`).
2. **Persistent Loadout**: Perlengkapan hero bersifat persisten lintas gelombang (tetap terpasang setelah memenangkan pertempuran dan recovery), berbeda dari serdadu yang bersifat sementara (*temporary wave deployment*).
3. **Slot Equipment**:
   - `PRIMARY`: Wajib untuk hero tempur (`SWORD`, `SPEAR`, `BOW`). Memberikan pengali ATK.
   - `SECONDARY`: Opsional (`SHIELD`, dll.). Memberikan pengali DEF.
   - `ARMOR`: Opsional (`HEAVY_ARMOR`). Memberikan pengali DEF.
4. **Hero Permadeath Return**: Ketika seorang hero gugur secara permanen dalam pertempuran (`is_alive == false`), seluruh perlengkapan yang sedang terpasang pada hero tersebut otomatis dikembalikan ke gudang benteng tepat satu kali pada fase pemulihan (*Recovery*).
5. **Battle Lock**: Aksi equip, unequip, dan swap terkunci secara mutlak selama fase `BATTLE`.
6. **Strict Conservation Invariant**:
   $$\text{Warehouse Stock} + \text{Hero-held Equipment} + \text{Temporary Soldier Reservations} = \text{Total Owned Equipment}$$

---

## 2. Technical Implementation Architecture

### 2.1 Domain Model (`HeroModel`)
- Menambahkan slot:
  - `primary_equipment: RefCounted`
  - `secondary_equipment: RefCounted`
  - `armor_equipment: RefCounted`
- Metode slot:
  - `equip(slot, eq) -> RefCounted` (mengembalikan perlengkapan lama untuk transaksi atomik)
  - `unequip(slot) -> RefCounted`
  - `has_equipment(slot) -> bool`
  - `get_equipment(slot) -> RefCounted`
  - `get_equipped_items() -> Array`
  - `clear_equipment() -> Array` (membersihkan slot dan mengembalikan seluruh item saat permadeath)
- Skalasi stat tempur:
  - `get_effective_atk()` mengalikan `base_atk` dengan `primary_equipment.get_power_multiplier()`.
  - `get_effective_def()` mengalikan `base_def` dengan `armor_equipment.get_power_multiplier()` dan bonus sekunder shield.

### 2.2 Application Coordinator (`GameCoordinator`)
- API manajemen perlengkapan hero:
  - `equip_hero(hero_id, slot, eq_type) -> bool`
  - `unequip_hero(hero_id, slot) -> bool`
  - `swap_hero_equipment(hero_id, slot, new_eq_type) -> bool`
  - `get_hero(hero_id) -> HeroModel`
- Konservasi dan pemrosesan pasca-wave di `proceed_from_result()`:
  - Memeriksa pahlawan yang gugur (`not hero.is_alive`), memanggil `hero.clear_equipment()`, dan mengembalikan item ke `_warehouse`.
  - Pahlawan yang selamat mempertahankan perlengkapannya untuk gelombang berikutnya.
  - Perhitungan kepemilikan global di `get_total_owned_stock(eq_type)`.

### 2.3 Presentation Layer
- `GameController`: Dispatch methods `equip_hero`, `unequip_hero`, `swap_hero_equipment`.
- `PrototypeDebugView`: Menampilkan informasi gear terpasang (`[P, S, A]`) dan stat ATK/DEF riil pada kolom Hero Roster.

---

## 3. Test Verification & Results

Suite pengujian otomatis `tests/test_hero_equipment_foundation.gd` memvalidasi seluruh 22 skenario:
1. `test_hero_equips_primary` (PASS)
2. `test_hero_equips_secondary` (PASS)
3. `test_hero_equips_armor` (PASS)
4. `test_equipment_comes_from_shared_warehouse` (PASS)
5. `test_insufficient_warehouse_stock` (PASS)
6. `test_invalid_role_equipment_combination` (PASS)
7. `test_failed_equip_causes_no_mutation` (PASS)
8. `test_hero_unequip_returns_equipment` (PASS)
9. `test_hero_swap` (PASS)
10. `test_failed_swap_preserves_original_state` (PASS)
11. `test_hero_equipment_conflicts_with_soldier_reservation` (PASS)
12. `test_soldier_reservation_conflicts_with_hero_equipment` (PASS)
13. `test_hero_equipment_locked_during_battle` (PASS)
14. `test_hero_equipment_remains_after_surviving_wave` (PASS)
15. `test_hero_permadeath_returns_all_equipped_equipment` (PASS)
16. `test_equipment_is_returned_exactly_once` (PASS)
17. `test_shared_warehouse_conservation` (PASS)
18. `test_existing_hero_stats_exp_morale_chemistry_intact` (PASS)
19. `test_existing_phase1_regression` (PASS)
20. `test_existing_phase2_regression` (PASS)
21. `test_existing_phase3_regression` (PASS)
22. `test_phase3b_regression` (PASS)

Hasil akhir: **22/22 PASSED, 0 FAILED**.
Regression full suite: **86/86 PASSED, 0 FAILED**.
Smoke Playtest Scene: **ALL PASS, 0 ERRORS**.
