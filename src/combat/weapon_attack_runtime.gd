class_name WeaponAttackRuntime
extends RefCounted

const BurnDataScript = preload("res://src/core/burn_data.gd")
const FormulasScript = preload("res://src/core/formulas.gd")
const TargetingScript = preload("res://src/combat/targeting.gd")
const WeaponStatsScript = preload("res://src/combat/weapon_stats.gd")

const TICKS_PER_SECOND := 60.0
const OPENING_COOLDOWN_MAX_TICKS := 180.0
const BOUNCE_LIFETIME_DISTANCE := 10000.0
const MELEE_SWEEP_MIN_DISTANCE := 250.0
const SWEEP_HALF_ARC_RADIANS := 0.9 * PI

var formulas: Variant = FormulasScript.new()

func tick_cooldown(cooldown_ticks: float, delta_seconds: float, attack_active: bool = false) -> float:
	if attack_active:
		return cooldown_ticks
	return max(0.0, cooldown_ticks - delta_seconds * TICKS_PER_SECOND)

func opening_cooldown_ticks(weapon: Variant, player: Variant) -> float:
	return min(OPENING_COOLDOWN_MAX_TICKS, weapon.resolved_cooldown_ticks(player))

func next_cooldown_ticks(weapon: Variant, player: Variant, attack_index: int = 0, options: Dictionary = {}) -> float:
	var cooldown: float = weapon.resolved_cooldown_ticks(player)
	if weapon.additional_cooldown_every > 0 and weapon.additional_cooldown_multiplier > 0.0 and attack_index > 0:
		if attack_index % weapon.additional_cooldown_every == 0:
			cooldown *= weapon.additional_cooldown_multiplier
	if weapon.cooldown_random_ticks > 0.0:
		var min_cooldown: float = max(1.0, cooldown - weapon.cooldown_random_ticks)
		var max_cooldown: float = cooldown + weapon.cooldown_random_ticks
		cooldown = _take_float(options, "cooldown_roll", randf_range(min_cooldown, max_cooldown))
	return max(2.0, cooldown)

func can_start_attack(weapon: Variant, player: Variant, enemies: Array, origin: Vector2, cooldown_ticks: float, movement: Vector2 = Vector2.ZERO, manual_aim: bool = false) -> Dictionary:
	if cooldown_ticks > 0.0:
		return {"can_attack": false, "reason": "cooldown", "target": null}
	if movement != Vector2.ZERO and int(player.effects.get("can_attack_while_moving", 1)) <= 0:
		return {"can_attack": false, "reason": "moving", "target": null}
	if manual_aim:
		return {"can_attack": true, "reason": "manual_aim", "target": null}
	var target: Variant = TargetingScript.nearest_enemy(enemies, origin, weapon.detection_range(player), weapon.resolved_min_range())
	if target == null:
		return {"can_attack": false, "reason": "no_target", "target": null}
	var distance: float = origin.distance_to(target.get("position", origin))
	if not weapon.can_attack_target(distance, player):
		return {"can_attack": false, "reason": "target_out_of_attack_range", "target": target}
	return {"can_attack": true, "reason": "ready", "target": target}

func start_attack(weapon: Variant, player: Variant, origin: Vector2, aim_angle: float, target_distance: float, attack_id: int, manual_aim: bool = false, options: Dictionary = {}) -> Dictionary:
	var attack_index: int = int(options.get("attack_index", attack_id))
	var accuracy_offset: float = _take_float(options, "accuracy_offset", randf_range(-1.0 + weapon.accuracy, 1.0 - weapon.accuracy))
	var facing_angle: float = aim_angle + accuracy_offset
	var packet: Dictionary = build_hit_packet(weapon, player, attack_id)
	var attack: Dictionary = {
		"attack_id": attack_id,
		"weapon_id": weapon.weapon_id,
		"weapon_type": weapon.type,
		"attack_type": actual_attack_type(weapon, attack_index),
		"origin": origin,
		"aim_angle": aim_angle,
		"facing_angle": facing_angle,
		"accuracy_offset": accuracy_offset,
		"cooldown_ticks": next_cooldown_ticks(weapon, player, attack_index, options),
		"hit_packet": packet,
		"windows": attack_windows(weapon, player, target_distance, attack_index),
		"projectiles": [],
	}
	if weapon.type == WeaponStatsScript.TYPE_RANGED:
		attack["projectiles"] = build_projectiles(weapon, player, origin, facing_angle, packet, attack_id, manual_aim, options)
	return attack

