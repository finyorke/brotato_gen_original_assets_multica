class_name GameSettings
extends RefCounted

const DEFAULTS := {
	"current_slot": 0,
	"volume": {
		"master": 0.5,
		"sound": 0.75,
		"music": 0.25,
	},
	"video": {
		"fullscreen": true,
		"screenshake": true,
		"language": "platform",
		"main_screen_keyart": 0,
		"background": 0,
		"visual_effects": true,
		"damage_display": true,
		"optimize_end_waves": false,
		"limit_fps": false,
		"mute_on_focus_lost": false,
		"pause_on_focus_lost": true,
		"streamer_mode_tracks": true,
		"legacy_tracks": false,
		"deactivated_dlc_tracks": [],
		"sort_inventory_presset": [],
		"sort_inventory_presset_reverse": [],
	},
	"gameplay": {
		"mouse_only": false,
		"manual_aim": false,
		"manual_aim_on_mouse_press": false,
		"movement_with_gamepad": true,
		"hp_bar_on_character": true,
		"hp_bar_on_bosses": true,
		"keep_lock": true,
		"lock_coop_camera": false,
		"endless_score_storing": 0,
		"share_coop_loot": true,
		"deactivated_dlcs": [],
		"deactivated_skin_sets": [],
		"no_item_appearance": false,
		"holding_button": true,
		"endless_mode_toggled": false,
		"play_mode": "SOLO",
		"ban_mode_toggled": true,
		"zone_selected": 0,
	},
	"accessibility": {
		"enemy_scaling": {
			"health": 1.0,
			"damage": 1.0,
			"speed": 1.0,
		},
		"explosion_opacity": 1.0,
		"projectile_opacity": 1.0,
		"pet_opacity": 1.0,
		"font_size": 1.0,
		"character_highlighting": false,
		"weapon_highlighting": false,
		"projectile_highlighting": false,
		"turret_highlighting": false,
		"pet_highlighting": false,
		"effects_icons_in_description": true,
		"alt_gold_sounds": false,
		"darken_screen": true,
		"retry_wave": false,
		"color_positive": [0.0, 1.0, 0.0],
		"color_negative": [1.0, 0.0, 0.0],
		"tier_0_color": [230, 230, 230],
		"tier_1_color": [90, 190, 255],
		"tier_2_color": [173, 90, 255],
		"tier_3_color": [255, 59, 59],
		"tier_4_color": [255, 119, 59],
		"tier_5_color": [208, 193, 66],
	},
}

var values: Dictionary = {}

static func from_dict(data: Dictionary):
	var settings = load("res://src/settings/game_settings.gd").new()
	settings.apply_dict(data)
	return settings

func _init() -> void:
	reset()

func reset() -> void:
	values = DEFAULTS.duplicate(true)

func to_dict() -> Dictionary:
	return values.duplicate(true)

func apply_dict(data: Dictionary) -> void:
	reset()
	_merge_defaults(values, data)

func get_value(path: String, fallback: Variant = null) -> Variant:
	var cursor: Variant = values
	for part in path.split("."):
		if not cursor is Dictionary:
			return fallback
		var dict: Dictionary = cursor
		if not dict.has(part):
			return fallback
		cursor = dict[part]
	if cursor is Array or cursor is Dictionary:
		return cursor.duplicate(true)
	return cursor

func set_value(path: String, value: Variant) -> bool:
	var parts := path.split(".")
	if parts.is_empty():
		return false
	var cursor: Dictionary = values
	for i in range(0, parts.size() - 1):
		var part := String(parts[i])
		if not cursor.has(part) or not cursor[part] is Dictionary:
			cursor[part] = {}
		cursor = cursor[part]
	cursor[String(parts[parts.size() - 1])] = _duplicate_variant(value)
	return true

func enemy_scaling_snapshot() -> Dictionary:
	return get_value("accessibility.enemy_scaling", {"health": 1.0, "damage": 1.0, "speed": 1.0})

func is_coop_enabled() -> bool:
	return String(get_value("gameplay.play_mode", "SOLO")) == "COOP"

func _merge_defaults(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		var source_value = source[key]
		if target.has(key) and target[key] is Dictionary and source_value is Dictionary:
			_merge_defaults(target[key], source_value)
		else:
			target[key] = _duplicate_variant(source_value)

func _duplicate_variant(value: Variant) -> Variant:
	if value is Array or value is Dictionary:
		return value.duplicate(true)
	return value
