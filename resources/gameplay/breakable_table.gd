class_name BreakableTable extends Resource

@export var breakables: Array[Dictionary] = []

func _init():
	self.resource_local_to_scene = true

func append(breakable_coordinates: Vector2i, contained_pickup: int, probability: float):
	assert(globals.is_not_pickup_seperator(contained_pickup))
	var entry: Dictionary = {
			"coords": breakable_coordinates,
			"contained_pickup": contained_pickup,
			"probability": probability,
		}
	breakables.append(entry)

func remove_at(index: int):
	breakables.remove_at(index)

func get_coords() -> Array[Vector2i]:
	return Array(breakables.map(
		func (entry: Dictionary) -> Vector2i: return entry.coords,
	), TYPE_VECTOR2I, "", null)

func size() -> int:
	return len(breakables)
