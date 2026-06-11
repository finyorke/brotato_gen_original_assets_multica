# M1 Self-Test Report

Status: passed locally.

Command:

```powershell
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd
```

Coverage target:

- Effect dictionary defaults and container duplication.
- Five effect storage methods and removal behavior.
- Permanent, temporary, linked, gain, cap, speed, dodge, level-up, and XP paths.
- Core formula checks for damage, cooldown, armor, regeneration, shop quality, reroll price, enemy HP, harvesting, pickup attraction, probability, and burning.

Results:

- `tests/run_tests.gd`: passed, 78 assertions.
- `godot --headless --path . --import`: passed.
- `godot --headless --path . --quit-after 1`: passed.
- `godot --headless --path . --export-release Web export/web/index.html`: passed.
