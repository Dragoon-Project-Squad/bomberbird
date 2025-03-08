extends StaticBody2D
class_name Bomb

@onready var bomb_root: Node2D = get_parent()
@onready var bomb_pool: Node2D = get_parent().get_parent()

var explosion_width := 2
const MAX_EXPLOSION_WIDTH := 8
var animation_finish := false
const TILE_SIZE = 32 #Primitive method of assigning correct tile size
#var TILE_SIZE: int = get_node("/root/World/Unbreakale").get_tileset().get_tile_size() #Would be cool but the match doesn't like non constants

@export var bomb_place_audio: AudioStreamWAV = load("res://sound/fx/bombdrop.wav")
@onready var bomb_placement_sfx_player: AudioStreamPlayer2D
@export var explosion_audio : AudioStreamWAV = load("res://sound/fx/explosion.wav")
@onready var explosion_sfx_player: AudioStreamPlayer2D
@onready var rays = $Raycasts
@onready var bombsprite := $BombSprite
@onready var explosion = $Explosion
@onready var tileMap = world_data.tile_map

func _ready():
	explosion_sfx_player = bomb_pool.get_node("BombGlobalAudioPlayers/ExplosionSoundPlayer")
	bomb_placement_sfx_player = get_node("BombPlacementPlayer")
	explosion_sfx_player.set_stream(explosion_audio)
	bomb_placement_sfx_player.set_stream(bomb_place_audio)
	self.visible = false
	$DetectArea.set_deferred("disabled", 1)
	$CollisionShape2D.set_deferred("disabled", 1) # This line of code thinks it knows better so it just kinda doesn't do what it should... also doesn't give an error tho...

func disable():
	explosion_sfx_player.position = Vector2.ZERO
	animation_finish = false
	explosion_width = 2
	self.visible = false
	explosion.reset()
	$AnimationPlayer.stop()
	$DetectArea.set_deferred("disabled", 1)
	$CollisionShape2D.set_deferred("disabled", 1)

func place(bombPos: Vector2, fuse_time_passed: float = 0):
	bomb_placement_sfx_player.play()
	bomb_root.position = bombPos
	self.visible = true
	$CollisionShape2D.set_deferred("disabled", 1)
	$DetectArea.set_deferred("disabled", 0)
	$AnimationPlayer.play("fuse_and_call_detonate()")
	$AnimationPlayer.advance(fuse_time_passed) #continue the animation from where it was left of
	
func detonate():
	explosion_sfx_player.stop()
	explosion_sfx_player.position = bomb_root.position
	explosion_sfx_player.play()
	var exp_range = {Vector2i.RIGHT: explosion_width, Vector2i.DOWN: explosion_width, Vector2i.LEFT: explosion_width, Vector2i.UP: explosion_width}
	for ray in rays.get_children():
		var ray_direction = ray.get_meta("direction")
		ray.target_position = ray_direction * explosion_width * TILE_SIZE
		ray.force_raycast_update()
		if !ray.is_colliding():
			continue
		var target: Node2D = ray.get_collider()
		if target.is_in_group("bombstop"):
			@warning_ignore("INTEGER_DIVISION") #Note this integer division is fine idk why godot feels like it needs to warn for int divisions anyway?
			var col_point = to_local(ray.get_collision_point()) + Vector2(ray_direction * (TILE_SIZE / 2))
			
			exp_range[ray_direction] = explosion.get_node("SpriteTileMap").local_to_map(col_point).length() - 1 #find the distance from bomb.position to the last tile that should be blown up (in number of tiles)
			if target.has_method("exploded") && is_multiplayer_authority(): target.exploded.rpc(str(get_parent().bomb_owner.name).to_int()) #if an object stopped the bomb and can be blown up... blow it up!
	if is_multiplayer_authority(): #multiplayer auth. now starts the transition to the explosion
		explosion.init_detonate.rpc(exp_range[Vector2i.RIGHT], exp_range[Vector2i.DOWN], exp_range[Vector2i.LEFT], exp_range[Vector2i.UP])
		explosion.do_detonate.rpc()
		if(!get_parent().bomb_owner.is_dead):
			get_parent().bomb_owner.return_bomb.rpc()
	
func done():
	world_data.set_tile(world_data.tiles.EMPTY, bomb_root.global_position)
	
	# Frees collision from astargrid when done
	# Revise for posible implementation on world_data
	var world : World
	world = get_parent().get_parent().get_parent()
	world.astargrid_set_point(world_data.tile_map.local_to_map(bomb_root.global_position), false)
	
	if !is_multiplayer_authority():
		return
	bomb_root.disable.rpc()
	bomb_pool.return_obj(get_parent()) # bomb returns itself to the pool

#Probably Deprecated
func is_out_of_bounds(pos: Vector2):
	if pos.x < 33 || pos.x > 447:
		return true
	if pos.y < 97 || pos.y > 447:
		return true
	return false

func set_explosion_width_and_size(somewidth: int):
	explosion_width = clamp(somewidth, 2, MAX_EXPLOSION_WIDTH)
	bombsprite.set_frame(clamp(somewidth-3, 0, 2))

#Either this or the above function are also probably Deprecated
func set_explosion_width(somewidth: int):
	explosion_width = clamp(somewidth, 2, MAX_EXPLOSION_WIDTH)
	
func set_bomb_size(size: int):
	bombsprite.set_frame(clamp(size-1, 0, 2))
	
func _on_detect_area_body_exit(_body: Node2D) -> void:
	#BUG: This likely causes other players to be abled to walk over the bomb aslong as the player that placed it remains on the bomb
	$CollisionShape2D.set_deferred("disabled", 0)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "idle":
		animation_finish = true
