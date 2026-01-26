extends MultiplayerSpawner

var player_scene = preload("res://scenes/human_player.tscn")
var ai_player_scene = preload("res://scenes/ai_player.tscn")

func _init():
	spawn_function = _spawn_player

func _ready() -> void:
	globals.game.player_spawner = self

func print_stuff(data):
	print("The Spawned Player's Name is ", str(data.pid))
	print("The Spawned Player's PID is ", data.pid)
	print("The person who called this method's Unique ID is ", multiplayer.get_unique_id())
	print("The playerdict's name for this person is ", data.playerdict.playername)
	
func _spawn_player(data) -> Player:
	var spawningplayer: Player
	if data.playertype == "human":
		spawningplayer = player_scene.instantiate()
	else:
		spawningplayer = ai_player_scene.instantiate()
	spawningplayer.synced_position = data.spawndata
	spawningplayer.name = str(data.pid)
	spawningplayer.set_player_name(data.playerdict.playername)
	if data.playertype == "human":
		spawningplayer.set_authority_during_spawn()
	spawningplayer.set_selected_spritepaths(data.playerdict.spritepaths)
	return spawningplayer
