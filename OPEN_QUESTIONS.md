# Open Questions

Only unresolved design-document ambiguity belongs here. Resolved implementation notes and
one-run platform issues should be removed so SHA-104 can use this file as the final audit list.

## OQ-001 Fractional `gain_stat_*` Results

- Question: The docs state all attributes are integers, while `gain_stat_*` multiplies each whole stat layer and can produce fractional intermediate values.
- Document locations: `game_mechanics_docs/01_核心属性与数值系统.md` §3.1-3.3, `game_mechanics_docs/08_效果系统.md` §1.5.
- Conservative handling: The M1 data layer stores the final stat as a float internally and rounds only at integer consumers such as max HP, damage, and XP thresholds.

## OQ-002 Wave Interval Decrease Step

- Question: Chapter 07 marks some area 1 repeat intervals with an arrow to a lower bound, but does not state the exact decrement step per repeat.
- Document locations: `game_mechanics_docs/07_波次难度与生成系统.md` §3.2 table notes and affected rows such as wave 3 `7 -> 3` and wave 5 `5 -> 2`.
- Conservative handling: The M2 starter data keeps the current 1 second decrement for arrow rows so the interval trends toward the documented lower bound, but this remains unverified and must be confirmed before final wave data lock.

## OQ-003 Horde Material Drop Lower Bound Order

- Question: Chapter 07 states the post-wave material chance lower bound and the horde-wave 0.65 multiplier, but the wording is ambiguous about whether the 0.5 lower bound is re-applied after the horde multiplier.
- Document locations: `game_mechanics_docs/07_波次难度与生成系统.md` §4.2.
- Conservative handling: The current formula applies the wave lower bound first, then the horde multiplier, matching the literal reading used in the M2 review; revisit if later documentation clarifies a post-horde clamp.

## OQ-004 Spawn Warning Occupancy Radius

- Question: Chapter 07 says a spawn marker relocates when the player stands on the marker, but does not specify the collision radius or shape for "stands on" before the real marker/player colliders are wired.
- Document locations: `game_mechanics_docs/07_波次难度与生成系统.md` §2.4.
- Conservative handling: The M2 scheduler treats exact position overlap as occupied and already supports relocation plus timer reset. SHA-100/SHA-103 should replace this with the documented or collider-derived overlap once marker/player bodies exist.
