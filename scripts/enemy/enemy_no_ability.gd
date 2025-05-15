extends EnemyState

func _enter() -> void:
	state_changed.emit(self, "wander")
