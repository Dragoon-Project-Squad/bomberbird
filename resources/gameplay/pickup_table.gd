class_name PickupTable extends Resource
## contains probabilistic weight for each pickup that should spawn on a specific stage

const PICKUP_ENABLED: bool = true
const PICKUP_SPAWN_BASE_CHANCE: float = 1.0


@export_group("Pickup Weights")
@export var extra_bomb: int = 10
@export var explosion_boost: int = 5
@export var speed_boost: int = 5
@export var speed_down: int = 1
## BANNED IN MP - Absolutely unfun
@export var heart: int = 0
@export var max_explosion: int = 1
@export var punch_ability: int = 2
@export var throw_ability: int = 2
## BANNED IN MP
@export var wallthrough: int = 0
## BANNED IN MP - Absolutely not.
@export var timer: int = 0
## BANNED IN MP
@export var invincibility_vest: int = 0
@export var virus: int = 1
@export var kick: int = 2
## BANNED IN MP
@export var bombthrough: int = 0
@export var piercing_bomb: int = 1
@export var land_mine: int = 1
## BANNED IN MP
@export var remote_control: int = 0
#@export var seeker_bomb: int = 1
@export var mount_goon: int = 2

@export_group("Others")
## if are_amounts is true pickups will not be spawned by weights but instead in such a way that if possible exactly 'weight' amounts of each pickups are spawned
@export var are_amounts: bool = false
@export var base_pickup_spawn_chance: float = PICKUP_SPAWN_BASE_CHANCE

var pickup_spawn_chance = PICKUP_SPAWN_BASE_CHANCE
var pickup_weights: Dictionary = {}
var is_uptodate: bool = false # This is kinda hacky but _init() doesn't work for this
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init():
	self.resource_local_to_scene = true

## writes the weight variables into the pickup_weight dictionary
func update():
	pickup_weights = {
		globals.pickups.BOMB_UP: extra_bomb,
		globals.pickups.FIRE_UP: explosion_boost,
		globals.pickups.SPEED_UP: speed_boost,
		globals.pickups.SPEED_DOWN: speed_down,
		globals.pickups.HP_UP: heart,
		globals.pickups.FULL_FIRE: max_explosion,
		globals.pickups.BOMB_PUNCH: punch_ability,
		globals.pickups.POWER_GLOVE: throw_ability,
		globals.pickups.WALLTHROUGH: wallthrough,
		globals.pickups.FREEZE: timer,
		globals.pickups.INVINCIBILITY_VEST: invincibility_vest,
		globals.pickups.VIRUS: virus,
		globals.pickups.KICK: kick,
		globals.pickups.BOMBTHROUGH: bombthrough,
		globals.pickups.PIERCING: piercing_bomb,
		globals.pickups.MINE: land_mine,
		globals.pickups.REMOTE: remote_control,
		#globals.pickups.SEEKER: seeker_bomb,
		globals.pickups.MOUNTGOON: mount_goon
		}
	is_uptodate = true

## writes the pickup_weight dictonary into the variables
func reverse_update():
	if pickup_weights.has(globals.pickups.BOMB_UP):
		extra_bomb = pickup_weights[globals.pickups.BOMB_UP]
	if pickup_weights.has(globals.pickups.FIRE_UP):
		explosion_boost = pickup_weights[globals.pickups.FIRE_UP]
	if pickup_weights.has(globals.pickups.SPEED_UP):
		speed_boost = pickup_weights[globals.pickups.SPEED_UP]
	if pickup_weights.has(globals.pickups.SPEED_DOWN):
		speed_down = pickup_weights[globals.pickups.SPEED_DOWN]
	if pickup_weights.has(globals.pickups.HP_UP):
		heart = pickup_weights[globals.pickups.HP_UP]
	if pickup_weights.has(globals.pickups.FULL_FIRE):
		max_explosion = pickup_weights[globals.pickups.FULL_FIRE]
	if pickup_weights.has(globals.pickups.BOMB_PUNCH):
		punch_ability = pickup_weights[globals.pickups.BOMB_PUNCH]
	if pickup_weights.has(globals.pickups.POWER_GLOVE):
		throw_ability = pickup_weights[globals.pickups.POWER_GLOVE]
	if pickup_weights.has(globals.pickups.WALLTHROUGH):
		wallthrough = pickup_weights[globals.pickups.WALLTHROUGH]
	if pickup_weights.has(globals.pickups.FREEZE):
		timer = pickup_weights[globals.pickups.FREEZE]
	if pickup_weights.has(globals.pickups.INVINCIBILITY_VEST):
		invincibility_vest = pickup_weights[globals.pickups.INVINCIBILITY_VEST]
	if pickup_weights.has(globals.pickups.VIRUS):
		virus = pickup_weights[globals.pickups.VIRUS]
	if pickup_weights.has(globals.pickups.KICK):
		kick = pickup_weights[globals.pickups.KICK]
	if pickup_weights.has(globals.pickups.BOMBTHROUGH):
		bombthrough = pickup_weights[globals.pickups.BOMBTHROUGH]
	if pickup_weights.has(globals.pickups.PIERCING):
		piercing_bomb = pickup_weights[globals.pickups.PIERCING]
	if pickup_weights.has(globals.pickups.MINE):
		land_mine = pickup_weights[globals.pickups.MINE]
	if pickup_weights.has(globals.pickups.REMOTE):
		remote_control = pickup_weights[globals.pickups.REMOTE]
	#if pickup_weights.has(globals.pickups.SEEKER):
		#seeker_bomb = pickup_weights[globals.pickups.SEEKER]
	if pickup_weights.has(globals.pickups.MOUNTGOON):
		mount_goon = pickup_weights[globals.pickups.MOUNTGOON]

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
	if globals.is_singleplayer():
		pickup_spawn_chance = base_pickup_spawn_chance
		return
	if SettingsContainer.get_pickup_spawn_rule() == SettingsContainer.pickup_spawn_rule_setting_states.STAGE:
		pickup_spawn_chance = base_pickup_spawn_chance
		return # Use the value decided by the STAGE
	elif SettingsContainer.get_pickup_spawn_rule() == SettingsContainer.pickup_spawn_rule_setting_states.CUSTOM:
		# Custom Mode, use the Global Percent
		pickup_spawn_chance = SettingsContainer.get_pickup_chance()

func to_json() -> Dictionary:
	self.update()
	return {"weights": pickup_weights, "are_amounts": are_amounts, "base_pickup_spawn_chance": base_pickup_spawn_chance}

func from_json(pickup_table: Dictionary):
	for pickup in range(globals.pickups.NONE):
		match pickup:
			globals.pickups.GENERIC_COUNT: continue
			globals.pickups.GENERIC_BOOL: continue
			globals.pickups.GENERIC_EXCLUSIVE: continue
			globals.pickups.GENERIC_BOMB: continue

		if pickup_table.weights.has(str(pickup)):
			self.pickup_weights[pickup] = pickup_table.weights[str(pickup)]
		else: 
			self.pickup_weights[pickup] = 0
	self.reverse_update()
	self.is_uptodate = true
	self.are_amounts = pickup_table.are_amounts
	self.base_pickup_spawn_chance = pickup_table.base_pickup_spawn_chance
	
