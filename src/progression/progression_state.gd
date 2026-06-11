class_name ProgressionState
extends RefCounted

const ChallengeRegistryScript = preload("res://src/progression/challenge_registry.gd")

const SAVE_VERSION := 3
const MAX_DANGER := 5
const DEFAULT_ZONE := "zone_crash_site"
const DEFAULT_CHARACTER := "character_well_rounded"

var version: int = SAVE_VERSION
var zones_unlocked: Array = []
var characters_unlocked: Array = []
var weapons_unlocked: Array = []
var items_unlocked: Array = []
var upgrades_unlocked: Array = []
var consumables_unlocked: Array = []
var challenges_completed: Array = []
var systems_unlocked: Array = []
var difficulties_unlocked: Dictionary = {}
var killed_enemies: Dictionary = {}
var killed_by_enemies: Dictionary = {}
var items_bought: Dictionary = {}
var data: Dictionary = {}

static func from_dict(serialized: Dictionary):
	var state = load("res://src/progression/progression_state.gd").new()
	state.apply_dict(serialized)
	return state

func _init() -> void:
	reset_defaults()

func reset_defaults() -> void:
	version = SAVE_VERSION
	zones_unlocked = [DEFAULT_ZONE]
	characters_unlocked = [DEFAULT_CHARACTER]
	weapons_unlocked = ["weapon_pistol"]
	items_unlocked = []
	upgrades_unlocked = _default_upgrade_ids()
	consumables_unlocked = ["consumable_fruit", "consumable_item_box"]
	challenges_completed = []
	systems_unlocked = []
	difficulties_unlocked = {}
	killed_enemies = {}
	killed_by_enemies = {}
	items_bought = {}
	data = {
		"fruit_eaten_full_hp": 0,
		"chal_hourglass_quit_wave": 0,
		"is_unlock_all_save": 0,
		"run_won": 0,
		"run_started": 0,
		"enemies_killed": 0,
		"materials_collected": 0,
		"trees_killed": 0,
		"steps_taken": 0,
		"enemies_killed_far_away": 0,
		"evil_mob_killed": 0,
		"evil_mob_killed_by": 0,
	}
	for character_id in ChallengeRegistryScript.character_ids():
		register_character_zone(String(character_id), DEFAULT_ZONE)
	_normalize_global_danger_unlocks()

func to_dict() -> Dictionary:
	return {
		"version": version,
		"zones_unlocked": zones_unlocked.duplicate(true),
		"characters_unlocked": characters_unlocked.duplicate(true),
		"weapons_unlocked": weapons_unlocked.duplicate(true),
		"items_unlocked": items_unlocked.duplicate(true),
		"upgrades_unlocked": upgrades_unlocked.duplicate(true),
		"consumables_unlocked": consumables_unlocked.duplicate(true),
		"challenges_completed": challenges_completed.duplicate(true),
		"systems_unlocked": systems_unlocked.duplicate(true),
		"difficulties_unlocked": difficulties_unlocked.duplicate(true),
		"killed_enemies": killed_enemies.duplicate(true),
		"killed_by_enemies": killed_by_enemies.duplicate(true),
		"items_bought": items_bought.duplicate(true),
		"data": data.duplicate(true),
	}

