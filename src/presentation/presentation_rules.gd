class_name PresentationRules
extends RefCounted

const TILE_SIZE := 64
const GROUND_SUBTILE_COLUMNS := 3
const GROUND_SUBTILE_ROWS := 4
const GROUND_PLAIN_SUBTILE := Vector2i(2, 3)
const GROUND_PLAIN_WEIGHT := 50
const GROUND_DECORATED_WEIGHT := 1
const FLASH_DURATION_SECONDS := 0.1
const FLOATING_TEXT_DURATION_SECONDS := 0.5
const PLAYER_DAMAGE_SHAKE_INTENSITY := 5.0
const ENEMY_DAMAGE_SHAKE_MAX_INTENSITY := 3.0
const SHAKE_DURATION_SECONDS := 0.1
const MATERIAL_BOOSTED_SCALE := 1.25
const MATERIAL_MERGED_VALUE_SCALE_STEP := 0.05
const MATERIAL_MAX_SCALE := 2.0

static func weighted_ground_subtiles(plain_weight: int = GROUND_PLAIN_WEIGHT, decorated_weight: int = GROUND_DECORATED_WEIGHT) -> Array:
	var entries: Array = []
	for y in GROUND_SUBTILE_ROWS:
		for x in GROUND_SUBTILE_COLUMNS:
			var coord := Vector2i(x, y)
			var weight := plain_weight if coord == GROUND_PLAIN_SUBTILE else decorated_weight
			entries.append({"coord": coord, "weight": weight})
	return entries

static func total_weight(entries: Array) -> int:
	var total := 0
	for entry in entries:
		total += int(entry.get("weight", 0))
	return total

static func pick_weighted_ground_subtile(roll: int, entries: Array = []) -> Vector2i:
	if entries.is_empty():
		entries = weighted_ground_subtiles()
	var total := total_weight(entries)
	if total <= 0:
		return GROUND_PLAIN_SUBTILE
	var remaining := posmod(roll, total)
	for entry in entries:
		remaining -= int(entry.get("weight", 0))
		if remaining < 0:
			return entry.get("coord", GROUND_PLAIN_SUBTILE)
	return GROUND_PLAIN_SUBTILE

static func decorated_ground_probability(entries: Array = []) -> float:
	if entries.is_empty():
		entries = weighted_ground_subtiles()
	var decorated := 0
	for entry in entries:
		if entry.get("coord", GROUND_PLAIN_SUBTILE) != GROUND_PLAIN_SUBTILE:
			decorated += int(entry.get("weight", 0))
	return float(decorated) / float(maxi(1, total_weight(entries)))

static func deterministic_ground_roll(cell: Vector2i, seed: int = 17) -> int:
	var h := int(cell.x * 73856093) ^ int(cell.y * 19349663) ^ int(seed * 83492791)
	return abs(h)

static func weapon_mount_position(slot_index: int, total_weapons: int, manifest_player: Dictionary = {}) -> Vector2:
	var mounts: Dictionary = manifest_player.get("weapon_mounts", {})
	var slots: Array = mounts.get("slots", [])
	if slot_index >= 0 and slot_index < slots.size():
		return _vec2(slots[slot_index])
	var radius: float = float(mounts.get("fallback_ring_radius", 60)) + max(0, total_weapons - 6) * float(mounts.get("extra_weapon_radius_step", 5))
	var angle: float = -PI * 0.5 + TAU * float(slot_index) / float(maxi(1, total_weapons))
	return Vector2.RIGHT.rotated(angle) * radius

static func weapon_draw_origin(player_position: Vector2, weapon_visual: Dictionary, manifest_player: Dictionary, slot_index: int = 0, total_weapons: int = 1) -> Vector2:
	var container_offset := _vec2(manifest_player.get("weapon_container_offset", [0, -24]))
	var mount_position := weapon_mount_position(slot_index, total_weapons, manifest_player)
	var sprite_position := _vec2(weapon_visual.get("sprite_position", [0, 0]))
	var sprite_offset := _vec2(weapon_visual.get("sprite_offset", [0, 0]))
	var align_anchor := _vec2(weapon_visual.get("align_anchor", [0, 0]))
	return player_position + container_offset + mount_position - align_anchor + sprite_position + sprite_offset

