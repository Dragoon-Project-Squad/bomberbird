extends MultiplayerSpawner
const BREAKABLE_SCENE_PATH : String = "res://scenes/exit.tscn"


func _init():
	spawn_function = spawn_breakable
	
func spawn_breakable(color):
	var exit = load(BREAKABLE_SCENE_PATH).instantiate()
	exit.hide.call_deferred()
	exit.set_deferred("modulate", color)
	return exit
