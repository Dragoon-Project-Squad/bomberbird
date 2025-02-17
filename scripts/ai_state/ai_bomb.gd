extends State
class_name AIBomb

var bomb_position : Vector2i

func _enter():
	print("Enter BombAndRun")
	aiplayer.is_bombing = true
	bomb_position = get_cell_position(aiplayer.global_position)

func _physics_process(delta):
	if !idle:
		set_next_point()
	move_to_next_point()
	
func _set_target():
	#safe_target()
	path.append(get_cell_position(aiplayer.global_position))

func safe_target() -> void:
	var unsafe_cells = get_unsafe_cells(bombs_near())
	var found = false
	var current_pos = get_cell_position(aiplayer.global_position)
	var iteration = 1
	while !found:
		for x in range(current_pos.x-iteration, current_pos.x+iteration):
			var y1 = current_pos.y - iteration
			var y2 = current_pos.y - iteration
			var new_target = Vector2i(x,y1)
			if is_new_target_valid(new_target, unsafe_cells):
				target = new_target
				return
			new_target = Vector2i(x,y2)
			if is_new_target_valid(new_target, unsafe_cells):
				target = new_target
				return
		for y in range(current_pos.y-(iteration-1), current_pos.y+(iteration-1)):
			var x1 = current_pos.x - iteration
			var x2 = current_pos.x - iteration
			var new_target = Vector2i(x1,y)
			if is_new_target_valid(new_target, unsafe_cells):
				target = new_target
				return
			new_target = Vector2i(x2,y)
			if is_new_target_valid(new_target, unsafe_cells):
				target = new_target
				return
	path = world.create_path(aiplayer, target)

func bombs_near() -> Array[Vector2i]:
	var bomb_list : Array[Vector2i]
	return bomb_list

func get_unsafe_cells(bomb_list : Array[Vector2i]) -> Array[Vector2i]:
	var cell_list : Array[Vector2i]
	return cell_list

func is_new_target_valid(new_target : Vector2i, unsafe_cells : Array[Vector2i]) -> bool:
	var is_x_inbounds = new_target.x < area.end.x and new_target.x > area.position.x
	var is_y_inbounds = new_target.y < area.end.y and new_target.y > area.position.y
	var is_safe_and_valid = new_target in unsafe_cells and world.is_unbreakable(new_target)
	return is_x_inbounds and is_y_inbounds and is_safe_and_valid