func actual_attack_type(weapon: Variant, attack_index: int) -> String:
	if not weapon.alternate_attack_type:
		return weapon.attack_type
	if attack_index % 2 == 0:
		return weapon.attack_type
	return WeaponStatsScript.ATTACK_SWEEP if weapon.attack_type == WeaponStatsScript.ATTACK_THRUST else WeaponStatsScript.ATTACK_THRUST

func attack_windows(weapon: Variant, player: Variant, target_distance: float, attack_index: int = 0) -> Dictionary:
	if weapon.type != WeaponStatsScript.TYPE_MELEE:
		return {
			"total_seconds": 0.0,
			"active_windows": [],
			"phases": [],
			"reach": weapon.resolved_range(player),
			"arc_radians": 0.0,
		}
	var attack_type: String = actual_attack_type(weapon, attack_index)
	var reach: float = weapon.resolved_range(player)
	var distance_for_duration: float = target_distance
	var arc: float = 0.0
	if attack_type == WeaponStatsScript.ATTACK_SWEEP:
		distance_for_duration = min(reach, max(MELEE_SWEEP_MIN_DISTANCE, target_distance))
		arc = SWEEP_HALF_ARC_RADIANS
	var duration: float = weapon.attack_duration_seconds(player, distance_for_duration)
	var active_end: float = duration if weapon.deal_dmg_on_return else duration * 0.5
	var phases: Array = []
	if attack_type == WeaponStatsScript.ATTACK_SWEEP:
		phases.append({"name": "orientation_setup", "start": 0.0, "end": 0.0, "active": false})
		phases.append({"name": "sweep_first_quarter", "start": 0.0, "end": duration * 0.25, "active": true})
		phases.append({"name": "sweep_second_quarter", "start": duration * 0.25, "end": duration * 0.5, "active": true})
		phases.append({"name": "return", "start": duration * 0.5, "end": duration, "active": weapon.deal_dmg_on_return})
	else:
		phases.append({"name": "thrust_out", "start": 0.0, "end": duration * 0.5, "active": true})
		phases.append({"name": "return", "start": duration * 0.5, "end": duration, "active": weapon.deal_dmg_on_return})
	return {
		"total_seconds": duration,
		"active_windows": [[0.0, active_end]],
		"phases": phases,
		"reach": distance_for_duration if attack_type == WeaponStatsScript.ATTACK_SWEEP else reach,
		"arc_radians": arc,
	}

func build_hit_packet(weapon: Variant, player: Variant, attack_id: int = 0, set_bonus_percent: float = 0.0) -> Dictionary:
	var vulnerability_effects: Array = []
	vulnerability_effects.append_array(player.effects.get("enemy_percent_damage_taken", []))
	vulnerability_effects.append_array(weapon.vulnerability_effects)
	var burn_data: Variant = build_burn_data(weapon, player)
	return {
		"attack_id": attack_id,
		"weapon_id": weapon.weapon_id,
		"damage": weapon.resolved_damage(player, set_bonus_percent),
		"crit_chance": weapon.effective_crit_chance(player),
		"crit_damage": weapon.crit_damage,
		"lifesteal": weapon.effective_lifesteal(player),
		"knockback": weapon.resolved_knockback(player),
		"knockback_piercing": weapon.knockback_piercing,
		"effect_scale": weapon.effect_scale,
		"burn_data": burn_data,
		"can_burn": int(player.effects.get("can_burn_enemies", 1)) > 0,
		"explosion_chance": weapon.explosion_chance,
		"explosion_scale": weapon.explosion_scale,
		"is_healing": weapon.is_healing,
		"speed_percent_modifier": weapon.speed_percent_modifier,
		"scaling_stats": weapon.scaling_stats.duplicate(true),
		"vulnerability_effects": vulnerability_effects,
		"presentation_hooks": ["damage_number", "flash", "hit_effect", "hit_sound"],
	}

func build_burn_data(weapon: Variant, player: Variant) -> Variant:
	var weapon_burn: Variant = _burn_from_variant(weapon.burning_data)
	var global_burn: Variant = _burn_from_variant(player.effects.get("burn_chance", {}))
	if weapon_burn.is_empty() and global_burn.is_empty():
		return null
	var result: Variant
	if weapon_burn.is_empty():
		result = global_burn.duplicate_data()
		result.is_global_burn = true
	else:
		result = weapon_burn.duplicate_data()
		result.damage += global_burn.damage
	result.damage = _scaled_burn_damage(result, player)
	result.spread += roundi(player.get_stat("burning_spread"))
	return result

