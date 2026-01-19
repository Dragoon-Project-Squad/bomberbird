extends ConnectionScreen

@onready var lobby_type_dropdown: OptionButton = $VBoxContainer/HostContainer/HBoxContainer/LobbyTypeDropdown

func _ready():
	super()
	check_joined_on_boot()
	
func check_joined_on_boot():
	if SteamManager.joined_lobby_on_boot != null:
		gamestate.join_steam_lobby(SteamManager.joined_lobby_on_boot)
		
func _on_host_pressed():
	gamestate.attempt_host_steam_game(lobby_type_dropdown.selected as Steam.LobbyType)
	await gamestate.steam_lobby_creation_finished # Wait for the lobby to be created
	multiplayer_game_hosted.emit()

func _on_join_pressed():
	Steam.activateGameOverlay("Friends")
