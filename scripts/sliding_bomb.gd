extends Area2D

const TILESIZE: int = 32
enum {DISABLED, SLIDING, CHECKING, PLACING, ENUM_SIZE}
var state: int = DISABLED

#sliding state variables
var time: float
var origin: Vector2
var starting_speed: Vector2
var direction: Vector2i
var place_now: bool

var bomb_root: Node2D



func _ready() -> void:
	bomb_root = get_parent()
	disable()

func disable() -> void:
	time = 0
	starting_speed = Vector2.ZERO
	direction = Vector2i.ZERO
	place_now = false
	self.visible = false
	$CollisionShape2D.set_deferred("Disabled", 1)
	set_state(DISABLED)

#The use of physics process might be strange in a non physics body, but cause we check collisions in check_space() and collisions only update each physics frame its needed
func _physics_process(delta: float) -> void:
	match state:
		PLACING:
			to_stationary_bomb()
		CHECKING:
			if !check_bounds():
				check_space()
		SLIDING:
			slide_physics(delta)
		
## sets an internal state for airborn bomb
func set_state(new_state: int):
	assert(0 <= new_state && new_state < ENUM_SIZE)
	match new_state:
		DISABLED: # I wrote this and I hate it
			self.state = new_state
		SLIDING:
			if self.state == DISABLED || self.state == CHECKING:
				self.state = new_state
		CHECKING:
			if self.state == SLIDING:
				self.state = new_state
		PLACING:
			if self.state == CHECKING:
				self.state = new_state

## called while the bomb is in its sliding state
func slide_physics(delta):
	time = time + delta
	bomb_root.position = origin + starting_speed * time
	set_state(CHECKING)

## called while the bomb is in the checking stage
func check_space():
	$CollisionShape2D.set_deferred("Disabled", 0)
	var place := place_now
	for collision in get_overlapping_bodies():
		if collision is Player || collision is Enemy:
			collision.do_stun()
			place = true
		if collision is Breakable:
			collision.crush()
			place = true

	for collision in get_overlapping_areas():
		if collision is Pickup:
			collision.crush()

	if place:
		set_state(PLACING)
		return
	slides(bomb_root.position, direction)

## tells to root to change this bomb to a stationary bomb called when checking found a valid spot
func to_stationary_bomb():
	if !is_multiplayer_authority():
		return
	bomb_root.do_place.rpc(self.position, -1, bomb_root.bomb_owner_is_dead)

## called while the bomb is in the checking state. Checks specifically if the bomb is outside of the arena (in that case continue hopping, or change direction under special conditions) of if outside of the world in which case the bomb should wrap around to the other side of the world 
func check_bounds() -> bool:
	var bounds = world_data.is_out_of_bounds(bomb_root.position)

	if bounds == world_data.bounds.IN:
		return false # we are in the arena so do a space check

	if bounds == world_data.bounds.OUT_LEFT && direction.y != 0: # We are out of bound on the left but our direction is either up or down so bounce to the right
		slides(bomb_root.position, Vector2i.RIGHT)
		return true
	elif bounds == world_data.bounds.OUT_RIGHT && direction.y != 0: # We are out of bound on the right but our direction is either up or down so bounce to the left
		slides(bomb_root.position, Vector2i.LEFT)
		return true
	elif bounds == world_data.bounds.OUT_TOP && direction.x != 0: # We are out of bound on the top but our direction is either left or right so bounce to the down
		slides(bomb_root.position, Vector2i.DOWN)
		return true
	elif bounds == world_data.bounds.OUT_DOWN && direction.x != 0: # We are out of bound on the down but our direction is either left or right so bounce to the top
		slides(bomb_root.position, Vector2i.UP)
		return true
	elif !world_data.is_out_of_world_edge(bomb_root.position): # clearly we are not in bounds and we do not need to correct to a different direction hence just bounce along
		slides(bomb_root.position, direction)
		return true

	return true

#throw calculates the arch and starts a throw operations
@warning_ignore("shadowed_variable")
func slides(origin: Vector2, direction: Vector2i):
	bomb_root.position = origin
	self.visible = true
	self.time = 0
	self.direction = direction
	self.origin = origin
	starting_speed = direction * (TILESIZE * 2)
	set_state(SLIDING)
	
func halt():
	self.place_now = true
	set_state(CHECKING)
