# Open Questions

## Fractional `gain_stat_*` Results

- Question: The docs state all attributes are integers, while `gain_stat_*` multiplies each whole stat layer and can produce fractional intermediate values.
- Document locations: `game_mechanics_docs/01_核心属性与数值系统.md` §3.1-3.3, `game_mechanics_docs/08_效果系统.md` §1.5.
- Conservative handling: The M1 data layer stores the final stat as a float internally and rounds only at integer consumers such as max HP, damage, and XP thresholds.

## Target Repository Sync

- Question: Multica resource checkout for `https://github.com/finyorke/brotato_gen_original_assets_multica` reports `repo is configured but not synced` even after the GitHub repository was created.
- Document locations: Platform/runtime configuration, not a game design document.
- Conservative handling: Development proceeded in a GitHub-authenticated local clone on branch `agent/fengbo-codex-bypass/sha-91`; this should be re-tried with `multica repo checkout` after the platform resource syncs.

## Wave Interval Decrease Step

- Question: Chapter 07 marks some area 1 repeat intervals with an arrow to a lower bound, but does not state the exact decrement step per repeat.
- Document locations: `game_mechanics_docs/07_波次难度与生成系统.md` §3.2 table notes and affected rows such as wave 3 `7 -> 3` and wave 5 `5 -> 2`.
- Conservative handling: The M2 starter data keeps the current 1 second decrement for arrow rows so the interval trends toward the documented lower bound, but this remains unverified and must be confirmed before final wave data lock.

## Horde Material Drop Lower Bound Order

- Question: Chapter 07 states the post-wave material chance lower bound and the horde-wave 0.65 multiplier, but the wording is ambiguous about whether the 0.5 lower bound is re-applied after the horde multiplier.
- Document locations: `game_mechanics_docs/07_波次难度与生成系统.md` §4.2.
- Conservative handling: The current formula applies the wave lower bound first, then the horde multiplier, matching the literal reading used in the M2 review; revisit if later documentation clarifies a post-horde clamp.

## Boss Base Movement Speed

- Question: Chapter 06 gives boss HP, damage, knockback resistance, value, phase movement behavior, and phase speed modifiers, but does not state a standalone base movement speed for Invoker/Predator.
- Document locations: `game_mechanics_docs/06_敌人与实体系统.md` §7.1 and §7.3.
- Conservative handling: The M2 boss rows encode the documented HP/damage/drop/value fields and omit a base speed value; boss movement remains behavior-driven pending source data.

## M3 Weapon Quality Slots

- Question: Chapter 03 describes "61 weapons x each grade" but the weapon tables list 201 concrete grade rows, leaving 43 family/quality slots without stats.
- Document locations: `game_mechanics_docs/03_武器系统.md` §10 and the 10.1/10.2 weapon tables.
- Conservative handling: M3 data keeps all 61 families with four quality slots each, marks undocumented slots as `available=false`, and only creates stat-bearing variants for documented rows.

## M3 Complex Effect Serialization

- Question: Several character, weapon, and item effects are described behaviorally but do not include every serialized effect-class field needed for a complete runtime implementation, especially pet/structure/projectile/explosion wrapper objects.
- Document locations: `game_mechanics_docs/02_角色系统.md` §3, `game_mechanics_docs/03_武器系统.md` §10-11, `game_mechanics_docs/05_道具清单.md` §3-4, and `game_mechanics_docs/08_效果系统.md` §2.
- Conservative handling: M3 imports parsed effect keys when deterministic and preserves the original text as `raw_effect_text` payloads with doc line traceability when the docs are not specific enough to synthesize a safe runtime object.

## Starter Enemy Contact Radius

- Question: Chapter 06 documents the player collision radius (24) and hurt radius (21), but the M2 starter enemy JSON does not yet include per-enemy body/contact radii.
- Document locations: `game_mechanics_docs/06_敌人与实体系统.md` §9 and `game_mechanics_docs/10_输入操控与玩家手感.md` §7.
- Conservative handling: The M2C runtime uses player hurt radius 21 plus a starter enemy body radius 24 for contact damage until full enemy hitbox data is imported.

## Starter Weapon Knockback Bounds

- Question: Chapter 01 says weapon knockback is `clamp(base + player knockback, min, max)`, but the M2 starter weapon rows do not yet include per-weapon knockback min/max bounds.
- Document locations: `game_mechanics_docs/01_核心属性与数值系统.md` §5.5 and `game_mechanics_docs/06_敌人与实体系统.md` §3.5.
- Conservative handling: The M2C runtime resolves knockback as `base + player knockback`, applies `negative_knockback` sign reversal, and leaves bound clamping for the future full weapon data import.

## Integer Rounding for Shop and Recycle Prices

- Question: Chapter 04 gives exact shop/recycle price formulas and explicitly says HP-shop and reroll prices use `ceil`, but it does not state how normal fractional material prices are displayed/deducted.
- Document locations: `game_mechanics_docs/04_商店经济与升级系统.md` §2.3, §2.7, §6.
- Conservative handling: The economy API exposes `shop_price_raw` for the exact formula, uses `ceil` for material shop deductions so the runtime does not undercharge fractional prices, and uses floor after the documented recycle rate so recycling does not overpay. Revisit if full M3A data or original scripts specify a different integer cast.

## Level-up Fixed Damage and Crit Damage Effect Keys

- Question: Chapter 04 lists level-up rows for fixed `damage` and `crit_damage`, but the current 234-key effect dictionary has no global `stat_damage` or `crit_damage` stat key.
- Document locations: `game_mechanics_docs/04_商店经济与升级系统.md` §3.4 and `game_mechanics_docs/08_效果系统.md` §1.6.
- Conservative handling: The M3B level-up fixture pool omits those two rows until the full content import defines their exact effect mapping, rather than inventing keys outside the documented effect dictionary.

## Melee Hitbox Geometry

- Question: Chapter 03 defines thrust/sweep timing, range, and sweep arc, while Chapter 12 says attack areas carry hit parameters, but neither document gives numeric collision-shape dimensions for the melee weapon texture hitboxes.
- Document locations: `game_mechanics_docs/03_武器系统.md` §§5.1-5.2, `game_mechanics_docs/12_表现层与底层系统.md` attack-area / hitbox notes.
- Conservative handling: `WeaponAttackRuntime` now computes documented timing windows, reach, sweep arc, and hit packets, but does not invent melee hitbox width/shape constants. Scene collision shapes should come from source assets or confirmed upstream data.

## Sweep Windup Duration

- Question: Chapter 03 says sweep attacks begin with a no-damage rotation setup, then two active quarters of `atk_duration`, but it does not state a separate duration for that setup phase.
- Document locations: `game_mechanics_docs/03_武器系统.md` §5.2.
- Conservative handling: The runtime records the setup as a zero-duration orientation phase and models the documented active half plus return phase. Revisit if upstream data exposes a separate sweep windup duration.
