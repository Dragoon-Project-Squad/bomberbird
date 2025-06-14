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
	options_menu.options_music_player.play()

func _on_option_menu_exited() -> void:
	pause_menu_ui.show()
	options_menu.hide()

func _on_exit_pressed() -> void:
	get_tree().paused = false
	if globals.current_gamemode == globals.gamemode.CAMPAIGN:
		gamestate.end_sp_game()
	elif globals.current_gamemode == globals.gamemode.BATTLEMODE:
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
