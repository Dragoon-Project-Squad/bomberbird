extends Control

func _ready() -> void:
	await get_tree().process_frame
	steam_powered_launch_checks()
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func steam_powered_launch_checks():
	if SteamManager.steam_checked_on_boot == true: #If Steam initialization was already attmepted, do nothing.
		return
	SteamManager.determine_platform()
	if SteamManager.this_platform == "steam":
		gamestate.execute_post_boot_steam_framework_methods()
	SteamManager.steam_checked_on_boot = true
