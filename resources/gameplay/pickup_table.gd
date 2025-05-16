class_name PickupTable extends Resource
## contains probabilistic weight for each pickup that should spawn on a specific stage
## TODO: also allow this to handle total amounts instead of probabalistic weights

const PICKUP_ENABLED := true
const PICKUP_SPAWN_BASE_CHANCE := 1.0
var pickup_spawn_chance = PICKUP_SPAWN_BASE_CHANCE

@export_group("Pickup Weights")
@export var extra_bomb: int = 500
@export var explosion_boost: int = 500
@export var speed_boost: int = 500
#@export var hearth: int = 0
@export var max_explosion: int = 100
@export var punch_ability: int = 200
#@export var throw_ability: int = 0
#@export var wallthrough: int = 0
#@export var timer: int = 0
#@export var invincibility_vest: int = 0
#@export var virus: int = 0
#@export var kick: int = 0
#@export var bombthrough: int = 0
@export var piercing_bomb: int = 500
#@export var land_mine: int = 0
#@export var remote_control: int = 0
#@export var seeker_bomb: int = 0

var are_amounts: bool = false
var pickup_weights: Dictionary = {}
var is_uptodate: bool = false # This is kinda hacky but _init() doesn't work for this
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init():
	self.resource_local_to_scene = true

## writes the weight variables into the pickup_weight dictunaty
func update():
	pickup_weights = {
		globals.pickups.BOMB_UP: extra_bomb,
		globals.pickups.FIRE_UP: explosion_boost,
		globals.pickups.SPEED_UP: speed_boost,
		#globals.pickups.HP_UP: health,
		globals.pickups.FULL_FIRE: max_explosion,
		globals.pickups.BOMB_PUNCH: punch_ability,
		#globals.pickups.POWER_GLOVE: throw_ability,
		#globals.pickups.WALLTHROUGH: wallthrough,
		#globals.pickups.FREEZE: timer,
		#globals.pickups.INVINCIBILITY_VEST: invincibility_vest,
		#globals.pickups.VIRUS: virus,
		#globals.pickups.KICK: kick,
		#globals.pickups.BOMBTHROUGH: bombthrough,
		globals.pickups.PIERCING: piercing_bomb,
		#globals.pickups.MINE: land_mine,
		#globals.pickups.REMOTE: remote_control,
		#globals.pickups.SEEKER: seeker_bomb,
		}
	is_uptodate = true

## writes the pickup_weight dictonary into the variables
func reverse_update():
	extra_bomb = pickup_weights[globals.pickups.BOMB_UP]
	explosion_boost = pickup_weights[globals.pickups.FIRE_UP]
	speed_boost = pickup_weights[globals.pickups.SPEED_UP]
	#hearth = pickup_weights[globals.pickups.HP_UP]
	max_explosion = pickup_weights[globals.pickups.FULL_FIRE]
	punch_ability = pickup_weights[globals.pickups.BOMB_PUNCH]
	#throw_ability = pickup_weights[globals.pickups.POWER_GLOVE]
	#wallthrough = pickup_weights[globals.pickups.WALLTHROUGH]
	#timer = pickup_weights[globals.pickups.FREEZE]
	#invincibility_vest = pickup_weights[globals.pickups.INVINCIBILITY_VEST]
	#virus = pickup_weights[globals.pickups.VIRUS]
	#kick = pickup_weights[globals.pickups.KICK]
	#bombthrough = pickup_weights[globals.pickups.BOMBTHROUGH]
	piercing_bomb = pickup_weights[globals.pickups.PIERCING]
	#land_mine = pickup_weights[globals.pickups.MINE]
	#remote_control = pickup_weights[globals.pickups.REMOTE]
	#seeker_bomb = pickup_weights[globals.pickups.SEEKER]

## calulates the total weight of all weights in the dict
func total_weight() -> int:
	if !is_uptodate:
		update()
	var sum = 0
	for key in pickup_weights.keys():
		sum += pickup_weights[key]
	return sum

## given a weight from 0 to 'total_weight()' returns the pickup this weight corresponts to
## ERROR behavior: if given a weight larger then total_weight() 
func get_type_from_weight(weight: int) -> int:
	# Note that according to the godot Doc a dictunary preserves the insertion order which makes this code valid
	for key in pickup_weights.keys():
		if pickup_weights[key] == 0: continue
		weight -= pickup_weights[key]
		if weight <= 0: return key
	push_error("invalid weight value given to pickup_table")
	return globals.pickups.NONE

func decide_pickup_spawn() -> bool:
	if !PICKUP_ENABLED:
		return false
	determine_base_pickup_rate()
	return _rng.randf_range(0.0,1.0) <= pickup_spawn_chance

func decide_pickup_type() -> int:
	var rng_result = _rng.randi_range(0, total_weight() - 1)
	return get_type_from_weight(rng_result)
	
func determine_base_pickup_rate() -> void:
	if SettingsContainer.get_pickup_spawn_rule() == 0:
		return # Use the value decided by the STAGE
	elif SettingsContainer.get_pickup_spawn_rule() == 1:
		pickup_spawn_chance = 0 # NONE
	elif SettingsContainer.get_pickup_spawn_rule() == 2:
		pickup_spawn_chance = 1 # ALL
	else: # Custom Mode, use the Global Percent
		pickup_spawn_chance = SettingsContainer.get_pickup_chance()
