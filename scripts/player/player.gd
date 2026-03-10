class_name Player
extends CharacterBody3D

@export var default_speed := 3
@export var mouse_sensitivity := 0.1
var input_enabled := true
var aimlook_enabled := true

@onready var head := $head
@onready var player_gui := $PlayerGUI
@onready var camera := $head/Camera3D
@onready var player_speed: int = default_speed
var wall_hit_count = 0
var previous_wall_hit = false

func _ready():
	$CollisionShape3D/MeshInstance3D.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.player = self


func _unhandled_input(event : InputEvent) -> void:
	if not aimlook_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouseInput : Vector2
		mouseInput.x += event.relative.x
		mouseInput.y += event.relative.y
		self.rotation_degrees.y -= mouseInput.x * mouse_sensitivity
		head.rotation_degrees.x -= mouseInput.y * mouse_sensitivity


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

	move_and_slide()
	check_wall()	

func check_wall():
	if is_on_wall():
		if not previous_wall_hit:
			wall_hit_count += 1
			previous_wall_hit = true
	else:
		if previous_wall_hit:
			previous_wall_hit = false
			
func _on_switch_level_2_body_entered(body: Node3D) -> void:
	if body == $".":
		call_deferred("_go_to_level_2")
		
func _go_to_level_2():
	get_tree().change_scene_to_file("res://scenes/level/level_2.tscn")

func _on_switch_level_3_body_entered(body: Node3D) -> void:
	if body == $".":
		call_deferred("_go_to_level_3")

func _go_to_level_3() -> void:
	get_tree().change_scene_to_file("res://scenes/level/level_3.tscn")

func _on_the_end_body_entered(_body: Node3D) -> void:
	get_tree().quit()
