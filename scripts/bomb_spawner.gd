extends MultiplayerSpawner
@export var bomb_audio_stream : AudioStreamWAV = load("res://sound/fx/bombdrop.wav")
@onready var bomb_placement_sfx_player := $BombPlacementSFXPlayer 

func _init():
	spawn_function = _spawn_bomb

func _ready():
	bomb_placement_sfx_player.set_stream(bomb_audio_stream)


func _spawn_bomb(data):
	if data.size() < 2 or typeof(data[0]) != TYPE_VECTOR2 or typeof(data[1]) != TYPE_INT:
		push_error("Corrupt data sent to bomb spawner. Bomb not spawned. Output: ", data)
		return null
	bomb_placement_sfx_player.play()
	var bomb = preload("res://scenes/bomb.tscn").instantiate()
	bomb.position = data[0]
	bomb.from_player = data[1]
	# Increase explosion power by spawning player's boosts
	if data[2] and typeof(data[2]) == TYPE_INT:
		bomb.explosion_level = min(data[2] + bomb.explosion_level, 3)
	return bomb
