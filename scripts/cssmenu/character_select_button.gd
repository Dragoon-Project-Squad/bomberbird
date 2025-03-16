extends TextureButton
class_name CharacterSelectButton
signal peer_pressed(id)

func get_texture_normal_path() -> String:
	return self.texture_normal.resource_path
	
func _on_pressed() -> void:
	var id = get_peer_button_pressed()
	peer_pressed.emit(id)
	
@rpc("any_peer")
func get_peer_button_pressed() -> int:
	var id = multiplayer.get_remote_sender_id()
	print("The person who clicked this button is: ", id)
	return id
