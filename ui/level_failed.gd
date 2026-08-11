extends Control


func _ready() -> void:
	var content := ShellTheme.setup_screen(self)
	var title := ShellTheme.make_label("Level Failed", 32, ShellTheme.DANGER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var message := ShellTheme.make_label("Nothing was lost. Retry is always available without an ad.", 18, ShellTheme.TEXT)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(message)
	ShellTheme.add_expand_spacer(content)

	var retry_button := ShellTheme.make_button("Retry Level", true)
	retry_button.pressed.connect(_on_retry_pressed)
	content.add_child(retry_button)
	var menu_button := ShellTheme.make_button("Main Menu")
	menu_button.pressed.connect(func() -> void: SceneTransitionManager.change_scene("res://scenes/main_menu.tscn"))
	content.add_child(menu_button)


func _on_retry_pressed() -> void:
	GameSession.retry_level()
	SceneTransitionManager.change_scene("res://scenes/gameplay_placeholder.tscn")
