extends CharacterBody2D
class_name Breakable


const PICKUP_ENABLED := true
const PICKUP_SPAWN_BASE_CHANCE := 1.0

@onready var breakable_sfx_player := $BreakableSound

var rng = RandomNumberGenerator.new()
var pickup_pool: PickupPool

func _ready():
	pickup_pool = globals.game.pickup_pool

func decide_pickup_spawn() -> bool:
	if !PICKUP_ENABLED:
		return false
	
	var rng_result = rng.randf_range(0.0,1.0)
	if rng_result <= PICKUP_SPAWN_BASE_CHANCE:
		return true
	else:
		return false
		
func decide_pickup_type() -> int:
	var pickup_table = globals.current_world.pickup_table
	var rng_result = rng.randi_range(0, pickup_table.total_weight())
	return pickup_table.get_type_from_weight(rng_result)
	
@rpc("call_local")
func exploded(by_who):
	# breakable_sfx_player.play()
	$"AnimationPlayer".play("explode")
	# Spawn a powerup where this rock used to be.

	if is_multiplayer_authority():
		if decide_pickup_spawn() && by_who != gamestate.ENVIRONMENTAL_KILL_PLAYER_ID:
			var type_of_pickup: int = decide_pickup_type()
			var pickup: Pickup = pickup_pool.request(type_of_pickup)
			pickup.place.rpc(self.position)
		else:
			world_data.set_tile.rpc(world_data.tiles.EMPTY, global_position) #We only wanne delete this cell if no pickup is spawned on it
			
	if is_multiplayer_authority():
		get_node("Shape").queue_free()
	astargrid_handler.astargrid_set_point(global_position, false)
	await $"AnimationPlayer".animation_finished #Wait for the animation to finish
	if is_multiplayer_authority():
		queue_free()
	
