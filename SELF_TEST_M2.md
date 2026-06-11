# M2 Combat Core Self-Test

## Scope

This pass starts M2 by moving the combat demo from hard-coded values to data-driven runtime primitives:

- `WeaponStats`: damage, cooldown, range, target detection, crit, projectile lifetime.
- `EnemyStats`: HP/damage/armor/speed scaling and material drop chance.
- `WaveScheduler`: wave timing, repeated spawn groups, 60 tick spawn warnings, 3 tick spawn materialization queue.
- `CombatRuntime`: player damage intake, armor/dodge/iframes, enemy knockback, material drop and pickup resolution, wave cleanup, and run win/loss state.
- Starter data rows for 3 weapons, area 1 enemy rows, and area 1 waves 1-20 plus common groups.
- Main scene now uses those data rows for the playable combat slice.

## Verification

Run:

```powershell
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd
```

Expected:

- M1 data/effect/formula tests still pass.
- M2 weapon, enemy, targeting, and wave scheduler tests pass.
- M2C pickup, iframe, knockback, drop, wave completion, and win/loss tests pass.

Main scene smoke:

```powershell
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --quit-after 2
```

## Remaining M2 Work

- Add projectile node behavior for piercing, bounce, spread, and lifetime.
- Add melee thrust/sweep hit windows instead of direct target damage.
- Complete interactive Danger 0 20-wave playthrough validation beyond the deterministic scheduler simulation.
