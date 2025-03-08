extends State
class_name AIDodge

var just_entered : bool

func _enter():
	#if aiplayer.name == "2":
	#	print(Time.get_unix_time_from_system())
	#	print("Dodge entered")
	idle = false
	path = []
	just_entered = true
	currently_moving = false
	set_area()

func _update(delta):
	_idle_and_detect(delta)

func _physics_update(delta):
	if just_entered:
		_set_target()
		just_entered=false
	if !idle:
		set_next_point()
	elif (idle and detect):
		_detect_surroundings()
		detect = false
	move_to_next_point()

func _on_player_finished_path() -> bool:
	state_changed.emit(self, "Safe")
	return true

func _set_target():
	safe_target()

func safe_target() -> void:
	var unsafe_cells = get_unsafe_cells(aiplayer.bombs_near)
	var found = false
	var current_pos = get_cell_position(aiplayer.global_position)
	var iteration = 1
	# Will consider it's own explosion rate to get out of danger
	var range = 6
	while !found and iteration < range:
		for x in range(current_pos.x-iteration, current_pos.x+iteration+1):
			var y1 = current_pos.y - iteration
			var y2 = current_pos.y + iteration
			var new_target = Vector2i(x,y1)
			#if aiplayer.name == "2":
			#	print(new_target)
			if set_valid_new_target(new_target, unsafe_cells):
				found = true
				break
			new_target = Vector2i(x,y2)
			#if aiplayer.name == "2":
			#	print(new_target)
			if set_valid_new_target(new_target, unsafe_cells):
				found = true
				break
		if found:
			break
		for y in range(current_pos.y-(iteration-1), current_pos.y+(iteration-1)+1):
			var x1 = current_pos.x - iteration
			var x2 = current_pos.x + iteration
			var new_target = Vector2i(x1,y)
			#if aiplayer.name == "2":
			#	print(new_target)
			if set_valid_new_target(new_target, unsafe_cells):
				found = true
				break
			new_target = Vector2i(x2,y)
			#if aiplayer.name == "2":
			#	print(new_target)
			if set_valid_new_target(new_target, unsafe_cells):
				found = true
				break
		if found:
			break
		iteration += 1
	if found:
		path = world.create_path(aiplayer, target)
		path.pop_front()
	else:
		#print("No safe was found")
		state_changed.emit(self, "Safe")

func set_valid_new_target(new_target : Vector2i, unsafe_cells : Array[Vector2i]) -> bool:
	if is_new_target_valid(new_target, unsafe_cells):
		path = world.create_path(aiplayer, new_target)
		#if aiplayer.name == "2":
		#	print("New target valid, path:",str(path))
		if path.size() > 0:
			target = new_target
			return true
		else:
			return false
	return false

func get_unsafe_cells(bomb_list : Array[Bomb]) -> Array[Vector2i]:
	var cell_list : Array[Vector2i]
	var cell
	var range = aiplayer.explosion_boost_count + 2
	for bomb in bomb_list:
		var bomb_position = get_cell_position(bomb.global_position)
		var unsafe_cell : Vector2i
		# Will only mark unsafe cells if there isn't unbreakables in the way of
		# the explosion
		# Code can look prettier, but I'm not gonna bother
		if not world.is_unbreakable(Vector2i(bomb_position.x-1, bomb_position.y)) or not world.is_unbreakable(Vector2i(bomb_position.x+1, bomb_position.y)):
			for x in range (bomb_position.x-range, bomb_position.x+range+1):
				cell = Vector2i(x, bomb_position.y)
				if area.has_point(cell):
					cell_list.append(cell)
		if not world.is_unbreakable(Vector2i(bomb_position.x, bomb_position.y-1)) or not world.is_unbreakable(Vector2i(bomb_position.x, bomb_position.y+1)):
			for y in range (bomb_position.y-range, bomb_position.y+range+1):
				cell = Vector2i(bomb_position.x, y)
				if area.has_point(cell):
					cell_list.append(Vector2i(bomb_position.x, y))
	#if aiplayer.name == "2":
	#	print(cell_list)
	return cell_list

func is_new_target_valid(new_target : Vector2i, unsafe_cells : Array[Vector2i]) -> bool:
	var is_x_inbounds = new_target.x < area.end.x and new_target.x >= area.position.x
	var is_y_inbounds = new_target.y < area.end.y and new_target.y >= area.position.y
	var is_safe = new_target not in unsafe_cells
	var is_not_blocked = not world.is_unbreakable(new_target) and not world.is_breakable(new_target)
	return is_x_inbounds and is_y_inbounds and is_safe and is_not_blocked
