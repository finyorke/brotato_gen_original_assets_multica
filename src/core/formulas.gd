class_name Formulas
extends RefCounted

const SHOP_TIER_PARAMS := {
	0: {"min_wave": 0, "base": 1.0, "increment": 0.0, "cap": 1.0},
	1: {"min_wave": 0, "base": 0.0, "increment": 0.06, "cap": 0.60},
	2: {"min_wave": 2, "base": 0.0, "increment": 0.02, "cap": 0.25},
	3: {"min_wave": 6, "base": 0.0, "increment": 0.0023, "cap": 0.08},
}

func weapon_damage(base_damage: float, scaling_stats: Dictionary, player: Variant, set_bonus_percent: float = 0.0, include_explosion_bonus: bool = false) -> int:
	var scaled: float = float(base_damage)
	for stat_key in scaling_stats.keys():
		scaled += player.get_stat(String(stat_key)) * float(scaling_stats[stat_key])
	scaled = max(1.0, scaled)
	var multiplier: float = 1.0 + player.get_stat("stat_percent_damage") / 100.0 + set_bonus_percent / 100.0
	if include_explosion_bonus:
		multiplier += player.get_stat("explosion_damage") / 100.0
	return maxi(1, roundi(scaled * multiplier))

func explosion_damage(base_damage: float, scaling_stats: Dictionary, player: Variant) -> int:
	return weapon_damage(base_damage, scaling_stats, player, 0.0, true)

func weapon_cooldown(base_cooldown_ticks: float, attack_speed_percent: float, attack_speed_mod_percent: float = 0.0) -> float:
	var base: float = max(2.0, base_cooldown_ticks)
	var atk_spd: float = (attack_speed_percent + attack_speed_mod_percent) / 100.0
	if atk_spd >= 0.0:
		return max(2.0, base / (1.0 + atk_spd))
	return max(2.0, base * (1.0 + abs(atk_spd)))

func ranged_weapon_range(base_range: float, stat_range: float) -> float:
	return max(25.0, base_range + stat_range)

func melee_weapon_range(base_range: float, stat_range: float) -> float:
	return max(25.0, base_range + stat_range / 2.0)

func armor_coef(armor: float) -> float:
	var positive_curve: float = 10.0 / (10.0 + abs(armor) / 1.5)
	if armor >= 0.0:
		return positive_curve
	return (1.0 - positive_curve) + 1.0

func player_damage_after_armor(raw_damage: int, armor: float, ignores_armor: bool = false) -> int:
	if ignores_armor:
		return maxi(1, raw_damage)
	return maxi(1, roundi(float(raw_damage) * armor_coef(armor)))

func enemy_damage_after_armor(raw_damage: int, enemy_armor: int) -> int:
	return maxi(1, raw_damage - enemy_armor)

func hp_regen_interval_seconds(hp_regeneration: float) -> float:
	if hp_regeneration <= 0.0:
		return 99.0
	return 5.0 / (1.0 + (hp_regeneration - 1.0) / 2.25)

func lifesteal_can_trigger(now_seconds: float, last_trigger_seconds: float) -> bool:
	return now_seconds - last_trigger_seconds >= 0.1

func xp_required_for_level(level: int) -> int:
	return int(pow(3 + level, 2))

func next_level_xp_needed(current_level: int, next_level_xp_needed_percent: float = 0.0) -> float:
	return float(xp_required_for_level(current_level + 1)) * (1.0 + next_level_xp_needed_percent / 100.0)

func shop_tier_chance(tier: int, wave_or_level: int, luck_percent: float = 0.0) -> float:
	var params: Dictionary = SHOP_TIER_PARAMS[tier]
	var wave_base: float = max(0.0, float(wave_or_level - 1 - int(params["min_wave"]))) * float(params["increment"])
	var luck: float = luck_percent / 100.0
	var wave_chance: float = wave_base * (1.0 + luck) if luck >= 0.0 else wave_base / (1.0 + abs(luck))
	return min(float(params["base"]) + wave_chance, float(params["cap"]))

func reroll_price(wave: int, paid_rerolls: int, reroll_price_percent: float = 0.0, endless_factor: float = 0.0) -> int:
	var delta := int(max(1.0, 0.4 * float(wave) * sqrt(1.0 + endless_factor)))
	var raw_price := int(float(wave) * 0.75) + delta * (1 + paid_rerolls)
	return ceili(float(raw_price) * max(0.1, 1.0 + reroll_price_percent / 100.0))

