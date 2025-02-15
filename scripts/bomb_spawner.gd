extends MultiplayerSpawner

func _init():
	spawn_function = _spawn_bomb

#TODO as spawning a bomb does not place it anymore this has to be move to the bomb itself
func _ready():
	pass

func _spawn_bomb(data):
	if data != []:
		push_error("Corrupt data sent to bomb spawner. Bomb not spawned. data.size():", data.size(), ", data", data)
		return null
	var bomb := preload("res://scenes/bombs/bomb_root.tscn").instantiate()
	bomb._ready()
	bomb.set_state(bomb.DISABLED)
	return bomb
