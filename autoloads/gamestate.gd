extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT := 10567
var is_game_online := false 
#TODO: Create VSCOM option, then set this to false and enable ONLY if Online

# Steam
const RELEASE_BUILD : bool = false # Will require the game to be launched through Steam specifically.
const STEAM_APP_ID : int = 480
const LobbyClass = preload("uid://jhdlqsokif5o")

# Multiplayer vars
const MAX_PEERS := 4
var peer : MultiplayerPeer = null

#Environmental damage vars
const ENVIRONMENTAL_KILL_PLAYER_ID := -69
const ENEMY_KILL_PLAYER_ID := -42

# Name for my player.
var player_name : String = globals.config.get_player_name()
var player_id : int = 0
# Names for remote players in id:name format.

# Name for player who hosts game
var host_player_name = ""

# Character Textures Resources

var character_texture_paths: CharacterSelectDataResource = preload("res://resources/css/character_texture_paths_default.tres")
var obstaclepaths: ObstaclePathResource = preload("res://resources/gameplay/default_obstacle_paths.tres")
var DEFAULT_PLAYER_TEXTURE_PATH = character_texture_paths.NORMALGOON_PLAYER_TEXTURE_PATH

# Player Data Master Dictionary
# Each Dict has:
# playername - The string name this player goes by
# playerslot - The slot this player takes up, if enabled
# spritepaths -
# is_ai - 
# is_enabled - determines if the player actually is loaded in or if their slot is available


var player_data_resource: PlayerDataResource = preload("res://resources/settings/player_data_default.tres")
var player_data_master_dict = {
	1: {
		"playername": globals.config.get_player_name(),
		"slotid": 1, 
		"spritepaths": character_texture_paths.bhdoki_paths, 
		"is_ai": false, 
		"is_enabled": true,
		"score": 0
	}
}

#Outdated Player Data Vars
var total_player_count := 1
var human_player_count := 1 #Every game must have at least 1 human or two AI

# AI Handling variables
const MAX_ID_COLLISION_RESCUE_ATTEMPTS = 4
const MAX_NAME_COLLISION_RESCUE_ATTEMPTS = 4

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)
signal secret_status_sent

signal lobby_created
signal lobby_joined

# Preloaded Scenes
var campaign_game_scene: String = "res://scenes/campaign_game.tscn"
var battlemode_game_scene: String = "res://scenes/battlemode_game.tscn"

# Singleplayer Vars
var current_level: int = 1 #205 # Defaults to a high number for battle mode.
var current_save_file: String = ""
var current_save: Dictionary
var current_graph: String

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
@rpc("call_remote", "any_peer")
func update_server_player_lists(client_player_name):
	var id = multiplayer.get_remote_sender_id()
	var ai_count = get_cpu_count()
	clear_ai_players()
	register_player(client_player_name, id)
	establish_player_counts()
	add_ai_players(ai_count)
	establish_player_counts()
	assign_player_numbers()
	sync_playerdata_across_players.rpc(player_data_master_dict.duplicate())

#@rpc("call_local")
#func sync_gamestate_across_players(in_players, in_player_numbers, in_host_player_name, in_characters):
	#players = in_players
	#player_numbers = in_player_numbers
	#host_player_name = in_host_player_name
	#characters = in_characters
	#player_list_changed.emit()
	
@rpc("call_local")
func sync_playerdata_across_players(newplayer_data_master_dict):
	player_data_master_dict = newplayer_data_master_dict.duplicate()
	player_list_changed.emit()

@rpc("call_remote")
func set_secret_status(host_secret_status):
	globals.secrets_enabled = host_secret_status
	secret_status_sent.emit()

## Steam-specific. Used whenever trying to join a lobby.
func _join_requested(lobby_id: int, steam_id: int) -> void:
	await join_game(lobby_id)

## Steam-specific. Called when something Multiplayer-related failed.
func _network_session_failed(steam_id: int, reason: int, connection_state: int) -> void:
	printerr("Steam failed to do something network-related. ID: %s, Reason: %s, State: %s" % [steam_id, reason, connection_state])

