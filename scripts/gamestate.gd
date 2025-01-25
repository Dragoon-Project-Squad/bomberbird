extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 4

var peer = null

# Player count variables
var total_player_count = 1
var human_player_count = 1 #Every game must have at least 1 human or two AI
# Name for my player.
var player_name = globals.config.get_player_name()

# Names for remote players in id:name format.
var players = {}
var players_ready = []

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
var player_scene = preload("res://scenes/player.tscn")
var ai_player_scene = preload("res://scenes/aiplayer.tscn")

# Singleplayer Vars
var current_level: int = 205 # Defaults to a high number for battle mode.

# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name)


# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/World"): # Game is in progress.
		if multiplayer.is_server():
			game_error.emit("Player " + players[id] + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)


# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	connection_succeeded.emit()


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	game_error.emit("Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	multiplayer.set_network_peer(null) # Remove peer
	connection_failed.emit()


# Lobby management functions.
@rpc("any_peer")
func register_player(new_player_name):
	var id = multiplayer.get_remote_sender_id()
	players[id] = new_player_name
	player_list_changed.emit()
	
func unregister_player(id):
	players.erase(id)
	player_list_changed.emit()


@rpc("call_local")
func load_world():
	# Change scene.
	var world = load("res://scenes/battlegrounds.tscn").instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()

	# Set up score.
	world.get_node("GameUI").add_player(multiplayer.get_unique_id(), player_name)
	for pn in players:
		world.get_node("GameUI").add_player(pn, players[pn])
	get_tree().set_pause(false) # Unpause and unleash the game!


func host_game(new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.set_multiplayer_peer(peer)


func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)


func get_player_list():
	return players.values()


func get_player_name():
	return player_name


func begin_game():
	human_player_count = 1+players.size()
	total_player_count = human_player_count + get_tree().get_root().get_node("Lobby/Options/AICountContainer/AIPlayerCount").get_value()
	#total_player_count = 2
	assert(multiplayer.is_server())
	add_ai_players()
	load_world.rpc()
	var world = get_tree().get_root().get_node("World")
	#var playerspawner = get_tree().get_root().get_node("World/PlayerSpawner")
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	spawn_points[1] = 0 # Server in spawn point 0.
	var spawn_point_idx = 1
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	var humans_loaded_in_game = 0
	for p_id in spawn_points:
		var spawn_pos = world.get_node("SpawnPoints/" + str(spawn_points[p_id])).position
		#var spawnedplayer
		var playerspawner = world.get_node("PlayerSpawner")
		var spawningdata = {"playertype": "human", "spawndata": spawn_pos, "pid": p_id, "defaultname": player_name, "playerdictionary": players}
		if humans_loaded_in_game < human_player_count:
			# Spawn a human there
			playerspawner.spawn(spawningdata)
			#spawnedplayer = player_scene.instantiate()
			humans_loaded_in_game += 1
		else:
			# Spawn a robot there
			playerspawner.spawn(spawningdata)
			#spawnedplayer = ai_player_scene.instantiate()
		#spawnedplayer.synced_position = spawn_pos
		#spawnedplayer.name = str(p_id)
		#spawnedplayer.set_player_name(player_name if p_id == multiplayer.get_unique_id() else players[p_id])
		#world.get_node("Players").add_child(spawnedplayer)
		
func add_ai_players():
	var ai_player_count = total_player_count - human_player_count
	if ai_player_count <= 0: # No robots allowed
		pass
	for n in range(0, ai_player_count, 1):
		register_ai_player()
	pass

func register_ai_player():
	var id = 2 #TODO: Generate CPU ID here, ensure it does not clash
	if !is_id_free(id):
		for i in range(2, 2+MAX_ID_COLLISION_RESCUE_ATTEMPTS, 1):
			id = i
			if is_id_free(id):
				break
	players[id] = "LikeBot" #TODO: Generate CPU name here
	if !is_name_free(players[id]):
		players[id] = "CommentBot"
	else:
		return
	if !is_name_free(players[id]):
		players[id] = "SubscribeBot"
	else:
		return
	if !is_name_free(players[id]):
		players[id] = "MembershipBot"
	else:
		return
	player_list_changed.emit()

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
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()
		peer.close()
	game_ended.emit() 
	players.clear()
	resetvars()
	
func resetvars():
	total_player_count = 1
	human_player_count = 1

func _ready():
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
