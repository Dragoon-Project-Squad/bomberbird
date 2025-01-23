extends StaticBody2D

var in_area: Array = []
var from_player: int
var explosion_level: int = 3
var animation_finish = false
const TILE_SIZE = 48 #Primitive method of assigning correct tile size
#var TILE_SIZE: int = get_node("/root/World/Unbreakale").get_tileset().get_tile_size() #Would be cool but the match doesn't like non constants
@export var explosion_audio : AudioStreamWAV = load("res://sound/fx/explosion.wav")
@onready var explosion_sfx_player := $ExplosionSoundPlayer 
@onready var rays = $Raycasts

func _ready():
	explosion_sfx_player.set_stream(explosion_audio)
	$Timer.start()
	
func explode():
	explosion_sfx_player.play()

	for ray in rays.get_children():
		match ray.target_position:
			Vector2(0,TILE_SIZE):
				ray.target_position = Vector2(0,TILE_SIZE * (explosion_level))
				ray.force_raycast_update()
			Vector2(0,-TILE_SIZE):
				ray.target_position = Vector2(0,-TILE_SIZE * (explosion_level))
				ray.force_raycast_update()
			Vector2(TILE_SIZE,0):
				ray.target_position = Vector2(TILE_SIZE * (explosion_level), 0 )
				ray.force_raycast_update()
			Vector2(-TILE_SIZE,0):
				ray.target_position = Vector2(-TILE_SIZE * (explosion_level), 0 )
				ray.force_raycast_update()
		if ray.is_colliding():
			in_area.append(ray.get_collider())
		if not is_multiplayer_authority():
		# Explode only on authority.
			return
		for breakable in in_area:
			if breakable.has_method("exploded"):
				# Exploded can only be called by the authority, but will also be called locally.
				breakable.exploded.rpc(from_player)
				in_area.erase(ray.get_collider())

func done():
	if is_multiplayer_authority():
		queue_free()

func _on_bomb_body_enter(body):
	if not body in in_area:
		in_area.append(body) #Add this thing to list of things this bomb will explode

func _on_bomb_body_exit(body):
	in_area.erase(body) # Remove this thing from the list of things this bomb will explode
	
func _on_timer_timeout() -> void:
	var explosion_animation = ""
	explode()
	
	if explosion_level <= 3:
		explosion_animation = "explosion_small"
	elif explosion_level == 4:
		explosion_animation = "explosion_medium"
	else:
		explosion_animation = "explosion_large"
	print(explosion_animation)
	$AnimatedSprite2D.play(explosion_animation)
	if animation_finish:
		done()

func _on_detect_area_body_exit(body: Node2D) -> void:
	$CollisionShape2D.set_deferred("disabled", 0)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "idle":
		animation_finish = true