func apply_dict(serialized: Dictionary) -> void:
	reset_defaults()
	version = int(serialized.get("version", SAVE_VERSION))
	zones_unlocked = _array_from(serialized.get("zones_unlocked", zones_unlocked))
	characters_unlocked = _array_from(serialized.get("characters_unlocked", characters_unlocked))
	weapons_unlocked = _array_from(serialized.get("weapons_unlocked", weapons_unlocked))
	items_unlocked = _array_from(serialized.get("items_unlocked", items_unlocked))
	upgrades_unlocked = _array_from(serialized.get("upgrades_unlocked", upgrades_unlocked))
	consumables_unlocked = _array_from(serialized.get("consumables_unlocked", consumables_unlocked))
	challenges_completed = _array_from(serialized.get("challenges_completed", challenges_completed))
	systems_unlocked = _array_from(serialized.get("systems_unlocked", systems_unlocked))
	difficulties_unlocked = _dict_from(serialized.get("difficulties_unlocked", difficulties_unlocked))
	killed_enemies = _dict_from(serialized.get("killed_enemies", killed_enemies))
	killed_by_enemies = _dict_from(serialized.get("killed_by_enemies", killed_by_enemies))
	items_bought = _dict_from(serialized.get("items_bought", items_bought))
	data.merge(_dict_from(serialized.get("data", {})), true)
	for character_id in ChallengeRegistryScript.character_ids():
		register_character_zone(String(character_id), DEFAULT_ZONE)
	_normalize_global_danger_unlocks()

func register_character_zone(character_id: String, zone_id: String) -> void:
	if character_id == DEFAULT_CHARACTER:
		_append_unique(characters_unlocked, character_id)
	_append_unique(zones_unlocked, zone_id)
	var key := _difficulty_key(character_id, zone_id)
	if difficulties_unlocked.has(key):
		return
	difficulties_unlocked[key] = {
		"character_id": character_id,
		"zone_id": zone_id,
		"difficulty_selected_value": 0,
		"max_selectable_difficulty": 0,
		"max_difficulty_beaten": -1,
		"max_endless_wave_beaten": 0,
		"best_record": {},
	}

func get_difficulty_info(character_id: String, zone_id: String) -> Dictionary:
	register_character_zone(character_id, zone_id)
	return (difficulties_unlocked[_difficulty_key(character_id, zone_id)] as Dictionary).duplicate(true)

func can_select_danger(character_id: String, zone_id: String, danger: int) -> bool:
	var clamped := clampi(danger, 0, MAX_DANGER)
	if clamped == 0:
		return true
	var info := get_difficulty_info(character_id, zone_id)
	return clamped <= int(info.get("max_selectable_difficulty", 0))

func set_selected_difficulty(character_id: String, zone_id: String, danger: int, is_coop: bool = false) -> void:
	if is_coop:
		return
	register_character_zone(character_id, zone_id)
	var key := _difficulty_key(character_id, zone_id)
	var info: Dictionary = difficulties_unlocked[key]
	info["difficulty_selected_value"] = clampi(danger, 0, MAX_DANGER)
	difficulties_unlocked[key] = info

func unlock_danger_globally(danger: int) -> int:
	var clamped := clampi(danger, 0, MAX_DANGER)
	for key in difficulties_unlocked.keys():
		var info: Dictionary = difficulties_unlocked[key]
		info["max_selectable_difficulty"] = maxi(int(info.get("max_selectable_difficulty", 0)), clamped)
		difficulties_unlocked[key] = info
	return clamped

func complete_challenge(challenge_id: String) -> bool:
	var definition := ChallengeRegistryScript.by_id(challenge_id)
	if definition.is_empty():
		return false
	var storage_id := String(definition.get("storage_id", challenge_id))
	if challenges_completed.has(storage_id):
		return false
	challenges_completed.append(storage_id)
	_apply_reward(definition)
	return true

func has_completed_challenge(challenge_id: String) -> bool:
	return challenges_completed.has(ChallengeRegistryScript.storage_id(challenge_id))

func record_counter(stat: String, amount: int) -> Array:
	data[stat] = int(data.get(stat, 0)) + amount
	var completed: Array = []
	for challenge in ChallengeRegistryScript.all():
		var definition: Dictionary = challenge
		if String(definition.get("stat", "")) != stat:
			continue
		var required := int(definition.get("value", 0))
		if _value_meets_requirement(float(data.get(stat, 0)), required):
			if complete_challenge(String(definition.get("id", ""))):
				completed.append(String(definition.get("id", "")))
	return completed

