# SELF TEST M3

Manual sampling was done against the bundled design docs after running:

```powershell
python tools\import_m3_static_content.py
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd
```

## Count Checks

- Characters: `49` rows in `data/m3/characters.json`, matching doc 02.
- Weapons: `61` families, `244` quality slots, and `201` documented variant rows in `data/m3/weapons.json`, matching doc 03's table note and preserving undocumented quality slots explicitly.
- Items: `209` item data rows in `data/m3/items.json`, matching doc 05.

## Character Samples

| ID | Source | Manual check |
|---|---|---|
| `character_well_rounded` | doc 02 line 201 | Effects include +5 max HP, +5 speed, +8 harvesting; starting weapon list has 13 choices. |
| `character_brawler` | doc 02 line 212 | Includes Unarmed class bonus, extra `weapon_fist_1`, +15 dodge, -50 range, -50 ranged damage. |
| `character_mage` | doc 02 line 252 | Includes elemental gain +25%, starting items `item_snake` and `item_scared_sausage`, and negative melee/ranged/engineering gains. |
| `character_fisherman` | doc 02 line 769 | Includes `item_bait` shop guarantee, bait price modifier, upgraded bait flag, and -50% enemy material value. |
| `character_bull` | doc 02 line 800 | Includes max HP, regen, armor, `explode_on_hit` source payload, and weapon slot replacement to 0. |

## Weapon Samples

| ID | Source | Manual check |
|---|---|---|
| `weapon_pistol_1` | doc 03 line 629 | Tier I, value 10, damage 12x1, ranged scaling 1.0, 60 frame cooldown, 5% x2 crit, range 400, knockback 15, 90% accuracy, 1 pierce at 50%. |
| `weapon_wrench_4` | doc 03 line 583 | Tier IV, value 149, damage 24, melee scaling 1.0, 54 frame cooldown, range 175, knockback 20, deploys rocket turret. |
| `weapon_chain_gun_4` | doc 03 line 589 | Tier IV only, value 300, damage 2x3, ranged + engineering scaling, 2 frame cooldown with every 100 shots reload x60. |
| `weapon_crossbow_2` | doc 03 line 591 | Tier II, value 34, damage 12x1, ranged 0.5 + range 0.1 scaling, 35% x1.75 crit, +2 pierce on crit note. |
| `weapon_torch_3` | doc 03 line 575 | Tier III, value 45, melee + elemental scaling 0.8, 22 frame cooldown, burn data note plus burning spread +1. |

## Item Samples

| ID | Source | Manual check |
|---|---|---|
| `item_alien_tongue` | doc 05 line 102 | Tier I, value 25, default unlocked, tags `pickup` and `knockback`, effects parse pickup range and knockback. |
| `item_baby_elephant` | doc 05 line 104 | Tier I, value 22, tags `stat_luck` and `pickup`, raw trigger payload keeps luck damage text and tracking. |
| `item_coupon` | doc 05 line 118 | Tier I, max 5, tag `economy`, effect parses `items_price` -5. |
| `item_scared_sausage` | doc 05 line 149 | Tier I, max 4, tag `stat_elemental_damage`, raw burn payload keeps 25% burn chance text and tracking. |
| `item_acid` | doc 05 line 164 | Tier II, value 65, tag `stat_max_hp`, effects parse +8 max HP, -2 dodge, -2 knockback. |
| `item_bait` | doc 05 line 166 | Tier II, value 25, tags `stat_percent_damage` and `number_of_enemies`, effects parse +8 damage and preserve next-wave special enemy text. |
| `item_cyberball` | doc 05 line 180 | Tier II, value 30, tag `stat_luck`, raw death-trigger luck damage payload preserved with tracking. |
| `item_turret_rocket` | doc 05 line 324 | Tier IV, value 80, tags `stat_engineering` and `structure`, structure payload text preserved. |
| `item_hourglass` | doc 05 line 307 | Tier IV, value 100, max 1, unlocked by challenge, `replaced_by` points to `item_broken_hourglass`. |
| `item_potato` | doc 05 line 315 | Tier IV, value 95, default locked, tags include max HP, regen, damage, speed, and luck; all listed stat effects parse. |

## Notes

- Complex effects without enough serialized class fields in the docs are intentionally retained as `raw_effect_text` payloads with source text and source line traceability.
- Weapon quality slots that are not listed in doc 03 are represented as unavailable slots instead of inventing stats.
