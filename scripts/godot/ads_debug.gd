extends Control

@onready var platform_value: Label = %PlatformValue
@onready var provider_value: Label = %ProviderValue
@onready var sdk_value: Label = %SdkValue
@onready var rewarded_value: Label = %RewardedValue
@onready var interstitial_value: Label = %InterstitialValue
@onready var banner_value: Label = %BannerValue
@onready var log_output: RichTextLabel = %LogOutput

var _log_lines: Array[String] = []


func _ready() -> void:
	%InitializeButton.pressed.connect(_on_initialize_pressed)
	%LoadRewardedButton.pressed.connect(_on_load_rewarded_pressed)
	%ShowRewardedButton.pressed.connect(_on_show_rewarded_pressed)
	%LoadInterstitialButton.pressed.connect(_on_load_interstitial_pressed)
	%ShowInterstitialButton.pressed.connect(_on_show_interstitial_pressed)
	%ShowBannerButton.pressed.connect(_on_show_banner_pressed)
	%HideBannerButton.pressed.connect(_on_hide_banner_pressed)
	%ClearLogButton.pressed.connect(_on_clear_log_pressed)

	AdsManager.status_changed.connect(_on_status_changed)
	AdsManager.sdk_initialized.connect(_on_sdk_initialized)
	AdsManager.ad_event.connect(_on_ad_event)
	AdsManager.reward_earned.connect(_on_reward_earned)
	_on_status_changed(AdsManager.get_status())
	_append_log("Debug scene ready. Real-device tests: PENDING USER DEVICE TEST.")


func _on_initialize_pressed() -> void:
	_append_log("Initialize SDK requested.")
	AdsManager.initialize()


func _on_load_rewarded_pressed() -> void:
	_append_log("Load Rewarded requested.")
	AdsManager.load_rewarded()


func _on_show_rewarded_pressed() -> void:
	_append_log("Show Rewarded requested.")
	AdsManager.show_rewarded()


func _on_load_interstitial_pressed() -> void:
	_append_log("Load Interstitial requested.")
	AdsManager.load_interstitial()


func _on_show_interstitial_pressed() -> void:
	_append_log("Show Interstitial requested.")
	AdsManager.show_interstitial()


func _on_show_banner_pressed() -> void:
	_append_log("Show Banner requested.")
	AdsManager.show_banner()


func _on_hide_banner_pressed() -> void:
	_append_log("Hide Banner requested.")
	AdsManager.hide_banner()


func _on_clear_log_pressed() -> void:
	_log_lines.clear()
	log_output.text = ""


func _on_status_changed(status: Dictionary) -> void:
	platform_value.text = str(status.get("platform", "Unknown"))
	provider_value.text = str(status.get("provider", "Unavailable"))
	sdk_value.text = str(status.get("sdk", "Unknown"))
	rewarded_value.text = str(status.get("rewarded", "Unknown"))
	interstitial_value.text = str(status.get("interstitial", "Unknown"))
	banner_value.text = str(status.get("banner", "Unknown"))


func _on_sdk_initialized(success: bool, message: String) -> void:
	_append_log("SDK %s: %s" % ["READY" if success else "NOT READY", message])


func _on_ad_event(ad_type: String, event_name: String, message: String) -> void:
	_append_log("%s/%s: %s" % [ad_type, event_name, message])


func _on_reward_earned(reward_name: String, amount: int) -> void:
	_append_log("Reward earned: %s x%d" % [reward_name, amount])


func _append_log(message: String) -> void:
	_log_lines.append("[%s] %s" % [Time.get_time_string_from_system(), message])
	if _log_lines.size() > 80:
		_log_lines.pop_front()
	log_output.text = "\n".join(_log_lines)
	log_output.scroll_to_line(_log_lines.size())
