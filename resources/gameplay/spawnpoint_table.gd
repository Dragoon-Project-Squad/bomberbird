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
