extends Node

signal bonus_granted(transaction_id: String, amount: int)
signal bonus_failed(reason: String)

var _pending_transaction_id := ""
var _pending_amount := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not AdsManager.reward_earned.is_connected(_on_reward_earned):
		AdsManager.reward_earned.connect(_on_reward_earned)
	if not AdsManager.ad_event.is_connected(_on_ad_event):
		AdsManager.ad_event.connect(_on_ad_event)


func has_pending_request() -> bool:
	return not _pending_transaction_id.is_empty()


func request_bonus(reward_name: String, bonus_amount: int) -> void:
	if has_pending_request():
		bonus_failed.emit("A rewarded request is already pending.")
		return
	if bonus_amount <= 0:
		bonus_failed.emit("The bonus amount must be positive.")
		return

	_pending_transaction_id = "rewarded_%s_%d" % [reward_name, Time.get_unix_time_from_system()]
	_pending_amount = bonus_amount
	AdsManager.show_rewarded(reward_name)


func _on_reward_earned(_reward_name: String, _amount: int) -> void:
	if not has_pending_request():
		return
	var transaction_id := _pending_transaction_id
	var amount := _pending_amount
	_clear_pending()
	if RewardService.grant_once(transaction_id, amount, "rewarded_ad"):
		AdFrequencyController.record_rewarded()
		bonus_granted.emit(transaction_id, amount)
	else:
		bonus_failed.emit("This rewarded transaction was already settled.")


func _on_ad_event(ad_type: String, event_name: String, message: String) -> void:
	if ad_type != "rewarded" or not has_pending_request():
		return
	if event_name in ["not_ready", "failed", "show_failed"]:
		_clear_pending()
		bonus_failed.emit(message if not message.is_empty() else "Rewarded ad was unavailable.")


func _clear_pending() -> void:
	_pending_transaction_id = ""
	_pending_amount = 0
