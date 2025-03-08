extends Node

var window_mode_index := 0
var resolution_index := 0
var master_volume := 0.0
var music_volume := 0.0
var sfx_volume := 0.0

var loaded_data : Dictionary = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	handle_signals()

func create_sotrage_dictionary() -> Dictionary:
	var settings_container_dict : Dictionary = {
		"window_mode_index" : window_mode_index,
		"resolution_index" : resolution_index,
		"master_volume" : master_volume,
		"music_volume" : music_volume,
		"sfx_volume" : sfx_volume
	}
	return settings_container_dict


func set_window_mode(index : int) -> void:
	window_mode_index = index

func set_resolution(index : int) -> void:
	resolution_index = index
	
func set_master_vol(value : float) -> void:
	master_volume = value
	
func set_music_vol(value : float) -> void:
	music_volume = value
	
func set_sfx_vol(value : float) -> void:
	sfx_volume = value

func on_settings_data_loaded(data : Dictionary) -> void:
	loaded_data = data
	print(loaded_data)
	set_window_mode(loaded_data.window_mode_index)
	set_resolution(loaded_data.window_mode_index)
	set_master_vol(loaded_data.master_volume)
	set_music_vol(loaded_data.music_volume)
	set_sfx_vol(loaded_data.sfx_volume)

func handle_signals() -> void:
	SettingsSignalBus.on_window_mode_selected.connect(set_window_mode)
	SettingsSignalBus.on_resolution_selected.connect(set_resolution)
	SettingsSignalBus.on_master_sound_set.connect(set_master_vol)
	SettingsSignalBus.on_music_sound_set.connect(set_music_vol)
	SettingsSignalBus.on_sfx_sound_set.connect(set_sfx_vol)
	SettingsSignalBus.load_settings_data.connect(on_settings_data_loaded)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
