extends MultiplayerSpawner

var player_scene = preload("res://scenes/player.tscn")
var ai_player_scene = preload("res://scenes/aiplayer.tscn")

func _init():
	spawn_function = _spawn_player

func _spawn_player(data) -> CharacterBody2D:
		var spawningplayer
		if data.playertype == "human":
			spawningplayer = player_scene.instantiate()
		else:
			spawningplayer = ai_player_scene.instantiate()
		#$"../Players".add_child(spawningplayer)
		spawningplayer.synced_position = data.spawndata
		spawningplayer.name = str(data.pid)
		print("Data: ",data)
		print("Multiplayer Unique ID: ", multiplayer.get_unique_id())
		if data.pid == multiplayer.get_unique_id():
			print("Chosen Name: ", data.defaultname)
		elif (data.pid == 1):
			print("Derived Name: ", data.defaultname)
		else:
			print("Derived Name: ", data.playerdictionary[data.pid])
		spawningplayer.set_player_name(data.defaultname if data.pid == multiplayer.get_unique_id() || data.pid == 1 else data.playerdictionary[data.pid])
		return spawningplayer
