extends ConnectionScreen

var lobby_type_dropdown : OptionButton

func _ready():
	super()

func _on_host_pressed():
	gamestate.attempt_host_game(lobby_type_dropdown.selected as Steam.LobbyType)
	await gamestate.steam_lobby_creation_finished # Wait for the lobby to be created
	multiplayer_game_hosted.emit()

func _on_join_pressed():
	Steam.activateGameOverlay("Friends")
