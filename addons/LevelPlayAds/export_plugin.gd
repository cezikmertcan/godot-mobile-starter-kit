@tool
extends EditorPlugin

var export_plugin: AndroidExportPlugin


func _enter_tree() -> void:
	export_plugin = AndroidExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	if export_plugin != null:
		remove_export_plugin(export_plugin)
		export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	const PLUGIN_NAME := "LevelPlayAds"
	const LEVELPLAY_VERSION := "9.5.0"


	func _supports_platform(platform) -> bool:
		return platform is EditorExportPlatformAndroid


	func _get_android_libraries(platform, debug: bool) -> PackedStringArray:
		var variant := "debug" if debug else "release"
		return PackedStringArray([
			PLUGIN_NAME + "/bin/" + variant + "/" + PLUGIN_NAME + "-" + variant + ".aar",
		])


	func _get_android_dependencies(platform, debug: bool) -> PackedStringArray:
		return PackedStringArray([
			"com.unity3d.ads-mediation:mediation-sdk:" + LEVELPLAY_VERSION,
			"com.unity3d.ads-mediation:unityads-adapter:5.11.0",
			"com.unity3d.ads:unity-ads:4.19.0",
			"com.google.android.gms:play-services-appset:16.0.0",
			"com.google.android.gms:play-services-ads-identifier:18.1.0",
			"com.google.android.gms:play-services-basement:18.1.0",
		])


	func _get_name() -> String:
		return PLUGIN_NAME
