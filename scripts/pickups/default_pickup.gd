class_name Pickup extends Area2D

signal pickup_destroyed

enum {DISABLED, AIRBORN, CHECKING, PLACING, PLACED, ENUM_SIZE}

const THROW_TIME: float = 0.3
const THROW_ANGLE_RAD: float = - PI / 8

@onready var pickup_sfx: AudioStreamWAV = load("res://sound/fx/powerup.wav")
@onready var explosion_sfx: AudioStreamWAV = load("res://sound/fx/explosion.wav")
@onready var pickup_sfx_player: AudioStreamPlayer = $PickupSoundPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collisionbox: CollisionShape2D = $CollisionShape2D

#throwing state variables
var time: float
var time_total: float
var throw_gravity: Vector2
var target: Vector2
var origin: Vector2
var starting_speed: Vector2
var direction: Vector2i
var state: int = DISABLED

var indestructable: bool = false
var _pickup_pick_up_barrier: bool = false
var in_use: bool = false
var pickup_type: int = globals.pickups.NONE:
	set(type): #i don't like setters but it only enforces something here so its okey
		assert(globals.is_valid_pickup(type))
		if pickup_type != globals.pickups.NONE:
			push_error("private member pickup_type should only be overwritten once")
		pickup_type = type

func _ready():
	hide()
	self.position = Vector2.ZERO
	pass

@rpc("call_local")
func disable_collison_and_hide():
	hide()
	world_data.set_tile(world_data.tiles.EMPTY, self.global_position)
	collisionbox.set_deferred("disabled", 1)

@rpc("call_local")
func enable_collison():
	collisionbox.set_deferred("disabled", 0)

@rpc("call_local")
func disable():
	hide()
	self.position = Vector2.ZERO
	self.indestructable = false
	process_mode = PROCESS_MODE_DISABLED
	self.in_use = false
	self.time = 0
	self.time_total = 0
	self.throw_gravity = Vector2.ZERO
	self.target = Vector2.ZERO
	self.starting_speed = Vector2.ZERO
	self.direction = Vector2i.ZERO
	set_state(DISABLED)

func enable():
	in_use = true
	process_mode = PROCESS_MODE_INHERIT
	_pickup_pick_up_barrier = false
	enable_collison()
	show()

@rpc("call_local")
func place(pos: Vector2, indestructable: bool = false):
	self.indestructable = indestructable
	self.position = pos
	world_data.set_tile(world_data.tiles.PICKUP, self.global_position)
	set_state(PLACED)
	enable()

## applies the power up to the player handed to it
func apply_power_up(_pickup_owner: Node2D):
	pass #default pickup has no effect

## if the body is a player proceed to cause the effect this pickup causes
func _on_body_entered(body: Node2D) -> void:
	if !is_multiplayer_authority(): return # Activate only on authority.
	if !(body is Player) && !(body is Boss):
		if body is SlidingBomb:
			self.crush()
		else:
			return
	if self.state != PLACED: return
	if _pickup_pick_up_barrier: return
	_pickup_pick_up_barrier = true
	self.pickup_destroyed.emit()
	#Prevent anyone else from colliding with this pickup
	pickup_sfx_player.stream = pickup_sfx
	pickup_sfx_player.play()
	disable_collison_and_hide.rpc()
	
	var pickup_owner = body
	pickup_owner.pickups.add(pickup_type)
	apply_power_up(pickup_owner)
	
	# Ensure powerup has time to play before pickup is destroyed
	await pickup_sfx_player.finished
	disable_collison_and_hide.rpc()
	disable.rpc()
	globals.game.pickup_pool.return_obj.call_deferred(self) #Pickup returns itself to the pool

@rpc("call_local")
## called when this pickup is destroyed by an explosion players the corresponding animation and sound
func exploded(_from_player):
	if self.indestructable: return
	self.pickup_destroyed.emit()
	disable_collison_and_hide()
	if $anim:
		$anim.play("pickup/explode_pickup")
		pickup_sfx_player.stream = explosion_sfx
		pickup_sfx_player.play()
		await $anim.animation_finished
		if pickup_sfx_player.playing:
			await pickup_sfx_player.finished
		if globals.game.stage_done: return # if stage finished in the meantime just terminate here
	disable()
	globals.game.pickup_pool.return_obj(self) #Pickup returns itself to the pool

