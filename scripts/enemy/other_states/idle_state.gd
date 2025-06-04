extends EnemyState

@export var idle_time: float = 1.2
@export var safe_check_time: float = 0.1

var idle_timeout: float = 0
var safe_check_timeout: float = 0

func _enter():
	self.enemy.movement_vector = Vector2.ZERO
	idle_timeout = 0
	safe_check_timeout = 0

func _physics_update(delta: float) -> void:
	idle_timeout += delta
	safe_check_time += delta
	if safe_check_timeout >= safe_check_time && !world_data.is_safe(self.enemy.position):
		state_changed.emit(self, "dodge")
	elif safe_check_timeout >= safe_check_time:
		safe_check_timeout = 0
	if idle_timeout >= idle_time:
		state_changed.emit(self, "wander")
