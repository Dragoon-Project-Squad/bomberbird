extends Area2D
## handles a bomb thrown in an arch. Does the actual calculation and processing for the arch but does not handle fuse time or explosions

const MISOBON_THROW_TIME: float = 0.3
const MISOBON_THROW_ANGLE_RAD: float = - PI / 8
const TILESIZE: int = 32
enum {DISABLED, AIRBORN, CHECKING, PLACING, ENUM_SIZE}
var state: int = DISABLED

#throwing state variables
var time: float
var time_total: float
var throw_gravity: Vector2
var target: Vector2
var origin: Vector2
var starting_speed: Vector2
var direction: Vector2i

var bomb_root: Node2D


func _ready() -> void:
	bomb_root = get_parent()
	disable()

func disable() ->void:
	time = 0
	time_total = 0
	throw_gravity = Vector2.ZERO
	target = Vector2.ZERO
	starting_speed = Vector2.ZERO
	direction = Vector2i.ZERO
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
		AIRBORN:
			throw_physics(delta)
		
## sets an internal state for airborn bomb
func set_state(new_state: int):
	assert(0 <= new_state && new_state <= ENUM_SIZE)
	match new_state:
		DISABLED: #I wrote this and I hate it
			self.state = new_state
		AIRBORN:
			if self.state == DISABLED || self.state == CHECKING:
				self.state = new_state
		CHECKING:
			if self.state == AIRBORN:
				self.state = new_state
		PLACING:
			if self.state == CHECKING:
				self.state = new_state

## called while the bomb is in its airborn state will find the next position in the precalculated arch
func throw_physics(delta):
	time = time + delta
	if(time < time_total):
		bomb_root.position = origin + starting_speed * time + 0.5 * throw_gravity * time * time
		return
	bomb_root.position = target
	set_state(CHECKING)

## called while the bomb is in the checking stage. Hence the bomb has completed its arch and now checks whenever its has landed in a valid spot
func check_space():
	# Why in the name of Mint Fantome herself does Monitorable have to be one to detect collisions with TileMap I hate collisions
	# I've been at this for Hours :Grieve:
	if !has_overlapping_areas() && !has_overlapping_bodies():
		set_state(PLACING)
		return
	var place: bool = true
	for collision in get_overlapping_bodies():
		if collision.is_in_group("thrown_bomb_bounces"):
			place = false
		if collision is Player || collision is Enemy:
			collision.do_stun()

	for collision in get_overlapping_areas():
		if collision.is_in_group("thrown_bomb_bounces"):
			place = false
		if collision is Pickup:
			collision.crush()

	if place:
		set_state(PLACING)
		return
	throw(bomb_root.position, bomb_root.position + Vector2(direction) * TILESIZE, direction, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)

## tells to root to change this bomb to a stationary bomb called when checking found a valid spot
func to_stationary_bomb():
	if !is_multiplayer_authority():
		return
	bomb_root.do_place.rpc(target, -1, bomb_root.bomb_owner_is_dead)

## called while the bomb is in the checking state. Checks specifically if the bomb is outside of the areana (in that case continue hopping, or change direction under special conditions) of if outside of the world in which case the bomb should wrap around to the other side of the world 
func check_bounds() -> bool:
	var bounds = world_data.is_out_of_bounds(bomb_root.position)

	if bounds == world_data.bounds.IN:
		return false #we are in the arena so do a space check

	if bounds == world_data.bounds.OUT_LEFT && direction.y != 0: # We are out of bound on the left but our direction is either up or down so bounce to the right
		throw(bomb_root.position, bomb_root.position + Vector2(Vector2i.RIGHT) * TILESIZE, Vector2i.RIGHT, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)
		return true
	elif bounds == world_data.bounds.OUT_RIGHT && direction.y != 0: # We are out of bound on the right but our direction is either up or down so bounce to the left
		throw(bomb_root.position, bomb_root.position + Vector2(Vector2i.LEFT) * TILESIZE, Vector2i.LEFT, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)
		return true
	elif bounds == world_data.bounds.OUT_TOP && direction.x != 0: # We are out of bound on the top but our direction is either left or right so bounce to the down 
		throw(bomb_root.position, bomb_root.position + Vector2(Vector2i.DOWN) * TILESIZE, Vector2i.DOWN, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)
		return true
	elif bounds == world_data.bounds.OUT_DOWN && direction.x != 0: # We are out of bound on the down but our direction is either left or right so bounce to the top
		throw(bomb_root.position, bomb_root.position + Vector2(Vector2i.UP) * TILESIZE, Vector2i.UP, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)
		return true
	elif !world_data.is_out_of_world_edge(bomb_root.position): #clearly we are not in bounds and we do not need to correct to a different direction hence just bounce along
		throw(bomb_root.position, bomb_root.position + Vector2(direction) * TILESIZE, direction, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)
		return true

	wrap_around() #clearly we are outside the world_edge hence we wrap
	return true

## wraps the bomb_root position to the other side of the defind world
func wrap_around():
	bomb_root.position -= Vector2(direction) * Vector2(world_data.world_edge_width, world_data.world_edge_height).dot(direction.abs()) * TILESIZE

#throw calculates the arch and starts a throw operations
func throw(origin: Vector2, target: Vector2, direction: Vector2i, angle_rad: float = MISOBON_THROW_ANGLE_RAD, time_total: float = MISOBON_THROW_TIME):
	$CollisionShape2D.set_deferred("Disabled", 0)
	bomb_root.position = origin
	self.visible = true
	var corrected_target = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(target))
	self.time = 0
	self.time_total = time_total
	self.direction = direction
	self.target = corrected_target
	self.origin = origin
	var diff: Vector2 = (corrected_target - origin)

	match direction:
		Vector2i.RIGHT:
			calculate_arch(diff, angle_rad)
		Vector2i.DOWN:
			calculate_line(diff.abs())
		Vector2i.LEFT:
			angle_rad = PI - angle_rad
			calculate_arch(diff, angle_rad)
		Vector2i.UP:
			calculate_line(diff.abs())
		_:
			push_error("throw must be handed a valid direction (UP, DOWN, LEFT o RIGHT) not: ", direction)
			return

	set_state(AIRBORN)

## in case of a down= or upwards throw the arch in just a straigh line
func calculate_line(diff: Vector2):
	throw_gravity = Vector2.ZERO
	starting_speed = (diff.y / time_total) * direction
	
## calculating the starting velocity and total time needed for the throw
func calculate_arch(diff: Vector2, angle_rad: float):
	starting_speed = Vector2(cos(angle_rad), sin(angle_rad)) * diff.x / (cos(angle_rad) * time_total)
	throw_gravity = 2 * (diff - starting_speed * time_total) * 1 / (time_total * time_total)
