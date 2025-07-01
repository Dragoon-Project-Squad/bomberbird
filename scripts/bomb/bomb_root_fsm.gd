#BombRoot is responsible the handle any outside interaction with bombs or in otherwords if any outside object want to interact with a bomb it must call to a function in this file. BombRoot then may or may not change its state if nessessary (hence hand authority to another child node) and give the appropiate information to the appropiate child to handle the interaction.
class_name BombRoot extends CharacterBody2D

signal bomb_finished

var bomb_owner: Node2D
# checks if the player has been dead at the time they placed the bomb
var bomb_owner_is_dead: bool
# remembers the time the bomb already cooked
var fuse_time_passed: float:
	set(value): # make sure fuse doesn't go past animation
		fuse_time_passed = minf(value, 2.79)
		fuse_time_passed = maxf(0, fuse_time_passed)
# stores the boost s.t. it is remembered even during transition to for example airborn (punched) state
var boost: int
var in_use: bool = false

# other bomb addons
var type: int
const FUSES = {
	NORMAL = 1.0,
	SLOW_A = 0.50,
	SLOW_B = 0.75,
	FAST = 2.0
}
var fuse_length := FUSES.NORMAL
var cell_number: int

enum {DISABLED, STATIONARY, AIRBORN, SLIDING, SIZE} #all states plus a SIZE constant that has to remain the last entry
var state: int = DISABLED #this is the authority if ever somehow two state nodes try to execute text_overrun_behavior

var state_map: Array[Node2D]

func _ready():
	state_map = [null, get_node("%StationaryBomb"), get_node("%AirbornBomb"), get_node("%SlidingBomb"), null] #Whenever a future state is implemented update this (for e.g. if someone implements push into a new childmake sure this child is loaded into state_map[SLIDING]
	set_state(DISABLED)	
	for state_node in state_map:
		if state_node != null:
			state_node.process_mode = Node.PROCESS_MODE_DISABLED

## sets the state to a given state. If the node representing this state in 'state_map' is not null will attempt to call disable on it and set its process_mode to disabled aswell
func set_state(choice: int):
	assert(0 <= choice && choice < SIZE)
	if state_map[state] != null:
		state_map[state].disable() #old state should be disabled
		state_map[state].process_mode = Node.PROCESS_MODE_DISABLED
	state = choice
	if state_map[state] != null:
		state_map[state].process_mode = Node.PROCESS_MODE_INHERIT

@rpc("call_local")
## disables this bomb so that it can be returned to the pool
func disable() -> int:
	if state == DISABLED:
		return 1 #it might not be an issue if a disabled node is attempted to be disabled again so we just return an error and let the caller figure that out without giving a project wide error
	self.in_use = false
	self.bomb_owner = null
	self.bomb_owner_is_dead = false
	self.boost = 0
	self.position = Vector2.ZERO
	self.fuse_time_passed = 0
	self.type = HeldPickups.bomb_types.DEFAULT
	for sig_dict in bomb_finished.get_connections():
		sig_dict.signal.disconnect(sig_dict.callable)
	set_state(DISABLED)
	return 0

## sets the bomb_owner of the bomb s.t. the bomb can later report to that player
@rpc("call_local")
func set_bomb_owner(player_id: String):
	if player_id == "": 
		self.bomb_owner = null
		return
	self.bomb_owner = globals.player_manager.get_node(str(player_id))

@rpc("call_local")
func  set_bomb_number(number: int):
	if number >= 0:
		cell_number = number

## sets the addon
@rpc("call_local")
func set_bomb_type(bomb_type: int):
	self.type = bomb_type

@rpc("call_local")
func set_fuse_length(length: float = 1.0):
	fuse_length = length

