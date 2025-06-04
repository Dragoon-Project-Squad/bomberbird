extends MultiplayerSpawner


func _init():
	spawn_function = spawn_enemy
	
func spawn_enemy(data: String):
	var enemy = load(data).instantiate()
	return enemy 
