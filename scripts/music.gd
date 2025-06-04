extends Node

@onready var mus_player: AudioStreamPlayer2D = $MusicPlayer

func play() -> void:
	mus_player.play()

func stop() -> void:
	mus_player.stop()
