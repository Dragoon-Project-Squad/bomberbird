extends StaticBody2D

var from_player: int
var player: Node2D
var explosion_width := 2
const MAX_EXPLOSION_WIDTH := 8
var animation_finish := false
const TILE_SIZE = 32 #Primitive method of assigning correct tile size
#var TILE_SIZE: int = get_node("/root/World/Unbreakale").get_tileset().get_tile_size() #Would be cool but the match doesn't like non constants
@export var explosion_audio : AudioStreamWAV = load("res://sound/fx/explosion.wav")
@onready var explosion_sfx_player := $ExplosionSoundPlayer 
@onready var rays = $Raycasts
@onready var bombsprite := $BombSprite
@onready var explosion = $Explosion
@onready var tileMap = get_tree().get_root().get_node("World/Floor")

func _ready():
	explosion_sfx_player.set_stream(explosion_audio)
	player = get_node("/root/World/Players/" + str(from_player))
	
func detonate():
	explosion_sfx_player.play()
	var exp_range = {Vector2i.RIGHT: explosion_width, Vector2i.DOWN: explosion_width, Vector2i.LEFT: explosion_width, Vector2i.UP: explosion_width}
	for ray in rays.get_children():
		ray.target_position = ray.get_meta("direction") * explosion_width * TILE_SIZE
		ray.force_raycast_update()
		if !ray.is_colliding():
			print(ray.get_meta("direction"), " hit nothing")
			continue
		var target: Node2D = ray.get_collider()
		if target.is_in_group("bombstop"):
			var col_point = to_local(ray.get_collision_point()) + Vector2(ray.get_meta("direction") * (TILE_SIZE / 2)) #Note this integer division is fine idk why godot feels like it needs to warn for int divisions anyway?
			
			exp_range[ray.get_meta("direction")] = explosion.get_node("SpriteTileMap").local_to_map(col_point).length() - 1
			if target.has_method("exploded") && is_multiplayer_authority(): target.exploded.rpc(from_player)
			print(ray.get_meta("direction"), " hit ", target.name, " at: ", explosion.get_node("SpriteTileMap").local_to_map(col_point)) 
	print(exp_range)
	if is_multiplayer_authority(): 
		explosion.init_detonate.rpc(exp_range[Vector2i.RIGHT], exp_range[Vector2i.DOWN], exp_range[Vector2i.LEFT], exp_range[Vector2i.UP])
		explosion.do_detonate.rpc()

	if(!player.is_dead) && is_multiplayer_authority():
		player.return_bomb.rpc()
	
func done():
	if is_multiplayer_authority():
		queue_free()

func is_out_of_bounds(pos: Vector2):
	if pos.x < 33 || pos.x > 447:
		return true
	if pos.y < 97 || pos.y > 447:
		return true
	return false

func set_explosion_width_and_size(somewidth: int):
	explosion_width = clamp(somewidth, 2, MAX_EXPLOSION_WIDTH)
	bombsprite.set_frame(clamp(somewidth-3, 0, 2))

func set_explosion_width(somewidth: int):
	explosion_width = clamp(somewidth, 2, MAX_EXPLOSION_WIDTH)
	
func set_bomb_size(size: int):
	bombsprite.set_frame(clamp(size-1, 0, 2))
	
func _on_detect_area_body_exit(_body: Node2D) -> void:
	$CollisionShape2D.set_deferred("disabled", 0)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "idle":
		animation_finish = true