func build_projectiles(weapon: Variant, player: Variant, origin: Vector2, facing_angle: float, packet: Dictionary, attack_id: int, manual_aim: bool = false, options: Dictionary = {}) -> Array:
	var projectiles: Array = []
	var count: int = weapon.effective_projectile_count(player)
	var speed: float = weapon.effective_projectile_speed(player)
	var spread: float = weapon.effective_projectile_spread(player)
	for i in count:
		var spread_offset: float = _take_indexed_float(options, "projectile_spread_offsets", i, randf_range(-spread, spread))
		var projectile_angle: float = facing_angle + spread_offset
		projectiles.append({
			"attack_id": attack_id,
			"weapon_id": weapon.weapon_id,
			"position": origin,
			"angle": projectile_angle,
			"velocity": Vector2.RIGHT.rotated(projectile_angle) * speed,
			"speed": speed,
			"remaining_lifetime": weapon.projectile_lifetime_seconds(player, manual_aim),
			"damage": packet["damage"],
			"hit_packet": packet.duplicate(true),
			"piercing_remaining": weapon.effective_piercing(player),
			"piercing_damage_reduction": weapon.effective_piercing_damage_reduction(player),
			"bounce_remaining": weapon.effective_bounce(player),
			"bounce_damage_reduction": weapon.effective_bounce_damage_reduction(player),
			"pierce_on_crit_remaining": maxi(0, weapon.pierce_on_crit + roundi(player.get_stat("pierce_on_crit"))),
			"bounce_on_crit_remaining": maxi(0, weapon.bounce_on_crit + roundi(player.get_stat("bounce_on_crit"))),
			"knockback": packet["knockback"],
			"ignored_enemy_ids": [],
			"stopped": false,
		})
	return projectiles

func advance_projectile(projectile: Dictionary, delta_seconds: float) -> bool:
	if bool(projectile.get("stopped", false)):
		return false
	projectile["position"] = projectile.get("position", Vector2.ZERO) + projectile.get("velocity", Vector2.ZERO) * delta_seconds
	projectile["remaining_lifetime"] = float(projectile.get("remaining_lifetime", 0.0)) - delta_seconds
	if float(projectile["remaining_lifetime"]) <= 0.0:
		projectile["stopped"] = true
		return false
	return true

func apply_attack_to_target(attack: Dictionary, enemy: Dictionary, player: Variant, options: Dictionary = {}) -> Dictionary:
	var packet: Dictionary = attack.get("hit_packet", {}).duplicate(true)
	return apply_hit_packet(packet, enemy, player, options)

func apply_projectile_hit(projectile: Dictionary, enemy: Dictionary, player: Variant, enemies: Array = [], options: Dictionary = {}) -> Dictionary:
	var enemy_id: String = String(enemy.get("id", enemy.get("instance_id", "")))
	if projectile.get("ignored_enemy_ids", []).has(enemy_id):
		return {"hit": false, "reason": "ignored", "projectile": projectile}
	var hit_origin: Vector2 = projectile.get("position", Vector2.ZERO)
	var packet: Dictionary = projectile.get("hit_packet", {}).duplicate(true)
	packet["damage"] = int(projectile.get("damage", packet.get("damage", 1)))
	packet["knockback"] = float(projectile.get("knockback", packet.get("knockback", 0.0)))
	var result: Dictionary = apply_hit_packet(packet, enemy, player, options)
	result["knockback_origin"] = hit_origin
	if not bool(result.get("hit", false)):
		result["projectile"] = projectile
		return result
	projectile["position"] = enemy.get("position", projectile.get("position", Vector2.ZERO))
	projectile["ignored_enemy_ids"].append(enemy_id)
	if bool(result.get("critical", false)):
		if int(projectile.get("bounce_on_crit_remaining", 0)) > 0:
			projectile["bounce_remaining"] = int(projectile.get("bounce_remaining", 0)) + 1
			projectile["bounce_on_crit_remaining"] = int(projectile["bounce_on_crit_remaining"]) - 1
		if int(projectile.get("pierce_on_crit_remaining", 0)) > 0:
			projectile["piercing_remaining"] = int(projectile.get("piercing_remaining", 0)) + 1
			projectile["pierce_on_crit_remaining"] = int(projectile["pierce_on_crit_remaining"]) - 1
	if int(projectile.get("bounce_remaining", 0)) > 0:
		projectile["bounce_remaining"] = int(projectile["bounce_remaining"]) - 1
		projectile["damage"] = _reduced_damage(int(projectile.get("damage", 1)), float(projectile.get("bounce_damage_reduction", 0.0)))
		projectile["knockback"] = 0.0
		_redirect_projectile_after_bounce(projectile, enemy, enemies, options)
	elif int(projectile.get("piercing_remaining", 0)) <= 0:
		projectile["stopped"] = true
	else:
		projectile["piercing_remaining"] = int(projectile["piercing_remaining"]) - 1
		projectile["damage"] = _reduced_damage(int(projectile.get("damage", 1)), float(projectile.get("piercing_damage_reduction", 0.0)))
	result["projectile"] = projectile
	return result

