extends World
class_name Zone
## Zone contains the base for each type of zone

@export_group("Zone")
@export var unbreakable_tile: Vector2i

func _ready() -> void:
	_unbreakable_tile = unbreakable_tile
	super()
