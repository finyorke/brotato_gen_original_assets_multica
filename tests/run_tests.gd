extends SceneTree

const EffectEntryScript = preload("res://src/core/effect_entry.gd")
const EffectKeysScript = preload("res://src/core/effect_keys.gd")
const PlayerDataScript = preload("res://src/core/player_data.gd")
const FormulasScript = preload("res://src/core/formulas.gd")
const BurnDataScript = preload("res://src/core/burn_data.gd")

var failures: Array = []
var assertions_run: int = 0
var formulas: Variant = FormulasScript.new()
var burn_tools: Variant = BurnDataScript.new()

func _initialize() -> void:
	_run_all()
	if failures.is_empty():
		print("M1 tests passed: %d assertions" % assertions_run)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("M1 tests failed: %d" % failures.size())
		quit(1)

func _run_all() -> void:
	_effect_key_tests()
	_storage_tests()
	_stat_pipeline_tests()
	_formula_tests()
	_burn_tests()

func _effect_key_tests() -> void:
	var defaults = EffectKeysScript.defaults()
	_assert_true(defaults.size() >= 234, "effect dictionary exposes at least the documented 234 keys")
	_assert_equal(defaults["stat_max_hp"], 10, "default max hp")
	_assert_equal(defaults["dodge_cap"], 60, "default dodge cap")
	_assert_equal(defaults["weapon_slot"], 6, "default weapon slots")
	_assert_equal(defaults["harvesting_growth"], 5, "default harvesting growth")
	_assert_equal(defaults["hp_cap"], EffectKeysScript.INF_CAP, "default hp cap")
	_assert_true(defaults["stat_links"] is Array, "stat_links is an array container")
	var second = EffectKeysScript.defaults()
	defaults["stat_links"].append(["stat_armor", 1, "stat_max_hp", 10, false])
	_assert_equal(second["stat_links"].size(), 0, "default arrays are deep duplicated")

func _storage_tests() -> void:
	var player: Variant = PlayerDataScript.new()
	var sum_effect: Variant = EffectEntryScript.make("stat_max_hp", 5)
	player.apply_effect(sum_effect)
	_assert_equal(player.effects["stat_max_hp"], 15, "SUM applies")
	player.remove_effect(sum_effect)
	_assert_equal(player.effects["stat_max_hp"], 10, "SUM removes")
	var key_value: Variant = EffectEntryScript.make("stat_armor", 2, EffectEntryScript.StorageMethod.KEY_VALUE, "stat_links")
	player.apply_effect(key_value)
	player.apply_effect(key_value)
	_assert_equal(player.effects["stat_links"], [["stat_armor", 4]], "KEY_VALUE merges same key")
	player.remove_effect(key_value)
	_assert_equal(player.effects["stat_links"], [["stat_armor", 2]], "KEY_VALUE subtracts")
	player.remove_effect(key_value)
	_assert_equal(player.effects["stat_links"], [], "KEY_VALUE removes zero entries")
	var replace_a: Variant = EffectEntryScript.make("dodge_cap", 90, EffectEntryScript.StorageMethod.REPLACE)
	var replace_b: Variant = EffectEntryScript.make("dodge_cap", 40, EffectEntryScript.StorageMethod.REPLACE)
	player.apply_effect(replace_a)
	player.apply_effect(replace_b)
	_assert_equal(player.effects["dodge_cap"], 40, "REPLACE applies latest")
	player.remove_effect(replace_b)
	_assert_equal(player.effects["dodge_cap"], 90, "REPLACE restores LIFO")
	player.remove_effect(replace_a)
	_assert_equal(player.effects["dodge_cap"], 60, "REPLACE restores original")
	var append_key: Variant = EffectEntryScript.make("weapon_sword", 0, EffectEntryScript.StorageMethod.APPEND_KEY, "starting_weapon")
	player.apply_effect(append_key)
	player.apply_effect(append_key)
	_assert_equal(player.effects["starting_weapon"], ["weapon_sword"], "APPEND_KEY is unique")
	player.remove_effect(append_key)
	_assert_equal(player.effects["starting_weapon"], [], "APPEND_KEY removes")
	var append_pair: Variant = EffectEntryScript.make("stat_speed", 3, EffectEntryScript.StorageMethod.APPEND_KEY_VALUE, "stats_next_wave")
	player.apply_effect(append_pair)
	player.apply_effect(append_pair)
	_assert_equal(player.effects["stats_next_wave"].size(), 2, "APPEND_KEY_VALUE allows duplicate pairs")
	player.remove_effect(append_pair)
	_assert_equal(player.effects["stats_next_wave"].size(), 1, "APPEND_KEY_VALUE removes one exact pair")

