extends Control
@onready var css_audio: AudioStreamPlayer = $AudioStreamPlayer
var error_sound: AudioStreamWAV = load("res://sound/fx/error.wav")
var select_sound: AudioStreamWAV = load("res://sound/fx/click.wav")
@onready var character_texture_paths: CharacterSelectDataResource = preload("res://resources/css/character_texture_paths_default.tres")

func play_error_audio() -> void:
	css_audio.stream = error_sound
	css_audio.play()
	
func play_select_audio() -> void:
	css_audio.stream = select_sound
	css_audio.play()
	
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
		print("Match 2!")
		$Players/Player2.set_texture.rpc(texture_path)
	elif id == gamestate.player_numbers.p3:
		$Players/Player3.set_texture.rpc(texture_path)
	elif id == gamestate.player_numbers.p4:
		$Players/Player4.set_texture.rpc(texture_path)
	else:
		print("Couldn't find a match.")
	
func _on_dragoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.NORMALGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.NORMALGOON_PLAYER_TEXTURE_PATH)
	play_select_audio()
	
func _on_chonkgoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.CHONKGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.CHONKGOON_PLAYER_TEXTURE_PATH)
	play_select_audio()
	
func _on_longoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.LONGGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.LONGGOON_PLAYER_TEXTURE_PATH)
	play_select_audio()
	
func _on_eggoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.EGGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.EGGOON_PLAYER_TEXTURE_PATH)
	play_select_audio()
	
func _on_tomato_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.TOMATODOKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.TOMATODOKI_PLAYER_TEXTURE_PATH)
	play_select_audio()

func _on_bhdoki_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.BHDOKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.BHDOKI_PLAYER_TEXTURE_PATH)
	play_select_audio()
	
func _on_secret_1_pressed() -> void:
	play_error_audio() #Not yet available

func _on_secret_2_pressed() -> void:
	play_error_audio() #Not yet available

func _on_secret_3_pressed() -> void:
	play_error_audio() #Not yet available

func _on_secret_4_pressed() -> void:
	play_error_audio() #Not yet available
