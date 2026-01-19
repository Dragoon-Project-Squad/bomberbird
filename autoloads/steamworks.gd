extends Node

var game_is_steam_powered : bool = false #Enables ALL Steam content.
var startupargs := OS.get_cmdline_args()
var joined_lobby_on_boot = null

const STEAM_APP_ID := 480 #Don't set this to the correct value until the game is released.

func _ready() -> void:
	pass
	#check_steam_powered()

func check_steam_powered():
	if Engine.has_singleton("Steam"):
		game_is_steam_powered = true

func check_steam_command_line_arguments():
	# There are arguments to process
	# A Steam connection argument exists
	# Lobby invite exists so try to connect to it
	if startupargs.size() > 0 and startupargs[0] == "+connect_lobby" and int(startupargs[1]) > 0: # There are arguments to process
		print("Command line lobby ID: %s" % startupargs[1])
		gamestate.join_steam_lobby_on_startup(int(startupargs[1])) 
		joined_lobby_on_boot = int(startupargs[1])
		
func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(STEAM_APP_ID, true)
	print("Did Steam initialize?: %s " % initialize_response)

	if initialize_response['status'] > Steam.STEAM_API_INIT_RESULT_OK:
		printerr("Failed to initialize Steam, shutting down: %s" % initialize_response)
		# Show some kind of prompt so the game doesn't suddently stop working
		#show_warning_prompt()
		get_tree().quit() #Or just blow up the game instead.
