# QA Doc Coverage Matrix

This matrix is the SHA-104 audit surface for SHA-91. The only specification source is
`devkit/brotato_original_devkit/`. Status values are intentionally conservative:

- Implemented: code/data/tests exist in this repository.
- Partial: a verifiable slice exists, but the full document section is not complete.
- Pending: assigned to a child issue or later milestone.
- Ambiguous: blocked by `OPEN_QUESTIONS.md`; the current handling must remain conservative.

## Source Coverage

| Source | Status | Current code/data/test coverage | Preview coverage | Owner / next check |
| --- | --- | --- | --- | --- |
| DOC-01 core stats and formulas | Partial | `src/core/player_data.gd`, `src/core/formulas.gd`, M1/M2 tests cover stat layers, caps, speed, dodge, XP, armor, regen, lifesteal, harvest, pickup math | Demo uses player speed, materials, XP helpers indirectly | SHA-104 keeps formula tests; M3/M6 must add full item/character/stat consumers |
| DOC-02 character system | Pending | No full 49-character data import yet | Not exposed | SHA-101 imports data and tests 5 character audits |
| DOC-03 weapon system | Partial | `src/combat/weapon_stats.gd`, `data/m2/starter_weapons.json`, M2 tests cover starter weapon damage/cooldown/range/crit/projectile lifetime | Demo starts with Pistol I | SHA-98 owns attack runtime, all weapon behaviors, and remaining 61x4 data hooks |
| DOC-04 shop economy and upgrades | Partial | `src/core/formulas.gd` tests shop tier chance and reroll price | Not exposed | SHA-99 owns shop runtime, locking, recycling, combining, upgrades |
| DOC-05 item catalog | Pending | Effect storage and stat pipeline can receive item effects; no 209-item import yet | Not exposed | SHA-101 imports item data; SHA-99 validates shop/item flow |
| DOC-06 enemies and entities | Partial | `src/combat/enemy_stats.gd`, `data/m2/area1_enemies.json`, M2 tests cover starter enemy scaling and instantiation | Demo spawns first enemy slice | SHA-102 owns complete area 1 enemy data and 20-wave runtime |
| DOC-07 waves, danger, spawning | Partial, Ambiguous | `src/combat/wave_scheduler.gd`, `data/m2/area1_waves.json`, M2 tests cover warning timer, queue cadence, caps, culls, spawn count | Demo uses wave 1-5 slice | SHA-102 owns full Danger 0 20-wave table; see OQ-002/OQ-003/OQ-004 |
| DOC-08 effect system | Partial | `src/core/effect_keys.gd`, `src/core/effect_entry.gd`, `src/core/player_data.gd`, M1 tests cover 234 keys and 5 storage methods | Indirect data layer only | SHA-101/SHA-99 must add event hook consumers for real items and characters |
| DOC-09 progression, challenges, coop | Pending | Endless factor formula exists; no save/challenge/coop runtime yet | Not exposed | SHA-106 owns saves, unlocks, danger 1-5, endless, local coop |
| DOC-10 input and feel | Partial | Tests cover instant speed formula, targeting range, pickup radius/flight, iframe timing | Demo supports movement/auto-target slice | SHA-100 owns damage loop, knockback, wave transitions; SHA-105 owns full input UI focus |
| DOC-11 UI flow and HUD | Pending | Fallback `docs/index.html` only; no game UI flow implementation | Preview loads exported Godot shell after deploy | SHA-105 owns title, selectors, HUD, wave end, shop, pause, result screens |
| DOC-12 presentation and low-level systems | Pending | Godot 60 tick config exists; no full VFX/audio/camera/object-pool audit yet | Basic demo visuals only | SHA-103 owns sprite mounting, particles, screenshake, audio, themes, export slimming |
| ASSET-01 characters and player | Pending | Devkit assets are present; player demo uses package sprite | Basic player sprite visible | SHA-103 owns scale/anchor/offset audit |
| ASSET-02 weapons and projectiles | Partial | Starter weapon texture/icon paths are validated by data load; projectile runtime pending | Pistol sprite/attack slice visible | SHA-98/SHA-103 own full weapon/projectile mounting audit |
| ASSET-03 enemies, pets, structures | Partial | Starter enemy texture paths are consumed by data runtime | Starter enemies visible | SHA-102/SHA-103 own full enemy/pet/structure audit |
| ASSET-04 items and icons | Pending | Assets present, no shop/inventory item UI yet | Not exposed | SHA-101/SHA-105/SHA-103 |
| ASSET-05 UI and fonts | Pending | Fallback preview page only | Not game UI | SHA-105/SHA-103 |
| ASSET-06 VFX, particles, maps | Pending | Assets present, no full tile/VFX rules implemented | Not audited | SHA-103 |
| ASSET-07 audio | Pending | Assets present, no audio limiter/pitch/music shuffle runtime yet | Not audited | SHA-103 |

