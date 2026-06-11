extends SceneTree

const EffectEntryScript = preload("res://src/core/effect_entry.gd")
const EffectKeysScript = preload("res://src/core/effect_keys.gd")
const PlayerDataScript = preload("res://src/core/player_data.gd")
const FormulasScript = preload("res://src/core/formulas.gd")
const BurnDataScript = preload("res://src/core/burn_data.gd")
const WeaponStatsScript = preload("res://src/combat/weapon_stats.gd")
const EnemyStatsScript = preload("res://src/combat/enemy_stats.gd")
const TargetingScript = preload("res://src/combat/targeting.gd")
const WaveSchedulerScript = preload("res://src/combat/wave_scheduler.gd")
const CombatRuntimeScript = preload("res://src/combat/combat_runtime.gd")
const EconomyCatalogScript = preload("res://src/economy/economy_catalog.gd")
const ShopStateScript = preload("res://src/economy/shop_state.gd")
const LevelUpPoolScript = preload("res://src/economy/level_up_pool.gd")
const RewardResolverScript = preload("res://src/economy/reward_resolver.gd")
const MainScene = preload("res://scenes/main.tscn")

var failures: Array = []
var assertions_run: int = 0
var formulas: Variant = FormulasScript.new()
var burn_tools: Variant = BurnDataScript.new()

func _initialize() -> void:
	_run_all()
	if failures.is_empty():
		print("Tests passed: %d assertions" % assertions_run)
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Tests failed: %d" % failures.size())
		quit(1)

func _run_all() -> void:
	_effect_key_tests()
	_storage_tests()
	_stat_pipeline_tests()
	_formula_tests()
	_burn_tests()
	_combat_m2_tests()
	_content_m3_tests()
	_combat_m2c_tests()
	_economy_m3b_tests()
	_ui_flow_m4_tests()

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
	linked.effects["stat_links"].clear()
	linked.effects["stat_links"].append(["stat_armor", 1, "stat_max_hp", 5, false])
	linked.effects["stat_links"].append(["stat_dodge", 1, "stat_armor", 1, false])
	linked.recalculate_linked_stats()
	_assert_equal(linked.get_stat("stat_armor"), 3.0, "stat_links still computes first link")
	_assert_equal(linked.get_stat("stat_dodge"), 0.0, "stat_links do not see linked layer outputs")
	var xp_player: Variant = PlayerDataScript.new()
	xp_player.apply_effect(EffectEntryScript.make("xp_gain", 100))
	var levels = xp_player.gain_xp(8)
	_assert_equal(levels, 1, "xp_gain modifies gained XP")
	_assert_equal(xp_player.level, 1, "level increments")
	_assert_equal(xp_player.effects["stat_max_hp"], 11, "level up grants max hp")
	_assert_equal(xp_player.current_health, 11, "level up max hp also heals current hp by one")

func _formula_tests() -> void:
	var player: Variant = PlayerDataScript.new()
	player.add_permanent_stat("stat_ranged_damage", 5)
	player.add_permanent_stat("stat_percent_damage", 20)
	_assert_equal(formulas.weapon_damage(10, {"stat_ranged_damage": 1.0}, player), 18, "weapon damage formula")
	player.add_permanent_stat("stat_ranged_damage", -20)
	_assert_equal(formulas.weapon_damage(10, {"stat_ranged_damage": 1.0}, player), 1, "weapon damage lower bound applies after scaling")
	player.add_permanent_stat("explosion_damage", 50)
	player.add_permanent_stat("stat_ranged_damage", 20)
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
	_assert_equal(formulas.enemy_damage(1, 0.6, 3), 2, "enemy damage wave scaling")
	_assert_equal(formulas.enemy_armor(2, 0.5, 5), 4, "enemy armor wave scaling")
	_assert_equal(formulas.danger_enemy_stat_multiplier(5), 1.40, "danger 5 enemy multiplier")
	_assert_approx(formulas.enemy_material_drop_chance(20), 0.7, "enemy material drop after wave 5")
	_assert_approx(formulas.enemy_material_drop_chance(20, true), 0.455, "horde wave material drop penalty")
	_assert_equal(formulas.spawn_count(4, 5, 1.0, 1, 0, 1.0, 4), 4, "spawn count can roll the documented min")
	_assert_equal(formulas.spawn_count(4, 5, 1.0, 1, 0, 1.0, 5), 5, "spawn count can roll the documented max")
	_assert_equal(formulas.spawn_count(4, 5, 1.0, 1, 0, 0.0, 4), 4, "spawn count does not add a fractional enemy when there is no fraction")
	_assert_equal(formulas.spawn_count(1, 1, 0.33, 1, 0, 0.2, 1), 1, "spawn count fractional roll can add one")
	_assert_equal(formulas.spawn_count(1, 1, 0.33, 1, 0, 0.9, 1), 0, "spawn count fractional roll can skip")
	_assert_equal(formulas.pickup_radius(0), 150.0, "pickup radius base")
	_assert_equal(formulas.pickup_radius(-90), 30.0, "pickup radius minimum")
	_assert_equal(formulas.player_iframe_seconds(2, 10), 0.4, "player iframe full clamp")
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

