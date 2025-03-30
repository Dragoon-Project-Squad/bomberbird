class_name BombPool extends ObjectPool

@export var initial_spawn_count: int #set in the inspector or in the child that inherits ObjectPool

func _ready():
	globals.game.bomb_pool = self
	obj_spawner = get_node("BombSpawner")
	create_reserve(initial_spawn_count)
	super()

func create_reserve(count: int, spawn_data = []):
	super(count, spawn_data)

func request(spawn_data: Array = []) -> BombRoot:
	return super(spawn_data)

func request_group(count: int, spawn_data: Array = []) -> Array[BombRoot]:
	return super(count, spawn_data)
