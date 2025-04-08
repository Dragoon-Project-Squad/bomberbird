class_name UnbreakableTable extends Resource

@export var unbreakables: Array[Dictionary] = []

func _init():
	self.resource_local_to_scene = true

func append(breakable_coordinates: Vector2i, probability: float):
	var entry: Dictionary = {
			"coords": breakable_coordinates,
			"probability": probability,
		}
	unbreakables.append(entry)

func remove_at(index: int):
	unbreakables.remove_at(index)

func get_coords() -> Array[Vector2i]:
	return Array(unbreakables.map(
		func (entry: Dictionary) -> Vector2i: return entry.coords,
	), TYPE_VECTOR2I, "", null)

func size() -> int:
	return len(unbreakables)
