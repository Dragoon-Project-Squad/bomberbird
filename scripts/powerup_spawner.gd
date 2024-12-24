extends MultiplayerSpawner
var explosion_boost_powerup_scene = preload("res://scenes/pickups/explosion_boost.tscn")
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
	var rng_result = 1
	# TODO: Invent fun spawn table that has chances for different pickups
	match rng_result:
		1: pickup_type = "explosion_boost"
		_: pickup_type = "explosion_boost"
	return pickup_type
	
func spawn_chosen_pickup(ptype: String) -> Pickup:
	# TODO: Add other pickup types
	match ptype:
		"explosion_boost":
			var spawned_pickup = explosion_boost_powerup_scene.instantiate()
			return spawned_pickup
		_:
			var spawned_pickup = explosion_boost_powerup_scene.instantiate()
			return spawned_pickup
	
func _spawn_pickup(spawn_coords: Vector2i):
	# Decide if we spawn a pickup at all
	if !will_pickup_spawn():
		return
	# Decide which pickup should be spawned
	var pickup = spawn_chosen_pickup(random_pickup_type())
	pickup.position = spawn_coords
