extends Node

@export var motion = Vector2():
	set(value):
		# This will be sent by players, make sure values are within limits.
		motion = clamp(value, Vector2(-1, -1), Vector2(1, 1))

@export var bombing := false
@export var hold_bomb := false
@export var throw_ability := false
@export var punch_ability := false
@export var secondary_ability := false
@export var remote_ability := false
@export var last_input = Vector2(0,0)
## Keep these as exports so the InputsSync can see them

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
	punch_ability = Input.is_action_pressed("punch_action")
	secondary_ability = Input.is_action_just_pressed("secondary_action")
	remote_ability = Input.is_action_just_pressed("detonate_rc")
