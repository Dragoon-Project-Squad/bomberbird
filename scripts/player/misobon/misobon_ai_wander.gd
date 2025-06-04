extends MisobonAiState

const WANDER_COOLDOWN: float = 1

## cooldown between checking for a target (if this is too low it might be laggy)
const TARGET_CHECKING_COOLDOWN: float = 0.1



var wander_cooldown: float = WANDER_COOLDOWN
var target_checking_cooldown: float = TARGET_CHECKING_COOLDOWN
var raycasts: Node2D #Set by the get_parent().player

func _update(delta: float) -> void:
	wander_cooldown += delta
	target_checking_cooldown += delta
	
	if wander_cooldown >= WANDER_COOLDOWN && is_multiplayer_authority():
		player.move_direction = rng.randi_range(-1, 1)
		wander_cooldown = 0
	
	player.progress += player.move_direction * player.MOVEMENT_SPEED * delta
	player.update_animation(
		player.get_parent().get_segment_id(player.progress)
	)

	if target_checking_cooldown < TARGET_CHECKING_COOLDOWN: # calling the bomb predicting algorighm is quite expensive if done every frame... so don't do it every frame (also might work well as a difficulty adjuster
		return
	target_checking_cooldown = 0

	var look_direction = player.get_parent().get_direction(player.progress)
	var throw_range = player.THROW_RANGE if look_direction != Vector2i.DOWN else player.THROW_RANGE + 2
	var pot_bomb_pos = player.position + Vector2(look_direction) * player.TILESIZE * throw_range

	var predicted_bounce = _predict_throw(pot_bomb_pos, look_direction, throw_range)
	if predicted_bounce == -999: return # an arbitrary decided error value (hence if predict bounce thinks a bomb may loop infinitly without external changes)

	pot_bomb_pos += Vector2(look_direction) * player.TILESIZE * predicted_bounce ## 
	
	## adjust this new position if its out of bounds
	if world_data.is_out_of_bounds(pot_bomb_pos) == world_data.bounds.OUT_RIGHT:
		pot_bomb_pos.x = world_data.tile_map.map_to_local(world_data.floor_origin + Vector2i(world_data.world_width - 1, 0)).x
	elif world_data.is_out_of_bounds(pot_bomb_pos) == world_data.bounds.OUT_LEFT:
		pot_bomb_pos.x = world_data.tile_map.map_to_local(world_data.floor_origin).x
	elif world_data.is_out_of_bounds(pot_bomb_pos) == world_data.bounds.OUT_TOP:
		pot_bomb_pos.y = world_data.tile_map.map_to_local(world_data.floor_origin).y
	elif world_data.is_out_of_bounds(pot_bomb_pos) == world_data.bounds.OUT_DOWN:
		pot_bomb_pos.y = world_data.tile_map.map_to_local(world_data.floor_origin + Vector2i(0, world_data.world_height - 1)).y

	raycasts.position = pot_bomb_pos - player.position
	
	if _check_raycasts():
		state_changed.emit(self, "Bombing") # throw the bomb if a player has been spotted


#Private functions
## predicts the throw of a bomb (more specificaly how many times it would bounce), used to then calculated if actually throwing a bomb is worth while
func _predict_throw(pos: Vector2, direction: Vector2i, throw_range: int) -> int:
	if world_data.is_out_of_bounds(pos) == world_data.bounds.OUT_RIGHT:
		pos.x = world_data.tile_map.map_to_local(world_data.floor_origin + Vector2i(world_data.world_width - 1, 0)).x
	elif world_data.is_out_of_bounds(pos) == world_data.bounds.OUT_LEFT:
		pos.x = world_data.tile_map.map_to_local(world_data.floor_origin).x
	elif world_data.is_out_of_bounds(pos) == world_data.bounds.OUT_TOP:
		pos.y = world_data.tile_map.map_to_local(world_data.floor_origin).y
	elif world_data.is_out_of_bounds(pos) == world_data.bounds.OUT_DOWN:
		pos.y = world_data.tile_map.map_to_local(world_data.floor_origin + Vector2i(0, world_data.world_height - 1)).y

	var res: int = 0
	var counter: int = 0
	while !world_data.is_tile(world_data.tiles.EMPTY, pos) && !world_data.is_tile(world_data.tiles.PICKUP, pos):
		pos += Vector2(direction) * player.TILESIZE
		res += 1
		counter += 1
		if counter > max(world_data.world_height, world_data.world_width):
			return -999
		if world_data.is_out_of_bounds(pos) != -1:
			pos = pos - Vector2(direction) * player.TILESIZE * (world_data.world_height if direction.y != 0 else world_data.world_width)
			res = -throw_range
	return res

## checks the raycast of a predicted bomb_throw to see if an enemy player would be hit by this
func _check_raycasts() -> bool:
	for ray in raycasts.get_children():
		ray.force_raycast_update()
		if !ray.is_colliding():
			continue
		if ray.get_collider() is Player:
			return true
	return false
