extends Node

func play() -> void:
	# stops any currently playing music to be safe, then plays battle music
	Wwise.post_event("stop_music", self)
	$AkState.set_value()
	Wwise.post_event("play_music_battle", self)

func stop() -> void:
	# stops all currently playing music
	Wwise.post_event("stop_music", self)
