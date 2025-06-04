extends MultiplayerSpawner
const BREAKABLE_SCENE_PATH : String = "res://scenes/breakable.tscn"


func _init():
	spawn_function = spawn_breakable
	
func spawn_breakable(_data):
	var breakable = load(BREAKABLE_SCENE_PATH).instantiate()
	breakable.disable()
	return breakable
