extends Node

const SAVE_PATH := "user://mobile_shell_save.json"
const CURRENT_SAVE_VERSION := 1

var _data: Dictionary = {}


func _ready() -> void:
	load_save()


func load_save() -> void:
	_data = _default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		save()
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		# Corrupt or incompatible data is replaced safely with a fresh save.
		save()
		return

	_data = _merge_defaults(_default_data(), parsed)
	_data["save_version"] = CURRENT_SAVE_VERSION
	save()


func save() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_data))
	return true


func reset_save() -> void:
	_data = _default_data()
	save()


func get_settings() -> Dictionary:
	return _data.get("settings", {}).duplicate(true)


func update_settings(settings: Dictionary) -> void:
	_data["settings"] = settings.duplicate(true)
	save()


func get_currency_balance() -> int:
	return int(_data.get("currency", {}).get("soft", 0))


func set_currency_balance(amount: int) -> void:
	_data["currency"]["soft"] = maxi(0, amount)
	save()


func get_progression() -> Dictionary:
	return _data.get("progression", {}).duplicate(true)


func update_progression(progression: Dictionary) -> void:
	_data["progression"] = progression.duplicate(true)
	save()


func get_ad_frequency() -> Dictionary:
	return _data.get("ad_frequency", {}).duplicate(true)


func update_ad_frequency(state: Dictionary) -> void:
	_data["ad_frequency"] = state.duplicate(true)
	save()


func has_claimed_reward(transaction_id: String) -> bool:
	return transaction_id in _data.get("claimed_rewards", [])


func mark_reward_claimed(transaction_id: String) -> void:
	if transaction_id.is_empty() or has_claimed_reward(transaction_id):
		return
	_data["claimed_rewards"].append(transaction_id)
	save()


func _default_data() -> Dictionary:
	return {
		"save_version": CURRENT_SAVE_VERSION,
		"settings": {
			"sound_enabled": true,
			"music_enabled": true,
			"vibration_enabled": true,
		},
		"currency": {
			"soft": 0,
		},
		"progression": {
			"current_level": 1,
			"levels_completed": 0,
		},
		"ad_frequency": {
			"last_interstitial_at": 0.0,
			"last_rewarded_at": 0.0,
			"interstitial_count": 0,
		},
		"claimed_rewards": [],
	}


func _merge_defaults(defaults: Dictionary, source: Dictionary) -> Dictionary:
	var result := defaults.duplicate(true)
	for key in source.keys():
		if not result.has(key):
			continue
		var default_value = result[key]
		var source_value = source[key]
		if default_value is Dictionary:
			if source_value is Dictionary:
				result[key] = _merge_defaults(default_value, source_value)
			continue
		if default_value is Array:
			if source_value is Array:
				result[key] = source_value
			continue
		if default_value is bool:
			if source_value is bool:
				result[key] = source_value
			continue
		if default_value is int or default_value is float:
			if source_value is int or source_value is float:
				result[key] = source_value
			continue
		if typeof(default_value) == typeof(source_value):
			result[key] = source_value
	return result
