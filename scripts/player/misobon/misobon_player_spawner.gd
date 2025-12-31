extends MultiplayerSpawner

var misobon_player_scene := preload("res://scenes/misobon_human_player.tscn")
var misobon_aiplayer_scene := preload("res://scenes/misobon_ai_player.tscn")

func _init():
	spawn_function = _spawn_misobon_player

func _ready() -> void:
	globals.game.misobon_player_spawner = self

#data is an dict of size 4, with the following types: {player_type: String, spawn_here: float, pid: int, name: string]
func _spawn_misobon_player(data) -> MisobonPlayer:
	if data.size() != 4 || typeof(data.player_type) != TYPE_STRING || typeof(data.spawn_here) != TYPE_FLOAT || typeof(data.pid) != TYPE_INT || typeof(data.name) != TYPE_STRING:
		push_error("Data for _spawn_misobon_player(data) is of the wrong format: ", data)
		return null

	var misobon_player: MisobonPlayer
	if data.player_type == "human":
		print_debug("Instantiated a human's misobon.")
		misobon_player = misobon_player_scene.instantiate()
	elif data.player_type == "ai":
		print_debug("Instantiated an AI's misobon.")
		misobon_player = misobon_aiplayer_scene.instantiate()
	else:
		push_error("data contained an unknown player type")
		return null
	misobon_player.progress = data.spawn_here
	misobon_player.name = str(data.pid)
	misobon_player.set_player_name(data.name)
	print_debug("Progress: " + str(misobon_player.get_progress()) + "/ Name: " + misobon_player.get_name() + "/ Player Name: " + misobon_player.get_player_name())
	return misobon_player
