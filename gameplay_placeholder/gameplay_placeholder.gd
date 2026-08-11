extends Control

const LEVEL_DURATION := 10.0

var _elapsed := 0.0
var _resolved := false
var _progress_bar: ProgressBar
var _timer_label: Label
var _pause_menu: PauseMenu


func _ready() -> void:
	get_tree().paused = false
	GameSession.begin_level()
	var content := ShellTheme.setup_screen(self)

	var top_bar := HBoxContainer.new()
	content.add_child(top_bar)
	var title := ShellTheme.make_label("Placeholder Level %d" % GameSession.current_level, 25, ShellTheme.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	var pause_button := ShellTheme.make_button("Pause")
	pause_button.custom_minimum_size = Vector2(120, 52)
	pause_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	pause_button.pressed.connect(_on_pause_pressed)
	top_bar.add_child(pause_button)

	var panel := ShellTheme.make_panel()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(panel)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	panel.add_child(body)
	var heading := ShellTheme.make_label("Gameplay Placeholder", 28, ShellTheme.TEXT)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(heading)
	var explanation := ShellTheme.make_label("This scene proves the reusable flow without implementing a real game mechanic.", 16, ShellTheme.MUTED)
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(explanation)
	_timer_label = ShellTheme.make_label("Timer: 0.0s / %.1fs" % LEVEL_DURATION, 20, ShellTheme.WARNING)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_timer_label)
	_progress_bar = ProgressBar.new()
	_progress_bar.max_value = LEVEL_DURATION
	_progress_bar.value = 0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, 28)
	body.add_child(_progress_bar)
	var gameplay_note := ShellTheme.make_label("Choose Complete or Fail to exercise the result screens. No ads run during active gameplay.", 16, ShellTheme.MUTED)
	gameplay_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(gameplay_note)
	ShellTheme.add_expand_spacer(body)
	var complete_button := ShellTheme.make_button("Trigger Level Complete", true)
	complete_button.pressed.connect(_on_complete_pressed)
	body.add_child(complete_button)
	var fail_button := ShellTheme.make_button("Trigger Level Failed")
	fail_button.pressed.connect(_on_fail_pressed)
	body.add_child(fail_button)


func _process(delta: float) -> void:
	if _resolved or get_tree().paused:
		return
	_elapsed = minf(LEVEL_DURATION, _elapsed + delta)
	if _progress_bar != null:
		_progress_bar.value = _elapsed
	if _timer_label != null:
		_timer_label.text = "Timer: %.1fs / %.1fs" % [_elapsed, LEVEL_DURATION]


func _on_pause_pressed() -> void:
	if _pause_menu != null:
		return
	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_on_resume_requested)
	_pause_menu.settings_requested.connect(_on_pause_settings_requested)
	_pause_menu.main_menu_requested.connect(_on_pause_main_menu_requested)
	get_tree().paused = true
	HapticManager.pulse()


func _on_resume_requested() -> void:
	get_tree().paused = false
	if is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
	_pause_menu = null


func _on_pause_settings_requested() -> void:
	get_tree().paused = false
	SceneTransitionManager.change_scene("res://scenes/settings.tscn")


func _on_pause_main_menu_requested() -> void:
	get_tree().paused = false
	SceneTransitionManager.change_scene("res://scenes/main_menu.tscn")


func _on_complete_pressed() -> void:
	if _resolved:
		return
	_resolved = true
	GameSession.complete_level()
	SceneTransitionManager.change_scene("res://scenes/level_complete.tscn")


func _on_fail_pressed() -> void:
	if _resolved:
		return
	_resolved = true
	GameSession.fail_level()
	SceneTransitionManager.change_scene("res://scenes/level_failed.tscn")
