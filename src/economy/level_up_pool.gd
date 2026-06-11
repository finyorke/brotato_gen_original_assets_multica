class_name LevelUpPool
extends RefCounted

const FormulasScript = preload("res://src/core/formulas.gd")

const UPGRADE_ROWS := [
	{"id": "upgrade_max_hp", "key": "stat_max_hp", "values": [3, 6, 9, 12]},
	{"id": "upgrade_percent_damage", "key": "stat_percent_damage", "values": [5, 8, 12, 16]},
	{"id": "upgrade_melee_damage", "key": "stat_melee_damage", "values": [2, 4, 6, 8]},
	{"id": "upgrade_ranged_damage", "key": "stat_ranged_damage", "values": [1, 2, 3, 4]},
	{"id": "upgrade_elemental_damage", "key": "stat_elemental_damage", "values": [1, 2, 3, 4]},
	{"id": "upgrade_attack_speed", "key": "stat_attack_speed", "values": [5, 10, 15, 20]},
	{"id": "upgrade_crit_chance", "key": "stat_crit_chance", "values": [3, 5, 7, 9]},
	{"id": "upgrade_range", "key": "stat_range", "values": [15, 30, 45, 60]},
	{"id": "upgrade_accuracy", "key": "accuracy", "values": [4, 8, 12, 16]},
	{"id": "upgrade_armor", "key": "stat_armor", "values": [1, 2, 3, 4]},
	{"id": "upgrade_dodge", "key": "stat_dodge", "values": [3, 6, 9, 12]},
	{"id": "upgrade_speed", "key": "stat_speed", "values": [3, 6, 9, 12]},
	{"id": "upgrade_hp_regeneration", "key": "stat_hp_regeneration", "values": [2, 3, 4, 5]},
	{"id": "upgrade_lifesteal", "key": "stat_lifesteal", "values": [1, 2, 3, 4]},
	{"id": "upgrade_harvesting", "key": "stat_harvesting", "values": [5, 8, 10, 12]},
	{"id": "upgrade_engineering", "key": "stat_engineering", "values": [2, 3, 4, 5]},
	{"id": "upgrade_luck", "key": "stat_luck", "values": [5, 10, 15, 20]},
]

var _formulas: Variant = FormulasScript.new()

func tier_for_level(level: int, player: Variant, roll: float = -1.0) -> int:
	if level == 5:
		return 1
	if level == 10 or level == 15 or level == 20:
		return 2
	if level > 0 and level % 5 == 0:
		return 3
	return _formulas.roll_shop_tier(level, player.get_stat("stat_luck"), roll)

func generate_options(level: int, player: Variant, already_shown_ids: Array = [], rolls: Dictionary = {}) -> Array:
	if player.get_stat("weapon_slot_upgrades") > 0.0 and player.get_stat("weapon_slot") < player.get_stat("weapon_slot_upgrades"):
		return [_make_option({"id": "upgrade_weapon_slot", "key": "weapon_slot", "values": [1, 1, 1, 1]}, 0, player)]
	var options: Array = []
	var excluded: Array = already_shown_ids.duplicate()
	var attempts: int = 0
	while options.size() < 4 and attempts < 50:
		attempts += 1
		var tier: int = tier_for_level(level, player, _take_roll(rolls, "tier_rolls"))
		var row: Dictionary = _pick_row(excluded, _take_roll(rolls, "pick_rolls"))
		if row.is_empty():
			break
		var option: Dictionary = _make_option(row, tier, player)
		options.append(option)
		excluded.append(option["id"])
	return options

func apply_option(player: Variant, option: Dictionary) -> void:
	var key: String = String(option.get("key", ""))
	var value: int = int(option.get("value", 0))
	if key.is_empty():
		return
	if key == "stat_max_hp":
		var before: int = player.get_max_health()
		player.add_permanent_stat(key, value)
		player.current_health += maxi(0, player.get_max_health() - before)
	else:
		player.add_permanent_stat(key, value)

func _make_option(row: Dictionary, tier: int, player: Variant) -> Dictionary:
	var values: Array = row.get("values", [])
	var base_value: int = int(values[clampi(tier, 0, values.size() - 1)])
	var modified_value: int = roundi(float(base_value) * (1.0 + player.get_stat("level_upgrades_modifications") / 100.0))
	return {
		"id": String(row.get("id", "")),
		"key": String(row.get("key", "")),
		"tier": tier,
		"value": modified_value,
	}

func _pick_row(excluded_ids: Array, roll: float) -> Dictionary:
	var candidates: Array = []
	for row in UPGRADE_ROWS:
		if not excluded_ids.has(String(row.get("id", ""))):
			candidates.append(row)
	if candidates.is_empty():
		return {}
	var index: int = randi() % candidates.size() if roll < 0.0 else clampi(floori(roll * float(candidates.size())), 0, candidates.size() - 1)
	return candidates[index].duplicate(true)

func _take_roll(rolls: Dictionary, key: String) -> float:
	if not rolls.has(key):
		return -1.0
	var values: Array = rolls[key]
	if values.is_empty():
		return -1.0
	return float(values.pop_front())
