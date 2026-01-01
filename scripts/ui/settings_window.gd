extends Panel

signal closing

@onready var resolution_option: OptionButton = $OptionButton
@onready var fullscreen_toggle: CheckBox = $CheckBox
@onready var vsync_toggle: CheckBox = $CheckBox2
@onready var audio_slider: HSlider = $HSlider


func _ready() -> void:
	_sync_resolution()
	_sync_toggles()
	_sync_audio()

	
func _sync_resolution() -> void:
	var current_res: Vector2i = SettingsHandler.get_setting_value("resolution")
	var res_text: String = "%dx%d" % [current_res.x, current_res.y]
	
	for i in resolution_option.item_count:
		if resolution_option.get_item_text(i) == res_text:
			resolution_option.select(i)
			return

			
func _sync_toggles() -> void:
	fullscreen_toggle.button_pressed = SettingsHandler.get_setting_value("fullscreen")
	vsync_toggle.button_pressed = SettingsHandler.get_setting_value("vsync")


func _sync_audio() -> void:
	audio_slider.value = SettingsHandler.get_setting_value("volume")


func _on_apply_settings() -> void:
	var res_text: String = resolution_option.get_item_text(resolution_option.selected)
	var parts: PackedStringArray = res_text.split("x")

	if parts.size() != 2:
		push_error("Invalid resolution format")
		return

	var resolution := Vector2i(int(parts[0]), int(parts[1]))

	SettingsHandler.settings["resolution"] = resolution
	SettingsHandler.settings["fullscreen"] = fullscreen_toggle.button_pressed
	SettingsHandler.settings["vsync"] = vsync_toggle.button_pressed
	SettingsHandler.settings["volume"] = audio_slider.value

	SettingsHandler.apply_settings()
	SettingsHandler.save_settings()


func _on_close():
	closing.emit()
	self.hide()