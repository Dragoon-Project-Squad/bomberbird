extends Control

@onready var audio_name_label: Label = $HBoxContainer/AudioNameLabel
@onready var audio_number_label: Label = $HBoxContainer/AudioNumberLabel
@onready var h_slider: HSlider = $HBoxContainer/HSlider

@export_enum("Master", "Music", "SFX") var bus_name : String

var bus_index := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_bus_name_by_index()
	set_audio_name_label_text()
	set_slider_value()
	
func set_audio_name_label_text() -> void:
	audio_name_label.text = str(bus_name) + " Volume"
	
func set_audio_num_label_text() -> void:
	audio_number_label.text = str(h_slider.value * 100)

func get_bus_name_by_index() -> void:
	bus_index = AudioServer.get_bus_index(bus_name)

func set_slider_value() -> void:
	h_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	set_audio_num_label_text()

func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	set_audio_num_label_text()
	
	match bus_index:
		0:
			SettingsSignalBus.emit_on_master_sound_set(value)
		1:
			SettingsSignalBus.emit_on_music_sound_set(value)
		2:
			SettingsSignalBus.emit_on_sfx_sound_set(value)
