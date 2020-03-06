extends Spatial

onready var players := $Players
onready var spectator_camera := $SpectatorCamera

func _ready():
	spectator_camera.current = get_tree().is_network_server()
	
	if not get_tree().is_network_server():
		spawn_player(get_tree().get_network_unique_id())
	
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")


func _unhandled_input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_11:
			get_tree().quit()


func _on_network_peer_connected(id):
	if id != 1:
		spawn_player(id)


func _on_network_peer_disconnected(id):
	if players.has_node(str(id)):
		players.get_node(str(id)).queue_free()


func _on_Player_tree_exited(player):
	if player.is_me:
		spectator_camera.make_current()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func spawn_player(player_id : int) -> void:
	var new_player = preload("res://Player/Player.tscn").instance()
	new_player.name = str(player_id)
	new_player.network_id = player_id
	players.add_child(new_player)
	new_player.connect("tree_exited", self, "_on_Player_tree_exited", [new_player])
