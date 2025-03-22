class_name ExitTable extends Resource

class Exit extends Resource:
	@export var coords: Vector2i
	@export var color: Color
	func _init(in_coords: Vector2i, in_color: Color):
		self.coords = in_coords
		self.color = in_color
	func _to_string():
		return "(" + str(coords) + ", " + str(color) + ")"

@export var exits: Array[Exit] = []

func append(exit_coordinates: Vector2i, exit_color: Color):
	exits.append(
		Exit.new(
			exit_coordinates,
			exit_color,
		)
	)

func set_color(index: int, exit_color: Color):
	exits[index].color = exit_color


func set_x(index: int, x: int):
	exits[index].coords.x = x


func set_y(index: int, y: int):
	exits[index].coords.y = y

func remove_at(index: int):
	exits.remove_at(index)
