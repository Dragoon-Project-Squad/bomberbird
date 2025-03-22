class_name EnemyTable extends Resource

class Enemy extends Resource:
	@export var file: String
	@export var coords: Vector2i
	func _init(in_coords: Vector2i, in_file: String):
		self.coords = in_coords
		self.file = in_file
	func _to_string():
		return "(" + str(coords) + ", " + str(file) + ")"

@export var enemys: Array[Enemy] = []

func append(enemy_coordinates: Vector2i, enemy_file: String):
	enemys.append(
		Enemy.new(
			enemy_coordinates,
			enemy_file,
		)
	)

func set_file(index: int, enemy_file: String):
	enemys[index].file = enemy_file


func set_x(index: int, x: int):
	enemys[index].coords.x = x


func set_y(index: int, y: int):
	enemys[index].coords.y = y

func remove_at(index: int):
	enemys.remove_at(index)
