class_name Config extends Node

var config = ConfigFile.new()

func _init() -> void:
	var err = self.load()
	if err == OK:
		#load_buttons()
		return
		
	defaults()
	save()

func defaults() -> void:
	config.set_value("Player", "player_name", "Dragoon")
	# TODO(Input)
	print(InputMap.action_get_events("move_down"))
	#config.set_value("Input", "player_name", "Steve")
	
func set_button(button, value) -> void:
	config.set_value("Buttons", button, value)

func load_button(action, event) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)

func save():
	config.save("user://config.cfg")

func load():
	return config.load("user://config.cfg")
	
func load_buttons():
	var actions = ["move_up", "move_down", "move_left", "move_right", "set_bomb"]
	for action in actions:
		load_button(action, config.get_value("Buttons", action))
		
func get_player_name():
	return config.get_value("Player", "player_name", "Dragoon")
	
func set_player_name(newplayername):
	config.set_value("Player", "player_name", newplayername)
	save()
	return 
