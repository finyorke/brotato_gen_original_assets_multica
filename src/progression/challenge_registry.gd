class_name ChallengeRegistry
extends RefCounted

enum RewardType {
	NONE,
	ITEM,
	WEAPON,
	ZONE,
	STARTING_WEAPON,
	CONSUMABLE,
	UPGRADE,
	CHARACTER,
	DIFFICULTY,
	SYSTEM,
}

const VANILLA_CHALLENGE_IDS := [
	"chal_advanced_technology",
	"chal_agriculture",
	"chal_apprentice",
	"chal_arms_dealer",
	"chal_artificer",
	"chal_baby",
	"chal_baited",
	"chal_blood_drinker",
	"chal_bourgeoisie",
	"chal_brawler",
	"chal_bull",
	"chal_difficulty_0",
	"chal_difficulty_1",
	"chal_difficulty_2",
	"chal_difficulty_3",
	"chal_difficulty_4",
	"chal_difficulty_5",
	"chal_chunky",
	"chal_crazy",
	"chal_cryptid",
	"chal_cyborg",
	"chal_demon",
	"chal_doctor",
	"chal_dying",
	"chal_engineer",
	"chal_entrepreneur",
	"chal_experimentation",
	"chal_explorer",
	"chal_farmer",
	"chal_fast",
	"chal_fast_learner",
	"chal_fireworks",
	"chal_fisherman",
	"chal_forest",
	"chal_gatherer_1",
	"chal_gatherer_2",
	"chal_gatherer_3",
	"chal_gatherer_4",
	"chal_gatherer_5",
	"chal_generalist",
	"chal_ghost",
	"chal_giant_slayer",
	"chal_gladiator",
	"chal_glutton",
	"chal_golem",
	"chal_hallucination",
	"chal_hoarder",
	"chal_hungry",
	"chal_hunter",
	"chal_jack",
	"chal_king",
	"chal_knight",
	"chal_lich",
	"chal_loud",
	"chal_lucky",
	"chal_lumberjack",
	"chal_mage",
	"chal_magic_and_machinery",
	"chal_masochist",
	"chal_medicine",
	"chal_multitasker",
	"chal_mutant",
	"chal_old",
	"chal_one_arm",
	"chal_pacifist",
	"chal_perfect_vision",
	"chal_ranger",
	"chal_reckless",
	"chal_recycling",
	"chal_renegade",
	"chal_robust",
	"chal_rookie",
	"chal_saver",
	"chal_scavenger",
	"chal_sick",
	"chal_slow",
	"chal_soldier",
	"chal_speedy",
	"chal_streamer",
	"chal_student",
	"chal_survivor_1",
	"chal_survivor_2",
	"chal_survivor_3",
	"chal_survivor_4",
	"chal_survivor_5",
	"chal_technomage",
	"chal_turrets",
	"chal_vagabond",
	"chal_vampire",
	"chal_well_rounded",
	"chal_wildling",
]

const DANGER_UNLOCK_IDS := [
	"unlock_difficulty_1",
	"unlock_difficulty_2",
	"unlock_difficulty_3",
	"unlock_difficulty_4",
	"unlock_difficulty_5",
]

const POST_11_CHALLENGE_IDS := [
	"chal_paws_n_claws",
	"chal_evil_hat",
	"chal_evil_mob",
	"fake_item_banned_item",
	"chal_hourglass",
	"chal_candy_bag",
	"chal_fruit_basket",
	"chal_will_o_the_wisp",
	"chal_ghost_outfit",
	"chal_vorpal_sword",
	"chal_bonk_dog",
	"chal_catling_gun",
	"chal_bot_o_mine",
	"chal_blazemander",
	"chal_doc_moth",
	"chal_lootworm",
	"chal_jellyshield",
]

const DIFFICULTY_CHARACTER_REWARDS := {
	"chal_difficulty_0": "character_one_arm",
	"chal_difficulty_1": "character_bull",
	"chal_difficulty_2": "character_soldier",
	"chal_difficulty_3": "character_masochist",
	"chal_difficulty_4": "character_knight",
	"chal_difficulty_5": "character_demon",
}

