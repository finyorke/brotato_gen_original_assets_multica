extends SceneTree

const EffectEntryScript = preload("res://src/core/effect_entry.gd")
const EffectKeysScript = preload("res://src/core/effect_keys.gd")
const PlayerDataScript = preload("res://src/core/player_data.gd")
const FormulasScript = preload("res://src/core/formulas.gd")
const BurnDataScript = preload("res://src/core/burn_data.gd")
const WeaponStatsScript = preload("res://src/combat/weapon_stats.gd")
const WeaponAttackRuntimeScript = preload("res://src/combat/weapon_attack_runtime.gd")
const EnemyStatsScript = preload("res://src/combat/enemy_stats.gd")
const TargetingScript = preload("res://src/combat/targeting.gd")
const WaveSchedulerScript = preload("res://src/combat/wave_scheduler.gd")
const CombatRuntimeScript = preload("res://src/combat/combat_runtime.gd")
const EconomyCatalogScript = preload("res://src/economy/economy_catalog.gd")
const ShopStateScript = preload("res://src/economy/shop_state.gd")
const LevelUpPoolScript = preload("res://src/economy/level_up_pool.gd")
const RewardResolverScript = preload("res://src/economy/reward_resolver.gd")
const MainScene = preload("res://scenes/main.tscn")
const AssetManifestScript = preload("res://src/presentation/asset_manifest.gd")
const PresentationRulesScript = preload("res://src/presentation/presentation_rules.gd")
const AudioRulesScript = preload("res://src/presentation/audio_rules.gd")
const ChallengeRegistryScript = preload("res://src/progression/challenge_registry.gd")
const ProgressionStateScript = preload("res://src/progression/progression_state.gd")
const SaveServiceScript = preload("res://src/progression/save_service.gd")
const GameSettingsScript = preload("res://src/settings/game_settings.gd")
const CoopStateScript = preload("res://src/coop/coop_state.gd")

