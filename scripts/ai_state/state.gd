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
var default_idle_time = 2
var idle_time = default_idle_time
var idle : bool

# Overwrite "_" functions as needed
func _enter() -> void:
	pass

func _exit() -> void:
	pass

func _update(delta : float) -> void:
	pass

func _physics_update(_delta : float) -> void:
	pass

func _set_target() -> void:
	pass

# *****General utility*****
func get_cell_position(position : Vector2) -> Vector2i:
	var cell_index = world.floor_layer.local_to_map(position)
	return cell_index

func get_global_position(cell : Vector2i) -> Vector2:
	var position = world.floor_layer.map_to_local(cell)
	position = Vector2i(position.x, position.y)
	return position

# *****Setting*****
func set_area() -> void:
	area = world.floor_layer.get_used_rect()

# *****Movement***** 
func set_next_point() -> void:
	# If player reached its next point enter idle
	if currently_moving and reached_next_point():
		currently_moving = false
		idle = true
		aiplayer.global_position = next_point
	# When idle time finishes, currently_moving should be put to false so it can move again.
	# If the path has been completely followed, decide a new target that each State should define,
	# then follow the next point
	elif !currently_moving:
		currently_moving = true
		if path.size()==0:
			_set_target()
		next_point = get_global_position(path.pop_front())

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