const STAT_CHALLENGES := {
	"chal_dying": {"stat": "stat_hp_regeneration", "value": -5, "reward_type": RewardType.CHARACTER, "reward": "character_sick"},
	"chal_agriculture": {"stat": "stat_harvesting", "value": 200, "reward_type": RewardType.CHARACTER, "reward": "character_farmer"},
	"chal_hallucination": {"stat": "stat_dodge", "value": 60, "reward_type": RewardType.CHARACTER, "reward": "character_ghost"},
	"chal_fast": {"stat": "stat_speed", "value": 50, "reward_type": RewardType.CHARACTER, "reward": "character_speedy"},
	"chal_slow": {"stat": "stat_speed", "value": -20, "reward_type": RewardType.CHARACTER, "reward": "character_streamer"},
	"chal_robust": {"stat": "stat_max_hp", "value": 100, "reward_type": RewardType.CHARACTER, "reward": "character_lich"},
	"chal_perfect_vision": {"stat": "stat_range", "value": 300, "reward_type": RewardType.CHARACTER, "reward": "character_hunter"},
	"chal_blood_drinker": {"stat": "stat_lifesteal", "value": 40, "reward_type": RewardType.CHARACTER, "reward": "character_vampire"},
	"chal_hoarder": {"stat": "materials", "value": 3000, "reward_type": RewardType.CHARACTER, "reward": "character_entrepreneur"},
	"chal_student": {"stat": "level", "value": 20, "reward_type": RewardType.CHARACTER, "reward": "character_apprentice"},
	"chal_ghost_outfit": {"stat": "stat_dodge", "value": 70, "reward_type": RewardType.ITEM, "reward": "item_ghost_outfit"},
	"chal_vorpal_sword": {"stat": "stat_crit_chance", "value": 100, "reward_type": RewardType.WEAPON, "reward": "weapon_vorpal_sword"},
}

const COUNTER_CHALLENGES := {
	"chal_survivor_1": {"stat": "enemies_killed", "value": 300, "reward": "character_old"},
	"chal_survivor_2": {"stat": "enemies_killed", "value": 2000, "reward": "character_mutant"},
	"chal_survivor_3": {"stat": "enemies_killed", "value": 5000, "reward": "character_loud"},
	"chal_survivor_4": {"stat": "enemies_killed", "value": 10000, "reward": "character_wildling"},
	"chal_survivor_5": {"stat": "enemies_killed", "value": 20000, "reward": "character_gladiator"},
	"chal_gatherer_1": {"stat": "materials_collected", "value": 300, "reward": "character_lucky"},
	"chal_gatherer_2": {"stat": "materials_collected", "value": 2000, "reward": "character_generalist"},
	"chal_gatherer_3": {"stat": "materials_collected", "value": 5000, "reward": "character_multitasker"},
	"chal_gatherer_4": {"stat": "materials_collected", "value": 10000, "reward": "character_pacifist"},
	"chal_gatherer_5": {"stat": "materials_collected", "value": 20000, "reward": "character_saver"},
	"chal_lumberjack": {"stat": "trees_killed", "value": 50, "reward": "character_explorer"},
	"chal_evil_hat": {"stat": "evil_mob_killed", "value": 5, "reward_type": RewardType.ITEM, "reward": "item_evil_hat", "storage_id": "chal_evil_mob"},
	"chal_evil_mob": {"stat": "evil_mob_killed", "value": 5, "reward_type": RewardType.ITEM, "reward": "item_evil_hat", "storage_id": "chal_evil_mob"},
	"chal_fruit_basket": {"stat": "fruit_eaten_full_hp", "value": 100, "reward_type": RewardType.ITEM, "reward": "item_fruit_basket"},
}

