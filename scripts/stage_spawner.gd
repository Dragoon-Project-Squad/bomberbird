extends MultiplayerSpawner

func _init():
	spawn_function = spawn_stage
	
func spawn_stage(path: String):
	assert(path != null)
	var stage: World = load(path).instantiate()
	return stage
