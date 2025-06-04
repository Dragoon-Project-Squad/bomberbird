extends MisobonAiState

func _update(_delta: float) ->void:
	if player.last_bomb_time >= player.BOMB_RATE:
		player.throw_bomb()
	state_changed.emit(self, "Wander")
