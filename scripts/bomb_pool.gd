extends Node2D

@onready var bomb_spawner: MultiplayerSpawner = get_node("../BombSpawner")

func _ready():
	pass

func request_bomb(requester: Node2D) -> Node2D: #This function is called by the player when the number of bombs he holds is increased
	var tree = get_tree()
	var bomb = tree.get_nodes_in_group("unowned").pop_back()
	if bomb == null: #no bomb hence spawn one
		bomb = bomb_spawner.spawn([str(requester.name).to_int()])
	else:
		bomb.remove_from_group("unowned")

	bomb.set_bomb_owner(requester)
	bomb.add_to_group(requester.name)
	return bomb

func request_bomb_array(requester: Node2D, count: int) -> Array[Node2D]:
	var arr: Array[Node2D] = []
	for _i in range(count):
		arr.push_back(request_bomb(requester))
	return arr

func return_bomb(returner: Node2D, bomb: Node2D):
	if(!bomb.is_in_group(returner.name)):
		printerr(returner.name, "tried to return a bomb that is not owned by them")

	bomb.remove_from_group(returner.name)
	bomb.add_to_group("unowned")

func return_bomb_array(returner: Node2D, bomb_array: Array[Node2D]):
	for bomb in bomb_array:
		return_bomb(returner, bomb)
