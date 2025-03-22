class_name PickupTable extends Resource

@export_group("Pickup Weigths")
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


var pickup_weights: Dictionary = {}
var initialized: bool = false # This is kinda hacky but _init() doesn't work for this

func _init():
	self.resource_local_to_scene = true

func init():
	pickup_weights = {
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
	initialized = true

func total_weight() -> int:
	if !initialized:
		init()
	var sum = 0
	for key in pickup_weights.keys():
		sum += pickup_weights[key]
	return sum

func get_type_from_weight(weight: int) -> int:
	for key in pickup_weights.keys():
		if pickup_weights[key] == 0: continue
		weight -= pickup_weights[key]
		if weight <= 0: return key
	push_error("invalid weight value given to pickup_table")
	return globals.pickups.NONE
