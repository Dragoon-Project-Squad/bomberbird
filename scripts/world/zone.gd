extends World
class_name Zone
## Zone contains the base for each type of zone

@export_group("Zone")
@export var unbreakable_tile: Vector2i
@export var tileset_id: int
@export_enum("saloon", "beach", "dungeon", "lab", "school", "secret", "vintage",) var breakable_texture : int

func _ready() -> void:
	_unbreakable_tile = unbreakable_tile
	_tileset_id = tileset_id
	print(breakable_texture)
	_breakable_texture_path = gamestate.obstaclepaths.get_value_by_argument(breakable_texture)

	super()
