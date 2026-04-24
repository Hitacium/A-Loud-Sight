class_name Player
extends CharacterBody3D

@export var default_speed := 3
@export var mouse_sensitivity := 0.1
@export var gamepad_sensitivity := 1.5
@export var gamepad_deadzone := 0.15

var input_enabled := true
var aimlook_enabled := true



@onready var head := $head
@onready var player_gui := $PlayerGUI
@onready var camera := $head/Camera3D
@onready var wall_bonk := $head/WallBonk
@onready var player_speed: int = default_speed
var wall_hit_count = 0
var previous_wall_hit = false

func _ready():
	$CollisionShape3D/MeshInstance3D.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.player = self


func _unhandled_input(event: InputEvent) -> void:
	if not aimlook_enabled:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouseInput: Vector2
		mouseInput.x = event.relative.x * mouse_sensitivity
		mouseInput.y = event.relative.y * mouse_sensitivity
		
		rotation_degrees.y -= mouseInput.x
		head.rotation_degrees.x -= mouseInput.y
		
		# Limite du pitch camera
		head.rotation_degrees.x = clamp(head.rotation_degrees.x, -80, 80)


func _physics_process(delta: float) -> void:
	if not input_enabled:
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * player_speed
		velocity.z = direction.z * player_speed
	else:
		velocity.x = move_toward(velocity.x, 0, player_speed)
		velocity.z = move_toward(velocity.z, 0, player_speed)

	if aimlook_enabled:
		_handle_gamepad_look(delta)

	move_and_slide()
	check_wall()	

func _handle_gamepad_look(delta: float) -> void:
	var stick := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	
	if stick.length() < gamepad_deadzone:
		return
		
	# Remap to start movement only past deadzone
	stick = (stick - stick.normalized() * gamepad_deadzone) / (1.0 - gamepad_deadzone)
	
	rotation_degrees.y -= stick.x * gamepad_sensitivity * delta * 100.0
	head.rotation_degrees.x -= stick.y * gamepad_sensitivity * delta * 100.0
	
	# Limite du pitch camera
	head.rotation_degrees.x = clamp(head.rotation_degrees.x, -80, 80)

func check_wall():
	if is_on_wall():
		if not previous_wall_hit:
			wall_hit_count += 1
			# start_joy_vibration(device, weak_magnitude, strong_magnitude, duration)
			Input.start_joy_vibration(0, 1, 0, 0.3)
			wall_bonk.play()
			previous_wall_hit = true
	else:
		if previous_wall_hit:
			previous_wall_hit = false
		
func save_level(level_name: String):
	var stopwatch = get_tree().get_first_node_in_group("stopwatch")
	stopwatch.stop()
	var time = stopwatch.get_time_seconds()
	ExperimentManager.add_level_data(level_name, wall_hit_count, time)

func _on_switch_level_2_body_entered(body: Node3D) -> void:
	if body == $".":
		save_level("level1")
		call_deferred("_go_to_level_2")
		
func _go_to_level_2():
	get_tree().change_scene_to_file("res://scenes/level/level_2.tscn")

func _on_switch_level_3_body_entered(body: Node3D) -> void:
	if body == $".":
		save_level("level2")
		call_deferred("_go_to_level_3")

func _go_to_level_3() -> void:
	get_tree().change_scene_to_file("res://scenes/level/level_3.tscn")

func _on_the_end_body_entered(_body: Node3D) -> void:
	save_level("level3")
	ExperimentManager.save_to_file()
	get_tree().quit()
