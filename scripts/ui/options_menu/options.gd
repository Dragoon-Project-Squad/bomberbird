extends Control

@onready var options_music_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var settings_tab_container: SettingsTabContainer = $MarginContainer/VBoxContainer/SettingsTabContainer

signal options_menu_exited

func _ready():
	settings_tab_container.options_menu_exited.connect(_on_exit_pressed)

func stop_options_menu_music() -> void:
	options_music_player.stop()

func switch_to_main_menu() -> void:
	self.visible = false
	options_menu_exited.emit()
	
func _on_exit_pressed() -> void:
	SettingsSignalBus.emit_set_settings_dictionary(SettingsContainer.create_storage_dictionary())
	stop_options_menu_music()
	switch_to_main_menu()
	#get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