func apply_hit_packet(packet: Dictionary, enemy: Dictionary, player: Variant, options: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		"hit": false,
		"critical": false,
		"damage_before_armor": 0,
		"direct_damage": 0,
		"knockback": float(packet.get("knockback", 0.0)),
		"killed": false,
		"lifesteal_heal": 0,
		"burn_applied": false,
		"vulnerability_percent": 0.0,
		"vulnerability_hooks": [],
		"explosion": null,
		"presentation_events": [],
	}
	if enemy.is_empty() or bool(enemy.get("dead", false)):
		result["reason"] = "invalid_enemy"
		return result
	result["hit"] = true
	result["lifesteal_heal"] = _try_lifesteal(packet, player, options)
	var explosion_chance: float = float(packet.get("explosion_chance", 0.0))
	if explosion_chance > 0.0 and _take_float(options, "explosion_roll", randf()) <= explosion_chance:
		result["explosion"] = {
			"position": enemy.get("position", Vector2.ZERO),
			"damage": int(packet.get("damage", 1)),
			"scale": float(packet.get("explosion_scale", 0.0)),
			"hit_packet": packet.duplicate(true),
		}
		result["presentation_events"].append("explosion_spawn")
		return result
	var forced_crit: bool = bool(packet.get("crit_on_hitting_burning_target", false)) and bool(enemy.get("burning", false))
	var critical: bool = forced_crit or _take_float(options, "crit_roll", randf()) <= float(packet.get("crit_chance", 0.0))
	result["critical"] = critical
	var damage: int = int(packet.get("damage", 1))
	if critical:
		damage = maxi(1, roundi(float(damage) * float(packet.get("crit_damage", 1.0))))
	var vulnerability: Dictionary = _collect_vulnerability(packet, enemy)
	result["vulnerability_percent"] = vulnerability["percent"]
	result["vulnerability_hooks"] = vulnerability["hooks"]
	if not is_zero_approx(float(vulnerability["percent"])):
		damage = maxi(1, roundi(float(damage) * (1.0 + float(vulnerability["percent"]) / 100.0)))
	result["damage_before_armor"] = damage
	var burn_data: Variant = packet.get("burn_data", null)
	if burn_data != null and bool(packet.get("can_burn", true)) and not bool(packet.get("is_healing", false)):
		if _take_float(options, "burn_roll", randf()) <= burn_data.chance:
			_apply_burn(enemy, burn_data)
			result["burn_applied"] = true
			result["presentation_events"].append("burn_applied")
	if bool(packet.get("is_healing", false)):
		result["healing_amount"] = damage
		return result
	var direct_damage: int = formulas.enemy_damage_after_armor(damage, int(enemy.get("armor", 0)))
	result["direct_damage"] = direct_damage
	result["presentation_events"].append_array(packet.get("presentation_hooks", []))
	if int(enemy.get("hp", 0)) - direct_damage <= 0:
		result["killed"] = true
	return result

func _try_lifesteal(packet: Dictionary, player: Variant, options: Dictionary) -> int:
	var chance: float = float(packet.get("lifesteal", 0.0))
	if chance <= 0.0 or player == null:
		return 0
	if _take_float(options, "lifesteal_roll", randf()) >= chance:
		return 0
	if player.get_stat("no_heal") > 0.0:
		return 0
	var amount: int = 2 if player.get_stat("stat_double_lifesteal_bonus") > 0.0 else 1
	var before: int = player.current_health
	player.current_health = mini(player.get_max_health(), player.current_health + amount)
	return player.current_health - before

func _collect_vulnerability(packet: Dictionary, enemy: Dictionary) -> Dictionary:
	var hooks: Array = []
	var percent: float = float(enemy.get("vulnerability_percent", enemy.get("percent_damage_taken", 0.0)))
	for hook in packet.get("vulnerability_effects", []):
		var normalized: Dictionary = _normalize_vulnerability_hook(hook)
		if normalized.is_empty():
			continue
		if _hook_matches_packet(normalized, packet):
			hooks.append(normalized)
			percent += float(normalized.get("value", 0.0))
	return {"percent": percent, "hooks": hooks}

