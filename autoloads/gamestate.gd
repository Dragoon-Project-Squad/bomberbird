extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT := 10567
var is_game_online := false

# Multiplayer vars
const MAX_PEERS := 4
var peer : MultiplayerPeer = null

# Steam
const RELEASE_BUILD : bool = false # Will require the game to be launched through Steam specifically.
const LobbyClass = preload("uid://jhdlqsokif5o") # UID leads to res://scenes/lobby/lobby.tscn
const PACKET_READ_LIMIT: int = 32

var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = MAX_PEERS
var lobby_vote_kick: bool = false
var steam_id: int = 0
var steam_username: String = ""


#Environmental damage vars
const ENVIRONMENTAL_KILL_PLAYER_ID := -69
const ENEMY_KILL_PLAYER_ID := -42

# Name for my player.
var player_name := "Value is set before save is loaded."
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
		"playername": "Value is set before save is loaded.",
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

# Steam Exclusive Signals
signal steam_lobby_creation_finished
signal steam_lobby_join_finished

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
	
@rpc("call_local")
func sync_playerdata_across_players(newplayer_data_master_dict):
	player_data_master_dict = newplayer_data_master_dict.duplicate()
	player_list_changed.emit()

@rpc("call_remote")
func set_secret_status(host_secret_status):
	globals.secrets = host_secret_status.duplicate()
	secret_status_sent.emit()
	
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
	if is_multiplayer_authority():
		set_secret_status.rpc_id(id, globals.secrets)
		sync_playerdata_across_players.rpc(player_data_master_dict)
	
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
		
@rpc("call_local")
func load_world(game_scene):
	# Change scene.
	var game = load(game_scene).instantiate()
	get_tree().get_root().add_child(game)
	if globals.is_singleplayer():
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

func host_vanilla_game(new_player_name):
	player_name = new_player_name
	host_player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.set_multiplayer_peer(peer)
	player_data_master_dict[1].spritepaths = character_texture_paths.normalgoon_paths
	gamestate.establish_player_counts()

func join_vanilla_game_as_peer(ip, new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)

func attempt_host_steam_game(lobby_type : Steam.LobbyType):
	print_debug("Attempting to host game...")
	
	if lobby_id != 0:
		print_debug("Game detects a lobby is already open under your name!")

	Steam.createLobby(lobby_type, lobby_members_max)
	
func host_steam_mp_game(hosting_lobby_id : int) -> void:
	peer = SteamMultiplayerPeer.new()
	peer.create_host()
	
	multiplayer.set_multiplayer_peer(peer)
	player_data_master_dict[1].spritepaths = character_texture_paths.normalgoon_paths
	gamestate.establish_player_counts()
	
	Steam.setLobbyData(hosting_lobby_id, "name", "%s's Lobby" % [player_name])
	
	steam_lobby_creation_finished.emit()

func join_steam_game_as_peer(joined_lobby_id : int):
	peer = SteamMultiplayerPeer.new()
	peer.connect_to_lobby(joined_lobby_id)
	
	multiplayer.set_multiplayer_peer(peer)
	steam_lobby_join_finished.emit()
	
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

func begin_mp_game():
	globals.current_gamemode = globals.gamemode.BATTLEMODE
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
	if globals.is_campaign_mode(): # do not write boss_rush data to a file
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
	elif has_node("/root/Lobby"):
		var lobby: Control = get_node("/root/Lobby")
		lobby.get_back_to_menu()
	game_ended.emit() #Listen to this signal to tell other nodes to cease the game.
	player_data_master_dict.clear()
	resetvars()
	world_data.reset()

func boss_rush_back_to_lobby():
	save_sp_game()
	if globals.game != null: # Game is in progress.
		# End it
		globals.game.queue_free()
	await get_tree().create_timer(0.05).timeout #The game scene needs to DIE.
	# Only run if Main Menu is currently loaded in the scene.
	assert(has_node("/root/Lobby"))
	var lobby: Control = get_node("/root/Lobby")
	lobby.show_character_select_screen()

	game_ended.emit() #Listen to this signal to tell other nodes to cease the game.
	player_data_master_dict.clear()
	resetvars()
	world_data.reset()

