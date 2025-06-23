class_name Boss extends Enemy

const TILE_SIZE: int = 32
const INVULNERABILITY_POWERUP_TIME: float = 16.0
const MAX_MOTION_SPEED: int = TILE_SIZE * 8
const MIN_MOTION_SPEED: int = TILE_SIZE * 2
@warning_ignore("INTEGER_DIVISION") #Note this integer division is fine idk why godot feels like it needs to warn for int divisions anyway?
const MOTION_SPEED_INCREASE: int = TILE_SIZE / 2
@warning_ignore("INTEGER_DIVISION") #Note this integer division is fine idk why godot feels like it needs to warn for int divisions anyway?
const MOTION_SPEED_DECREASE: int = TILE_SIZE / 2

@onready var bomb_carry_sprite: Sprite2D = $BombSprite

@export_subgroup("Boss variables")
@export var is_secret_boss: bool = false
@export var pickups: HeldPickups
@export var ability_detector: Area2D
@export var init_bomb_count: int = 1
@export var init_explosion_boost_count: int = 0
@export_enum(
	"extra_bomb",
	"explosion_boost",
	"speed_boost",
	"speed_down",
	"hearth",
	"max_explosion",
	"punch_ability",
	"throw_ability",
	"wallthrough",
	"timer",
	"invincibility_vest",
	"kick",
	"bombthrough",
	"piercing_bomb",
	"land_mine",
	"remote_control",
	"seeker_bomb",
	"no_pickup",
	) var dropped_pickup: String

var cooldown_done: bool = true
var curr_target: Node2D
var curr_bomb: BombRoot
var kicked_bomb: BombRoot
var bomb_to_throw: BombRoot

func place(pos: Vector2, path: String):
	super(pos, path)
	if(!is_multiplayer_authority()): return 1
	assert(ability_detector, "ability_detector must be assigned in the inspector")
	reset_pickups()
	if self.detection_handler: self.detection_handler.make_ready()
	self.cooldown_done = true
	self.statemachine.reset()
	init_pickups()

func init_pickups():
	for _speed_up in range(self.pickups.held_pickups[globals.pickups.SPEED_UP]):
		increase_speed()
	for _speed_down in range(self.pickups.held_pickups[globals.pickups.SPEED_UP]):
		decrease_speed()
	if self.pickups.held_pickups[globals.pickups.WALLTHROUGH]:
		enable_wallclip()
	if self.pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] == HeldPickups.exclusive.BOMBTHROUGH:
		enable_bombclip()
	if self.pickups.held_pickups[globals.pickups.INVINCIBILITY_VEST]:
		start_invul()

func _process(delta: float):
	if !damage_invulnerable:
		show()
		set_process(false)
		return
	invulnerable_remaining_time -= delta
	invulnerable_animation_time += delta
	if invulnerable_remaining_time <= 0:
		damage_invulnerable = false
		pickups.held_pickups[globals.pickups.INVINCIBILITY_VEST] = false
	elif invulnerable_animation_time <= INVULNERABILITY_FLASH_TIME:
		self.visible = !self.visible
		invulnerable_animation_time = 0

func get_current_bomb_count() -> int:
	return init_bomb_count + pickups.held_pickups[globals.pickups.BOMB_UP]

func get_current_bomb_boost() -> int:
	if pickups.held_pickups[globals.pickups.FULL_FIRE]:
		return init_explosion_boost_count + pickups.MAX_EXPLOSION_BOOSTS_PERMITTED
	return init_explosion_boost_count + pickups.held_pickups[globals.pickups.FIRE_UP]

@rpc("call_local")
func get_curr_mine_count() -> int:
	return 1 if self.pickups.held_pickups[globals.pickups.GENERIC_BOMB] == HeldPickups.bomb_types.MINE else 0
	
@rpc("call_local")
func increase_speed():
	movement_speed += MOTION_SPEED_INCREASE
	movement_speed = clamp(movement_speed, MIN_MOTION_SPEED, MAX_MOTION_SPEED)

@rpc("call_local")
func decrease_speed():
	movement_speed -= MOTION_SPEED_DECREASE
	movement_speed = clamp(movement_speed, MIN_MOTION_SPEED, MAX_MOTION_SPEED)

@rpc("call_local")
func enable_wallclip():
	self.set_collision_mask_value(3, false)

@rpc("call_local")
func enable_bombclip():
	self.set_collision_mask_value(4, false)

@rpc("call_local")
func disable_bombclip():
	self.set_collision_mask_value(4, true)

@rpc("call_local")
func start_invul():
	invulnerable_remaining_time = INVULNERABILITY_POWERUP_TIME
	damage_invulnerable = true
	set_process(true)

@rpc("call_local")
func exploded(by_whom: int):
	if invulnerable || damage_invulnerable: return 1
	if _exploded_barrier: return
	super(by_whom)
	if(self.health >= 1): return
	if !is_multiplayer_authority(): return
	var pickup_type: int = globals.get_pickup_type_from_name(self.dropped_pickup)
	if self.is_secret_boss:
		pass #TODO: unlock mint for this player

	if pickup_type == globals.pickups.NONE: return
	var curr_pos = self.position
	if globals.game.stage_done: return #if we entered the portal and the stage is disabled don't spawn the pickup
	var pickup: Pickup = globals.game.pickup_pool.request(pickup_type)
	var valid_pos: Vector2 = Vector2.ZERO
	var path: Array[Vector2] = world_data.get_path_to_empty_tile(curr_pos)
	if path.is_empty(): return
	valid_pos = path[-1]
	if valid_pos == Vector2.ZERO: return
	pickup.place.rpc(valid_pos, true)

func reset_pickups():
	self.bomb_carry_sprite.hide()
	damage_invulnerable = false
	self.set_collision_mask_value(4, true)
	self.set_collision_mask_value(3, true)
	pickups.reset()

func unvirus():
	pass

func stop_time(user: String, is_player: bool):
	if user == self.name && !is_player:
		self.pickups.held_pickups[globals.pickups.FREEZE] = false
		return
	self.time_is_stopped = true
