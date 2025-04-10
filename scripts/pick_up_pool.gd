class_name PickupPool extends ObjectPool

@export_group("Initial Pickup Spawn Amount")
@export var extra_bomb: int = 0
@export var explosion_boost: int = 0
@export var speed_boost: int = 0
#@export var hearth: int = 0
@export var max_explosion: int = 0
@export var punch_ability: int = 0
#@export var throw_ability: int = 0
#@export var wallthrough: int = 0
#@export var timer: int = 0
#@export var invincibility_vest: int = 0
#@export var virus: int = 0
#@export var kick: int = 0
#@export var bombthrough: int = 0
#@export var piercing_bomb: int = 0
#@export var land_mine: int = 0
#@export var remote_control: int = 0
#@export var seeker_bomb: int = 0

#NOTE: If we have a rate table for each pickup we could dynamically calculate the expected value to set initial spawn count
@onready var initial_spawn_counts := {
	globals.pickups.BOMB_UP: extra_bomb,
	globals.pickups.FIRE_UP: explosion_boost,
	globals.pickups.SPEED_UP: speed_boost,
	#globals.pickups.HP_UP: hearth,
	globals.pickups.FULL_FIRE: max_explosion,
	globals.pickups.BOMB_PUNCH: punch_ability,
	#globals.pickups.POWER_GLOVE: throw_ability,
	#globals.pickups.WALLTHROUGH: wallthrough,
	#globals.pickups.FREEZE: timer,
	#globals.pickups.INVINCIBILITY_VEST: invincibility_vest,
	#globals.pickups.VIRUS: virus,
	#globals.pickups.KICK: kick,
	#globals.pickups.BOMBTHROUGH: bombthrough,
	#globals.pickups.PIERCING: piercing_bomb,
	#globals.pickups.MINE: land_mine,
	#globals.pickups.REMOTE: remote_control,
	#globals.pickups.SEEKER: seeker_bomb,
	}

func _ready():
	globals.game.pickup_pool = self
	obj_spawner = get_node("PickupSpawner")
	unowned = {}
	for pickup_type in initial_spawn_counts.keys():
		create_reserve(initial_spawn_counts[pickup_type], pickup_type)
	super()

func create_reserve(count: int, pickup_type: int): #creates a number of unowned obj's for the pool
	if !is_multiplayer_authority():
		return
	if !initial_spawn_counts.has(pickup_type): 
		push_error("a pickup of unknown type has been requested from the pool, Type: ", globals.pickup_name_str[pickup_type])
		return null
	unowned[pickup_type] = []
	unowned[pickup_type].resize(count)
	for i in range(count):
		unowned[pickup_type][i] = obj_spawner.spawn(pickup_type)

func request(pickup_type: int) -> Pickup:
	if !initial_spawn_counts.has(pickup_type): 
		push_error("a pickup of unknown type has been requested from the pool, Type: ", globals.pickup_name_str[pickup_type])
		return null
	var pickup: Pickup = unowned[pickup_type].pop_front()
		
	if pickup == null: #no obj hence spawn one
		pickup = obj_spawner.spawn(pickup_type)
		
	return pickup

func request_group(counts: Array[int], pickup_types: Array[int]) -> Dictionary:
	assert(counts.size() == pickup_types.size(), "pickup_type list must be as big as the count array")
	
	var size: int = 0
	for count in counts: size += count
	var return_dict: Dictionary = {}

	for type_index in range(pickup_types.size()): 
		if counts[type_index] <= 0: continue
		
		var count: int = counts[type_index]
		var pickup_type = pickup_types[type_index]
		assert(initial_spawn_counts.has(pickup_type), "pickup_type no a valid type, Type: " + str(pickup_type))
		
		var take: int = 0
		if unowned.has(pickup_type):
			take = min(count, unowned[pickup_type].size())
		return_dict[pickup_type] = []
		for _i in range(take):
			return_dict[pickup_type].push_back(unowned[pickup_type].pop_front())

		for _i in range(count - return_dict[pickup_type].size()):
			return_dict[pickup_type].push_back(obj_spawner.spawn(pickup_type))
	
	return return_dict

func return_obj(pickup: Pickup) -> void:
	assert(pickup, "null was attempted to be returned to the pickup_pool")
	assert(!pickup.visible)
	assert(pickup.position == Vector2.ZERO)
	if !initial_spawn_counts.has(pickup.pickup_type):
		push_error("a pickup of unknown type has been return to the pool, Type: ", globals.pickup_name_str[pickup.pickup_type])
		return
	if !unowned.has(pickup.pickup_type):
		unowned[pickup.pickup_type] = []
	assert(!(pickup in unowned[pickup.pickup_type]))
	unowned[pickup.pickup_type].push_back(pickup)

func return_obj_group(pickup_dict: Dictionary) -> void:
	for pickup_type in pickup_dict.keys():
		assert(pickup_dict[pickup_type].all(func (p: Pickup): return p != null), "null was attempted to be returned to the pickup_pool")
		assert(pickup_dict[pickup_type].all(func (p: Pickup): return !p.visible))
		assert(pickup_dict[pickup_type].all(func (p: Pickup): return p.position == Vector2.ZERO))
		if !initial_spawn_counts.has(pickup_type):
			push_error("a pickup of unknown type has been return to the pool, Type: ", globals.pickup_name_str[pickup_type])
			continue
		if !unowned.has(pickup_type):
			unowned[pickup_type] = []
			
		unowned[pickup_type].append_array(pickup_dict[pickup_type])