# Callback from SceneTree.
func _player_disconnected(id):
	var ai_count = get_cpu_count()
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
func register_player(new_player_name: String, id: int):
	player_data_master_dict[id] = {
		"playername" = new_player_name,
		"slotid" = 0,
		"spritepaths" = character_texture_paths.normalgoon_paths,
		"is_ai" = false,
		"is_enabled" = true
	}
	player_list_changed.emit()
	if is_multiplayer_authority():
		set_secret_status.rpc_id(id, globals.secrets_enabled)
	
@rpc("authority", "call_local")
func unregister_player(id):
	player_data_master_dict.erase(id)
	player_list_changed.emit()

@rpc("authority", "call_local")
func remove_player_from_world(id):
	if globals.current_world != null:
		if globals.current_world.has_node("Players/" + str(id)):
			globals.current_world.get_node("Players/" + str(id)).queue_free()
	
@rpc("any_peer", "call_local")
func change_character_player(characterpathdict : Dictionary):
	#print(
		#"Changing ID ", 
		#multiplayer.get_remote_sender_id(), 
		#"'s character model to ", 
		#characterpathdict["walk"]
	#)
	var id = multiplayer.get_remote_sender_id()
	if id == 0:
		id = 1
	player_data_master_dict[id].spritepaths = characterpathdict.duplicate()


func assign_player_numbers():
	var players_assigned = 0 #If this hits 4, we kill the loop as a sanity check.
	for p in player_data_master_dict:
		match players_assigned:
			0:
				player_data_master_dict[p].slotid = 1
			1:
				player_data_master_dict[p].slotid = 2
			2:
				player_data_master_dict[p].slotid = 3
			3:
				player_data_master_dict[p].slotid = 4
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
		#print("Player ", players_assigned, " assigned to ID number: ", p)

func get_cpu_count() -> int:
	var ai_player_count = 0
	for p in player_data_master_dict:
		if player_data_master_dict[p].is_enabled && player_data_master_dict[p].is_ai:
			ai_player_count = ai_player_count + 1
	return ai_player_count
	
func establish_player_counts() -> void:
	#players actually contains ais already
	human_player_count = 0
	var ai_player_count = 0
	for p in player_data_master_dict:
		if player_data_master_dict[p].is_enabled && player_data_master_dict[p].is_ai:
			ai_player_count = ai_player_count + 1
		if player_data_master_dict[p].is_enabled && not player_data_master_dict[p].is_ai:
			human_player_count = human_player_count + 1
	total_player_count = human_player_count + ai_player_count
	#print("epc: cpus: ", ai_player_count, ", players: ", human_player_count)
	assert(multiplayer.is_server())
		
@rpc("call_local")
func load_world(game_scene):
	# Change scene.
	var game = load(game_scene).instantiate()
	get_tree().get_root().add_child(game)
	if globals.current_gamemode == globals.gamemode.CAMPAIGN:
		if self.current_save.campaign != "": current_graph = self.current_save.campaign
		else: self.current_save.campaign = current_graph
		game.load_level_graph(current_graph)
	if has_node("/root/MainMenu"):
		get_node("/root/MainMenu").pause_main_menu_music()

	# Set up score.
	if is_multiplayer_authority():
		for p in player_data_master_dict:
			game.game_ui.add_player.rpc(p, player_data_master_dict[p])
	# Unpause and unleash the game!
	game.start()
	get_tree().set_pause(false) 

func host_game(lobby_type : Steam.LobbyType):
	peer = SteamMultiplayerPeer.new()
	peer.create_lobby(lobby_type, MAX_PEERS)
	peer.network_session_failed.connect(_network_session_failed)
	
	await peer.lobby_created
	peer.network_session_failed.disconnect(_network_session_failed)
	
	multiplayer.set_multiplayer_peer(peer)
	player_data_master_dict[1].spritepaths = character_texture_paths.normalgoon_paths
	gamestate.establish_player_counts()
	
	peer.set_lobby_joinable(true)
	peer.set_lobby_data("name", "%s's Lobby" % [player_name])
	
	lobby_created.emit()

