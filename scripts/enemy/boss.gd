class_name Boss extends Enemy

const INVULNERABILITY_POWERUP_TIME: float = 16.0

@export_subgroup("Boss variables")
@export var pickups: HeldPickups
@export var init_bomb_count: int = 1
@export var init_explosion_boost_count: int = 0
@export var idle_chance: float = 0.4
@export var wander_distance: int = 8

var cooldown_done: bool = true
var curr_target: Node2D

func place(pos: Vector2, path: String):
	super(pos, path)
	if(!is_multiplayer_authority()): return 1
	if self.detection_handler: self.detection_handler.make_ready()

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

func get_current_bomb_count():
	return init_bomb_count + pickups.held_pickups[globals.pickups.BOMB_UP]

func get_current_bomb_boost():
	if pickups.held_pickups[globals.pickups.FULL_FIRE]:
		return init_explosion_boost_count + pickups.MAX_EXPLOSION_BOOSTS_PERMITTED
	return init_explosion_boost_count + pickups.held_pickups[globals.pickups.FIRE_UP]
	
@rpc("call_local")
func enable_wallclip():
	self.set_collision_mask_value(3, false)

@rpc("call_local")
func enable_bombclip():
	self.set_collision_mask_value(4, false)

@rpc("call_local")
func start_invul():
	invulnerable_remaining_time = INVULNERABILITY_POWERUP_TIME
	damage_invulnerable = true
	set_process(true)
