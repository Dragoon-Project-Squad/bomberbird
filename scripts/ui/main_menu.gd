extends Control
@onready var title_sceen: Node2D = $TitleSceen
@onready var button_box: VBoxContainer = $ButtonBox
@onready var options_menu: Control = $OptionsMenu
@onready var main_menu_music_player: AudioStreamPlayer = $AudioStreamPlayer
signal options_menu_entered

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ButtonBox/Singleplayer.grab_focus()
	
func switch_to_options_menu() -> void:
	hide_main_menu()
	options_menu.visible = true
	options_menu.options_music_player.play()
	
func hide_main_menu() -> void:
	title_sceen.visible = false
	button_box.visible = false

func reveal_main_menu() -> void:
	title_sceen.visible = true
	button_box.visible = true

func pause_main_menu_music() -> void:
	main_menu_music_player.stream_paused = true
	
func unpause_main_menu_music() -> void:
	main_menu_music_player.stream_paused = false
	
func _on_single_player_pressed() -> void:
	#if a game is already running do not allow a new game to start
	if globals.current_world == null:
		gamestate.begin_singleplayer_game()
	# get_tree().change_scene_to_file("res://scenes/battlegrounds.tscn")


func _on_multiplayer_pressed() -> void:
	#if a game is already running do not allow to open lobby
	if globals.current_world == null:
		get_tree().change_scene_to_file("res://scenes/lobby/battle_settings.tscn")

func _on_options_pressed() -> void:
	#if a game is already running do not allow to open menu
	if globals.current_world == null:
		pause_main_menu_music()
		switch_to_options_menu()

func _on_options_menu_options_menu_exited() -> void:
	reveal_main_menu()
	unpause_main_menu_music()
