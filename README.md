# Brotato Original Assets Multica

Godot 4 implementation scaffold for SHA-91. The project treats `devkit/brotato_original_devkit/` as the only specification source and imports its full design docs plus asset pack into this repository.

## Current Scope

Completed M1:

- 60 tick/s Godot project configuration.
- Data-driven player effect dictionary initialized from the documented effect keys.
- Effect apply/remove support for all five storage methods.
- Permanent, temporary, and linked stat aggregation with `gain_stat_*` modifiers and caps.
- Core formulas from chapters 00, 01, and 08.
- Headless tests in `tests/run_tests.gd`.

Current M2 slice:

- Data-driven starter weapon rows for Pistol I, Fist I, and SMG I.
- Data-driven area 1 enemy rows needed by the 20-wave Danger 0 schedule, with gated normal enemy rows encoded from the docs.
- Full area 1 wave 1-20 scheduler data, including common groups, composite spawn groups, danger gates, immediate wave 20 boss timing, 60 tick spawn warnings, and 3 tick spawn queue cadence.
- Combat helpers for weapon resolution, enemy stat scaling, targeting, material drop chance, pickup radius, and player iframe timing.
- Weapon attack runtime for cooldown gating, attack duration windows, hit packet construction, crit, lifesteal, burn/vulnerability hook records, explosion conversion, projectile spread/lifetime, piercing, and bounce.
- M2C combat runtime for player damage intake, armor/dodge/iframes, enemy knockback, material drops, pickup attraction, XP/material collection, timer-based wave cleanup, and starter-subset win/loss state.
- Main scene now consumes the M2 data, shared weapon attack runtime, and combat runtime loop instead of hard-coded weapon/enemy numbers.

Current M3 data import:

- `tools/import_m3_static_content.py` imports docs 02, 03, 05, and 08 into `data/m3/`.
- The generated data covers 49 characters, 61 weapon families with four quality slots, 201 documented weapon variant rows, 209 item data rows, tags/sets, unlock metadata, asset refs, and effect payloads.
- Complex effects without full serialized fields are preserved as raw source-text payloads with doc line traceability; see `OPEN_QUESTIONS.md`.

Current M3B backend slice:

- Fixture economy catalog for a small documented subset of items, weapons, and consumables until full M3A content data is merged.
- Shop/economy APIs for tier rolls, prices, rerolls, locking, item purchase, weapon buy-combine, recycling, and reward settlement.
- Level-up option generation with documented tier overrides and upgrade values for effect keys already present in the M1 dictionary.
- Headless tests for shop probabilities, pricing, reroll/free reroll, locking, combining, recycling, XP/harvesting rewards, crates, and consumables.

Current M5 slice:

- M5 asset manifest built from the seven asset mapping docs, covering player, starter weapons, area 1 enemies, materials, ground themes, tier colors, VFX, audio events, and music.
- Main scene consumes the M5 presentation rules for weighted ground tiles, material variants, weapon offsets, flash, shake, floating damage text, and audio request throttling.
- Tests cover representative asset audits, audio pitch/rate limiting, 11-track music queue behavior, and ground tile weighting.
- Web export now uses selected runtime resources instead of bundling the full devkit tree.

Current M6 backend slice:

- Progression state for unlocks, difficulty records, challenge completion, 113 challenge registry entries, and win/endless record updates.
- V3-style local save service for `save_v3_<slot>.json`, `run_v3_<slot>.json`, `settings.json`, atomic temp writes, and rotating progress backups.
- Settings defaults for documented audio/video/gameplay/accessibility options that directly affect backend decisions.
- Co-op state helper for player join slots, shared material rotation, shared item box assignment, death/ready state, and per-player shop state creation.
- Extended danger, endless, and co-op formulas with headless coverage.

## Run Locally

```powershell
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --path .
```

## Test

```powershell
python tools\import_m3_static_content.py
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd
```

## Preview

`.github/workflows/godot-pages.yml` exports the Godot Web build and deploys it to GitHub Pages after the PR is merged to `main`, or manually via `workflow_dispatch`.

Known external blocker: GitHub returned 422 for Pages on the private repository plan during M1. The workflow remains ready; Pages needs repo/plan support or another preview host before a public URL can be maintained.
