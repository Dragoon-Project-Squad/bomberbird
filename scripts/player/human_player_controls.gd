extends Node

var motion = Vector2():
	set(value):
		# This will be sent by players, make sure values are within limits.
		motion = clamp(value, Vector2(-1, -1), Vector2(1, 1))

var bombing := false
var throw_ability := false
var punch_ability := false
var secondary_ability := false
var last_input = Vector2(0,0)

func update():
	var m = Vector2()
	if Input.is_action_pressed("move_left"):
		m += Vector2(-1, 0)
	if Input.is_action_pressed("move_right"):
		m += Vector2(1, 0)
	if Input.is_action_pressed("move_up"):
		m += Vector2(0, -1)
	if Input.is_action_pressed("move_down"):
		m += Vector2(0, 1)
	if m == Vector2(0,0) and get_parent().is_nonstop:
		m = last_input
	else:
		last_input = m
	if get_parent().is_reverse:
		m *= Vector2(-1, -1)
	motion = m
	bombing = Input.is_action_pressed("set_bomb")
	throw_ability = Input.is_action_just_released("set_bomb")
	punch_ability = Input.is_action_pressed("punch_action")
	secondary_ability = Input.is_action_just_pressed("secondary_action")
