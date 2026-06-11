class_name Targeting
extends RefCounted

static func nearest_enemy(enemies: Array, origin: Vector2, max_detection_range: float, min_range: float = 0.0) -> Variant:
	var best: Variant = null
	var best_distance := INF
	for enemy in enemies:
		var enemy_data: Dictionary = enemy
		if bool(enemy_data.get("dead", false)):
			continue
		var enemy_pos: Vector2 = enemy_data.get("position", Vector2.ZERO)
		var distance := origin.distance_to(enemy_pos)
		if distance >= min_range and distance <= max_detection_range and distance < best_distance:
			best = enemy
			best_distance = distance
	return best