var failures: Array = []
var assertions_run: int = 0
var formulas: Variant = FormulasScript.new()
var burn_tools: Variant = BurnDataScript.new()
var attack_runtime: Variant = WeaponAttackRuntimeScript.new()

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
	_weapon_runtime_m2_tests()
	_content_m3_tests()
	_combat_m2c_tests()
	_economy_m3b_tests()
	_ui_flow_m4_tests()
	_presentation_m5_tests()
	_progression_m6_tests()
	_save_settings_m6_tests()
	_coop_m6_tests()

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
	_assert_approx(formulas.weapon_attack_duration_seconds(100, 0), 0.4142857143, "attack duration range factor")
	_assert_approx(formulas.weapon_attack_duration_seconds(100, 60), 0.3185714286, "attack duration attack speed")
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
	_assert_equal(formulas.danger_effects(5)["danger_enemy_damage"], 40, "danger 5 applies documented enemy damage")
	_assert_equal(formulas.danger_elite_event_count(4), 3, "danger 4 schedules three elite events")
	_assert_equal(formulas.danger_boss_count(5), 2, "danger 5 uses double boss")
	_assert_approx(formulas.coop_enemy_damage_multiplier(4), 1.24, "coop damage uses eight percent per extra player")
	_assert_approx(formulas.coop_material_value_multiplier(2), 1.430769, "coop material compensation uses documented factor", 0.00001)
	_assert_approx(formulas.endless_hp_multiplier(formulas.endless_factor(21)), 1.045, "endless hp multiplier uses 2.25 coefficient")
	_assert_equal(formulas.enemy_damage(10, 0, 21, 0, 1.4, formulas.endless_factor(21), 4), 18, "enemy damage combines danger coop and endless")
	_assert_equal(formulas.enemy_speed(100, 20, 0.5, formulas.endless_factor(40)), 88, "enemy speed applies accessibility and endless cap")
	_assert_equal(formulas.endless_max_enemies(100, 21), 135, "endless reuses wave index for enemy cap")
	_assert_equal(formulas.endless_extra_group_count(30), 6, "endless extra group count")

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
	_assert_equal(enemy_json["enemies"].size(), 25, "area 1 enemy data includes normal enemies, tree, and bosses")
	var baby: Variant = EnemyStatsScript.from_dict(enemy_json["enemies"][0])
	_assert_equal(baby.max_health_for_wave(5), 11, "baby alien hp wave scaling")
	player.add_permanent_stat("enemy_health", 50)
	_assert_equal(baby.max_health_for_wave(5, player), 17, "enemy_health effect scales enemy hp")
	_assert_equal(baby.contact_damage_for_wave(3), 2, "baby alien damage wave scaling")
	_assert_equal(baby.speed_for_roll(1.0), 300.0, "enemy speed randomization upper bound")
	_assert_equal(baby.instantiate(1, Vector2(12, 24))["hp"], 3, "enemy instantiate carries hp")
	var helmet: Variant = EnemyStatsScript.from_dict(_enemy_row(enemy_json, "helmet_alien"))
	_assert_equal(helmet.max_health_for_wave(13), 56, "helmet alien hp scaling row")
	var horned_charger: Variant = EnemyStatsScript.from_dict(_enemy_row(enemy_json, "horned_charger"))
	_assert_equal(horned_charger.contact_damage_for_wave(18), 20, "horned charger damage scaling row")
	var junkie_row := _enemy_row(enemy_json, "junkie")
	_assert_equal(junkie_row["item_drop_chance"], 0.01, "junkie keeps literal documented item chance")
	_assert_equal(junkie_row["can_drop_consumable"], false, "junkie still cannot drop consumables")
	var tree: Variant = EnemyStatsScript.from_dict(_enemy_row(enemy_json, "tree"))
	_assert_equal(tree.entity_type, "neutral", "tree row remains neutral data")
	_assert_approx(tree.material_drop_chance(20), 1.0, "always-drop rows bypass wave material chance")
	_assert_true(String(_enemy_row(enemy_json, "tree").get("source", "")).contains("tree_stats"), "tree stat row cites asset mapping source")

	var wave_json := _load_json("res://data/m2/area1_waves.json")
	_assert_equal(wave_json["waves"].size(), 20, "area 1 wave table includes all 20 waves")
	_assert_equal(wave_json["common_groups"].size(), 3, "area 1 common groups are encoded once")
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

	var composite_scheduler: Variant = WaveSchedulerScript.from_dict(wave_json["waves"][15])
	var composite_requests: Array = composite_scheduler.advance(1.0, 0, 95)
	_assert_equal(composite_requests.size(), 2, "composite group emits one request per unit row")
	_assert_equal(composite_requests[0]["enemy_id"], "buffer", "composite group keeps first unit id")
	_assert_equal(composite_requests[1]["enemy_id"], "helmet_alien", "composite group keeps second unit id")
	_assert_equal(composite_requests[0]["performance_cull"], 7, "composite group culls against the combined group count")

	var boss_scheduler: Variant = WaveSchedulerScript.from_dict(wave_json["waves"][19])
	var boss_requests: Array = boss_scheduler.advance(0.0, 0, 0)
	_assert_equal(boss_requests.size(), 1, "boss group emits before the first elapsed second")
	_assert_true(bool(boss_requests[0].get("is_boss", false)), "boss request carries boss flag")
	_assert_equal(boss_requests[0]["enemy_pool"], ["predator", "invoker"], "boss request carries area 1 boss pool")

	_assert_danger0_wave_schedule_simulates(wave_json, enemy_json)

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
func _weapon_runtime_m2_tests() -> void:
	var player: Variant = PlayerDataScript.new()
	var damage_runtime: Variant = CombatRuntimeScript.new()
	var row := {
		"id": "runtime_ranged",
		"type": "ranged",
		"damage": 10,
		"scaling_stats": {},
		"cooldown": 400,
		"max_range": 200,
		"projectiles": 2,
		"projectile_spread": 0.2,
		"projectile_speed": 1000,
		"piercing": 1,
		"piercing_dmg_reduction": 0.5,
		"bounce": 1,
		"bounce_dmg_reduction": 0.5,
	}
	var weapon: Variant = WeaponStatsScript.from_dict(row)
	player.add_permanent_stat("projectiles", 2)
	player.add_permanent_stat("piercing", 1)
	player.add_permanent_stat("piercing_damage", 25)
	player.add_permanent_stat("bounce", 1)
	player.add_permanent_stat("bounce_damage", 25)
	_assert_equal(weapon.effective_projectile_count(player), 4, "extra projectiles only apply when base projectiles exist")
	_assert_approx(weapon.effective_projectile_spread(player), 0.4, "extra projectile spread adds 0.1 rad each")
	_assert_equal(weapon.effective_piercing(player), 2, "player piercing adds to weapon piercing")
	_assert_approx(weapon.effective_piercing_damage_reduction(player), 0.25, "piercing damage stat reduces pierce penalty")
	_assert_equal(weapon.effective_bounce(player), 2, "player bounce adds to weapon bounce")
	_assert_approx(weapon.effective_bounce_damage_reduction(player), 0.25, "bounce damage stat reduces bounce penalty")
	_assert_equal(attack_runtime.opening_cooldown_ticks(weapon, player), 180.0, "opening cooldown clamps to 180 ticks")
	_assert_equal(attack_runtime.tick_cooldown(10.0, 1.0 / 60.0), 9.0, "cooldown ticks down in frame units")
	_assert_equal(attack_runtime.tick_cooldown(10.0, 1.0, true), 10.0, "cooldown pauses during attack windows")

	var moving_player: Variant = PlayerDataScript.new()
	moving_player.effects["can_attack_while_moving"] = 0
	var enemy := {"id": "gate", "position": Vector2(100, 0), "hp": 10}
	var readiness: Dictionary = attack_runtime.can_start_attack(weapon, moving_player, [enemy], Vector2.ZERO, 0.0, Vector2.RIGHT)
	_assert_true(not bool(readiness["can_attack"]), "attack gate blocks movement when effect disables moving attacks")

	var spread_weapon: Variant = WeaponStatsScript.from_dict({
		"id": "spread",
		"type": "ranged",
		"damage": 4,
		"cooldown": 10,
		"max_range": 200,
		"accuracy": 0.9,
		"projectiles": 3,
		"projectile_spread": 0.25,
		"projectile_speed": 1000,
	})
	var spread_attack: Dictionary = attack_runtime.start_attack(
		spread_weapon,
		PlayerDataScript.new(),
		Vector2.ZERO,
		0.0,
		100.0,
		1,
		false,
		{"accuracy_offset": 0.1, "projectile_spread_offsets": [-0.25, 0.0, 0.25]}
	)
	_assert_equal(spread_attack["projectiles"].size(), 3, "ranged attack creates one projectile state per row count")
	_assert_approx(spread_attack["projectiles"][0]["angle"], -0.15, "projectile angle includes accuracy and spread")
	_assert_approx(spread_attack["projectiles"][2]["angle"], 0.35, "projectile spread can offset both sides")
	_assert_approx(spread_attack["projectiles"][0]["remaining_lifetime"], 0.3, "projectile lifetime uses range plus 100 px")

	var melee_weapon: Variant = WeaponStatsScript.from_dict({
		"id": "runtime_sweep",
		"type": "melee",
		"damage": 8,
		"cooldown": 13,
		"max_range": 150,
		"attack_type": "sweep",
	})
	var windows: Dictionary = attack_runtime.attack_windows(melee_weapon, PlayerDataScript.new(), 80.0)
	_assert_approx(windows["reach"], 150.0, "sweep distance respects weapon max range")
	_assert_approx(windows["arc_radians"], 0.9 * PI, "sweep arc uses documented 0.9 pi side angle")
	_assert_approx(windows["active_windows"][0][1], float(windows["total_seconds"]) * 0.5, "melee active hit window closes before return by default")

	var hit_player: Variant = PlayerDataScript.new()
	hit_player.current_health = 5
	hit_player.add_permanent_stat("stat_elemental_damage", 3)
	hit_player.effects["enemy_percent_damage_taken"].append(["test_source", "stat_ranged_damage", 50])
	var hit_weapon: Variant = WeaponStatsScript.from_dict({
		"id": "hooked",
		"type": "ranged",
		"damage": 10,
		"scaling_stats": {"stat_ranged_damage": 1.0},
		"crit_chance": 1.0,
		"crit_damage": 2.0,
		"lifesteal": 1.0,
		"burning_data": {"chance": 1.0, "damage": 2, "duration": 3, "spread": 1},
	})
	var hit_packet: Dictionary = attack_runtime.build_hit_packet(hit_weapon, hit_player, 7)
	var hooked_enemy := {"id": "hooked_enemy", "position": Vector2.ZERO, "hp": 50, "max_hp": 50, "armor": 2}
	var hit_result: Dictionary = attack_runtime.apply_hit_packet(hit_packet, hooked_enemy, hit_player, {"crit_roll": 1.0, "lifesteal_roll": 0.0, "burn_roll": 0.0})
	_assert_true(hit_result["critical"], "crit roll uses <= weapon crit chance")
	_assert_equal(hit_result["direct_damage"], 28, "crit and vulnerability apply before enemy armor")
	_assert_equal(hooked_enemy["hp"], 50, "hit packet leaves enemy hp for combat runtime")
	damage_runtime.apply_enemy_damage(hooked_enemy, int(hit_result["direct_damage"]), Vector2.LEFT, float(hit_result["knockback"]))
	_assert_equal(hooked_enemy["hp"], 22, "combat runtime applies weapon direct damage")
	_assert_equal(hit_player.current_health, 6, "lifesteal hook heals one hp")
	_assert_true(hit_result["burn_applied"], "burn hook applies on successful burn roll")
	_assert_equal(hooked_enemy["burn_data"].damage, 5, "burn damage scales with elemental damage")
	_assert_equal(hit_result["vulnerability_hooks"].size(), 1, "vulnerability hook records matching scaling stat")

	var explosive_player: Variant = PlayerDataScript.new()
	explosive_player.add_permanent_stat("explosion_damage", 50)
	var explosive_weapon: Variant = WeaponStatsScript.from_dict({
		"id": "explosive",
		"type": "ranged",
		"damage": 10,
		"scaling_stats": {},
		"is_exploding": true,
		"explosion_scale": 1.25,
	})
	var explosive_packet: Dictionary = attack_runtime.build_hit_packet(explosive_weapon, explosive_player, 8)
	var explosive_enemy := {"id": "explosive_enemy", "position": Vector2(4, 0), "hp": 20, "max_hp": 20, "armor": 0}
	var explosion_result: Dictionary = attack_runtime.apply_hit_packet(explosive_packet, explosive_enemy, explosive_player, {"explosion_roll": 0.0})
	_assert_equal(explosive_enemy["hp"], 20, "unit-side explosion cancels direct damage")
	_assert_equal(explosion_result["explosion"]["damage"], 15, "explosion payload keeps weapon damage with explosion bonus")
	_assert_approx(explosion_result["explosion"]["scale"], 1.25, "explosion payload keeps row scale")

	var pierce_weapon: Variant = WeaponStatsScript.from_dict({
		"id": "piercer",
		"type": "ranged",
		"damage": 10,
		"scaling_stats": {},
		"cooldown": 10,
		"max_range": 100,
		"projectiles": 1,
		"projectile_speed": 1000,
		"piercing": 1,
		"piercing_dmg_reduction": 0.5,
	})
	var pierce_attack: Dictionary = attack_runtime.start_attack(pierce_weapon, PlayerDataScript.new(), Vector2.ZERO, 0.0, 50.0, 9, false, {"accuracy_offset": 0.0, "projectile_spread_offsets": [0.0]})
	var pierce_projectile: Dictionary = pierce_attack["projectiles"][0]
	var p1 := {"id": "p1", "position": Vector2(10, 0), "hp": 20, "max_hp": 20, "armor": 0}
	var p2 := {"id": "p2", "position": Vector2(20, 0), "hp": 20, "max_hp": 20, "armor": 0}
	var p1_result: Dictionary = attack_runtime.apply_projectile_hit(pierce_projectile, p1, PlayerDataScript.new(), [p1, p2], {"crit_roll": 1.0})
	_assert_equal(p1_result["direct_damage"], 10, "first projectile hit reports full damage")
	damage_runtime.apply_enemy_damage(p1, int(p1_result["direct_damage"]), p1_result["knockback_origin"], float(p1_result["knockback"]))
	_assert_equal(p1["hp"], 10, "combat runtime applies first projectile damage")
	_assert_true(not pierce_projectile["stopped"], "projectile remains alive after available pierce")
	_assert_equal(pierce_projectile["damage"], 5, "piercing reduces damage after hit")
	var p2_result: Dictionary = attack_runtime.apply_projectile_hit(pierce_projectile, p2, PlayerDataScript.new(), [p1, p2], {"crit_roll": 1.0})
	_assert_equal(p2_result["direct_damage"], 5, "pierced projectile reports reduced damage")
	damage_runtime.apply_enemy_damage(p2, int(p2_result["direct_damage"]), p2_result["knockback_origin"], float(p2_result["knockback"]))
	_assert_equal(p2["hp"], 15, "combat runtime applies pierced projectile damage")
	_assert_true(pierce_projectile["stopped"], "projectile stops when no pierce remains")

	var bounce_weapon: Variant = WeaponStatsScript.from_dict({
		"id": "bouncer",
		"type": "ranged",
		"damage": 10,
		"scaling_stats": {},
		"cooldown": 10,
		"max_range": 100,
		"projectiles": 1,
		"projectile_speed": 1000,
		"piercing": 3,
		"piercing_dmg_reduction": 0.0,
		"bounce": 1,
		"bounce_dmg_reduction": 0.5,
		"knockback": 15,
	})
	var bounce_attack: Dictionary = attack_runtime.start_attack(bounce_weapon, PlayerDataScript.new(), Vector2.ZERO, 0.0, 50.0, 10, false, {"accuracy_offset": 0.0, "projectile_spread_offsets": [0.0]})
	var bounce_projectile: Dictionary = bounce_attack["projectiles"][0]
	var b1 := {"id": "b1", "position": Vector2(10, 0), "hp": 20, "max_hp": 20, "armor": 0}
	var b2 := {"id": "b2", "position": Vector2(30, 0), "hp": 20, "max_hp": 20, "armor": 0}
	var b1_result: Dictionary = attack_runtime.apply_projectile_hit(bounce_projectile, b1, PlayerDataScript.new(), [b1, b2], {"crit_roll": 1.0, "bounce_target_id": "b2"})
	_assert_equal(b1_result["direct_damage"], 10, "bounce hit reports current projectile damage")
	var b1_hit: Dictionary = damage_runtime.apply_enemy_damage(b1, int(b1_result["direct_damage"]), b1_result["knockback_origin"], float(b1_result["knockback"]))
	_assert_equal(b1["hp"], 10, "combat runtime applies bounced projectile damage")
	_assert_true(b1_hit["knockback_vector"] != Vector2.ZERO, "pre-bounce hit still applies projectile knockback")
	_assert_equal(bounce_projectile["damage"], 5, "bounce reduces damage after hit")
	_assert_equal(bounce_projectile["piercing_remaining"], 3, "bounce takes priority over piercing")
	_assert_equal(bounce_projectile["knockback"], 0.0, "bounce clears projectile knockback")
	_assert_approx(bounce_projectile["remaining_lifetime"], 10.0, "bounce retimes projectile to 10000 px lifetime")
	var b2_result: Dictionary = attack_runtime.apply_projectile_hit(bounce_projectile, b2, PlayerDataScript.new(), [b1, b2], {"crit_roll": 1.0})
	var b2_hit: Dictionary = damage_runtime.apply_enemy_damage(b2, int(b2_result["direct_damage"]), b2_result["knockback_origin"], float(b2_result["knockback"]))
	_assert_equal(b2["hp"], 15, "combat runtime applies post-bounce reduced damage")
	_assert_equal(b2_hit["knockback_vector"], Vector2.ZERO, "post-bounce hit keeps combat knockback zero")

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

