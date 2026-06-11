class_name EnemyStats
extends RefCounted

const FormulasScript = preload("res://src/core/formulas.gd")

var enemy_id: String = ""
var display_name: String = ""
var health: float = 1.0
var health_increase_each_wave: float = 0.0
var damage: float = 1.0
var damage_increase_each_wave: float = 0.0
var speed: float = 0.0
var speed_randomization: float = 0.0
var knockback_resistance: float = 0.0
var value: int = 1
var armor: float = 0.0
var armor_increase_each_wave: float = 0.0
var base_drop_chance: float = 0.0
var item_drop_chance: float = 0.0
var can_drop_material: bool = true
var always_drop_material: bool = false
var can_drop_consumable: bool = true
var movement_mode: String = "chase"
var priority_clear: bool = false
var is_boss: bool = false
var is_elite: bool = false
var is_loot: bool = false
var entity_type: String = "enemy"
var texture_path: String = ""

var _formulas: Variant = FormulasScript.new()

static func from_dict(data: Dictionary):
	var stats = load("res://src/combat/enemy_stats.gd").new()
	stats.enemy_id = String(data.get("id", ""))
	stats.display_name = String(data.get("name", stats.enemy_id))
	stats.health = float(data.get("health", 1.0))
	stats.health_increase_each_wave = float(data.get("health_increase_each_wave", 0.0))
	stats.damage = float(data.get("damage", 1.0))
	stats.damage_increase_each_wave = float(data.get("damage_increase_each_wave", 0.0))
	stats.speed = float(data.get("speed", 0.0))
	stats.speed_randomization = float(data.get("speed_randomization", 0.0))
	stats.knockback_resistance = float(data.get("knockback_resistance", 0.0))
	stats.value = int(data.get("value", 1))
	stats.armor = float(data.get("armor", 0.0))
	stats.armor_increase_each_wave = float(data.get("armor_increase_each_wave", 0.0))
	stats.base_drop_chance = float(data.get("base_drop_chance", 0.0))
	stats.item_drop_chance = float(data.get("item_drop_chance", 0.0))
	stats.can_drop_material = bool(data.get("can_drop_material", true))
	stats.always_drop_material = bool(data.get("always_drop_material", false))
	stats.can_drop_consumable = bool(data.get("can_drop_consumable", true))
	stats.movement_mode = String(data.get("movement_mode", "chase"))
	stats.priority_clear = bool(data.get("priority_clear", false))
	stats.is_boss = bool(data.get("is_boss", false))
	stats.is_elite = bool(data.get("is_elite", false))
	stats.is_loot = bool(data.get("is_loot", false))
	stats.entity_type = String(data.get("entity_type", "enemy"))
	stats.texture_path = String(data.get("texture", ""))
	return stats

func max_health_for_wave(wave: int, player: Variant = null, difficulty_multiplier: float = 1.0, player_count: int = 1, endless_factor: float = 0.0) -> int:
	var enemy_health_percent := 0.0
	if player != null:
		enemy_health_percent = player.get_stat("enemy_health")
	return _formulas.enemy_hp(health, health_increase_each_wave, wave, enemy_health_percent, difficulty_multiplier, player_count, endless_factor)

func contact_damage_for_wave(wave: int, player: Variant = null, difficulty_multiplier: float = 1.0, endless_factor: float = 0.0, player_count: int = 1) -> int:
	var enemy_damage_percent := 0.0
	if player != null:
		enemy_damage_percent = player.get_stat("enemy_damage")
	return _formulas.enemy_damage(damage, damage_increase_each_wave, wave, enemy_damage_percent, difficulty_multiplier, endless_factor, player_count)

func armor_for_wave(wave: int, armor_percent_modifier: float = 0.0) -> int:
	return _formulas.enemy_armor(armor, armor_increase_each_wave, wave, armor_percent_modifier)

func speed_for_roll(speed_roll: float = 0.0, speed_percent_modifier: float = 0.0) -> float:
	return max(0.0, (speed + speed_randomization * clamp(speed_roll, -1.0, 1.0)) * (1.0 + speed_percent_modifier / 100.0))

func material_drop_chance(wave: int, is_horde_wave: bool = false) -> float:
	if not can_drop_material:
		return 0.0
	if always_drop_material:
		return 1.0
	return _formulas.enemy_material_drop_chance(wave, is_horde_wave)

func instantiate(wave: int, position: Vector2, player: Variant = null, speed_roll: float = 0.0, difficulty_multiplier: float = 1.0, player_count: int = 1, endless_factor: float = 0.0) -> Dictionary:
	var hp := max_health_for_wave(wave, player, difficulty_multiplier, player_count, endless_factor)
	return {
		"id": enemy_id,
		"display_name": display_name,
		"position": position,
		"hp": hp,
		"max_hp": hp,
		"damage": contact_damage_for_wave(wave, player, difficulty_multiplier, endless_factor, player_count),
		"armor": armor_for_wave(wave),
		"speed": speed_for_roll(speed_roll),
		"knockback_resistance": knockback_resistance,
		"value": value,
		"can_drop_material": can_drop_material,
		"movement_mode": movement_mode,
		"priority_clear": priority_clear,
		"is_boss": is_boss,
		"is_elite": is_elite,
		"is_loot": is_loot,
		"entity_type": entity_type,
		"texture": texture_path,
	}
