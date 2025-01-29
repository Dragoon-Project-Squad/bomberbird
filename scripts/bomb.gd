extends StaticBody2D

var in_area: Array = []
var from_player: int
var explosion_width := 2
var animation_finish := false
const TILE_SIZE = 32 #Primitive method of assigning correct tile size
#var TILE_SIZE: int = get_node("/root/World/Unbreakale").get_tileset().get_tile_size() #Would be cool but the match doesn't like non constants
@export var explosion_audio : AudioStreamWAV = load("res://sound/fx/explosion.wav")
@onready var explosion_sfx_player := $ExplosionSoundPlayer 
@onready var rays = $Raycasts
@onready var bombsprite := $BombSprite
@onready var explosions = $Explosions
@onready var explosion_scene = preload("res://scenes/explosion.tscn")
@onready var tileMap = get_tree().get_root().get_node("World/Floor")

func _ready():
	explosion_sfx_player.set_stream(explosion_audio)
	$Timer.start()
	
func explode():
	explosion_sfx_player.play()
	var explosion_direction = Vector2.ZERO
	var bombblocked = false
	place_explosion(position, explosion_direction, "center")
	for ray in rays.get_children():
		bombblocked = false
		match ray.target_position:
			Vector2(0,TILE_SIZE):
				ray.target_position = Vector2(0,TILE_SIZE * (explosion_width))
				ray.force_raycast_update()
				explosion_direction = Vector2.DOWN
			Vector2(0,-TILE_SIZE):
				ray.target_position = Vector2(0,-TILE_SIZE * (explosion_width))
				ray.force_raycast_update()
				explosion_direction = Vector2.UP
			Vector2(TILE_SIZE,0):
				ray.target_position = Vector2(TILE_SIZE * (explosion_width), 0 )
				ray.force_raycast_update()
				explosion_direction = Vector2.RIGHT
			Vector2(-TILE_SIZE,0):
				ray.target_position = Vector2(-TILE_SIZE * (explosion_width), 0 )
				ray.force_raycast_update()
				explosion_direction = Vector2.LEFT
		if ray.is_colliding():
			in_area.append(ray.get_collider())
			print(ray.get_collider())
			if ray.get_collider().is_in_group("bombstop"):
				bombblocked = true #We hit something that needs the bomb to stop.
		if !bombblocked: #Note that we hit something but keep going.
			explode_space_between_center_and_end(position, ray.target_position+position, explosion_direction)
			place_explosion(ray.target_position+position, explosion_direction, "side_border")
		if not is_multiplayer_authority():
		# Explode only on authority.
			return
		for collider in in_area:
			if collider.has_method("exploded"):
				explode_space_between_center_and_end(position, collider.position, explosion_direction)
				place_explosion(collider.position, explosion_direction, "side_border")
				# Exploded can only be called by the authority, but will also be called locally.
				collider.exploded.rpc(from_player)
				if collider.is_in_group("bombstop"):
					in_area.erase(ray.get_collider())
			else:
				var shaved_collision_point = shave_back_colliding_point(ray.get_collision_point(), explosion_direction)
				var colliding_tile_pos = tileMap.map_to_local(tileMap.local_to_map(shaved_collision_point))
				explode_space_between_center_and_end(position, colliding_tile_pos, explosion_direction)
				place_explosion(colliding_tile_pos, explosion_direction, "side_border")
func done():
	if is_multiplayer_authority():
		queue_free()

func shave_back_colliding_point(collidingpoint: Vector2, intendeddirection: Vector2) -> Vector2:
	var newcollisionpos = collidingpoint
	match intendeddirection:
		Vector2.UP:
			pass
		Vector2.LEFT:
			pass
		Vector2.DOWN:
			newcollisionpos.y = collidingpoint.y - 1
		Vector2.RIGHT:
			newcollisionpos.x = collidingpoint.x - 1
	return newcollisionpos

func explode_space_between_center_and_end(centerpos: Vector2, endpos: Vector2, explosion_direction: Vector2):
	var difference_in_tiles = abs(int(((endpos-centerpos)/TILE_SIZE).x + ((endpos-centerpos)/TILE_SIZE).y))
	for n in range(1, difference_in_tiles):
		var new_explosion_pos = centerpos+(explosion_direction*TILE_SIZE*n)
		place_explosion(new_explosion_pos, explosion_direction, "side")
	pass

func is_out_of_bounds(pos: Vector2):
	if pos.x < 33 || pos.x > 447:
		return true
	if pos.y < 97 || pos.y > 447:
		return true
	return false

func place_explosion(explosion_pos: Vector2i, explosion_direction: Vector2, explosion_type: String):
	#if not is_multiplayer_authority():
		## Explode only on authority.
		#return
	if is_out_of_bounds(explosion_pos):
		return
	var explosion = explosion_scene.instantiate()
	explosion.bombowner = from_player
	explosion.position = explosion_pos
	match explosion_type:
		"center":
			explosion.type = explosion.CENTER
		"side_border":
			explosion.type = explosion.SIDE_BORDER
		_:
			explosion.type = explosion.SIDE
	explosion.direction = explosion_direction
	explosions.add_child(explosion)
	
func set_explosion_width_and_size(somewidth: int):
	explosion_width = clamp(somewidth, 2, 5)
	bombsprite.set_frame(clamp(somewidth-3, 0, 2))

func set_explosion_width(somewidth: int):
	explosion_width = clamp(somewidth, 2, 5)
	
func set_bomb_size(size: int):
	bombsprite.set_frame(clamp(size-1, 0, 2))
	
func _on_bomb_body_enter(body):
	if not body in in_area:
		in_area.append(body) #Add this thing to list of things this bomb will explode

func _on_bomb_body_exit(body):
	in_area.erase(body) # Remove this thing from the list of things this bomb will explode
	
#func _on_timer_timeout() -> void:
	#explode()
	#print(explosion_animation)
	#done()

func _on_detect_area_body_exit(_body: Node2D) -> void:
	$CollisionShape2D.set_deferred("disabled", 0)
#func _on_bomb_collision_area_2d_body_exited(_body: Node2D) -> void:
	#print("exited")
	#$BombCollisionBody2D.set_deferred("process_mode", 0)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "idle":
		animation_finish = true
