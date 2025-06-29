extends State
class_name AIWander

func _enter():
	idle = true
	path = []
	next_point = aiplayer.global_position
	currently_moving = false
	set_area()

func _update(delta):
	detect_stuck(delta)
	_idle_and_detect(delta)
	
func _physics_update(_delta):
	if !idle:
		set_next_point()
	elif (idle and detect):
		_detect_surroundings()
		detect = false
	move_to_next_point()

func _set_target() -> bool:
	return randomize_target()

func _detect_surroundings() -> void:
	if is_bomb_near():
		state_changed.emit(self, "Dodge")
		return
	if is_breakable_in_front():
		state_changed.emit(self, "Bombing")
		return
	if is_enemy_near():
		state_changed.emit(self, "FollowTarget")
		return

## Choose random point to wander to and create pathing
func randomize_target() -> bool:
	# BUG: this is calculated by each client but only the multiplayer authorities result is actually used.
	# This is normaly no problem as predicting the next move for each client is usually a good idea but
	# since this function contains randomisation each client will get a potentialy vastly different result causeing
	# unnessessary calculations.
	var offset = area.position
	var end = area.end
	var current_cell = get_cell_position(aiplayer.global_position)
	var valid_point = false
	var number_generator = RandomNumberGenerator.new()
	var new_target : Vector2i
	var max_target_range = 4
	while !valid_point:
		# Generate random cell to move to
		var posx = clampi(number_generator.randi_range(current_cell.x-max_target_range, current_cell.x+max_target_range+1), offset.x, end.x-1)
		var posy = clampi(number_generator.randi_range(current_cell.y-max_target_range, current_cell.y+max_target_range+1), offset.y, end.y-1)
		new_target = Vector2i(posx, posy)
		# If the point is valid, finish
		if (!world_data.is_tile(world_data.tiles.UNBREAKABLE, world_data.tile_map.map_to_local(new_target)) and new_target != current_cell):
			valid_point = true
		else:
			continue
		path = astargrid_handler.create_path_no_breakables(aiplayer.position, new_target)
		if len(path) > 1 && world_data.is_tile(world_data.tiles.BREAKABLE, world_data.tile_map.map_to_local(path[1])):
			valid_point = false
			path = []
	
	# Remove first point in path which is the current position
	path.pop_front()
	return !path.is_empty()


func is_breakable_in_front() -> bool:
	if path.size()==0:
		return false
	return world_data.is_tile(world_data.tiles.BREAKABLE, world_data.tile_map.map_to_local(path[0]))

func is_enemy_near() -> bool:
	# TODO
	return false

func is_bomb_near() -> bool:
	return aiplayer.bombs_near.size() > 0