func record_run_started() -> void:
	data["run_started"] = int(data.get("run_started", 0)) + 1

func record_run_result(result: Dictionary) -> Dictionary:
	var danger := clampi(int(result.get("danger", 0)), 0, MAX_DANGER)
	var zone_id := String(result.get("zone_id", DEFAULT_ZONE))
	var won := bool(result.get("won", false))
	var is_coop := bool(result.get("is_coop", false))
	var endless := bool(result.get("endless", false))
	var wave := int(result.get("wave", 20))
	var players: Array = result.get("players", [])
	if players.is_empty():
		players = [{
			"character_id": String(result.get("character_id", DEFAULT_CHARACTER)),
			"zone_id": zone_id,
			"bans_used": int(result.get("bans_used", 0)),
		}]
	var completed: Array = []
	if won:
		data["run_won"] = int(data.get("run_won", 0)) + 1
		if danger + 1 <= MAX_DANGER:
			unlock_danger_globally(danger + 1)
			if complete_challenge("unlock_difficulty_%d" % [danger + 1]):
				completed.append("unlock_difficulty_%d" % [danger + 1])
		if danger >= 1 and complete_challenge("fake_item_banned_item"):
			completed.append("fake_item_banned_item")
	for player in players:
		var player_data: Dictionary = player
		var character_id := String(player_data.get("character_id", DEFAULT_CHARACTER))
		var player_zone := String(player_data.get("zone_id", zone_id))
		register_character_zone(character_id, player_zone)
		if not is_coop:
			set_selected_difficulty(character_id, player_zone, danger, false)
		if won:
			_update_best_record(character_id, player_zone, {
				"danger": danger,
				"wave": wave,
				"enemy_scaling": result.get("enemy_scaling", {"health": 1.0, "damage": 1.0, "speed": 1.0}),
				"retries": int(result.get("retries", 0)),
				"bans_used": int(player_data.get("bans_used", result.get("bans_used", 0))),
				"is_coop": is_coop,
			})
			var difficulty_challenge := "chal_difficulty_%d" % [danger]
			if complete_challenge(difficulty_challenge):
				completed.append(difficulty_challenge)
			var character_win := ChallengeRegistryScript.character_win_challenge_id(character_id)
			if not character_win.is_empty() and complete_challenge(character_win):
				completed.append(character_win)
		if endless:
			_update_endless_record(character_id, player_zone, wave, danger)
	return {"completed_challenges": completed, "max_selectable_difficulty": _global_max_selectable_difficulty()}

func unlocked_percent() -> float:
	var denominator := maxi(1, ChallengeRegistryScript.ids_excluding_difficulty_unlocks().size())
	var counted := 0
	for id in ChallengeRegistryScript.ids_excluding_difficulty_unlocks():
		if has_completed_challenge(String(id)):
			counted += 1
	return float(counted) / float(denominator)

func _update_best_record(character_id: String, zone_id: String, record: Dictionary) -> void:
	var key := _difficulty_key(character_id, zone_id)
	var info: Dictionary = difficulties_unlocked[key]
	var current: Dictionary = info.get("best_record", {})
	if _is_better_record(record, current):
		info["best_record"] = record.duplicate(true)
		info["max_difficulty_beaten"] = maxi(int(info.get("max_difficulty_beaten", -1)), int(record.get("danger", 0)))
	difficulties_unlocked[key] = info

func _update_endless_record(character_id: String, zone_id: String, wave: int, danger: int) -> void:
	var key := _difficulty_key(character_id, zone_id)
	var info: Dictionary = difficulties_unlocked[key]
	var current_wave := int(info.get("max_endless_wave_beaten", 0))
	var current_danger := int(info.get("max_endless_danger", -1))
	if wave > current_wave or (wave == current_wave and danger > current_danger):
		info["max_endless_wave_beaten"] = wave
		info["max_endless_danger"] = danger
	difficulties_unlocked[key] = info

