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

## The Atlas coordinate of the unbreakable tile in this stages tileset
var _unbreakable_tile: Vector2i
var breakable_pool: BreakablePool
var rng = RandomNumberGenerator.new()

# PRIVATE FUNCTIONS

func _init():
	globals.current_world = self

func _ready() -> void:
	_asserting_world()
	disable()
	breakable_pool = globals.game.breakable_pool

func disable():
	bounds_layer.collision_enabled = false
	obsticals_layer.collision_enabled = false

@warning_ignore("SHADOWED_VARIABLE")
func enable(exit_table: ExitTable, enemy_table: EnemyTable, pickup_table: PickupTable, spawnpoints: Array[Vector2i]):
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

	self.enemy_table = enemy_table
	self.exit_table = exit_table
	self.pickup_table = pickup_table
	self.spawnpoints = spawnpoints

	_set_spawnpoints()
	_spawn_enemies()
	_generate_breakables()

	world_data.finish_init()
	astargrid_handler.astargrid_set_initial_solidpoints()

## resets a stage s.t. it may be reused later
func _reset():
	pass

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
			rng.randi_range(0, world_data.world_width - 1),
			rng.randi_range(0, world_data.world_height - 1),
		) + world_data.floor_origin
		if world_data.is_tile(world_data.tiles.UNBREAKABLE, world_data.tile_map.map_to_local(new_spawnpoint)):
				continue # Skip cells where solid tiles are placed
		if new_spawnpoint in spawnpoints:
			continue
		if new_spawnpoint in enemy_table.get_coords():
			continue
		spawnpoints.append(new_spawnpoint)
		remaining_spawnpoints -= 1
