class_name HotkeyRebindButton
extends Control

@onready var label: Label = $HBoxContainer/Label as Label
@onready var button: Button = $HBoxContainer/Button as Button
@export var action_name := "move_up"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_unhandled_key_input(false) #DO NOT just take random keyboard inputs.
	set_action_name()
	set_text_for_key()
	
func set_action_name() -> void:
	label.text = "Unassigned"
	
	match action_name:
		"move_up":
			label.text = "Up"
		"move_left":
			label.text = "Left"
		"move_right":
			label.text = "Right"
		"move_down":
			label.text = "Down"
		"set_bomb":
			label.text = "Bomb/Glove"
		"detonate_rc":
			label.text = "Remote Detonate"
		"punch_action":
			label.text = "Punch/Ride Ability"
		"secondary_action":
			label.text = "Kick Stop"
		"pause":
			label.text = "Pause"

func set_text_for_key() -> void:
	var action_events = InputMap.action_get_events(action_name)
	print(action_events)