# sets the state to stationary and tells the corresponding state to start processing
@rpc("call_local")
@warning_ignore("SHADOWED_VARIABLE")
func do_place(bombPos: Vector2, boost: int = self.boost, is_dead: bool = false) -> int:
	var force_collision: bool = false

	match state:
		STATIONARY: #a bomb should not already be in the STATIONARY state when it is getting placed
			printerr("do place is called from a wrong state")
			return 2
		AIRBORN:
			force_collision = true #If it state is airborn we do now want the collision ignore logic to work rather we want the bomb to collied immediately
		SLIDING:
			force_collision = false

	set_state(STATIONARY)
	in_use = true
	
	bomb_owner_is_dead = is_dead

	if boost < -1: #this is wack
		boost = self.boost
	else:
		self.boost = boost

	var bomb_authority: Node2D = state_map[state]
	bomb_authority.set_explosion_width_and_size(min(boost + bomb_authority.explosion_width, bomb_authority.MAX_EXPLOSION_WIDTH))
	bomb_authority.set_bomb_type(type)
	bomb_authority.place(bombPos, fuse_time_passed, force_collision)
	if self.type == HeldPickups.bomb_types.MINE:
		world_data.set_tile(world_data.tiles.MINE, self.global_position, self.boost + 2, false)
	else:
		world_data.set_tile(world_data.tiles.BOMB, self.global_position, boost + 2, type == HeldPickups.bomb_types.PIERCING)
	if force_collision: return 0
	return 0

@rpc("call_local")
## used to throw a bomb as a misobon character, changes the bomb into the throw state with predefind values
func do_misobon_throw(origin: Vector2, target: Vector2, direction: Vector2i, is_dead: bool = true) -> int:
	if bomb_owner == null: #this should only be called by a misobon player hence the bomb must have an owner
		printerr("A bomb without an bomb_owner tried to be thrown")
		return 1
	if state != DISABLED: #this bomb has should just have been taken from the player pool. if not a fatal error has occured
		printerr("a misobon player wanted to throw a bomb that already has an active state")
		return 2

	in_use = true
	set_state(AIRBORN)
	bomb_owner_is_dead = is_dead
	var bomb_authority: Node2D = state_map[state]
	bomb_authority.throw(origin, target, direction)

	return 0

@rpc("call_local")
func do_punch(direction: Vector2i):
	if state != STATIONARY: #this bomb has should just have been taken from the player pool. if not a fatal error has occured
		printerr("a player wanted to punch a bomb that already has an active state")
		return 2
	if self.type == HeldPickups.bomb_types.MINE:
		return 1

	in_use = true
	fuse_time_passed = state_map[state].get_node("AnimationPlayer").current_animation_position

	set_state(AIRBORN)
	bomb_owner_is_dead = false
	var bomb_authority: Node2D = state_map[state]
	bomb_authority.throw(
		self.position,
		self.position + 2 * world_data.tile_map.tile_set.tile_size.x * Vector2(direction),
		direction,
		-PI / 6,
		0.4
	)
	world_data.set_tile(world_data.tiles.EMPTY, self.global_position)
	return 0

@rpc("call_local")
func do_throw(direction: Vector2i, new_position: Vector2):
	if state != AIRBORN: #this bomb has should just have been taken from the player pool. if not a fatal error has occured
		printerr("a player wanted to throw a bomb that already has an active state")
		return 2
	
	self.position = new_position
	in_use = true
	bomb_owner_is_dead = false
	var bomb_authority: Node2D = state_map[state]
	bomb_authority.throw(
		self.position,
		self.position + 3 * world_data.tile_map.tile_set.tile_size.x * Vector2(direction),
		direction,
		-PI / 6,
		0.4
	)
	return 0

@rpc("call_local")
func carry():
	if state != DISABLED:
		return
	if self.type == HeldPickups.bomb_types.MINE:
		return
	self.in_use = false # this might be a problem if world reset happens while a player is carrying a bomb causing this bomb not be be reset properly
	set_state(AIRBORN)

@rpc("call_local")
func boss_carry(): # boss just be build different ig
	if state != DISABLED && state != STATIONARY:
		return
	if self.type == HeldPickups.bomb_types.MINE:
		return
	world_data.set_tile(world_data.tiles.EMPTY, self.global_position)	
	set_state(AIRBORN)

@rpc("call_local")
func do_kick(direction: Vector2i):
	if state != STATIONARY:
		printerr("Bomb already active")
		return 2
	if self.type == HeldPickups.bomb_types.MINE:
		return 1
	
	in_use = true
	bomb_owner_is_dead = false
	fuse_time_passed = state_map[state].get_node("AnimationPlayer").current_animation_position
	set_state(SLIDING)
	var bomb_auth := state_map[state]
	bomb_auth.slides(direction)
	world_data.set_tile(world_data.tiles.EMPTY, self.global_position)	
	return 0

@rpc("call_local")
func stop_kick():
	if state != SLIDING:
		printerr("Bomb not sliding but attempted to call stop_kick()")
		return 2
	var bomb_auth := state_map[state]
	bomb_auth.halt()
	return 0
