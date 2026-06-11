class_name ShopState
extends RefCounted

const EffectEntryScript = preload("res://src/core/effect_entry.gd")
const FormulasScript = preload("res://src/core/formulas.gd")

const SLOT_COUNT := 4
const WEAPON_CHANCE := 0.35

var wave: int = 1
var slots: Array = []
var paid_rerolls: int = 0
var free_rerolls: int = 0
var next_reroll_is_free: bool = false

var _formulas: Variant = FormulasScript.new()

static func open(player: Variant, catalog: Variant, p_wave: int, keep_lock: bool = true, rolls: Dictionary = {}):
	var shop = load("res://src/economy/shop_state.gd").new()
	shop.wave = p_wave
	shop.free_rerolls = maxi(0, int(player.get_stat("free_rerolls")))
	if not keep_lock:
		player.locked_shop_items.clear()
	for locked in player.locked_shop_items:
		var slot: Dictionary = locked.duplicate(true)
		slot["locked"] = true
		slot["sold"] = false
		shop.slots.append(slot)
	shop._fill_empty_slots(player, catalog, [], rolls.duplicate(true))
	shop._sync_locked_items(player)
	return shop

func slot_price(index: int, player: Variant) -> int:
	if index < 0 or index >= slots.size():
		return 0
	var slot: Dictionary = slots[index]
	if slot.get("sold", false):
		return 0
	return _formulas.shop_price(
		int(slot.get("value", 0)),
		int(slot.get("wave_value", wave)),
		player.get_stat("items_price"),
		_specific_price_percent(player, String(slot.get("id", ""))),
		player.get_stat("weapons_price"),
		String(slot.get("kind", "")) == "weapon",
		player.get_stat("hp_shop") > 0.0
	)

func reroll(player: Variant, catalog: Variant, rolls: Dictionary = {}) -> Dictionary:
	if _all_slots_locked():
		return {"ok": false, "reason": "all_slots_locked", "cost": 0, "free": false}
	var free := false
	var cost := 0
	if free_rerolls > 0:
		free_rerolls -= 1
		free = true
	elif next_reroll_is_free:
		next_reroll_is_free = false
		free = true
	else:
		cost = _formulas.reroll_price(wave, paid_rerolls, player.get_stat("reroll_price"), _formulas.endless_factor(wave))
		if player.materials < cost:
			return {"ok": false, "reason": "not_enough_materials", "cost": cost, "free": false}
		player.materials -= cost
		paid_rerolls += 1
	_apply_reroll_effects(player)
	var previous_ids: Array = []
	for i in range(slots.size() - 1, -1, -1):
		var slot: Dictionary = slots[i]
		if bool(slot.get("locked", false)):
			continue
		previous_ids.append(String(slot.get("id", "")))
		slots.remove_at(i)
	_fill_empty_slots(player, catalog, previous_ids, rolls.duplicate(true))
	_sync_locked_items(player)
	return {"ok": true, "cost": cost, "free": free}

func toggle_lock(index: int, player: Variant) -> bool:
	if player.get_stat("disable_item_locking") > 0.0:
		return false
	if index < 0 or index >= slots.size():
		return false
	var slot: Dictionary = slots[index]
	if slot.get("sold", false) or not bool(slot.get("is_lockable", true)):
		return false
	slot["locked"] = not bool(slot.get("locked", false))
	slots[index] = slot
	player.effects["used_item_locking"] = 1
	_sync_locked_items(player)
	return true

func buy_slot(index: int, player: Variant, catalog: Variant) -> Dictionary:
	if index < 0 or index >= slots.size():
		return {"ok": false, "reason": "bad_slot"}
	var slot: Dictionary = slots[index]
	if slot.get("sold", false):
		return {"ok": false, "reason": "sold"}
	var price: int = slot_price(index, player)
	if not _can_pay(player, price):
		return {"ok": false, "reason": "not_enough_currency", "price": price}
	var result: Dictionary
	if String(slot.get("kind", "")) == "weapon":
		result = _acquire_weapon(player, catalog, slot)
	else:
		result = _acquire_item(player, slot)
	if not bool(result.get("ok", false)):
		return result
	_pay(player, price)
	slot["sold"] = true
	slot["locked"] = false
	slots[index] = slot
	_update_empty_shop_reward()
	_sync_locked_items(player)
	result["price"] = price
	return result

func ban_slot(index: int) -> bool:
	if index < 0 or index >= slots.size():
		return false
	var slot: Dictionary = slots[index]
	if slot.get("sold", false):
		return false
	slot["sold"] = true
	slot["locked"] = false
	slot["banned"] = true
	slots[index] = slot
	_update_empty_shop_reward()
	return true

