extends MultiplayerSpawner
const EXPLOSION_BOOST_PICKUP_SCENE_PATH : String = "res://scenes/pickups/explosion_boost.tscn"
const MAX_EXPLOSION_PICKUP_SCENE_PATH : String = "res://scenes/pickups/max_explosion.tscn"
const SPEED_BOOST_PICKUP_SCENE_PATH : String = "res://scenes/pickups/speed_boost.tscn"
const PUNCH_ABILITY_PICKUP_SCENE_PATH : String = "res://scenes/pickups/punch_ability.tscn"
const EXTRA_BOMB_PICKUP_SCENE_PATH : String = "res://scenes/pickups/extra_bomb.tscn"
const PICKUP_SPAWN_RATE = 0.1

func _init():
	spawn_function = _spawn_pickup

func will_pickup_spawn() -> bool:
	# TODO: Make this have a random chance of spawning a pickup
	if (PICKUP_SPAWN_RATE != 0.1):
		return false
	return true

func random_pickup_type() -> String:
	var pickup_type
	var rng = RandomNumberGenerator.new()
	var rng_result = rng.randi_range(1,3)
	# TODO: Invent fun spawn table that has chances for different pickups
	match rng_result:
		1: pickup_type = "explosion_boost"
		2: pickup_type = "max_explosion"
		3: pickup_type = "speed_boost"
		4: pickup_type = "punch_ability"
		5: pickup_type = "extra_bomb"
		_: pickup_type = "explosion_boost"
	return pickup_type
	
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
	
func _spawn_pickup(spawn_coords: Vector2):
	# Decide if we spawn a pickup at all
	if !will_pickup_spawn():
		return
	# Decide which pickup should be spawned
	var pickup = spawn_chosen_pickup(random_pickup_type())
	pickup.position = spawn_coords
	return pickup