func _presentation_m5_tests() -> void:
	var manifest: Variant = AssetManifestScript.load_from_path("res://data/m5/asset_manifest.json")
	var audit: Dictionary = manifest.representative_audit()
	_assert_equal(audit["source_docs"], 7, "M5 manifest points at all seven asset mapping docs")
	_assert_true(int(audit["weapon_count"]) >= 3, "M5 manifest includes starter weapon visuals")
	_assert_true(int(audit["enemy_count"]) >= 5, "M5 manifest includes area 1 enemy visuals")
	_assert_equal(audit["material_texture_count"], 11, "M5 manifest includes 11 material sprites")
	_assert_equal(audit["ground_theme_count"], 6, "M5 manifest includes six ground themes")
	_assert_equal(audit["music_track_count"], 11, "M5 manifest includes 11 music tracks")
	_assert_true(int(audit["sound_event_count"]) >= 9, "M5 manifest includes runtime sound event groups")
	_assert_true(int(audit["vfx_count"]) >= 10, "M5 manifest includes visual feedback rules")
	_assert_equal(audit["quality_tint_count"], 6, "M5 manifest includes tier color rules")

	var player_visual: Dictionary = manifest.player_visual()
	_assert_file_exists(String(player_visual["body_texture"]), "player body texture exists")
	_assert_equal(player_visual["weapon_container_offset"], [0.0, -24.0], "player weapon container offset follows mapping")
	_assert_equal(player_visual["shadow"]["position"], [0.0, 38.0], "player shadow offset follows mapping")
	_assert_equal(player_visual["legs"]["left_mount"], [15.0, 18.0], "player left leg mount follows mapping")

	var pistol: Dictionary = manifest.weapon_visual("weapon_pistol")
	_assert_file_exists(String(pistol["texture"]), "pistol texture exists")
	_assert_equal(pistol["muzzle"], [32.0, 0.0], "pistol muzzle mount follows mapping")
	_assert_equal(pistol["align_anchor"], [2.0, 16.0], "pistol align anchor follows mapping")
	_assert_equal(int(pistol["recoil"]), 25, "pistol recoil distance follows mapping")
	_assert_approx(float(pistol["recoil_duration"]), 0.1, "pistol recoil duration follows mapping")
	_assert_equal(manifest.sound_event("weapon_pistol_fire")["paths"].size(), 5, "pistol fire sound group has five variants")

	var smg: Dictionary = manifest.weapon_visual("weapon_smg")
	_assert_equal(int(smg["recoil"]), 10, "smg recoil distance follows mapping")
	_assert_approx(float(smg["recoil_duration"]), 0.05, "smg recoil duration follows mapping")
	_assert_approx(float(smg["effect_scale"]), 0.2, "smg hit effect scale follows mapping")
	_assert_equal(manifest.sound_event("weapon_smg_fire")["paths"].size(), 9, "smg fire sound group has nine variants")

	var fist: Dictionary = manifest.weapon_visual("weapon_fist")
	_assert_file_exists(String(fist["texture"]), "fist texture exists")
	_assert_equal(fist["hitbox_extents"], [48.0, 20.0], "fist hitbox extents follow mapping")
	_assert_equal(String(fist["attack_type"]), "thrust", "fist attack type follows mapping")

	var fly: Dictionary = manifest.enemy_visual("fly")
	_assert_file_exists(String(fly["texture"]), "fly texture exists")
	_assert_equal(fly["sprite_offset"], [0.0, -20.0], "fly sprite offset follows mapping")
	_assert_approx(float(fly["hurt_radius"]), 70.06, "fly hurt radius follows mapping")
	var charger: Dictionary = manifest.enemy_visual("charger")
	_assert_equal(charger["hurt_offset"], [0.0, -19.0], "charger hurt offset follows mapping")
	_assert_approx(float(charger["charge_prep_seconds"]), 0.4, "charger prep animation follows mapping")

	var rare: Color = manifest.quality_tint(2)
	_assert_approx(rare.r, 173.0 / 255.0, "rare tier red channel")
	_assert_approx(rare.g, 90.0 / 255.0, "rare tier green channel")
	_assert_approx(rare.b, 1.0, "rare tier blue channel")

	var hit_particles: Dictionary = manifest.vfx_data("hit_particles")
	_assert_file_exists(String(hit_particles["texture"]), "hit particle texture exists")
	_assert_equal(int(hit_particles["amount"]), 8, "hit particle amount follows mapping")
	_assert_approx(float(hit_particles["lifetime"]), 0.5, "hit particle lifetime follows mapping")
	_assert_approx(float(manifest.vfx_data("flash")["duration_seconds"]), 0.1, "flash duration follows mapping")

	var entries := PresentationRulesScript.weighted_ground_subtiles()
	_assert_equal(entries.size(), 12, "ground has 12 atlas subtiles")
	_assert_equal(PresentationRulesScript.total_weight(entries), 61, "ground tile weights total 61")
	_assert_approx(PresentationRulesScript.decorated_ground_probability(entries), 11.0 / 61.0, "ground decorated subtile probability")
	_assert_equal(PresentationRulesScript.pick_weighted_ground_subtile(0, entries), Vector2i(0, 0), "ground roll can select first decorated subtile")
	_assert_equal(PresentationRulesScript.pick_weighted_ground_subtile(10, entries), Vector2i(1, 3), "ground roll can select last decorated subtile")
	_assert_equal(PresentationRulesScript.pick_weighted_ground_subtile(60, entries), Vector2i(2, 3), "ground roll favors plain subtile")
	_assert_approx(PresentationRulesScript.material_scale(1, 2), 1.25, "boosted material scale")
	_assert_approx(PresentationRulesScript.material_scale(40, 1), 2.0, "merged material scale cap")
	_assert_equal(PresentationRulesScript.hit_effect_position(Vector2.ZERO, Vector2.RIGHT, 100.0), Vector2(25, 0), "hit effect offset uses texture width quarter")
	_assert_true(PresentationRulesScript.should_replace_screen_shake({"intensity": 1.0, "duration": 0.05}, {"intensity": 2.0, "duration": 0.1}), "stronger longer screen shake replaces current")
	_assert_true(not PresentationRulesScript.should_replace_screen_shake({"intensity": 3.0, "duration": 0.1}, {"intensity": 2.0, "duration": 0.2}), "weaker screen shake does not replace current")

	_assert_approx(AudioRulesScript.pitch_from_roll(0.2, 0.0), 0.8, "audio pitch lower bound")
	_assert_approx(AudioRulesScript.pitch_from_roll(0.2, 0.5), 1.0, "audio pitch center")
	_assert_approx(AudioRulesScript.pitch_from_roll(0.2, 1.0), 1.2, "audio pitch upper bound")
	var audio: Variant = AudioRulesScript.new()
	var base_event := {"paths": ["a.wav"], "pitch_rand": 0.2, "volume_db": -10}
	for i in 16:
		_assert_true(bool(audio.request_sound("base", base_event, 0.5, 0.0)["accepted"]), "audio queue accepts within limit")
	_assert_true(not bool(audio.request_sound("base", base_event, 0.5, 0.0)["accepted"]), "audio queue drops when full")
	var forced_event := {"paths": ["forced.wav"], "always_play": true}
	_assert_true(bool(audio.request_sound("forced", forced_event, 0.5, 0.0)["accepted"]), "always_play displaces queue head")
	_assert_equal(audio.queued_count(), 16, "always_play keeps queue capped")
	_assert_equal(audio.dequeue_frame().size(), 1, "audio dequeues one sound per frame")
	var limited_audio: Variant = AudioRulesScript.new()
	var limited_event := {"paths": ["pet.wav"], "max_play": 1}
	_assert_true(bool(limited_audio.request_sound("pet_voice", limited_event, 0.5, 0.0)["accepted"]), "limited sound queues first request")
	limited_audio.dequeue_frame()
	_assert_true(not bool(limited_audio.request_sound("pet_voice", limited_event, 0.5, 0.0)["accepted"]), "limited sound blocks over max_play")
	limited_audio.finish_sound("pet_voice")
	_assert_true(bool(limited_audio.request_sound("pet_voice", limited_event, 0.5, 0.0)["accepted"]), "limited sound accepts after finish")

	var all_music: Array = manifest.music_tracks(true, true)
	_assert_equal(all_music.size(), 11, "music pool can include all 11 tracks")
	_assert_equal(AudioRulesScript.music_pool(manifest.audio_data()["music_tracks"], false, true).size(), 5, "streamer music pool can be isolated")
	var shuffled := AudioRulesScript.shuffled_tracks(all_music, [0.0, 0.2, 0.4, 0.6, 0.8])
	_assert_equal(shuffled.size(), 11, "music shuffle preserves track count")
	var next_candidates := [{"id": "a"}, {"id": "b"}]
	_assert_equal(AudioRulesScript.next_track(next_candidates, "a")["id"], "b", "music next track avoids immediate repeat")
	_assert_equal(AudioRulesScript.music_volume_for_state(manifest.audio_data(), "wave_failed"), -20.0, "music failure ducking follows doc")
	_assert_equal(AudioRulesScript.music_volume_for_state(manifest.audio_data(), "shop"), -8.0, "music shop ducking follows doc")