func _combat_m2_tests() -> void:
	var weapon_json := _load_json("res://data/m2/starter_weapons.json")
	_assert_equal(weapon_json.get("weapons", []).size(), 3, "starter weapon subset row count")
	var pistol: Variant = WeaponStatsScript.from_dict(weapon_json["weapons"][0])
	var fist: Variant = WeaponStatsScript.from_dict(weapon_json["weapons"][1])
	var player: Variant = PlayerDataScript.new()
	player.add_permanent_stat("stat_ranged_damage", 4)
	player.add_permanent_stat("stat_range", 20)
	player.add_permanent_stat("stat_attack_speed", 20)
	_assert_equal(pistol.resolved_damage(player), 16, "pistol I damage from ranged scaling")
	_assert_equal(pistol.resolved_cooldown_ticks(player), 50.0, "pistol I cooldown uses attack speed")
	_assert_equal(pistol.resolved_range(player), 420.0, "ranged range gets full stat range")
	_assert_equal(pistol.detection_range(player), 620.0, "weapon detection adds 200 px")
	_assert_true(pistol.can_attack_target(470.0, player), "weapon attack range allows +50 px grace")
	_assert_true(not pistol.can_attack_target(471.0, player), "weapon attack range rejects past grace")
	_assert_approx(pistol.projectile_lifetime_seconds(player), 520.0 / 3000.0, "projectile lifetime uses range + 100")
	player.add_permanent_stat("stat_crit_chance", 10)
	_assert_approx(pistol.effective_crit_chance(player), 0.15, "weapon crit adds capped player crit")
	_assert_equal(pistol.damage_after_crit(16, true), 32, "weapon crit damage multiplier")
	_assert_equal(fist.resolved_range(player), 160.0, "melee range gets half stat range")

	var enemies := [
		{"id": "near", "position": Vector2(100, 0), "hp": 1},
		{"id": "far", "position": Vector2(200, 0), "hp": 1},
	]
	_assert_equal(TargetingScript.nearest_enemy(enemies, Vector2.ZERO, 150.0)["id"], "near", "targeting chooses nearest enemy in detection range")
	_assert_equal(TargetingScript.nearest_enemy(enemies, Vector2.ZERO, 90.0), null, "targeting rejects enemies outside detection range")

	var enemy_json := _load_json("res://data/m2/area1_enemies.json")
	var baby: Variant = EnemyStatsScript.from_dict(enemy_json["enemies"][0])
	_assert_equal(baby.max_health_for_wave(5), 11, "baby alien hp wave scaling")
	player.add_permanent_stat("enemy_health", 50)
	_assert_equal(baby.max_health_for_wave(5, player), 17, "enemy_health effect scales enemy hp")
	_assert_equal(baby.contact_damage_for_wave(3), 2, "baby alien damage wave scaling")
	_assert_equal(baby.speed_for_roll(1.0), 300.0, "enemy speed randomization upper bound")
	_assert_equal(baby.instantiate(1, Vector2(12, 24))["hp"], 3, "enemy instantiate carries hp")

	var wave_json := _load_json("res://data/m2/area1_waves.json")
	var scheduler: Variant = WaveSchedulerScript.from_dict(wave_json["waves"][0])
	_assert_equal(scheduler.advance(0.99, 0, 0).size(), 0, "wave scheduler waits until first whole second")
	var requests: Array = scheduler.advance(0.01, 0, 0)
	_assert_equal(requests.size(), 1, "wave scheduler emits first group at t1")
	_assert_equal(requests[0]["enemy_id"], "baby_alien", "wave scheduler request enemy id")
	_assert_true(int(requests[0]["count"]) >= 4 and int(requests[0]["count"]) <= 5, "wave scheduler request count uses min-max roll")
	scheduler.enqueue_warning(requests[0], Vector2(300, 300))
	for i in 59:
		_assert_equal(scheduler.physics_tick().size(), 0, "spawn warning has not materialized before 60 ticks")
	var materialized: Array = scheduler.physics_tick()
	_assert_equal(materialized.size(), 1, "spawn queue materializes on 60th warning tick and queue cadence")
	_assert_equal(materialized[0]["enemy_id"], "baby_alien", "materialized warning keeps enemy id")
	scheduler.enqueue_warning({"enemy_id": "baby_alien", "count": 1}, Vector2.ZERO)
	for i in 60:
		_assert_equal(scheduler.physics_tick(Vector2.ZERO, func(_area: String) -> Vector2: return Vector2(100, 100)).size(), 0, "spawn warning relocates and resets while overlapping player")
	_assert_equal(scheduler.active_warning_count(), 1, "overlapping warning remains active")
	_assert_equal(scheduler.warning_queue[0]["position"], Vector2(100, 100), "overlapping warning moves to a new spawn point")
	for i in 59:
		_assert_equal(scheduler.physics_tick(Vector2.ZERO).size(), 0, "relocated warning waits through its reset timer")
	var relocated: Array = scheduler.physics_tick(Vector2.ZERO)
	_assert_equal(relocated.size(), 1, "relocated warning materializes after the reset timer")

	var capped_scheduler: Variant = WaveSchedulerScript.from_dict(wave_json["waves"][0])
	capped_scheduler.groups[0]["count_min"] = 5
	capped_scheduler.groups[0]["count_max"] = 5
	var capped_requests: Array = capped_scheduler.advance(1.0, 0, 100)
	_assert_equal(capped_requests.size(), 1, "wave scheduler still emits requests at enemy cap")
	_assert_equal(capped_requests[0]["performance_cull"], 5, "wave scheduler asks runtime to cull over-cap enemies")
	var queue_scheduler: Variant = WaveSchedulerScript.from_dict(wave_json["waves"][0])
	for i in 121:
		queue_scheduler.spawn_queue.append({"enemy_id": "baby_alien", "count": 1})
	var queue_materialized: Array = []
	for i in 3:
		queue_materialized = queue_scheduler.physics_tick()
	_assert_equal(queue_materialized.size(), 2, "spawn queue drains up to two when backlog exceeds 100")

