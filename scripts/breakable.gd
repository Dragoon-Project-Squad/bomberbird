extends CharacterBody2D
@onready var breakable_sfx_player := $BreakableSound
const PICKUP_ENABLED := true
const PICKUP_SPAWN_BASE_CHANCE := 1.0

func decide_pickup_spawn() -> bool:
	if !PICKUP_ENABLED:
		return false
	var rng = RandomNumberGenerator.new()
	var rng_result = rng.randf_range(0.0,1.0)
	if rng_result <= PICKUP_SPAWN_BASE_CHANCE:
		return true
	else:
		return false
		
func decide_pickup_type() -> String:
	var pickup_type
	var rng = RandomNumberGenerator.new()
	var rng_result = rng.randi_range(1,4)
	# TODO: Invent fun spawn table that has chances for different pickups
	match rng_result:
		1: pickup_type = "explosion_boost"
		2: pickup_type = "max_explosion"
		3: pickup_type = "speed_boost"
		4: pickup_type = "extra_bomb"
		5: pickup_type = "punch_ability"
		_: pickup_type = "explosion_boost"
	return pickup_type
	
@rpc("call_local")
func exploded(_by_who):
	#breakable_sfx_player.play()
	#$"../../Score".increase_score(by_who) Rocks don't count for score
	$"AnimationPlayer".play("explode")
	# Spawn a powerup where this rock used to be.
	if is_multiplayer_authority():
		if decide_pickup_spawn():
			var type_of_pickup = decide_pickup_type()
			get_node("/root/World/PickupSpawner").spawn({"spawnpoint": self.position, "pickuptype": type_of_pickup})
	get_node("Shape").queue_free()
	await $"AnimationPlayer".animation_finished #Wait for the animation to finish
	queue_free()
