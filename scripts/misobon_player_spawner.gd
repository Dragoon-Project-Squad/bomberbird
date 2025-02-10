extends MultiplayerSpawner

var misobon_player_scene := preload("res://scenes/misobon_player.tscn")
#TODO preload AI misobon player

func _init():
	spawn_function = _spawn_misobon_player

#data is an dict of size 4, with the following types: {player_type: String, spawn_here: float, pid: int, name: string]
func _spawn_misobon_player(data) -> PathFollow2D:
	var misobon_player
	if data.player_type == "human":
		misobon_player = misobon_player_scene.instantiate()
	else:
		printerr("ups this is not yet implemented. This will likely cause a crash!")
		pass #TODO instantiate AI misobon player
	misobon_player.synced_progress = data.spawn_here
	misobon_player.name = str(data.pid)
	misobon_player.set_player_name(data.name)

	return misobon_player