func enemy_hp(base_hp: float, hp_per_wave: float, wave: int, enemy_health_percent: float = 0.0, difficulty_coefficient: float = 1.0, player_count: int = 1, endless_factor: float = 0.0) -> int:
	var coop_multiplier := 1.0 + 0.3 * float(maxi(1, player_count) - 1)
	var endless_multiplier := 1.0 + endless_factor
	return roundi((base_hp + hp_per_wave * float(wave - 1)) * (1.0 + enemy_health_percent / 100.0) * difficulty_coefficient * coop_multiplier * endless_multiplier)

func enemy_damage(base_damage: float, damage_per_wave: float, wave: int, enemy_damage_percent: float = 0.0, difficulty_coefficient: float = 1.0, endless_factor: float = 0.0) -> int:
	var endless_multiplier := 1.0 + endless_factor
	return maxi(1, roundi((base_damage + damage_per_wave * float(wave - 1)) * (1.0 + enemy_damage_percent / 100.0) * difficulty_coefficient * endless_multiplier))

func enemy_armor(base_armor: float, armor_per_wave: float, wave: int, armor_percent_modifier: float = 0.0) -> int:
	return roundi((base_armor + armor_per_wave * float(wave - 1)) * (1.0 + armor_percent_modifier / 100.0))

func danger_enemy_stat_multiplier(danger: int) -> float:
	match danger:
		3:
			return 1.12
		4:
			return 1.26
		5:
			return 1.40
	return 1.0

func enemy_material_drop_chance(wave: int, is_horde_wave: bool = false) -> float:
	var chance: float = 1.0 if wave < 5 else max(0.5, 1.0 - float(wave) * 0.015)
	if is_horde_wave:
		chance *= 0.65
	return chance

func spawn_count(min_count: int, max_count: int, unit_spawn_rate: float = 1.0, player_count: int = 1, number_of_enemies_percent: float = 0.0, fractional_roll: float = -1.0, number_roll: Variant = null) -> int:
	var min_number := mini(min_count, max_count)
	var max_number := maxi(min_count, max_count)
	var rolled_number: int
	if min_number == max_number:
		rolled_number = min_number
	elif number_roll == null:
		rolled_number = randi_range(min_number, max_number)
	else:
		rolled_number = clampi(int(number_roll), min_number, max_number)
	var base_count: float = float(rolled_number)
	var coop_multiplier: float = 1.0 + 0.3 * float(maxi(1, player_count) - 1)
	var value: float = base_count * unit_spawn_rate * coop_multiplier * (1.0 + number_of_enemies_percent / 100.0)
	var whole: int = floori(value)
	var fractional: float = value - float(whole)
	var roll := randf() if fractional_roll < 0.0 else fractional_roll
	var fractional_bonus := 1 if fractional > 0.0 and roll <= fractional else 0
	return maxi(0, whole + fractional_bonus)

func pickup_radius(pickup_range_percent: float) -> float:
	return max(30.0, 150.0 * (1.0 + pickup_range_percent / 100.0))

func player_iframe_seconds(damage_taken: int, max_health: int, endless_strength: float = 1.0) -> float:
	var clamped_endless: float = max(0.0001, endless_strength)
	var ratio: float = float(maxi(0, damage_taken)) / max(1.0, float(max_health))
	return clamp(ratio * 0.4 / 0.15, 0.2, 0.4) / clamped_endless

func endless_factor(wave: int) -> float:
	var endless_wave: int = max(0, wave - 20)
	var endless_mult: float = 2.0 + max(0.0, float(wave - 35) * 0.2)
	return float(endless_wave * (endless_wave + 1)) / 2.0 / 100.0 * endless_mult

func harvest_value(harvesting_stat: float, living_enemies: int = 0, pacifist_percent: float = 0.0, living_trees: int = 0, cryptid: int = 0, materials_per_living_enemy: int = 0, charmed_enemy_materials: int = 0) -> int:
	return roundi(harvesting_stat) + roundi(float(living_enemies) * pacifist_percent / 100.0) + living_trees * cryptid + living_enemies * materials_per_living_enemy + charmed_enemy_materials

func harvesting_growth_delta(harvesting_stat: float, harvesting_growth_percent: float = 5.0, wave: int = 1) -> int:
	if harvesting_stat <= 0.0:
		return 0
	if wave <= 20:
		return ceili(harvesting_stat * harvesting_growth_percent / 100.0)
	return -ceili(harvesting_stat * 0.20)

func pickup_flight_speed(initial_speed: float, acceleration: float, elapsed_seconds: float) -> float:
	return initial_speed + acceleration * elapsed_seconds

func generic_probability_succeeds(chance: float, roll: float) -> bool:
	if chance == 0.0:
		return false
	return roll <= chance
