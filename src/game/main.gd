extends Node2D

const PlayerDataScript = preload("res://src/core/player_data.gd")
const FormulasScript = preload("res://src/core/formulas.gd")
const WeaponStatsScript = preload("res://src/combat/weapon_stats.gd")
const EnemyStatsScript = preload("res://src/combat/enemy_stats.gd")
const TargetingScript = preload("res://src/combat/targeting.gd")
const WaveSchedulerScript = preload("res://src/combat/wave_scheduler.gd")
const PLAYER_TEXTURE := preload("res://devkit/brotato_original_devkit/asset_pack/assets/player/potato.png")
const MATERIAL_TEXTURE := preload("res://devkit/brotato_original_devkit/asset_pack/assets/materials/material_0000.png")
const WEAPON_DATA_PATH := "res://data/m2/starter_weapons.json"
const ENEMY_DATA_PATH := "res://data/m2/area1_enemies.json"
const WAVE_DATA_PATH := "res://data/m2/area1_waves.json"

var player_data: Variant
var formulas: Variant = FormulasScript.new()
var weapon_stats: Variant
var wave_scheduler: Variant
var player_position := Vector2.ZERO
var enemies: Array = []
var materials: Array = []
var weapon_cooldown_ticks := 0.0
var current_wave := 1
var current_danger := 0
var enemy_stats_by_id: Dictionary = {}
var enemy_textures: Dictionary = {}
var waves_by_number: Dictionary = {}
var weapon_texture: Texture2D

func _ready() -> void:
	Engine.physics_ticks_per_second = 60
	_load_m2_data()
	player_data = PlayerDataScript.new()
	player_data.add_permanent_stat("stat_ranged_damage", 4)
	player_data.add_permanent_stat("stat_attack_speed", 20)
	player_position = get_viewport_rect().size * 0.5

func _physics_process(delta: float) -> void:
	_update_player(delta)
	_update_enemies(delta)
	_update_weapon(delta)
	_update_materials(delta)
	_update_wave(delta)
	queue_redraw()

func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.18, 0.31, 0.17), true)
	for x in range(0, int(viewport_size.x), 64):
		draw_line(Vector2(x, 0), Vector2(x, viewport_size.y), Color(0.22, 0.36, 0.2), 1.0)
	for y in range(0, int(viewport_size.y), 64):
		draw_line(Vector2(0, y), Vector2(viewport_size.x, y), Color(0.22, 0.36, 0.2), 1.0)
	for material in materials:
		var material_data: Dictionary = material
		var material_pos: Vector2 = material_data["position"]
		draw_texture_rect(MATERIAL_TEXTURE, Rect2(material_pos - Vector2(12, 12), Vector2(24, 24)), false)
	for warning in wave_scheduler.warning_queue:
		var warning_data: Dictionary = warning
		var warning_pos: Vector2 = warning_data["position"]
		var pulse := 0.45 + 0.25 * sin(float(warning_data["remaining_ticks"]) * 0.45)
		draw_circle(warning_pos, 34.0, Color(1.0, 0.25, 0.12, pulse))
		draw_arc(warning_pos, 46.0, 0.0, TAU, 48, Color(1.0, 0.85, 0.25, 0.9), 3.0)
	for enemy in enemies:
		var enemy_data: Dictionary = enemy
		var enemy_pos: Vector2 = enemy_data["position"]
		var texture := _texture_for_enemy(enemy_data)
		if texture != null:
			draw_texture_rect(texture, Rect2(enemy_pos - Vector2(32, 32), Vector2(64, 64)), false)
		else:
			draw_circle(enemy_pos, 26.0, Color(0.8, 0.14, 0.12), true)
		var hp_ratio: float = clamp(float(enemy_data["hp"]) / float(enemy_data["max_hp"]), 0.0, 1.0)
		draw_rect(Rect2(enemy_pos + Vector2(-24, -44), Vector2(48, 5)), Color.BLACK, true)
		draw_rect(Rect2(enemy_pos + Vector2(-24, -44), Vector2(48 * hp_ratio, 5)), Color(0.9, 0.14, 0.12), true)
	draw_ellipse(player_position + Vector2(0, 30), 84.0, 24.0, Color(0, 0, 0, 0.35), true)
	draw_texture_rect(PLAYER_TEXTURE, Rect2(player_position - Vector2(48, 48), Vector2(96, 96)), false)
	if weapon_texture != null:
		draw_texture_rect(weapon_texture, Rect2(player_position + Vector2(32, -14), Vector2(56, 28)), false)
	draw_string(ThemeDB.fallback_font, Vector2(24, 32), "M2 combat slice | Wave %d %.1fs/%ds | Materials %d | Enemies %d" % [current_wave, wave_scheduler.elapsed_seconds, int(wave_scheduler.duration_seconds), player_data.materials, enemies.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(24, 56), "%s | Damage %d | Cooldown %.1f ticks | Detect %.0f px" % [weapon_stats.display_name, weapon_stats.resolved_damage(player_data), weapon_stats.resolved_cooldown_ticks(player_data), weapon_stats.detection_range(player_data)], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.95, 0.9))