func _stat_pipeline_tests() -> void:
	var player: Variant = PlayerDataScript.new()
	player.add_permanent_stat("stat_max_hp", 10)
	_assert_equal(player.get_stat("stat_max_hp"), 20.0, "permanent layer contributes")
	player.add_temporary_stat("stat_max_hp", 4)
	_assert_equal(player.get_stat("stat_max_hp"), 24.0, "temporary layer contributes")
	player.apply_effect(EffectEntryScript.make("gain_stat_max_hp", 50))
	_assert_equal(player.get_stat("stat_max_hp"), 36.0, "gain_stat multiplies all stat layers")
	player.clear_temporary_stats()
	_assert_equal(player.get_stat("stat_max_hp"), 30.0, "temporary stats clear")
	player.apply_effect(EffectEntryScript.make("hp_cap", 12, EffectEntryScript.StorageMethod.REPLACE))
	_assert_equal(player.get_max_health(), 12, "hp cap applies")
	player.apply_effect(EffectEntryScript.make("stat_dodge", 80))
	_assert_equal(player.get_dodge_probability(), 0.6, "dodge uses default cap")
	player.apply_effect(EffectEntryScript.make("dodge_cap", 90, EffectEntryScript.StorageMethod.REPLACE))
	_assert_equal(player.get_dodge_probability(), 0.8, "dodge cap can be replaced up to hard cap")
	var speed_player: Variant = PlayerDataScript.new()
	speed_player.add_permanent_stat("stat_speed", 20)
	_assert_equal(speed_player.get_speed(), 540.0, "player speed uses base 450")
	speed_player.add_permanent_stat("stat_speed", -200)
	_assert_equal(speed_player.get_speed(), 0.0, "negative final movement speed clamps at runtime")
	var linked: Variant = PlayerDataScript.new()
	linked.effects["stat_links"].append(["stat_armor", 1, "stat_max_hp", 5, false])
	linked.recalculate_linked_stats()
	_assert_equal(linked.get_stat("stat_armor"), 2.0, "stat_links computes int chunks")
	linked.add_temporary_stat("stat_max_hp", 5)
	linked.recalculate_linked_stats()
	_assert_equal(linked.get_stat("stat_armor"), 3.0, "stat_links can see temporary source")
	linked.effects["stat_links"].clear()
	linked.effects["stat_links"].append(["stat_armor", 1, "stat_max_hp", 5, true])
	linked.recalculate_linked_stats()
	_assert_equal(linked.get_stat("stat_armor"), 2.0, "stat_links perm-only ignores temporary source")
	var xp_player: Variant = PlayerDataScript.new()
	xp_player.apply_effect(EffectEntryScript.make("xp_gain", 100))
	var levels = xp_player.gain_xp(8)
	_assert_equal(levels, 1, "xp_gain modifies gained XP")
	_assert_equal(xp_player.level, 1, "level increments")
	_assert_equal(xp_player.effects["stat_max_hp"], 11, "level up grants max hp")

