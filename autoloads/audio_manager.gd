# Copyright © 2019-2020 Hugo Locurcio and contributors - MIT License
# See `LICENSE.md` included in the source distribution for details.
# https://github.com/Calinou/escape-space/blob/master/autoload/sound.gd

extends Node

enum Type {
	NON_POSITIONAL,
	POSITIONAL_2D,
}

func on_button_pressed()->void:
	Wwise.post_event("snd_click", self)


func _enter_tree():
	## Registers the Wwise listener upon entering the tree.
	## Will persist throughout session to listen to all audio events.
	Wwise.register_listener(self)
	
	## Loads the soundbank "game" which contains all sfx and music as of 6/22
	Wwise.load_bank("game")

# Plays a sound. The AudioStreamPlayer node will be added to the `parent`
# specified as parameter.
func play(type: int, parent: Node, stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var audio_stream_player: Node
	match type:
		Type.NON_POSITIONAL:
			audio_stream_player = AudioStreamPlayer.new()
		Type.POSITIONAL_2D:
			audio_stream_player = AudioStreamPlayer2D.new()

	parent.add_child(audio_stream_player)
	audio_stream_player.bus = "SFX"
	audio_stream_player.stream = stream
	audio_stream_player.volume_db = volume_db
	audio_stream_player.pitch_scale = pitch_scale
	audio_stream_player.play()
	audio_stream_player.connect("finished", func(): audio_stream_player.queue_free())
