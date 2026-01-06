extends Control

@onready var settings_panel: Panel = $Settings
@onready var buttons_container: VBoxContainer = $VBoxContainer


func _ready() -> void:
	settings_panel.hide()
	
	
func _play() -> void:
	get_tree().change_scene_to_file("res://scenes/level/level_1.tscn")


func _settings() -> void:
	settings_panel.show()
	buttons_container.hide()


func _quit() -> void:
	get_tree().quit()


func _on_close_button() -> void:
	settings_panel.hide()
	buttons_container.show() 
