extends Node

signal transition_started(scene_path: String)
signal transition_finished(scene_path: String)
signal transition_failed(scene_path: String, error_code: int)

var _transitioning := false


func change_scene(scene_path: String) -> void:
	if _transitioning:
		return
	if not ResourceLoader.exists(scene_path):
		transition_failed.emit(scene_path, ERR_FILE_NOT_FOUND)
		PopupManager.show_message("Scene unavailable", scene_path)
		return

	_transitioning = true
	transition_started.emit(scene_path)
	var overlay := get_node_or_null("/root/LoadingOverlay")
	if overlay != null:
		overlay.show_loading()
	call_deferred("_change_scene_deferred", scene_path)


func _change_scene_deferred(scene_path: String) -> void:
	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		_transitioning = false
		var overlay := get_node_or_null("/root/LoadingOverlay")
		if overlay != null:
			overlay.hide_loading()
		transition_failed.emit(scene_path, result)
		PopupManager.show_message("Scene transition failed", "%s (%s)" % [scene_path, result])
		return

	await get_tree().process_frame
	_transitioning = false
	var overlay := get_node_or_null("/root/LoadingOverlay")
	if overlay != null:
		overlay.hide_loading()
	transition_finished.emit(scene_path)
