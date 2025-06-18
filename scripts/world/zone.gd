extends World
class_name Zone
## Zone contains the base for each type of zone

@export_group("Zone")
@export var unbreakable_tile: Vector2i
@export var tileset_id: int

func _ready() -> void:
	_unbreakable_tile = unbreakable_tile
	_tileset_id = tileset_id
	super()
