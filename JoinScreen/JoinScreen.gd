extends Control

const SERVER_PORT := 8000
const MAX_PLAYERS := 5
const SERVER_IP := "127.0.0.1"

func _on_JoinButton_pressed():
	var peer := NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	start_with_peer(peer)


func _on_CreateServerButton_pressed():
	var peer := NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	start_with_peer(peer)


func start_with_peer(peer : NetworkedMultiplayerPeer) -> void:
	get_tree().set_network_peer(peer)
	get_tree().change_scene("res://Game/Game.tscn")
