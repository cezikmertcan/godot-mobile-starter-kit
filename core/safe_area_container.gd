class_name SafeAreaContainer
extends MarginContainer


func _ready() -> void:
	if not get_viewport().size_changed.is_connected(_update_safe_area):
		get_viewport().size_changed.connect(_update_safe_area)
	_update_safe_area()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_safe_area()


func _update_safe_area() -> void:
	var safe_rect := DisplayServer.get_display_safe_area()
	if safe_rect.size.x <= 0 or safe_rect.size.y <= 0:
		return

	var viewport_size := get_viewport_rect().size
	var left := maxi(0, safe_rect.position.x)
	var top := maxi(0, safe_rect.position.y)
	var right := maxi(0, int(viewport_size.x) - safe_rect.position.x - safe_rect.size.x)
	var bottom := maxi(0, int(viewport_size.y) - safe_rect.position.y - safe_rect.size.y)
	add_theme_constant_override("margin_left", left)
	add_theme_constant_override("margin_top", top)
	add_theme_constant_override("margin_right", right)
	add_theme_constant_override("margin_bottom", bottom)
