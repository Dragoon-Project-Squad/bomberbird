## world expects the following structure (child nodes) to work properly:
## - Floor: TileMapLayer (Layer just consists of floor tiles)
## - Border: TileMapLayer (Layer with just tiles blocking the player from exiting the main area)
## - Obsticals: TileMapLayer (Layer with Unbreakables and potentially Breakables)
## - Breakables: Node2D (Node that will contain all breakables generated also contains the BreakableSpawner)
## - Players: PlayerManager (Node that will contain all players, also contains a PlayerSpawner)
## - MisobonPath: MisobonPath (Node that will contain all misobon players, also contains a MisobonPlayerSpawner)
## - BombPool: BombPool (Node that spawns and contains all bombs used during the game
## - PickupPool: PickupPool (Node that spawns and contains all pickups used during the game
## - Camera2D: Camera2D (Main camera used during the game)
## - Timers: Node (Contains atleast the MatchTimer)
## - Music: Node (responsable for playing the music in this stage)

extends Node2D
class_name World

@export_group("World Settings")
## Tile Coordinate of the top right tile still within the playable area
@export var arena_rect: Rect2i
@export var misobon_path_rect: Rect2i

var unbreakable_tile: Vector2i

func _init():
	globals.current_world = self

func _ready() -> void:
	assert(arena_rect != Rect2i())
	assert(misobon_path_rect != Rect2i())
	pass

