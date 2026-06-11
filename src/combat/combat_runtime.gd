class_name CombatRuntime
extends RefCounted

const FormulasScript = preload("res://src/core/formulas.gd")

const STATE_RUNNING := "running"
const STATE_WON := "won"
const STATE_LOST := "lost"

# Docs: 06 §9 and 10 §7 define player hurt/pickup radii; enemy body radius is tracked in OPEN_QUESTIONS.md for this M2 subset.
const PLAYER_HURT_RADIUS := 21.0
const ENEMY_CONTACT_RADIUS := 24.0
const CONTACT_RADIUS := PLAYER_HURT_RADIUS + ENEMY_CONTACT_RADIUS
const PLAYER_PICKUP_RADIUS := 32.0

# Docs: 01 §11 and 12 §3.8 cap material entities at 50 and merge excess value into existing drops.
const MATERIAL_ENTITY_LIMIT := 50
const MATERIAL_SCALE_STEP := 0.05
const MATERIAL_MAX_SCALE := 2.0

# Docs: 10 §7 and 12 §3.8: material attraction starts at 500 px/s and accelerates by 20 px/frame at 60 Hz.
const MATERIAL_ATTRACT_INITIAL_SPEED := 500.0
const MATERIAL_ATTRACT_ACCELERATION := 1200.0

# Docs: 06 §3.5 and 10 §5.1: knockback vector decays by lerp-to-zero with 0.1 per physics frame.
const KNOCKBACK_DECAY := 0.1

var player_data: Variant = null
var formulas: Variant = FormulasScript.new()
var state := STATE_RUNNING
var current_wave := 1
var highest_wave := 1
var current_danger := 0
var iframe_seconds_remaining := 0.0
var hit_protection_charges := 0
var bonus_gold := 0
var last_damage_result: Dictionary = {}

func start_run(player: Variant, starting_wave: int = 1, highest_wave_number: int = 1, danger: int = 0) -> void:
	player_data = player
	current_wave = starting_wave
	highest_wave = maxi(starting_wave, highest_wave_number)
	current_danger = danger
	state = STATE_RUNNING
	bonus_gold = 0
	start_wave(starting_wave)

func start_wave(wave: int = current_wave) -> void:
	current_wave = wave
	state = STATE_RUNNING
	iframe_seconds_remaining = 0.0
	hit_protection_charges = maxi(0, roundi(player_data.get_stat("hit_protection")))
	var max_health: int = player_data.get_max_health()
	var start_percent: float = _wave_start_health_percent()
	player_data.current_health = maxi(1, roundi(float(max_health) * start_percent / 100.0))

func advance(delta: float) -> void:
	iframe_seconds_remaining = max(0.0, iframe_seconds_remaining - delta)

func resolve_player_damage(raw_damage: int, can_dodge: bool = true, ignores_armor: bool = false, ignores_iframes: bool = false, dodge_roll: float = -1.0) -> Dictionary:
	if state != STATE_RUNNING:
		return _damage_result(false, "inactive", 0, false, false)
	if iframe_seconds_remaining > 0.0 and not ignores_iframes:
		return _damage_result(false, "iframes", 0, false, false)

	var dodged := false
	var blocked := false
	var damage_taken := 0
	if can_dodge and _probability_roll(player_data.get_dodge_probability(), dodge_roll):
		dodged = true
	elif hit_protection_charges > 0:
		hit_protection_charges -= 1
		blocked = true
	else:
		damage_taken = formulas.player_damage_after_armor(raw_damage, player_data.get_stat("stat_armor"), ignores_armor)
		player_data.current_health -= damage_taken

	# Docs: 01 §6.3 says hit, block, and dodge outcomes all trigger iframes; zero-damage outcomes clamp to 0.2s.
	iframe_seconds_remaining = formulas.player_iframe_seconds(damage_taken, player_data.get_max_health(), 1.0)
	if player_data.current_health <= 0:
		player_data.current_health = 0
		player_data.clear_temporary_stats()
		state = STATE_LOST

	return _damage_result(true, "hit", damage_taken, dodged, blocked)

