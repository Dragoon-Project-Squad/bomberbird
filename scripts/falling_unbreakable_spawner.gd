extends MultiplayerSpawner
const FALLING_SCENE_PATH : String = "res://scenes/falling_unbreakable.tscn"


func _init():
	spawn_function = spawn_breakable
	
func spawn_breakable(_data):
	var falling_breakable = load(FALLING_SCENE_PATH).instantiate()
	return falling_breakable