func _content_m3_tests() -> void:
	var characters_json := _load_json("res://data/m3/characters.json")
	var weapons_json := _load_json("res://data/m3/weapons.json")
	var items_json := _load_json("res://data/m3/items.json")
	var tags_sets_json := _load_json("res://data/m3/tags_sets_unlocks.json")
	var effect_reference_json := _load_json("res://data/m3/effect_reference.json")
	var summary_json := _load_json("res://data/m3/generation_summary.json")

	var characters: Array = characters_json.get("characters", [])
	var weapon_families: Array = weapons_json.get("families", [])
	var weapon_variants: Array = weapons_json.get("variants", [])
	var items: Array = items_json.get("items", [])
	var effect_defaults: Dictionary = effect_reference_json.get("effect_defaults", {})

	_assert_equal(characters.size(), 49, "M3 character row count")
	_assert_equal(weapon_families.size(), 61, "M3 weapon family count")
	_assert_equal(int(weapons_json.get("summary", {}).get("quality_slot_count", 0)), 244, "M3 weapon family x quality slots")
	_assert_equal(weapon_variants.size(), 201, "M3 documented weapon variant rows")
	_assert_equal(items.size(), 209, "M3 item data row count")
	_assert_equal(int(summary_json.get("weapon_undocumented_quality_slots", 0)), 43, "M3 explicitly tracks undocumented weapon slots")

	_assert_equal(effect_defaults.size(), EffectKeysScript.key_count(), "M3 effect defaults mirror EffectKeys")
	_assert_equal(effect_defaults["stat_max_hp"], 10, "M3 effect default max hp")
	_assert_equal(effect_defaults["dodge_cap"], 60, "M3 effect default dodge cap")
	_assert_equal(effect_defaults["weapon_slot"], 6, "M3 effect default weapon slots")
	_assert_equal(effect_defaults["harvesting_growth"], 5, "M3 effect default harvesting growth")
	_assert_equal(effect_defaults["hp_cap"], EffectKeysScript.INF_CAP, "M3 effect default hp cap")

	var character_ids := {}
	for character in characters:
		var character_id := String(character.get("id", ""))
		_assert_true(not character_ids.has(character_id), "unique character id %s" % character_id)
		character_ids[character_id] = true
		_validate_source_ref(character, "character %s" % character_id)
		_assert_true(character.get("effects", []).size() > 0, "character %s has effect payloads" % character_id)
		if not ["character_beast_master", "character_bull"].has(character_id):
			_assert_true(character.get("starting_weapons", []).size() > 0, "character %s has starting weapon choices" % character_id)
		for effect in character.get("effects", []):
			_validate_effect_reference(effect, "character %s" % character_id)

	var family_ids := {}
	for family in weapon_families:
		var family_id := String(family.get("id", ""))
		_assert_true(not family_ids.has(family_id), "unique weapon family id %s" % family_id)
		family_ids[family_id] = true
		_validate_source_ref(family, "weapon family %s" % family_id)
		_assert_equal(family.get("quality_slots", []).size(), 4, "weapon family %s has four quality slots" % family_id)
		_assert_resource_exists(String(family.get("asset_refs", {}).get("icon", "")), "weapon family %s icon" % family_id)

	for variant in weapon_variants:
		var variant_id := String(variant.get("id", ""))
		_validate_source_ref(variant, "weapon variant %s" % variant_id)
		_assert_true(family_ids.has(String(variant.get("family_id", ""))), "weapon variant %s references a known family" % variant_id)
		_assert_resource_exists(String(variant.get("asset_refs", {}).get("icon", "")), "weapon variant %s icon" % variant_id)
		_assert_resource_exists(String(variant.get("asset_refs", {}).get("texture", "")), "weapon variant %s texture" % variant_id)
		for scaling_key in variant.get("scaling_stats", {}).keys():
			_assert_true(EffectKeysScript.has_key(String(scaling_key)) or String(scaling_key) == "stat_levels", "weapon variant %s scaling key %s exists" % [variant_id, scaling_key])
		for effect in variant.get("effects", []):
			_validate_effect_reference(effect, "weapon variant %s" % variant_id)

	var item_ids := {}
	for item in items:
		var item_id := String(item.get("id", ""))
		_assert_true(not item_ids.has(item_id), "unique item id %s" % item_id)
		item_ids[item_id] = true
		_validate_source_ref(item, "item %s" % item_id)
		_assert_resource_exists(String(item.get("asset_refs", {}).get("icon", "")), "item %s icon" % item_id)
		_assert_true(item.get("effects", []).size() > 0, "item %s has effect payloads" % item_id)
		for effect in item.get("effects", []):
			_validate_effect_reference(effect, "item %s" % item_id)

	var weapon_sets: Array = tags_sets_json.get("weapon_sets", [])
	var item_tags: Dictionary = tags_sets_json.get("item_tags", {})
	var unlock_metadata: Dictionary = tags_sets_json.get("unlock_metadata", {})
	var banned_item_groups: Dictionary = tags_sets_json.get("banned_item_groups", {})
	_assert_equal(weapon_sets.size(), 15, "M3 weapon set count")
	_assert_true(item_tags.has("stat_max_hp"), "M3 item tag index contains stat_max_hp")
	_assert_true(item_tags.has("pet"), "M3 item tag index contains pet")
	_assert_equal(unlock_metadata.size(), 49, "M3 unlock metadata covers all characters")
	_assert_true(banned_item_groups.has("harvesting"), "M3 banned item groups include harvesting")

	var self_test := _load_text("res://SELF_TEST_M3.md")
	for sample_id in [
		"character_well_rounded",
		"character_mage",
		"weapon_pistol_1",
		"weapon_wrench_4",
		"item_alien_tongue",
		"item_hourglass",
	]:
		_assert_true(self_test.contains(sample_id), "SELF_TEST_M3 includes sample %s" % sample_id)

