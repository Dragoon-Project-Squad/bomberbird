extends Control

@onready var title_sceen: Node2D = $"../TitleSceen"
@onready var button_box: VBoxContainer = $"../ButtonBox"


func switch_to_main_menu() -> void:
	self.visible = false
	title_sceen.visible = true
	button_box.visible = true
	
func _on_exit_pressed() -> void:
	SettingsSignalBus.emit_set_settings_dictionary(SettingsContainer.create_sotrage_dictionary())
	switch_to_main_menu()
	#get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
