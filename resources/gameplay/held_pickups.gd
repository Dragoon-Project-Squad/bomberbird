class_name HeldPickups extends Resource
## holds information about which pickups a player has.

enum bomb_types {DEFAULT = 0, PIERCING, MINE, REMOTE, SEEKER}
enum exclusive {DEFAULT = 0, KICK, BOMBTHROUGH}
enum virus {DEFAULT = 0, SPEEDDOWN, SPEEDUP, FIREDOWN, SLOWFUSE_A, SLOWFUSE_B, FASTFUSE, AUTOBOMB, INVERSE_CONTROL, NON_STOP_MOTION, NOBOMBS}
enum mounts {DEFAULT = 0, PINK, CYAN, PURPLE, GREEN, RED} # see https://bomberman.fandom.com/wiki/Louies

const MAX_BOMB_UPGRADE_PERMITTED: int = 6
const MAX_EXPLOSION_BOOSTS_PERMITTED: int = 6
const MAX_SPEED_UP_PERMITTED: int = 99 #TODO Probably incorrect
const MAX_SPEED_DOWN_PERMITTED: int = 99 #TODO: Probably incorrect
const MAX_HEALTH_PERMITTED: int = 6

@export_group("inital pickups")
@export_enum("NONE", "PIERCING", "MINE", "REMOTE", "SEEKER") var initial_bomb_type: int = 0
@export_enum("NONE", "KICK", "BOMBTHROUGH") var initial_exlusive: int = 0
@export_enum("NONE", "SPEEDDOWN", "SPEEDUP", "FIREDOWN", "SLOWFUSE_A", "SLOWFUSE_B", "FASTFUSE", "AUTOBOMB", "INVERSE_CONTROL", "NON_STOP_MOTION", "NOBOMBS") var initial_virus: int = 0
@export_enum("NONE", "PINK", "CYAN", "PURPLE", "GREEN", "RED") var initial_mountgoon: int = 0
@export var initial_bomb_up: int = 0
@export var initial_fire_up: int = 0
@export var initial_speed_up: int = 0
@export var initial_speed_down: int = 0
@export var initial_hp_up: int = 0
@export var initial_full_fire: bool = false
@export var initial_bomb_punch: bool = false
@export var initial_power_glove: bool = false
@export var initial_wallthrough: bool = false
@export var initial_freeze: bool = false
@export var initial_invincibility_vest: bool = false

var held_pickups: Dictionary = {
	globals.pickups.GENERIC_BOMB: bomb_types.DEFAULT,
	globals.pickups.GENERIC_EXCLUSIVE: exclusive.DEFAULT,
	globals.pickups.VIRUS: virus.DEFAULT,
	globals.pickups.MOUNTGOON: mounts.DEFAULT, # this should maybe be changed to a enum with DEFAULT=0 being no mount
	globals.pickups.BOMB_UP: 0,
	globals.pickups.FIRE_UP: 0,
	globals.pickups.SPEED_UP: 0,
	globals.pickups.SPEED_DOWN: 0,
	globals.pickups.HP_UP: 0,
	globals.pickups.FULL_FIRE: false,
	globals.pickups.BOMB_PUNCH: false,
	globals.pickups.POWER_GLOVE: false,
	globals.pickups.WALLTHROUGH: false,
	globals.pickups.FREEZE: false,
	globals.pickups.INVINCIBILITY_VEST: false,
	}

func _init():
	self.resource_local_to_scene = true

## reset to the starting position of default pickups
func reset():
	held_pickups[globals.pickups.GENERIC_BOMB] = initial_bomb_type
	held_pickups[globals.pickups.GENERIC_EXCLUSIVE] = initial_exlusive
	held_pickups[globals.pickups.VIRUS] = initial_virus
	held_pickups[globals.pickups.BOMB_UP] = initial_bomb_up
	held_pickups[globals.pickups.FIRE_UP] = initial_fire_up
	held_pickups[globals.pickups.SPEED_UP] = initial_speed_up
	held_pickups[globals.pickups.SPEED_DOWN] = initial_speed_down
	held_pickups[globals.pickups.HP_UP] = initial_hp_up
	held_pickups[globals.pickups.FULL_FIRE] = initial_full_fire
	held_pickups[globals.pickups.BOMB_PUNCH] = initial_bomb_punch
	held_pickups[globals.pickups.POWER_GLOVE] = initial_power_glove
	held_pickups[globals.pickups.WALLTHROUGH] = initial_wallthrough
	held_pickups[globals.pickups.FREEZE] = initial_freeze
	held_pickups[globals.pickups.INVINCIBILITY_VEST] = initial_invincibility_vest
	held_pickups[globals.pickups.MOUNTGOON] = initial_mountgoon


## add a pickup to the players "inventory"
func add(pickup_type: int):
	assert(globals.is_valid_pickup(pickup_type))
	match pickup_type:
		globals.pickups.MINE:
			held_pickups[globals.pickups.GENERIC_BOMB] = bomb_types.MINE
		globals.pickups.REMOTE:
			held_pickups[globals.pickups.GENERIC_BOMB] = bomb_types.REMOTE
		globals.pickups.SEEKER:
			held_pickups[globals.pickups.GENERIC_BOMB] = bomb_types.SEEKER
		globals.pickups.VIRUS:
			held_pickups[pickup_type] = virus.values()[randi_range(virus.DEFAULT + 1, virus.NOBOMBS)]
		globals.pickups.BOMB_UP:
			held_pickups[pickup_type] = min(held_pickups[pickup_type] + 1, MAX_BOMB_UPGRADE_PERMITTED)
		globals.pickups.FIRE_UP:
			held_pickups[pickup_type] = min(held_pickups[pickup_type] + 1, MAX_EXPLOSION_BOOSTS_PERMITTED)
		globals.pickups.SPEED_UP:
			held_pickups[pickup_type] = min(held_pickups[pickup_type] + 1, MAX_SPEED_UP_PERMITTED)
		globals.pickups.SPEED_DOWN:
			held_pickups[pickup_type] = min(held_pickups[pickup_type] + 1, MAX_SPEED_DOWN_PERMITTED)
		globals.pickups.HP_UP:
			held_pickups[pickup_type] += 1
		globals.pickups.FULL_FIRE:
			held_pickups[pickup_type] = true
		globals.pickups.BOMB_PUNCH:
			held_pickups[globals.pickups.BOMB_PUNCH] = true
		globals.pickups.POWER_GLOVE:
			held_pickups[globals.pickups.POWER_GLOVE] = true
		globals.pickups.KICK:
			held_pickups[globals.pickups.GENERIC_EXCLUSIVE] = exclusive.KICK
		globals.pickups.BOMBTHROUGH:
			held_pickups[globals.pickups.GENERIC_EXCLUSIVE] = exclusive.BOMBTHROUGH
		globals.pickups.WALLTHROUGH:
			held_pickups[pickup_type] = true
		globals.pickups.PIERCING:
			held_pickups[globals.pickups.GENERIC_BOMB] = bomb_types.PIERCING
		globals.pickups.FREEZE:
			held_pickups[pickup_type] = true
		globals.pickups.INVINCIBILITY_VEST:
			held_pickups[pickup_type] = true
		globals.pickups.MOUNTGOON:
			held_pickups[pickup_type] = mounts.values()[randi_range(mounts.DEFAULT + 1, mounts.RED)]
		_:
			push_error("unknown pickup type... picked up")