func heal_player(amount: int) -> int:
	if amount <= 0 or player_data.get_stat("no_heal") > 0.0:
		return 0
	var before: int = player_data.current_health
	player_data.current_health = mini(player_data.get_max_health(), player_data.current_health + amount)
	return player_data.current_health - before

func apply_enemy_damage(enemy: Dictionary, damage: int, attacker_position: Vector2, knockback_amount: float = 0.0) -> Dictionary:
	var actual_damage := maxi(1, damage)
	enemy["hp"] = int(enemy.get("hp", 1)) - actual_damage
	var direction: Vector2 = _knockback_direction(attacker_position, enemy.get("position", attacker_position))
	var final_knockback: float = knockback_amount
	if int(enemy["hp"]) <= 0:
		enemy["dead"] = true
		final_knockback = sign(knockback_amount) * max(absf(knockback_amount), 15.0)
		if is_zero_approx(final_knockback):
			final_knockback = 15.0
	if not is_zero_approx(final_knockback):
		enemy["knockback_vector"] = direction * final_knockback
	return {
		"damage": actual_damage,
		"dead": bool(enemy.get("dead", false)),
		"knockback_vector": enemy.get("knockback_vector", Vector2.ZERO),
	}

func enemy_knockback_velocity(enemy: Dictionary) -> Vector2:
	var knockback_vector: Vector2 = enemy.get("knockback_vector", Vector2.ZERO)
	var resistance: float = clamp(float(enemy.get("knockback_resistance", 0.0)), 0.0, 1.0)
	return knockback_vector * (100.0 - resistance * 100.0)

func decay_enemy_knockback(enemy: Dictionary) -> void:
	var knockback_vector: Vector2 = enemy.get("knockback_vector", Vector2.ZERO)
	if knockback_vector.length_squared() <= 0.0001:
		enemy["knockback_vector"] = Vector2.ZERO
		return
	enemy["knockback_vector"] = knockback_vector.lerp(Vector2.ZERO, KNOCKBACK_DECAY)

func enemy_can_contact_damage(enemy: Dictionary) -> bool:
	return enemy_knockback_velocity(enemy).length() <= float(enemy.get("speed", 0.0))

func enemy_is_touching_player(enemy: Dictionary, player_position: Vector2) -> bool:
	var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
	return enemy_position.distance_to(player_position) <= CONTACT_RADIUS

func should_drop_enemy_material(enemy: Dictionary, wave: int, is_horde_wave: bool = false, drop_roll: float = -1.0) -> bool:
	if not bool(enemy.get("can_drop_material", true)):
		return false
	return _probability_roll(formulas.enemy_material_drop_chance(wave, is_horde_wave), drop_roll)

func enemy_material_value(enemy: Dictionary, fractional_roll: float = -1.0) -> int:
	var base_value := maxi(0, int(enemy.get("value", 1)))
	if base_value <= 0:
		return 0
	var drop_percent: float = player_data.get_stat("gold_drops") + player_data.get_stat("enemy_gold_drops")
	var raw_value: float = max(0.5 * float(base_value), float(base_value) * (1.0 + drop_percent / 100.0))
	var whole := floori(raw_value)
	var fraction: float = raw_value - float(whole)
	if fraction > 0.0 and _probability_roll(fraction, fractional_roll):
		whole += 1
	return maxi(0, whole)

func spawn_material_from_enemy(enemy: Dictionary, materials: Array, wave: int, is_horde_wave: bool = false, drop_roll: float = -1.0, fractional_roll: float = -1.0, merge_index: int = -1) -> bool:
	if not should_drop_enemy_material(enemy, wave, is_horde_wave, drop_roll):
		return false
	var value: int = enemy_material_value(enemy, fractional_roll)
	if value <= 0:
		return false
	add_material_drop(materials, enemy.get("position", Vector2.ZERO), value, merge_index)
	return true

