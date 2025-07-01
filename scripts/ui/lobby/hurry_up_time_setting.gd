extends BattleSettingControl

@onready var h_slider: HSlider = $HBoxContainer/HSlider
@onready var slider_number_label: Label = $HBoxContainer/SliderNumberLabel
	
func load_data() -> void:
	set_slider_value(SettingsContainer.get_hurry_up_time())
	set_chance_num_label_text()
	
func set_slider_value(newval : int) -> void:
	h_slider.value = newval
	
func set_chance_num_label_text() -> void:
	slider_number_label.text = time_to_string(h_slider.value)

func time_to_string(time := 120.0) -> String:
	var seconds = fmod(time, 60)
	var minutes = time / 60
	var format_string = "%02d:%02d"
	var actual_time_string = format_string % [minutes, seconds]
	return actual_time_string
	
func _on_value_changed(value: float) -> void:
	set_chance_num_label_text()
	SettingsSignalBus.emit_on_hurry_up_time_set(value)

func disable() -> void:
	h_slider.editable = false