func _combat_m2c_tests() -> void:
	var player: Variant = PlayerDataScript.new()
	var runtime: Variant = CombatRuntimeScript.new()
	runtime.start_run(player, 1, 2, 0)
	player.add_permanent_stat("stat_armor", 15)
	var hit: Dictionary = runtime.resolve_player_damage(4, false)
	_assert_equal(hit["damage"], 2, "player contact damage uses armor coefficient")
	_assert_equal(player.current_health, 8, "player damage subtracts health")
	_assert_approx(runtime.iframe_seconds_remaining, 0.4, "player hit grants iframe clamp")
	var iframe_block: Dictionary = runtime.resolve_player_damage(4, false)
	_assert_true(not bool(iframe_block["accepted"]), "iframes block repeated contact damage")
	runtime.advance(0.4)
	player.add_permanent_stat("stat_dodge", 60)
	var dodge: Dictionary = runtime.resolve_player_damage(4, true, false, false, 0.0)
	_assert_true(bool(dodge["dodged"]), "dodge can prevent player damage")
	_assert_equal(player.current_health, 8, "dodged damage leaves health unchanged")
	_assert_approx(runtime.iframe_seconds_remaining, 0.2, "dodged hit grants minimum iframes")
	runtime.advance(0.2)
	var death: Dictionary = runtime.resolve_player_damage(99, false, true)
	_assert_equal(death["state"], CombatRuntimeScript.STATE_LOST, "lethal player damage sets loss state")
	_assert_equal(player.current_health, 0, "lethal player damage clamps health to zero")

	player = PlayerDataScript.new()
	runtime = CombatRuntimeScript.new()
	runtime.start_run(player, 1, 2, 0)
	var enemy := {
		"position": Vector2(20, 0),
		"hp": 2,
		"max_hp": 2,
		"speed": 250.0,
		"damage": 1,
		"knockback_resistance": 0.5,
		"value": 1,
	}
	var enemy_hit: Dictionary = runtime.apply_enemy_damage(enemy, 3, Vector2.ZERO, 15.0)
	_assert_true(bool(enemy_hit["dead"]), "enemy lethal hit marks death")
	_assert_approx(Vector2(enemy_hit["knockback_vector"]).length(), 15.0, "enemy death knockback keeps minimum amount")
	_assert_approx(runtime.enemy_knockback_velocity(enemy).length(), 750.0, "enemy knockback velocity applies resistance")
	_assert_true(not runtime.enemy_can_contact_damage(enemy), "strong knockback disables contact damage")
	runtime.decay_enemy_knockback(enemy)
	_assert_approx(Vector2(enemy["knockback_vector"]).length(), 13.5, "enemy knockback decays by 10 percent per tick")

	player = PlayerDataScript.new()
	runtime = CombatRuntimeScript.new()
	runtime.start_run(player, 5, 5, 0)
	player.add_permanent_stat("gold_drops", 100)
	enemy = {"position": Vector2(12, 20), "value": 1, "can_drop_material": true}
	var materials: Array = []
	_assert_true(runtime.spawn_material_from_enemy(enemy, materials, 5, false, 0.0, 0.0), "enemy material drop can spawn")
	_assert_equal(materials.size(), 1, "material drop appends an entity")
	_assert_equal(materials[0]["value"], 2, "material value includes gold_drops scaling")
	for i in CombatRuntimeScript.MATERIAL_ENTITY_LIMIT - materials.size():
		runtime.add_material_drop(materials, Vector2.ZERO, 1)
	var merged: Dictionary = runtime.add_material_drop(materials, Vector2.ZERO, 3, 0)
	_assert_equal(materials.size(), CombatRuntimeScript.MATERIAL_ENTITY_LIMIT, "material cap merges excess drops")
	_assert_equal(merged["value"], 5, "merged material accumulates value")

	player = PlayerDataScript.new()
	runtime = CombatRuntimeScript.new()
	runtime.start_run(player, 1, 1, 0)
	player.add_permanent_stat("chance_double_gold", 100)
	player.add_permanent_stat("heal_when_pickup_gold", 100)
	player.current_health = 5
	var pickup_material: Dictionary = runtime.make_material(Vector2(10, 0), 2)
	var pickup: Dictionary = runtime.update_material_attraction(pickup_material, Vector2.ZERO, 1.0 / 60.0, 0.0, 0.0)
	_assert_true(bool(pickup["collected"]), "material inside pickup radius collects immediately")
	_assert_equal(pickup["value"], 4, "material pickup can double value")
	_assert_equal(player.materials, 4, "material pickup adds money")
	_assert_equal(player.current_xp, 4.0, "material pickup adds equal xp")
	_assert_equal(player.current_health, 6, "heal_when_pickup_gold heals one hp")
	var flying_material: Dictionary = runtime.make_material(Vector2(140, 0), 1)
	runtime.update_material_attraction(flying_material, Vector2.ZERO, 1.0 / 60.0)
	_assert_true(Vector2(flying_material["position"]).x < 140.0, "material inside pickup range attracts toward player")

	player = PlayerDataScript.new()
	runtime = CombatRuntimeScript.new()
	runtime.start_run(player, 1, 2, 0)
	player.add_permanent_stat("stat_harvesting", 10)
	materials = [runtime.make_material(Vector2.ZERO, 2), runtime.make_material(Vector2.ZERO, 3)]
	var live_enemies := [{"id": "a"}, {"id": "b"}]
	var settlement: Dictionary = runtime.complete_wave(live_enemies, materials)
	_assert_equal(settlement["state"], CombatRuntimeScript.STATE_RUNNING, "non-final wave keeps run active")
	_assert_equal(runtime.current_wave, 2, "wave completion advances to next wave")
	_assert_equal(live_enemies.size(), 0, "wave completion clears living enemies")
	_assert_equal(materials.size(), 0, "wave completion clears ground materials")
	_assert_equal(runtime.bonus_gold, 5, "wave completion recovers ground materials into bonus gold")
	_assert_equal(player.materials, 10, "harvesting grants materials")
	_assert_equal(player.current_xp, 10.0, "harvesting grants xp")
	_assert_equal(player.effects["stat_harvesting"], 11, "harvesting grows at wave end")
	runtime.start_wave(2)
	runtime.complete_wave([], [])
	_assert_equal(runtime.state, CombatRuntimeScript.STATE_WON, "final starter wave completion sets win state")

