class_name WeaponStats
extends RefCounted

const FormulasScript = preload("res://src/core/formulas.gd")

const TYPE_MELEE := "melee"
const TYPE_RANGED := "ranged"
const ATTACK_THRUST := "thrust"
const ATTACK_SWEEP := "sweep"
const TARGET_DETECTION_BONUS := 200.0
const ATTACK_RANGE_GRACE := 50.0
const MIN_RANGE_EXTENSION := 25.0
const PROJECTILE_AUTO_EXTRA_DISTANCE := 100.0
const PROJECTILE_MANUAL_EXTRA_DISTANCE := 50.0
const PROJECTILE_SPREAD_PER_EXTRA_PROJECTILE := 0.1

var weapon_id: String = ""
var display_name: String = ""
var type: String = TYPE_RANGED
var tier: int = 0
var value: int = 0
var sets: Array = []
var base_damage: float = 0.0
var scaling_stats: Dictionary = {}
var cooldown_ticks: float = 60.0
var attack_speed_mod_percent: float = 0.0
var crit_chance: float = 0.03
var crit_damage: float = 1.5
var min_range: float = 0.0
var max_range: float = 150.0
var knockback: float = 0.0
var knockback_piercing: float = 0.0
var accuracy: float = 1.0
var effect_scale: float = 1.0
var projectile_count: int = 1
var projectile_spread: float = 0.0
var projectile_speed: float = 0.0
var piercing: int = 0
var piercing_damage_reduction: float = 0.0
var bounce: int = 0
var bounce_damage_reduction: float = 0.0
var can_bounce: bool = true
var increase_projectile_speed_with_range: bool = false
var lifesteal: float = 0.0
var is_exploding: bool = false
var explosion_chance: float = 0.0
var explosion_scale: float = 0.0
var is_healing: bool = false
var speed_percent_modifier: float = 0.0
var attack_type: String = ATTACK_THRUST
var alternate_attack_type: bool = false
var deal_dmg_on_return: bool = false
var cooldown_random_ticks: float = 0.0
var additional_cooldown_multiplier: float = -1.0
var additional_cooldown_every: int = 0
var pierce_on_crit: int = 0
var bounce_on_crit: int = 0
var burning_data: Dictionary = {}
var vulnerability_effects: Array = []
var texture_path: String = ""
var icon_path: String = ""

var _formulas: Variant = FormulasScript.new()

static func from_dict(data: Dictionary):
	var stats = load("res://src/combat/weapon_stats.gd").new()
	stats.weapon_id = String(data.get("weapon_id", data.get("family_id", data.get("id", ""))))
	stats.display_name = _display_name(data, stats.weapon_id)
	stats.type = String(data.get("type", TYPE_RANGED))
	stats.tier = int(data.get("tier", 0))
	stats.value = int(data.get("value", 0))
	stats.sets = data.get("sets", []).duplicate(true)
	stats.base_damage = float(data.get("damage", 0.0))
	stats.scaling_stats = data.get("scaling_stats", {}).duplicate(true)
	stats.cooldown_ticks = float(data.get("cooldown", 60.0))
	stats.attack_speed_mod_percent = float(data.get("attack_speed_mod", 0.0))
	stats.crit_chance = float(data.get("crit_chance", 0.03))
	stats.crit_damage = float(data.get("crit_damage", 1.5))
	stats.min_range = float(data.get("min_range", 0.0))
	stats.max_range = float(data.get("max_range", 150.0))
	stats.knockback = float(data.get("knockback", 0.0))
	stats.knockback_piercing = float(data.get("knockback_piercing", 0.0))
	stats.accuracy = float(data.get("accuracy", 1.0))
	stats.effect_scale = float(data.get("effect_scale", 1.0))
	stats.projectile_count = int(data.get("projectiles", 1))
	stats.projectile_spread = float(data.get("projectile_spread", 0.0))
	stats.projectile_speed = float(data.get("projectile_speed", 0.0))
	stats.piercing = int(data.get("piercing", 0))
	stats.piercing_damage_reduction = float(data.get("piercing_dmg_reduction", 0.0))
	stats.bounce = int(data.get("bounce", 0))
	stats.bounce_damage_reduction = float(data.get("bounce_dmg_reduction", 0.0))
	stats.can_bounce = bool(data.get("can_bounce", true))
	stats.increase_projectile_speed_with_range = bool(data.get("increase_projectile_speed_with_range", false))
	stats.lifesteal = float(data.get("lifesteal", 0.0))
	stats.is_exploding = bool(data.get("is_exploding", false))
	stats.explosion_chance = float(data.get("explosion_chance", 1.0 if stats.is_exploding else 0.0))
	stats.explosion_scale = float(data.get("explosion_scale", 0.0))
	stats.is_healing = bool(data.get("is_healing", false))
	stats.speed_percent_modifier = float(data.get("speed_percent_modifier", 0.0))
	stats.attack_type = String(data.get("attack_type", ATTACK_THRUST)).to_lower()
	stats.alternate_attack_type = bool(data.get("alternate_attack_type", false))
	stats.deal_dmg_on_return = bool(data.get("deal_dmg_on_return", false))
	stats.cooldown_random_ticks = float(data.get("cooldown_random", data.get("max_cooldown_rand", 0.0)))
	stats.additional_cooldown_multiplier = float(data.get("additional_cooldown_multiplier", -1.0))
	stats.additional_cooldown_every = int(data.get("additional_cooldown_every", data.get("reload_every", 0)))
	stats.pierce_on_crit = int(data.get("pierce_on_crit", 0))
	stats.bounce_on_crit = int(data.get("bounce_on_crit", 0))
	stats.burning_data = data.get("burning_data", {}).duplicate(true)
	stats.vulnerability_effects = data.get("vulnerability_effects", data.get("enemy_percent_damage_taken", [])).duplicate(true)
	var asset_refs: Dictionary = data.get("asset_refs", {})
	stats.texture_path = String(data.get("texture", asset_refs.get("texture", "")))
	stats.icon_path = String(data.get("icon", asset_refs.get("icon", "")))
	return stats