func end_game():
	if globals.game != null: # Game is in progress.
		# End it
		globals.game.queue_free()
	if multiplayer.has_multiplayer_peer():
		var peer_still_connected : bool
		peer_still_connected = false if peer.get_connection_status() == 0 else true
		if peer_still_connected && multiplayer.is_server(): #I'm the host.
			for peers in multiplayer.get_peers():
				multiplayer.multiplayer_peer.disconnect_peer(peers) #Tell the host to kick everyone.
		peer.close() #Close the peer so everyone really knows I'm leaving.
		peer = OfflineMultiplayerPeer.new() #Tell Godot that we're in Offline mode and to safely retarget all RPC codes for a singleplayer experience.
		multiplayer.set_multiplayer_peer(peer)
		if SteamManager.game_is_steam_powered:
			leave_steam_lobby()
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
		"schooldoki":
			playerdict.spritepaths = character_texture_paths.schooldoki_paths
		"crowki":
			playerdict.spritepaths = character_texture_paths.crowki_paths
		"tomatodoki":
			playerdict.spritepaths = character_texture_paths.tomatodoki_paths
		"wisp":
			playerdict.spritepaths = character_texture_paths.wisp_paths
		"mint":
			playerdict.spritepaths = character_texture_paths.mint_paths
		"snuffy":
			playerdict.spritepaths = character_texture_paths.snuffy_paths
		"laimu":
			playerdict.spritepaths = character_texture_paths.laimu_paths
		"dooby":
			playerdict.spritepaths = character_texture_paths.dooby_paths
		"nimi":
			playerdict.spritepaths = character_texture_paths.nimi_paths
		_:
			push_error("Could not identify character!")
			playerdict.spritepaths = character_texture_paths.egggoon_paths


func _on_steam_lobby_created(connection: int, this_lobby_id: int) -> void:
	print_debug("Lobby creation attempt returned.")
	if connection != Steam.RESULT_OK:
		printerr("Lobby creation failed.")
		display_specific_steam_lobby_creation_error(connection)
	else:
		# Set the lobby ID
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)

		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(lobby_id, true)

		# Set some lobby data
		Steam.setLobbyData(lobby_id, "name", "Default Name Lobby")

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)
		host_steam_mp_game(lobby_id)
		
		
# Steam-specific. Catalouges error messages.
func display_specific_steam_lobby_creation_error(connection_failed_reason_code : int) -> void:
	var fail_reason: String
	
	match connection_failed_reason_code:
		Steam.RESULT_FAIL: fail_reason = "This lobby no longer exists."
		Steam.RESULT_TIMEOUT: fail_reason = "TThe message was sent to the Steam servers, but it didn't respond."
		Steam.RESULT_LIMIT_EXCEEDED: fail_reason = "Your game client has created too many lobbies and is being rate limited."
		Steam.RESULT_ACCESS_DENIED: fail_reason = "Your game isn't set to allow lobbies, or your client does not rights to play the game!"
		Steam.RESULT_NO_CONNECTION: fail_reason = "Your Steam client doesn't have a connection to the back-end."

	print("Failed to create Steam lobby: %s" % fail_reason)

## Steam-specific. Used whenever trying to join a lobby.
func join_steam_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % lobby_id)

	# Clear any previous lobby members lists, if you were in a previous lobby
	lobby_members.clear()

	# Make the lobby join request to Steam
	Steam.joinLobby(this_lobby_id)
	
func _on_steam_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	# Get the lobby owner's name
	var owner_name: String = Steam.getFriendPersonaName(friend_id)

	print("Joining %s's lobby..." % owner_name)

	# Attempt to join the lobby
	join_steam_lobby(this_lobby_id)
	
func _on_steam_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id

		# Get the lobby members
		get_lobby_members()

		# Make the initial handshake
		make_steam_p2p_handshake()
		# If not the owner of lobby, join up
		if Steam.getLobbyOwner(lobby_id) != Steam.getSteamID():
			join_steam_game_as_peer(lobby_id)
		
	# Else it failed for some reason
	else:
		# Get the failure reason
		var fail_reason: String

		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "YOu should not be seeing this message!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."

		print("Failed to join this lobby: %s" % fail_reason)

		#Reopen the lobby list
		#_on_open_lobby_list_pressed() #No lobby list functionality in Bomberbird yet

