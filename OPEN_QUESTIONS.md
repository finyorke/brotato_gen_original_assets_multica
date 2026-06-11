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

## M3 Weapon Quality Slots

- Question: Chapter 03 describes "61 weapons x each grade" but the weapon tables list 201 concrete grade rows, leaving 43 family/quality slots without stats.
- Document locations: `game_mechanics_docs/03_武器系统.md` §10 and the 10.1/10.2 weapon tables.
- Conservative handling: M3 data keeps all 61 families with four quality slots each, marks undocumented slots as `available=false`, and only creates stat-bearing variants for documented rows.

## M3 Complex Effect Serialization

- Question: Several character, weapon, and item effects are described behaviorally but do not include every serialized effect-class field needed for a complete runtime implementation, especially pet/structure/projectile/explosion wrapper objects.
- Document locations: `game_mechanics_docs/02_角色系统.md` §3, `game_mechanics_docs/03_武器系统.md` §10-11, `game_mechanics_docs/05_道具清单.md` §3-4, and `game_mechanics_docs/08_效果系统.md` §2.
- Conservative handling: M3 imports parsed effect keys when deterministic and preserves the original text as `raw_effect_text` payloads with doc line traceability when the docs are not specific enough to synthesize a safe runtime object.
