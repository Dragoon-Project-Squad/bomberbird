extends Resource

const SAVE_PATH = "user://saves"

static func save(file_name: String, save_data: Dictionary):
	var file_access := FileAccess.open(SAVE_PATH + "/" + file_name + ".json", FileAccess.WRITE)
	if not file_access:
		print("An error happened while saving data: ", FileAccess.get_open_error())
		return
	file_access.store_line(JSON.stringify(save_data))
	file_access.close()
	pass


static func load(file_name: String) -> Dictionary:
	var file_access := FileAccess.open(SAVE_PATH + "/" + file_name + ".json", FileAccess.READ)
	var json_string: String = file_access.get_as_text()
	file_access.close()

	var json: JSON = JSON.new()
	if json.parse(json_string):
		push_error("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return {}
	return json.data