func _economy_m3b_tests() -> void:
	_assert_equal(formulas.roll_shop_tier(10, 0, 0.001), 3, "shop tier roll hits tier IV first")
	_assert_equal(formulas.roll_shop_tier(10, 0, 0.05), 2, "shop tier roll hits tier III")
	_assert_equal(formulas.roll_shop_tier(10, 0, 0.30), 1, "shop tier roll hits tier II")
	_assert_equal(formulas.roll_shop_tier(10, 0, 0.80), 0, "shop tier roll falls back to tier I")
	_assert_equal(formulas.roll_shop_tier(10, 0, 0.80, 1, 3, 1), 1, "shop tier increase clamps after result")
	_assert_equal(formulas.shop_price(20, 5), 35, "shop item price formula")
	_assert_equal(formulas.shop_price(20, 5, -20), 28, "shop item price discount")
	_assert_equal(formulas.shop_price(10, 5, 0, 0, 100, true), 35, "weapon price modifies base value before wave formula")
	_assert_equal(formulas.shop_price(10, 5, 0, 0, 100, true, true), 2, "hp shop price uses ceil original over 20")
	_assert_equal(formulas.reroll_price_breakdown(10, 2, -50)["paid"], 10, "reroll price discount applies to paid amount")
	_assert_equal(formulas.recycle_value(40, 20, 0), 10, "default recycle value is 25 percent")
	_assert_equal(formulas.recycle_value(40, 20, 35), 24, "recycling machine raises recycle value to 60 percent")
	_assert_equal(formulas.recycle_value(40, 1, 35), 1, "base value one always recycles for one")
	_assert_equal(formulas.material_drop_amount(3.0, 50, 0, 0, 1, 1.0, 1.0), 4, "material drop floors boosted value without fractional bonus")
	_assert_equal(formulas.material_drop_amount(3.0, 50, 0, 0, 1, 1.0, 0.0), 5, "material drop fractional part can add one")
	_assert_equal(formulas.consumable_heal(2), 5, "fruit heal uses consumable_heal")
	_assert_approx(formulas.consumable_drop_chance(0.2, 50, 0.5), 0.2, "consumable drop chance luck and endless")
	_assert_approx(formulas.crate_drop_chance(0.2, 50, 2, 25), 0.125, "crate drop chance divides by previous crates and applies crate chance")

	var rng := RandomNumberGenerator.new()
	rng.seed = 99173
	var counts := [0, 0, 0, 0]
	var samples := 20000
	for i in samples:
		counts[formulas.roll_shop_tier(10, 0, rng.randf())] += 1
	_assert_approx(float(counts[3]) / float(samples), formulas.shop_tier_chance(3, 10), "statistical tier IV shop rate", 0.01)
	_assert_approx(float(counts[2]) / float(samples), formulas.shop_tier_chance(2, 10) - formulas.shop_tier_chance(3, 10), "statistical tier III shop rate", 0.015)
	_assert_approx(float(counts[1]) / float(samples), formulas.shop_tier_chance(1, 10) - formulas.shop_tier_chance(2, 10), "statistical tier II shop rate", 0.02)

	var catalog: Variant = EconomyCatalogScript.from_json()
	_assert_true(catalog.get_entry("item_coupon").size() > 0, "economy fixture catalog loads items")
	var max_player: Variant = PlayerDataScript.new()
	max_player.add_item(catalog.get_entry("item_recycling_machine"))
	_assert_equal(catalog.pool("item", 1, max_player).size(), 1, "max_nb filters owned shop items")

	var shop_player: Variant = PlayerDataScript.new()
	shop_player.materials = 999
	var shop: Variant = ShopStateScript.open(shop_player, catalog, 1, true, {
		"weapon_preference_rolls": [1.0],
		"kind_rolls": [1.0, 1.0],
		"tier_rolls": [0.99, 0.99, 0.99, 0.99],
		"pick_rolls": [0.0, 0.2, 0.0, 0.5],
		"tag_rolls": [1.0, 1.0],
	})
	var weapon_slots := 0
	for slot in shop.slots:
		var slot_data: Dictionary = slot
		if String(slot_data.get("kind", "")) == "weapon":
			weapon_slots += 1
	_assert_equal(weapon_slots, 2, "wave one shop guarantees two weapons")
	var locked_price: int = shop.slot_price(0, shop_player)
	var locked_id := String(shop.slots[0].get("id", ""))
	_assert_true(shop.toggle_lock(0, shop_player), "shop slot can be locked")
	var next_shop: Variant = ShopStateScript.open(shop_player, catalog, 2, true, {
		"weapon_preference_rolls": [1.0],
		"kind_rolls": [1.0, 1.0],
		"tier_rolls": [0.99, 0.99, 0.99],
		"pick_rolls": [0.0, 0.0, 0.0],
		"tag_rolls": [1.0, 1.0],
	})
	_assert_equal(String(next_shop.slots[0].get("id", "")), locked_id, "locked shop item carries into next shop")
	_assert_equal(next_shop.slot_price(0, shop_player), locked_price, "locked shop item keeps old wave price")
	var materials_before_reroll: int = shop_player.materials
	var reroll_result: Dictionary = next_shop.reroll(shop_player, catalog, {
		"weapon_preference_rolls": [1.0],
		"kind_rolls": [1.0, 1.0],
		"tier_rolls": [0.99, 0.99, 0.99],
		"pick_rolls": [0.0, 0.0, 0.0],
		"tag_rolls": [1.0, 1.0],
	})
	_assert_true(reroll_result["ok"], "paid reroll succeeds")
	_assert_equal(reroll_result["cost"], 2, "wave two paid reroll price")
	_assert_equal(shop_player.materials, materials_before_reroll - 2, "paid reroll deducts materials")
	_assert_equal(String(next_shop.slots[0].get("id", "")), locked_id, "reroll preserves locked slot")

	var free_player: Variant = PlayerDataScript.new()
	free_player.materials = 100
	free_player.apply_effect(EffectEntryScript.make("free_rerolls", 1))
	var free_shop: Variant = ShopStateScript.open(free_player, catalog, 3, true, {
		"weapon_preference_rolls": [1.0],
		"kind_rolls": [1.0, 1.0, 1.0],
		"tier_rolls": [0.99, 0.99, 0.99, 0.99],
		"pick_rolls": [0.0, 0.0, 0.0, 0.0],
		"tag_rolls": [1.0, 1.0, 1.0],
	})
	var free_result: Dictionary = free_shop.reroll(free_player, catalog, {
		"weapon_preference_rolls": [1.0],
		"kind_rolls": [1.0, 1.0, 1.0],
		"tier_rolls": [0.99, 0.99, 0.99, 0.99],
		"pick_rolls": [0.0, 0.0, 0.0, 0.0],
		"tag_rolls": [1.0, 1.0, 1.0],
	})
	_assert_true(free_result["free"], "free_rerolls makes first reroll free")
	_assert_equal(free_result["cost"], 0, "free reroll has zero cost")
	_assert_equal(free_shop.paid_rerolls, 0, "free reroll does not increment paid count")

	var buy_player: Variant = PlayerDataScript.new()
	buy_player.materials = 100
	var buy_shop: Variant = ShopStateScript.new()
	buy_shop.wave = 1
	var coupon: Dictionary = catalog.get_entry("item_coupon")
	coupon["wave_value"] = 1
	buy_shop.slots = [coupon]
	var buy_result: Dictionary = buy_shop.buy_slot(0, buy_player, catalog)
	_assert_true(buy_result["ok"], "buying an item succeeds")
	_assert_equal(buy_player.materials, 82, "buying coupon deducts documented price")
	_assert_equal(buy_player.get_stat("items_price"), -5.0, "buying item applies effects")

	var combine_player: Variant = PlayerDataScript.new()
	combine_player.materials = 100
	combine_player.add_permanent_stat("weapon_slot", -5)
	combine_player.add_weapon(catalog.get_entry("weapon_pistol_t1"))
	var combine_shop: Variant = ShopStateScript.new()
	combine_shop.wave = 1
	var pistol: Dictionary = catalog.get_entry("weapon_pistol_t1")
	pistol["wave_value"] = 1
	combine_shop.slots = [pistol]
	var combine_result: Dictionary = combine_shop.buy_slot(0, combine_player, catalog)
	_assert_true(combine_result["ok"], "full weapon slots can buy-combine same weapon")
	_assert_equal(combine_result["upgraded_to"], "weapon_pistol_t2", "buy-combine upgrades to next tier")
	_assert_equal(combine_player.weapons.size(), 1, "buy-combine keeps slot count stable")
	_assert_equal(String(combine_player.weapons[0].get("id", "")), "weapon_pistol_t2", "inventory contains upgraded weapon")

	var recycle_player: Variant = PlayerDataScript.new()
	recycle_player.apply_effect(EffectEntryScript.make("recycling_gains", 35))
	recycle_player.add_weapon(catalog.get_entry("weapon_smg_t1"))
	var recycle_shop: Variant = ShopStateScript.new()
	recycle_shop.wave = 5
	var recycle_result: Dictionary = recycle_shop.recycle_weapon(0, recycle_player)
	_assert_true(recycle_result["ok"], "weapon recycling succeeds")
	_assert_equal(recycle_result["value"], 21, "weapon recycling uses current shop price and recycling gains")
	_assert_equal(recycle_player.materials, 21, "weapon recycling pays materials")

	var level_pool: Variant = LevelUpPoolScript.new()
	var level_player: Variant = PlayerDataScript.new()
	var level_options: Array = level_pool.generate_options(5, level_player, [], {
		"tier_rolls": [0.99, 0.99, 0.99, 0.99],
		"pick_rolls": [0.0, 0.0, 0.0, 0.0],
	})
	_assert_equal(level_options.size(), 4, "level up generates four options")
	_assert_equal(level_options[0]["tier"], 1, "level five forces tier II upgrades")
	_assert_equal(level_options[0]["value"], 6, "tier II max hp upgrade value")
	level_pool.apply_option(level_player, level_options[0])
	_assert_equal(level_player.get_max_health(), 16, "applying max hp level option changes stat")
	_assert_equal(level_player.current_health, 16, "max hp level option heals by increase")
	var forced_slot_player: Variant = PlayerDataScript.new()
	forced_slot_player.add_permanent_stat("weapon_slot", -4)
	forced_slot_player.apply_effect(EffectEntryScript.make("weapon_slot_upgrades", 6))
	var forced_options: Array = level_pool.generate_options(2, forced_slot_player)
	_assert_equal(forced_options.size(), 1, "weapon slot upgrades force slot option")
	_assert_equal(forced_options[0]["key"], "weapon_slot", "forced level option is weapon slot")

	var reward: Variant = RewardResolverScript.new()
	var reward_player: Variant = PlayerDataScript.new()
	reward_player.apply_effect(EffectEntryScript.make("chance_double_gold", 100))
	var pickup_result: Dictionary = reward.pickup_material(reward_player, 5, 0.0)
	_assert_equal(pickup_result["materials"], 10, "material pickup can double gold")
	_assert_equal(reward_player.materials, 10, "material pickup adds money")
	var harvest_player: Variant = PlayerDataScript.new()
	harvest_player.add_permanent_stat("stat_harvesting", 10)
	var harvest_result: Dictionary = reward.settle_harvesting(harvest_player, 1)
	_assert_equal(harvest_result["value"], 10, "harvesting grants materials")
	_assert_equal(harvest_result["growth"], 1, "harvesting grows by default five percent rounded up")
	_assert_equal(harvest_player.materials, 10, "harvesting settlement adds money")
	_assert_equal(harvest_player.get_stat("stat_harvesting"), 11.0, "harvesting growth is permanent")
	var negative_harvest_player: Variant = PlayerDataScript.new()
	negative_harvest_player.materials = 10
	negative_harvest_player.add_permanent_stat("stat_harvesting", -5)
	var negative_result: Dictionary = reward.settle_harvesting(negative_harvest_player, 1)
	_assert_equal(negative_result["value"], -5, "negative harvesting computes negative value")
	_assert_equal(negative_harvest_player.materials, 5, "negative harvesting deducts only money")
	_assert_equal(reward.collect_bonus_gold([{"value": 2}, {"value": 3}]), 5, "ground materials collect into bonus gold")
	var repayment: Dictionary = reward.repay_bonus_gold(3, 5)
	_assert_equal(repayment["value"], 6, "bonus gold doubles next material up to its value")
	_assert_equal(repayment["remaining_bonus_gold"], 2, "bonus gold repayment decrements pool")

