extends Control


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass
	
func _on_exit_pressed() -> void:
	SettingsSignalBus.emit_set_settings_dictionary(SettingsContainer.create_sotrage_dictionary())
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