func _progression_m6_tests() -> void:
	_assert_equal(ChallengeRegistryScript.count(), 113, "challenge registry exposes documented 113 base challenges")
	_assert_equal(ChallengeRegistryScript.by_id("fake_item_banned_item")["reward"], "ban_system", "ban system challenge is registered")
	_assert_equal(ChallengeRegistryScript.storage_id("chal_evil_hat"), "chal_evil_mob", "evil hat uses documented storage id")
	var state: Variant = ProgressionStateScript.new()
	_assert_true(state.can_select_danger("character_well_rounded", "zone_crash_site", 0), "danger 0 default unlocked")
	_assert_true(not state.can_select_danger("character_well_rounded", "zone_crash_site", 1), "danger 1 starts locked")
	var result: Dictionary = state.record_run_result({
		"won": true,
		"danger": 0,
		"wave": 20,
		"character_id": "character_well_rounded",
		"zone_id": "zone_crash_site",
		"enemy_scaling": {"health": 1.0, "damage": 1.0, "speed": 1.0},
		"retries": 0,
		"bans_used": 0,
	})
	_assert_true(result["completed_challenges"].has("unlock_difficulty_1"), "winning danger 0 completes danger unlock")
	_assert_true(result["completed_challenges"].has("chal_difficulty_0"), "winning danger 0 completes exact difficulty challenge")
	_assert_true(result["completed_challenges"].has("chal_well_rounded"), "winning with a character completes character win challenge")
	_assert_true(state.can_select_danger("character_brawler", "zone_crash_site", 1), "danger unlock is shared across characters")
	_assert_true(state.characters_unlocked.has("character_one_arm"), "danger zero challenge unlocks one arm")
	_assert_true(state.items_unlocked.has("item_potato"), "character win reward unlocks item")
	var worse_result: Dictionary = state.record_run_result({
		"won": true,
		"danger": 0,
		"wave": 20,
		"character_id": "character_well_rounded",
		"zone_id": "zone_crash_site",
		"enemy_scaling": {"health": 1.0, "damage": 1.0, "speed": 1.0},
		"retries": 2,
		"bans_used": 0,
	})
	_assert_true(not worse_result["completed_challenges"].has("chal_difficulty_0"), "completed challenges are idempotent")
	var info: Dictionary = state.get_difficulty_info("character_well_rounded", "zone_crash_site")
	_assert_equal(info["best_record"]["retries"], 0, "worse retry count does not replace best record")
	state.record_run_result({
		"won": true,
		"danger": 1,
		"wave": 25,
		"endless": true,
		"character_id": "character_well_rounded",
		"zone_id": "zone_crash_site",
	})
	info = state.get_difficulty_info("character_well_rounded", "zone_crash_site")
	_assert_equal(info["max_endless_wave_beaten"], 25, "endless wave record updates")
	_assert_true(state.systems_unlocked.has("ban_system"), "danger >=1 win unlocks ban system")

