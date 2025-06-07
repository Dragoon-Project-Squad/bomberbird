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
const ENEMY_KILL_PLAYER_ID := -42

# Player count variables
var total_player_count := 1
var human_player_count := 1 #Every game must have at least 1 human or two AI

# Name for my player.
var player_name = globals.config.get_player_name()
# Names for remote players in id:name format.
var players = {}
var players_ready = []
# Name for player who hosts game
var host_player_name = ""

# Player Numbers in string:id format.
var player_numbers = {
	"p1": 1,
	"p2": -2,
	"p3": -3,
	"p4": -4
}

# Character Textures in id:texture2D format.
var characters = {}
var character_texture_paths: CharacterSelectDataResource = preload("res://resources/css/character_texture_paths_default.tres")
var DEFAULT_PLAYER_TEXTURE_PATH = character_texture_paths.NORMALGOON_PLAYER_TEXTURE_PATH
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
	# This func called withing client and server
	if multiplayer.is_server():
		request_client_player_name.rpc_id(id) #this also triggering crossclient gamestate update

#this called from server to client
@rpc("call_remote")
func request_client_player_name():
	update_server_player_lists.rpc(player_name)

#this called from client to server
@rpc("call_remote", 'any_peer')
func update_server_player_lists(client_player_name):
	var id = multiplayer.get_remote_sender_id()
	var ai_count = SettingsContainer.get_cpu_count()
	clear_ai_players()
	register_player(client_player_name, id)
	establish_player_counts()
	add_ai_players(ai_count)
	establish_player_counts()
	assign_player_numbers()
	sync_gamestate_across_players.rpc(players, player_numbers, host_player_name)

@rpc("call_local")
func sync_gamestate_across_players(in_players, in_player_numbers, in_host_player_name):
	players = in_players
	player_numbers = in_player_numbers
	host_player_name = in_host_player_name
	player_list_changed.emit()

# Callback from SceneTree.
func _player_disconnected(id):
	var ai_count = SettingsContainer.get_cpu_count()
	if multiplayer.is_server():
		clear_ai_players()
		unregister_player(id)
		establish_player_counts()
	if globals.current_world != null: # Game is in progress.
		# Remove from world
		remove_player_from_world.rpc(id)
		# If everyone else disconnected
		if total_player_count == 1:
			game_error.emit("All other players disconnected")
			end_game()
	if multiplayer.is_server():
		add_ai_players(ai_count)
		establish_player_counts()
		assign_player_numbers()
	player_list_changed.emit()

# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	connection_succeeded.emit()


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	# Gets called by the server if all players disconnect, this is to prevent that
	game_error.emit("Server disconnected")


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	multiplayer.set_multiplayer_peer(null) # Remove peer
	connection_failed.emit()

# Lobby management functions.
@rpc("any_peer")
func register_player(new_player_name, id):
	characters[id] = DEFAULT_PLAYER_TEXTURE_PATH
	players[id] = new_player_name
	player_list_changed.emit()
	
@rpc("authority", "call_local")
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
	#players actually contains ais already
	#+1 here to count ourselves
	human_player_count = 1 + players.size() - SettingsContainer.get_cpu_count()
	print("epc: cpus: ", SettingsContainer.get_cpu_count(), ", players: ", players.size())
	assert(multiplayer.is_server())
	total_player_count = min(4, human_player_count + SettingsContainer.get_cpu_count())
	
@rpc("call_local")
func load_world(game_scene):
	# Change scene.
	var game = load(game_scene).instantiate()
	get_tree().get_root().add_child(game)
	if has_node("/root/MainMenu/DebugCampaignSelector"):
		game.load_level_graph(get_node("/root/MainMenu/DebugCampaignSelector").get_graph())
	if has_node("/root/MainMenu"):
		get_node("/root/MainMenu").pause_main_menu_music()

	# Set up score.
	if is_multiplayer_authority():
		game.game_ui.add_player.rpc(multiplayer.get_unique_id(), player_name, characters[multiplayer.get_unique_id()])
		for pn in players:
			game.game_ui.add_player.rpc(pn, players[pn], characters[pn])

	# Unpause and unleash the game!
	game.start()
	get_tree().set_pause(false) 

