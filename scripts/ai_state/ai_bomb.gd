extends State
class_name AIBombing

func _physics_update(_delta : float) -> void:
	if !aiplayer.stunned && aiplayer.last_bomb_time >= aiplayer.BOMB_RATE:
		aiplayer.place_bomb()
	state_changed.emit(self, "Dodge")
