class_name CoopState
extends RefCounted

const PlayerDataScript = preload("res://src/core/player_data.gd")
const FormulasScript = preload("res://src/core/formulas.gd")
const ShopStateScript = preload("res://src/economy/shop_state.gd")

const MAX_PLAYERS := 4
const SWITCH_MAX_PLAYERS := 2
const JOIN_HOLD_SECONDS := 0.7
const BAN_TOKEN_LIMIT := 8

var players: Array = []
var share_coop_loot: bool = true
var lock_coop_camera: bool = false
var bonus_gold: int = 0
var next_material_recipient: int = 0

var _formulas: Variant = FormulasScript.new()

func player_count() -> int:
	return players.size()

func add_player(player_data: Variant = null, character_id: String = "", starting_weapon_id: String = "") -> int:
	if players.size() >= MAX_PLAYERS:
		return -1
	var data = player_data if player_data != null else PlayerDataScript.new()
	var index := players.size()
	players.append({
		"index": index,
		"player_data": data,
		"character_id": character_id,
		"starting_weapon_id": starting_weapon_id,
		"alive": true,
		"ready": false,
		"pending_boxes": [],
		"ban_tokens": BAN_TOKEN_LIMIT,
	})
	return index

func player_data(index: int) -> Variant:
	if index < 0 or index >= players.size():
		return null
	var player: Dictionary = players[index]
	return player.get("player_data", null)

func living_player_count() -> int:
	var count := 0
	for player in players:
		var state: Dictionary = player
		if bool(state.get("alive", false)):
			count += 1
	return count

func set_alive(index: int, alive: bool) -> void:
	if index < 0 or index >= players.size():
		return
	var player: Dictionary = players[index]
	player["alive"] = alive
	players[index] = player

func all_players_dead() -> bool:
	return player_count() > 0 and living_player_count() == 0

func start_wave() -> void:
	for i in players.size():
		var state: Dictionary = players[i]
		var data = state["player_data"]
		state["alive"] = true
		state["ready"] = false
		var start_percent: float = max(0.0, data.get_stat("hp_start_wave"))
		data.current_health = maxi(1, roundi(float(data.get_max_health()) * start_percent / 100.0))
		players[i] = state

func set_ready(index: int, ready: bool) -> void:
	if index < 0 or index >= players.size():
		return
	var player: Dictionary = players[index]
	player["ready"] = ready
	players[index] = player

func all_ready() -> bool:
	if players.is_empty():
		return false
	for player in players:
		var state: Dictionary = player
		if not bool(state.get("ready", false)):
			return false
	return true

func pickup_material(value: int) -> Dictionary:
	var amount := maxi(0, value)
	var distribution: Array = []
	for i in players.size():
		distribution.append({"player_index": i, "materials": 0, "levels": 0})
	if players.is_empty() or amount <= 0:
		return {"distribution": distribution, "total": 0}
	for point in amount:
		var index := next_material_recipient % players.size()
		var state: Dictionary = players[index]
		var data = state["player_data"]
		data.materials += 1
		distribution[index]["materials"] = int(distribution[index]["materials"]) + 1
		distribution[index]["levels"] = int(distribution[index]["levels"]) + data.gain_xp(1)
		next_material_recipient = (next_material_recipient + 1) % players.size()
	return {"distribution": distribution, "total": amount}

func assign_item_box(pickup_player_index: int, tie_roll: float = -1.0) -> int:
	if players.is_empty():
		return -1
	var target_index := clampi(pickup_player_index, 0, players.size() - 1)
	if share_coop_loot:
		var min_boxes := 999999
		var tied_indexes: Array = []
		for i in players.size():
			var state: Dictionary = players[i]
			var count := (state.get("pending_boxes", []) as Array).size()
			if count < min_boxes:
				min_boxes = count
				tied_indexes = [i]
			elif count == min_boxes:
				tied_indexes.append(i)
		var roll: float = randf() if tie_roll < 0.0 else clamp(tie_roll, 0.0, 0.999999)
		target_index = int(tied_indexes[floori(roll * float(tied_indexes.size()))])
	var target: Dictionary = players[target_index]
	var boxes: Array = target.get("pending_boxes", [])
	boxes.append({"kind": "item_box"})
	target["pending_boxes"] = boxes
	players[target_index] = target
	return target_index

func create_shop_states(catalog: Variant, wave: int, keep_lock: bool = true, rolls_by_player: Array = []) -> Array:
	var result: Array = []
	for i in players.size():
		var state: Dictionary = players[i]
		var rolls: Dictionary = rolls_by_player[i] if i < rolls_by_player.size() and rolls_by_player[i] is Dictionary else {}
		result.append(ShopStateScript.open(state["player_data"], catalog, wave, keep_lock, rolls))
	return result

func coop_enemy_context() -> Dictionary:
	return {
		"player_count": players.size(),
		"enemy_quantity_multiplier": _formulas.coop_enemy_count_multiplier(players.size()),
		"enemy_health_multiplier": _formulas.coop_enemy_health_multiplier(players.size()),
		"enemy_damage_multiplier": _formulas.coop_enemy_damage_multiplier(players.size()),
		"material_value_multiplier": _formulas.coop_material_value_multiplier(players.size()),
	}
