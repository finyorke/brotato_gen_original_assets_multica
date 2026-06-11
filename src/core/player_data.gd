class_name PlayerData
extends RefCounted

const EffectKeysScript = preload("res://src/core/effect_keys.gd")

const BASE_PLAYER_SPEED := 450.0
const STORAGE_SUM := 0
const STORAGE_KEY_VALUE := 1
const STORAGE_REPLACE := 2
const STORAGE_APPEND_KEY := 3
const STORAGE_APPEND_KEY_VALUE := 4

var effects: Dictionary = {}
var temporary_stats: Dictionary = {}
var linked_stats: Dictionary = {}
var materials: int = 0
var level: int = 0
var current_xp: float = 0.0
var current_health: int = 10

var _stat_cache: Dictionary = {}
var _replace_stack: Dictionary = {}

func _init() -> void:
	reset()

func reset() -> void:
	effects = EffectKeysScript.defaults()
	temporary_stats = {}
	linked_stats = {}
	materials = 0
	level = 0
	current_xp = 0.0
	current_health = get_max_health()
	_stat_cache.clear()
	_replace_stack.clear()

func apply_effect(effect) -> void:
	match int(effect.storage_method):
		STORAGE_SUM:
			effects[effect.key] = effects.get(effect.key, 0) + effect.value
		STORAGE_KEY_VALUE:
			_apply_key_value(effect, 1)
		STORAGE_REPLACE:
			_apply_replace(effect)
		STORAGE_APPEND_KEY:
			_apply_append_key(effect, 1)
		STORAGE_APPEND_KEY_VALUE:
			_apply_append_key_value(effect, 1)
		_:
			push_error("Unknown storage method: %s" % effect.storage_method)
	invalidate_cache()

func remove_effect(effect) -> void:
	match int(effect.storage_method):
		STORAGE_SUM:
			effects[effect.key] = effects.get(effect.key, 0) - effect.value
		STORAGE_KEY_VALUE:
			_apply_key_value(effect, -1)
		STORAGE_REPLACE:
			_remove_replace(effect)
		STORAGE_APPEND_KEY:
			_apply_append_key(effect, -1)
		STORAGE_APPEND_KEY_VALUE:
			_apply_append_key_value(effect, -1)
		_:
			push_error("Unknown storage method: %s" % effect.storage_method)
	invalidate_cache()

func add_permanent_stat(stat_key: String, amount: int) -> void:
	effects[stat_key] = effects.get(stat_key, 0) + amount
	invalidate_cache()

func add_temporary_stat(stat_key: String, amount: int) -> void:
	temporary_stats[stat_key] = temporary_stats.get(stat_key, 0) + amount
	invalidate_cache()

func clear_temporary_stats() -> void:
	temporary_stats.clear()
	linked_stats.clear()
	invalidate_cache()

func get_gain_multiplier(stat_key: String) -> float:
	return 1.0 + float(effects.get("gain_" + stat_key, 0)) / 100.0

func get_stat(stat_key: String) -> float:
	if _stat_cache.has(stat_key):
		return _stat_cache[stat_key]
	var gain := get_gain_multiplier(stat_key)
	var value := (
		float(effects.get(stat_key, 0))
		+ float(temporary_stats.get(stat_key, 0))
		+ float(linked_stats.get(stat_key, 0))
	) * gain
	_stat_cache[stat_key] = value
	return value

func get_permanent_stat(stat_key: String, with_gain: bool = true) -> float:
	var value := float(effects.get(stat_key, 0))
	if with_gain:
		value *= get_gain_multiplier(stat_key)
	return value

func get_capped_stat(stat_key: String) -> float:
	if not EffectKeysScript.CAPPED_STATS.has(stat_key):
		return get_stat(stat_key)
	var cap_key: String = String(EffectKeysScript.CAPPED_STATS[stat_key])
	return min(get_stat(stat_key), float(effects.get(cap_key, EffectKeysScript.INF_CAP)))

func get_max_health() -> int:
	return maxi(1, roundi(get_capped_stat("stat_max_hp")))

func get_speed() -> float:
	var capped_speed: float = min(get_stat("stat_speed"), float(effects.get("speed_cap", EffectKeysScript.INF_CAP)))
	return max(0.0, BASE_PLAYER_SPEED * (1.0 + capped_speed / 100.0))

func get_dodge_probability() -> float:
	return max(0.0, min(get_capped_stat("stat_dodge"), 90.0) / 100.0)

