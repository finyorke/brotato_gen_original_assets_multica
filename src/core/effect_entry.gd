class_name EffectEntry
extends RefCounted

enum StorageMethod {
	SUM,
	KEY_VALUE,
	REPLACE,
	APPEND_KEY,
	APPEND_KEY_VALUE,
}

var key: String = ""
var text_key: String = ""
var value: Variant = 0
var custom_key: String = ""
var storage_method: int = StorageMethod.SUM
var effect_sign: String = "NEUTRAL"
var custom_args: Array = []
var curse_factor: float = 1.0
var base_value: Variant = null

static func make(
		p_key: String,
		p_value: Variant,
		p_storage_method: int = StorageMethod.SUM,
		p_custom_key: String = ""
	):
	var entry = load("res://src/core/effect_entry.gd").new()
	entry.key = p_key
	entry.text_key = p_key.to_upper()
	entry.value = p_value
	entry.storage_method = p_storage_method
	entry.custom_key = p_custom_key
	return entry
