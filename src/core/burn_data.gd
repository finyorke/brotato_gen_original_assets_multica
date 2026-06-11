class_name BurnData
extends RefCounted

var chance: float = 0.0
var damage: int = 0
var duration: int = 0
var spread: int = 0
var scaling_stats: Dictionary = {"stat_elemental_damage": 1.0}
var is_global_burn: bool = false
var source_id: String = ""

func duplicate_data():
	var copy = get_script().new()
	copy.chance = chance
	copy.damage = damage
	copy.duration = duration
	copy.spread = spread
	copy.scaling_stats = scaling_stats.duplicate(true)
	copy.is_global_burn = is_global_burn
	copy.source_id = source_id
	return copy

func is_empty() -> bool:
	return is_zero_approx(chance) and damage == 0 and duration == 0 and spread == 0

func merge_global(other: Variant, sign: int = 1) -> void:
	chance += other.chance * sign
	damage += other.damage * sign
	spread += other.spread * sign
	if sign >= 0:
		duration = maxi(duration, other.duration)
	else:
		duration = max(0, duration - other.duration)

func merged_enemy_burn(existing, incoming):
	var merged: Variant = existing.duplicate_data()
	if incoming.damage >= existing.damage:
		merged.source_id = incoming.source_id
		merged.scaling_stats = incoming.scaling_stats.duplicate(true)
	merged.chance = max(existing.chance, incoming.chance)
	merged.damage = maxi(existing.damage, incoming.damage)
	merged.duration = maxi(existing.duration, incoming.duration)
	merged.spread = maxi(existing.spread, incoming.spread)
	return merged

func tick_interval(reduction_percent: float, increase_percent: float) -> float:
	return max(0.1, 0.5 * (1.0 + increase_percent / 100.0 - reduction_percent / 100.0))
