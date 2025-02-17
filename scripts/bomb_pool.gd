extends ObjectPool

func _ready():
	obj_spawner = get_node("BombSpawner")
	super()

func create_reserve(count: int):
	spawn_data = []
	super(count)

func request(caller: Node2D) -> Node2D:
	spawn_data = []
	var bomb: Node2D = super(caller)
	if bomb.bomb_owner == null:
		bomb.set_bomb_owner.rpc(str(caller))
	return bomb

func request_array(caller: Node2D, count: int) -> Array[Node2D]:
	spawn_data = []
	var bomb_arr: Array[Node2D] = super(caller, count)
	for bomb in bomb_arr:
		if bomb.bomb_owner == null:
			bomb.set_bomb_owner.rpc(str(caller))
	return bomb_arr
