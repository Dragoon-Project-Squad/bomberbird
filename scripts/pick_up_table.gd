extends Resource
class_name PickupTable

@export var pickup_weights: Dictionary = {
	"piercing_bomb": 0,
	"mine_bomb": 0,
	"remote_bomb": 0,
	"seeker_bomb": 0,
	"kick": 0,
	"bomb_through": 0,
	"virus": 0,
	"extra_bomb": 0,
	"explosion_boost": 0,
	"speed_boost": 0,
	"heart": 0,
	"max_explosion": 0,
	"punch_ability": 0,
	"throw_ability": 0,
	"wallthrough": 0,
	"timer": 0,
	"invincibility_vest": 0
	}

func total_weight() -> int:
	var sum = 0
	for key in pickup_weights.keys():
		sum += pickup_weights[key]
	return sum

func get_type_from_weight(weight: int) -> String:
	for key in pickup_weights.keys():
		weight -= pickup_weights[key]
		if weight <= 0: return key
	push_error("invalid weight value given to pickup_table")
	return ""
