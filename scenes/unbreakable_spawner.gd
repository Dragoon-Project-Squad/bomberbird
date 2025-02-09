extends MultiplayerSpawner
const BREAKABLE_SCENE_PATH : String = "res://scenes/unbreakable.tscn"

func _init():
	spawn_function = place_unbreakable
	
func place_unbreakable(spawncoords: Vector2):
	var unbreakable = preload(BREAKABLE_SCENE_PATH).instantiate()
	unbreakable.position = spawncoords
	return unbreakable
