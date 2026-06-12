# SELF TEST UI

Scope: latest devkit sync and UI layout pass against chapter 13 layout specs for SHA-91.

Implemented layout coverage:

1. Title screen uses the multi-layer title key art, 1122x330 centered logo, two-column bottom menu, profile/codex/options/credits entries, and version line.
2. Settings uses the documented 25/10/125 margins, 65px tab row, centered content area, and audio/video/gameplay/accessibility controls.
3. Character, weapon, and danger selection use fixed top-left back controls, 25/75/25/25 content margins, preview/detail panels, and 96x96 grid cells.
4. Combat HUD uses 24px edge margins, 320x48 health/XP bars, 64px material row, centered wave/timer, right-side pause/stat panel, and damage darken overlay.
5. Shop uses 25px margins, four 465x603 product cards, 414px right column, equipment grids, and a fixed bottom-right continue action.
6. Level-up and crate reward overlays use the documented card/panel sizes with reroll/accept controls.
7. Pause and result screens now reserve the documented center panels, inventory/equipment/stat areas, wave timeline, and restart/menu actions.
8. Profile, codex, credits, and generic placeholder screens share the same panel language so the title-menu entries lead to concrete UI surfaces.

Verification run:

- `python tools\import_m3_static_content.py`
- `& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd`
- `& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --quit-after 3`
- `& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --export-release Web export/web/index.html`

Result:

- M3 import completed with 49 characters, 209 items, 61 weapon families, 244 weapon quality slots, and 43 undocumented entries.
- Godot tests passed: 6500 assertions.
- Headless startup completed cleanly.
- Web export completed successfully to `export/web/index.html`.
