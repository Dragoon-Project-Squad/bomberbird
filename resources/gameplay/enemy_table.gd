class_name EnemyTable extends Resource

@export var enemies: Array[Dictionary] = []

func _init():
	self.resource_local_to_scene = true

func append(enemy_coordinates: Vector2i, enemy_file: String, enemy_path: String, probability: float):
	var entry: Dictionary = {
			"coords": enemy_coordinates,
			"file": enemy_file,
			"path": enemy_path,
			"probability": probability,
		}
	enemies.append(entry)

func set_file(index: int, enemy_file: String, enemy_path: String):
	enemies[index].file = enemy_file
	enemies[index].path = enemy_path


func set_x(index: int, x: int):
	enemies[index].coords.x = x


func set_y(index: int, y: int):
	enemies[index].coords.y = y

func remove_at(index: int):
	enemies.remove_at(index)

func get_coords() -> Array[Vector2i]:
	return Array(enemies.map(
		func (entry: Dictionary) -> Vector2i: return entry.coords,
	), TYPE_VECTOR2I, "", null)

func size() -> int:
	return len(enemies)

func get_enemy_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	for entry in enemies:
		var full_path: String = entry.path + "/" + entry.file
		if(!ret.has(full_path)): ret[full_path] = []
		ret[full_path].append({ "coords": entry.coords, "probability": entry.probability })
	return ret

func to_json() -> Array[Dictionary]:
	var res: Array[Dictionary]
	for entry in enemies:
		var new_entry: Dictionary = {
			"coords": var_to_str(entry.coords),
			"file": entry.file,
			"path": entry.path,
			"probability": entry.probability,
			}
		res.append(new_entry)
	return res

func from_json(json_data: Array):
	enemies = []
	for entry in json_data:
		var new_entry: Dictionary = {
			"coords": str_to_var(entry.coords),
			"file": entry.file,
			"path": entry.path,
			"probability": entry.probability,
			}
		enemies.append(new_entry)
