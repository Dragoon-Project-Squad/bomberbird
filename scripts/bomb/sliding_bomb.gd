extends CharacterBody2D
class_name SlidingBomb

const TILESIZE: int = 32
enum {DISABLED, SLIDING, CHECKING, PLACING, ENUM_SIZE}
var state: int = DISABLED

#sliding state variables
var speed: float
var direction: Vector2i
var place_now: bool
var place_position: Vector2

var target: KinematicCollision2D
var bomb_root: BombRoot

func _ready() -> void:
	if get_parent() is BombRoot:
		bomb_root = get_parent()
	else:
		printerr("parent is not bombroot how did this happen?")
		return
	disable()

func disable() -> void:
	speed = 0.0
	direction = Vector2i.ZERO
	target = null
	place_now = false
	place_position = Vector2.ZERO
	self.visible = false
	self.position = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	set_state(DISABLED)

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
func slide_physics(delta: float):
	target = move_and_collide(Vector2(direction) * speed * delta)
	if target != null or place_now:
		bomb_root.global_position = self.global_position
		self.position = Vector2.ZERO
		set_state(CHECKING)

## called while the bomb is in the checking stage
func check_space():
	if place_now:
		set_state(PLACING)
		return
	if target == null:
		set_state(SLIDING)
	var collision := target.get_collider()
	if (
			collision is CollisionObject2D # everything inherits so just check this
			or collision.is_in_group("bombstop")
	):
		place_position = correct_coords(target.get_position())
		if collision is Bomb or collision is TileMapLayer:
			if direction == Vector2i.RIGHT or direction == Vector2i.DOWN:
				place_position -= Vector2(direction * TILESIZE)
		elif collision.has_method("do_stun"):
			collision.do_stun()
		elif collision.has_method("crush"):
			if collision is Breakable:
				place_position += Vector2(direction * TILESIZE)
			collision.crush()
		else:
			printerr("what the heck is this collision: ", collision)
		set_state(PLACING)

func to_stationary_bomb():
	if !is_multiplayer_authority():
		return
	self.remove_collision_exception_with(bomb_root.bomb_owner)
	$CollisionShape2D.set_deferred("disabled", true)
	bomb_root.do_place.rpc(place_position, -1, bomb_root.bomb_owner_is_dead)

#throw calculates the arch and starts a throw operations
@warning_ignore("shadowed_variable")
func slides(direction: Vector2i):
	self.add_collision_exception_with(bomb_root.bomb_owner)
	self.visible = true
	self.direction = direction
	speed = TILESIZE * 4
	$CollisionShape2D.set_deferred("disabled", false)
	set_state(SLIDING)

func correct_coords(current_coords: Vector2) -> Vector2:
	return world_data.tile_map.map_to_local(
		world_data.tile_map.local_to_map(current_coords)
	)

func halt():
	place_position = self.global_position
	self.place_now = true

# not sure to explode while in sliding state or ignore explosion
# function is set for when that happens
@rpc("call_local")
func exploded(_by_who):
	return
	#bomb_root.fuse_time_passed = 2.79
	#halt()
