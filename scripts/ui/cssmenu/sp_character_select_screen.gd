extends Control

@onready var character_texture_paths: CharacterSelectDataResource = preload("res://resources/css/character_texture_paths_default.tres")
@onready var secret_1: TextureButton = $SkinBG/CharacterGrid/secret1
@onready var secret_2: TextureButton = $SkinBG/CharacterGrid/secret2
@onready var last_selected_panel: Panel = %CharacterGrid.get_node("eggoon/Panel")
@onready var campaign_selector: Control = %CampaignSelector
@onready var start_button: SeButton = %Start

@export var mint_visible := false

signal characters_confirmed
signal characters_back_pressed

## Wwise event that plays an error sound when .post() is called.
@export var error_sound: WwiseEvent

## Wwise event that plays a click sound when .post() is called.
@export var select_sound: WwiseEvent

func _ready() -> void:
	if mint_visible or globals.secrets.mint:
		secret_1.show()
		secret_2.show()


func enter() -> void:
	show()
	campaign_selector.enter()

	# select the default
	show_selected_panel("eggoon")
	gamestate.current_save.character_paths = "egggoon"
	gamestate.current_save.player_name = "Player1"
	%PlayerName.text = ""

func make_starting_screen():
	start_button.text = "Start"

func make_next_screen():
	start_button.text = "Next"



func play_error_audio() -> void:
	error_sound.post(self)

@rpc("any_peer", "call_local")
func play_select_audio() -> void:
	select_sound.post(self)

func show_selected_panel(character: String):
	if last_selected_panel: last_selected_panel.hide()
	last_selected_panel = %CharacterGrid.get_node(character + "/Panel")
	last_selected_panel.show()

func _on_eggoon_pressed() -> void:
	show_selected_panel("eggoon")
	gamestate.current_save.character_paths = "egggoon"
	play_select_audio.rpc()
	
func _on_dragoon_pressed() -> void:
	show_selected_panel("dragoon")
	gamestate.current_save.character_paths = "normalgoon"
	play_select_audio.rpc()
	
func _on_chonkgoon_pressed() -> void:
	show_selected_panel("chonkgoon")
	gamestate.current_save.character_paths = "chonkgoon"
	play_select_audio.rpc()
	
func _on_longoon_pressed() -> void:
	show_selected_panel("longoon")
	gamestate.current_save.character_paths = "longgoon"
	play_select_audio.rpc()
	
func _on_dad_pressed() -> void:
	show_selected_panel("dad")
	gamestate.current_save.character_paths = "dad"
	play_select_audio.rpc()

func _on_bhdoki_pressed() -> void:
	show_selected_panel("bhdoki")
	gamestate.current_save.character_paths = "bhdoki"
	play_select_audio.rpc()

func _on_summerdoki_pressed() -> void:
	show_selected_panel("summerdoki")
	gamestate.current_save.character_paths = "summerdoki"
	play_select_audio.rpc()
	
func _on_schooldoki_pressed() -> void:
	show_selected_panel("schooldoki")
	gamestate.current_save.character_paths = "schooldoki"
	play_select_audio.rpc()

func _on_retrodoki_pressed() -> void:
	show_selected_panel("retrodoki")
	gamestate.current_save.character_paths = "retrodoki"
	play_select_audio.rpc()

func _on_altdoki_pressed() -> void:
	show_selected_panel("altdoki")
	gamestate.current_save.character_paths = "altgirldoki"
	play_select_audio.rpc()

func _on_crowki_pressed() -> void:
	show_selected_panel("crowki")
	gamestate.current_save.character_paths = "crowki"
	play_select_audio.rpc()

func _on_tomato_pressed() -> void:
	show_selected_panel("tomato")
	gamestate.current_save.character_paths = "tomatodoki"
	play_select_audio.rpc()

func _on_secret_1_pressed() -> void:
	if not mint_visible and not globals.secrets.mint:
		play_error_audio() #Not yet available
	else:
		show_selected_panel("wisp")
		gamestate.current_save.character_paths = "wisp"
		play_select_audio.rpc()

func _on_secret_2_pressed() -> void:
	if not mint_visible and not globals.secrets.mint:
		play_error_audio()
	else:
		show_selected_panel("mint")
		gamestate.current_save.character_paths = "mint"
		play_select_audio.rpc()

func _on_exit_pressed() -> void:
	characters_back_pressed.emit()

func _on_confirm_pressed() -> void:
	characters_confirmed.emit()

func _on_player_name_text_changed(new_text: String) -> void:
	if new_text == "": gamestate.current_save.player_name = "Player1"
	else: gamestate.current_save.player_name = new_text
