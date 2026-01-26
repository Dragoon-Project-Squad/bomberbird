extends Control

func _ready() -> void:
	await get_tree().process_frame
	check_steam_powered_on_launch()
	await get_tree().process_frame
	if save_data_loaded_successfully():
		enter_game()
	else:
		$SaveDataWarning.show()
		
func enter_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func save_data_loaded_successfully() -> bool:
	if SaveManager.is_save_data_available():
		return true
	else:
		return false
		
func check_steam_powered_on_launch():
	if SteamManager.steam_checked_on_boot == true: #If Steam initialization was already attmepted, do nothing.
		return
	SteamManager.determine_platform()
	if SteamManager.this_platform == "steam":
		gamestate.execute_post_boot_steam_framework_methods()
	SteamManager.steam_checked_on_boot = true
	
func _on_save_data_warning_confirmed() -> void:
	SaveManager.initialize_default_save_data()
	SaveManager.load_settings_data()
	if !SaveManager.save_data_loaded:
		$CloseGame.show()
	else:
		enter_game()
		
func _on_save_data_warning_canceled() -> void:
	$CloseGame.show()
	

func _on_close_game_confirmed() -> void:
	get_tree().quit(1)
