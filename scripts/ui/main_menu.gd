extends Control

@onready var title_screen: Control = $TitleScreen
@onready var button_box: VBoxContainer = $ButtonBox
@onready var options_menu: Control = $OptionsMenu
@onready var credits_screen: Control = $Credits
@onready var version_number_text: Label = $VersionNumberPanel/VersionNumRichText
@onready var menu_music = %MenuMusic

signal options_menu_entered

var preload_credits_scene = preload("res://scenes/credits/credits_screen.tscn")



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# stops all music to be safe
	Wwise.post_event("stop_music", self)
	# plays the main menu music
	menu_music.post_event()
	version_number_text.set_text("v" + ProjectSettings.get_setting("application/config/version"))
	$ButtonBox/Singleplayer.grab_focus()
	check_secret()	
	
	#splash screen
	var splash_screen = get_node("/root/Splash")
	if splash_screen != null:
		splash_screen.start_splash()
	
func switch_to_options_menu() -> void:
	hide_main_menu()
	options_menu.visible = true
	options_menu_entered.emit()
	# plays the options music resource in the OptionsMenu node
	options_menu.options_music.post(options_menu)
	
func switch_to_credits_menu() -> void:
	hide_main_menu()
	credits_screen.visible = true
	
func hide_main_menu() -> void:
	title_screen.hide()
	button_box.hide()
	$DokiSubscribeLink.hide()
	
func reveal_main_menu() -> void:
	title_screen.visible = true
	button_box.visible = true
	$DokiSubscribeLink.show()

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
	hide();

func _on_multiplayer_pressed() -> void:
	# stops ALL music
	Wwise.post_event("stop_music", self)
	get_tree().change_scene_to_file("res://scenes/lobby/lobby.tscn")
	hide();

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

#unveil splash when beat drops
func _on_menu_music_music_sync_user_cue(_data: Dictionary) -> void:
	var splash_screen = get_node("/root/Splash")
	if splash_screen != null:
		splash_screen.end_splash()

#have the splash do cool text things
func _on_menu_music_music_sync_entry(_data: Dictionary) -> void:
	var splash_screen = get_node("/root/Splash")
	if splash_screen != null:
		splash_screen.anim_splash()
