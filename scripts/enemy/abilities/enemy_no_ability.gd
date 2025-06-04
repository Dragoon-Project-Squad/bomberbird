extends EnemyState
# Handles enemies without ability

func _enter() -> void:
	state_changed.emit(self, "wander")
