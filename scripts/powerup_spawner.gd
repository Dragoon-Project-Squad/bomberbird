extends MultiplayerSpawner
const EXPLOSION_BOOST_PICKUP_SCENE_PATH : String = "res://scenes/pickups/explosion_boost.tscn"
const MAX_EXPLOSION_PICKUP_SCENE_PATH : String = "res://scenes/pickups/max_explosion.tscn"
const SPEED_BOOST_PICKUP_SCENE_PATH : String = "res://scenes/pickups/speed_boost.tscn"
const PUNCH_ABILITY_PICKUP_SCENE_PATH : String = "res://scenes/pickups/punch_ability.tscn"
const EXTRA_BOMB_PICKUP_SCENE_PATH : String = "res://scenes/pickups/extra_bomb.tscn"
const PICKUP_SPAWN_RATE = 0.1

func _init():
	spawn_function = _spawn_pickup
	
func spawn_chosen_pickup(ptype: String) -> Pickup:
	var spawned_pickup
	# TODO: Add other pickup types
	match ptype:
		"explosion_boost":
			spawned_pickup = preload(EXPLOSION_BOOST_PICKUP_SCENE_PATH).instantiate()
		"max_explosion":
			spawned_pickup = preload(MAX_EXPLOSION_PICKUP_SCENE_PATH).instantiate()
		"speed_boost":
			spawned_pickup = preload(SPEED_BOOST_PICKUP_SCENE_PATH).instantiate()
		"punch_ability":
			spawned_pickup = preload(PUNCH_ABILITY_PICKUP_SCENE_PATH).instantiate()
		"extra_bomb":
			spawned_pickup = preload(EXTRA_BOMB_PICKUP_SCENE_PATH).instantiate()
		_:
			spawned_pickup = preload(EXPLOSION_BOOST_PICKUP_SCENE_PATH).instantiate()
	return spawned_pickup
	
func _spawn_pickup(data):
	if typeof(data) != TYPE_STRING:
		push_error("Invalid Pickup data: ", data)
	var pickup = spawn_chosen_pickup(data)
	pickup.pickup_type = data
	pickup.disable()
	return pickup
