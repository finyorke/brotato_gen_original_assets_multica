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
		print("M1 tests failed: %d" % failures.size())
		quit(1)

func _run_all() -> void:
	_effect_key_tests()
	_storage_tests()
	_stat_pipeline_tests()
	_formula_tests()
	_burn_tests()
	_combat_m2_tests()

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