func _is_better_record(candidate: Dictionary, current: Dictionary) -> bool:
	if current.is_empty():
		return true
	var candidate_danger := int(candidate.get("danger", 0))
	var current_danger := int(current.get("danger", 0))
	if candidate_danger != current_danger:
		return candidate_danger > current_danger
	var candidate_scaling := _enemy_scaling_score(candidate.get("enemy_scaling", {}))
	var current_scaling := _enemy_scaling_score(current.get("enemy_scaling", {}))
	if not is_equal_approx(candidate_scaling, current_scaling):
		return candidate_scaling > current_scaling
	var candidate_retries := int(candidate.get("retries", 0))
	var current_retries := int(current.get("retries", 0))
	if candidate_retries != current_retries:
		return candidate_retries < current_retries
	var candidate_bans := int(candidate.get("bans_used", 0))
	var current_bans := int(current.get("bans_used", 0))
	if candidate_bans != current_bans:
		return candidate_bans < current_bans
	return bool(current.get("is_coop", false)) and not bool(candidate.get("is_coop", false))

func _enemy_scaling_score(value: Variant) -> float:
	if not value is Dictionary:
		return 1.0
	var scaling: Dictionary = value
	return pow(float(scaling.get("health", 1.0)) * float(scaling.get("damage", 1.0)) * float(scaling.get("speed", 1.0)), 1.0 / 3.0)

func _apply_reward(definition: Dictionary) -> void:
	var reward: Variant = definition.get("reward", "")
	match int(definition.get("reward_type", ChallengeRegistryScript.RewardType.NONE)):
		ChallengeRegistryScript.RewardType.ITEM:
			_append_unique(items_unlocked, String(reward))
		ChallengeRegistryScript.RewardType.WEAPON, ChallengeRegistryScript.RewardType.STARTING_WEAPON:
			_append_unique(weapons_unlocked, String(reward))
		ChallengeRegistryScript.RewardType.ZONE:
			_append_unique(zones_unlocked, String(reward))
		ChallengeRegistryScript.RewardType.CONSUMABLE:
			_append_unique(consumables_unlocked, String(reward))
		ChallengeRegistryScript.RewardType.UPGRADE:
			_append_unique(upgrades_unlocked, String(reward))
		ChallengeRegistryScript.RewardType.CHARACTER:
			_append_unique(characters_unlocked, String(reward))
			register_character_zone(String(reward), DEFAULT_ZONE)
		ChallengeRegistryScript.RewardType.DIFFICULTY:
			unlock_danger_globally(int(reward))
		ChallengeRegistryScript.RewardType.SYSTEM:
			_append_unique(systems_unlocked, String(reward))

func _normalize_global_danger_unlocks() -> void:
	unlock_danger_globally(_global_max_selectable_difficulty())

func _global_max_selectable_difficulty() -> int:
	var max_danger := 0
	for info_value in difficulties_unlocked.values():
		var info: Dictionary = info_value
		max_danger = maxi(max_danger, int(info.get("max_selectable_difficulty", 0)))
	return clampi(max_danger, 0, MAX_DANGER)

func _difficulty_key(character_id: String, zone_id: String) -> String:
	return "%s|%s" % [character_id, zone_id]

func _value_meets_requirement(value: float, requirement: int) -> bool:
	if requirement < 0:
		return value <= float(requirement)
	return value >= float(requirement)

func _default_upgrade_ids() -> Array:
	var result: Array = []
	for stat in ["armor", "dodge", "harvesting", "hp_regeneration", "lifesteal", "luck", "max_hp", "melee_damage", "percent_damage", "ranged_damage", "speed"]:
		for tier in range(1, 5):
			result.append("upgrade_%s_%d" % [stat, tier])
	return result

func _append_unique(values: Array, value: String) -> void:
	if value.is_empty():
		return
	if not values.has(value):
		values.append(value)

func _array_from(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []

func _dict_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}