func _update_player(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	player_position += input_vector * player_data.get_speed() * delta
	var bounds: Vector2 = get_viewport_rect().size
	player_position.x = clamp(player_position.x, 40.0, bounds.x - 40.0)
	player_position.y = clamp(player_position.y, 40.0, bounds.y - 40.0)

func _update_enemies(delta: float) -> void:
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		var enemy_pos: Vector2 = enemy["position"]
		var to_player := player_position - enemy_pos
		var direction := to_player.normalized()
		if String(enemy.get("movement_mode", "chase")) == "keep_distance":
			var distance := to_player.length()
			if distance < 260.0:
				direction = -direction
			elif distance <= 360.0:
				direction = Vector2.ZERO
		enemy["position"] = enemy_pos + direction * float(enemy["speed"]) * delta
		enemies[i] = enemy

func _update_weapon(delta: float) -> void:
	weapon_cooldown_ticks -= delta * 60.0
	if weapon_cooldown_ticks > 0.0:
		return
	var target: Variant = TargetingScript.nearest_enemy(enemies, player_position, weapon_stats.detection_range(player_data), weapon_stats.min_range)
	if target == null:
		return
	var target_distance := player_position.distance_to(target["position"])
	if not weapon_stats.can_attack_target(target_distance, player_data):
		return
	var damage: int = weapon_stats.resolved_damage(player_data)
	var critical: bool = randf() <= weapon_stats.effective_crit_chance(player_data)
	damage = weapon_stats.damage_after_crit(damage, critical)
	damage = formulas.enemy_damage_after_armor(damage, int(target.get("armor", 0)))
	target["hp"] -= damage
	weapon_cooldown_ticks = weapon_stats.resolved_cooldown_ticks(player_data)
	if int(target["hp"]) <= 0:
		_drop_material(target["position"], 1)
		enemies.erase(target)

func _update_materials(delta: float) -> void:
	for material in materials.duplicate():
		var material_data: Dictionary = material
		var material_pos: Vector2 = material_data["position"]
		var distance: float = material_pos.distance_to(player_position)
		if distance <= 30.0:
			player_data.materials += material_data["value"]
			player_data.gain_xp(material_data["value"])
			materials.erase(material)
		elif distance <= 150.0:
			var speed: float = formulas.pickup_flight_speed(500.0, 1200.0, material_data["flight_time"])
			material_data["flight_time"] += delta
			material_data["position"] = material_pos + (player_position - material_pos).normalized() * speed * delta

func _update_wave(delta: float) -> void:
	var requests: Array = wave_scheduler.advance(delta, current_danger, enemies.size())
	for request in requests:
		for i in int(request.get("count", 1)):
			var single_request: Dictionary = request.duplicate(true)
			single_request["count"] = 1
			wave_scheduler.enqueue_warning(single_request, _random_spawn_position(String(request.get("spawn_area", "full"))))
	var materialized: Array = wave_scheduler.physics_tick(player_position)
	for request in materialized:
		_spawn_enemy_from_request(request)
	if wave_scheduler.elapsed_seconds >= wave_scheduler.duration_seconds and enemies.is_empty() and wave_scheduler.active_warning_count() == 0 and wave_scheduler.pending_spawn_count() == 0 and current_wave < _highest_wave_number():
		current_wave += 1
		wave_scheduler = WaveSchedulerScript.from_dict(waves_by_number[current_wave])

func _spawn_enemy_from_request(request: Dictionary) -> void:
	var enemy_id := String(request.get("enemy_id", "baby_alien"))
	var stats: Variant = enemy_stats_by_id.get(enemy_id, null)
	if stats == null:
		push_warning("Missing enemy stats for %s" % enemy_id)
		return
	var difficulty_multiplier: float = formulas.danger_enemy_stat_multiplier(current_danger)
	enemies.append(stats.instantiate(current_wave, request.get("position", player_position), player_data, randf_range(-1.0, 1.0), difficulty_multiplier))

func _drop_material(pos: Vector2, value: int) -> void:
	materials.append({
		"position": pos,
		"value": value,
		"flight_time": 0.0,
	})

func _random_spawn_position(area: String) -> Vector2:
	var viewport_size: Vector2 = get_viewport_rect().size
	var min_distance := 300.0
	for attempt in 32:
		var pos := _raw_spawn_position(area, viewport_size)
		if pos.distance_to(player_position) >= min_distance:
			return pos
		min_distance = max(25.0, min_distance - 5.0)
	return _raw_spawn_position("edge", viewport_size)

func _raw_spawn_position(area: String, viewport_size: Vector2) -> Vector2:
	var margin := 64.0
	if area == "edge":
		match randi() % 4:
			0:
				return Vector2(randf_range(margin, viewport_size.x - margin), margin)
			1:
				return Vector2(viewport_size.x - margin, randf_range(margin, viewport_size.y - margin))
			2:
				return Vector2(randf_range(margin, viewport_size.x - margin), viewport_size.y - margin)
			_:
				return Vector2(margin, randf_range(margin, viewport_size.y - margin))
	if area.begins_with("cluster_"):
		var radius := float(area.get_slice("_", 1))
		var center := Vector2(randf_range(margin, viewport_size.x - margin), randf_range(margin, viewport_size.y - margin))
		var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf() * radius
		return (center + offset).clamp(Vector2(margin, margin), viewport_size - Vector2(margin, margin))
	return Vector2(randf_range(margin, viewport_size.x - margin), randf_range(margin, viewport_size.y - margin))

func _texture_for_enemy(enemy_data: Dictionary) -> Texture2D:
	var path := String(enemy_data.get("texture", ""))
	if path.is_empty():
		return null
	if not enemy_textures.has(path):
		enemy_textures[path] = load(path)
	return enemy_textures[path]

func _load_m2_data() -> void:
	var weapon_json: Dictionary = _load_json(WEAPON_DATA_PATH)
	var weapon_rows: Array = weapon_json.get("weapons", [])
	weapon_stats = WeaponStatsScript.from_dict(weapon_rows[0])
	weapon_texture = load(weapon_stats.texture_path)

	var enemy_json: Dictionary = _load_json(ENEMY_DATA_PATH)
	for row in enemy_json.get("enemies", []):
		var stats: Variant = EnemyStatsScript.from_dict(row)
		enemy_stats_by_id[stats.enemy_id] = stats

	var wave_json: Dictionary = _load_json(WAVE_DATA_PATH)
	for row in wave_json.get("waves", []):
		waves_by_number[int(row.get("wave", 1))] = row
	wave_scheduler = WaveSchedulerScript.from_dict(waves_by_number[current_wave])

func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Could not parse JSON: %s" % path)
		return {}
	return parsed

func _highest_wave_number() -> int:
	var highest := current_wave
	for wave_number in waves_by_number.keys():
		highest = maxi(highest, int(wave_number))
	return highest
