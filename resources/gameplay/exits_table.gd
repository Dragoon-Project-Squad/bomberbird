class_name ExitTable extends Resource

@export var exits: Array[Dictionary] = []

func _init():
	self.resource_local_to_scene = true

## adds an exit to the table
## [param exit_coordinates] Vector2i the position of the exit
## [param exit_color] Color the color of the exit
func append(exit_coordinates: Vector2i, exit_color: Color):
	var entry: Dictionary = {
		"coords": exit_coordinates,
		"color": exit_color,
		}
	exits.append(entry)

## sets the color of some exit
## [param index] intex of the exit to set
## [param exit_color] Color the color of the exit
func set_color(index: int, exit_color: Color):
	exits[index].color = exit_color

## sets the x coordinate of some exit
## [param index] intex of the exit to set
## [param x] x coordinate to set
func set_x(index: int, x: int):
	exits[index].coords.x = x


## sets the y coordinate of some exit
## [param index] intex of the exit to set
## [param y] y coordinate to set
func set_y(index: int, y: int):
	exits[index].coords.y = y

## removes an entry in exit
## [param index] intex of the exit to set
func remove_at(index: int):
	exits.remove_at(index)

## returns the amount of exits in the exit_table
func size() -> int:
	return len(exits)

func to_json() -> Array[Dictionary]:
	var res: Array[Dictionary]
	for entry in exits:
		var new_entry: Dictionary = {
			"coords": var_to_str(entry.coords),
			"color": var_to_str(entry.color),
			}
		res.append(new_entry)
	return res

func from_json(json_data: Array):
	exits = []
	for entry in json_data:
		var new_entry: Dictionary = {
			"coords": str_to_var(entry.coords),
			"color": str_to_var(entry.color)
			}
		exits.append(new_entry)
