extends CanvasLayer

var _background: ColorRect
var _message: Label


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide_loading()


func show_loading(message: String = "Loading...") -> void:
	_message.text = message
	_background.visible = true


func hide_loading() -> void:
	if _background != null:
		_background.visible = false


func _build() -> void:
	_background = ColorRect.new()
	_background.name = "LoadingBackground"
	_background.color = Color(0.02, 0.03, 0.08, 0.94)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background.add_child(center)

	var panel := ShellTheme.make_panel()
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)
	_message = ShellTheme.make_label("Loading...", 20, ShellTheme.TEXT)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_message)
