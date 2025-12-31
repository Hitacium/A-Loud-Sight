class_name Player
extends CharacterBody3D

@onready var head := $head
@onready var plrGUI := $PlayerGUI
@onready var InteractRaycast := $head/RayCast3D
@onready var camera := $head/Camera3D
@onready var SPEED: int = DEFAULT_SPEED

@export var DEFAULT_SPEED := 3
@export var mouse_sensitivity := 0.1

var inputEnabled := true
var aimlookEnabled := true

func _ready():
	$MeshInstance3D.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.player = self

func _physics_process(delta: float) -> void:
	if !inputEnabled:
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED) 
	
	move_and_slide()
	
func _unhandled_input(event : InputEvent) -> void:
	if !aimlookEnabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouseInput : Vector2
		mouseInput.x += event.relative.x
		mouseInput.y += event.relative.y
		self.rotation_degrees.y -= mouseInput.x * mouse_sensitivity
		head.rotation_degrees.x -= mouseInput.y * mouse_sensitivity