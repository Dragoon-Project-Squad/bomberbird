extends Node
class_name State

signal state_changed

# Utils
var world : World
var aiplayer : AIPlayer
var area : Rect2i

# Movement vars
var target : Vector2i
var path : Array[Vector2i]
var next_point : Vector2
var currently_moving : bool
var default_idle_time = 0.5
var idle_time = default_idle_time
var default_stuck_time = 1
var stuck_time = default_stuck_time
var idle : bool
var prev_pos : Vector2
var detect : bool

# Overwrite "_" functions as needed
func _enter() -> void:
	pass

func _exit() -> void:
	target = Vector2i()
	path = []
	next_point = Vector2()
	currently_moving  = false
	idle_time = default_idle_time
	stuck_time = default_stuck_time
	idle = false

func _update(_delta : float) -> void:
	pass

func _physics_update(_delta : float) -> void:
	pass

func _set_target() -> bool:
	return false

# *****General utility*****
func get_cell_position(position : Vector2) -> Vector2i:
	var cell_index = world_data.tile_map.local_to_map(position)
	return cell_index

func get_global_position(cell : Vector2i) -> Vector2:
	var position = world_data.tile_map.map_to_local(cell)
	position = Vector2i(position.x, position.y)
	return position

func _idle_and_detect(delta) -> void:
	if idle:
		# Wait in idle for a set time after moving
		if(idle_time>0):
			idle_time -= delta
		else:
			idle = false
			idle_time = default_idle_time
			currently_moving = false
			# Once idle time finished, evaluate the situation and change state
			# depending on the things detected
			detect = true

func _detect_surroundings() -> void:
	pass

func detect_stuck(delta) -> void:
	if not idle:
		if stuck_time > 0:
			stuck_time -= delta
		else:
			var floor_prev_pos = Vector2(floor(prev_pos.x), floor(prev_pos.y))
			var floor_current_pos = Vector2(floor(aiplayer.global_position.x), floor(aiplayer.global_position.y))
			stuck_time = default_stuck_time
			if prev_pos == Vector2(0,0):
				prev_pos = aiplayer.global_position
			elif floor_prev_pos == floor_current_pos:
				#if aiplayer.name == "2":
					#print("Stuck detected, changing direction")
				prev_pos = Vector2(0, 0)
				aiplayer.global_position = get_global_position(get_cell_position(aiplayer.global_position))
				idle = true
				_set_target()
				

# *****Setting*****
func set_area() -> void:
	area = world_data.get_arena_rect()

# *****Movement***** 
func set_next_point() -> void:
	# If player reached its next point enter idle
	if currently_moving and reached_next_point():
		_on_player_reached_next_point()
		aiplayer.global_position = next_point
	# When idle time finishes, currently_moving should be put to false so it can move again.
	# If the path has been completely followed, decide a new target that each State should define,
	# then follow the next point
	elif !currently_moving:
		currently_moving = true
		if path.size() == 0:
			if !_on_player_finished_path():
				return
		assert(!path.is_empty())
		next_point = get_global_position(path.pop_front())

func _on_player_reached_next_point() -> bool:
	currently_moving = false
	idle = true
	stuck_time = default_stuck_time
	return false

func _on_player_finished_path() -> bool:
	return _set_target()

func _on_new_stage() -> void:
	idle = true
	_set_target()
	state_changed.emit(self, "Wander")

func move_to_next_point() -> void:
	if next_point:
		aiplayer.movement_vector = Vector2(next_point.x - aiplayer.global_position.x, next_point.y - aiplayer.global_position.y)
	else:
		aiplayer.movement_vector = Vector2(0, 0)

# Variable next_point is a whole number while global_position, due to the speed,
# is a real number (has decimals) it also can vary from +-1 from the next point.
# This function is so it detects that variation and treats it as if it already
# the next point.
func reached_next_point() -> bool:
	var validate_x = aiplayer.global_position.x<next_point.x+1 and aiplayer.global_position.x>next_point.x-1
	var validate_y = aiplayer.global_position.y<next_point.y+1 and aiplayer.global_position.y>next_point.y-1
	return validate_x and validate_y