const EVENT_CHALLENGES := {
	"chal_rookie": {"event": "first_death", "reward_type": RewardType.CHARACTER, "reward": "character_chunky"},
	"chal_turrets": {"event": "turret_count", "value": 5, "reward_type": RewardType.CHARACTER, "reward": "character_engineer"},
	"chal_medicine": {"event": "wave_healing", "value": 200, "reward_type": RewardType.CHARACTER, "reward": "character_doctor"},
	"chal_fireworks": {"event": "explosion_kill_count", "value": 15, "reward_type": RewardType.CHARACTER, "reward": "character_artificer"},
	"chal_recycling": {"event": "run_weapon_recycles", "value": 12, "reward_type": RewardType.CHARACTER, "reward": "character_arms_dealer"},
	"chal_hungry": {"event": "run_consumables_picked", "value": 20, "reward_type": RewardType.CHARACTER, "reward": "character_glutton"},
	"chal_advanced_technology": {"event": "ranged_damage_and_structures", "value": 10, "reward_type": RewardType.CHARACTER, "reward": "character_cyborg", "additional_args": {"structures": 3}},
	"chal_magic_and_machinery": {"event": "elemental_damage_and_structures", "value": 10, "reward_type": RewardType.CHARACTER, "reward": "character_technomage", "additional_args": {"structures": 3}},
	"chal_giant_slayer": {"event": "boss_or_elite_killed_fast", "value": 15, "reward_type": RewardType.CHARACTER, "reward": "character_jack"},
	"chal_baited": {"event": "item_count", "value": 2, "reward_type": RewardType.CHARACTER, "reward": "character_fisherman", "additional_args": {"item_id": "item_bait"}},
	"chal_forest": {"event": "wave_end_living_trees", "value": 10, "reward_type": RewardType.CHARACTER, "reward": "character_cryptid"},
	"chal_bourgeoisie": {"event": "tier_iv_weapon_count", "value": 3, "reward_type": RewardType.CHARACTER, "reward": "character_king"},
	"chal_reckless": {"event": "wave_end_current_hp_equals", "value": 1, "reward_type": RewardType.CHARACTER, "reward": "character_golem"},
	"chal_scavenger": {"event": "different_tier_i_item_count", "value": 10, "reward_type": RewardType.CHARACTER, "reward": "character_renegade"},
	"chal_fast_learner": {"event": "level_before_wave", "value": 10, "reward_type": RewardType.CHARACTER, "reward": "character_baby", "additional_args": {"before_wave": 6}},
	"chal_experimentation": {"event": "different_weapon_count", "value": 6, "reward_type": RewardType.CHARACTER, "reward": "character_vagabond"},
	"chal_paws_n_claws": {"event": "pets_unlocked", "value": 5, "reward_type": RewardType.CHARACTER, "reward": "character_beast_master"},
	"fake_item_banned_item": {"event": "win_danger_at_least", "value": 1, "reward_type": RewardType.SYSTEM, "reward": "ban_system"},
	"chal_hourglass": {"event": "continue_after_quit_under_seconds", "value": 5, "reward_type": RewardType.ITEM, "reward": "item_hourglass", "additional_args": {"min_wave": 2}},
	"chal_candy_bag": {"event": "win_without_locking_shop", "reward_type": RewardType.ITEM, "reward": "item_candy_bag"},
	"chal_will_o_the_wisp": {"event": "burn_kills_in_wave", "value": 30, "reward_type": RewardType.ITEM, "reward": "item_will_o_the_wisp"},
	"chal_bonk_dog": {"event": "weapon_scaling_count", "value": 6, "reward_type": RewardType.ITEM, "reward": "item_bonk_dog", "additional_args": {"scaling": "stat_melee_damage"}},
	"chal_catling_gun": {"event": "weapon_scaling_count", "value": 6, "reward_type": RewardType.ITEM, "reward": "item_catling_gun", "additional_args": {"scaling": "stat_ranged_damage"}},
	"chal_bot_o_mine": {"event": "weapon_scaling_count", "value": 6, "reward_type": RewardType.ITEM, "reward": "item_bot_o_mine", "additional_args": {"scaling": "stat_engineering"}},
	"chal_blazemander": {"event": "weapon_scaling_count", "value": 6, "reward_type": RewardType.ITEM, "reward": "item_blazemander", "additional_args": {"scaling": "stat_elemental_damage"}},
	"chal_doc_moth": {"event": "hp_regen_and_lifesteal", "value": 10, "reward_type": RewardType.ITEM, "reward": "item_doc_moth"},
	"chal_lootworm": {"event": "wave_end_ground_materials", "value": 20, "reward_type": RewardType.ITEM, "reward": "item_lootworm"},
	"chal_jellyshield": {"event": "projectile_hits_in_wave", "value": 3, "reward_type": RewardType.ITEM, "reward": "item_jellyshield"},
}

