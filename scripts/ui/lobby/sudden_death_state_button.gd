extends BattleSettingControl

@onready var checkbox: CheckBox = $HBoxContainer/Checkbox

func load_data() -> void:
	set_initial_button_state()

func set_initial_button_state() -> void:
	checkbox.button_pressed = SettingsContainer.get_sudden_death_state()
	set_button_text_to_state(SettingsContainer.get_sudden_death_state())
	
func set_button_text_to_state(a_state : bool) -> void:
	if a_state:
		checkbox.text = "On"
	else:
		checkbox.text = "Off"
		
func _on_checkbox_toggled(toggled_on: bool) -> void:
	SettingsSignalBus.emit_on_sudden_death_state_set(toggled_on)
	set_button_text_to_state(toggled_on)

func disable() -> void:
	checkbox.disabled = true
