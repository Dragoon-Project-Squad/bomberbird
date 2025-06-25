extends Control

@onready var connect_screen: PanelContainer = $Connect
@onready var character_select_screen: Control = $CharacterSelect
@onready var battle_settings_screen: Control = $BattleSettings
@onready var stage_select_screen: Control = $StageSelect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	gamestate.game_ended.connect(_on_game_ended)
	gamestate.game_error.connect(_on_game_error)
	gamestate.secret_status_sent.connect(_on_secret_status_sent)
	if not multiplayer.get_peers().is_empty():
		print("I AM ONLINE")
		show_character_select_screen()

func start_the_battle() -> void:
	animation_player.play("begin_the_game")
	await animation_player.animation_finished
	if is_multiplayer_authority():
		gamestate.begin_game()

func show_connect_screen() -> void:
	connect_screen.show()
	character_select_screen.hide()
	battle_settings_screen.hide()
	stage_select_screen.hide()

func show_character_select_screen() -> void:
	connect_screen.hide()
	if is_multiplayer_authority():
		character_select_screen.setup_for_host()
		character_select_screen.setup_for_peers.rpc()
	character_select_screen.show()
	battle_settings_screen.hide()
	stage_select_screen.hide()
	
func show_battle_settings_screen() -> void:
	connect_screen.hide()
	character_select_screen.hide()
	if is_multiplayer_authority():
		battle_settings_screen.setup_for_host()
		battle_settings_screen.setup_for_peers.rpc()
	battle_settings_screen.show()
	stage_select_screen.hide()
	
func show_stage_select_screen() -> void:
	connect_screen.hide()
	character_select_screen.hide()
	battle_settings_screen.hide()
	if is_multiplayer_authority():
		stage_select_screen.setup_for_peers.rpc()
	stage_select_screen.show()

@rpc("call_local")
func hide_all_lobby_screens() -> void:
	#Called via AnimationPlayer("begin_the_game")
	connect_screen.hide()
	character_select_screen.hide()
	battle_settings_screen.hide()
	stage_select_screen.hide()

func _on_game_error(errtxt):
	if is_inside_tree():
		$ErrorDialog.dialog_text = errtxt
		$ErrorDialog.popup_centered()
	
func _on_connect_multiplayer_game_hosted() -> void:
	#HOST
	print("Hosted a game!")
	show_character_select_screen()

func _on_connect_multiplayer_game_joined() -> void:
	#CLIENT
	print("Joined a game!")
	show_character_select_screen()

func _on_character_select_characters_confirmed() -> void:
	show_battle_settings_screen()

func _on_battle_settings_battle_settings_aborted() -> void:
	show_character_select_screen()

func _on_battle_settings_battle_settings_confirmed() -> void:
	show_stage_select_screen()

func _on_stage_select_stage_select_aborted() -> void:
	show_battle_settings_screen()

func _on_stage_select_stage_selected() -> void:
	start_the_battle()

func _on_secret_status_sent() -> void:
	if globals.secrets_enabled:
		character_select_screen.reveal_secrets()
		stage_select_screen.switch_to_secret_stages()
func _on_error_dialog_confirmed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_game_ended():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
