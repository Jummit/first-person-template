extends Spatial

onready var players := $Players
onready var server_camera := $ServerCamera

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	
	server_camera.current = get_tree().is_network_server()
	if not get_tree().is_network_server():
		create_player(get_tree().get_network_unique_id())


func _unhandled_input(event):
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
	if event is InputEventJoypadButton:
		if event.button_index == JOY_BUTTON_11:
			get_tree().quit()


func _on_network_peer_connected(id):
	if id != 1:
		create_player(id)


func _on_network_peer_disconnected(id):
	if players.has_node(str(id)):
		players.get_node(str(id)).queue_free()


func create_player(id : int):
	var new_player = preload("res://Player/Player.tscn").instance()
	new_player.name = str(id)
	new_player.network_id = id
	players.add_child(new_player)
