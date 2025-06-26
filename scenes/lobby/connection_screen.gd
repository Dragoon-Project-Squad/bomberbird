extends PanelContainer

var timeout_timer = null
signal multiplayer_game_hosted
signal multiplayer_game_joined

@export var lobby_type_dropdown : OptionButton

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.connection_succeeded.connect(_on_connection_success)

	# Connection timeout timer
	timeout_timer = Timer.new()
	timeout_timer.name = "ConnectionTimeout"
	timeout_timer.wait_time = 5.0
	timeout_timer.one_shot = true
	timeout_timer.connect("timeout", Callable(self, "_on_connection_timeout"))
	add_child(timeout_timer)


func _on_host_pressed():
	gamestate.host_game(lobby_type_dropdown.selected as Steam.LobbyType)
	
	await gamestate.lobby_created # Wait for the lobby to be created
	multiplayer_game_hosted.emit()
	#get_tree().change_scene_to_file("res://scenes/cssmenu/character_select_screen.tscn")

func _on_join_pressed():
	Steam.activateGameOverlay("Friends")
	#$Host.disabled = true
	#$Join.disabled = true

	#var player_name = $Name.text
	#globals.config.set_player_name(player_name)
	#timeout_timer.start()
	#gamestate.join_game(ip, player_name)
	

func _on_connection_timeout():
	if gamestate.peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		multiplayer.multiplayer_peer = null  # Reset the multiplayer peer
		$Host.disabled = false
		$Join.disabled = false
		$Join.release_focus()
		$ErrorLabel.text = "Connection timed out"

func _on_connection_success():
	multiplayer_game_joined.emit()
	#get_tree().change_scene_to_file("res://scenes/cssmenu/character_select_screen.tscn")


func _on_connection_failed():
	$Host.disabled = false
	$Join.disabled = false
	$ErrorLabel.set_text("Connection failed.")
