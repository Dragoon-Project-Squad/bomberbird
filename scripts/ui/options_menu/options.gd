extends Control

@onready var settings_tab_container: SettingsTabContainer = $MarginContainer/VBoxContainer/SettingsTabContainer

@export var options_music: WwiseEvent

signal options_menu_exited

func _ready():
	settings_tab_container.options_menu_exited.connect(_on_exit_pressed)

func switch_to_main_menu() -> void:
	self.visible = false
	options_menu_exited.emit()
	
func _on_exit_pressed() -> void:
	if self.visible:
		# stops the options menu music in the OptionsMenu node
		options_music.stop(self)
		SettingsSignalBus.emit_set_settings_dictionary(SettingsContainer.create_storage_dictionary())
		switch_to_main_menu()
		#get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