func _formula_tests() -> void:
	var player: Variant = PlayerDataScript.new()
	player.add_permanent_stat("stat_ranged_damage", 5)
	player.add_permanent_stat("stat_percent_damage", 20)
	_assert_equal(formulas.weapon_damage(10, {"stat_ranged_damage": 1.0}, player), 18, "weapon damage formula")
	player.add_permanent_stat("explosion_damage", 50)
	_assert_equal(formulas.explosion_damage(10, {"stat_ranged_damage": 1.0}, player), 26, "explosion damage formula")
	_assert_equal(formulas.weapon_cooldown(60, 100), 30.0, "positive attack speed cooldown")
	_assert_equal(formulas.weapon_cooldown(60, -50), 90.0, "negative attack speed cooldown")
	_assert_equal(formulas.weapon_cooldown(1, 0), 2.0, "cooldown lower bound")
	_assert_equal(formulas.ranged_weapon_range(150, 20), 170.0, "ranged range")
	_assert_equal(formulas.melee_weapon_range(150, 20), 160.0, "melee range")
	_assert_approx(formulas.armor_coef(15), 0.5, "positive armor coefficient")
	_assert_approx(formulas.armor_coef(-15), 1.5, "negative armor coefficient")
	_assert_equal(formulas.player_damage_after_armor(10, 15), 5, "player armor damage")
	_assert_equal(formulas.player_damage_after_armor(1, 999), 1, "player damage min 1")
	_assert_equal(formulas.enemy_damage_after_armor(10, 3), 7, "enemy flat armor")
	_assert_equal(formulas.enemy_damage_after_armor(3, 99), 1, "enemy damage min 1")
	_assert_equal(formulas.hp_regen_interval_seconds(0), 99.0, "nonpositive hp regen disabled")
	_assert_equal(formulas.hp_regen_interval_seconds(1), 5.0, "1 hp regen interval")
	_assert_equal(formulas.hp_regen_interval_seconds(10), 1.0, "10 hp regen interval")
	_assert_true(not formulas.lifesteal_can_trigger(1.05, 1.0), "lifesteal throttle blocks")
	_assert_true(formulas.lifesteal_can_trigger(1.11, 1.0), "lifesteal throttle releases")
	_assert_equal(formulas.xp_required_for_level(1), 16, "xp level 1")
	_assert_equal(formulas.xp_required_for_level(20), 529, "xp level 20")
	_assert_equal(formulas.next_level_xp_needed(0), 16.0, "next level xp from level 0")
	_assert_approx(formulas.shop_tier_chance(1, 2, 0), 0.06, "tier II shop chance")
	_assert_approx(formulas.shop_tier_chance(2, 10, 0), 0.14, "tier III shop chance")
	_assert_approx(formulas.shop_tier_chance(1, 2, 100), 0.12, "positive luck shop chance")
	_assert_approx(formulas.shop_tier_chance(1, 2, -50), 0.04, "negative luck shop chance")
	_assert_equal(formulas.reroll_price(10, 2, 0), 19, "reroll price")
	_assert_equal(formulas.enemy_hp(10, 2, 6), 20, "enemy hp wave scaling")
	_assert_equal(formulas.enemy_hp(10, 2, 6, 50, 1.0, 2), 39, "enemy hp percent and coop scaling")
	_assert_approx(formulas.endless_factor(20), 0.0, "no endless factor at wave 20")
	_assert_approx(formulas.endless_factor(21), 0.02, "endless factor wave 21")
	_assert_equal(formulas.harvest_value(10, 5, 100, 2, 3, 1, 4), 30, "harvest settlement value")
	_assert_equal(formulas.harvesting_growth_delta(10, 5, 1), 1, "harvesting positive growth")
	_assert_equal(formulas.harvesting_growth_delta(10, 5, 21), -2, "endless harvesting decay")
	_assert_equal(formulas.pickup_flight_speed(500, 1200, 0.5), 1100.0, "pickup flight acceleration")
	_assert_true(not formulas.generic_probability_succeeds(0.0, 0.0), "zero chance always fails")
	_assert_true(formulas.generic_probability_succeeds(0.2, 0.2), "generic chance uses <= roll")

func _burn_tests() -> void:
	var a: Variant = BurnDataScript.new()
	a.chance = 0.25
	a.damage = 2
	a.duration = 3
	a.spread = 1
	var b: Variant = BurnDataScript.new()
	b.chance = 0.10
	b.damage = 5
	b.duration = 2
	b.spread = 2
	a.merge_global(b)
	_assert_approx(a.chance, 0.35, "global burn chance stacks")
	_assert_equal(a.damage, 7, "global burn damage stacks")
	_assert_equal(a.duration, 3, "global burn duration takes max")
	_assert_equal(a.spread, 3, "global burn spread stacks")
	var merged = burn_tools.merged_enemy_burn(a, b)
	_assert_equal(merged.damage, 7, "enemy burn keeps strongest damage")
	_assert_equal(burn_tools.tick_interval(50, 0), 0.25, "burn tick reduction")
	_assert_equal(burn_tools.tick_interval(200, 0), 0.1, "burn tick lower bound")

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	assertions_run += 1
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _assert_approx(actual: float, expected: float, label: String, epsilon: float = 0.0001) -> void:
	assertions_run += 1
	if abs(actual - expected) > epsilon:
		failures.append("%s: expected approx %s, got %s" % [label, str(expected), str(actual)])

func _assert_true(value: bool, label: String) -> void:
	assertions_run += 1
	if not value:
		failures.append("%s: expected true" % label)
