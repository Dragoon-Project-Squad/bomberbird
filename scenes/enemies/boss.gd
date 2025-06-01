class_name Boss extends Enemy

@export_subgroup("Boss variables")
@export var pickups: HeldPickups
@export var init_bomb_count: int = 2
@export var init_explosion_boost_count: int = 0

func get_current_bomb_count():
	return init_bomb_count + pickups.held_pickups[globals.pickups.BOMB_UP]

func get_current_bomb_boost():
	if pickups.held_pickups[globals.pickups.FULL_FIRE]:
		return init_explosion_boost_count + pickups.MAX_EXPLOSION_BOOSTS_PERMITTED
	return init_explosion_boost_count + pickups.held_pickups[globals.pickups.FIRE_UP]
	
