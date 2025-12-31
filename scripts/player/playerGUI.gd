extends CanvasLayer

@onready var debuginfo: Label = $DebugInfoLabel
const DEBUG_TEMPLATE: String = "PlayerState: {plrstate}\nPlayerSpeed: {speed}\nGlobal Coordinates (X/Y/Z): {globalpos}\nFPS: {fps}"

func _input(event) -> void:
	if event.is_action_pressed("debug"):
		debuginfo.visible = !debuginfo.visible
		debugLoop()

func debugLoop():
	while debuginfo.visible:
		debuginfo.text = DEBUG_TEMPLATE.format({
			"plrstate": GameManager.player.currentState,
			"speed": GameManager.player.SPEED,
			"globalpos": GameManager.player.global_position,
			"fps": Engine.get_frames_per_second()
		})
		await get_tree().create_timer(.5).timeout