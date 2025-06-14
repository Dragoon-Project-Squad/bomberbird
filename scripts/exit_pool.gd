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
	if !is_multiplayer_authority(): return
	if color == null: push_error("color_data is not allowed to be null")
	var exit = unowned.pop_front()
	if exit == null: #no obj hence spawn one
		exit = obj_spawner.spawn([])

	exit.hide()
	exit.modulate = color
	return exit

func request_group(count: int, color: Color) -> Array[Exit]:
	return super(count, color)