func _ui_flow_m4_tests() -> void:
	var main: Node = MainScene.instantiate()
	root.add_child(main)
	_assert_equal(main.ui_state_name(), "title", "M4 UI starts at title")
	main.start_new_run()
	_assert_equal(main.ui_state_name(), "character_select", "new run opens character selection")
	main.choose_character("well_rounded")
	_assert_equal(main.ui_state_name(), "weapon_select", "character selection opens weapon selection")
	main.choose_weapon("weapon_pistol")
	_assert_equal(main.ui_state_name(), "danger_select", "weapon selection opens danger selection")
	main.choose_danger(0)
	_assert_equal(main.ui_state_name(), "combat", "danger selection starts combat")
	main.force_wave_complete_for_smoke()
	_assert_equal(main.ui_state_name(), "wave_complete", "combat can enter wave-complete flow")
	main.continue_wave_end()
	_assert_equal(main.ui_state_name(), "crate_reward", "wave-complete flow processes crate rewards before level-ups")
	main.accept_crate_reward()
	_assert_equal(main.ui_state_name(), "level_up", "crate reward advances to level-up screen")
	_assert_true(main.current_level_options.size() > 0, "level-up screen has generated options")
	main.choose_level_option(0)
	_assert_equal(main.ui_state_name(), "shop", "level-up flow advances to shop")
	_assert_true(main.current_shop.slots.size() > 0, "shop opens with fixture slots")
	var previous_wave: int = main.current_wave
	main.leave_shop()
	_assert_equal(main.ui_state_name(), "combat", "GO starts the next combat wave")
	_assert_equal(main.current_wave, previous_wave + 1, "GO increments the wave")
	_assert_true(bool(main.floating_text_rule("enemy_damage")["uses_damage_toggle"]), "enemy damage numbers obey damage_display setting")
	_assert_true(bool(main.floating_text_rule("material")["always_display"]), "material floating text is an always-display HUD contract")
	main.queue_free()

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

