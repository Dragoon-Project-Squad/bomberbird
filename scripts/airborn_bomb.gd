extends Area2D

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

#checking state variables
var arena_bounds: Array[Vector2]
var world_bounds: Array[Vector2]
var world_size: Vector2

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

func throw_physics(delta):
	time = time + delta
	if(time < time_total):
		bomb_root.position = origin + starting_speed * time + 0.5 * throw_gravity * time * time
		return
	bomb_root.position = target
	set_state(CHECKING)

func check_space():
	# Why in the name of Mint Fantome herself does Monitorable have to be one to detect collisions with TileMap I hate collisions
	# I've been at this for Hours :Grieve:
	$CollisionShape2D.set_deferred("Disabled", 0)
	if !has_overlapping_areas() && !has_overlapping_bodies():	
		set_state(PLACING)
		return
	var place: bool = true
	for collision in get_overlapping_bodies():
		if collision.is_in_group("thrown_bomb_bounces"):
			place = false
		if collision is Player:
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

func to_stationary_bomb():
	if !is_multiplayer_authority():
		return
	bomb_root.do_place.rpc(target, -1)

func check_bounds() -> bool:
	var in_arena_x: bool = arena_bounds[0].x < bomb_root.position.x && bomb_root.position.x < arena_bounds[1].x
	var in_arena_y: bool = arena_bounds[0].y < bomb_root.position.y && bomb_root.position.y < arena_bounds[1].y
	var in_world_x: bool = world_bounds[0].x < bomb_root.position.x && bomb_root.position.x < world_bounds[1].x
	var in_world_y: bool = world_bounds[0].y < bomb_root.position.y && bomb_root.position.y < world_bounds[1].y

	if in_arena_x && in_arena_y:
		return false #we are in the arena so do a space check

	if !in_arena_x && direction.x == 0:
		if arena_bounds[0].x >= bomb_root.position.x:
			throw(bomb_root.position, bomb_root.position + Vector2(Vector2i.RIGHT) * TILESIZE, Vector2i.RIGHT, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)
		else:
			throw(bomb_root.position, bomb_root.position + Vector2(Vector2i.LEFT) * TILESIZE, Vector2i.LEFT, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)
		return true

	if !in_arena_y && direction.y == 0:
		if arena_bounds[0].y >= bomb_root.position.y:
			throw(bomb_root.position, bomb_root.position + Vector2(Vector2i.DOWN) * TILESIZE, Vector2i.DOWN, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)
		else:
			throw(bomb_root.position, bomb_root.position + Vector2(Vector2i.UP) * TILESIZE, Vector2i.UP, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)
		return true

	if in_world_x && in_world_y:
		throw(bomb_root.position, bomb_root.position + Vector2(direction) * TILESIZE, direction, MISOBON_THROW_ANGLE_RAD, MISOBON_THROW_TIME / 2)
		return true #we have already found a problem so skip to after match

	wrap_around()
	return true


func wrap_around():
	bomb_root.position -= Vector2(direction) * world_size.dot(direction.abs())
	#print("wrap_position: ", bomb_root.position)


#throw calculates and starts a throw operations
func throw(origin: Vector2, target: Vector2, direction: Vector2i, angle_rad: float = MISOBON_THROW_ANGLE_RAD, time_total: float = MISOBON_THROW_TIME):
	#This should really be in _ready but that no worky
	var world: Node2D = get_node("/root/World")
	arena_bounds = world.get_arena_bounds()
	world_bounds = world.get_world_bounds()
	world_size = world.get_world_size()

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

func calculate_line(diff: Vector2):
	throw_gravity = Vector2.ZERO
	starting_speed = (diff.y / time_total) * direction
	
func calculate_arch(diff: Vector2, angle_rad: float):
	#calculating the starting velocity and total time needed for the throw
	starting_speed = Vector2(cos(angle_rad), sin(angle_rad)) * diff.x / (cos(angle_rad) * time_total)
	throw_gravity = 2 * (diff - starting_speed * time_total) * 1 / (time_total * time_total)
