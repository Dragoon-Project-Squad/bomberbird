class_name ExitTable extends Resource

@export var exits: Array[Dictionary] = []

func _init():
	self.resource_local_to_scene = true

func append(exit_coordinates: Vector2i, exit_color: Color):
	var entry: Dictionary = {
		"coords": exit_coordinates,
		"color": exit_color,
		}
	exits.append(entry)

func set_color(index: int, exit_color: Color):
	exits[index].color = exit_color


func set_x(index: int, x: int):
	exits[index].coords.x = x


func set_y(index: int, y: int):
	exits[index].coords.y = y

func remove_at(index: int):
	exits.remove_at(index)
