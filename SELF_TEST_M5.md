# SELF TEST M5

Scope: asset presentation, manifest coverage, audio rules, and Web export packaging for SHA-103.

Representative audit against asset mapping docs:

1. Player body uses `assets/player/potato.png`, centered at original 150x150 source size.
2. Player shadow reuses the body texture, black alpha 0.392157, offset `(0,38)`, scale `(1,-0.3)`.
3. Player legs use `assets/player/legs.png` with 50x50 frames and documented left/right mounts.
4. Pistol uses `assets/weapons/pistol/pistol.png`, icon, muzzle `(32,0)`, align anchor `(2,16)`, recoil `25/0.1s`, and five pistol shots at -10 dB.
5. SMG uses `assets/weapons/smg/smg.png`, recoil `10/0.05s`, effect scale 0.2, and nine SMG shots at -10 dB.
6. Fist uses `assets/weapons/fist/fist_short.png`, hitbox extents `(48,20)`, muzzle `(8,0)`, thrust attack, and fast swing sounds.
7. Area 1 enemies map baby alien, chaser, spitter, charger, and fly textures plus documented offsets and collision radii.
8. Materials use the 11 `material_0000` through `material_0010` sprites, boosted scale 1.25, and merged-value scale cap 2.0.
9. Ground themes map all six `tiles_*.png` atlases, `tiles_outline.png`, 64px cells, and the 50:1 weighted plain subtile rule.
10. Quality/tier colors match the runtime tint table for common through danger 5.
11. VFX rules lock 0.1s flash, hit particles, slash frames, critical particles, pickup particles, burn texture hints, spawn markers, screen shake, floating text, and camera constants.
12. Audio manifest includes the 11-track shared music pool, Sound/Music bus routing, 12-player pools, 16-entry queues, one dequeue per frame, pitch variants, and max-play throttling.

Automated tests:

- `tests/run_tests.gd` now covers M5 manifest audit count and representative asset existence.
- Ground tile weighting checks the 12 subtiles, total weight 61, and plain subtile probability 50/61.
- Audio tests cover pitch ranges, 16-entry queue rate limiting, `always_play` queue displacement, one-sound-per-frame dequeue, same-id max-play caps, music pool count, shuffle, no immediate same-track replay, and state volume dB rules.

Preview/export:

- `export_presets.cfg` uses selected runtime resources rather than `all_resources`, so the Web pck no longer intentionally packages the full devkit docs and unused asset tree.
- The runtime export file list includes the main scene, source scripts, M2 enemy/wave data, M3 character/item/weapon economy data, M5 data, current visual assets, audio event groups, six ground themes, and 11 music tracks.
- SHA-107 main-scene smoke uses the exported path with the M3 Well Rounded character, M3 Pistol I starter variant, M3-backed shop/economy scripts, M2 Danger 0 waves, and M5 presentation hooks.
