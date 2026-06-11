class_name AssetManifest
extends RefCounted

var data: Dictionary = {}

static func load_from_path(path: String):
	var manifest = load("res://src/presentation/asset_manifest.gd").new()
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Could not parse asset manifest: %s" % path)
		manifest.data = {}
	else:
		manifest.data = parsed
	return manifest

func source_doc_count() -> int:
	return data.get("source_docs", []).size()

func player_visual() -> Dictionary:
	return data.get("player", {})

func weapon_visual(weapon_id: String) -> Dictionary:
	return data.get("weapons", {}).get(weapon_id, {})

func enemy_visual(enemy_id: String) -> Dictionary:
	return data.get("enemies", {}).get(enemy_id, {})

func material_texture_paths() -> Array:
	return data.get("materials", {}).get("textures", []).duplicate(true)

func ground_data() -> Dictionary:
	return data.get("ground", {})

func ground_themes() -> Array:
	return ground_data().get("themes", []).duplicate(true)

func theme_by_id(theme_id: String) -> Dictionary:
	for theme in ground_themes():
		if String(theme.get("id", "")) == theme_id:
			return theme
	return {}

func quality_tint(tier: int, dark: bool = false) -> Color:
	var tier_data: Dictionary = data.get("quality_tints", {}).get(str(tier), {})
	var values: Array = tier_data.get("dark" if dark else "color", [0.0, 0.0, 0.0])
	return _color_from_rgb(values)

func vfx_data(key: String) -> Dictionary:
	return data.get("vfx", {}).get(key, {})

func audio_data() -> Dictionary:
	return data.get("audio", {})

func sound_event(event_id: String) -> Dictionary:
	return audio_data().get("sound_events", {}).get(event_id, {})

func music_tracks(include_legacy: bool = true, include_streamer: bool = true) -> Array:
	var tracks: Array = []
	for track in audio_data().get("music_tracks", []):
		var pool := String(track.get("pool", ""))
		if pool == "legacy" and not include_legacy:
			continue
		if pool == "streamer" and not include_streamer:
			continue
		tracks.append(track)
	return tracks

func runtime_asset_paths() -> Array:
	var paths: Array = []
	_collect_paths(data, paths)
	return paths

func representative_audit() -> Dictionary:
	return {
		"source_docs": source_doc_count(),
		"player_body": player_visual().get("body_texture", ""),
		"weapon_count": data.get("weapons", {}).size(),
		"enemy_count": data.get("enemies", {}).size(),
		"material_texture_count": material_texture_paths().size(),
		"ground_theme_count": ground_themes().size(),
		"music_track_count": music_tracks(true, true).size(),
		"sound_event_count": audio_data().get("sound_events", {}).size(),
		"vfx_count": data.get("vfx", {}).size(),
		"quality_tint_count": data.get("quality_tints", {}).size()
	}

func _collect_paths(value: Variant, paths: Array) -> void:
	if value is String:
		var text := String(value)
		if text.begins_with("res://"):
			paths.append(text)
	elif value is Array:
		for entry in value:
			_collect_paths(entry, paths)
	elif value is Dictionary:
		for key in value.keys():
			_collect_paths(value[key], paths)

func _color_from_rgb(values: Array) -> Color:
	if values.size() < 3:
		return Color.BLACK
	return Color(float(values[0]), float(values[1]), float(values[2]), 1.0)