func _normalize_vulnerability_hook(hook: Variant) -> Dictionary:
	if hook is Dictionary:
		return hook.duplicate(true)
	if hook is Array:
		if hook.size() >= 3:
			return {"source": String(hook[0]), "key": String(hook[1]), "value": float(hook[2])}
		if hook.size() >= 2:
			return {"source": "", "key": String(hook[0]), "value": float(hook[1])}
	return {}

func _hook_matches_packet(hook: Dictionary, packet: Dictionary) -> bool:
	var key: String = String(hook.get("key", ""))
	if key.is_empty() or key == "all":
		return true
	return packet.get("scaling_stats", {}).has(key)

func _apply_burn(enemy: Dictionary, burn_data: Variant) -> void:
	var incoming: Variant = burn_data.duplicate_data()
	if enemy.has("burn_data") and enemy["burn_data"] != null:
		var existing: Variant = _burn_from_variant(enemy["burn_data"])
		enemy["burn_data"] = existing.merged_enemy_burn(existing, incoming)
	else:
		enemy["burn_data"] = incoming
	enemy["burning"] = true

func _redirect_projectile_after_bounce(projectile: Dictionary, hit_enemy: Dictionary, enemies: Array, options: Dictionary) -> void:
	var speed: float = float(projectile.get("speed", 0.0))
	if speed <= 0.0:
		projectile["stopped"] = true
		return
	projectile["remaining_lifetime"] = BOUNCE_LIFETIME_DISTANCE / speed
	var target: Variant = _choose_bounce_target(projectile, hit_enemy, enemies, options)
	var direction: Vector2 = Vector2.ZERO
	if target != null:
		direction = (target.get("position", projectile.get("position", Vector2.ZERO)) - projectile.get("position", Vector2.ZERO)).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT.rotated(_take_float(options, "bounce_angle", randf() * TAU))
	projectile["velocity"] = direction * speed
	projectile["angle"] = direction.angle()
	projectile["stopped"] = false

func _choose_bounce_target(projectile: Dictionary, hit_enemy: Dictionary, enemies: Array, options: Dictionary) -> Variant:
	var ignored: Array = projectile.get("ignored_enemy_ids", [])
	var candidates: Array = []
	for enemy in enemies:
		var enemy_data: Dictionary = enemy
		var enemy_id: String = String(enemy_data.get("id", enemy_data.get("instance_id", "")))
		if enemy_data == hit_enemy or bool(enemy_data.get("dead", false)) or ignored.has(enemy_id):
			continue
		candidates.append(enemy_data)
	if candidates.is_empty():
		return null
	if options.has("bounce_target_id"):
		var requested: String = String(options["bounce_target_id"])
		for candidate in candidates:
			if String(candidate.get("id", candidate.get("instance_id", ""))) == requested:
				return candidate
	var index: int = int(_take_float(options, "bounce_target_index", randi() % candidates.size()))
	return candidates[clampi(index, 0, candidates.size() - 1)]

func _reduced_damage(current_damage: int, reduction: float) -> int:
	return maxi(1, roundi(float(current_damage) * (1.0 - clamp(reduction, 0.0, 1.0))))

func _scaled_burn_damage(burn_data: Variant, player: Variant) -> int:
	var damage: float = float(burn_data.damage)
	for stat_key in burn_data.scaling_stats.keys():
		damage += player.get_stat(String(stat_key)) * float(burn_data.scaling_stats[stat_key])
	damage = max(1.0, damage)
	return maxi(1, roundi(damage * (1.0 + player.get_stat("stat_percent_damage") / 100.0)))

func _burn_from_variant(value: Variant) -> Variant:
	if value is Object and value.has_method("duplicate_data"):
		return value.duplicate_data()
	var burn: Variant = BurnDataScript.new()
	if value is Dictionary:
		burn.chance = float(value.get("chance", 0.0))
		burn.damage = int(value.get("damage", 0))
		burn.duration = int(value.get("duration", 0))
		burn.spread = int(value.get("spread", 0))
		burn.scaling_stats = value.get("scaling_stats", {"stat_elemental_damage": 1.0}).duplicate(true)
		burn.is_global_burn = bool(value.get("is_global_burn", false))
		burn.source_id = String(value.get("source_id", ""))
	return burn

func _take_float(options: Dictionary, key: String, fallback: float) -> float:
	if not options.has(key):
		return fallback
	var value: Variant = options[key]
	if value is Array:
		if value.is_empty():
			return fallback
		return float(value.pop_front())
	return float(value)

func _take_indexed_float(options: Dictionary, key: String, index: int, fallback: float) -> float:
	if not options.has(key):
		return fallback
	var value: Variant = options[key]
	if value is Array:
		if index < value.size():
			return float(value[index])
		return fallback
	return float(value)