func add_material_drop(materials: Array, position: Vector2, value: int, merge_index: int = -1) -> Dictionary:
	var final_value: int = _apply_bonus_gold(value)
	if final_value <= 0:
		return {}
	if materials.size() >= MATERIAL_ENTITY_LIMIT:
		var index := merge_index
		if index < 0 or index >= materials.size():
			index = randi() % materials.size()
		var existing: Dictionary = materials[index]
		existing["value"] = int(existing.get("value", 0)) + final_value
		existing["scale"] = min(MATERIAL_MAX_SCALE, float(existing.get("scale", 1.0)) + MATERIAL_SCALE_STEP * float(final_value))
		return existing
	var material: Dictionary = make_material(position, final_value)
	materials.append(material)
	return material

func make_material(position: Vector2, value: int) -> Dictionary:
	return {
		"position": position,
		"value": maxi(0, value),
		"flight_time": 0.0,
		"scale": 1.0,
	}

func update_material_attraction(material: Dictionary, player_position: Vector2, delta: float, double_roll: float = -1.0, heal_roll: float = -1.0) -> Dictionary:
	var material_position: Vector2 = material.get("position", Vector2.ZERO)
	var distance := material_position.distance_to(player_position)
	if distance <= PLAYER_PICKUP_RADIUS:
		return collect_material(material, double_roll, heal_roll)
	if distance <= formulas.pickup_radius(player_data.get_stat("pickup_range")):
		var flight_time := float(material.get("flight_time", 0.0))
		var speed: float = formulas.pickup_flight_speed(MATERIAL_ATTRACT_INITIAL_SPEED, MATERIAL_ATTRACT_ACCELERATION, flight_time)
		material["flight_time"] = flight_time + delta
		material["position"] = material_position + (player_position - material_position).normalized() * speed * delta
		return {"collected": false, "attracting": true}
	material["flight_time"] = 0.0
	return {"collected": false, "attracting": false}

func update_materials(materials: Array, player_position: Vector2, delta: float) -> Array:
	var events: Array = []
	for material in materials.duplicate():
		var material_data: Dictionary = material
		var event: Dictionary = update_material_attraction(material_data, player_position, delta)
		if bool(event.get("collected", false)):
			materials.erase(material)
			events.append(event)
	return events

func collect_material(material: Dictionary, double_roll: float = -1.0, heal_roll: float = -1.0) -> Dictionary:
	var value := maxi(0, roundi(float(material.get("value", 0)) * (1.0 + player_data.get_stat("increase_material_value") / 100.0)))
	if _percent_roll(player_data.get_stat("chance_double_gold"), double_roll):
		value *= 2
	player_data.materials += value
	var gained_levels: int = player_data.gain_xp(value)
	var healed := 0
	if _percent_roll(player_data.get_stat("heal_when_pickup_gold"), heal_roll):
		healed = heal_player(1)
	return {
		"collected": true,
		"value": value,
		"gained_levels": gained_levels,
		"healed": healed,
	}

func complete_wave(enemies: Array, materials: Array, living_trees: int = 0, charmed_enemy_materials: int = 0) -> Dictionary:
	if state != STATE_RUNNING:
		return {"completed": false, "state": state}
	var settlement: Dictionary = settle_wave(enemies.size(), materials, living_trees, charmed_enemy_materials)
	enemies.clear()
	if current_wave >= highest_wave:
		state = STATE_WON
	else:
		current_wave += 1
	settlement["completed"] = true
	settlement["state"] = state
	settlement["next_wave"] = current_wave
	return settlement