func host_game(new_player_name):
	player_name = new_player_name
	host_player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.set_multiplayer_peer(peer)
	characters[1] = DEFAULT_PLAYER_TEXTURE_PATH
	SettingsContainer.set_cpu_count(0)
	gamestate.establish_player_counts()


func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)


func get_player_list():
	return players.values()

func get_player_name() -> String:
	return player_name

func begin_singleplayer_game():
	globals.current_gamemode = globals.gamemode.CAMPAIGN
	SettingsContainer.misobon_setting = SettingsContainer.misobon_setting_states.OFF
	human_player_count = 1
	total_player_count = human_player_count
	if total_player_count > 1:
		add_ai_players(total_player_count - human_player_count)

	characters[1] = DEFAULT_PLAYER_TEXTURE_PATH
	load_world.rpc(campaign_game_scene)

func begin_game():
	globals.current_gamemode = globals.gamemode.BATTLEMODE
	current_level = 205
	if players.size() == 0: # If players disconnected at character select
		game_error.emit("All other players disconnected")
		end_game()
	load_world.rpc(battlemode_game_scene)
	
func add_ai_players(ai_players_to_add: int):
	var ai_players_count = min(
		ai_players_to_add, 
		MAX_PEERS-human_player_count)
	SettingsContainer.set_cpu_count(ai_players_count)
	for n in range(0, SettingsContainer.get_cpu_count(), 1):
		register_ai_player()
	pass

func clear_ai_players():
	for n in range(human_player_count, total_player_count+1, 1):
		players.erase(n)
	SettingsContainer.set_cpu_count(0)
	pass

func register_ai_player():
	var id = 2 #TODO: Generate CPU ID here, ensure it does not clash
	if not is_id_free(id):
		for i in range(2, 2+MAX_ID_COLLISION_RESCUE_ATTEMPTS, 1):
			id = i
			if is_id_free(id):
				break
	assign_ai_character_sprite(id)
	name_ai_player(id)
	player_list_changed.emit()

func name_ai_player(pid: int):
	players[pid] = "LikeBot" #TODO: Generate CPU name from list resource here
	if not is_name_free(players[pid]):
		players[pid] = "CommentBot"
	else:
		return
	if not is_name_free(players[pid]):
		players[pid] = "SubscribeBot"
	else:
		return
	if not is_name_free(players[pid]):
		players[pid] = "MembershipBot"
	else:
		return
		
func assign_ai_character_sprite(pid: int):
	match pid:
		2:
			characters[pid] = character_texture_paths.NORMALGOON_PLAYER_TEXTURE_PATH
		3:
			characters[pid] = character_texture_paths.CHONKGOON_PLAYER_TEXTURE_PATH
		4:
			characters[pid] = character_texture_paths.LONGGOON_PLAYER_TEXTURE_PATH
		_:
			characters[pid] = character_texture_paths.DAD_PLAYER_TEXTURE_PATH
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
			
func end_sp_game():
	if globals.game != null: # Game is in progress.
		# End it
		globals.game.queue_free()
	await get_tree().create_timer(0.05).timeout #The game scene needs to DIE.
	#Only run if Main Menu is currently loaded in the scene.
	if has_node("/root/MainMenu"):
		var main_menu = get_node("/root/MainMenu")
		main_menu.show()
		main_menu.unpause_main_menu_music()
	game_ended.emit() #Listen to this signal to tell other nodes to cease the game.
	players.clear()
	resetvars()
	world_data.reset()
		
func end_game():
	if globals.game != null: # Game is in progress.
		# End it
		globals.game.queue_free()
	if multiplayer.has_multiplayer_peer(): 
		if not multiplayer.is_server(): #I'm not the host.
			multiplayer.multiplayer_peer.disconnect_peer(1) #Tell the host to kick me.
		peer.close() #Close the peer so everyone really knows I'm leaving.
		peer = OfflineMultiplayerPeer.new() #Tell Godot that we're in Offline mode and to safely retarget all RPC codes for a singleplayer experience.
		multiplayer.set_multiplayer_peer(peer)
	#Only run if Main Menu is currently loaded in the scene.
	if has_node("/root/MainMenu"):
		var main_menu = get_node("/root/MainMenu")
		main_menu.show()
		main_menu.unpause_main_menu_music()
	game_ended.emit() #Listen to this signal to tell other nodes to cease the game.
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
