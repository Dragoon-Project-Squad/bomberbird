extends Node

@export
var motion: float = 0:
	set(value):
		# This will be sent by players, make sure values are within limits.
		motion = clamp(value, -1, 1)

@export
var bombing: bool = false

func update(path_pos: float, path_seg_length: int, grace: int):
	var m: float = 0
	var rel_path_pos: float = int(path_pos) % (path_seg_length * 4)
	rel_path_pos = rel_path_pos + (path_pos - int(path_pos)) #this is some hacky shit that depending on grace may be unnessessary.

	var key = ["move_left", "move_up", "move_right", "move_down"]

	# decides on if with relation to the input we should move forwards or backwards in the path
	for i in range(4):
		#if the player is not on this section of the path, continue to next section
		if (i * path_seg_length - grace <= rel_path_pos && rel_path_pos <= (i+1) * path_seg_length + grace): continue

		if Input.is_action_pressed(key[i]): #move forward in the path
			m += 1
		if Input.is_action_pressed(key[(i+2) % 4]): #move backwards in the path
			m -= 1

	motion = m
	bombing = Input.is_action_pressed("set_bomb")