const CHARACTER_WIN_REWARDS := {
	"chal_well_rounded": {"character": "character_well_rounded", "reward_type": RewardType.ITEM, "reward": "item_potato"},
	"chal_brawler": {"character": "character_brawler", "reward_type": RewardType.WEAPON, "reward": "weapon_power_fist_t3"},
	"chal_crazy": {"character": "character_crazy", "reward_type": RewardType.ITEM, "reward": "item_hunting_trophy"},
	"chal_ranger": {"character": "character_ranger", "reward_type": RewardType.ITEM, "reward": "item_night_vision_goggles"},
	"chal_mage": {"character": "character_mage", "reward_type": RewardType.WEAPON, "reward": "weapon_thunder_sword_t3"},
	"chal_chunky": {"character": "character_chunky", "reward_type": RewardType.WEAPON, "reward": "weapon_potato_thrower_t2"},
	"chal_old": {"character": "character_old", "reward_type": RewardType.ITEM, "reward": "item_snail"},
	"chal_lucky": {"character": "character_lucky", "reward_type": RewardType.ITEM, "reward": "item_lucky_charm"},
	"chal_mutant": {"character": "character_mutant", "reward_type": RewardType.ITEM, "reward": "item_octopus"},
	"chal_generalist": {"character": "character_generalist", "reward_type": RewardType.ITEM, "reward": "item_little_muscley_dude"},
	"chal_loud": {"character": "character_loud", "reward_type": RewardType.ITEM, "reward": "item_rip_and_tear"},
	"chal_multitasker": {"character": "character_multitasker", "reward_type": RewardType.WEAPON, "reward": "weapon_chopper"},
	"chal_wildling": {"character": "character_wildling", "reward_type": RewardType.WEAPON, "reward": "weapon_hatchet"},
	"chal_pacifist": {"character": "character_pacifist", "reward_type": RewardType.ITEM, "reward": "item_panda"},
	"chal_gladiator": {"character": "character_gladiator", "reward_type": RewardType.ITEM, "reward": "item_spider"},
	"chal_saver": {"character": "character_saver", "reward_type": RewardType.ITEM, "reward": "item_padding"},
	"chal_sick": {"character": "character_sick", "reward_type": RewardType.ITEM, "reward": "item_whetstone"},
	"chal_farmer": {"character": "character_farmer", "reward_type": RewardType.ITEM, "reward": "item_wheat"},
	"chal_ghost": {"character": "character_ghost", "reward_type": RewardType.ITEM, "reward": "item_ritual"},
	"chal_speedy": {"character": "character_speedy", "reward_type": RewardType.ITEM, "reward": "item_fin"},
	"chal_entrepreneur": {"character": "character_entrepreneur", "reward_type": RewardType.ITEM, "reward": "item_top_hat"},
	"chal_engineer": {"character": "character_engineer", "reward_type": RewardType.ITEM, "reward": "item_robot_arm"},
	"chal_explorer": {"character": "character_explorer", "reward_type": RewardType.ITEM, "reward": "item_compass"},
	"chal_doctor": {"character": "character_doctor", "reward_type": RewardType.ITEM, "reward": "item_medikit"},
	"chal_hunter": {"character": "character_hunter", "reward_type": RewardType.WEAPON, "reward": "weapon_sniper_gun_t3"},
	"chal_artificer": {"character": "character_artificer", "reward_type": RewardType.ITEM, "reward": "item_explosive_ammo"},
	"chal_arms_dealer": {"character": "character_arms_dealer", "reward_type": RewardType.ITEM, "reward": "item_anvil"},
	"chal_streamer": {"character": "character_streamer", "reward_type": RewardType.ITEM, "reward": "item_community_support"},
	"chal_cyborg": {"character": "character_cyborg", "reward_type": RewardType.ITEM, "reward": "item_improved_tools"},
	"chal_glutton": {"character": "character_glutton", "reward_type": RewardType.ITEM, "reward": "item_spicy_sauce"},
	"chal_jack": {"character": "character_jack", "reward_type": RewardType.ITEM, "reward": "item_giant_belt"},
	"chal_lich": {"character": "character_lich", "reward_type": RewardType.ITEM, "reward": "item_tentacle"},
	"chal_apprentice": {"character": "character_apprentice", "reward_type": RewardType.WEAPON, "reward": "weapon_staff"},
	"chal_cryptid": {"character": "character_cryptid", "reward_type": RewardType.WEAPON, "reward": "weapon_claw"},
	"chal_fisherman": {"character": "character_fisherman", "reward_type": RewardType.ITEM, "reward": "item_lure"},
	"chal_golem": {"character": "character_golem", "reward_type": RewardType.ITEM, "reward": "item_stone_skin"},
	"chal_king": {"character": "character_king", "reward_type": RewardType.WEAPON, "reward": "weapon_kings_sword_t4"},
	"chal_renegade": {"character": "character_renegade", "reward_type": RewardType.ITEM, "reward": "item_fairy"},
	"chal_one_arm": {"character": "character_one_arm", "reward_type": RewardType.ITEM, "reward": "item_focus"},
	"chal_bull": {"character": "character_bull", "reward_type": RewardType.ITEM, "reward": "item_gnome"},
	"chal_soldier": {"character": "character_soldier", "reward_type": RewardType.WEAPON, "reward": "weapon_nuclear_launcher_t3"},
	"chal_masochist": {"character": "character_masochist", "reward_type": RewardType.WEAPON, "reward": "weapon_spiky_shield"},
	"chal_knight": {"character": "character_knight", "reward_type": RewardType.WEAPON, "reward": "weapon_plasma_sledgehammer_t3"},
	"chal_demon": {"character": "character_demon", "reward_type": RewardType.WEAPON, "reward": "weapon_obliterator_t3"},
	"chal_baby": {"character": "character_baby", "reward_type": RewardType.ITEM, "reward": "item_celery_tea"},
	"chal_vagabond": {"character": "character_vagabond", "reward_type": RewardType.ITEM, "reward": "item_jelly"},
	"chal_technomage": {"character": "character_technomage", "reward_type": RewardType.WEAPON, "reward": "weapon_particle_accelerator_t3"},
	"chal_vampire": {"character": "character_vampire", "reward_type": RewardType.ITEM, "reward": "item_rotten_flesh"},
}