func get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()

	# Get the number of members from this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)

	# Get the data of these players from Steam
	for this_member in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)

		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)

		# Add them to the list
		lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})

# A user's information has changed
func _on_steam_persona_change(this_steam_id: int, _flag: int) -> void:
	# Make sure you're in a lobby and this user is valid or Steam might spam your console log
	if lobby_id > 0:
		print_debug("A user (%s) had information change, update the lobby list" % this_steam_id)

		# Update the player list
		get_lobby_members()

func _on_steam_lobby_chat_update(_this_lobby_id: int, change_id: int, _making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)

	# Else if a player has left the lobby
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)

	# Else if a player has been kicked
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)

	# Else if a player has been banned
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)

	# Else there was some unknown change
	else:
		print("%s did... something." % changer_name)

	# Update the lobby now that a change has occurred
	get_lobby_members()

func leave_steam_lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		lobby_id = 0

		# Close session with all users
		for this_member in lobby_members:
			# Make sure this isn't your Steam ID
			if this_member['steam_id'] != steam_id:

				# Close the P2P session using the Networking class
				Steam.closeP2PSessionWithUser(this_member['steam_id'])

		# Clear the local lobby list
		lobby_members.clear()

## Steam-specific. Helps handle handshakes.
func _on_steam_network_messages_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)

	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptSessionWithUser(remote_id)

	# Make the initial handshake
	make_steam_p2p_handshake()
	
## Steam-specific. Called when something Multiplayer-related failed.
func _on_steam_network_messages_session_failed(fail_steam_id: int, fail_reason: int, fail_connection_state: int) -> void:
	printerr("Steam failed to do something network-request-related. ID: %s, Reason: %s, State: %s" % [fail_steam_id, fail_reason, fail_connection_state])

func make_steam_p2p_handshake() -> void:
	print("Sending P2P handshake to the lobby")

	send_steam_p2p_packet(0, {"message": "handshake", "from": steam_id})

func send_steam_p2p_packet(this_target: int, packet_data: Dictionary) -> void:
			# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0

	# Create a data array to send the data through
	var this_data: PackedByteArray
	this_data.append_array(var_to_bytes(packet_data))

	# If sending a packet to everyone
	if this_target == 0:
		# If there is more than one user, send packets
		if lobby_members.size() > 1:
			# Loop through all members that aren't you
			for this_member in lobby_members:
				if this_member['steam_id'] != steam_id:
					Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)

	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel)
			
func steam_signal_setup() -> void:
	Steam.join_requested.connect(_on_steam_lobby_join_requested)
	#Steam.lobby_chat_update.connect(_on_lobby_chat_update) #No chatroom feature enabled.
	Steam.lobby_created.connect(_on_steam_lobby_created)
	#Steam.lobby_data_update.connect(_on_lobby_data_update)
	#Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_joined.connect(_on_steam_lobby_joined)
	#Steam.lobby_match_list.connect(_on_lobby_match_list)
	#Steam.lobby_message.connect(_on_lobby_message)
	Steam.persona_state_change.connect(_on_steam_persona_change)
	Steam.network_messages_session_request.connect(_on_steam_network_messages_session_request)
	Steam.network_messages_session_failed.connect(_on_steam_network_messages_session_failed)

func join_steam_lobby_on_startup(startupargs) -> void:
	printerr("This developer attempted to program command line args without actually coding their effect. Point and laugh.")
	print_debug("Anyway, here's your args, you silly billy.", startupargs)
	
	if has_node("/root/MainMenu"):
		get_node("/root/MainMenu")._on_multiplayer_pressed()
	
func steam_playername_integration():
	player_id = Steam.getSteamID()
	player_name = Steam.getFriendPersonaName(player_id)
	print("Initialized Steam with id %s (%s)" % [player_id, player_name])
	
	player_data_master_dict[1].playername = player_name

func execute_post_boot_steam_framework_methods() -> void:
	SteamManager.initialize_steam()
	steam_signal_setup()
	steam_playername_integration()
	
func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
