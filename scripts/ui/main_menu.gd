extends Control

@onready var title_screen: Control = $TitleScreen
@onready var button_box: VBoxContainer = $ButtonBox
@onready var options_menu: Control = $OptionsMenu
@onready var credits_screen: Control = $Credits
@onready var version_number_text: Label = $VersionNumberPanel/VersionNumRichText
@onready var menu_music = %MenuMusic
@onready var intro_screen: Control = $Intro
@onready var title := %Title
@onready var foreground := %Foreground

var beat_drop := false

signal options_menu_entered


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# stops all music to be safe
	Wwise.post_event("stop_music", self)
	# Ensure nothing is visible during setup.
	hide_main_menu()
	version_number_text.set_text("v" + ProjectSettings.get_setting("application/config/version"))
	$ButtonBox/Singleplayer.grab_focus()
	check_secret()
	
	# plays the main menu music
	menu_music.post_event()
	if !gamestate.intro_screen_shown:
		show_intro_screen_on_launch()
	else:
		reveal_main_menu()

func show_intro_screen_on_launch():
	if !gamestate.intro_screen_shown:
		show_intro_screen()
		
func show_intro_screen():
	if intro_screen != null:
		intro_screen.show()
		#Playing the animation is handled by the Wwise signal.
	# The Intro Screen reveals the main menu when it's done.

func switch_to_options_menu() -> void:
	hide_main_menu()
	options_menu.show()
	options_menu_entered.emit()
	# plays the options music resource in the OptionsMenu node
	options_menu.options_music.post(options_menu)
	
func switch_to_credits_menu() -> void:
	hide_main_menu()
	credits_screen.show()
	
func hide_main_menu() -> void:
	title_screen.hide()
	button_box.hide()
	$VersionNumberPanel.hide()
	$DokiSubscribeLink.hide()
	
func reveal_main_menu() -> void:
	title_screen.show()
	button_box.show()
	$VersionNumberPanel.show()
	$DokiSubscribeLink.show()
	credits_screen.hide()
	if has_node("intro_screen"):
		intro_screen.hide()

func pause_main_menu_music() -> void:
	# pauses the main menu music if playing in wwise
	Wwise.post_event("pause_music_main_menu", menu_music)
	
func unpause_main_menu_music() -> void:
	# resumes the main menu music if playing in wwise
	Wwise.post_event("unpause_music_main_menu", menu_music)
	
func check_secret() -> void:
	#Do NOT set it to false if the data isn't there.
	if SettingsContainer.get_mint_flag() == "boo":
		globals.secrets.mint = true
		#print_debug("Mint Secret TRUE")
	if SettingsContainer.get_snuffy_flag() == "shiny":
		globals.secrets.snuffy = true
		#print_debug("Snuffy Secret TRUE")
	if SettingsContainer.get_laimu_flag() == "ferret":
		globals.secrets.laimu = true
		#print_debug("Laimu Secret TRUE")
	if SettingsContainer.get_dooby_flag() == "doobinit":
		globals.secrets.dooby = true
		#print_debug("Dooby Secret TRUE")
	if SettingsContainer.get_nimi_flag() == "konbakuwa":
		globals.secrets.nimi = true
		#print_debug("Nimi Secret TRUE")

func _on_single_player_pressed() -> void:
	# stops ALL music
	Wwise.post_event("stop_music", self)
	get_tree().change_scene_to_file("res://scenes/lobby/sp_lobby.tscn")
	hide()

func _on_multiplayer_pressed() -> void:
	# stops ALL music
	Wwise.post_event("stop_music", self)
	get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
	hide()

func _on_options_pressed() -> void:
	pause_main_menu_music()
	switch_to_options_menu()
	
func _on_credits_pressed() -> void:
	switch_to_credits_menu()

func _on_options_menu_options_menu_exited() -> void:
	reveal_main_menu()
	unpause_main_menu_music()

func _on_exit_pressed() -> void:
	get_tree().quit() # Replace with function body.

func _on_credits_credits_ended() -> void:
	reveal_main_menu()

#unveil main menu when beat drops
func _on_menu_music_music_sync_user_cue(_data: Dictionary) -> void:
	beat_drop = true
	if gamestate.intro_screen_shown == true:
		return
	else:
		intro_screen.end_intro()

#have the intro do cool text things
func _on_menu_music_music_sync_entry(_data: Dictionary) -> void:
	if gamestate.intro_screen_shown == true:
		return
	else:
		intro_screen.anim_intro()

func _on_intro_intro_screen_shown(input_cancelled: Variant) -> void:
	gamestate.intro_screen_shown = true
	if(input_cancelled):
		Wwise.post_event("snd_click", get_parent())
		pass

func _on_menu_music_music_sync_beat(_data: Dictionary) -> void:
	var tween := create_tween()
	if tween.is_valid():
		if beat_drop:
			tween.tween_property(title, "scale", Vector2(1.960, 2.14), 0.06).set_trans(Tween.TRANS_CUBIC)
			tween.parallel().tween_property(foreground, "scale:y", 0.98, 0.06).set_trans(Tween.TRANS_CIRC)
			tween.parallel().tween_property(foreground, "position:y", 114.422, 0.06).set_trans(Tween.TRANS_CIRC)
			tween.tween_property(title, "scale", Vector2(1.832, 2.0), 0.06).set_trans(Tween.TRANS_CUBIC)
			tween.parallel().tween_property(foreground, "scale:y", 1.0, 0.06).set_trans(Tween.TRANS_CIRC)
			tween.parallel().tween_property(foreground, "position:y", 112.5, 0.06).set_trans(Tween.TRANS_CIRC)
		else:
			tween.tween_property(title, "scale", Vector2(1.960, 2.14), 0.06).set_trans(Tween.TRANS_CUBIC)
			tween.tween_property(title, "scale", Vector2(1.832, 2.0), 0.06).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	tween.stop()
