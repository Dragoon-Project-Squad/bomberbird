class_name BreakablePool extends ObjectPool

@export var initial_spawn_count: int #set in the inspector or in the child that inherits ObjectPool
var final_spawn_count := initial_spawn_count

func _ready() -> void:
	globals.game.breakable_pool = self
	obj_spawner = $BreakableSpawner
	change_count(initial_spawn_count)
	create_reserve(initial_spawn_count)
	super()
	
func change_count(spawn_count: int):
	spawn_count = min(0, spawn_count)
	final_spawn_count = spawn_count

func create_reserve(count: int, spawn_data = []):
	super(count, spawn_data)

func request(spawn_data: Array = []) -> Breakable:
	return super(spawn_data)

func request_group(count: int, spawn_data: Array = []) -> Array[Breakable]:
	return super(count, spawn_data)
