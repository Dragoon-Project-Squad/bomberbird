class_name ExitPool extends ObjectPool

@export var initial_spawn_count: int #set in the inspector or in the child that inherits ObjectPool

func _ready() -> void:
	globals.game.exit_pool = self
	obj_spawner = $ExitSpawner
	create_reserve(initial_spawn_count)
	super()

func create_reserve(count: int, color: Color = Color.WHITE):
	super(count, color)

func request(color: Color) -> Exit:
	var exit: Exit = super(color)
	exit.hide.call_deferred()
	exit.set_deferred("modulate", color)
	return exit

func request_group(count: int, color: Color) -> Array[Exit]:
	return super(count, color)
