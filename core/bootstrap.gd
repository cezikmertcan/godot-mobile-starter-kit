extends Node


func _ready() -> void:
	get_tree().paused = false
	SettingsService.reload_from_save()
	AudioManager.apply_settings()
	SceneTransitionManager.change_scene("res://scenes/main_menu.tscn")
