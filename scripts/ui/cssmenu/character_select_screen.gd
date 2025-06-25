extends Control

@onready var css_audio: AudioStreamPlayer = $AudioStreamPlayer
@onready var character_texture_paths: CharacterSelectDataResource = preload("res://resources/css/character_texture_paths_default.tres")
@onready var secret_1: TextureButton = $SkinBG/CharacterGrid/secret1
@onready var secret_2: TextureButton = $SkinBG/CharacterGrid/secret2

@export var supersecretvisible := globals.secrets_enabled

signal characters_confirmed

var error_sound: AudioStreamWAV = load("res://sound/fx/error.wav")
var select_sound: AudioStreamWAV = load("res://sound/fx/click.wav")

func _ready() -> void:
	if supersecretvisible:
		secret_1.show()
		secret_2.show()
	setup_default_character_select_paths()
	gamestate.player_list_changed.connect(refresh_lobby_panel)
	refresh_lobby_panel()

func setup_default_character_select_paths() -> void:
	$Players/Player2.set_texture(character_texture_paths.DEFAULT_PLAYER_2_SELECT)
	$Players/Player3.set_texture(character_texture_paths.DEFAULT_PLAYER_3_SELECT)
	$Players/Player4.set_texture(character_texture_paths.DEFAULT_PLAYER_4_SELECT)

func setup_for_host() -> void:
	refresh_lobby_panel()

@rpc("call_remote")
func setup_for_peers() -> void:
	$Start.disabled = true
	
@rpc("call_remote")
func reveal_secrets() -> void:
	print("Can you see them?")
	secret_1.show()
	secret_2.show()

@rpc("call_local")
func update_char_screen(total_player_count: int) -> void:
	gamestate.total_player_count = total_player_count
	update_player_slots()

func play_error_audio() -> void:
	css_audio.stream = error_sound
	css_audio.play()

@rpc("any_peer", "call_local")
func play_select_audio() -> void:
	css_audio.stream = select_sound
	css_audio.play()

func refresh_lobby_panel():
	var players = gamestate.get_player_name_list()
	#player list is exactly as on host, so it contains client name but not server name
	print("Players ", players)
	$PlayerList/List.clear()
	
	for p in players:
		#FIXME: We should separate players, self and bots and this is not the way
		if players[p].contains("Bot"):
			continue
		if p == multiplayer.get_unique_id():
			$PlayerList/List.add_item(players[p] + " (You)")
		else:
			$PlayerList/List.add_item(players[p])
	if is_multiplayer_authority():
		update_char_screen.rpc(players.size())
	
func _on_ready_pressed() -> void:
	print("Not yet implemented")

func update_player_slots() -> void:
	var player_control_number = 0
	var playernamelist = gamestate.get_player_name_list().values()
	for player in $Players.get_children():
		if player is PlayerControl:
			player.set_is_participating(player_control_number < gamestate.total_player_count)
			player.is_cpu = player_control_number >= gamestate.human_player_count && player_control_number < gamestate.total_player_count
			if (player_control_number == 0):
				player.set_player_name_label_text(playernamelist[player_control_number])
			elif (player_control_number < gamestate.player_data_master_dict.size()):
				player.set_player_name_label_text(playernamelist[player_control_number])
			player_control_number += 1

@rpc("any_peer", "call_local")
func change_slot_texture(texture_path: String):
	var playerslotidmatchdict = gamestate.get_player_slot_list()
	var id = multiplayer.get_remote_sender_id()
	if id == playerslotidmatchdict[1]:
		$Players/Player1.set_texture.rpc(texture_path)
	elif id == playerslotidmatchdict[2]:
		print("Player 2 switched character!")
		$Players/Player2.set_texture.rpc(texture_path)
	elif id == playerslotidmatchdict[3]:
		$Players/Player3.set_texture.rpc(texture_path)
	elif id == playerslotidmatchdict[4]:
		$Players/Player4.set_texture.rpc(texture_path)
	else:
		print("Couldn't find a match. id=", id)
	
func _on_eggoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.EGGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.egggoon_paths)
	play_select_audio.rpc()
	
func _on_dragoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.NORMALGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.normalgoon_paths)
	play_select_audio.rpc()
	
func _on_chonkgoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.CHONKGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.chonkgoon_paths)
	play_select_audio.rpc()
	
func _on_longoon_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.LONGGOON_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.longgoon_paths)
	play_select_audio.rpc()
	
func _on_dad_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.DAD_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.dad_paths)
	play_select_audio.rpc()

func _on_bhdoki_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.BHDOKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.bhdoki_paths)
	play_select_audio.rpc()

func _on_retrodoki_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.RETRODOKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.retrodoki_paths)
	play_select_audio.rpc()

func _on_altdoki_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.ALTGIRLDOKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.altgirldoki_paths)
	play_select_audio.rpc()

func _on_crowki_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.CROWKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.crowki_paths)
	play_select_audio.rpc()

func _on_tomato_pressed() -> void:
	change_slot_texture.rpc_id(1, character_texture_paths.TOMATODOKI_SELECT_TEXTURE_PATH)
	gamestate.change_character_player.rpc_id(1, character_texture_paths.tomatodoki_paths)
	play_select_audio.rpc()

func _on_secret_1_pressed() -> void:
	if not supersecretvisible:
		play_error_audio() #Not yet available
	else:
		change_slot_texture.rpc_id(1, character_texture_paths.SECRET1_SELECT_TEXTURE_PATH)
		gamestate.change_character_player.rpc_id(1, character_texture_paths.secretone_paths)
		play_select_audio.rpc()
func _on_secret_2_pressed() -> void:
	if not supersecretvisible:
		play_error_audio() #Not yet available
	else:
		change_slot_texture.rpc_id(1, character_texture_paths.SECRET2_SELECT_TEXTURE_PATH)
		gamestate.change_character_player.rpc_id(1, character_texture_paths.secrettwo_paths)
		play_select_audio.rpc()

func _on_exit_pressed() -> void:
	gamestate.end_game()
	if gamestate.peer:
		gamestate.peer.close()

func _on_confirm_pressed() -> void:
	if gamestate.total_player_count < 2:
		push_warning("Less than two players!")
	elif gamestate.total_player_count > 4:
		push_error("More than four players!")
	if is_multiplayer_authority():
		proceed_to_next_screen.rpc()
	
@rpc("call_local")
func proceed_to_next_screen():
	characters_confirmed.emit()

func _on_find_public_ip_pressed():
	Steam.activateGameOverlay("Friends")
