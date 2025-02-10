extends Node

@export
var motion: float = 0:
	set(value):
		# This will be sent by players, make sure values are within limits.
		motion = clamp(value, -1, 1)

@export
var bombing: bool = false

func update(seg_information: Array[bool]):
	var m: float = 0
	var key = ["move_right", "move_down", "move_left", "move_up"]

	# decides on if with relation to the input we should move forwards or backwards in the path
	for i in range(4):
		#if the player is not on this section of the path, continue to next section
		if Input.is_action_pressed(key[i]) && (seg_information[i] || seg_information[i + 4]): #move forward in the path
			m += 1
		if Input.is_action_pressed(key[(i+2) % 4]) && (seg_information[i] || seg_information[i + 8]): #move backwards in the path
			m -= 1

	motion = m
	bombing = Input.is_action_pressed("set_bomb")