static func _display_name(data: Dictionary, fallback: String) -> String:
	var value: Variant = data.get("name", fallback)
	var base_name := fallback
	if value is Dictionary:
		base_name = String(value.get("en", value.get("zh", fallback)))
	else:
		base_name = String(value)
	var tier_name := String(data.get("tier_name", ""))
	if tier_name.is_empty() or base_name.ends_with(" " + tier_name):
		return base_name
	return "%s %s" % [base_name, tier_name]

func resolved_damage(player: Variant, set_bonus_percent: float = 0.0) -> int:
	return _formulas.weapon_damage(base_damage, scaling_stats, player, set_bonus_percent, is_exploding)

func resolved_cooldown_ticks(player: Variant) -> float:
	return _formulas.weapon_cooldown(cooldown_ticks, player.get_stat("stat_attack_speed"), attack_speed_mod_percent)

func resolved_range(player: Variant) -> float:
	if type == TYPE_MELEE:
		return _formulas.melee_weapon_range(max_range, player.get_stat("stat_range"))
	return _formulas.ranged_weapon_range(max_range, player.get_stat("stat_range"))

func resolved_min_range() -> float:
	if min_range <= 0.0:
		return 0.0
	return min_range + MIN_RANGE_EXTENSION

func detection_range(player: Variant) -> float:
	return resolved_range(player) + TARGET_DETECTION_BONUS

func can_attack_target(distance: float, player: Variant, manual_aim: bool = false) -> bool:
	if manual_aim:
		return true
	return distance >= resolved_min_range() and distance <= resolved_range(player) + ATTACK_RANGE_GRACE

func effective_crit_chance(player: Variant) -> float:
	return crit_chance + player.get_capped_stat("stat_crit_chance") / 100.0

func damage_after_crit(base_hit_damage: int, critical: bool) -> int:
	if critical:
		return maxi(1, roundi(float(base_hit_damage) * crit_damage))
	return base_hit_damage

func resolved_knockback(player: Variant) -> float:
	var amount: float = knockback + player.get_stat("knockback")
	if player.get_stat("negative_knockback") > 0.0:
		amount *= -1.0
	return amount

func effective_lifesteal(player: Variant) -> float:
	return lifesteal + player.get_stat("stat_lifesteal") / 100.0

func effective_projectile_count(player: Variant) -> int:
	if projectile_count <= 0:
		return 0
	return maxi(1, projectile_count + roundi(player.get_stat("projectiles")))

func effective_projectile_spread(player: Variant) -> float:
	var extra_projectiles := maxi(0, effective_projectile_count(player) - projectile_count)
	return projectile_spread + float(extra_projectiles) * PROJECTILE_SPREAD_PER_EXTRA_PROJECTILE

func effective_piercing(player: Variant) -> int:
	return maxi(0, piercing + roundi(player.get_stat("piercing")))

func effective_piercing_damage_reduction(player: Variant) -> float:
	return clamp(piercing_damage_reduction - player.get_stat("piercing_damage") / 100.0, 0.0, 1.0)

func effective_bounce(player: Variant) -> int:
	if not can_bounce:
		return 0
	return maxi(0, bounce + roundi(player.get_stat("bounce")))

func effective_bounce_damage_reduction(player: Variant) -> float:
	return clamp(bounce_damage_reduction - player.get_stat("bounce_damage") / 100.0, 0.0, 1.0)

func effective_projectile_speed(player: Variant) -> float:
	if increase_projectile_speed_with_range:
		return clamp(projectile_speed + projectile_speed / 300.0 * player.get_stat("stat_range"), 50.0, 6000.0)
	return projectile_speed

func projectile_lifetime_seconds(player: Variant, manual_aim: bool = false) -> float:
	var speed := effective_projectile_speed(player)
	if speed <= 0.0:
		return 0.0
	var extra_distance := PROJECTILE_MANUAL_EXTRA_DISTANCE if manual_aim else PROJECTILE_AUTO_EXTRA_DISTANCE
	return (resolved_range(player) + extra_distance) / speed

func attack_duration_seconds(player: Variant, target_distance: float) -> float:
	return _formulas.weapon_attack_duration_seconds(target_distance, player.get_stat("stat_attack_speed"), attack_speed_mod_percent)