func recalculate_linked_stats(context: Dictionary = {}) -> void:
	linked_stats.clear()
	invalidate_cache()
	var computed_linked_stats := {}
	var links: Array = effects.get("stat_links", [])
	for link in links:
		if not (link is Array) or link.size() < 4:
			continue
		var stat_to_tweak := String(link[0])
		var nb_to_tweak := float(link[1])
		var stat_scaled := String(link[2])
		var nb_stat_scaled := float(link[3])
		var perm_stats_only := bool(link[4]) if link.size() > 4 else false
		if is_zero_approx(nb_stat_scaled):
			continue
		var actual_scaled := _get_link_source(stat_scaled, perm_stats_only, context)
		var amount := int(nb_to_tweak * actual_scaled / nb_stat_scaled)
		computed_linked_stats[stat_to_tweak] = computed_linked_stats.get(stat_to_tweak, 0) + amount
	linked_stats = computed_linked_stats
	invalidate_cache()

func gain_xp(value: float) -> int:
	if value <= 0.0:
		return 0
	current_xp += value * (1.0 + get_stat("xp_gain") / 100.0)
	var gained_levels := 0
	while current_xp >= _next_level_xp_needed(level, get_stat("next_level_xp_needed")):
		var needed: float = _next_level_xp_needed(level, get_stat("next_level_xp_needed"))
		current_xp -= needed
		level += 1
		gained_levels += 1
		add_permanent_stat("stat_max_hp", 1)
		current_health = mini(get_max_health(), current_health + 1)
		_apply_stat_pairs(effects.get("stats_on_level_up", []))
	return gained_levels

func invalidate_cache() -> void:
	_stat_cache.clear()

func _apply_stat_pairs(pairs: Array) -> void:
	for pair in pairs:
		if pair is Array and pair.size() >= 2:
			add_permanent_stat(String(pair[0]), int(pair[1]))

func _container_key(effect) -> String:
	if effect.custom_key.is_empty():
		return effect.key
	return effect.custom_key

func _ensure_array(key: String) -> Array:
	if not effects.has(key) or not (effects[key] is Array):
		effects[key] = []
	return effects[key]

func _apply_key_value(effect, sign: int) -> void:
	var arr := _ensure_array(_container_key(effect))
	for i in arr.size():
		var entry = arr[i]
		if entry is Array and entry.size() >= 2 and String(entry[0]) == effect.key:
			entry[1] = entry[1] + effect.value * sign
			if entry[1] == 0:
				arr.remove_at(i)
			return
	if sign > 0:
		arr.append([effect.key, effect.value])

func _apply_replace(effect) -> void:
	if not _replace_stack.has(effect.key):
		_replace_stack[effect.key] = []
	_replace_stack[effect.key].append(_duplicate_variant(effects.get(effect.key, null)))
	effect.base_value = _duplicate_variant(effects.get(effect.key, null))
	effects[effect.key] = _duplicate_variant(effect.value)

func _remove_replace(effect) -> void:
	var stack: Array = _replace_stack.get(effect.key, [])
	if stack.is_empty():
		return
	effects[effect.key] = stack.pop_back()
	if stack.is_empty():
		_replace_stack.erase(effect.key)

func _apply_append_key(effect, sign: int) -> void:
	var arr := _ensure_array(_container_key(effect))
	if sign > 0:
		if not arr.has(effect.key):
			arr.append(effect.key)
	else:
		arr.erase(effect.key)

func _apply_append_key_value(effect, sign: int) -> void:
	var arr := _ensure_array(_container_key(effect))
	if sign > 0:
		arr.append([effect.key, effect.value])
		return
	for i in arr.size():
		var entry = arr[i]
		if entry is Array and entry.size() >= 2 and String(entry[0]) == effect.key and entry[1] == effect.value:
			arr.remove_at(i)
			return

func _get_link_source(source: String, perm_stats_only: bool, context: Dictionary) -> float:
	match source:
		"materials":
			return float(context.get("materials", materials))
		"structures", "structure_count":
			return float(context.get("structures", context.get("structure_count", effects.get("structures", []).size())))
		"pets", "pet_count":
			return float(context.get("pets", context.get("pet_count", effects.get("stat_pets", []).size())))
		"missing_hp_percent":
			var max_health: float = max(1.0, float(get_max_health()))
			return floor(max(0.0, (max_health - float(current_health)) / max_health * 100.0))
	if effects.has(source):
		return get_permanent_stat(source, true) if perm_stats_only else get_stat(source)
	return float(context.get(source, 0))

func _duplicate_variant(value: Variant) -> Variant:
	if value is Array or value is Dictionary:
		return value.duplicate(true)
	return value

func _next_level_xp_needed(current_level: int, next_level_xp_needed_percent: float = 0.0) -> float:
	return float(pow(3 + current_level + 1, 2)) * (1.0 + next_level_xp_needed_percent / 100.0)