func _assert_resource_exists(path: String, label: String) -> void:
	assertions_run += 1
	if path == "" or not FileAccess.file_exists(path):
		failures.append("%s: missing resource %s" % [label, path])

func _validate_source_ref(record: Dictionary, label: String) -> void:
	_assert_true(record.has("source_ref"), "%s has source_ref" % label)
	var ref: Dictionary = record.get("source_ref", {})
	_assert_true(String(ref.get("doc", "")).ends_with(".md"), "%s source_ref doc is markdown" % label)
	_assert_true(int(ref.get("line", 0)) > 0, "%s source_ref has positive line" % label)

func _validate_effect_reference(effect: Dictionary, label: String) -> void:
	if not effect.has("key"):
		_assert_true(effect.has("source_text"), "%s raw effect keeps source text" % label)
		return
	var key := String(effect.get("key", ""))
	var custom_key := String(effect.get("custom_key", ""))
	if custom_key != "":
		_assert_true(EffectKeysScript.has_key(custom_key), "%s custom effect key %s exists" % [label, custom_key])
	elif key.begins_with("item_") or key.begins_with("weapon_"):
		_assert_true(key != "", "%s item/weapon append key is present" % label)
	else:
		_assert_true(EffectKeysScript.has_key(key), "%s effect key %s exists" % [label, key])

func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null:
		failures.append("could not parse JSON: %s" % path)
		return {}
	return parsed

func _load_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		failures.append("missing text file: %s" % path)
		return ""
	return FileAccess.get_file_as_string(path)
