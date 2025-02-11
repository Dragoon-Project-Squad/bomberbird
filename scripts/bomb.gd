extends StaticBody2D

var in_area: Array = []
var from_player: int
var explosion_width := 2
const MAX_EXPLOSION_WIDTH := 8
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
	var collider_stopped_upon = null
	place_explosion(position, explosion_direction, "center")
	for ray in rays.get_children():
		bombblocked = false #Reset bomb lock
		collider_stopped_upon = null #Reset collider stopped upon
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
			in_area.append(ray.get_collider()) #Add impacted objects to array.
			#print(ray.get_collider())
			if ray.get_collider().is_in_group("bombstop"):
				bombblocked = true #We hit something that needs the bomb to stop.
				collider_stopped_upon = ray.get_collider()
			elif ray.get_collider().has_method("exploded"): #The bomb ray hit something that bombs pierce.
				if is_multiplayer_authority(): #Try to destroy it on the host side.
					## Explode only on authority.
					ray.get_collider().exploded.rpc(from_player)
		if not bombblocked: #This direction isn't stopped, draw the full thing.
			explode_space_between_center_and_end(position, ray.target_position+position, explosion_direction)
			place_explosion(ray.target_position+position, explosion_direction, "side_border")
		elif collider_stopped_upon.has_method("exploded"): # Explodeable bomb stopper was hit.
			explode_space_between_center_and_end(position, collider_stopped_upon.position, explosion_direction)
			place_explosion(collider_stopped_upon.position, explosion_direction, "side_border")
			if is_multiplayer_authority(): #Try to destroy it on the host side.
				## Explode only on authority.
				ray.get_collider().exploded.rpc(from_player)
		else: # We hit something utterly unbreakable
			var shaved_collision_point = shave_back_colliding_point(ray.get_collision_point(), explosion_direction)
			var colliding_tile_pos = tileMap.map_to_local(tileMap.local_to_map(shaved_collision_point))
			explode_space_between_center_and_end(position, colliding_tile_pos, explosion_direction)
			if colliding_tile_pos != position: #Do not overlap the center.
				place_explosion(colliding_tile_pos, explosion_direction, "side_border")
			#for collider in in_area: #Check if anything hit by this ray was explodeable.
				##BUG There is very likely a race condition here.
				#if collider.has_method("exploded"):
					#explode_space_between_center_and_end(position, collider.position, explosion_direction)
					#place_explosion(collider.position, explosion_direction, "side_border")
					## Exploded can only be called by the authority, but will also be called locally.
					#if collider.is_in_group("bombstop"):
						#in_area.erase(ray.get_collider())
					#if is_multiplayer_authority():
						## Explode only on authority.
						#collider.exploded.rpc(from_player)
				#else:
					#var shaved_collision_point = shave_back_colliding_point(ray.get_collision_point(), explosion_direction)
					#var colliding_tile_pos = tileMap.map_to_local(tileMap.local_to_map(shaved_collision_point))
					#explode_space_between_center_and_end(position, colliding_tile_pos, explosion_direction)
					#place_explosion(colliding_tile_pos, explosion_direction, "side_border")
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
	if is_out_of_bounds(explosion_pos):
		return
	if is_multiplayer_authority():
		get_node("/root/World/ExplosionSpawner").spawn({"spawnpoint": explosion_pos, "bombowner": from_player, "explosiontype": explosion_type, "direction": explosion_direction})
	
func set_explosion_width_and_size(somewidth: int):
	explosion_width = clamp(somewidth, 2, MAX_EXPLOSION_WIDTH)
	bombsprite.set_frame(clamp(somewidth-3, 0, 2))

func set_explosion_width(somewidth: int):
	explosion_width = clamp(somewidth, 2, MAX_EXPLOSION_WIDTH)
	
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
