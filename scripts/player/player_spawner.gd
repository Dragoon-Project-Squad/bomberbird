extends MultiplayerSpawner

var player_scene = preload("res://scenes/human_player.tscn")
var ai_player_scene = preload("res://scenes/ai_player.tscn")

func _init():
	spawn_function = _spawn_player

func _ready() -> void:
	globals.game.player_spawner = self

func _spawn_player(data) -> Player:
	var spawningplayer: Player
	if data.playertype == "human":
		spawningplayer = player_scene.instantiate()
	else:
		spawningplayer = ai_player_scene.instantiate()
	spawningplayer.synced_position = data.spawndata
	spawningplayer.name = str(data.pid)
	spawningplayer.set_player_name(data.defaultname if data.pid == multiplayer.get_unique_id() || data.pid == 1 else data.playerdict.playername)
	spawningplayer.set_selected_spritepaths(data.playerdict.spritepaths)
	return spawningplayer
