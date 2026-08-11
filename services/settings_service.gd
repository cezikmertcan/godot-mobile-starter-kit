extends Node

signal setting_changed(setting_name: String, value: Variant)

var _settings: Dictionary = {}


func _ready() -> void:
	reload_from_save()


func reload_from_save() -> void:
	_settings = SaveService.get_settings()


func get_setting(setting_name: String, default_value: Variant = null) -> Variant:
	return _settings.get(setting_name, default_value)


func set_setting(setting_name: String, value: Variant) -> void:
	if _settings.get(setting_name) == value:
		return
	_settings[setting_name] = value
	SaveService.update_settings(_settings)
	setting_changed.emit(setting_name, value)


func is_enabled(setting_name: String) -> bool:
	return bool(get_setting(setting_name, true))


func set_sound_enabled(enabled: bool) -> void:
	set_setting("sound_enabled", enabled)


func set_music_enabled(enabled: bool) -> void:
	set_setting("music_enabled", enabled)


func set_vibration_enabled(enabled: bool) -> void:
	set_setting("vibration_enabled", enabled)