static func all() -> Array:
	var definitions: Array = []
	for id in VANILLA_CHALLENGE_IDS:
		definitions.append(_definition_for_id(String(id)))
	for id in DANGER_UNLOCK_IDS:
		definitions.append(_definition_for_id(String(id)))
	for id in POST_11_CHALLENGE_IDS:
		definitions.append(_definition_for_id(String(id)))
	return definitions

static func count() -> int:
	return all().size()

static func by_id(id: String) -> Dictionary:
	for definition in all():
		var challenge: Dictionary = definition
		if String(challenge.get("id", "")) == id:
			return challenge
	return {}

static func ids() -> Array:
	var result: Array = []
	for definition in all():
		var challenge: Dictionary = definition
		result.append(String(challenge["id"]))
	return result

static func ids_excluding_difficulty_unlocks() -> Array:
	var result: Array = []
	for id in ids():
		if not String(id).begins_with("unlock_difficulty_"):
			result.append(id)
	return result

static func character_ids() -> Array:
	var result: Array = ["character_well_rounded"]
	for reward in DIFFICULTY_CHARACTER_REWARDS.values():
		_append_unique(result, String(reward))
	for challenge in STAT_CHALLENGES.values():
		if int(challenge.get("reward_type", RewardType.NONE)) == RewardType.CHARACTER:
			_append_unique(result, String(challenge.get("reward", "")))
	for challenge in COUNTER_CHALLENGES.values():
		if int(challenge.get("reward_type", RewardType.CHARACTER)) == RewardType.CHARACTER:
			_append_unique(result, String(challenge.get("reward", "")))
	for challenge in EVENT_CHALLENGES.values():
		if int(challenge.get("reward_type", RewardType.NONE)) == RewardType.CHARACTER:
			_append_unique(result, String(challenge.get("reward", "")))
	for challenge in CHARACTER_WIN_REWARDS.values():
		_append_unique(result, String(challenge.get("character", "")))
	return result

