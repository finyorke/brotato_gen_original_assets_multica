# Brotato Original Assets Multica

Godot 4 implementation scaffold for SHA-91. The project treats `devkit/brotato_original_devkit/` as the only specification source and imports its full design docs plus asset pack into this repository.

## Current Scope

This first implementation pass covers M1:

- 60 tick/s Godot project configuration.
- Data-driven player effect dictionary initialized from the documented effect keys.
- Effect apply/remove support for all five storage methods.
- Permanent, temporary, and linked stat aggregation with `gain_stat_*` modifiers and caps.
- Core formulas from chapters 00, 01, and 08.
- A smoke demo scene that uses package assets and validates instant movement, nearest-target auto attack, enemy HP scaling, material pickup range, and pickup flight acceleration.
- Headless tests in `tests/run_tests.gd`.

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

