class_name SaveService
extends RefCounted

const ProgressionStateScript = preload("res://src/progression/progression_state.gd")
const GameSettingsScript = preload("res://src/settings/game_settings.gd")

const SLOT_COUNT := 3
const BACKUP_COUNT := 5

var base_path: String = "user://"

func _init(p_base_path: String = "user://") -> void:
	base_path = _normalize_base_path(p_base_path)
	_ensure_base_dir()

func progress_path(slot: int) -> String:
	return _path("save_v3_%d.json" % [_clamp_slot(slot)])

func run_path(slot: int) -> String:
	return _path("run_v3_%d.json" % [_clamp_slot(slot)])

func settings_path() -> String:
	return _path("settings.json")

func save_progress(slot: int, progress: Variant) -> bool:
	return _write_json_atomic(progress_path(slot), progress.to_dict(), true)

func load_progress(slot: int) -> Variant:
	var parsed := _read_json_with_backups(progress_path(slot))
	if parsed.is_empty():
		return ProgressionStateScript.new()
	return ProgressionStateScript.from_dict(parsed)

func save_run(slot: int, run_state: Dictionary) -> bool:
	return _write_json_atomic(run_path(slot), run_state, true)

func load_run(slot: int) -> Dictionary:
	return _read_json_with_backups(run_path(slot))

func clear_run(slot: int) -> bool:
	var path := run_path(slot)
	if not FileAccess.file_exists(path):
		return true
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string("{}")
	file.close()
	return true

func save_settings(settings: Variant) -> bool:
	var payload: Dictionary = settings.to_dict() if settings is GameSettingsScript else settings
	return _write_json_atomic(settings_path(), payload, false)

func load_settings() -> Variant:
	var parsed := _read_json(settings_path())
	if parsed.is_empty():
		return GameSettingsScript.new()
	return GameSettingsScript.from_dict(parsed)

func copy_slot(from_slot: int, to_slot: int) -> bool:
	var source := progress_path(from_slot)
	if not FileAccess.file_exists(source):
		return false
	return _copy_file(source, progress_path(to_slot))

func _write_json_atomic(path: String, payload: Dictionary, backups: bool) -> bool:
	_ensure_base_dir()
	if backups:
		_rotate_backups(path)
	var tmp_path := "%s.tmp" % path
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return _copy_file(tmp_path, path)

func _read_json_with_backups(path: String) -> Dictionary:
	var parsed := _read_json(path)
	if not parsed.is_empty():
		return parsed
	for i in BACKUP_COUNT:
		parsed = _read_json(_backup_path(path, i))
		if not parsed.is_empty():
			return parsed
	return {}

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}

func _rotate_backups(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	for i in range(BACKUP_COUNT - 1, 0, -1):
		var previous := _backup_path(path, i - 1)
		if FileAccess.file_exists(previous):
			_copy_file(previous, _backup_path(path, i))
	_copy_file(path, _backup_path(path, 0))

func _copy_file(source: String, destination: String) -> bool:
	var text := FileAccess.get_file_as_string(source)
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true

func _backup_path(path: String, index: int) -> String:
	var extension_index := path.rfind(".")
	if extension_index < 0:
		return "%s_%02d.bak" % [path, index]
	return "%s_%02d.bak" % [path.substr(0, extension_index), index]

func _normalize_base_path(path: String) -> String:
	if path.ends_with("/") or path.ends_with("\\"):
		return path
	return path + "/"

func _path(file_name: String) -> String:
	return base_path + file_name

func _ensure_base_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(base_path))

func _clamp_slot(slot: int) -> int:
	return clampi(slot, 0, SLOT_COUNT - 1)