## Critical Formula And Behavior Tests

Rows marked Implemented are represented by `tests/run_tests.gd`. Rows marked Assigned must be
implemented by the named child issue before final SHA-91 acceptance.

| ID | Requirement | Source | Status | Coverage |
| --- | --- | --- | --- | --- |
| CT-001 | Effect dictionary exposes the documented 234 keys and defaults | DOC-08 | Implemented | `_effect_key_tests` |
| CT-002 | Effect default containers are deep duplicated | DOC-08 | Implemented | `_effect_key_tests` |
| CT-003 | SUM effects apply and remove correctly | DOC-08 | Implemented | `_storage_tests` |
| CT-004 | KEY_VALUE effects merge, subtract, and remove zero entries | DOC-08 | Implemented | `_storage_tests` |
| CT-005 | REPLACE effects restore prior values in LIFO order | DOC-08 | Implemented | `_storage_tests` |
| CT-006 | APPEND_KEY effects stay unique and removable | DOC-08 | Implemented | `_storage_tests` |
| CT-007 | APPEND_KEY_VALUE effects allow duplicate pairs and remove one pair | DOC-08 | Implemented | `_storage_tests` |
| CT-008 | Permanent, temporary, and gain stat layers aggregate together | DOC-01/DOC-08 | Implemented | `_stat_pipeline_tests` |
| CT-009 | Temporary stats clear without touching permanent stats | DOC-01 | Implemented | `_stat_pipeline_tests` |
| CT-010 | HP cap, dodge cap, dodge hard cap, and movement speed clamp apply | DOC-01 | Implemented | `_stat_pipeline_tests` |
| CT-011 | Linked stats compute integer chunks from source stats | DOC-08 | Implemented | `_stat_pipeline_tests` |
| CT-012 | Linked stat layer outputs are invisible to other linked stats | DOC-08 | Implemented | `_stat_pipeline_tests` |
| CT-013 | XP gain multiplier, level threshold, max HP gain, and level-up heal apply | DOC-01 | Implemented | `_stat_pipeline_tests` |
| CT-014 | Weapon damage uses base plus stat scaling, lower bound, and percent damage | DOC-03 | Implemented | `_formula_tests` |
| CT-015 | Explosion damage includes the explosion damage percent bonus | DOC-03/DOC-08 | Implemented | `_formula_tests` |
| CT-016 | Attack speed cooldown handles positive, negative, and 2-frame lower bound | DOC-03 | Implemented | `_formula_tests` |
| CT-017 | Ranged and melee range use full and half stat range respectively | DOC-03 | Implemented | `_formula_tests` |
| CT-018 | Player armor coefficient covers positive armor, negative armor, and min 1 damage | DOC-01 | Implemented | `_formula_tests` |
| CT-019 | Enemy armor is flat reduction with min 1 damage | DOC-06 | Implemented | `_formula_tests` |
| CT-020 | HP regeneration interval disables at nonpositive values and scales above 1 | DOC-01 | Implemented | `_formula_tests` |
| CT-021 | Lifesteal has a 0.1 second throttle | DOC-01/DOC-03 | Implemented | `_formula_tests` |
| CT-022 | XP requirement follows the documented `(3 + level)^2` curve | DOC-01 | Implemented | `_formula_tests` |
| CT-023 | Shop tier probabilities include wave gates, caps, and luck | DOC-04 | Implemented | `_formula_tests` |
| CT-024 | Reroll price uses wave, paid rerolls, and percent modifier | DOC-04 | Implemented | `_formula_tests` |
| CT-025 | Enemy HP scales by wave, enemy health percent, difficulty, and coop | DOC-06 | Implemented | `_formula_tests` |
| CT-026 | Enemy damage and armor scale by wave and modifiers | DOC-06 | Implemented | `_formula_tests` |
| CT-027 | Danger enemy stat multipliers match danger 3-5 values | DOC-07 | Implemented | `_formula_tests` |
| CT-028 | Enemy material drop chance after wave 5 and horde multiplier are represented | DOC-07 | Implemented, Ambiguous | `_formula_tests`, OQ-003 |
| CT-029 | Spawn count rolls min-max and handles fractional enemies | DOC-07 | Implemented | `_formula_tests` |
| CT-030 | Pickup attraction radius includes the documented lower bound | DOC-10 | Implemented | `_formula_tests` |
| CT-031 | Player iframe duration uses damage ratio clamp | DOC-10 | Implemented | `_formula_tests` |
| CT-032 | Endless factor starts after wave 20 | DOC-07/DOC-09 | Implemented | `_formula_tests` |
| CT-033 | Harvest settlement and endless harvest decay are represented | DOC-01/DOC-07 | Implemented | `_formula_tests` |
| CT-034 | Pickup flight uses initial speed plus acceleration | DOC-10 | Implemented | `_formula_tests` |
| CT-035 | Generic probability helper rejects zero chance and succeeds on inclusive roll | DOC-08 | Implemented | `_formula_tests` |
| CT-036 | Burn data merges global burn, keeps strongest enemy burn, and clamps tick interval | DOC-03/DOC-08 | Implemented | `_burn_tests` |
| CT-037 | Starter weapons load expected row count and resolve Pistol/Fist behavior | DOC-03 | Implemented | `_combat_m2_tests` |
| CT-038 | Weapon target detection adds 200 px and attack range adds 50 px grace | DOC-03/DOC-10 | Implemented | `_combat_m2_tests` |
| CT-039 | Projectile lifetime uses range plus travel grace over projectile speed | DOC-03 | Implemented | `_combat_m2_tests` |
| CT-040 | Weapon crit chance and crit damage combine weapon and player stats | DOC-03 | Implemented | `_combat_m2_tests` |
| CT-041 | Targeting selects nearest eligible enemy and rejects out-of-range enemies | DOC-10 | Implemented | `_combat_m2_tests` |
| CT-042 | Starter enemies scale HP/damage/speed and instantiate runtime rows | DOC-06 | Implemented | `_combat_m2_tests` |
| CT-043 | Wave scheduler emits first group on whole-second timing | DOC-07 | Implemented | `_combat_m2_tests` |
| CT-044 | Spawn warnings materialize after 60 ticks | DOC-07 | Implemented | `_combat_m2_tests` |
| CT-045 | Occupied spawn warnings relocate and restart their timer | DOC-07 | Implemented, Ambiguous | `_combat_m2_tests`, OQ-004 |
| CT-046 | Enemy-cap overflow requests performance culls instead of stopping spawns | DOC-07 | Implemented | `_combat_m2_tests` |
| CT-047 | Spawn queue backlog over 100 dequeues up to two entries every 3 ticks | DOC-07 | Implemented | `_combat_m2_tests` |
| CT-048 | Full Danger 0 wave 1-20 scheduler data | DOC-07 | Assigned | SHA-102 |
| CT-049 | Weapon pierce, bounce, spread, explosion, and melee hit windows | DOC-03 | Assigned | SHA-98 |
| CT-050 | Player contact damage, dodge, knockback, death, drops, and wave transitions | DOC-06/DOC-10 | Assigned | SHA-100 |
| CT-051 | Full shop locking, recycling, combining, crates, and level-up choices | DOC-04 | Assigned | SHA-99 |
| CT-052 | Character, weapon, and item catalog import checks | DOC-02/DOC-03/DOC-05 | Assigned | SHA-101 |
| CT-053 | UI flow smoke from title to result without debug entry | DOC-11 | Assigned | SHA-105 |
| CT-054 | Asset mount audit for sampled sprites, nine-slices, particles, and audio | ASSET-01..ASSET-07/DOC-12 | Assigned | SHA-103 |
| CT-055 | Save, unlock, danger, endless, settings, and local coop smoke | DOC-09/DOC-11 | Assigned | SHA-106 |

