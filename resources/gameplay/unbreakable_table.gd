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

func to_json() -> Array[Dictionary]:
	var res: Array[Dictionary]
	for entry in unbreakables:
		var new_entry: Dictionary = {
			"coords": var_to_str(entry.coords),
			"probability": entry.probability,
			}
		res.append(new_entry)
	return res

func from_json(json_data: Array):
	unbreakables = []
	for entry in json_data:
		var new_entry: Dictionary = {
			"coords": str_to_var(entry.coords),
			"probability": entry.probability,
			}
		unbreakables.append(new_entry)
