class_name HeldPickups extends Resource
## holds information about which pickups a player has.

enum bomb_types {DEFAULT, PIERCING, MINE, REMOTE, SEEKER}
enum exclusive {DEFAULT, KICK, BOMBTHROUGH}
enum virus {DEFAULT, SPEEDDOWN, SPEEDUP, FIREDOWN, SLOWFUSE_A, SLOWFUSE_B, FASTFUSE, AUTOBOMB, INVERSE_CONTROL, NON_STOP_MOTION, NOBOMBS, SIZE}

var held_pickups: Dictionary = {
	globals.pickups.GENERIC_BOMB: bomb_types.DEFAULT,
	globals.pickups.MINE: bomb_types.MINE,
	globals.pickups.GENERIC_EXCLUSIVE: exclusive.DEFAULT,
	globals.pickups.VIRUS: virus.DEFAULT,
	globals.pickups.BOMB_UP: 0,
	globals.pickups.FIRE_UP: 0,
	globals.pickups.SPEED_UP: 0,
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

## reset to the starting position of no pickups
## IMPORTANT: THIS MAY NOT RESET THE EFFECTS CAUSED BY THE PICKUPS SUCH AS A SPEED INCREASE AS THOSE ARE HANDLED SEPERATLY BUT BOOLEAN PICKUPS MAY ALREADY BE RESET BY THIS
func reset():
	held_pickups[globals.pickups.GENERIC_BOMB] = bomb_types.DEFAULT
	held_pickups[globals.pickups.GENERIC_EXCLUSIVE] = exclusive.DEFAULT
	held_pickups[globals.pickups.VIRUS] = virus.DEFAULT
	held_pickups[globals.pickups.BOMB_UP] = 0
	held_pickups[globals.pickups.FIRE_UP] = 0
	held_pickups[globals.pickups.SPEED_UP] = 0
	held_pickups[globals.pickups.HP_UP] = 0
	held_pickups[globals.pickups.FULL_FIRE] = false
	held_pickups[globals.pickups.BOMB_PUNCH] = false
	held_pickups[globals.pickups.POWER_GLOVE] = false
	held_pickups[globals.pickups.WALLTHROUGH] = false
	held_pickups[globals.pickups.FREEZE] = false
	held_pickups[globals.pickups.INVINCIBILITY_VEST] = false

## add a pickup to the players "inventory"
func add(pickup_type: int, virus_type: int = 0):
	assert(globals.is_valid_pickup(pickup_type))
	if(virus_type < 0 || virus.SIZE <= virus_type):
		push_error("Invalid virus type given")
	match pickup_type:
		globals.pickups.MINE:
			held_pickups[globals.pickups.GENERIC_BOMB] = bomb_types.MINE
		globals.pickups.REMOTE:
			held_pickups[globals.pickups.GENERIC_BOMB] = bomb_types.REMOTE
		globals.pickups.SEEKER:
			held_pickups[globals.pickups.GENERIC_BOMB] = bomb_types.SEEKER
		globals.pickups.VIRUS:
			held_pickups[pickup_type] = virus_type
		globals.pickups.BOMB_UP:
			held_pickups[pickup_type] += 1
		globals.pickups.FIRE_UP:
			held_pickups[pickup_type] += 1
		globals.pickups.SPEED_UP:
			held_pickups[pickup_type] += 1
		globals.pickups.HP_UP:
			held_pickups[pickup_type] += 1
		globals.pickups.FULL_FIRE:
			held_pickups[pickup_type] = true
		globals.pickups.BOMB_PUNCH:
			held_pickups[pickup_type] = true
		globals.pickups.POWER_GLOVE:
			held_pickups[pickup_type] = true
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
		_:
			push_error("unknown pickup type... picked up")
