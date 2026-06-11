class_name EconomyCatalog
extends RefCounted

const EffectEntryScript = preload("res://src/core/effect_entry.gd")

const DEFAULT_PATH := "res://data/m3/economy_fixtures.json"
const M3_ITEMS_PATH := "res://data/m3/items.json"
const M3_WEAPONS_PATH := "res://data/m3/weapons.json"

var entries: Array = []
var entries_by_id: Dictionary = {}

static func from_json(path: String = DEFAULT_PATH):
	var catalog = load("res://src/economy/economy_catalog.gd").new()
	catalog._add_fixture_sections(path, ["items", "weapons", "consumables", "upgrades"])
	return catalog

static func from_m3_content(items_path: String = M3_ITEMS_PATH, weapons_path: String = M3_WEAPONS_PATH, fixture_path: String = DEFAULT_PATH):
	var catalog = load("res://src/economy/economy_catalog.gd").new()
	catalog._add_m3_items(items_path)
	catalog._add_m3_weapons(weapons_path)
	catalog._add_fixture_sections(fixture_path, ["consumables", "upgrades"])
	return catalog

func add_entry(entry: Dictionary) -> void:
	var normalized := entry.duplicate(true)
	normalized["id"] = String(normalized.get("id", ""))
	normalized["name"] = _localized_name(normalized.get("name", normalized["id"]), normalized["id"])
	normalized["kind"] = String(normalized.get("kind", "item"))
	normalized["tier"] = int(normalized.get("tier", 0))
	normalized["value"] = int(normalized.get("value", 0))
	normalized["max_nb"] = int(normalized.get("max_nb", -1))
	normalized["can_be_looted"] = bool(normalized.get("can_be_looted", true))
	normalized["is_lockable"] = bool(normalized.get("is_lockable", true))
	normalized["unlocked_by_default"] = bool(normalized.get("unlocked_by_default", true))
	normalized["tags"] = normalized.get("tags", []).duplicate(true)
	normalized["effects"] = _normalized_effects(normalized.get("effects", []))
	normalized["sets"] = normalized.get("sets", []).duplicate(true)
	if not normalized.has("weapon_id"):
		normalized["weapon_id"] = normalized["id"]
	entries.append(normalized)
	entries_by_id[normalized["id"]] = normalized

func get_entry(id: String) -> Dictionary:
	if not entries_by_id.has(id):
		return {}
	return entries_by_id[id].duplicate(true)

func pool(kind: String, tier: int, player: Variant = null, context: Dictionary = {}) -> Array:
	return _pool(kind, tier, player, context, false)

func pick(kind: String, tier: int, player: Variant = null, context: Dictionary = {}, roll: float = -1.0) -> Dictionary:
	var candidates := _pool(kind, tier, player, context, false)
	if candidates.is_empty():
		candidates = _pool(kind, tier, player, context, true)
	if candidates.is_empty():
		for entry in entries:
			if String(entry.get("kind", "")) == kind and _passes_hard_filters(entry, player, context):
				candidates.append(entry.duplicate(true))
	if candidates.is_empty():
		return {}
	var index := randi() % candidates.size() if roll < 0.0 else clampi(floori(roll * float(candidates.size())), 0, candidates.size() - 1)
	return candidates[index].duplicate(true)

func inventory_count(player: Variant, entry: Dictionary, context: Dictionary = {}) -> int:
	var count := 0
	if player != null and player.has_method("inventory_count"):
		count += int(player.inventory_count(String(entry.get("id", ""))))
	for id in context.get("current_shop_ids", []):
		if String(id) == String(entry.get("id", "")):
			count += 1
	for id in context.get("locked_shop_ids", []):
		if String(id) == String(entry.get("id", "")):
			count += 1
	return count

func _pool(kind: String, tier: int, player: Variant, context: Dictionary, hard_only: bool) -> Array:
	var result: Array = []
	for entry in entries:
		if String(entry.get("kind", "")) != kind:
			continue
		if int(entry.get("tier", 0)) != tier:
			continue
		if not _passes_hard_filters(entry, player, context):
			continue
		if not hard_only and not _passes_soft_filters(entry, context):
			continue
		result.append(entry.duplicate(true))
	return result

func _passes_hard_filters(entry: Dictionary, player: Variant, context: Dictionary) -> bool:
	if not bool(entry.get("can_be_looted", true)):
		return false
	if not bool(entry.get("unlocked_by_default", true)) and not context.get("unlocked_ids", []).has(String(entry.get("id", ""))):
		return false
	if int(entry.get("max_nb", -1)) == 0:
		return false
	if context.get("banned_ids", []).has(String(entry.get("id", ""))):
		return false
	if context.get("excluded_ids", []).has(String(entry.get("id", ""))):
		return false
	if player != null:
		if String(entry.get("kind", "")) == "weapon":
			if String(entry.get("type", "")) == "melee" and player.get_stat("no_melee_weapons") > 0.0:
				return false
			if String(entry.get("type", "")) == "ranged" and player.get_stat("no_ranged_weapons") > 0.0:
				return false
			if player.get_stat("no_duplicate_weapons") > 0.0 and player.has_method("has_weapon_family") and player.has_weapon_family(String(entry.get("weapon_id", entry.get("id", "")))):
				return false
		if String(entry.get("kind", "")) == "item":
			for removed in player.effects.get("remove_shop_items", []):
				if entry.get("tags", []).has(String(removed)):
					return false
		var max_nb := int(entry.get("max_nb", -1))
		if max_nb >= 0 and inventory_count(player, entry, context) >= max_nb:
			return false
	return true

