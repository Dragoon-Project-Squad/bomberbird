extends Control

func _on_confirm_button_pressed() -> void:
	SettingsSignalBus.emit_set_settings_dictionary(SettingsContainer.create_storage_dictionary())
	get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