func join_game(lobby_id : int):
	peer = SteamMultiplayerPeer.new()
	peer.connect_lobby(lobby_id)
	peer.network_session_failed.connect(_network_session_failed)
	
	print("hi guys")
	await Steam.lobby_joined # ????????????????????
	
	multiplayer.set_multiplayer_peer(peer)
	peer.network_session_failed.disconnect(_network_session_failed)
	
	print("killing myself postponed")
	lobby_joined.emit()
	
	if get_tree().current_scene != LobbyClass:
		get_tree().change_scene_to_file("uid://jhdlqsokif5o") # UID leads to res://scenes/lobby/lobby.tscn

func get_player_name_list(): #id:playername
	var playernames = {}
	for p in player_data_master_dict:
		playernames[p] = player_data_master_dict[p].playername
	return playernames
	
func get_player_slot_list(): #slotid:id
	var playerslots = {}
	for p in player_data_master_dict:
		playerslots[player_data_master_dict[p].slotid] = p
	return playerslots
	
func get_player_texture_list(): #id:spritepaths
	var playertextures = {}
	for p in player_data_master_dict:
		playertextures[p] = player_data_master_dict[p].spritepaths
	return playertextures

func get_player_name() -> String:
	return player_name

func set_player_scores(player_scores) -> void:
	for id in player_scores.keys():
		player_data_master_dict[id].score = player_scores[id]

func get_player_scores() -> Dictionary:
	var scores = {}
	for id in player_data_master_dict.keys():
		scores[id] = player_data_master_dict[id].score
	return scores

func begin_singleplayer_game():
	globals.current_gamemode = globals.gamemode.CAMPAIGN
	SettingsContainer.misobon_setting = SettingsContainer.misobon_setting_states.OFF
	human_player_count = 1
	total_player_count = human_player_count
	# only used for spawning ai to debug
	if total_player_count > 1:
		add_ai_players(total_player_count - human_player_count)

	player_name = current_save.player_name
	player_data_master_dict[1].playername = current_save.player_name
	player_data_master_dict[1].spritepaths = character_texture_paths.characters[current_save.character_paths]
	load_world.rpc(campaign_game_scene)

func begin_game():
	globals.current_gamemode = globals.gamemode.BATTLEMODE
	current_level = 205
	if player_data_master_dict.size() == 0: # If players disconnected at character select
		game_error.emit("All other players disconnected")
		end_game()
	load_world.rpc(battlemode_game_scene)
	
func add_ai_players(ai_players_to_add: int):
	var ai_players_count = min(
		ai_players_to_add, 
		MAX_PEERS-human_player_count)
	for n in range(0, ai_players_count, 1):
		register_ai_player()

func clear_ai_players():
	for p in player_data_master_dict.keys():
		if player_data_master_dict[p].is_ai:
			player_data_master_dict.erase(p)

func register_ai_player():
	var id = 2 #TODO: Generate CPU ID here, ensure it does not clash
	if not is_id_free(id):
		for i in range(2, 2+MAX_ID_COLLISION_RESCUE_ATTEMPTS, 1):
			id = i
			if is_id_free(id):
				break
	player_data_master_dict[id] = {
		"playername" = "Nameless Dragoon",
		"playerid" = 0,
		"slotid" = 0,
		"spritepaths" = character_texture_paths.normalgoon_paths,
		"is_ai" = true,
		"is_enabled" = true,
		"score" = 0
	}
	assign_ai_character_sprite(id)
	name_ai_player(id)
	
	player_list_changed.emit()

func name_ai_player(pid: int):
	player_data_master_dict[pid].playername = "LikeBot" #TODO: Generate CPU name from list resource here
	if not is_name_free(player_data_master_dict[pid].playername):
		player_data_master_dict[pid].playername = "CommentBot"
	else:
		return
	if not is_name_free(player_data_master_dict[pid].playername):
		player_data_master_dict[pid].playername = "SubscribeBot"
	else:
		return
	if not is_name_free(player_data_master_dict[pid].playername):
		player_data_master_dict[pid].playername = "MembershipBot"
	else:
		return
		
