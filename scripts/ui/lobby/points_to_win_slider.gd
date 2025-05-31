extends BattleSettingControl

@onready var h_slider: HSlider = $HBoxContainer/HSlider
@onready var slider_number_label: Label = $HBoxContainer/SliderNumberLabel

# Called when the node enters the scene tree for the first time.
func load_data() -> void:
	set_slider_value(SettingsContainer.get_points_to_win())
	set_chance_num_label_text()

func set_slider_value(newval : int) -> void:
	h_slider.value = newval

func set_chance_num_label_text() -> void:
	slider_number_label.text = str(int(h_slider.value))

func _on_value_changed(value: float) -> void:
	set_chance_num_label_text()
	SettingsSignalBus.emit_on_points_to_win_set(value)

func disable() -> void:
	h_slider.editable = false
