extends Node

@onready var mus_player: AudioStreamPlayer2D = $MusicPlayer

var music_dir_path: String = "res://sound/mus/battle/"

func _ready() -> void:
	dir_contents(music_dir_path)

func play() -> void:
	mus_player.play()

func stop() -> void:
	mus_player.stop()

func dir_contents(path: String):
	var dir: DirAccess = DirAccess.open(path)
	var index: int = 0
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "": # As by the godot documentation get_next() will close the stream if its done and return the empty string hence closing the stream manually is not mandatory
			if file_name.get_extension() == "ogg":
				loadstream(index, load(path + file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the music path.")

func loadstream(index: int, this_stream: AudioStreamOggVorbis):
	if this_stream == null:
		return
	if mus_player.playing:
		mus_player.stop()
	mus_player.stream.add_stream(index, this_stream)
	this_stream.loop = true
	index = index + 1