func combine_weapon_by_id(player: Variant, catalog: Variant, item_id: String) -> Dictionary:
	if player.get_stat("lock_current_weapons") > 0.0:
		return {"ok": false, "reason": "locked_weapons"}
	var indexes: Array = player.weapon_indexes_for_item(item_id)
	if indexes.size() < 2:
		return {"ok": false, "reason": "missing_pair"}
	var entry: Dictionary = catalog.get_entry(item_id)
	var upgrade_id := String(entry.get("upgrades_into", ""))
	if upgrade_id.is_empty() or int(entry.get("tier", 0)) >= int(player.get_stat("max_weapon_tier")):
		return {"ok": false, "reason": "not_upgradable"}
	player.remove_weapon_at(int(indexes[1]))
	player.remove_weapon_at(int(indexes[0]))
	player.add_weapon(catalog.get_entry(upgrade_id))
	return {"ok": true, "upgraded_to": upgrade_id}

func recycle_weapon(index: int, player: Variant) -> Dictionary:
	if player.get_stat("lock_current_weapons") > 0.0:
		return {"ok": false, "reason": "locked_weapons"}
	if index < 0 or index >= player.weapons.size():
		return {"ok": false, "reason": "bad_weapon"}
	var weapon: Dictionary = player.weapons[index]
	var price: int = _formulas.shop_price(
		int(weapon.get("value", 0)),
		wave,
		player.get_stat("items_price"),
		_specific_price_percent(player, String(weapon.get("id", ""))),
		player.get_stat("weapons_price"),
		true,
		false
	)
	var value: int = _formulas.recycle_value(price, int(weapon.get("value", 0)), player.get_stat("recycling_gains"))
	player.remove_weapon_at(index)
	player.materials += value
	return {"ok": true, "value": value, "shop_price": price}

func _fill_empty_slots(player: Variant, catalog: Variant, previous_ids: Array, rolls: Dictionary) -> void:
	var wanted_weapon_context: Dictionary = _weapon_preference_context(player, _take_roll(rolls, "weapon_preference_rolls"))
	var guaranteed_weapons: int = maxi(_base_weapon_guarantee(), int(player.get_stat("minimum_weapons_in_shop"))) - _locked_weapon_count()
	if player.get_stat("weapon_slot") <= 0.0:
		guaranteed_weapons = 0
	while slots.size() < SLOT_COUNT:
		var kind: String = "item"
		if guaranteed_weapons > 0:
			kind = "weapon"
			guaranteed_weapons -= 1
		elif player.get_stat("weapon_slot") > 0.0 and _take_roll(rolls, "kind_rolls") <= WEAPON_CHANCE:
			kind = "weapon"
		var min_tier: int = int(player.get_stat("min_weapon_tier")) if kind == "weapon" else 0
		var max_tier: int = int(player.get_stat("max_weapon_tier")) if kind == "weapon" else 3
		var tier: int = _formulas.roll_shop_tier(wave, player.get_stat("stat_luck"), _take_roll(rolls, "tier_rolls"), min_tier, max_tier, _consume_increase_tier(player))
		var context: Dictionary = _catalog_context(player, previous_ids)
		if kind == "weapon":
			context.merge(wanted_weapon_context, true)
		else:
			var tag_chance: float = 0.10 if player.get_stat("stat_boosted_wanted_item_tag") > 0.0 else 0.05
			if _take_roll(rolls, "tag_rolls") <= tag_chance:
				context["wanted_item_tags"] = player.wanted_tags
		var entry: Dictionary = catalog.pick(kind, tier, player, context, _take_roll(rolls, "pick_rolls"))
		if entry.is_empty() and kind == "weapon":
			entry = catalog.pick("item", tier, player, _catalog_context(player, previous_ids), _take_roll(rolls, "pick_rolls"))
		if entry.is_empty():
			break
		entry["wave_value"] = wave
		entry["locked"] = false
		entry["sold"] = false
		slots.append(entry)

func _catalog_context(player: Variant, previous_ids: Array) -> Dictionary:
	var current_ids: Array = []
	var locked_ids: Array = []
	for slot in slots:
		var slot_data: Dictionary = slot
		if slot_data.get("sold", false):
			continue
		current_ids.append(String(slot_data.get("id", "")))
		if bool(slot_data.get("locked", false)):
			locked_ids.append(String(slot_data.get("id", "")))
	return {
		"excluded_ids": previous_ids + current_ids,
		"current_shop_ids": current_ids,
		"locked_shop_ids": locked_ids,
		"banned_ids": player.banned_shop_ids,
	}

