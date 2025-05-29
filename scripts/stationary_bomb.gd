extends StaticBody2D
class_name Bomb
## Handles the most basic bomb behaviore of a bomb just sitting and waiting to explode

@onready var bomb_root: Node2D = get_parent()
@onready var bomb_pool: Node2D = get_parent().get_parent()

var explosion_width := 2
const MAX_EXPLOSION_WIDTH := 8
var animation_finish := false
const TILE_SIZE = 32 #Primitive method of assigning correct tile size
#var TILE_SIZE: int = get_node("/root/World/Unbreakale").get_tileset().get_tile_size() #Would be cool but the match doesn't like non constants

# bomb addons
var pierce := false
var mine := false

@export var bomb_place_audio: AudioStreamWAV = load("res://sound/fx/bombdrop.wav")
@onready var bomb_placement_sfx_player: AudioStreamPlayer
@export var explosion_audio : AudioStreamWAV = load("res://sound/fx/explosion.wav")
@onready var explosion_sfx_player: AudioStreamPlayer2D #Left 2D for Monsto fix
@onready var rays: Node2D = $Raycasts
@onready var bombsprite := $BombSprite
@onready var explosion = $Explosion
@onready var tileMap = world_data.tile_map

var force_collision: bool = false
var armed: bool = false

func _ready():
	explosion_sfx_player = bomb_pool.get_node("BombGlobalAudioPlayers/ExplosionSoundPlayer")
	bomb_placement_sfx_player = get_node("BombPlacementPlayer")
	explosion_sfx_player.set_stream(explosion_audio)
	bomb_placement_sfx_player.set_stream(bomb_place_audio)
	self.visible = false

func disable():
	explosion_sfx_player.position = Vector2.ZERO #Mmonsto Fix
	animation_finish = false
	explosion_width = 2
	self.visible = false
	explosion.reset()
	$AnimationPlayer.stop()

func set_addons(addons: Dictionary):
	if addons.is_empty():
		return
	pierce = addons.get("pierce", false)
	mine = addons.get("mine", false)

func place(bombPos: Vector2, fuse_time_passed: float = 0, force_collision: bool = false):
	bomb_placement_sfx_player.play()
	bomb_root.position = bombPos
	self.visible = true
	self.force_collision = force_collision
	if mine:
		armed = false
		$AnimationPlayer.play("hide")
	else:
		$AnimationPlayer.play("fuse_and_call_detonate()")
	$AnimationPlayer.advance(fuse_time_passed) #continue the animation from where it was left of

func hide_mine():
	hide()
	set_collision_layer_value(4, false)
	astargrid_handler.astargrid_set_point(bomb_root.global_position, false)
	world_data.set_tile(world_data.tiles.EMPTY, bomb_root.global_position)
	armed = true
	return

## started the detonation call chain, calculates the true range of the explosion by checking for any breakables in its path, destroys those and corrects its exposion size before telling the exposion child to activate
func detonate():
	explosion_sfx_player.stop()
	explosion_sfx_player.position = bomb_root.position #Monsto Fix
	explosion_sfx_player.play()
	var exp_range = {Vector2i.RIGHT: explosion_width, Vector2i.DOWN: explosion_width, Vector2i.LEFT: explosion_width, Vector2i.UP: explosion_width}
	for ray: RayCast2D in rays.get_children():
		var ray_direction = ray.get_meta("direction")
		ray.target_position = ray_direction * explosion_width * TILE_SIZE
		ray.force_raycast_update()
		if !ray.is_colliding():
			continue
		var targets: Array[Node2D] = []
		while ray.is_colliding():
			targets.append(ray.get_collider())
			if !pierce || ray.get_collider().is_class("TileMapLayer"):
				break
			ray.add_exception_rid(ray.get_collider_rid())
			ray.force_raycast_update()
		for target in targets:
			if target.is_in_group("bombstop"):
				@warning_ignore("INTEGER_DIVISION") #Note this integer division is fine idk why godot feels like it needs to warn for int divisions anyway?
				var col_point = to_local(ray.get_collision_point()) + Vector2(ray_direction * (TILE_SIZE / 2))
				#find the distance from bomb.position to the last tile that should be blown up (in number of tiles)
				exp_range[ray_direction] = explosion.get_node("SpriteTileMap").local_to_map(col_point).length() - 1 
				if target.has_method("exploded") && is_multiplayer_authority():
					if(bomb_root.bomb_owner):
						target.exploded.rpc(str(get_parent().bomb_owner.name).to_int()) #if an object stopped the bomb and can be blown up... blow it up!
					else:
						target.exploded.rpc(gamestate.ENVIRONMENTAL_KILL_PLAYER_ID) #if an object stopped the bomb and can be blown up... blow it up!
	if(bomb_root.bomb_owner):
		remove_collision_exception_with(bomb_root.bomb_owner)
	if is_multiplayer_authority(): #multiplayer auth. now starts the transition to the explosion
		explosion.init_detonate.rpc(exp_range[Vector2i.RIGHT], exp_range[Vector2i.DOWN], exp_range[Vector2i.LEFT], exp_range[Vector2i.UP])
		explosion.do_detonate.rpc()
		if(get_parent().bomb_owner && !get_parent().bomb_owner.is_dead):
			get_parent().bomb_owner.return_bomb.rpc()
	
## called when a bomb has detonated and hence is done, clears it of the arena both in world_data and for the AI then returns the root back to the bomb_pool
func done():
	bomb_root.bomb_finished.emit()
	world_data.set_tile(world_data.tiles.EMPTY, bomb_root.global_position)
	force_collision = false
	
	# Frees collision from astargrid when done
	# Revise for posible implementation on world_data
	astargrid_handler.astargrid_set_point(bomb_root.global_position, false)
	
	if !is_multiplayer_authority():
		return
	bomb_root.disable.rpc()
	bomb_pool.return_obj(get_parent()) # bomb returns itself to the pool

@rpc("call_local")
func exploded(by_who):
	$AnimationPlayer.advance(2.79)

func set_explosion_width_and_size(somewidth: int):
	explosion_width = clamp(somewidth, 2, MAX_EXPLOSION_WIDTH)
	bombsprite.set_frame(clamp(somewidth-3, 0, 2))

## sets the size of the bomb (larger if its range is larger)
## im unsure what calls this function since it does not seem to be an animation neither to be in this file bit its effect can clearly be seen in the game
func set_bomb_size(size: int):
	bombsprite.set_frame(clamp(size-1, 0, 2))
	
func _on_detect_area_body_entered(body: Node2D):
	if force_collision: return
	if (body is Player || body is Enemy) && armed && mine:
		show()
		$AnimationPlayer.play("mine_explode")
	if body is Breakable:
		body.crush()
	if !(body in get_collision_exceptions()):
		add_collision_exception_with(body)

func _on_detect_area_body_exit(body: Node2D):
	if body in get_collision_exceptions():
		remove_collision_exception_with(body)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "idle":
		animation_finish = true
