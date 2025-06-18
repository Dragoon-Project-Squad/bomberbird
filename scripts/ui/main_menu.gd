extends Control
@onready var title_sceen: Node2D = $TitleSceen
@onready var button_box: VBoxContainer = $ButtonBox
@onready var options_menu: Control = $OptionsMenu
@onready var graph_selection: Control = $DebugCampaignSelector
@onready var main_menu_music_player: AudioStreamPlayer = $AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu_music_player.play()
	main_menu_music_player.autoplay = true
	$ButtonBox/Singleplayer.grab_focus()
	check_secret()

func switch_to_options_menu() -> void:
	hide_main_menu()
	options_menu.visible = true
	options_menu.options_music_player.play()
	
func hide_main_menu() -> void:
	graph_selection.hide()
	title_sceen.hide()
	button_box.hide()
	$DokiSubscribeLink.hide()
	
func reveal_main_menu() -> void:
	graph_selection.show()
	title_sceen.visible = true
	button_box.visible = true
	$DokiSubscribeLink.show()

func pause_main_menu_music() -> void:
	main_menu_music_player.stream_paused = true
	
func unpause_main_menu_music() -> void:
	main_menu_music_player.stream_paused = false
	
func check_secret() -> void:
	if SettingsContainer.get_data_flag() == "boo":
		globals.secrets_enabled = true

func _on_single_player_pressed() -> void:
	gamestate.begin_singleplayer_game()
	hide();

func _on_multiplayer_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
	hide();

func _on_options_pressed() -> void:
	pause_main_menu_music()
	switch_to_options_menu()

func _on_options_menu_options_menu_exited() -> void:
	reveal_main_menu()
	unpause_main_menu_music()

func _on_exit_pressed() -> void:
	get_tree().quit() # Replace with function body.