func _weapon_preference_context(player: Variant, roll: float) -> Dictionary:
	if player.weapons.is_empty():
		return {}
	var same_weapon_chance: float = 0.2 + max(0.0, float(6 - wave)) * 0.01
	var same_set_chance: float = 0.35 + max(0.0, float(6 - wave)) * 0.04
	var actual_roll: float = randf() if roll < 0.0 else roll
	if actual_roll <= same_weapon_chance:
		return {"wanted_weapon_ids": player.weapon_families()}
	if actual_roll <= same_weapon_chance + same_set_chance:
		return {"wanted_weapon_sets": player.weapon_sets()}
	return {}

func _acquire_item(player: Variant, slot: Dictionary) -> Dictionary:
	player.add_item(slot)
	for effect_data in slot.get("effects", []):
		player.apply_effect(_effect_from_dict(effect_data))
	return {"ok": true, "kind": "item", "id": String(slot.get("id", ""))}

func _acquire_weapon(player: Variant, catalog: Variant, slot: Dictionary) -> Dictionary:
	if player.weapon_count() < int(player.get_stat("weapon_slot")):
		player.add_weapon(slot)
		return {"ok": true, "kind": "weapon", "id": String(slot.get("id", ""))}
	var match_index: int = player.first_weapon_index_for_item(String(slot.get("id", "")))
	if match_index < 0:
		return {"ok": false, "reason": "weapon_slots_full"}
	var upgrade_id := String(slot.get("upgrades_into", ""))
	if upgrade_id.is_empty() or int(slot.get("tier", 0)) >= int(player.get_stat("max_weapon_tier")):
		return {"ok": false, "reason": "weapon_not_upgradable"}
	player.remove_weapon_at(match_index)
	player.add_weapon(catalog.get_entry(upgrade_id))
	return {"ok": true, "kind": "weapon", "id": String(slot.get("id", "")), "upgraded_to": upgrade_id}

func _effect_from_dict(data: Dictionary) -> Variant:
	return EffectEntryScript.make(
		String(data.get("key", "")),
		data.get("value", 0),
		int(data.get("storage_method", EffectEntryScript.StorageMethod.SUM)),
		String(data.get("custom_key", ""))
	)

func _specific_price_percent(player: Variant, id: String) -> float:
	var total := 0.0
	for pair in player.effects.get("specific_items_price", []):
		if pair is Array and pair.size() >= 2 and String(pair[0]) == id:
			total += float(pair[1])
	return total

func _consume_increase_tier(player: Variant) -> int:
	var entries: Array = player.effects.get("increase_tier_on_reroll", [])
	if entries.is_empty():
		return 0
	var entry = entries.pop_front()
	if entry is Array and entry.size() >= 2:
		return int(entry[1])
	return int(entry)

func _apply_reroll_effects(player: Variant) -> void:
	for pair in player.effects.get("gain_stats_on_reroll", []):
		if pair is Array and pair.size() >= 2:
			player.add_permanent_stat(String(pair[0]), int(pair[1]))

func _can_pay(player: Variant, price: int) -> bool:
	if player.get_stat("hp_shop") > 0.0:
		return player.get_max_health() - price >= 1
	return player.materials >= price

func _pay(player: Variant, price: int) -> void:
	if player.get_stat("hp_shop") > 0.0:
		player.add_permanent_stat("stat_max_hp", -price)
		player.current_health = mini(player.current_health, player.get_max_health())
	else:
		player.materials -= price

func _all_slots_locked() -> bool:
	if slots.is_empty():
		return false
	for slot in slots:
		var slot_data: Dictionary = slot
		if not slot_data.get("sold", false) and not bool(slot_data.get("locked", false)):
			return false
	return true

func _locked_weapon_count() -> int:
	var count := 0
	for slot in slots:
		var slot_data: Dictionary = slot
		if bool(slot_data.get("locked", false)) and String(slot_data.get("kind", "")) == "weapon":
			count += 1
	return count

func _base_weapon_guarantee() -> int:
	if wave <= 2:
		return 2
	if wave <= 5:
		return 1
	return 0

func _update_empty_shop_reward() -> void:
	for slot in slots:
		var slot_data: Dictionary = slot
		if not slot_data.get("sold", false):
			return
	next_reroll_is_free = true

func _sync_locked_items(player: Variant) -> void:
	player.locked_shop_items.clear()
	for slot in slots:
		var slot_data: Dictionary = slot
		if bool(slot_data.get("locked", false)) and not slot_data.get("sold", false):
			player.locked_shop_items.append(slot_data.duplicate(true))

func _take_roll(rolls: Dictionary, key: String) -> float:
	if not rolls.has(key):
		return -1.0
	var values: Array = rolls[key]
	if values.is_empty():
		return -1.0
	return float(values.pop_front())
