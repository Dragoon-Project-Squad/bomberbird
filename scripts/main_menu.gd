extends Control
@onready var title_sceen: Node2D = $TitleSceen
@onready var button_box: VBoxContainer = $ButtonBox
@onready var options_menu: Control = $OptionsMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ButtonBox/Singleplayer.grab_focus()

func switch_to_options_menu() -> void:
	options_menu.visible = true
	title_sceen.visible = false
	button_box.visible = false

func _on_single_player_pressed() -> void:
	#if a game is already running do not allow a new game to start
	if not has_node("/root/World"):
		gamestate.begin_singleplayer_game()
	# get_tree().change_scene_to_file("res://scenes/battlegrounds.tscn")


func _on_multiplayer_pressed() -> void:
	#if a game is already running do not allow to open lobby
	if not has_node("/root/World"):
		get_tree().change_scene_to_file("res://scenes/lobby.tscn")


func _on_options_pressed() -> void:
	#if a game is already running do not allow to open menu
	if has_node("/root/World"):
		pass
	#get_tree().change_scene_to_file("res://scenes/options_menu/options_menu.tscn")
	switch_to_options_menu()
