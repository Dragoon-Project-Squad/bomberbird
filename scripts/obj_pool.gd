## Interface for obj pools, contains functions that need to be implemented for a valid pool
class_name ObjectPool extends Node2D

var obj_spawner: MultiplayerSpawner
var unowned #keeps a reference of unowned object
#children of ObjectPool must manage owned on there own if needed

func _ready() -> void:
	pass

func create_reserve(count, spawn_data): #creates a number of unowned obj's for the pool
	if !is_multiplayer_authority():
		return
	unowned = []
	unowned.resize(count)
	if spawn_data == null: push_error("spawn_data is not allowed to be null")
	for i in range(count):
		unowned[i] = obj_spawner.spawn(spawn_data)
	

func request(spawn_data) -> Variant: #This function is called if a caller needs a obj from the pool
	if spawn_data == null: push_error("spawn_data is not allowed to be null")
	var obj = unowned.pop_front()
	if obj == null: #no obj hence spawn one
		obj = obj_spawner.spawn(spawn_data)
	
	return obj

func request_group(count, spawn_data) -> Variant:
	if spawn_data == null: push_error("spawn_data is not allowed to be null")
	var res: Array[Node2D] = []
	for i in range(count):
		res.push_back(request(spawn_data))
	return res

func return_obj(obj) -> void:
	unowned.push_back(obj)

func return_obj_group(obj_array) -> void:
	if typeof(obj_array) != TYPE_ARRAY: push_error("return_obj_group expected an array")
	unowned.append_array(obj_array)