func _save_settings_m6_tests() -> void:
	var settings: Variant = GameSettingsScript.new()
	_assert_equal(settings.get_value("gameplay.share_coop_loot"), true, "share coop loot default")
	_assert_equal(settings.get_value("accessibility.enemy_scaling.health"), 1.0, "enemy scaling default")
	settings.set_value("gameplay.play_mode", "COOP")
	settings.set_value("accessibility.enemy_scaling.health", 0.75)
	_assert_true(settings.is_coop_enabled(), "settings can enable coop mode")
	var restored_settings: Variant = GameSettingsScript.from_dict(settings.to_dict())
	_assert_equal(restored_settings.enemy_scaling_snapshot()["health"], 0.75, "settings round trip keeps nested values")
	var service: Variant = SaveServiceScript.new("user://m6_tests")
	var progress: Variant = ProgressionStateScript.new()
	progress.complete_challenge("chal_hourglass")
	_assert_true(service.save_progress(0, progress), "progress save writes")
	_assert_true(service.save_settings(settings), "settings save writes")
	var loaded_progress: Variant = service.load_progress(0)
	_assert_true(loaded_progress.has_completed_challenge("chal_hourglass"), "progress save loads challenge")
	var loaded_settings: Variant = service.load_settings()
	_assert_equal(loaded_settings.get_value("gameplay.play_mode"), "COOP", "settings save loads gameplay value")
	_assert_true(service.save_run(0, {"wave": 9, "danger": 2, "players": [{"character_id": "character_well_rounded"}]}), "run save writes")
	_assert_equal(service.load_run(0)["wave"], 9, "run save loads")

