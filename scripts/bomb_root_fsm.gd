#BombRoot is responsible the handle any outside interaction with bombs or in otherwords if any outside object want to interact with a bomb it must call to a function in this file. BombRoot then may or may not change its state if nessessary (hence hand authority to another child node) and give the appropiate information to the appropiate child to handle the interaction.
class_name BombRoot extends Node2D

var bomb_owner: Node2D
# checks if the player has been dead at the time they placed the bomb
var bomb_owner_is_dead: bool
# remembers the time the bomb already cooked
var fuse_time_passed: float
# stores the boost s.t. it is remembered even during transition to for example airborn (punched) state
var boost: int

enum {DISABLED, STATIONARY, AIRBORN, SLIDING, SIZE} #all states plus a SIZE constant that has to remain the last entry
var state: int = DISABLED #this is the authority if ever somehow two state nodes try to execute text_overrun_behavior

var state_map: Array[Node2D]

func _ready():
	state_map = [null, get_node("%StationaryBomb"), get_node("%AirbornBomb"), null] #Whenever a future state is implemented update this (for e.g. if someone implements push into a new childmake sure this child is loaded into state_map[SLIDING]
	set_state(DISABLED)	
	for state_node in state_map:
		if state_node != null:
			state_node.process_mode = Node.PROCESS_MODE_DISABLED

func set_state(choice: int):
	assert(0 <= choice && choice < SIZE)
	if state_map[state] != null:
		state_map[state].disable()#old state should be disabled
		state_map[state].process_mode = Node.PROCESS_MODE_DISABLED
	state = choice
	if state_map[state] != null:
		state_map[state].process_mode = Node.PROCESS_MODE_INHERIT

@rpc("call_local")
func disable() -> int:
	if state == DISABLED:
		return 1 #it might not be an issue if a disabled node is attempted to be disabled again so we just return an error and let the caller figure that out without giving a project wide error
	bomb_owner = null
	bomb_owner_is_dead = false
	self.position = Vector2.ZERO
	self.fuse_time_passed = 0
	set_state(DISABLED)
	return 0

@rpc("call_local")
func set_bomb_owner(player_id: String):
	bomb_owner = globals.player_manager.get_node(str(player_id))

@rpc("call_local")
func do_place(bombPos: Vector2, boost: int = boost, is_dead: bool = false) -> int:
	if bomb_owner == null:
		printerr("A bomb without an bomb_owner tried to be placed")
		return 1

	var force_collision: bool = false

	match state:
		STATIONARY: #a bomb should not already be in the STATIONARY state when it is getting placed
			printerr("do place is called from a wrong state")
			return 2
		AIRBORN:
			force_collision = true #If it state is airborn we do now want the collision ignore logic to work rather we want the bomb to collied immediately

	set_state(STATIONARY)
	
	bomb_owner_is_dead = is_dead

	if boost < 0:
		boost = self.boost
	elif self.boost == 0:
		self.boost = boost

	var bomb_authority: Node2D = state_map[state]
	bomb_authority.set_explosion_width_and_size(min(boost + bomb_authority.explosion_width, bomb_authority.MAX_EXPLOSION_WIDTH))
	bomb_authority.place(bombPos, fuse_time_passed)
	world_data.set_tile(world_data.tiles.BOMB, self.global_position)
	if force_collision: bomb_authority._on_detect_area_body_exit(bomb_owner) # This sucks but i haven't found a better way to solve this... I think we need to rework how bombs stay collision less for the placing player at some point
	return 0

@rpc("call_local")
func do_misobon_throw(origin: Vector2, target: Vector2, direction: Vector2i, is_dead: bool = true) -> int:
	if bomb_owner == null: #this should only be called by a misobon player hence the bomb must have an owner
		printerr("A bomb without an bomb_owner tried to be thrown")
		return 1
	if state != DISABLED: #this bomb has should just have been taken from the player pool. if not a fatal error has occured
		printerr("a misobon player wanted to throw a bomb that already has an active state")
		return 2

	set_state(AIRBORN)
	bomb_owner_is_dead = is_dead
	var bomb_authority: Node2D = state_map[state]
	bomb_authority.throw(origin, target, direction)

	return 0

@rpc("call_local")
func do_punch(direction: Vector2i):
	if bomb_owner == null: #this should only be called by a misobon player hence the bomb must have an owner
		printerr("A bomb without an bomb_owner tried to be thrown")
		return 1
	if state != STATIONARY: #this bomb has should just have been taken from the player pool. if not a fatal error has occured
		printerr("a player wanted to punch a bomb that already has an active state")
		return 2

	fuse_time_passed = state_map[state].get_node("AnimationPlayer").current_animation_position

	set_state(AIRBORN)
	bomb_owner_is_dead = false
	var bomb_authority: Node2D = state_map[state]
	bomb_authority.throw(
		self.position,
		self.position + 3 * world_data.tile_map.tile_set.tile_size.x * Vector2(direction),
		direction,
		-PI / 6,
		0.4
	)
	world_data.set_tile(world_data.tiles.EMPTY, self.global_position)

	return 0


#!!!!!
# ALL FUNCTION FROM THIS POINT ARE EXAMPLES / NOT YET USED BY ANYTHING SO YOU ARE FREE TO COMPLETLY CHANGE THEM IF YOU IMPLEMENT ONE OF THEM PLEASE UPDATE THIS COMMENT TO REFLECT THIS
#!!!!!


func do_kick(target: Vector2, direction: Vector2i):
	if bomb_owner == null: #this should only be called by a misobon player hence the bomb must have an owner
		printerr("A bomb without an bomb_owner tried to be thrown")
		return 1
	#TODO make checks for state and change to ??? state if allowed
	#TODO call the appropiate function to handle this in state_map[state]
	return 0 #errorcode 0 mean no error


#And so on...
