class_name WeaponStats
extends RefCounted

const FormulasScript = preload("res://src/core/formulas.gd")

const TYPE_MELEE := "melee"
const TYPE_RANGED := "ranged"
const TARGET_DETECTION_BONUS := 200.0
const ATTACK_RANGE_GRACE := 50.0

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
var crit_chance: float = 0.0
var crit_damage: float = 1.0
var min_range: float = 0.0
var max_range: float = 150.0
var knockback: float = 0.0
var accuracy: float = 1.0
var projectile_count: int = 1
var projectile_spread: float = 0.0
var projectile_speed: float = 0.0
var piercing: int = 0
var piercing_damage_reduction: float = 0.0
var bounce: int = 0
var bounce_damage_reduction: float = 0.0
var lifesteal: float = 0.0
var is_exploding: bool = false
var explosion_scale: float = 0.0
var texture_path: String = ""
var icon_path: String = ""

var _formulas: Variant = FormulasScript.new()

static func from_dict(data: Dictionary):
	var stats = load("res://src/combat/weapon_stats.gd").new()
	stats.weapon_id = String(data.get("id", ""))
	stats.display_name = String(data.get("name", stats.weapon_id))
	stats.type = String(data.get("type", TYPE_RANGED))
	stats.tier = int(data.get("tier", 0))
	stats.value = int(data.get("value", 0))
	stats.sets = data.get("sets", []).duplicate(true)
	stats.base_damage = float(data.get("damage", 0.0))
	stats.scaling_stats = data.get("scaling_stats", {}).duplicate(true)
	stats.cooldown_ticks = float(data.get("cooldown", 60.0))
	stats.attack_speed_mod_percent = float(data.get("attack_speed_mod", 0.0))
	stats.crit_chance = float(data.get("crit_chance", 0.0))
	stats.crit_damage = float(data.get("crit_damage", 1.0))
	stats.min_range = float(data.get("min_range", 0.0))
	stats.max_range = float(data.get("max_range", 150.0))
	stats.knockback = float(data.get("knockback", 0.0))
	stats.accuracy = float(data.get("accuracy", 1.0))
	stats.projectile_count = int(data.get("projectiles", 1))
	stats.projectile_spread = float(data.get("projectile_spread", 0.0))
	stats.projectile_speed = float(data.get("projectile_speed", 0.0))
	stats.piercing = int(data.get("piercing", 0))
	stats.piercing_damage_reduction = float(data.get("piercing_dmg_reduction", 0.0))
	stats.bounce = int(data.get("bounce", 0))
	stats.bounce_damage_reduction = float(data.get("bounce_dmg_reduction", 0.0))
	stats.lifesteal = float(data.get("lifesteal", 0.0))
	stats.is_exploding = bool(data.get("is_exploding", false))
	stats.explosion_scale = float(data.get("explosion_scale", 0.0))
	stats.texture_path = String(data.get("texture", ""))
	stats.icon_path = String(data.get("icon", ""))
	return stats

func resolved_damage(player: Variant, set_bonus_percent: float = 0.0) -> int:
	return _formulas.weapon_damage(base_damage, scaling_stats, player, set_bonus_percent, is_exploding)

func resolved_cooldown_ticks(player: Variant) -> float:
	return _formulas.weapon_cooldown(cooldown_ticks, player.get_stat("stat_attack_speed"), attack_speed_mod_percent)

func resolved_range(player: Variant) -> float:
	if type == TYPE_MELEE:
		return _formulas.melee_weapon_range(max_range, player.get_stat("stat_range"))
	return _formulas.ranged_weapon_range(max_range, player.get_stat("stat_range"))

func detection_range(player: Variant) -> float:
	return resolved_range(player) + TARGET_DETECTION_BONUS

func can_attack_target(distance: float, player: Variant, manual_aim: bool = false) -> bool:
	if manual_aim:
		return true
	return distance >= min_range and distance <= resolved_range(player) + ATTACK_RANGE_GRACE

func effective_crit_chance(player: Variant) -> float:
	return crit_chance + player.get_capped_stat("stat_crit_chance") / 100.0

func damage_after_crit(base_hit_damage: int, critical: bool) -> int:
	if critical:
		return maxi(1, roundi(float(base_hit_damage) * crit_damage))
	return base_hit_damage

func projectile_lifetime_seconds(player: Variant, manual_aim: bool = false) -> float:
	if projectile_speed <= 0.0:
		return 0.0
	var extra_distance := 50.0 if manual_aim else 100.0
	return (resolved_range(player) + extra_distance) / projectile_speed
