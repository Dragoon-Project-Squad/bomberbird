extends Node

var motion = Vector2():
	set(value):
		# This will be sent by players, make sure values are within limits.
		motion = clamp(value, Vector2(-1, -1), Vector2(1, 1))

var bombing := false
var throw_ability := false
var punch_ability := false
var secondary_ability := false

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

	motion = m
	bombing = Input.is_action_pressed("set_bomb")
	throw_ability = Input.is_action_just_released("set_bomb")
	punch_ability = Input.is_action_pressed("punch_action")
	secondary_ability = Input.is_action_just_pressed("secondary_action")
