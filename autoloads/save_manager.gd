extends Node

const SETTINGS_SAVE_PATH : String = "user://settingsdata.save"
const SECRET_SAVE_PATH : String = "user://bomberbird.secret"

var settings_data_dict : Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SettingsSignalBus.set_settings_dictionary.connect(on_settings_save)
	SettingsSignalBus.set_secret_file_data.connect(on_secret_save)
	load_settings_data()
	load_secret_data()
	
func on_settings_save(data : Dictionary) -> void:
	var save_settings_data_file = FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.WRITE)
	var json_data_string = JSON.stringify(data)
	save_settings_data_file.store_line(json_data_string)

func load_settings_data() -> void:
	if not FileAccess.file_exists(SETTINGS_SAVE_PATH):
		push_warning("No settings save data found!")
		return
	
	var save_settings_data_file = FileAccess.open(SETTINGS_SAVE_PATH, FileAccess.READ)
	var loaded_json : Dictionary = {}
	
	while save_settings_data_file.get_position() < save_settings_data_file.get_length():
		var json_string = save_settings_data_file.get_line()
		var json = JSON.new()
		var _parsed_result = json.parse(json_string)
		
		loaded_json = json.get_data()
		
	SettingsSignalBus.emit_load_settings_data(loaded_json)
	loaded_json = {}

func on_secret_save(data : Dictionary) -> void:
	var secret_data_file = FileAccess.open(SECRET_SAVE_PATH, FileAccess.WRITE)
	var json_data_string = JSON.stringify(data)
	secret_data_file.store_line(json_data_string)

func on_secret_delete():
	if !FileAccess.file_exists(SECRET_SAVE_PATH):
		push_error("attempted to delete a nonexisting secret_file: " + SECRET_SAVE_PATH)
		return
	DirAccess.remove_absolute(SECRET_SAVE_PATH)

func load_secret_data() -> void:
	if not FileAccess.file_exists(SECRET_SAVE_PATH):
		return
	var secret_data_file = FileAccess.open(SECRET_SAVE_PATH, FileAccess.READ)
	var loaded_json : Dictionary = {}
	
	while secret_data_file.get_position() < secret_data_file.get_length():
		var json_string = secret_data_file.get_line()
		var json = JSON.new()
		var _parsed_result = json.parse(json_string)
		
		loaded_json = json.get_data()
		
	SettingsSignalBus.emit_load_secret_data(loaded_json)
	loaded_json = {}
