extends Control

@onready var save_select_screen: Control = $SaveMenu
@onready var character_select_screen: Control = $CharacterSelectScreen
@onready var lobby_music_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	gamestate.game_ended.connect(_on_game_ended)
	gamestate.game_error.connect(_on_game_error)
	show_save_menu_screen()
	
func show_save_menu_screen() -> void:
	save_select_screen.show()
	character_select_screen.hide()

func show_character_select_screen() -> void:
	assert(gamestate.current_save_file != "")
	assert(gamestate.current_save.has("character_paths"))
	assert(gamestate.current_save.has("player_name"))
	character_select_screen.enter()
	save_select_screen.hide()
	
func hide_all_lobby_screens() -> void:
	hide()
	character_select_screen.hide()

func pause_sp_lobby_music() -> void:
	lobby_music_player.stream_paused = true
	
func unpause_sp_lobby__music() -> void:
	lobby_music_player.stream_paused = false
	
func get_back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_game_error(errtxt):
	if is_inside_tree():
		$ErrorDialog.dialog_text = errtxt
		$ErrorDialog.popup_centered()
	
func _on_game_start() -> void:
	gamestate.begin_singleplayer_game()
	hide_all_lobby_screens()
	pause_sp_lobby_music()

func _on_error_dialog_confirmed() -> void:
	get_back_to_menu()

func _on_game_ended():
	get_back_to_menu()
