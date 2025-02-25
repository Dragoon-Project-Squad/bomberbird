extends State
class_name AIBombing

func _physics_update(_delta : float) -> void:
	aiplayer.place_bomb()
	state_changed.emit(self, "Wander")
