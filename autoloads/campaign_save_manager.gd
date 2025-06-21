extends Node

signal has_saved(file: String)
signal has_loaded(file: String)

const SAVE_PATH: String = "user://save_data"
const EMPTY_SAVE: Dictionary = {
	"campaign": "",
	"campaign_version": LevelGraph.VERSION,
	"player_name": "Player1",
	"character_paths": "", 
	"player_health": 3,
	"player_pickups": {},
	"last_stage": 0,
	"visited_exits": {}, # contains dicts with {"stage: int", "exit: Array[int]" } of exits that have already been visited in this safe
	"current_score": 0,
	"exit_count": -1,
	"has_finished": false,
	"fresh_save": true,
	}

func save(data: Dictionary, file_name: String) -> void:
	if !FileAccess.file_exists(SAVE_PATH):
		DirAccess.make_dir_recursive_absolute(SAVE_PATH)

	var file_access := FileAccess.open(SAVE_PATH + "/" + file_name + ".json", FileAccess.WRITE)
	if not file_access:
		print("An error happened while saving data: ", FileAccess.get_open_error())
		return
	file_access.store_line(JSON.stringify(data))
	file_access.close()
	has_saved.emit(file_name)

func delete_save(file_name: String) -> void:
	if !FileAccess.file_exists(SAVE_PATH + "/" + file_name + ".json"):
		push_error("attempted to delete a nonexisting save: " + file_name + ".json")
		return
	DirAccess.remove_absolute(SAVE_PATH + "/" + file_name + ".json")

func save_exist(file_name: String) -> bool:
	return FileAccess.file_exists(SAVE_PATH + "/" + file_name + ".json")

func load(file_name: String) -> Dictionary:
	if !FileAccess.file_exists(SAVE_PATH + "/" + file_name + ".json"):
		push_error("attempted to load a nonexisting save: " + file_name + ".json")
		return EMPTY_SAVE.duplicate(true)
	var file_access := FileAccess.open(SAVE_PATH + "/" + file_name + ".json", FileAccess.READ)
	var json_string := file_access.get_line()
	file_access.close()

	var json: JSON = JSON.new()
	var error := json.parse(json_string)
	if error:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return EMPTY_SAVE.duplicate(true)

	var save_file: Dictionary = json.data.duplicate(true)
	save_file.visited_exits.clear()
	save_file.player_pickups.clear()
	for stage_str in json.data.visited_exits.keys():
		var stage: int = int(stage_str)
		save_file.visited_exits[stage] = {}
		for exit_str in json.data.visited_exits[stage_str].keys():
			save_file.visited_exits[stage][int(exit_str)] = null
	for pickup in json.data.player_pickups.keys():
		save_file.player_pickups[int(pickup)] = json.data.player_pickups[pickup]

	has_loaded.emit(file_name)
	return save_file

func get_new_save() -> Dictionary:
	return EMPTY_SAVE.duplicate(true)
	
