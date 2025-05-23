extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT := 10567
var is_game_online := true 
#TODO: Create VSCOM option, then set this to false and enable ONLY if Online

# Multiplayer vars
const MAX_PEERS := 4
var peer = null

#Environmental damage vars
const ENVIRONMENTAL_KILL_PLAYER_ID := -69

# Player count variables
var total_player_count := 1
var human_player_count := 1 #Every game must have at least 1 human or two AI

# Name for my player.
var player_name = globals.config.get_player_name()
# Names for remote players in id:name format.
var players = {}
var players_ready = []

# Player Numbers in string:id format.
var player_numbers = {
	"p1": 1,
	"p2": -2,
	"p3": -3,
	"p4": -4
}

# Character Textures in id:texture2D format.
var characters = {}
const DEFAULT_PLAYER_TEXTURE_PATH = "res://assets/player/chonkgoon_walk.png"

# AI Handling variables
const MAX_ID_COLLISION_RESCUE_ATTEMPTS = 4
const MAX_NAME_COLLISION_RESCUE_ATTEMPTS = 4

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Preloaded Scenes
var campaign_game_scene: String = "res://scenes/campaign_game.tscn"
var battlemode_game_scene: String = "res://scenes/battlemode_game.tscn"

# Singleplayer Vars
var current_level: int = 1 #205 # Defaults to a high number for battle mode.

# Battle Mode vars

# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name)

# Callback from SceneTree.
func _player_disconnected(id):
	total_player_count -= 1
	human_player_count -= 1
	if globals.current_world != null: # Game is in progress.
		# Remove from world
		remove_player_from_world.rpc(id)
		# If everyone else disconnected
		if total_player_count == 1:
			game_error.emit("All other players disconnected")
			end_game()
	# Unregister this player.
	unregister_player(id)

# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	connection_succeeded.emit()


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	# Gets called by the server if all players disconnect, this is to prevent that
	game_error.emit("Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	multiplayer.set_multiplayer_peer(null) # Remove peer
	connection_failed.emit()

# Lobby management functions.
@rpc("any_peer")
func register_player(new_player_name):
	var id = multiplayer.get_remote_sender_id()
	characters[id] = DEFAULT_PLAYER_TEXTURE_PATH
	players[id] = new_player_name
	player_list_changed.emit()
	
func unregister_player(id):
	players.erase(id)
	player_list_changed.emit()

@rpc("authority", "call_local")
func remove_player_from_world(id):
	if globals.current_world != null:
		if globals.current_world.has_node("Players/" + str(id)):
			globals.current_world.get_node("Players/" + str(id)).queue_free()
	
@rpc("any_peer", "call_local")
func change_character_player(texture_path : String):
	print(
		"Changing ID ", 
		multiplayer.get_remote_sender_id(), 
		"'s character model to ", 
		texture_path
	)
	var id = multiplayer.get_remote_sender_id()
	if id == 0:
		id = 1
	characters[id] = texture_path


func assign_player_numbers():
	var players_assigned = 1 #If this hits 4, we kill the loop as a sanity check.
	for p in players:
		match players_assigned:
			1:
				player_numbers.p2 = p
			2:
				player_numbers.p3 = p
			3:
				player_numbers.p4 = p
			4:
				push_warning("4 players assigned, but the loop wanted to continue. Terminating...")	
				return
			5:
				push_error("More than 4 players detected! Are you sure this is correct!?")
				return
			_:
				push_error("More than 4 players detected! Are you sure this is correct!?")
				return
		players_assigned += 1
		print("Player ", players_assigned, " assigned to ID number: ", p)


func establish_player_counts() -> void:
	human_player_count = 1 + players.size()
	assert(multiplayer.is_server())
	total_player_count = min(4, human_player_count + SettingsContainer.get_cpu_count())
	add_ai_players() #Depends on knowing the total player count and human player count to do its job
	
@rpc("call_local")
func load_world(game_scene):
	# Change scene.
	var game = load(game_scene).instantiate()
	get_tree().get_root().add_child(game)
	if has_node("/root/MainMenu/DebugCampaignSelector"):
		game.load_level_graph(get_node("/root/MainMenu/DebugCampaignSelector").get_graph())
	game.start()
	if get_tree().get_root().has_node("Lobby"):
		get_tree().get_root().get_node("Lobby").hide()
	else:
		get_node("/root/MainMenu").pause_main_menu_music()


	# Set up score.
	if is_multiplayer_authority():
		game.game_ui.add_player.rpc(multiplayer.get_unique_id(), player_name)
		for pn in players:
			game.game_ui.add_player.rpc(pn, players[pn])

	# Unpause and unleash the game!
	get_tree().set_pause(false) 

func host_game(new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.set_multiplayer_peer(peer)
	characters[1] = DEFAULT_PLAYER_TEXTURE_PATH


func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)


func get_player_list():
	return players.values()


func get_player_name():
	return player_name

func begin_singleplayer_game():
	globals.current_gamemode = globals.gamemode.CAMPAIGN
	SettingsContainer.misobon_setting = SettingsContainer.misobon_setting_states.OFF
	human_player_count = 1
	total_player_count = human_player_count
	if total_player_count > 1:
		add_ai_players()

	characters[1] = DEFAULT_PLAYER_TEXTURE_PATH

	load_world.rpc(campaign_game_scene)

func begin_game():
	globals.current_gamemode = globals.gamemode.BATTLEMODE
	current_level = 205
	if players.size() == 0: # If players disconnected at character select
		game_error.emit("All other players disconnected")
		end_game()
	load_world.rpc(battlemode_game_scene)
	
func add_ai_players():
	var ai_player_count = total_player_count - human_player_count
	print("total player count: ", total_player_count, " human player count: ", human_player_count)
	if ai_player_count <= 0: # No robots allowed
		print("No robots allowed")
		pass
	for n in range(0, ai_player_count, 1):
		register_ai_player()
	pass

func register_ai_player():
	var id = 2 #TODO: Generate CPU ID here, ensure it does not clash
	if not is_id_free(id):
		for i in range(2, 2+MAX_ID_COLLISION_RESCUE_ATTEMPTS, 1):
			id = i
			if is_id_free(id):
				break
	characters[id] = DEFAULT_PLAYER_TEXTURE_PATH
	player_list_changed.emit()
	players[id] = "LikeBot" #TODO: Generate CPU name from list resource here
	if not is_name_free(players[id]):
		players[id] = "CommentBot"
	else:
		return
	if not is_name_free(players[id]):
		players[id] = "SubscribeBot"
	else:
		return
	if not is_name_free(players[id]):
		players[id] = "MembershipBot"
	else:
		return

func is_id_free(chosen_ai_id) -> bool:
	for p in players:
		if p == chosen_ai_id:
			return false
	return true

func is_name_free(playername: String) -> bool:
	var times_name_used := 0
	for p in players:
		if players[p] == playername:
			times_name_used += 1
	if times_name_used > 1:
		return false
	return true

func end_game():
	if globals.game != null: # Game is in progress.
		# End it
		globals.game.queue_free()
		if !multiplayer.is_server(): #BUG: This is likely the culprite for #100 but i don't understand mp enought yet to change it
			peer.close()
	if has_node("/root/MainMenu"):
		var main_menu: Control = get_node("/root/MainMenu")
		main_menu.show()
		main_menu.unpause_main_menu_music()
	game_ended.emit() 
	players.clear()
	resetvars()
	world_data.reset()
	
func resetvars():
	total_player_count = 1
	human_player_count = 1

func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