func settle_wave(living_enemies: int, materials: Array, living_trees: int = 0, charmed_enemy_materials: int = 0) -> Dictionary:
	# Docs: 07 §7 requires timer-end cleanup, harvest settlement, and unpicked material recovery before the next state.
	var recovered_materials: int = _recover_ground_materials(materials)
	var harvest_value: int = formulas.harvest_value(
		player_data.get_stat("stat_harvesting"),
		living_enemies,
		player_data.get_stat("pacifist"),
		living_trees,
		int(player_data.get_stat("cryptid")),
		int(player_data.get_stat("materials_per_living_enemy")),
		charmed_enemy_materials
	)
	var gained_levels := 0
	if harvest_value >= 0:
		player_data.materials += harvest_value
		gained_levels = player_data.gain_xp(harvest_value)
	else:
		player_data.materials = maxi(0, player_data.materials + harvest_value)
	var harvesting_growth: int = formulas.harvesting_growth_delta(
		player_data.get_permanent_stat("stat_harvesting"),
		player_data.get_stat("harvesting_growth"),
		current_wave
	)
	if harvesting_growth != 0:
		player_data.add_permanent_stat("stat_harvesting", harvesting_growth)
	player_data.clear_temporary_stats()
	iframe_seconds_remaining = 0.0
	hit_protection_charges = 0
	return {
		"harvest": harvest_value,
		"harvest_levels": gained_levels,
		"harvesting_growth": harvesting_growth,
		"recovered_materials": recovered_materials,
		"bonus_gold": bonus_gold,
	}

func get_ui_state(enemy_count: int = 0, ground_material_count: int = 0) -> Dictionary:
	return {
		"state": state,
		"wave": current_wave,
		"danger": current_danger,
		"health": player_data.current_health,
		"max_health": player_data.get_max_health(),
		"materials": player_data.materials,
		"level": player_data.level,
		"xp": player_data.current_xp,
		"iframes": iframe_seconds_remaining,
		"hit_protection": hit_protection_charges,
		"bonus_gold": bonus_gold,
		"enemies": enemy_count,
		"ground_materials": ground_material_count,
	}

func _damage_result(accepted: bool, reason: String, damage_taken: int, dodged: bool, blocked: bool) -> Dictionary:
	last_damage_result = {
		"accepted": accepted,
		"reason": reason,
		"damage": damage_taken,
		"dodged": dodged,
		"blocked": blocked,
		"health": player_data.current_health if player_data != null else 0,
		"state": state,
		"iframes": iframe_seconds_remaining,
	}
	return last_damage_result

func _wave_start_health_percent() -> float:
	var next_percent := float(player_data.effects.get("hp_start_next_wave", 100))
	var start_percent := float(player_data.effects.get("hp_start_wave", 100))
	if not is_equal_approx(next_percent, 100.0):
		player_data.effects["hp_start_next_wave"] = 100
		player_data.invalidate_cache()
		return next_percent
	return start_percent

func _knockback_direction(attacker_position: Vector2, enemy_position: Vector2) -> Vector2:
	var direction := enemy_position - attacker_position
	if direction.length_squared() <= 0.0001:
		return Vector2.RIGHT
	return direction.normalized()

func _apply_bonus_gold(value: int) -> int:
	var final_value := maxi(0, value)
	var bonus := mini(final_value, bonus_gold)
	bonus_gold -= bonus
	return final_value + bonus

func _recover_ground_materials(materials: Array) -> int:
	var recovered := 0
	for material in materials:
		var material_data: Dictionary = material
		recovered += int(material_data.get("value", 0))
	materials.clear()
	bonus_gold += recovered
	return recovered

func _probability_roll(chance: float, roll: float = -1.0) -> bool:
	if chance <= 0.0:
		return false
	var actual_roll := randf() if roll < 0.0 else roll
	return formulas.generic_probability_succeeds(chance, actual_roll)

func _percent_roll(chance_percent: float, roll: float = -1.0) -> bool:
	return _probability_roll(chance_percent / 100.0, roll)
