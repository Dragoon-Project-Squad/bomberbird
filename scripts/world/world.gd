extends Node2D
class_name World
## World contains the base functionallity of every stage
## World expects the following structure (child nodes) to work properly:
## - Floor: TileMapLayer (Layer just consists of floor tiles)
## - Bounds: TileMapLayer (Layer with just tiles blocking the player from exiting the main area)
## - Obstacles: TileMapLayer (Layer with Unbreakables and potentially Breakables)
## - Breakables: Node2D (Node that will contain all breakables generated)
## - Players: PlayerManager (Node that will contain all players)
## - MisobonPath: MisobonPath (Node that will contain all misobon players)
## - BombPool: BombPool (Node that spawns and contains all bombs used during the game
## - PickupPool: PickupPool (Node that spawns and contains all pickups used during the game
## - Camera2D: Camera2D (Main camera used during the game)
## - Timers: Node (Node that will contain all Timers)
## - Music: Node (responsable for playing the music in this stage)
## - BreakableSpawner
## - PlayerSpawner
## - MisobonPlayerSpawner

@export_group("World Settings")
## The Rectangle that covers the playable area where (x,y) are the top left corner and (w, h) the size of the rectangle all in tile coordinates
@export var _arena_rect: Rect2i
## The Rectangle that determans the world_edge hence outside of which items are wrapped around to the other side
@export var _world_edge_rect: Rect2i
## list of spawnpoints (if there are less players then spawnpoints they will be used in order)
## if there is more players then spawnpoints, spawnpoints will be choosen randomly
@export var spawnpoints: Array[Vector2i]
@export var exit_table: ExitTable
@export var enemy_table: EnemyTable
@export var pickup_table: PickupTable

@onready var floor_layer = $Floor
@onready var bounds_layer = $Bounds
@onready var obstacles_layer = $Obstacles
@onready var hurry_up = $HurryUp

@onready var music = $Music

## The Atlas coordinate of the unbreakable tile in this stages tileset
var _unbreakable_tile: Vector2i
var _rng = RandomNumberGenerator.new()

var breakable_pool: BreakablePool

# PRIVATE FUNCTIONS

func _ready() -> void:
	_asserting_world()
	disable()
	breakable_pool = globals.game.breakable_pool

func stage_ended():
	pass

func disable():
	music.stop()

	bounds_layer.collision_enabled = false
	obsticals_layer.collision_enabled = false

@warning_ignore("SHADOWED_VARIABLE")
func enable(exit_table: ExitTable, enemy_table: EnemyTable, pickup_table: PickupTable, spawnpoints: Array[Vector2i]):
	music.play()
	globals.current_world = self
	if hurry_up:
		hurry_up.start()

	bounds_layer.collision_enabled = true
	obsticals_layer.collision_enabled = true

	world_data.reset()
	astargrid_handler.astargrid.clear()

	world_data.begin_init(_arena_rect, _world_edge_rect, floor_layer)
<<<<<<< HEAD
	world_data.init_unbreakables(_unbreakable_tile, obstacles_layer)
=======
	world_data.init_unbreakables(_unbreakable_tile, obsticals_layer)

>>>>>>> f572cc7 (breakable_pool and more init stuff)
	astargrid_handler.setup_astargrid()

	self.enemy_table = enemy_table.duplicate()
	self.exit_table = exit_table.duplicate()
	self.pickup_table = pickup_table.duplicate()
	pickup_table.update()
	print(pickup_table.pickup_weights)
	self.spawnpoints = spawnpoints

	_set_spawnpoints()
	if is_multiplayer_authority():
		if !globals.game.players_are_spawned: _spawn_player()
		else: _place_players.rpc()
		_spawn_enemies()
	_generate_breakables()

	world_data.finish_init()
	astargrid_handler.astargrid_set_initial_solidpoints()

## resets a stage s.t. it may be reused later
func reset():
	for breakable in breakable_pool.get_children():
		if !(breakable is Breakable): continue
		if !breakable.visible: continue #If the breakable is visible we may assume it is in use
		if is_multiplayer_authority():
			breakable.disable_collision.rpc()
			breakable.disable.rpc()
		breakable_pool.return_obj(breakable)

func _spawn_enemies():
	pass

## Asserts that properties of the world are set correctly
func _asserting_world():
	assert(_arena_rect.size != Vector2i.ZERO, "area_rect must be set properly and cannot have size ZERO")

## Generates all the breakables
func _generate_breakables():
	pass

func _spawn_breakable(cell: Vector2i):
	world_data.init_breakable(cell)
	var spawn_coords = world_data.tile_map.map_to_local(cell)
	astargrid_handler.astargrid_set_point.rpc(spawn_coords, true)
	breakable_pool.request().place(spawn_coords)

## sets spawnpoints
func _set_spawnpoints():
	var remaining_spawnpoints: int = gamestate.total_player_count - spawnpoints.size()
	while remaining_spawnpoints > 0:	
		var new_spawnpoint: Vector2i = Vector2i(
			_rng.randi_range(0, world_data.world_width - 1),
			_rng.randi_range(0, world_data.world_height - 1),
		) + world_data.floor_origin
		if world_data.is_tile(world_data.tiles.UNBREAKABLE, world_data.tile_map.map_to_local(new_spawnpoint)):
				continue # Skip cells where solid tiles are placed
		if new_spawnpoint in spawnpoints:
			continue
		if new_spawnpoint in enemy_table.get_coords():
			continue
		spawnpoints.append(new_spawnpoint)
		remaining_spawnpoints -= 1

@rpc("call_local")
func _place_players():
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	var spawn_point_idx = 0
	spawn_points[1] = spawn_point_idx # Server in spawn point 0.

	for p in gamestate.players:
		spawn_point_idx += 1
		spawn_points[p] = spawn_point_idx

	for p_id in spawn_points:
		globals.player_manager.get_node(str(p_id)).position = world_data.tile_map.map_to_local(spawnpoints[spawn_points[p_id]])	

func _spawn_player():
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	var spawn_point_idx = 0
	spawn_points[1] = spawn_point_idx # Server in spawn point 0.

	for p in gamestate.players:
		spawn_point_idx += 1
		spawn_points[p] = spawn_point_idx

	var humans_loaded_in_game = 0

	for p_id in spawn_points:
		var spawn_pos: Vector2 = world_data.tile_map.map_to_local(spawnpoints[spawn_points[p_id]])
		print(p_id, ": ", spawn_pos) 
		var playerspawner: MultiplayerSpawner = globals.game.player_spawner
		var misobonspawner: MultiplayerSpawner = globals.game.misobon_player_spawner
		var spawningdata = {"spawndata": spawn_pos, "pid": p_id, "defaultname": gamestate.player_name, "playerdictionary": gamestate.players, "characterdictionary": gamestate.characters}
		var misobondata = {"spawn_here": 0.0, "pid": p_id}
		var player: Player 

		if humans_loaded_in_game < gamestate.human_player_count:
			spawningdata.playertype = "human"
			misobondata.player_type = "human"
			humans_loaded_in_game += 1
		else:
			spawningdata.playertype = "ai"
			misobondata.player_type = "ai"

		player = playerspawner.spawn(spawningdata)
		if gamestate.misobon_mode != gamestate.misobon_states.OFF:
			misobondata.name = player.get_player_name()
			misobonspawner.spawn(misobondata)
