extends Node

var this_platform := "itch" 
var steam_api : Object = null
var startupargs := OS.get_cmdline_args()
var joined_lobby_on_boot = null

const STEAM_APP_ID := 480 #Don't set this to the correct value until the game is released.

func _ready() -> void:
	pass

func is_steam_powered() -> bool:
	if this_platform == "steam" && steam_api != null:
		return true
	return false

func determine_platform() -> void:
	if Engine.has_singleton("Steam"):
		this_platform = "steam"
	else:
		this_platform = "itch"

func check_steam_command_line_arguments():
	# There are arguments to process
	# A Steam connection argument exists
	# Lobby invite exists so try to connect to it
	if startupargs.size() > 0 and startupargs[0] == "+connect_lobby" and int(startupargs[1]) > 0: # There are arguments to process
		print("Command line lobby ID: %s" % startupargs[1])
		gamestate.join_steam_lobby_on_startup(int(startupargs[1])) 
		joined_lobby_on_boot = int(startupargs[1])
		
func initialize_steam() -> void:
	if this_platform == "steam":
		steam_api = Engine.get_singleton("Steam")
		var initialize_response: Dictionary = steam_api.steamInitEx(STEAM_APP_ID, true)
		
		if initialize_response['status'] > steam_api.STEAM_API_INIT_RESULT_OK:
			printerr("Failed to initialize Steam, shutting down: %s" % initialize_response)
			# Show some kind of prompt so the game doesn't suddently stop working
			#TODO Write warning prompt
			get_tree().quit() #Or just blow up the game instead.
			
	else:
		steam_api = null
