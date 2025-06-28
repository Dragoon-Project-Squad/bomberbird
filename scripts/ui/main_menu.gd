extends Control
@onready var title_sceen: Node2D = $TitleSceen
@onready var button_box: VBoxContainer = $ButtonBox
@onready var options_menu: Control = $OptionsMenu
@onready var GodotCredits: Control = $Credits
signal options_menu_entered

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# stops all music to be safe
	Wwise.post_event("stop_music", self)
	# plays the main menu music
	Wwise.post_event("play_music_main_menu", self)

	$ButtonBox/Singleplayer.grab_focus()
	check_secret()

func switch_to_options_menu() -> void:
	hide_main_menu()
	options_menu.visible = true
	
	# plays the options music resource in the OptionsMenu node
	options_menu.options_music.post(options_menu)
	
func switch_to_credits_menu() -> void:
	hide_main_menu()
	GodotCredits.visible = true
	
func hide_main_menu() -> void:
	title_sceen.hide()
	button_box.hide()
	$DokiSubscribeLink.hide()
	
func reveal_main_menu() -> void:
	title_sceen.visible = true
	button_box.visible = true
	$DokiSubscribeLink.show()

func pause_main_menu_music() -> void:
	# pauses the main menu music if playing in wwise
	Wwise.post_event("pause_music_main_menu", self)
	
func unpause_main_menu_music() -> void:
	# resumes the main menu music if playing in wwise
	Wwise.post_event("unpause_music_main_menu", self)
	
func check_secret() -> void:
	if SettingsContainer.get_data_flag() == "boo":
		globals.secrets_enabled = true
		print("You found a secret!!!")
	#Do NOT set it to false if the data isn't there.

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
