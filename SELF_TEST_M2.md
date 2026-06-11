# M2 Combat Core Self-Test

## Scope

This pass starts M2 by moving the combat demo from hard-coded values to data-driven runtime primitives:

- `WeaponStats`: damage, cooldown, range, target detection, crit, projectile lifetime, projectile count/spread, pierce/bounce, burn/explosion/hook fields.
- `WeaponAttackRuntime`: cooldown gating, opening cooldown clamp, attack duration windows, hit packet construction, crit/lifesteal/burn/vulnerability/explosion hooks, projectile spread/lifetime, piercing, and bounce sequencing.
- `EnemyStats`: HP/damage/armor/speed scaling and material drop chance.
- `WaveScheduler`: wave timing, repeated spawn groups, 60 tick spawn warnings, 3 tick spawn materialization queue.
- `CombatRuntime`: player damage intake, armor/dodge/iframes, enemy knockback, material drop and pickup resolution, wave cleanup, and run win/loss state.
- Starter data rows for 3 weapons, area 1 enemy rows, and area 1 waves 1-20 plus common groups.
- Main scene now uses those data rows and the shared weapon attack runtime for the playable combat slice.

## Source Notes

- Weapon damage, cooldown, attack speed, crit/lifesteal, range, projectile spread, pierce/bounce, projectile lifetime, attack duration, and melee windows follow `brotato_original_devkit/game_mechanics_docs/03_武器系统.md` §§3.4-3.8, 3.12, 4.2-4.5, 5.1-5.2, 6.1-6.3, and 7.1-7.4.
- Burn construction, burn application, vulnerability hooks, and probability behavior follow `brotato_original_devkit/game_mechanics_docs/08_效果系统.md` §§3.1-3.4, 4, 5, and 6.
- Attack gating while moving, target detection, manual-aim range bypass, and 60-ticks-per-second cooldown decrement follow `brotato_original_devkit/game_mechanics_docs/10_输入操控与玩家手感.md` §6 and §12.
- Hit packet presentation hook fields mirror the attack-area payload and hit-order notes in `brotato_original_devkit/game_mechanics_docs/12_表现层与底层系统.md` collision / hitbox section.

## Verification

Run:

```powershell
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --script tests/run_tests.gd
```

Expected:

- M1 data/effect/formula tests still pass.
- M2 weapon, enemy, targeting, wave scheduler, and weapon runtime tests pass.
- M2C pickup, iframe, knockback, drop, wave completion, and win/loss tests pass.

Main scene smoke:

```powershell
& 'C:\Users\fengbo\Developer\godot\Godot_v4.6.2-stable_win64_console.exe' --headless --path . --quit-after 2
```

## Remaining M2 Work

- Add projectile node behavior for piercing, bounce, spread, and lifetime.
- Add melee thrust/sweep hit windows instead of direct target damage.
- Replace the current dictionary projectile simulation with scene projectile nodes and asset-derived hitbox shapes.
- Add scene collision shapes for melee thrust/sweep hitboxes once the exact dimensions are sourced from assets or upstream data.
- Add full explosion area-of-effect scene handling once explosion scale-to-radius presentation data is locked.
- Complete interactive Danger 0 20-wave playthrough validation beyond the deterministic scheduler simulation.
