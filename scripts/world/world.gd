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


@export var pickup_table: PickupTable


@onready var floor_layer = $Floor
@onready var bounds_layer = $Bounds
@onready var obstacles_layer = $Obstacles
@onready var breakable_spawner = $BreakableSpawner
@onready var breakables = $Breakables
@onready var bomb_pool = $BombPool
@onready var pickup_pool = $PickupPool
@onready var game_ui= $GameUI

## The Atlas coordinate of the unbreakable tile in this stages tileset
var _unbreakable_tile: Vector2i

## declares whenever a world is special (hence should be loaded standalone without adjusting anything
var _is_special: bool

# PRIVATE FUNCTIONS

func _init():
	globals.current_world = self

func _ready() -> void:
	_asserting_world()
	world_data.begin_init(_arena_rect, _world_edge_rect, floor_layer)
	world_data.init_unbreakables(_unbreakable_tile, obstacles_layer)
	astargrid_handler.setup_astargrid()
	_set_spawnpoints()
	_generate_breakables()
	world_data.finish_init()
	astargrid_handler.astargrid_set_initial_solidpoints()

## Asserts that properties of the world are set correctly
func _asserting_world():
	assert(_arena_rect.size != Vector2i.ZERO, "area_rect must be set properly and cannot have size ZERO")

## Generates all the breakables
func _generate_breakables():
	pass

## sets spawnpoints
func _set_spawnpoints():
	pass
