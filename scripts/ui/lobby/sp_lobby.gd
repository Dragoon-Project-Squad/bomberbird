extends Control

@onready var mode_select_screen: Control = $ModeSelect
@onready var save_select_screen: Control = $SaveMenu
@onready var character_select_screen: Control = $CharacterSelectScreen
@onready var pickup_shop_screen: Control = $PickupShop

## plays lobby music for the singleplayer lobby only.
@export var lobby_music: WwiseEvent

func _ready() -> void:
	gamestate.game_error.connect(_on_game_error)
	
	# activates the lobby music Wwise Event
	lobby_music.post(self)
	
	show_mode_select_screen()

func show_mode_select_screen() -> void:
	show()
	mode_select_screen.show()
	save_select_screen.hide()
	character_select_screen.hide()
	pickup_shop_screen.hide()

func show_save_menu_screen() -> void:
	show()
	mode_select_screen.hide()
	save_select_screen.show()
	character_select_screen.hide()
	pickup_shop_screen.hide()

func show_character_select_screen() -> void:
	assert(gamestate.current_save_file != "")
	assert(gamestate.current_save.has("character_paths"))
	assert(gamestate.current_save.has("player_name"))
	show()
	mode_select_screen.hide()
	character_select_screen.enter()
	save_select_screen.hide()
	pickup_shop_screen.hide()

	if globals.is_boss_rush_mode():
		character_select_screen.make_next_screen()
	elif globals.is_campaign_mode():
		character_select_screen.make_starting_screen()
	
func finished_character_select_screen() -> void:
	if globals.is_boss_rush_mode():
		show_pickup_shop_screen()
	elif globals.is_campaign_mode():
		_on_game_start()

func back_from_character_select_screen() -> void:
	if globals.is_boss_rush_mode():
		show_mode_select_screen()
	elif globals.is_campaign_mode():
		show_save_menu_screen()

func show_pickup_shop_screen():
	show()
	mode_select_screen.hide()
	save_select_screen.hide()
	character_select_screen.hide()
	pickup_shop_screen.enter()

func hide_all_lobby_screens() -> void:
	hide()
	mode_select_screen.hide()
	save_select_screen.hide()
	character_select_screen.hide()
	
func get_back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_game_error(errtxt):
	if is_inside_tree():
		$ErrorDialog.dialog_text = errtxt
		$ErrorDialog.popup_centered()
	
func _on_game_start() -> void:
	
	# stops all music so that the player knows the game is loading
	Wwise.post_event("stop_music", self)
	
	gamestate.begin_singleplayer_game()
	hide_all_lobby_screens()

func _on_error_dialog_confirmed() -> void:
	get_back_to_menu()