@rpc("call_local")
## called when a pickup is destroyed by something that is not an explosion
func crush():
	self.pickup_destroyed.emit()
	disable_collison_and_hide()
	disable()
	globals.game.pickup_pool.return_obj(self) #Pickup returns itself to the pool


## sets an internal state for throw pickup
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
		PLACED:
			if self.state == PLACING || self.state == DISABLED:
				self.state = new_state

func _physics_process(delta: float) -> void:
	match state:
		PLACING:
			place(self.position)
		CHECKING:
			if !check_bounds():
				check_space()
		AIRBORN:
			throw_physics(delta)

## called while the bomb is in its airborn state will find the next position in the precalculated arch
func throw_physics(delta):
	time = time + delta
	if(time < time_total):
		self.position = origin + starting_speed * time + 0.5 * throw_gravity * time * time
		return
	self.position = target
	set_state(CHECKING)

func check_space():
	# Why in the name of Mint Fantome herself does Monitorable have to be one to detect collisions with TileMap I hate collisions
	# I've been at this for Hours :Grieve:
	if !has_overlapping_areas() && !has_overlapping_bodies():
		set_state(PLACING)
		return
	var place_now: bool = true
	for collision in get_overlapping_bodies():
		if collision.is_in_group("thrown_pickup_bounces"):
			place_now = false

	for collision in get_overlapping_areas():
		if collision.is_in_group("thrown_pickup_bounces"):
			place_now = false

	if place_now:
		set_state(PLACING)
		return
	throw(self.position, self.position + Vector2(self.direction) * world_data.tile_map.tile_set.tile_size.x, direction, THROW_ANGLE_RAD, THROW_TIME / 2)

## called while the bomb is in the checking state. Checks specifically if the bomb is outside of the areana (in that case continue hopping, or change direction under special conditions) of if outside of the world in which case the bomb should wrap around to the other side of the world 
func check_bounds() -> bool:
	var bounds = world_data.is_out_of_bounds(self.position)

	if bounds == world_data.bounds.IN:
		return false #we are in the arena so do a space check

	if bounds == world_data.bounds.OUT_LEFT && direction.y != 0: # We are out of bound on the left but our direction is either up or down so bounce to the right
		throw(self.position, self.position + Vector2(Vector2i.RIGHT) * world_data.tile_map.tile_set.tile_size.x, Vector2i.RIGHT, PI / 8, self.time_total / 2)
		return true
	elif bounds == world_data.bounds.OUT_RIGHT && direction.y != 0: # We are out of bound on the right but our direction is either up or down so bounce to the left
		throw(self.position, self.position + Vector2(Vector2i.LEFT) * world_data.tile_map.tile_set.tile_size.x, Vector2i.LEFT, PI / 8, self.time_total / 2)
		return true
	elif bounds == world_data.bounds.OUT_TOP && direction.x != 0: # We are out of bound on the top but our direction is either left or right so bounce to the down 
		throw(self.position, self.position + Vector2(Vector2i.DOWN) * world_data.tile_map.tile_set.tile_size.x, Vector2i.DOWN, PI / 8, self.time_total / 2)
		return true
	elif bounds == world_data.bounds.OUT_DOWN && direction.x != 0: # We are out of bound on the down but our direction is either left or right so bounce to the top
		throw(self.position, self.position + Vector2(Vector2i.UP) * world_data.tile_map.tile_set.tile_size.x, Vector2i.UP, PI / 8, self.time_total / 2)
		return true
	elif !world_data.is_out_of_world_edge(self.position): #clearly we are not in bounds and we do not need to correct to a different direction hence just bounce along
		throw(self.position, self.position + Vector2(direction) * world_data.tile_map.tile_set.tile_size.x, direction, PI / 8, self.time_total / 2)
		return true

	wrap_around() #clearly we are outside the world_edge hence we wrap
	return true

## wraps the bomb_root position to the other side of the defind world
func wrap_around():
	self.position -= Vector2(self.direction) * Vector2(world_data.world_edge_width, world_data.world_edge_height).dot(direction.abs()) * world_data.tile_map.tile_set.tile_size.x

@rpc("call_local")
## an alternative to place
func throw(origin: Vector2, target: Vector2, direction: Vector2i, angle_rad: float = THROW_ANGLE_RAD, time_total: float = THROW_TIME):
	collisionbox.set_deferred("Disabled", 0)
	self.position = origin
	in_use = true
	process_mode = PROCESS_MODE_INHERIT
	show()
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
