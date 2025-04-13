extends Control

@onready var h_slider: HSlider = $HBoxContainer/HSlider
@onready var slider_number_label: Label = $HBoxContainer/SliderNumberLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_data()
	
func load_data() -> void:
	_on_value_changed(SettingsContainer.get_pickup_chance())
	set_chance_num_label_text()
	
func set_chance_num_label_text() -> void:
	slider_number_label.text = str(h_slider.value) + "%"

func _on_value_changed(value: float) -> void:
	set_chance_num_label_text()
	SettingsSignalBus.emit_on_pickup_chance_set(value)
