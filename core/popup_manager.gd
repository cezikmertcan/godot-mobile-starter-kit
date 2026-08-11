extends CanvasLayer

var _active_dialog: Window = null


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_message(title: String, message: String) -> void:
	_clear_dialog()
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.min_size = Vector2i(420, 180)
	add_child(dialog)
	_active_dialog = dialog
	dialog.confirmed.connect(_clear_dialog)
	dialog.close_requested.connect(_clear_dialog)
	dialog.popup_centered()


func show_confirmation(title: String, message: String, confirmed_action: Callable) -> void:
	_clear_dialog()
	var dialog := ConfirmationDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.min_size = Vector2i(460, 200)
	add_child(dialog)
	_active_dialog = dialog
	dialog.confirmed.connect(func() -> void:
		if confirmed_action.is_valid():
			confirmed_action.call()
		_clear_dialog()
	)
	dialog.canceled.connect(_clear_dialog)
	dialog.close_requested.connect(_clear_dialog)
	dialog.popup_centered()


func _clear_dialog() -> void:
	if is_instance_valid(_active_dialog):
		_active_dialog.queue_free()
	_active_dialog = null
