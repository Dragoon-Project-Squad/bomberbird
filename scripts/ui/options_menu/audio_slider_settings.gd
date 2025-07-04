extends Control

@onready var audio_name_label: Label = $HBoxContainer/AudioNameLabel
@onready var audio_number_label: Label = $HBoxContainer/AudioNumberLabel
@onready var h_slider: HSlider = $HBoxContainer/HSlider

@export_enum("Master", "Music", "SFX") var bus_name : String

var bus_index := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_bus_name_by_index()
	load_data()
	set_audio_name_label_text()
	set_slider_value()
	
func load_data() -> void:
	match bus_name:
		"Master":
			_on_value_changed(SettingsContainer.get_master_volume())
		"Music":
			_on_value_changed(SettingsContainer.get_music_volume())
		"SFX":
			_on_value_changed(SettingsContainer.get_sfx_volume())
			
func set_audio_name_label_text() -> void:
	audio_name_label.text = str(bus_name) + " Volume"
	
func set_audio_num_label_text() -> void:
	audio_number_label.text = str(h_slider.value * 100)

func get_bus_name_by_index() -> void:
	#bus_index = AudioServer.get_bus_index(bus_name)
	match bus_name:
		"Master": bus_index = 0
		"Music": bus_index = 1
		"SFX": bus_index = 2

func set_slider_value() -> void:
	h_slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	#h_slider.value = Wwise.get_rtpc_value(bus_name, null)
	set_audio_num_label_text()

func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	Wwise.set_rtpc_value(bus_name, value, null)
	set_audio_num_label_text()
	
	match bus_index:
		0:
			SettingsSignalBus.emit_on_master_sound_set(value)
		1:
			SettingsSignalBus.emit_on_music_sound_set(value)
		2:
			SettingsSignalBus.emit_on_sfx_sound_set(value)