func _coop_m6_tests() -> void:
	var coop: Variant = CoopStateScript.new()
	var p1: Variant = PlayerDataScript.new()
	var p2: Variant = PlayerDataScript.new()
	_assert_equal(coop.add_player(p1, "character_well_rounded", "weapon_pistol"), 0, "coop adds p1")
	_assert_equal(coop.add_player(p2, "character_brawler", "weapon_fist"), 1, "coop adds p2")
	var distributed: Dictionary = coop.pickup_material(5)
	_assert_equal(distributed["distribution"][0]["materials"], 3, "coop material rotates first share")
	_assert_equal(distributed["distribution"][1]["materials"], 2, "coop material rotates second share")
	_assert_equal(p1.materials, 3, "coop pickup credits p1 wallet")
	_assert_equal(p2.materials, 2, "coop pickup credits p2 wallet")
	_assert_equal(coop.assign_item_box(0, 0.0), 0, "first shared box can go to first tied queue")
	_assert_equal(coop.assign_item_box(0, 0.0), 1, "second shared box goes to shorter queue")
	coop.set_alive(0, false)
	_assert_true(not coop.all_players_dead(), "one living coop player keeps wave alive")
	coop.set_alive(1, false)
	_assert_true(coop.all_players_dead(), "all dead ends coop wave")
	coop.start_wave()
	_assert_equal(coop.living_player_count(), 2, "next wave respawns all players")
	coop.set_ready(0, true)
	_assert_true(not coop.all_ready(), "coop waits for all go states")
	coop.set_ready(1, true)
	_assert_true(coop.all_ready(), "coop all ready state")
	var context: Dictionary = coop.coop_enemy_context()
	_assert_approx(context["enemy_health_multiplier"], 1.3, "coop context exposes enemy hp scaling")

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