func _passes_soft_filters(entry: Dictionary, context: Dictionary) -> bool:
	if context.has("wanted_weapon_ids") and not context.get("wanted_weapon_ids", []).is_empty():
		if not context["wanted_weapon_ids"].has(String(entry.get("weapon_id", entry.get("id", "")))):
			return false
	if context.has("wanted_weapon_sets") and not context.get("wanted_weapon_sets", []).is_empty():
		var matched_set := false
		for set_id in entry.get("sets", []):
			if context["wanted_weapon_sets"].has(String(set_id)):
				matched_set = true
				break
		if not matched_set:
			return false
	if context.has("wanted_item_tags") and not context.get("wanted_item_tags", []).is_empty():
		var matched_tag := false
		for tag in entry.get("tags", []):
			if context["wanted_item_tags"].has(String(tag)):
				matched_tag = true
				break
		if not matched_tag:
			return false
	return true

func _add_fixture_sections(path: String, sections: Array) -> void:
	var parsed := _parse_json(path)
	if parsed.is_empty():
		return
	for section in sections:
		for row in parsed.get(section, []):
			var entry: Dictionary = row.duplicate(true)
			entry["kind"] = String(entry.get("kind", String(section).trim_suffix("s")))
			add_entry(entry)

func _add_m3_items(path: String) -> void:
	var parsed := _parse_json(path)
	for row in parsed.get("items", []):
		var entry: Dictionary = row.duplicate(true)
		entry["kind"] = "item"
		entry["name"] = _localized_name(entry.get("name", entry.get("id", "")), String(entry.get("id", "")))
		add_entry(entry)

func _add_m3_weapons(path: String) -> void:
	var parsed := _parse_json(path)
	var variants_by_family_tier := {}
	for row in parsed.get("variants", []):
		var family_id := String(row.get("family_id", row.get("weapon_id", row.get("id", ""))))
		var tier := int(row.get("tier", 0))
		variants_by_family_tier["%s:%d" % [family_id, tier]] = row
	for row in parsed.get("variants", []):
		var entry: Dictionary = row.duplicate(true)
		var family_id := String(entry.get("family_id", entry.get("weapon_id", entry.get("id", ""))))
		var tier := int(entry.get("tier", 0))
		entry["kind"] = "weapon"
		entry["weapon_id"] = family_id
		entry["name"] = _weapon_display_name(entry)
		entry["can_be_looted"] = bool(entry.get("can_be_looted", true))
		entry["unlocked_by_default"] = bool(entry.get("unlocked_by_default", true))
		entry["is_lockable"] = bool(entry.get("is_lockable", true))
		var asset_refs: Dictionary = entry.get("asset_refs", {})
		entry["texture"] = String(entry.get("texture", asset_refs.get("texture", "")))
		entry["icon"] = String(entry.get("icon", asset_refs.get("icon", "")))
		var next_variant: Dictionary = variants_by_family_tier.get("%s:%d" % [family_id, tier + 1], {})
		entry["upgrades_into"] = String(next_variant.get("id", ""))
		add_entry(entry)

func _parse_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Could not parse economy catalog: %s" % path)
		return {}
	return parsed

func _localized_name(value: Variant, fallback: String = "") -> String:
	if value is Dictionary:
		return String(value.get("en", value.get("zh", fallback)))
	return String(value if value != null else fallback)

func _weapon_display_name(entry: Dictionary) -> String:
	var base_name := _localized_name(entry.get("name", entry.get("id", "")), String(entry.get("id", "")))
	var tier_name := String(entry.get("tier_name", ""))
	if tier_name.is_empty() or base_name.ends_with(" " + tier_name):
		return base_name
	return "%s %s" % [base_name, tier_name]

func _normalized_effects(source_effects: Array) -> Array:
	var result: Array = []
	for effect in source_effects:
		if not (effect is Dictionary):
			continue
		var effect_data: Dictionary = effect
		var key := String(effect_data.get("key", ""))
		if key.is_empty():
			continue
		var storage_method := _storage_method_id(effect_data.get("storage_method", EffectEntryScript.StorageMethod.SUM))
		if storage_method < 0:
			continue
		var normalized := effect_data.duplicate(true)
		normalized["storage_method"] = storage_method
		result.append(normalized)
	return result

func _storage_method_id(value: Variant) -> int:
	if value is int:
		return int(value)
	match String(value).to_upper():
		"SUM":
			return EffectEntryScript.StorageMethod.SUM
		"KEY_VALUE":
			return EffectEntryScript.StorageMethod.KEY_VALUE
		"REPLACE":
			return EffectEntryScript.StorageMethod.REPLACE
		"APPEND_KEY":
			return EffectEntryScript.StorageMethod.APPEND_KEY
		"APPEND_KEY_VALUE":
			return EffectEntryScript.StorageMethod.APPEND_KEY_VALUE
	return -1
