#BombRoot is responsible the handle any outside interaction with bombs or in otherwords if any outside object want to interact with a bomb it must call to a function in this file. BombRoot then may or may not change its state if nessessary (hence hand authority to another child node) and give the appropiate information to the appropiate child to handle the interaction.
extends Node2D

var bomb_owner: Node2D

enum {DISABLED, STATIONARY, AIRBORN, SLIDING, SIZE} #all states plus a SIZE constant that has to remain the last entry
var state: int = DISABLED #this is the authority if ever somehow two state nodes try to execute text_overrun_behavior

var state_map: Array[Node2D]

func _ready():
	state_map = [null, get_node("%StationaryBomb"), null, null] 
	set_state(DISABLED)	

func set_state(choice: int):
	assert(0 <= choice && choice < SIZE)
	if state_map[state] != null:
		state_map[state].disable()#old state should be disabled
		#state_map[state].set_process(false)
	state = choice

func disable() -> int:
	if state == DISABLED:
		return 1 #it might not be an issue if a disabled node is attempted to be disabled again so we just return an error and let the caller figure that out without giving a project wide error
	set_state(DISABLED)
	return 0

func set_bomb_owner(player: Node2D):
	bomb_owner = player

@rpc("call_local")
func do_place(bombPos: Vector2, boost: int):
	if bomb_owner == null:
		printerr("A bomb without an bomb_owner tried to be thrown")
		return 1
	if state == STATIONARY: #a bomb should not already be in a 
		printerr("do place is called from a wrong state")
		return 2

	set_state(STATIONARY)
	#state_map[state].set_process(true)
	var bomb_authority: Node2D = state_map[state]
	bomb_authority.set_explosion_width_and_size(min(boost + bomb_authority.explosion_width, bomb_authority.MAX_EXPLOSION_WIDTH))
	bomb_authority.pass_bomb_owner()
	bomb_authority.place(bombPos)


#!!!!!
# ALL FUNCTION FROM THIS POINT ARE EXAMPLES / NOT YET USED BY ANYTHING SO YOU ARE FREE TO COMPLETLY CHANGE THEM IF YOU IMPLEMENT ONE OF THEM PLEASE UPDATE THIS COMMENT TO REFLECT THIS
#!!!!!

func do_misobon_throw(origin: Vector2, target: Vector2, direction: Vector2i) -> int:
	if bomb_owner == null: #this should only be called by a misobon player hence the bomb must have an owner
		printerr("A bomb without an bomb_owner tried to be thrown")
		return 1
	if state != DISABLED: #this bomb has should just have been taken from the player pool. if not a fatal error has occured
		printerr("a misobon player wanted to throw a bomb that already has an active state")
		return 2

	set_state(AIRBORN)
	#TODO call the appropiate function to handle this in state_map[state]
	return 0 #errorcode 0 mean no error

func do_kick(target: Vector2, direction: Vector2i):
	if bomb_owner == null: #this should only be called by a misobon player hence the bomb must have an owner
		printerr("A bomb without an bomb_owner tried to be thrown")
		return 1
	#TODO make checks for state and change to AIRBORN state if allowed
	#TODO call the appropiate function to handle this in state_map[state]
	return 0 #errorcode 0 mean no error

func do_push(direction: Vector2i):
	if bomb_owner == null: #this should only be called by a misobon player hence the bomb must have an owner
		printerr("A bomb without an bomb_owner tried to be thrown")
		return 1

	#TODO make checks for state and change to SLIDING state if allowed
	#TODO call the appropiate function to handle this in state_map[state]
	return 0 #errorcode 0 mean no error

#And so on...
