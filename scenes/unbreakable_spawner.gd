extends MultiplayerSpawner
const UNBREAKABLE_SCENE_PATH : String = "res://scenes/unbreakable.tscn"

func _init():
	spawn_function = place_unbreakable
	
func place_unbreakable(spawncoords: Vector2):
	var unbreakable = preload(UNBREAKABLE_SCENE_PATH).instantiate()
	unbreakable.position = spawncoords
	return unbreakable
