extends Control

@onready var label: Label = $HBoxContainer/Label
@onready var checkbox: CheckBox = $HBoxContainer/Checkbox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_data()
	
func load_data() -> void:
	_on_checkbox_toggled(SettingsContainer.get_hurry_up_state())

func _on_checkbox_toggled(toggled_on: bool) -> void:
	SettingsSignalBus.emit_on_hurry_up_state_set(toggled_on)
	if toggled_on:
		checkbox.text = "On"
	else:
		checkbox.text = "Off"
