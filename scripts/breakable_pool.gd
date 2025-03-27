class_name BreakablePool extends ObjectPool

@export var initial_spawn_count: int #set in the inspector or in the child that inherits ObjectPool

func _ready() -> void:
	obj_spawner = $BreakableSpawner
	create_reserve(initial_spawn_count)
	super()

func create_reserve(count: int, spawn_data = []):
	super(count, spawn_data)

func request(spawn_data: Array = []) -> Breakable:
	return super(spawn_data)

func request_group(count: int, spawn_data: Array = []) -> Array[Breakable]:
	return super(spawn_data, count)
