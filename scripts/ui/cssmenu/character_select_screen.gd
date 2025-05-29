extends Control

@onready var css_audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var character_texture_paths: CharacterSelectDataResource = preload("res://resources/css/character_texture_paths_default.tres")
@onready var secret_1: TextureButton = $SkinBG/CharacterGrid/secret1
@onready var secret_2: TextureButton = $SkinBG/CharacterGrid/secret2

@export var supersecretvisible := false

var error_sound: AudioStreamWAV = load("res://sound/fx/error.wav")
var select_sound: AudioStreamWAV = load("res://sound/fx/click.wav")

func _ready() -> void:
	if supersecretvisible:
		secret_1.show()
		secret_2.show()
	setup_default_character_select_paths()

func setup_default_character_select_paths() -> void:
	$Players/Player2.set_texture(character_texture_paths.DEFAULT_PLAYER_2_SELECT)
	$Players/Player3.set_texture(character_texture_paths.DEFAULT_PLAYER_3_SELECT)
	$Players/Player4.set_texture(character_texture_paths.DEFAULT_PLAYER_4_SELECT)

func play_error_audio() -> void:
	css_audio.stream = error_sound
	css_audio.play()

@rpc("any_peer", "call_local")
func play_select_audio() -> void:
	css_audio.stream = select_sound
	css_audio.play()

@rpc("call_local")
func disable_unused_player_slots() -> void:
	var slots_to_disable = 4 - gamestate.total_player_count
	if slots_to_disable < 0:
		push_error("Somehow, over 4 players are registered. Aborting process.")
		return
	if slots_to_disable > 3:
		push_error("Somehow, no players are registered. Aborting process.")
		return
	while slots_to_disable > 0:
		match slots_to_disable:
			3:
				$Players/Player2.remove_as_participant()
				slots_to_disable -= 1
			2:
				$Players/Player3.remove_as_participant()
				slots_to_disable -= 1
			1:
				$Players/Player4.remove_as_participant()
				slots_to_disable -= 1
				
@rpc("any_peer", "call_local")
func change_slot_texture(texture_path: String):
	var id = multiplayer.get_remote_sender_id()
	if id == 1:
		$Players/Player1.set_texture.rpc(texture_path)
	elif id == gamestate.player_numbers.p2:
		print("Player 2 switched character!")
		$Players/Player2.set_texture.rpc(texture_path)
	elif id == gamestate.player_numbers.p3:
		$Players/Player3.set_texture.rpc(texture_path)
	elif id == gamestate.player_numbers.p4:
		$Players/Player4.set_texture.rpc(texture_path)
	else:
		print("Couldn't find a match.")
	
func _on_eggoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.EGGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.EGGOON_PLAYER_TEXTURE_PATH)
	play_select_audio.rpc()
	
func _on_dragoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.NORMALGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.NORMALGOON_PLAYER_TEXTURE_PATH)
	play_select_audio.rpc()
	
func _on_chonkgoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.CHONKGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.CHONKGOON_PLAYER_TEXTURE_PATH)
	play_select_audio.rpc()
	
func _on_longoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.LONGGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.LONGGOON_PLAYER_TEXTURE_PATH)
	play_select_audio.rpc()
	
func _on_dad_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.DAD_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.DAD_PLAYER_TEXTURE_PATH)
	play_select_audio.rpc()

func _on_bhdoki_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.BHDOKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.BHDOKI_PLAYER_TEXTURE_PATH)
	play_select_audio.rpc()

func _on_retrodoki_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.RETRODOKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.RETRODOKI_PLAYER_TEXTURE_PATH)
	play_select_audio.rpc()

func _on_altdoki_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.ALTGIRLDOKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.ALTGIRLDOKI_PLAYER_TEXTURE_PATH)
	play_select_audio.rpc()

func _on_crowki_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.CROWKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.CROWKI_PLAYER_TEXTURE_PATH)
	play_select_audio.rpc()

func _on_tomato_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.TOMATODOKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.TOMATODOKI_PLAYER_TEXTURE_PATH)
	play_select_audio.rpc()

func _on_secret_1_pressed() -> void:
	if not supersecretvisible:
		play_error_audio() #Not yet available
	else:
		change_slot_texture.rpc_id(1, character_texture_paths.SECRET1_SELECT_TEXTURE_PATH)
		gamestate.change_character_player.rpc_id(1, character_texture_paths.SECRET1_PLAYER_TEXTURE_PATH)
		play_select_audio.rpc()
func _on_secret_2_pressed() -> void:
	if not supersecretvisible:
		play_error_audio() #Not yet available
	else:
		change_slot_texture.rpc_id(1, character_texture_paths.SECRET2_SELECT_TEXTURE_PATH)
		gamestate.change_character_player.rpc_id(1, character_texture_paths.SECRET2_PLAYER_TEXTURE_PATH)
		play_select_audio.rpc()
