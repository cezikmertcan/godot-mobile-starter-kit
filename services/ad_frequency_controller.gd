extends Node

const INTERSTITIAL_COOLDOWN_SECONDS := 30.0
const REWARDED_COOLDOWN_SECONDS := 45.0
const RESULT_TIMEOUT_SECONDS := 8.0

var _state: Dictionary = {}
var _pending_callback: Callable = Callable()
var _pending_context := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_state = SaveService.get_ad_frequency()


func can_show_interstitial(_context: String = "") -> bool:
	if _pending_callback.is_valid():
		return false
	var now := Time.get_unix_time_from_system()
	var last_interstitial := float(_state.get("last_interstitial_at", 0.0))
	var last_rewarded := float(_state.get("last_rewarded_at", 0.0))
	return now - last_interstitial >= INTERSTITIAL_COOLDOWN_SECONDS and now - last_rewarded >= REWARDED_COOLDOWN_SECONDS


func show_if_eligible(context: String, continuation: Callable) -> void:
	if not can_show_interstitial(context):
		_call_continuation(continuation)
		return

	_pending_context = context
	_pending_callback = continuation
	if not AdsManager.ad_event.is_connected(_on_ad_event):
		AdsManager.ad_event.connect(_on_ad_event)
	AdsManager.show_interstitial()
	_wait_for_result()


func record_interstitial_shown() -> void:
	_state["last_interstitial_at"] = Time.get_unix_time_from_system()
	_state["interstitial_count"] = int(_state.get("interstitial_count", 0)) + 1
	SaveService.update_ad_frequency(_state)


func record_rewarded() -> void:
	_state["last_rewarded_at"] = Time.get_unix_time_from_system()
	SaveService.update_ad_frequency(_state)


func get_state() -> Dictionary:
	return _state.duplicate(true)


func _on_ad_event(ad_type: String, event_name: String, _message: String) -> void:
	if ad_type != "interstitial" or not _pending_callback.is_valid():
		return
	if event_name == "displayed":
		record_interstitial_shown()
	if event_name in ["closed", "failed", "show_failed", "not_ready"]:
		_finish_pending()


func _wait_for_result() -> void:
	await get_tree().create_timer(RESULT_TIMEOUT_SECONDS).timeout
	if _pending_callback.is_valid():
		_finish_pending()


func _finish_pending() -> void:
	var callback := _pending_callback
	_pending_callback = Callable()
	_pending_context = ""
	_call_continuation(callback)


func _call_continuation(callback: Callable) -> void:
	if callback.is_valid():
		callback.call()
