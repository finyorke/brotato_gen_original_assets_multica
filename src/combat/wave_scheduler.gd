class_name WaveScheduler
extends RefCounted

const FormulasScript = preload("res://src/core/formulas.gd")

const WARNING_TICKS := 60
const SPAWN_QUEUE_TICK_INTERVAL := 3

var wave_number: int = 1
var duration_seconds: float = 20.0
var max_enemies: int = 100
var elapsed_seconds: float = 0.0
var groups: Array = []
var warning_queue: Array = []
var spawn_queue: Array = []

var _next_second_to_process: int = 1
var _spawn_queue_tick: int = 0
var _formulas: Variant = FormulasScript.new()

static func from_dict(data: Dictionary):
	var scheduler = load("res://src/combat/wave_scheduler.gd").new()
	scheduler.wave_number = int(data.get("wave", 1))
	scheduler.duration_seconds = float(data.get("duration", 20.0))
	scheduler.max_enemies = int(data.get("max_enemies", 100))
	for group in data.get("groups", []):
		var state: Dictionary = group.duplicate(true)
		state["next_time"] = float(state.get("spawn_timing", 0.0))
		state["remaining_repeats"] = int(state.get("repeating", 0))
		state["current_interval"] = float(state.get("repeat_interval", 0.0))
		scheduler.groups.append(state)
	return scheduler

func advance(delta: float, danger: int, current_enemy_count: int, player_count: int = 1, number_of_enemies_percent: float = 0.0) -> Array:
	elapsed_seconds = min(duration_seconds, elapsed_seconds + delta)
	var requests: Array = []
	while _next_second_to_process <= floori(elapsed_seconds):
		requests.append_array(_process_second(_next_second_to_process, danger, current_enemy_count, player_count, number_of_enemies_percent))
		_next_second_to_process += 1
	return requests

func enqueue_warning(request: Dictionary, position: Vector2) -> void:
	var warning := request.duplicate(true)
	warning["position"] = position
	warning["remaining_ticks"] = WARNING_TICKS
	warning_queue.append(warning)

func physics_tick(player_position: Variant = null, relocate_spawn_position: Callable = Callable()) -> Array:
	var materialized: Array = []
	for warning in warning_queue.duplicate():
		var warning_data: Dictionary = warning
		warning_data["remaining_ticks"] = int(warning_data["remaining_ticks"]) - 1
		if int(warning_data["remaining_ticks"]) > 0:
			continue
		var warning_position: Vector2 = warning_data["position"]
		if _player_blocks_warning(warning_position, player_position):
			if relocate_spawn_position.is_valid():
				warning_data["position"] = relocate_spawn_position.call(String(warning_data.get("spawn_area", "full")))
			warning_data["remaining_ticks"] = WARNING_TICKS
			continue
		warning_queue.erase(warning)
		spawn_queue.append(warning_data)
	_spawn_queue_tick += 1
	if _spawn_queue_tick % SPAWN_QUEUE_TICK_INTERVAL == 0 and not spawn_queue.is_empty():
		var dequeue_count := _spawn_queue_dequeue_count()
		for i in dequeue_count:
			if spawn_queue.is_empty():
				break
			materialized.append(spawn_queue.pop_front())
	return materialized

func active_warning_count() -> int:
	return warning_queue.size()

func pending_spawn_count() -> int:
	return spawn_queue.size()

func _process_second(second: int, danger: int, current_enemy_count: int, player_count: int, number_of_enemies_percent: float) -> Array:
	var requests: Array = []
	var enemy_cap := _enemy_cap(player_count)
	var projected_enemy_count := current_enemy_count
	for i in groups.size():
		var group: Dictionary = groups[i]
		if danger < int(group.get("min_danger", 0)):
			continue
		if second < ceili(float(group.get("next_time", INF))):
			continue
		var count: int = _formulas.spawn_count(
			int(group.get("count_min", 1)),
			int(group.get("count_max", 1)),
			float(group.get("unit_spawn_rate", 1.0)),
			player_count,
			number_of_enemies_percent
		)
		if count > 0:
			var cull_count := mini(projected_enemy_count, maxi(0, projected_enemy_count + count - enemy_cap))
			projected_enemy_count = projected_enemy_count - cull_count + count
			requests.append({
				"enemy_id": String(group.get("enemy_id", "")),
				"count": count,
				"spawn_area": String(group.get("spawn_area", "full")),
				"performance_cull": cull_count,
			})
		_schedule_next_group_time(group)
		groups[i] = group
	return requests

func _schedule_next_group_time(group: Dictionary) -> void:
	var remaining := int(group.get("remaining_repeats", 0))
	if remaining <= 0:
		group["next_time"] = INF
		return
	var interval := float(group.get("current_interval", 0.0))
	group["next_time"] = float(group.get("next_time", 0.0)) + interval
	group["remaining_repeats"] = remaining - 1
	var decreased := interval - float(group.get("interval_decrease", 0.0))
	group["current_interval"] = max(float(group.get("min_repeat_interval", interval)), decreased)

func _enemy_cap(player_count: int) -> int:
	return int(max_enemies + float(maxi(1, player_count) - 1) * float(max_enemies) / 8.0)

func _player_blocks_warning(warning_position: Vector2, player_position: Variant) -> bool:
	if not player_position is Vector2:
		return false
	var player_vec: Vector2 = player_position
	return warning_position.is_equal_approx(player_vec)

func _spawn_queue_dequeue_count() -> int:
	if spawn_queue.size() <= 100:
		return 1
	return int(clamp(float(spawn_queue.size() - 100) / 10.0, 1.0, 2.0))