func _assert_file_exists(path: String, label: String) -> void:
	assertions_run += 1
	if not FileAccess.file_exists(path):
		failures.append("%s: missing %s" % [label, path])

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

func _enemy_row(enemy_json: Dictionary, enemy_id: String) -> Dictionary:
	for row in enemy_json.get("enemies", []):
		if String(row.get("id", "")) == enemy_id:
			return row
	failures.append("missing enemy row: %s" % enemy_id)
	return {}

func _assert_danger0_wave_schedule_simulates(wave_json: Dictionary, enemy_json: Dictionary) -> void:
	var enemy_ids := {}
	for row in enemy_json.get("enemies", []):
		enemy_ids[String(row.get("id", ""))] = true
	var seen_ids := {}
	var total_requests := 0
	var boss_requests := 0
	seed(12345)
	for wave in wave_json.get("waves", []):
		var scheduler: Variant = WaveSchedulerScript.from_dict(wave, wave_json.get("common_groups", []))
		var wave_requests: Array = scheduler.advance(0.0, 0, 0)
		for second in int(scheduler.duration_seconds):
			wave_requests.append_array(scheduler.advance(1.0, 0, 0))
		total_requests += wave_requests.size()
		for request in wave_requests:
			if bool(request.get("is_boss", false)):
				boss_requests += 1
			for enemy_id in _request_enemy_ids(request):
				_assert_true(enemy_ids.has(enemy_id), "wave schedule references known enemy id %s" % enemy_id)
				seen_ids[enemy_id] = true
	_assert_true(total_requests > 200, "Danger 0 simulation emits requests across the full run")
	_assert_equal(boss_requests, 1, "Danger 0 simulation emits one boss request")
	for required_id in ["helmet_alien", "fin_alien", "spawner", "buffer", "horned_charger", "horned_bruiser", "pursuer"]:
		_assert_true(seen_ids.has(required_id), "Danger 0 simulation reaches %s" % required_id)
	_assert_true(not seen_ids.has("fly"), "Danger 0 simulation skips danger-gated fly groups")

func _request_enemy_ids(request: Dictionary) -> Array:
	var ids: Array = []
	if request.has("enemy_id"):
		ids.append(String(request["enemy_id"]))
	for enemy_id in request.get("enemy_pool", []):
		ids.append(String(enemy_id))
	return ids

func _load_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		failures.append("missing text file: %s" % path)
		return ""
	return FileAccess.get_file_as_string(path)
