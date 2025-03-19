extends TextureButton
class_name CharacterSelectButton
signal peer_pressed()
	
func _on_pressed() -> void:
	peer_pressed.emit()
