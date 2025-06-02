class_name Boss extends Enemy

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

func get_current_bomb_count():
	return init_bomb_count + pickups.held_pickups[globals.pickups.BOMB_UP]

func get_current_bomb_boost():
	if pickups.held_pickups[globals.pickups.FULL_FIRE]:
		return init_explosion_boost_count + pickups.MAX_EXPLOSION_BOOSTS_PERMITTED
	return init_explosion_boost_count + pickups.held_pickups[globals.pickups.FIRE_UP]
	
