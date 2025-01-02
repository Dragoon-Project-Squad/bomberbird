extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567
const MAX_PEERS = 4
const BASE_RENDER: Vector2 = Vector2(1152, 648)
const MIN_SIZE = Vector2(1152, 648)
const MAX_ID_COLLISION_RESCUE_ATTEMPTS = 4
const MAX_NAME_COLLISION_RESCUE_ATTEMPTS = 4
const AI_NAMES = ["LikeBot", "CommentBot", "SubscribeBot", "MembershipBot"]

# Preloaded Scenes
var player_scene = preload("res://scenes/player.tscn")
var ai_player_scene = preload("res://scenes/aiplayer.tscn")

var peer = null
var players: Dictionary = {}
var player_name = "Dragoon"
var total_player_count = 2
var human_player_count = 1
var players_ready = []

# Scene management
var current_scene = null
var game_container: SubViewportContainer
var game_subport: SubViewport
var main_node: CanvasLayer

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

func _enter_tree():
	ProjectSettings.set_setting("display/window/size/min_width", MIN_SIZE.x)
	ProjectSettings.set_setting("display/window/size/min_height", MIN_SIZE.y)
	DisplayServer.window_set_min_size(MIN_SIZE)
	# Gets last child of root because it counts back from the end of the index

	# Please don't change these lines unless you can confirm the nodes get assigned
	main_node = get_node("/root/Main")
	game_container = main_node.get_node("GameContainer")
	game_subport = game_container.get_node("GamePort")

func _ready():
	print(game_container.get_path())
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)

	get_tree().get_root().connect("size_changed", Callable(self, "_on_screen_resized"))
	_on_screen_resized()

func _on_screen_resized():
	# Calculate current viewport size and integer scaling factor
	var cur_viewport_size: Vector2 = get_viewport().size
	var scale_factor: int = mini(
		floor(cur_viewport_size.x / BASE_RENDER.x),
		floor(cur_viewport_size.y / BASE_RENDER.y)
	)
	print("Current viewport size: ", cur_viewport_size)
	print("Scale factor: ", scale_factor)

	# Calculate the offset, then adjust scale + position of game container
	var scaled_size: Vector2 = BASE_RENDER * scale_factor
	game_container.scale = Vector2(scale_factor, scale_factor) / 2
	game_container.position = floor((cur_viewport_size - scaled_size) / 2)


func goto_scene(path):
	_deferred_goto_scene.call_deferred(path)

func _deferred_goto_scene(path):
	# Safe to remove scene
	# Load, instance new scene, then add to root as child
	current_scene.free()
	current_scene = ResourceLoader.load(path).instantiate()
	game_subport.add_child(current_scene)


# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name)

# Callback from SceneTree.
func _player_disconnected(id):
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
	var world = load("res://scenes/world.tscn").instantiate()
	game_subport.add_child(world)
	current_scene = world

	# get lobby from game_subport
	if game_subport.has_node("Lobby"):
		game_subport.get_node("Lobby").hide()

	# Set up score.
	world.get_node("Score").add_player(multiplayer.get_unique_id(), player_name)
	for pn in players:
		world.get_node("Score").add_player(pn, players[pn])

	get_tree().set_pause(false) # Unpause and start the game!


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
	assert(multiplayer.is_server())
	add_ai_players()
	load_world.rpc()
	var world = game_subport.get_node("World")
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
		var spawnedplayer
		if humans_loaded_in_game < human_player_count:
			# Spawn a human there
			spawnedplayer = player_scene.instantiate()
			humans_loaded_in_game += 1
		else:
			# Spawn a robot there
			# TODO: Find a way to track how many humans and AI are participating
			spawnedplayer = ai_player_scene.instantiate()
		spawnedplayer.synced_position = spawn_pos
		spawnedplayer.name = str(p_id)
		spawnedplayer.set_player_name(player_name if p_id == multiplayer.get_unique_id() else players[p_id])
		world.get_node("Players").add_child(spawnedplayer)

func add_ai_players():
	var ai_player_count = total_player_count - human_player_count
	if ai_player_count <= 0: # No robots allowed
		pass
	for n in range(0, ai_player_count, 1):
		register_ai_player()
	pass

func register_ai_player():
	var id = _generate_unique_id()
	var name = _generate_unique_name()
	players[id] = name
	player_list_changed.emit()


func _generate_unique_id() -> int:
	for id in range(2, 2 + MAX_ID_COLLISION_RESCUE_ATTEMPTS):
		if id not in players:
			return id
	return -1

func _generate_unique_name() -> String:
	for name in AI_NAMES:
		if name not in players.values():
			return name
	return "AIPlayer"


func end_game():
	current_scene.queue_free()
	players.clear()
	game_ended.emit()

