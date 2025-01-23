extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ButtonBox/SinglePlayer.grab_focus()

func _on_single_player_pressed() -> void:
	pass # Replace with function body.


func _on_multiplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_options_pressed() -> void:
	pass # Replace with function body.
