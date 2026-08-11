extends Node

var _sound_enabled := true
var _music_enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not SettingsService.setting_changed.is_connected(_on_setting_changed):
		SettingsService.setting_changed.connect(_on_setting_changed)
	apply_settings()


func apply_settings() -> void:
	_sound_enabled = SettingsService.is_enabled("sound_enabled")
	_music_enabled = SettingsService.is_enabled("music_enabled")
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, not (_sound_enabled or _music_enabled))


func play_ui_click() -> void:
	# A real game can attach an AudioStreamPlayer here without changing callers.
	if _sound_enabled:
		return


func is_sound_enabled() -> bool:
	return _sound_enabled


func is_music_enabled() -> bool:
	return _music_enabled


func _on_setting_changed(setting_name: String, _value: Variant) -> void:
	if setting_name in ["sound_enabled", "music_enabled"]:
		apply_settings()
