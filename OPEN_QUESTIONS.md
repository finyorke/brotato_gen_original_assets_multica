# Open Questions

## Fractional `gain_stat_*` Results

- Question: The docs state all attributes are integers, while `gain_stat_*` multiplies each whole stat layer and can produce fractional intermediate values.
- Document locations: `game_mechanics_docs/01_核心属性与数值系统.md` §3.1-3.3, `game_mechanics_docs/08_效果系统.md` §1.5.
- Conservative handling: The M1 data layer stores the final stat as a float internally and rounds only at integer consumers such as max HP, damage, and XP thresholds.

## Target Repository Sync

- Question: Multica resource checkout for `https://github.com/finyorke/brotato_gen_original_assets_multica` reports `repo is configured but not synced` even after the GitHub repository was created.
- Document locations: Platform/runtime configuration, not a game design document.
- Conservative handling: Development proceeded in a GitHub-authenticated local clone on branch `agent/fengbo-codex-bypass/sha-91`; this should be re-tried with `multica repo checkout` after the platform resource syncs.

