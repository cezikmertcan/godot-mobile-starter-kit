extends Control

var _balance_label: Label
var _progress_label: Label


func _ready() -> void:
	var content := ShellTheme.setup_screen(self)
	var title := ShellTheme.make_label("Mobile Game Shell", 32, ShellTheme.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var subtitle := ShellTheme.make_label("Reusable portrait foundation", 17, ShellTheme.MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(subtitle)

	var status_panel := ShellTheme.make_panel()
	content.add_child(status_panel)
	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 6)
	status_panel.add_child(status_box)
	_progress_label = ShellTheme.make_label("", 18, ShellTheme.TEXT)
	_balance_label = ShellTheme.make_label("", 18, ShellTheme.SUCCESS)
	status_box.add_child(_progress_label)
	status_box.add_child(_balance_label)

	content.add_child(ShellTheme.make_section_title("Play"))
	var start_button := ShellTheme.make_button("Start Placeholder Level", true)
	start_button.pressed.connect(_on_start_pressed)
	content.add_child(start_button)

	var settings_button := ShellTheme.make_button("Settings")
	settings_button.pressed.connect(_on_settings_pressed)
	content.add_child(settings_button)

	if OS.is_debug_build():
		content.add_child(ShellTheme.make_section_title("Developer"))
		var developer_button := ShellTheme.make_button("Developer Tools")
		developer_button.pressed.connect(_on_developer_pressed)
		content.add_child(developer_button)

	ShellTheme.add_expand_spacer(content)
	var note := ShellTheme.make_label("No real game mechanic is included; add game-specific content when ready.", 15, ShellTheme.MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(note)

	if not SoftCurrencyService.balance_changed.is_connected(_on_balance_changed):
		SoftCurrencyService.balance_changed.connect(_on_balance_changed)
	_refresh_status()


func _on_start_pressed() -> void:
	AudioManager.play_ui_click()
	HapticManager.pulse()
	SceneTransitionManager.change_scene("res://scenes/gameplay_placeholder.tscn")


func _on_settings_pressed() -> void:
	AudioManager.play_ui_click()
	SceneTransitionManager.change_scene("res://scenes/settings.tscn")


func _on_developer_pressed() -> void:
	SceneTransitionManager.change_scene("res://scenes/developer_menu.tscn")


func _on_balance_changed(_balance: int, _delta: int, _source: String) -> void:
	_refresh_status()


func _refresh_status() -> void:
	var progression := SaveService.get_progression()
	_progress_label.text = "Current level: %d • Completed: %d" % [GameSession.current_level, int(progression.get("levels_completed", 0))]
	_balance_label.text = "Soft currency: %d" % SoftCurrencyService.get_balance()
