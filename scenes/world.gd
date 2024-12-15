extends Node2D

var music_dir_path : String = "res://sound/mus/"
@onready var mus_player := $MusicPlayer

func _ready() -> void:
	dir_contents(music_dir_path)
	mus_player.play()

func dir_contents(path):
	var dir = DirAccess.open(path)
	var index = 0
	var file_name
	var stream: AudioStreamOggVorbis
	if dir:
		dir.list_dir_begin()
		file_name = dir.get_next()
		while file_name != "":
			if file_name.get_extension() == "ogg":
				stream = load(path+file_name)
				stream.loop = true
				mus_player.stream.add_stream(index, stream)
				index = index + 1
			elif dir.current_is_dir():
				print("Found directory: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
