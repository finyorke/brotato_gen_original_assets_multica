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
- Data-driven starter enemy rows for the first Danger 0 wave slice.
- Wave 1-5 scheduler data, including spawn timing, repeats, danger gates, 60 tick spawn warnings, and 3 tick spawn queue cadence.
- Combat helpers for weapon resolution, enemy stat scaling, targeting, material drop chance, pickup radius, and player iframe timing.
- M2C combat runtime for player damage intake, armor/dodge/iframes, enemy knockback, material drops, pickup attraction, XP/material collection, timer-based wave cleanup, and starter-subset win/loss state.
- Main scene now consumes the M2 data and runtime loop instead of hard-coded weapon/enemy numbers.

Current M3B backend slice:

- Fixture economy catalog for a small documented subset of items, weapons, and consumables until full M3A content data is merged.
- Shop/economy APIs for tier rolls, prices, rerolls, locking, item purchase, weapon buy-combine, recycling, and reward settlement.
- Level-up option generation with documented tier overrides and upgrade values for effect keys already present in the M1 dictionary.
- Headless tests for shop probabilities, pricing, reroll/free reroll, locking, combining, recycling, XP/harvesting rewards, crates, and consumables.

## Run Locally

```powershell
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --path .
```

## Test

```powershell
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd
```

## Preview

`.github/workflows/godot-pages.yml` exports the Godot Web build and deploys it to GitHub Pages after the PR is merged to `main`, or manually via `workflow_dispatch`.

Known external blocker: GitHub returned 422 for Pages on the private repository plan during M1. The workflow remains ready; Pages needs repo/plan support or another preview host before a public URL can be maintained.
