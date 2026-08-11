class_name PauseMenu
extends Control

signal resume_requested
signal settings_requested
signal main_menu_requested


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.03, 0.08, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := ShellTheme.make_panel()
	panel.custom_minimum_size = Vector2(340, 0)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	var title := ShellTheme.make_label("Paused", 28, ShellTheme.TEXT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	content.add_child(ShellTheme.make_button("Resume", true))
	content.get_child(-1).pressed.connect(func() -> void: resume_requested.emit())
	content.add_child(ShellTheme.make_button("Settings"))
	content.get_child(-1).pressed.connect(func() -> void: settings_requested.emit())
	content.add_child(ShellTheme.make_button("Main Menu"))
	content.get_child(-1).pressed.connect(func() -> void: main_menu_requested.emit())
