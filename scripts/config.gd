class_name Config extends Node

var config = ConfigFile.new()

func _init() -> void:
	var err = self.load()
	if err == OK:
		return
		
	defaults()
	save()

func defaults() -> void:
	config.set_value("Player", "player_name", "Dragoon")
	# TODO(Input)
	#print(InputMap.action_get_events("move_down"))
	#config.set_value("Input", "player_name", "Steve")
	
func save():
	config.save("user://config.cfg")

func load():
	return config.load("user://config.cfg")
	
func get_player_name():
	return config.get_value("Player", "player_name", "Dragoon")
