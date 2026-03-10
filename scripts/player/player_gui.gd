extends CanvasLayer


@onready var debuginfo: Label = $DebugInfoLabel
const DEBUG_TEMPLATE: String = "PlayerState: {plrstate}\n
PlayerSpeed: {speed}\n
Global Coordinates (X/Y/Z): {globalpos}\n
FPS: {fps}\n"

@export var stopwatch_label : Label

var stopwatch : Stopwatch

func _ready():
	stopwatch = get_tree().get_first_node_in_group("stopwatch")
	assert(stopwatch)
	
func _process(_delta: float) -> void:
	update_stopwatch_label()
	
func update_stopwatch_label():
	stopwatch_label.text = stopwatch.time_to_string()

func _input(event) -> void:
	if event.is_action_pressed("debug"):
		debuginfo.visible = !debuginfo.visible
		debugLoop()

func debugLoop():
	while debuginfo.visible:
		debuginfo.text = DEBUG_TEMPLATE.format({
			"plrstate": GameManager.player.currentState,
			"speed": GameManager.player.player_speed,
			"globalpos": GameManager.player.global_position,
			"fps": Engine.get_frames_per_second(),
		})
		await get_tree().create_timer(.5).timeout
