extends KinematicBody

onready var camera_socket := $CameraSocket
onready var camera := $CameraSocket/Camera
onready var animation_player := $AnimationPlayer
onready var walk_player := $WalkPlayer
onready var sprint_player := $SprintPlayer
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
	
	camera.current = is_me
	crosshair.visible = is_me
	
	set_process_input(is_me)
	set_physics_process(is_me)
	
	rset_config("translation", MultiplayerAPI.RPC_MODE_REMOTE)
	rset_config("rotation", MultiplayerAPI.RPC_MODE_REMOTE)
	
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")


func _physics_process(_delta):
	var movement_input := get_movement_input() * get_movement_speed_multiplier()
	move_and_collide(movement_input.rotated(Vector3.UP, rotation.y))
	
	if is_on_floor() and Input.is_action_pressed("jump"):
		vertical_velocity = JUMP_FORCE
		jump_player.play()
	else:
		vertical_velocity -= GRAVITY
	move_and_slide(Vector3.UP * vertical_velocity, Vector3.UP)
	
	
	var sprint_pressed := Input.is_action_pressed("sprint")
	var moving = Vector3(movement_input.x, 0, movement_input.z).length() > 0 and is_on_floor()
	var walking = moving and not sprint_pressed
	var sprinting = moving and sprint_pressed
	if not moving:
		walk_player.stop()
		sprint_player.stop()
	elif walking and not walk_player.playing:
		walk_player.play()
	elif sprinting and not sprint_player.playing:
		sprint_player.play()
	
	set_sneaking(Input.is_action_pressed("sneak"))
	
	if connected_to_server:
		rset_unreliable("translation", translation)


func _input(event):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_y(-event.relative.x / MOUSE_SENSITIVITY)
		camera_socket.rotate_x(-event.relative.y / MOUSE_SENSITIVITY)
		camera_socket.rotation_degrees.x = clamp(camera_socket.rotation_degrees.x, -60, 60)
		if connected_to_server:
			rset_unreliable("rotation", rotation)


func _on_connected_to_server():
	connected_to_server = true


func set_sneaking(to):
	if sneaking != to:
		$SneakPlayer.play()
		animation_player.play("Sneak" if to else "UnSneak")
		sneaking = to


func get_movement_input() -> Vector3:
	var movement = Vector3()
	
	if Input.is_action_pressed("move_forward"):
		movement.z = -1
	if Input.is_action_pressed("move_back"):
		movement.z = 1
	if Input.is_action_pressed("move_right"):
		movement.x = 1
	if Input.is_action_pressed("move_left"):
		movement.x = -1
	
	return movement


func get_movement_speed_multiplier() -> float:
	return MOVEMENT_SPEED * (SPRINTING_MULTIPLIER if Input.is_action_pressed("sprint") else 1.0)
