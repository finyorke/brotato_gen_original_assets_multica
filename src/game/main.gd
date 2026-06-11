extends Node2D

const PlayerDataScript = preload("res://src/core/player_data.gd")
const FormulasScript = preload("res://src/core/formulas.gd")
const PLAYER_TEXTURE := preload("res://devkit/brotato_original_devkit/asset_pack/assets/player/potato.png")
const ENEMY_TEXTURE := preload("res://devkit/brotato_original_devkit/asset_pack/assets/enemies/baby_alien/baby_alien.png")
const MATERIAL_TEXTURE := preload("res://devkit/brotato_original_devkit/asset_pack/assets/materials/material_0000.png")

var player_data: Variant
var formulas: Variant = FormulasScript.new()
var player_position := Vector2.ZERO
var enemies: Array = []
var materials: Array = []
var weapon_cooldown_ticks := 0.0
var spawn_timer := 0.0
var elapsed := 0.0

func _ready() -> void:
	Engine.physics_ticks_per_second = 60
	player_data = PlayerDataScript.new()
	player_data.add_permanent_stat("stat_ranged_damage", 4)
	player_data.add_permanent_stat("stat_attack_speed", 20)
	player_position = get_viewport_rect().size * 0.5
	for i in 6:
		_spawn_enemy()

func _physics_process(delta: float) -> void:
	elapsed += delta
	_update_player(delta)
	_update_enemies(delta)
	_update_weapon(delta)
	_update_materials(delta)
	spawn_timer += delta
	if spawn_timer >= 1.0:
		spawn_timer = 0.0
		_spawn_enemy()
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
	for enemy in enemies:
		var enemy_data: Dictionary = enemy
		var enemy_pos: Vector2 = enemy_data["position"]
		draw_texture_rect(ENEMY_TEXTURE, Rect2(enemy_pos - Vector2(32, 32), Vector2(64, 64)), false)
		var hp_ratio: float = clamp(float(enemy_data["hp"]) / float(enemy_data["max_hp"]), 0.0, 1.0)
		draw_rect(Rect2(enemy_pos + Vector2(-24, -44), Vector2(48, 5)), Color.BLACK, true)
		draw_rect(Rect2(enemy_pos + Vector2(-24, -44), Vector2(48 * hp_ratio, 5)), Color(0.9, 0.14, 0.12), true)
	draw_ellipse(player_position + Vector2(0, 30), 84.0, 24.0, Color(0, 0, 0, 0.35), true)
	draw_texture_rect(PLAYER_TEXTURE, Rect2(player_position - Vector2(48, 48), Vector2(96, 96)), false)
	draw_string(ThemeDB.fallback_font, Vector2(24, 32), "M1 smoke demo | 60 tick/s | Materials %d | Enemies %d" % [player_data.materials, enemies.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(24, 56), "Move: WASD. Auto-target range = weapon range + 200 px.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.95, 0.9))

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
		var direction: Vector2 = (player_position - enemy_pos).normalized()
		enemy["position"] = enemy_pos + direction * float(enemy["speed"]) * delta
		enemies[i] = enemy

func _update_weapon(delta: float) -> void:
	weapon_cooldown_ticks -= delta * 60.0
	if weapon_cooldown_ticks > 0.0:
		return
	var target: Variant = _nearest_enemy_in_range(150.0 + player_data.get_stat("stat_range") + 200.0)
	if target == null:
		return
	var damage: int = formulas.weapon_damage(5, {"stat_ranged_damage": 1.0}, player_data)
	target["hp"] -= damage
	weapon_cooldown_ticks = formulas.weapon_cooldown(60.0, player_data.get_stat("stat_attack_speed"))
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

func _spawn_enemy() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var side := randi() % 4
	var pos := Vector2.ZERO
	match side:
		0:
			pos = Vector2(randf() * viewport_size.x, -32)
		1:
			pos = Vector2(viewport_size.x + 32, randf() * viewport_size.y)
		2:
			pos = Vector2(randf() * viewport_size.x, viewport_size.y + 32)
		_:
			pos = Vector2(-32, randf() * viewport_size.y)
	var hp: int = formulas.enemy_hp(6, 1, maxi(1, int(elapsed / 12.0) + 1))
	enemies.append({
		"position": pos,
		"hp": hp,
		"max_hp": hp,
		"speed": 115.0,
	})

func _drop_material(pos: Vector2, value: int) -> void:
	materials.append({
		"position": pos,
		"value": value,
		"flight_time": 0.0,
	})

func _nearest_enemy_in_range(max_range: float) -> Variant:
	var best: Variant = null
	var best_distance: float = INF
	for enemy in enemies:
		var enemy_data: Dictionary = enemy
		var enemy_pos: Vector2 = enemy_data["position"]
		var distance: float = player_position.distance_to(enemy_pos)
		if distance <= max_range and distance < best_distance:
			best = enemy
			best_distance = distance
	return best
