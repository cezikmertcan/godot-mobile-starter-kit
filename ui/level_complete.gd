extends Control

var _bonus_button: Button
var _continue_button: Button
var _summary: Label


func _ready() -> void:
	var content := ShellTheme.setup_screen(self)
	var title := ShellTheme.make_label("Level Complete", 32, ShellTheme.SUCCESS)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var level_label := ShellTheme.make_label("Level %d finished" % GameSession.last_level_number, 20, ShellTheme.TEXT)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(level_label)

	var panel := ShellTheme.make_panel()
	content.add_child(panel)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	panel.add_child(info)
	_summary = ShellTheme.make_label("Normal reward: +%d soft currency\nCurrent balance: %d" % [GameSession.last_base_reward, SoftCurrencyService.get_balance()], 18, ShellTheme.TEXT)
	_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(_summary)
	var note := ShellTheme.make_label("The normal reward is granted locally and never requires an ad.", 15, ShellTheme.MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_child(note)

	content.add_child(ShellTheme.make_section_title("Optional reward"))
	_bonus_button = ShellTheme.make_button("Watch Ad for x2 Reward")
	_bonus_button.pressed.connect(_on_bonus_pressed)
	content.add_child(_bonus_button)

	ShellTheme.add_expand_spacer(content)
	_continue_button = ShellTheme.make_button("Continue to Next Level", true)
	_continue_button.pressed.connect(_on_continue_pressed)
	content.add_child(_continue_button)
	var menu_button := ShellTheme.make_button("Main Menu")
	menu_button.pressed.connect(func() -> void: SceneTransitionManager.change_scene("res://scenes/main_menu.tscn"))
	content.add_child(menu_button)

	if not RewardedAdHelper.bonus_granted.is_connected(_on_bonus_granted):
		RewardedAdHelper.bonus_granted.connect(_on_bonus_granted)
	if not RewardedAdHelper.bonus_failed.is_connected(_on_bonus_failed):
		RewardedAdHelper.bonus_failed.connect(_on_bonus_failed)


func _on_bonus_pressed() -> void:
	if GameSession.last_reward_id.is_empty():
		return
	_bonus_button.disabled = true
	_bonus_button.text = "Waiting for rewarded ad..."
	RewardedAdHelper.request_bonus(GameSession.last_reward_id + "_bonus", GameSession.last_base_reward)


func _on_bonus_granted(_transaction_id: String, amount: int) -> void:
	_bonus_button.text = "Bonus granted: +%d" % amount
	_summary.text = "Normal reward: +%d soft currency\nBonus reward: +%d\nCurrent balance: %d" % [GameSession.last_base_reward, amount, SoftCurrencyService.get_balance()]


func _on_bonus_failed(reason: String) -> void:
	_bonus_button.disabled = false
	_bonus_button.text = "Watch Ad for x2 Reward"
	PopupManager.show_message("Reward unavailable", reason)


func _on_continue_pressed() -> void:
	if RewardedAdHelper.has_pending_request():
		PopupManager.show_message("Reward pending", "Wait for the rewarded ad result before continuing.")
		return
	_continue_button.disabled = true
	AdFrequencyController.show_if_eligible("level_complete", Callable(self, "_go_to_next_level"))


func _go_to_next_level() -> void:
	SceneTransitionManager.change_scene("res://scenes/gameplay_placeholder.tscn")
