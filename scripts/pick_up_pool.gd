class_name PickupPool extends ObjectPool

#NOTE: If we have a rate table for each pickup we could dynamically calculate the expected value to set initial spawn count
@export var initial_spawn_counts := {
		"explosion_boost": 0,
		"max_explosion": 0,
		"speed_boost": 0,
		"punch_ability": 0,
		"extra_bomb": 0
		}

func _ready():
	obj_spawner = get_node("PickupSpawner")
	unowned = {}
	for pickup_type in initial_spawn_counts.keys():
		create_reserve(initial_spawn_counts[pickup_type], pickup_type)
	super()

func create_reserve(count: int, pickup_type: String): #creates a number of unowned obj's for the pool
	if !is_multiplayer_authority():
		return
	if !initial_spawn_counts.has(pickup_type): 
		push_error("a pickup of unknown type has been requested from the pool, Type: ", pickup_type)
		return null
	unowned[pickup_type] = []
	for _i in range(count):
		unowned[pickup_type].push_back(obj_spawner.spawn(pickup_type))

func request(pickup_type: String) -> Pickup:
	if !initial_spawn_counts.has(pickup_type): 
		push_error("a pickup of unknown type has been requested from the pool, Type: ", pickup_type)
		return null
	var pickup: Pickup = unowned[pickup_type].pop_front()
		
	if pickup == null: #no obj hence spawn one
		pickup = obj_spawner.spawn(pickup_type)
		
	return pickup

func request_group(counts: Array[int], pickup_types: Array[String]) -> Dictionary:
	if counts.size() != pickup_types.size():
		push_error("pickup_type list must be as big as the count array")
		return {}
	
	var size: int = 0
	for count in counts: size += count
	var return_dict: Dictionary = {}

	for type_index in range(pickup_types.size()): 
		if counts[type_index] <= 0: continue
		
		var count: int = counts[type_index]
		var pickup_type = pickup_types[type_index]
		
		if !initial_spawn_counts.has(pickup_type):
			push_error("pickup_type no a valid type, Type: ", pickup_type)
			continue
		return_dict[pickup_type] = unowned[pickup_type].slice(0, count)
		
		for _i in range(counts[type_index] - return_dict[pickup_type].size()):
			return_dict[pickup_type].push_back(obj_spawner.spawn(pickup_type))
	
	return return_dict

func return_obj(pickup: Pickup) -> void:
	if !initial_spawn_counts.has(pickup.pickup_type):
		push_error("a pickup of unknown type has been return to the pool, Type: ", pickup.pickup_type)
		return
	if !unowned.has(pickup.pickup_type):
		unowned[pickup.pickup_type] = []
	unowned[pickup.pickup_type].push_back(pickup)

func return_obj_group(pickup_dict: Dictionary) -> void:
	for pickup_type in pickup_dict.keys():
		if !unowned.has(pickup_type):
			push_error("a pickup of unknown type has been return to the pool, Type: ", pickup_type)
			continue
		if !unowned.has(pickup_type):
			unowned[pickup_type] = []
			
		unowned[pickup_type].append_array(pickup_dict[pickup_type])
