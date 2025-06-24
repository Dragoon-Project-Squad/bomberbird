extends Timer
# implements a costum detection type based on signals

@export var start_time: float = 12
@onready var enemy: Enemy = get_parent()

var had_signal: bool = false

func _ready() -> void:
	self.one_shot = true

func check_for_priority_target():
	enemy.statemachine.target = null
	if had_signal:
		had_signal = false
		return true
	return false

func _set_check():
	had_signal = true

func on():
	self.start(start_time)
	self.timeout.connect(_set_check, CONNECT_ONE_SHOT)
	had_signal = false

func off():
	self.stop()
	if self.timeout.has_connections():
		self.timeout.disconnect(_set_check)
	had_signal = false
	pass
