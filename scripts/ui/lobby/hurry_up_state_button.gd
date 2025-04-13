extends Control

@onready var label: Label = $HBoxContainer/Label
@onready var checkbox: CheckBox = $HBoxContainer/Checkbox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_data()
	
func load_data() -> void:
	_on_checkbox_toggled(SettingsContainer.get_hurry_up_state())
	set_initial_button_state()
	
func set_initial_button_state() -> void:
	checkbox.button_pressed = SettingsContainer.get_hurry_up_state()
	set_button_text_to_state(SettingsContainer.get_hurry_up_state())
	
func set_button_text_to_state(a_state : bool) -> void:
	if a_state:
		checkbox.text = "On"
	else:
		checkbox.text = "Off"

func _on_checkbox_toggled(toggled_on: bool) -> void:
	SettingsSignalBus.emit_on_hurry_up_state_set(toggled_on)
	set_button_text_to_state(toggled_on)
