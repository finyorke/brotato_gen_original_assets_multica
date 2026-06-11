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

## Integer Rounding for Shop and Recycle Prices

- Question: Chapter 04 gives exact shop/recycle price formulas and explicitly says HP-shop and reroll prices use `ceil`, but it does not state how normal fractional material prices are displayed/deducted.
- Document locations: `game_mechanics_docs/04_商店经济与升级系统.md` §2.3, §2.7, §6.
- Conservative handling: The economy API exposes `shop_price_raw` for the exact formula, uses `ceil` for material shop deductions so the runtime does not undercharge fractional prices, and uses floor after the documented recycle rate so recycling does not overpay. Revisit if full M3A data or original scripts specify a different integer cast.

## Level-up Fixed Damage and Crit Damage Effect Keys

- Question: Chapter 04 lists level-up rows for fixed `damage` and `crit_damage`, but the current 234-key effect dictionary has no global `stat_damage` or `crit_damage` stat key.
- Document locations: `game_mechanics_docs/04_商店经济与升级系统.md` §3.4 and `game_mechanics_docs/08_效果系统.md` §1.6.
- Conservative handling: The M3B level-up fixture pool omits those two rows until the full content import defines their exact effect mapping, rather than inventing keys outside the documented effect dictionary.
