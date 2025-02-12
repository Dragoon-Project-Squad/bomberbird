extends MultiplayerSpawner
@export var bomb_audio_stream : AudioStreamWAV = load("res://sound/fx/bombdrop.wav")
@onready var bomb_placement_sfx_player := $BombPlacementSFXPlayer 

func _init():
	spawn_function = _spawn_bomb

#TODO as spawning a bomb does not place it anymore this has to be move to the bomb itself
func _ready():
	bomb_placement_sfx_player.set_stream(bomb_audio_stream)


func _spawn_bomb(data):
	if data.size() != 1 or typeof(data[0]) != TYPE_INT:
		push_error("Corrupt data sent to bomb spawner. Bomb not spawned. data.size():", data.size(), ", data", data)
		return null
	var bomb := preload("res://scenes/bomb/bomb_root.tscn").instantiate()
	bomb._ready()
	bomb.set_bomb_owner(get_node("/root/World/Players/" + str(data[0])))
	bomb.set_state(bomb.DISABLED)
	return bomb
