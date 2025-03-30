extends MultiplayerSpawner
const BREAKABLE_SCENE_PATH : String = "res://scenes/exit.tscn"


func _init():
	spawn_function = spawn_breakable
	
func spawn_breakable(color_data: Color):
	var exit = load(BREAKABLE_SCENE_PATH).instantiate()
	exit.hide()
	exit.modulate = color_data
	return exit
