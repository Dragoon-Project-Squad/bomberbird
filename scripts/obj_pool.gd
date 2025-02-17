# Interface for obj pools, contains functions that need to be implemented for a valid pool
class_name ObjectPool extends Node2D

var obj_spawner: MultiplayerSpawner
var spawn_data #This is set by a class child of ObjectPool, before it calls super()

@export var initial_spawn_count: int #set in the inspector or in the child that inherits ObjectPool

func _ready():
	create_reserve(initial_spawn_count)#Never liked inheritnece but note that if this is called with a super() from a child and that child implements create_reserve the childs version will be called (which is the intended behavior here)

func create_reserve(count: int): #creates a number of unowned obj's for the pool
	if !is_multiplayer_authority():
		return
	if spawn_data == null: push_error("spawn_data is not allowed to be null")
	for _i in range(count):
		var bomb = obj_spawner.spawn(spawn_data)
		bomb.add_to_group("unowned")
	

func request(caller: Node2D) -> Node2D: #This function is called if a caller needs a obj from the pool
	if spawn_data == null: push_error("spawn_data is not allowed to be null")
	var tree = get_tree()
	var obj = tree.get_nodes_in_group("unowned").pop_front()
	if obj == null: #no obj hence spawn one
		obj = obj_spawner.spawn(spawn_data)
	else:
		obj.remove_from_group("unowned")

	obj.add_to_group(caller.name)
	return obj

func request_array(caller: Node2D, count: int) -> Array[Node2D]:
	if spawn_data == null: push_error("spawn_data is not allowed to be null")
	var res: Array[Node2D] = []
	for i in range(count):
		res.push_back(request(caller))
	return res


func return_obj(returner: Node2D, obj: Node2D):
	if(!obj.is_in_group(returner.name)):
		printerr(returner.name, "tried to return a obj that is not owned by them")

	obj.remove_from_group(returner.name)
	obj.add_to_group("unowned")

func return_obj_array(returner: Node2D, obj_array: Array[Node2D]):
	for obj in obj_array:
		return_obj(returner, obj)
