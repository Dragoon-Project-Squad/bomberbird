extends Control

@onready var css_audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var character_texture_paths: CharacterSelectDataResource = preload("res://resources/css/character_texture_paths_default.tres")
@onready var secret_1: TextureButton = $SkinBG/CharacterGrid/secret1
@onready var secret_2: TextureButton = $SkinBG/CharacterGrid/secret2
@onready var last_selected_panel: Panel = %CharacterGrid.get_node("eggoon/Panel")

@export var supersecretvisible := false

signal characters_confirmed
signal characters_back_pressed

var error_sound: AudioStreamWAV = load("res://sound/fx/error.wav")
var select_sound: AudioStreamWAV = load("res://sound/fx/click.wav")

func _ready() -> void:
	if supersecretvisible or globals.secrets_enabled:
		secret_1.show()
		secret_2.show()


func enter() -> void:
	show()

	# select the default
	show_selected_panel("eggoon")
	gamestate.current_save.character_paths = character_texture_paths.egggoon_paths
	gamestate.current_save.player_name = "Player1"
	%PlayerName.text = ""


func play_error_audio() -> void:
	css_audio.stream = error_sound
	css_audio.play()

@rpc("any_peer", "call_local")
func play_select_audio() -> void:
	css_audio.stream = select_sound
	css_audio.play()

func show_selected_panel(character: String):
	if last_selected_panel: last_selected_panel.hide()
	last_selected_panel = %CharacterGrid.get_node(character + "/Panel")
	last_selected_panel.show()

func _on_eggoon_pressed() -> void:
	show_selected_panel("eggoon")
	gamestate.current_save.character_paths = character_texture_paths.egggoon_paths
	play_select_audio.rpc()
	
func _on_dragoon_pressed() -> void:
	show_selected_panel("dragoon")
	gamestate.current_save.character_paths = character_texture_paths.normalgoon_paths
	play_select_audio.rpc()
	
func _on_chonkgoon_pressed() -> void:
	show_selected_panel("chonkgoon")
	gamestate.current_save.character_paths = character_texture_paths.chonkgoon_paths
	play_select_audio.rpc()
	
func _on_longoon_pressed() -> void:
	show_selected_panel("longoon")
	gamestate.current_save.character_paths = character_texture_paths.longgoon_paths
	play_select_audio.rpc()
	
func _on_dad_pressed() -> void:
	show_selected_panel("dad")
	gamestate.current_save.character_paths = character_texture_paths.dad_paths
	play_select_audio.rpc()

func _on_bhdoki_pressed() -> void:
	show_selected_panel("bhdoki")
	gamestate.current_save.character_paths = character_texture_paths.bhdoki_paths
	play_select_audio.rpc()

func _on_retrodoki_pressed() -> void:
	show_selected_panel("retrodoki")
	gamestate.current_save.character_paths = character_texture_paths.retrodoki_paths
	play_select_audio.rpc()

func _on_altdoki_pressed() -> void:
	show_selected_panel("altdoki")
	gamestate.current_save.character_paths = character_texture_paths.altgirldoki_paths
	play_select_audio.rpc()

func _on_crowki_pressed() -> void:
	show_selected_panel("crowki")
	gamestate.current_save.character_paths = character_texture_paths.crowki_paths
	play_select_audio.rpc()

func _on_tomato_pressed() -> void:
	show_selected_panel("tomato")
	gamestate.current_save.character_paths = character_texture_paths.tomatodoki_paths
	play_select_audio.rpc()

func _on_secret_1_pressed() -> void:
	if not supersecretvisible and not globals.secrets_enabled:
		play_error_audio() #Not yet available
	else:
		show_selected_panel("secret1")
		gamestate.current_save.character_paths = character_texture_paths.secretone_paths
		play_select_audio.rpc()

func _on_secret_2_pressed() -> void:
	if not supersecretvisible and not globals.secrets_enabled:
		play_error_audio()
	else:
		show_selected_panel("secret2")
		gamestate.current_save.character_paths = character_texture_paths.secrettwo_paths
		play_select_audio.rpc()

func _on_exit_pressed() -> void:
	characters_back_pressed.emit()

func _on_confirm_pressed() -> void:
	characters_confirmed.emit()

func _on_player_name_text_changed(new_text: String) -> void:
	if new_text == "": gamestate.current_save.player_name = "Player1"
	else: gamestate.current_save.player_name = new_text
