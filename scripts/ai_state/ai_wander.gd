extends State
class_name AIWander

signal state_changed

func _enter():
	idle = true
	currently_moving = false
	set_area()

func _update(delta):
	idle_and_detect(delta)
	
func _physics_update(delta):
	if !idle:
		set_next_point()
	move_to_next_point()

func _set_target():
	randomize_target()

func idle_and_detect(delta) -> void:
	if idle:
		# Wait in idle for a set time after moving
		if(idle_time>0):
			idle_time -= delta
		else:
			idle = false
			idle_time = default_idle_time
			# Once idle time finished, evaluate the situation and change state
			# depending on the things detected
			detect_surroundings()

func detect_surroundings() -> void:
	if is_bomb_near():
		state_changed.emit(self, "Survive")
		return
	if is_breakable_near():
		state_changed.emit(self, "BombAndRun")
		return
	if is_enemy_near():
		state_changed.emit(self, "FollowTarget")
		return

# Choose random point to wander to and create pathing
func randomize_target():
	var offset = area.position
	var end = area.end
	var valid_point = false
	var number_generator = RandomNumberGenerator.new()
	var new_target : Vector2i
	while !valid_point:
		# Generate random cell to move to
		var posx = number_generator.randi_range(offset.x, end.x-1)
		var posy = number_generator.randi_range(offset.y, end.y-1)
		new_target = Vector2i(posx, posy)
		# If the point is valid, finish
		if (!is_unbreakable(new_target, offset) and is_near(new_target)):
			valid_point = true
	path = world.create_path(aiplayer, new_target)
	# Remove first point in path which is the current position
	path.pop_front()

# Check if point is within a range
func is_near(point : Vector2i) -> bool:
	var range = 4
	var current_cell = get_cell_position(aiplayer.global_position)
	if (current_cell == point):
		return false
	var validation_x = current_cell.x-range < point.x and point.x < current_cell.x+range
	var validation_y = current_cell.y-range < point.y and point.y < current_cell.y+range
	return validation_x and validation_y
	
func is_unbreakable(point : Vector2i, offset : Vector2i) -> bool:
	return (point.x-offset.x+1)%2==0 and (point.y-offset.y+1)%2==0

func is_breakable_near() -> bool:
	# TODO
	return false

func is_enemy_near() -> bool:
	# TODO
	return false

func is_bomb_near() -> bool:
	# TODO
	return false
