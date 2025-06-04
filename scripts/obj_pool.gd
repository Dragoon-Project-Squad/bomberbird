## Interface for obj pools, contains functions that need to be implemented for a valid pool
class_name ObjectPool extends Node2D

var obj_spawner: MultiplayerSpawner
## keeps a reference of unowned object
## children of ObjectPool must manage owned on there own if needed
var unowned 

func _ready() -> void:
	pass

## creates a number of unowned obj's for the pool
## [param count] a data structure indicating an amount (default int)
## [param spawn_data] a data structure use to spawn the desired obj (used by the spawn function of the obj_spawner)
func create_reserve(count, spawn_data): 
	if !is_multiplayer_authority(): return
	unowned = []
	unowned.resize(count)
	if spawn_data == null: push_error("spawn_data is not allowed to be null")
	for i in range(count):
		unowned[i] = obj_spawner.spawn(spawn_data)
	
## Returns an Obj
## [param spawn_data] a data structure use to spawn the desired obj (used by the spawn function of the obj_spawner)
func request(spawn_data) -> Variant: 
	if !is_multiplayer_authority(): return
	if spawn_data == null: push_error("spawn_data is not allowed to be null")
	var obj = unowned.pop_front()
	if obj == null: #no obj hence spawn one
		obj = obj_spawner.spawn(spawn_data)
	
	return obj

## Returns a data_structure containing Obj (default an Array)
## [param count] a data structure indicating an amount (default int)
## [param spawn_data] a data structure use to spawn the desired obj (used by the spawn function of the obj_spawner)
func request_group(count, spawn_data) -> Variant:
	if !is_multiplayer_authority(): return
	if spawn_data == null: push_error("spawn_data is not allowed to be null")
	var res: Array[Node2D] = []
	for i in range(count):
		res.push_back(request(spawn_data))
	return res

## returns an obj to the pool
## [param obj] the obj to return
func return_obj(obj) -> void:
	if !is_multiplayer_authority(): return
	unowned.push_back(obj)

## returns an ammount of obj to the pool
## [param obj_array] a data structure of obj to return
func return_obj_group(obj_array) -> void:
	if !is_multiplayer_authority(): return
	if typeof(obj_array) != TYPE_ARRAY: push_error("return_obj_group expected an array")
	unowned.append_array(obj_array)
