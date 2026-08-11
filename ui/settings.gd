extends Control


func _ready() -> void:
	var content := ShellTheme.setup_screen(self)
	var title := ShellTheme.make_label("Settings", 32, ShellTheme.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	content.add_child(ShellTheme.make_label("These settings are saved locally on this device.", 16, ShellTheme.MUTED))

	var panel := ShellTheme.make_panel()
	content.add_child(panel)
	var settings_box := VBoxContainer.new()
	settings_box.add_theme_constant_override("separation", 10)
	panel.add_child(settings_box)
	settings_box.add_child(_make_toggle("Sound", "sound_enabled"))
	settings_box.add_child(_make_toggle("Music", "music_enabled"))
	settings_box.add_child(_make_toggle("Vibration", "vibration_enabled"))

	ShellTheme.add_expand_spacer(content)
	var back_button := ShellTheme.make_button("Back", true)
	back_button.pressed.connect(_on_back_pressed)
	content.add_child(back_button)


func _make_toggle(label_text: String, setting_name: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 48)
	row.add_theme_constant_override("separation", 12)
	var label := ShellTheme.make_label(label_text, 18, ShellTheme.TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var toggle := CheckButton.new()
	toggle.text = "On"
	toggle.button_pressed = SettingsService.is_enabled(setting_name)
	toggle.tooltip_text = "Toggle %s" % label_text
	toggle.toggled.connect(func(enabled: bool) -> void:
		SettingsService.set_setting(setting_name, enabled)
		if setting_name == "vibration_enabled":
			HapticManager.pulse()
	)
	row.add_child(toggle)
	return row


func _on_back_pressed() -> void:
	SceneTransitionManager.change_scene("res://scenes/main_menu.tscn")
