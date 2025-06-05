extends Area2D

const TILESIZE: int = 32
enum {DISABLED, SLIDING, CHECKING, PLACING, ENUM_SIZE}
var state: int = DISABLED

#sliding state variables
var origin: Vector2
var starting_speed: float
var direction: Vector2i
var place_now: bool
var target: Vector2

var bomb_root: Node2D

func _ready() -> void:
	bomb_root = get_parent()
	disable()

func disable() -> void:
	starting_speed = 0.0
	direction = Vector2i.ZERO
	target = Vector2.ZERO
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
			check_space()
		SLIDING:
			slide_physics(delta)
		
## sets an internal state for airborn bomb
func set_state(new_state: int):
	assert(0 <= new_state && new_state < ENUM_SIZE)
	match new_state:
		DISABLED:
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
	bomb_root.position += Vector2(direction) * starting_speed * delta
	if target:
		if (target - bomb_root.position).dot(Vector2(direction)) <= 0:
			place_now = true
			set_state(CHECKING)
	else:
		set_state(CHECKING)

## called while the bomb is in the checking stage
func check_space():
	var in_bounds = world_data.is_out_of_bounds(bomb_root.position)
	if in_bounds != world_data.bounds.IN:
		match in_bounds:
			world_data.bounds.OUT_TOP:
				bomb_root.position += Vector2.DOWN * TILESIZE / 2
			world_data.bounds.OUT_DOWN:
				bomb_root.position += Vector2.UP * TILESIZE / 2
			world_data.bounds.OUT_LEFT:
				bomb_root.position += Vector2.RIGHT * TILESIZE / 2
			world_data.bounds.OUT_RIGHT:
				bomb_root.position += Vector2.LEFT * TILESIZE / 2
		place_now = true
	if place_now:
		set_state(PLACING)
		return
	$CollisionShape2D.set_deferred("Disabled", 0)
	for collision in get_overlapping_bodies():
		if (
				collision is Player
				or collision is Enemy
				or collision is Breakable
				or collision is Bomb
				or collision.is_in_group("bomb_stop")
		):
			target = collision.global_position
			if collision is Bomb:
				target -= Vector2(direction * TILESIZE)
			if collision.has_method("do_stun"):
				collision.do_stun()
			elif collision.has_method("crush"):
				collision.crush()

	for collision in get_overlapping_areas():
		if collision is Pickup:
			collision.crush()

	slides(bomb_root.position, direction)

## tells to root to change this bomb to a stationary bomb called when checking found a valid spot
func to_stationary_bomb():
	if !is_multiplayer_authority():
		return
	var corrected_cords = (
		world_data.tile_map.map_to_local(
			world_data.tile_map.local_to_map(bomb_root.position)
		)
	)
	bomb_root.do_place.rpc(corrected_cords, -1, bomb_root.bomb_owner_is_dead)

#throw calculates the arch and starts a throw operations
@warning_ignore("shadowed_variable")
func slides(origin: Vector2, direction: Vector2i):
	bomb_root.position = origin
	self.visible = true
	self.direction = direction
	self.origin = origin
	starting_speed = TILESIZE * 8
	set_state(SLIDING)

func halt():
	self.place_now = true

func exploded():
	print("i have exploded wao")
