extends TextureButton
class_name CharacterSelectButton
signal peer_pressed(id)
	
func _on_pressed() -> void:
	peer_pressed.emit(multiplayer.get_unique_id())
