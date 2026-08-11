extends Node


func pulse(duration_ms: int = 30, amplitude: float = 0.5) -> void:
	if not SettingsService.is_enabled("vibration_enabled"):
		return
	if OS.has_feature("android") or OS.has_feature("ios"):
		Input.vibrate_handheld(duration_ms, amplitude)