func assign_ai_character_sprite(pid: int):
	match pid:
		2:
			player_data_master_dict[pid].spritepaths = character_texture_paths.normalgoon_paths
		3:
			player_data_master_dict[pid].spritepaths = character_texture_paths.chonkgoon_paths
		4:
			player_data_master_dict[pid].spritepaths = character_texture_paths.longgoon_paths
		_:
			player_data_master_dict[pid].spritepaths = character_texture_paths.dad_paths
	return
	
func is_id_free(chosen_ai_id) -> bool:
	for p in player_data_master_dict:
		if p == chosen_ai_id:
			return false
	return true

func is_name_free(playername: String) -> bool:
	var times_name_used := 0
	for p in player_data_master_dict:
		if player_data_master_dict[p].playername == playername:
			times_name_used += 1
	if times_name_used > 1:
		return false
	return true
			
func save_sp_game():
	campaign_save_manager.save(current_save, current_save_file)

func end_sp_game():
	save_sp_game()
	if globals.game != null: # Game is in progress.
		# End it
		globals.game.queue_free()
	await get_tree().create_timer(0.05).timeout #The game scene needs to DIE.
	# Only run if Main Menu is currently loaded in the scene.
	if has_node("/root/MainMenu"):
		var main_menu = get_node("/root/MainMenu")
		main_menu.show()
		main_menu.unpause_main_menu_music()
	elif has_node("/root/lobby"):
		var lobby: Node2D = get_node("/root/lobby")
		lobby.get_back_to_menu()
	game_ended.emit() #Listen to this signal to tell other nodes to cease the game.
	player_data_master_dict.clear()
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
	player_data_master_dict.clear()
	resetvars()
	world_data.reset()
	
func resetvars():
	total_player_count = 1
	human_player_count = 1
	player_data_master_dict = {
		1: {
			"playername": player_name,
			"playerid": player_id,
			"slotid": 1, 
			"spritepaths": character_texture_paths.bhdoki_paths, 
			"is_ai": false, 
			"is_enabled": true,
			"score": 0
		}
	}
	
func assign_dict_to_spritepaths(playerdict: Dictionary):
	var spritepaths : String = playerdict.spritepaths
	match spritepaths:
		"egggoon":
			playerdict.spritepaths = character_texture_paths.egggoon_paths
		"normalgoon":
			playerdict.spritepaths = character_texture_paths.normalgoon_paths
		"chonkgoon":
			playerdict.spritepaths = character_texture_paths.chonkgoon_paths
		"longgoon":
			playerdict.spritepaths = character_texture_paths.longgoon_paths
		"dad":
			playerdict.spritepaths = character_texture_paths.longgoon_paths
		"bhdoki":
			playerdict.spritepaths = character_texture_paths.bhdoki_paths
		"retrodoki":
			playerdict.spritepaths = character_texture_paths.retrodoki_paths
		"altgirldoki":
			playerdict.spritepaths = character_texture_paths.altgirldoki_paths
		"crowki":
			playerdict.spritepaths = character_texture_paths.crowki_paths
		"tomatodoki":
			playerdict.spritepaths = character_texture_paths.tomatodoki_paths
		"secretone":
			playerdict.spritepaths = character_texture_paths.secretone_paths
		"secrettwp":
			playerdict.spritepaths = character_texture_paths.secrettwo_paths
		_:
			push_error("Could not identify character!")
			playerdict.spritepaths = character_texture_paths.egggoon_paths
			
func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
	
	# Steam-specific initialization.
	if RELEASE_BUILD and Steam.restartAppIfNecessary(STEAM_APP_ID):
		get_tree().quit()
	
	Steam.join_requested.connect(_join_requested)
	Steam.steamInit(STEAM_APP_ID, true)
	
	player_id = Steam.getSteamID()
	player_name = Steam.getFriendPersonaName(player_id)
	print("Initialized Steam with id %s (%s)" % [player_id, player_name])
	
	player_data_master_dict[1].playername = player_name
