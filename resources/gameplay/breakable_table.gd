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
		func (entry: Dictionary) -> Vector2i: return entry.coords
	), TYPE_VECTOR2I, "", null)

func get_specific_pickup_breakables(pickup_type: int) -> Array[Vector2i]:
	var arr: Array = breakables.filter(
		func (entry: Dictionary) -> bool: return entry.contained_pickup == pickup_type
		).map(
			func (entry: Dictionary) -> Vector2i: return entry.coords
			)
	return Array(arr, TYPE_VECTOR2I, "", null)
			

func size() -> int:
	return len(breakables)

func to_json() -> Array[Dictionary]:
	var res: Array[Dictionary]
	for entry in breakables:
		var new_entry: Dictionary = {
			"coords": var_to_str(entry.coords),
			"contained_pickup": entry.contained_pickup,
			"probability": entry.probability,
			}
		res.append(new_entry)
	return res

func from_json(json_data: Array):
	breakables = []
	for entry in json_data:
		var new_entry: Dictionary = {
			"coords": str_to_var(entry.coords),
			"contained_pickup": int(entry.contained_pickup),
			"probability": entry.probability,
			}
		breakables.append(new_entry)
