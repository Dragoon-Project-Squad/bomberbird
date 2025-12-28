extends CanvasLayer

@onready var options_menu: Control = %OptionsMenu
@onready var game: Game = get_parent()
@onready var pause_menu_ui: VBoxContainer = %PauseMenuUI

signal pause_menu_exited

func _on_continue_pressed() -> void:
	close()

func _on_settings_pressed() -> void:
	pause_menu_ui.hide()
	options_menu.show()
	options_menu.hide_sound_test()
	#options_menu.options_music.post(options_menu)

func _on_option_menu_exited() -> void:
	pause_menu_ui.show()
	options_menu.hide()
	options_menu.show_sound_test()

func _on_exit_pressed() -> void:
	get_tree().paused = false
	if globals.is_singleplayer():
		gamestate.end_sp_game()
	elif globals.is_multiplayer():
		gamestate.end_game()
	else:
		push_error("game could not end since the current_gamemode variable in global is corrupt")
		
func _input(event):
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			close.call_deferred() # this is queued to avoid the escape key retriggering the open call from game

func close() -> void:
	if options_menu.visible: return
	pause_menu_exited.emit()
	pause_menu_ui.show()
	hide()
	get_tree().paused = false

func open() -> void:
	pause_menu_ui.show()
	options_menu.hide()
	show()
	get_tree().paused = true
