extends Node

@export var speed_boost: float = 1.5
var already_applied: bool = false

func apply():
	assert(!already_applied)
	get_parent().movement_speed *= speed_boost
