class_name AudioRules
extends RefCounted

const PLAYERS_PER_POOL := 12
const QUEUE_LIMIT := 16
const DEQUEUE_PER_FRAME := 1

var queue_limit: int = QUEUE_LIMIT
var queued: Array = []
var active_by_id: Dictionary = {}

func request_sound(event_id: String, event_data: Dictionary, pitch_roll: float = 0.5, variant_roll: float = 0.0, position: Vector2 = Vector2.ZERO) -> Dictionary:
	var max_play := int(event_data.get("max_play", 0))
	if max_play > 0 and int(active_by_id.get(event_id, 0)) >= max_play:
		return {"accepted": false, "reason": "max_play"}
	if queued.size() >= queue_limit:
		if bool(event_data.get("always_play", false)):
			queued.pop_front()
		else:
			return {"accepted": false, "reason": "queue_full"}
	var paths: Array = event_data.get("paths", [])
	var path := ""
	if not paths.is_empty():
		var variant_index := clampi(floori(clamp(variant_roll, 0.0, 0.999999) * paths.size()), 0, paths.size() - 1)
		path = String(paths[variant_index])
	var request := {
		"id": event_id,
		"path": path,
		"bus": String(event_data.get("bus", "Sound")),
		"mode": String(event_data.get("mode", "global")),
		"volume_db": float(event_data.get("volume_db", 0.0)),
		"pitch": pitch_from_roll(float(event_data.get("pitch_rand", 0.0)), pitch_roll),
		"position": position,
		"always_play": bool(event_data.get("always_play", false)),
		"max_play": max_play
	}
	queued.append(request)
	return {"accepted": true, "request": request}

func dequeue_frame() -> Array:
	var played: Array = []
	for i in DEQUEUE_PER_FRAME:
		if queued.is_empty():
			break
		var request: Dictionary = queued.pop_front()
		var event_id := String(request.get("id", ""))
		active_by_id[event_id] = int(active_by_id.get(event_id, 0)) + 1
		played.append(request)
	return played

func finish_sound(event_id: String) -> void:
	var remaining: int = max(0, int(active_by_id.get(event_id, 0)) - 1)
	if remaining == 0:
		active_by_id.erase(event_id)
	else:
		active_by_id[event_id] = remaining

func queued_count() -> int:
	return queued.size()

func active_count(event_id: String) -> int:
	return int(active_by_id.get(event_id, 0))

static func pitch_from_roll(pitch_rand: float, roll: float) -> float:
	return 1.0 - pitch_rand + clamp(roll, 0.0, 1.0) * pitch_rand * 2.0

static func music_pool(tracks: Array, include_legacy: bool = true, include_streamer: bool = true) -> Array:
	var pool: Array = []
	for track in tracks:
		var group := String(track.get("pool", ""))
		if group == "legacy" and not include_legacy:
			continue
		if group == "streamer" and not include_streamer:
			continue
		pool.append(track)
	return pool

static func shuffled_tracks(tracks: Array, rolls: Array) -> Array:
	var shuffled := tracks.duplicate(true)
	if shuffled.size() <= 1:
		return shuffled
	var roll_index := 0
	for i in range(shuffled.size() - 1, 0, -1):
		var roll := 0.5
		if roll_index < rolls.size():
			roll = float(rolls[roll_index])
		roll_index += 1
		var j := clampi(floori(clamp(roll, 0.0, 0.999999) * float(i + 1)), 0, i)
		var tmp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp
	return shuffled

static func next_track(shuffled: Array, current_id: String = "") -> Dictionary:
	if shuffled.is_empty():
		return {}
	if String(shuffled[0].get("id", "")) != current_id or shuffled.size() == 1:
		return shuffled.pop_front()
	for i in range(1, shuffled.size()):
		if String(shuffled[i].get("id", "")) != current_id:
			var candidate: Dictionary = shuffled[i]
			shuffled.remove_at(i)
			return candidate
	return shuffled.pop_front()

static func music_volume_for_state(audio_data: Dictionary, state: String) -> float:
	return float(audio_data.get("music_states_db", {}).get(state, 0.0))
