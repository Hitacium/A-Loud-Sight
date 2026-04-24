extends Control
@onready var settings_panel: Panel = $Settings
@onready var main_panel: Control = $Main

func _ready() -> void:
	settings_panel.closing.connect(_on_close_button)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_action_pressed("ui_cancel"):
		if settings_panel.visible:
			settings_panel._on_close()
			return
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_tree().paused = true
				self.show()
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				get_tree().paused = false
				self.hide()

func _unpause() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false
	self.hide()

func _settings() -> void:
	main_panel.hide()
	settings_panel.show()

func _quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _actually_quit() -> void:
	get_tree().quit()

func _on_close_button() -> void:
	settings_panel.hide()
	main_panel.show()
	self.show()
