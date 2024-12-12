extends Node2D

var music : AudioStreamOggVorbis = load("res://sound/mus/alpha_dance.ogg")
@onready var mus_player := $MusicPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mus_player.set_stream(music)
	mus_player.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
