extends StaticBody2D
class_name Bomb
## Handles the most basic bomb behaviore of a bomb just sitting and waiting to explode

@onready var bomb_root: BombRoot = get_parent()
@onready var bomb_pool: Node2D = get_parent().get_parent()

var explosion_width := 2
const MAX_EXPLOSION_WIDTH := 8
var animation_finish := false
const TILE_SIZE = 32 #Primitive method of assigning correct tile size
var is_exploded: bool = false

# bomb addons
var pierce := false
var mine := false

@export var bomb_place_audio: AudioStreamWAV = load("res://sound/fx/bombdrop.wav")
@onready var bomb_placement_sfx_player: AudioStreamPlayer
@export var explosion_audio : AudioStreamWAV = load("res://sound/fx/explosion.wav")
@onready var explosion_sfx_player: AudioStreamPlayer2D #Left 2D for Monsto fix
@onready var rays: Node2D = $Raycasts
@onready var bombsprite: Sprite2D = $BombSprite
@onready var explosion: Explosion = $Explosion
@onready var tileMap = world_data.tile_map

var force_collision: bool = false
var armed: bool = false

func _ready():
	explosion_sfx_player = bomb_pool.get_node("BombGlobalAudioPlayers/ExplosionSoundPlayer")
	bomb_placement_sfx_player = get_node("BombPlacementPlayer")
	explosion_sfx_player.set_stream(explosion_audio)
	bomb_placement_sfx_player.set_stream(bomb_place_audio)
	self.explosion.is_finished_exploding.connect(done)
	self.explosion.has_killed.connect(_kill)
	self.visible = false

func disable():
	explosion_sfx_player.position = Vector2.ZERO #Mmonsto Fix
	self.explosion_width = 2
	set_collision_layer_value(4, true)
	set_collision_layer_value(6, true)
	self.visible = false
	self.armed = false
	self.mine = false
	self.pierce = false
	self.is_exploded = false
	self.animation_finish = false
	self.force_collision = false
	explosion.reset()
	$AnimationPlayer.stop()

func set_bomb_type(bomb_type: int):
	match bomb_type:
		HeldPickups.bomb_types.DEFAULT:
			return
		HeldPickups.bomb_types.PIERCING:
			pierce = true
		HeldPickups.bomb_types.MINE:
			mine = true
		HeldPickups.bomb_types.REMOTE:
			pass
		HeldPickups.bomb_types.SEEKER:
			pass
		_: # bomb type does not exist
			return

func place(bombPos: Vector2, fuse_time_passed: float = 0, force_collision: bool = false):
	is_exploded = false 
	bomb_placement_sfx_player.play()
	bomb_root.position = bombPos
	self.visible = true
	self.force_collision = force_collision
	var animation: AnimationPlayer = $AnimationPlayer
	if mine:
		armed = false
		animation.play("hide")
	else:
		animation.play("fuse_and_call_detonate()", -1.0, bomb_root.fuse_length, false)
		animation.advance(fuse_time_passed) #continue the animation from where it was left of

func hide_mine():
	hide()
	set_collision_layer_value(4, false)
	set_collision_layer_value(6, false)
	astargrid_handler.astargrid_set_point(bomb_root.global_position, false)
	armed = true
	return

## started the detonation call chain, calculates the true range of the explosion by checking for any breakables in its path, destroys those and corrects its exposion size before telling the exposion child to activate
func detonate():
	is_exploded = true
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
			if not pierce or ray.get_collider().is_class("TileMapLayer"):
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
						target.exploded.rpc(gamestate.ENEMY_KILL_PLAYER_ID) #if an object stopped the bomb and can be blown up... blow it up!
	if bomb_root.bomb_owner:
		remove_collision_exception_with(bomb_root.bomb_owner)
	if is_multiplayer_authority(): #multiplayer auth. now starts the transition to the explosion
		explosion.init_detonate.rpc(exp_range[Vector2i.RIGHT], exp_range[Vector2i.DOWN], exp_range[Vector2i.LEFT], exp_range[Vector2i.UP])
		explosion.do_detonate.rpc()
		if(get_parent().bomb_owner && !get_parent().bomb_owner.is_dead):
			get_parent().bomb_owner.return_bomb.rpc(mine)
	
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
func exploded(_by_who):
	$AnimationPlayer.advance(2.79)

func _kill(obj):
	if obj is Area2D:
		if bomb_root.bomb_owner:
			obj.exploded.rpc(str(bomb_root.bomb_owner.name).to_int())
		else:
			obj.exploded.rpc(gamestate.ENEMY_KILL_PLAYER_ID)
		return

	if self != obj && bomb_root.bomb_owner:
		obj.exploded.rpc(str(bomb_root.bomb_owner.name).to_int())
	elif self != obj:
		obj.exploded.rpc(gamestate.ENVIRONMENTAL_KILL_PLAYER_ID)
	if (
		obj is Player
		&& bomb_root.bomb_owner
		&& bomb_root.bomb_owner_is_dead #was the bomb owner dead when the bomb was created?
		&& bomb_root.bomb_owner.is_dead #is the bomb owner still dead?
		&& obj.lives - 1 <= 0 #will the player that got hit die
		&& !obj.stunned #will the player that got hit die
		&& !obj.invulnerable #will the player that got hit die
		&& !obj.hurry_up_started #has hurry up alread started
	): #TODO: fix this, this is stupit
		report_kill(obj)

## reports a kill from a player to the killer s.t. he can be revived if the settings allow it
func report_kill(killed_player: Player):
	if(!bomb_root.bomb_owner): return
	var killer: Player = bomb_root.bomb_owner
	if !is_multiplayer_authority(): return
	killer.misobon_player.revive.rpc(killed_player.position)

func crush():
	if is_exploded: return
	if(get_parent().bomb_owner && !get_parent().bomb_owner.is_dead):
		get_parent().bomb_owner.return_bomb.rpc()
	$AnimationPlayer.stop()
	done()

func set_explosion_width_and_size(somewidth: int):
	explosion_width = clamp(somewidth, 1, MAX_EXPLOSION_WIDTH)
	bombsprite.set_frame(clamp(somewidth-3, 0, 2))

## sets the size of the bomb (larger if its range is larger)
## im unsure what calls this function since it does not seem to be an animation neither to be in this file bit its effect can clearly be seen in the game
func set_bomb_size(size: int):
	bombsprite.set_frame(clamp(size-1, 0, 2))
	
func _on_detect_area_body_entered(body: Node2D):
	if force_collision: return
	if (body is Player || body is Enemy) && armed && mine:
		show()
		$AnimationPlayer.play("mine_explode", -1.0, bomb_root.fuse_length, false)
		if world_data.is_tile(world_data.tiles.MINE, self.global_position):
			world_data.set_tile(world_data.tiles.BOMB, self.global_position, bomb_root.boost + 2, false)
	if body is Breakable:
		body.crush.rpc()
	if !(body in get_collision_exceptions()):
		add_collision_exception_with(body)

func _on_detect_area_body_exit(body: Node2D):
	if body in get_collision_exceptions():
		remove_collision_exception_with(body)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "idle":
		animation_finish = true