## Current Open Questions

`OPEN_QUESTIONS.md` is the canonical list. As of this matrix, active entries are:

| ID | Topic | Blocking area |
| --- | --- | --- |
| OQ-001 | Fractional `gain_stat_*` rounding timing | Final integer stat consumers |
| OQ-002 | Wave repeat interval decrement step for arrow rows | Full wave data lock |
| OQ-003 | Horde material drop multiplier versus 0.5 lower bound order | Material drop formula lock |
| OQ-004 | Spawn warning "player stands on marker" collision radius | Spawn marker/player collider integration |

## Parent Acceptance Audit

| Requirement | Current status | Next audit action |
| --- | --- | --- |
| Chapter-by-chapter matrix for DOC-01..DOC-12 | Implemented in this file | Keep updated whenever child PRs merge |
| Asset mapping matrix for ASSET-01..ASSET-07 | Implemented in this file | SHA-103 must replace pending rows with code/data/test references |
| At least 30 critical formula/behavior tests represented or assigned | Implemented: 55 rows, 47 already represented in tests | `tests/run_tests.gd` guards minimum row count |
| `OPEN_QUESTIONS.md` formatted and deduplicated | Implemented | Add only unresolved design/document ambiguity, not run logs |
| Preview maintained | External preview exists | Re-verify after merged PRs that change export/runtime |
