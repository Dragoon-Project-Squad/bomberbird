extends Area2D

var in_area: Array = []
var from_player: int
var explosion_level: int = 1
@export var explosion_audio : AudioStreamWAV = load("res://sound/fx/explosion.wav")
@onready var explosion_sfx_player := $ExplosionSoundPlayer 
@onready var rays = $Raycasts

func _ready():
	explosion_sfx_player.set_stream(explosion_audio)
	$Timer.start()
# Called from the animation.
func _physics_process(delta: float) -> void:
	in_area = detect_rays()
	
func detect_rays() -> Array:
	
	var colliders = []
	var final_colliders = []
	
	for ray in rays.get_children():
		var initial_ray_cast_to = ray.cast_to
		for tile in explosion_level:
			ray.cast_to = initial_ray_cast_to * (Vector2.ONE * (tile + 1))
			if ray.is_colliding():
				var collider = ray.get_collider()
				colliders.append(collider)
				ray.add_exception(collider)
				ray.force_raycast_update()
			else:
				break

		for collider in colliders: # Loop through all the colliders.
			if not collider in final_colliders: # If the collider is not in the "final_colliders" array...
				final_colliders.append(collider)
	return final_colliders
func explode():
	explosion_sfx_player.play()
	if not is_multiplayer_authority():
		# Explode only on authority.
		return
	for p in in_area:
		if p.has_method("exploded"):
			# Checks if there is wall in between bomb and the object
			var world_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
			var query := PhysicsRayQueryParameters2D.create(position, p.position)
			query.hit_from_inside = true
			var result: Dictionary  = world_state.intersect_ray(query)
			if not result.collider is TileMapLayer:
				# Exploded can only be called by the authority, but will also be called locally.
				p.exploded.rpc(from_player)

func done():
	if is_multiplayer_authority():
		queue_free()

func _on_bomb_body_enter(body):
	if not body in in_area:
		in_area.append(body) #Add this thing to list of things this bomb will explode

func _on_bomb_body_exit(body):
	in_area.erase(body) # Remove this thing from the list of things this bomb will explode
	
func _on_timer_timeout() -> void:
	print("explode")
	explode()
	done()

func _on_bomb_collision_area_2d_body_exited(body: Node2D) -> void:
	print("exited")
	$BombCollisionBody2D.set_deferred("process_mode", 0)
