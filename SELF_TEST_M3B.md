# SELF TEST M3B / SHA-107 Integration

Scope: shop economy and growth backend from chapter 04, plus the SHA-107 full M3 item/weapon catalog integration used by the playable Danger 0 preview.

Covered:

- Shop tier probabilities and statistical distribution.
- Shop price, reroll price, HP-shop price, recycle value.
- Four-slot shop fill with early weapon guarantees, lock carryover, frozen lock price, paid/free rerolls.
- Item purchase effects, weapon buy-combine, weapon recycling.
- Level-up tier overrides, four unique choices, max-HP application, weapon-slot forced upgrade.
- Material pickup, consumable/drop/crate formulas, bonus gold repayment, harvesting settlement and growth.
- Full M3 catalog normalization for 209 imported items, 201 documented weapon variants, parsed effect storage methods, weapon family IDs, upgrade links, and runtime texture paths.
- Main-scene integration uses the M3 Well Rounded character, M3 Pistol I starter variant, M3-backed shop slots, `ShopState` purchases/rerolls, and `LevelUpPool` upgrades between M2 Danger 0 waves.

Verification command:

```powershell
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd
```
