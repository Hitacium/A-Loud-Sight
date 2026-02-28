extends Node

const SETTINGS_FILE_PATH := "user://settings.json"
const DEFAULT_SETTINGS := {
	"resolution": Vector2i(1920, 1080),
	"vsync": true,
	"fullscreen": false,
	"volume": 1.0
}

var settings: Dictionary = {}


func _ready():
	load_settings()
	apply_settings()


func get_setting_value(key: String) -> Variant:
	return settings.get(key, DEFAULT_SETTINGS.get(key))
	
	
func apply_settings() -> void:
	var resolution: Vector2i = get_setting_value("resolution")

	if get_setting_value("fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Center window only if windowed
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(resolution)
	
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var window_pos: Vector2i = (screen_size - resolution) / 2
		DisplayServer.window_set_position(window_pos)

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED
		if get_setting_value("vsync")
		else DisplayServer.VSYNC_DISABLED
	)

	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(
		bus,
		linear_to_db(get_setting_value("volume"))
	)


func save_settings() -> void:
	var to_save: Dictionary = settings.duplicate(true)

	# Convert Vector2i to array for JSON
	if "resolution" in to_save and typeof(to_save["resolution"]) == TYPE_VECTOR2I:
		var r: Vector2i = to_save["resolution"]
		to_save["resolution"] = [r.x, r.y]

	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(to_save))
		file.close()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		settings = DEFAULT_SETTINGS.duplicate(true)
		save_settings()
		return

	var file := FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		settings = DEFAULT_SETTINGS.duplicate(true)
	else:
		settings = DEFAULT_SETTINGS.duplicate(true)
		settings.merge(data as Dictionary, true)

	# Convert resolution back to Vector2i
	if "resolution" in settings and typeof(settings["resolution"]) == TYPE_ARRAY:
		var arr: Array = settings["resolution"]
		if arr.size() == 2:
			settings["resolution"] = Vector2i(arr[0], arr[1])


func get_resolution_as_str() -> String:
	var r: Vector2i = get_setting_value("resolution")
	return "%dx%d" % [r.x, r.y]
