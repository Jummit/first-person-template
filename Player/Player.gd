extends KinematicBody

onready var camera := $Camera
onready var animation_player := $AnimationPlayer
onready var walk_player := $WalkPlayer
onready var jump_player := $JumpPlayer
onready var crosshair := $Crosshair

var is_me := true
var network_id := -1
var connected_to_server := false
var vertical_velocity := 0.0
var sneaking := false setget set_sneaking

const GRAVITY := 0.2
const JUMP_FORCE := 4.0
const MOVEMENT_SPEED := 0.1
const SPRINTING_MULTIPLIER := 1.2
const MOUSE_SENSITIVITY := 600.0

func _ready():
	is_me = network_id == get_tree().get_network_unique_id()
	
	if is_me:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		walk_player.play()
	
	camera.current = is_me
	crosshair.visible = is_me
	
	set_process_input(is_me)
	set_physics_process(is_me)
	
	rset_config("translation", MultiplayerAPI.RPC_MODE_REMOTE)
	rset_config("rotation", MultiplayerAPI.RPC_MODE_REMOTE)
	
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")


func _physics_process(_delta):
	var movement_input := get_movement_input()
	move_and_collide(movement_input.rotated(Vector3.UP, rotation.y) * get_movement_speed_multiplier())
	
	if is_on_floor():
		vertical_velocity = -1
	else:
		vertical_velocity -= GRAVITY
	
	if is_on_floor() and Input.is_action_pressed("jump"):
		vertical_velocity = JUMP_FORCE
		jump_player.play()
	
	move_and_slide(Vector3.UP * vertical_velocity, Vector3.UP)
	
	walk_player.stream_paused = movement_input.length() == 0 or not is_on_floor()
	
	self.sneaking = Input.is_action_pressed("sneak")
	
	replicate("translation")


func _input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_y(-event.relative.x / MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y / MOUSE_SENSITIVITY)
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80, 90)
		
		replicate("rotation")


func _on_connected_to_server():
	connected_to_server = true


func set_sneaking(to):
	if sneaking != to:
		$SneakPlayer.play()
		animation_player.play("Sneak" if to else "UnSneak")
		sneaking = to


func get_movement_input() -> Vector3:
	var movement := Vector3()
	movement.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	movement.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	return movement


func get_movement_speed_multiplier() -> float:
	return MOVEMENT_SPEED * (SPRINTING_MULTIPLIER if Input.is_action_pressed("sprint") else 1.0)


func replicate(property : String) -> void:
	if connected_to_server:
		rset_unreliable(property, get(property))