static func material_scale(value: int, boosted: int = 1) -> float:
	if boosted > 1:
		return MATERIAL_BOOSTED_SCALE
	return min(MATERIAL_MAX_SCALE, 1.0 + max(0, value - 1) * MATERIAL_MERGED_VALUE_SCALE_STEP)

static func hit_effect_position(unit_position: Vector2, knockback_direction: Vector2, texture_width: float) -> Vector2:
	if knockback_direction == Vector2.ZERO:
		return unit_position
	return unit_position + knockback_direction.normalized() * texture_width * 0.25

static func screen_shake_for_enemy_damage(damage: int) -> Dictionary:
	return {
		"intensity": min(float(damage) / 3.0, ENEMY_DAMAGE_SHAKE_MAX_INTENSITY),
		"duration": SHAKE_DURATION_SECONDS
	}

static func screen_shake_for_player_damage() -> Dictionary:
	return {
		"intensity": PLAYER_DAMAGE_SHAKE_INTENSITY,
		"duration": SHAKE_DURATION_SECONDS
	}

static func should_replace_screen_shake(current: Dictionary, incoming: Dictionary) -> bool:
	return float(incoming.get("intensity", 0.0)) > float(current.get("intensity", 0.0)) and float(incoming.get("duration", 0.0)) > float(current.get("duration", 0.0))

static func screen_shake_offset(intensity: float, roll_x: float, roll_y: float) -> Vector2:
	return Vector2(clamp(roll_x, 0.0, 1.0), clamp(roll_y, 0.0, 1.0)) * max(0.0, intensity)

static func single_player_camera_center(player_position: Vector2, map_size: Vector2, viewport_size: Vector2, edge_margin: float = 96.0) -> Vector2:
	var half_view := viewport_size * 0.5
	var min_center := half_view - Vector2(edge_margin, edge_margin * 2.0)
	var max_center := map_size - half_view + Vector2(edge_margin, edge_margin)
	var center := player_position
	if min_center.x > max_center.x:
		center.x = map_size.x * 0.5
	else:
		center.x = clamp(center.x, min_center.x, max_center.x)
	if min_center.y > max_center.y:
		center.y = map_size.y * 0.5
	else:
		center.y = clamp(center.y, min_center.y, max_center.y)
	return center

static func damage_text_style(kind: String, amount: int = 0) -> Dictionary:
	match kind:
		"player_damage":
			return {"text": "-%d" % amount, "color": Color(1.0, 0.231373, 0.231373)}
		"enemy_crit":
			return {"text": str(amount), "color": Color(1.0, 0.844, 0.0)}
		"armor_reduced":
			return {"text": str(amount), "color": Color(0.62, 0.62, 0.62)}
		"one_shot":
			return {"text": "ONE_SHOT", "color": Color(1.0, 0.844, 0.0)}
		"dodge":
			return {"text": "DODGE", "color": Color(0.901961, 0.901961, 0.901961)}
		"nullified":
			return {"text": "NULLIFIED", "color": Color(0.901961, 0.901961, 0.901961)}
		"heal":
			return {"text": "+%d" % amount, "color": Color(0.463, 1.0, 0.463)}
		_:
			return {"text": str(amount), "color": Color.WHITE}

static func floating_text_offset(age_seconds: float, duration_seconds: float = FLOATING_TEXT_DURATION_SECONDS) -> Vector2:
	var t: float = clamp(age_seconds / max(0.001, duration_seconds), 0.0, 1.0)
	return Vector2(0, -80).lerp(Vector2(0, -110), t)

static func floating_text_alpha(age_seconds: float, duration_seconds: float = FLOATING_TEXT_DURATION_SECONDS) -> float:
	var fade_start := duration_seconds
	var fade_end := duration_seconds * 2.0
	if age_seconds <= fade_start:
		return 1.0
	return 1.0 - clamp((age_seconds - fade_start) / max(0.001, fade_end - fade_start), 0.0, 1.0)

static func _vec2(values: Variant) -> Vector2:
	if values is Vector2:
		return values
	if values is Array and values.size() >= 2:
		return Vector2(float(values[0]), float(values[1]))
	return Vector2.ZERO
