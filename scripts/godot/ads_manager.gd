extends Node
## Platform-neutral advertisement boundary.
##
## Gameplay should depend on this autoload only. Android and iOS providers must
## expose the same normalized methods and signals through their Godot singleton.

signal sdk_initialized(success: bool, message: String)
signal ad_event(ad_type: String, event_name: String, message: String)
signal reward_earned(reward_name: String, amount: int)
signal status_changed(status: Dictionary)

const ANDROID_PLUGIN_NAME := "LevelPlayAds"
const IOS_PLUGIN_NAME := "LevelPlayAdsIOS"
const IOS_SHARED_PLUGIN_NAME := "LevelPlayAds"
const CONFIG_PATH := "res://config/levelplay_config.json"
const NORMALIZED_PLUGIN_METHODS := [
	"initialize",
	"loadRewarded",
	"showRewarded",
	"loadInterstitial",
	"showInterstitial",
	"showBanner",
	"hideBanner",
]

var _plugin: Object = null
var _config: Dictionary = {}
var _status: Dictionary = {
	"platform": "Unknown",
	"provider": "Unavailable",
	"sdk": "Not initialized",
	"rewarded": "Idle",
	"interstitial": "Idle",
	"banner": "Hidden",
}


func _ready() -> void:
	_status["platform"] = _platform_name()
	_resolve_plugin()
	_status["provider"] = _provider_name()
	_emit_status()


func initialize() -> void:
	_load_config()
	_resolve_plugin()

	if _plugin == null:
		_set_sdk_state("Unsupported", _unsupported_provider_message())
		return

	if not _plugin_has_normalized_api():
		_set_sdk_state("Unsupported", "%s does not expose the normalized LevelPlay API." % _provider_name())
		return

	var app_key := str(_config.get("app_key", "")).strip_edges()
	if app_key.is_empty() or app_key.begins_with("REPLACE_WITH"):
		_set_sdk_state("Configuration required", _configuration_required_message())
		return

	_set_sdk_state("Initializing", "Calling Unity LevelPlay initialization.")
	_plugin.initialize(
		app_key,
		str(_config.get("rewarded_ad_unit_id", "")),
		str(_config.get("interstitial_ad_unit_id", "")),
		str(_config.get("banner_ad_unit_id", "")),
		bool(_config.get("enable_test_suite", false)),
		str(_config.get("banner_placement", "")),
	)


func load_rewarded() -> void:
	if not _ensure_provider("rewarded", "load"):
		return
	_status["rewarded"] = "Loading"
	_emit_status()
	_plugin.loadRewarded()


func show_rewarded(placement_name: String = "") -> void:
	if not _ensure_provider("rewarded", "show"):
		return
	_plugin.showRewarded(placement_name)


func load_interstitial() -> void:
	if not _ensure_provider("interstitial", "load"):
		return
	_status["interstitial"] = "Loading"
	_emit_status()
	_plugin.loadInterstitial()


func show_interstitial(placement_name: String = "") -> void:
	if not _ensure_provider("interstitial", "show"):
		return
	_plugin.showInterstitial(placement_name)


func show_banner() -> void:
	if not _ensure_provider("banner", "show"):
		return
	_status["banner"] = "Loading"
	_emit_status()
	_plugin.showBanner()


func hide_banner() -> void:
	if not _ensure_provider("banner", "hide"):
		return
	_plugin.hideBanner()
	_status["banner"] = "Hidden"
	_emit_status()


func get_status() -> Dictionary:
	return _status.duplicate(true)


func _resolve_plugin() -> void:
	if _plugin != null:
		return

	if OS.has_feature("android"):
		_try_resolve_plugin(ANDROID_PLUGIN_NAME)
	elif OS.has_feature("ios"):
		# Prefer an explicitly platform-named iOS plugin, while accepting the
		# shared singleton name used by plugins that register per platform.
		_try_resolve_plugin(IOS_PLUGIN_NAME)
		if _plugin == null:
			_try_resolve_plugin(IOS_SHARED_PLUGIN_NAME)


func _try_resolve_plugin(plugin_name: String) -> void:
	if _plugin != null or not Engine.has_singleton(plugin_name):
		return
	_plugin = Engine.get_singleton(plugin_name)
	_connect_plugin_signals()