static func character_win_challenge_id(character_id: String) -> String:
	for id in CHARACTER_WIN_REWARDS.keys():
		var data: Dictionary = CHARACTER_WIN_REWARDS[id]
		if String(data.get("character", "")) == character_id:
			return String(id)
	return ""

static func storage_id(id: String) -> String:
	var definition := by_id(id)
	if definition.is_empty():
		return id
	return String(definition.get("storage_id", id))

static func _definition_for_id(id: String) -> Dictionary:
	var definition := {
		"id": id,
		"storage_id": id,
		"value": 0,
		"stat": "",
		"event": "",
		"reward_type": RewardType.NONE,
		"reward": "",
		"additional_args": {},
	}
	if id.begins_with("unlock_difficulty_"):
		var difficulty := int(id.get_slice("_", 2))
		definition["value"] = difficulty - 1
		definition["event"] = "win_previous_difficulty"
		definition["reward_type"] = RewardType.DIFFICULTY
		definition["reward"] = difficulty
		return definition
	if DIFFICULTY_CHARACTER_REWARDS.has(id):
		var difficulty := int(id.get_slice("_", 2))
		definition["value"] = difficulty
		definition["event"] = "win_exact_difficulty"
		definition["reward_type"] = RewardType.CHARACTER
		definition["reward"] = DIFFICULTY_CHARACTER_REWARDS[id]
		return definition
	if STAT_CHALLENGES.has(id):
		definition.merge(STAT_CHALLENGES[id], true)
		return definition
	if COUNTER_CHALLENGES.has(id):
		var counter_data: Dictionary = COUNTER_CHALLENGES[id]
		definition["stat"] = String(counter_data.get("stat", ""))
		definition["value"] = int(counter_data.get("value", 0))
		definition["reward_type"] = int(counter_data.get("reward_type", RewardType.CHARACTER))
		definition["reward"] = String(counter_data.get("reward", ""))
		definition["storage_id"] = String(counter_data.get("storage_id", id))
		return definition
	if EVENT_CHALLENGES.has(id):
		definition.merge(EVENT_CHALLENGES[id], true)
		return definition
	if CHARACTER_WIN_REWARDS.has(id):
		var win_data: Dictionary = CHARACTER_WIN_REWARDS[id]
		definition["event"] = "win_with_character"
		definition["reward_type"] = int(win_data.get("reward_type", RewardType.NONE))
		definition["reward"] = String(win_data.get("reward", ""))
		definition["additional_args"] = {"character_id": String(win_data.get("character", ""))}
		return definition
	return definition

static func _append_unique(values: Array, value: String) -> void:
	if value.is_empty():
		return
	if not values.has(value):
		values.append(value)
