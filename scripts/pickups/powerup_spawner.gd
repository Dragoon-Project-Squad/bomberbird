extends MultiplayerSpawner
const EXPLOSION_BOOST_PICKUP_SCENE_PATH : String = "res://scenes/pickups/explosion_boost.tscn"
const MAX_EXPLOSION_PICKUP_SCENE_PATH : String = "res://scenes/pickups/max_explosion.tscn"
const SPEED_BOOST_PICKUP_SCENE_PATH : String = "res://scenes/pickups/speed_boost.tscn"
const SPEED_DOWN_PICKUP_SCENE_PATH : String = "res://scenes/pickups/speed_down.tscn"
const PUNCH_ABILITY_PICKUP_SCENE_PATH : String = "res://scenes/pickups/punch_ability.tscn"
const EXTRA_BOMB_PICKUP_SCENE_PATH : String = "res://scenes/pickups/extra_bomb.tscn"
const WALL_CLIP_PICKUP_SCENE_PATH : String = "res://scenes/pickups/wall_clip.tscn"
const BOMB_CLIP_PICKUP_SCENE_PATH : String = "res://scenes/pickups/bomb_clip.tscn"
const PIERCING_BOMB_PICKUP_SCENE_PATH : String = "res://scenes/pickups/piercing_bomb.tscn"
const LAND_MINE_PICKUP_SCENE_PATH : String = "res://scenes/pickups/land_mine.tscn"
const THROW_BOMB_PICKUP_SCENE_PATH : String = "res://scenes/pickups/throw_bomb.tscn"
const INVUL_PICKUP_SCENE_PATH : String = "res://scenes/pickups/invul_star.tscn"
const VIRUS_PICKUP_SCENE_PATH : String = "res://scenes/pickups/virus.tscn"
const KICK_PICKUP_SCENE_PATH: String = "res://scenes/pickups/kick_ability.tscn"
const PICKUP_SPAWN_RATE = 0.1


func _init():
	spawn_function = _spawn_pickup
	
func spawn_chosen_pickup(ptype: int) -> Pickup:
	assert(globals.is_valid_pickup(ptype))
	var spawned_pickup
	# TODO: Add other pickup types
	match ptype:
		globals.pickups.FIRE_UP:
			spawned_pickup = preload(EXPLOSION_BOOST_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.FULL_FIRE:
			spawned_pickup = preload(MAX_EXPLOSION_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.SPEED_UP:
			spawned_pickup = preload(SPEED_BOOST_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.SPEED_DOWN:
			spawned_pickup = preload(SPEED_DOWN_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.BOMB_PUNCH:
			spawned_pickup = preload(PUNCH_ABILITY_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.BOMB_UP:
			spawned_pickup = preload(EXTRA_BOMB_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.WALLTHROUGH:
			spawned_pickup = preload(WALL_CLIP_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.BOMBTHROUGH:
			spawned_pickup = preload(BOMB_CLIP_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.PIERCING:
			spawned_pickup = preload(PIERCING_BOMB_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.MINE:
			spawned_pickup = preload(LAND_MINE_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.POWER_GLOVE:
			spawned_pickup = preload(THROW_BOMB_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.INVINCIBILITY_VEST:
			spawned_pickup = preload(INVUL_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.VIRUS:
			spawned_pickup = preload(VIRUS_PICKUP_SCENE_PATH).instantiate()
		globals.pickups.KICK:
			spawned_pickup = preload(KICK_PICKUP_SCENE_PATH).instantiate()
		_:
			push_error("invalid pickup type passed to the spawn function")
			spawned_pickup = preload(EXPLOSION_BOOST_PICKUP_SCENE_PATH).instantiate()
	return spawned_pickup
	
func _spawn_pickup(data):
	if typeof(data) != TYPE_INT:
		push_error("Invalid Pickup data: ", data)
	var pickup = spawn_chosen_pickup(data)
	pickup.pickup_type = data
	pickup.disable()
	return pickup
