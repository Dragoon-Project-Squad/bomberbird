class_name SpawnpointTable extends Resource

@export var spawnpoints: Array[Dictionary] = []

func _init():
	self.resource_local_to_scene = true

func append(spawnpoint_coordinates: Vector2i, spawnpoint_probability: float):
	var entry: Dictionary = {
		"coords": spawnpoint_coordinates,
		"probability": spawnpoint_probability,
		}
	spawnpoints.append(entry)

func set_color(index: int, spawnpoint_probability: Color):
	spawnpoints[index].probability = spawnpoint_probability


func set_x(index: int, x: int):
	spawnpoints[index].coords.x = x


func set_y(index: int, y: int):
	spawnpoints[index].coords.y = y

func remove_at(index: int):
	spawnpoints.remove_at(index)

func size() -> int:
	return len(spawnpoints)

func to_json() -> Array[Dictionary]:
	var res: Array[Dictionary]
	for entry in spawnpoints:
		var new_entry: Dictionary = {
			"coords": var_to_str(entry.coords),
			"probability": entry.probability,
			}
		res.append(new_entry)
	return res

func from_json(json_data: Array):
	spawnpoints = []
	for entry in json_data:
		var new_entry: Dictionary = {
			"coords": str_to_var(entry.coords),
			"probability": entry.probability,
			}
		spawnpoints.append(new_entry)
