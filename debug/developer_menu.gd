extends Control


func _ready() -> void:
	var content := ShellTheme.setup_screen(self)
	var title := ShellTheme.make_label("Developer Tools", 32, ShellTheme.WARNING)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var note := ShellTheme.make_label("Debug-only utilities are kept outside the normal player flow.", 16, ShellTheme.MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(note)

	var ads_button := ShellTheme.make_button("Open LevelPlay Ad Test Screen", true)
	ads_button.pressed.connect(func() -> void: SceneTransitionManager.change_scene("res://scenes/ads_debug.tscn"))
	content.add_child(ads_button)

	var reset_button := ShellTheme.make_button("Reset Local Save")
	reset_button.pressed.connect(_on_reset_pressed)
	content.add_child(reset_button)

	ShellTheme.add_expand_spacer(content)
	var back_button := ShellTheme.make_button("Back")
	back_button.pressed.connect(func() -> void: SceneTransitionManager.change_scene("res://scenes/main_menu.tscn"))
	content.add_child(back_button)


func _on_reset_pressed() -> void:
	PopupManager.show_confirmation("Reset save?", "This removes local settings, currency, and placeholder progression.", Callable(self, "_confirm_reset"))


func _confirm_reset() -> void:
	SaveService.reset_save()
	SettingsService.reload_from_save()
	AudioManager.apply_settings()
	GameSession._load_progression()
	PopupManager.show_message("Save reset", "The local save has been restored to defaults.")
