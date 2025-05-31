extends Node2D
# implements a costum detection type based on signals

@export var start_time: float = 12
@onready var enemy: Enemy = get_parent()

var had_signal: bool = false

func _ready() -> void:
	get_tree().create_timer(start_time).timeout.connect(_set_check, CONNECT_ONE_SHOT)

func check_for_priority_target():
	enemy.statemachine.target = null
	if had_signal:
		had_signal = false
		return true
	return false

func _set_check():
	had_signal = true

func on():
	pass

func off():
	pass