func _connect_plugin_signals() -> void:
	if _plugin == null:
		return
	if _plugin.has_signal("sdk_initialized") and not _plugin.sdk_initialized.is_connected(_on_plugin_sdk_initialized):
		_plugin.sdk_initialized.connect(_on_plugin_sdk_initialized)
	if _plugin.has_signal("ad_event") and not _plugin.ad_event.is_connected(_on_plugin_ad_event):
		_plugin.ad_event.connect(_on_plugin_ad_event)
	if _plugin.has_signal("reward_earned") and not _plugin.reward_earned.is_connected(_on_plugin_reward_earned):
		_plugin.reward_earned.connect(_on_plugin_reward_earned)


func _load_config() -> void:
	_config = {}
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return

	var platform_key := _platform_config_key()
	var platform_config = parsed.get(platform_key, null)
	if platform_config is Dictionary:
		_config = platform_config.duplicate(true)


func _ensure_provider(ad_type: String, operation: String) -> bool:
	_resolve_plugin()
	if _plugin != null and _plugin_has_normalized_api() and str(_status.get("sdk", "")) == "Ready":
		return true
	_emit_ad_event(ad_type, "not_ready", "Cannot %s before SDK initialization succeeds." % operation)
	return false


func _plugin_has_normalized_api() -> bool:
	if _plugin == null:
		return false
	for method_name in NORMALIZED_PLUGIN_METHODS:
		if not _plugin_exposes_method(method_name):
			return false
	return true


func _plugin_exposes_method(method_name: String) -> bool:
	if _plugin.has_method(method_name):
		return true
	if _plugin.has_method("has_java_method"):
		return _plugin.has_java_method(method_name)
	return false


func _on_plugin_sdk_initialized(success: bool, message: String) -> void:
	_set_sdk_state("Ready" if success else "Failed", message)
	if success:
		_status["rewarded"] = "Idle"
		_status["interstitial"] = "Idle"
		_status["banner"] = "Hidden"
	_emit_status()


func _on_plugin_ad_event(ad_type: String, event_name: String, message: String) -> void:
	var state_by_event := {
		"loading": "Loading",
		"loaded": "Ready",
		"displayed": "Showing",
		"closed": "Idle",
		"hidden": "Hidden",
		"failed": "Failed",
		"show_failed": "Show failed",
	}
	if _status.has(ad_type) and state_by_event.has(event_name):
		_status[ad_type] = state_by_event[event_name]
	_emit_status()
	_emit_ad_event(ad_type, event_name, message)


func _on_plugin_reward_earned(reward_name: String, amount: int) -> void:
	reward_earned.emit(reward_name, amount)
	_emit_ad_event("rewarded", "reward_earned", "%s %d" % [reward_name, amount])


func _set_sdk_state(state: String, message: String) -> void:
	_status["sdk"] = state
	_emit_status()
	if state in ["Ready", "Failed", "Unsupported", "Configuration required"]:
		sdk_initialized.emit(state == "Ready", message)
	if state != "Ready":
		_emit_ad_event("sdk", "state", message)


func _emit_ad_event(ad_type: String, event_name: String, message: String) -> void:
	ad_event.emit(ad_type, event_name, message)


func _emit_status() -> void:
	status_changed.emit(get_status())


func _platform_config_key() -> String:
	if OS.has_feature("android"):
		return "android"
	if OS.has_feature("ios"):
		return "ios"
	return ""


func _provider_name() -> String:
	if OS.has_feature("android"):
		return "Unity LevelPlay"
	if OS.has_feature("ios"):
		return "Unity LevelPlay (iOS)"
	return "Desktop fallback"


func _unsupported_provider_message() -> String:
	if OS.has_feature("android"):
		return "Android LevelPlay plugin is not available on this platform."
	if OS.has_feature("ios"):
		return "iOS LevelPlay plugin is not available in this export."
	return "LevelPlay ads are unsupported on this platform."


func _configuration_required_message() -> String:
	if OS.has_feature("ios"):
		return "Add a real iOS LevelPlay app key under the ios section in config/levelplay_config.json."
	return "Add a real Android LevelPlay app key under the android section in config/levelplay_config.json."


func _platform_name() -> String:
	if OS.has_feature("android"):
		return "Android"
	if OS.has_feature("ios"):
		return "iOS"
	if OS.has_feature("windows"):
		return "Windows"
	if OS.has_feature("macos"):
		return "macOS"
	if OS.has_feature("linux"):
		return "Linux"
	return "Unknown"
