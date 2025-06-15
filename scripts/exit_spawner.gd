extends MultiplayerSpawner
const EXIT_SCENE_PATH : String = "res://scenes/exit.tscn"


func _init():
	spawn_function = spawn_exit
	
func spawn_exit(_data):
	var exit = load(EXIT_SCENE_PATH).instantiate()
	return exit
