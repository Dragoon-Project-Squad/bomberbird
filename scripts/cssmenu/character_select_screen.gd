extends Control
@onready var css_audio: AudioStreamPlayer = $AudioStreamPlayer
var error_sound: AudioStreamWAV = load("res://sound/fx/error.wav")
var select_sound: AudioStreamWAV = load("res://sound/fx/click.wav")

func play_error_audio() -> void:
	css_audio.stream = error_sound
	css_audio.play()
	
func play_select_audio() -> void:
	css_audio.stream = select_sound
	css_audio.play()
	
func _on_dokibird_pressed(id) -> void:
	print("Received ID as ", id)
	$Players/Player1.set_texture($SkinBG/CharacterGrid/dokibird.get_texture_normal())
	gamestate.change_character_player(load("res://assets/css/dokibh.png"))
	play_select_audio()
	
func _on_dragoon_pressed() -> void:
	$Players/Player1.set_texture = load("res://assets/css/normalgoon.png")
	gamestate.change_character_player(load("res://assets/player/dragoon_walk.png"))
	play_select_audio()
	
func _on_chonkgoon_pressed() -> void:
	$CSSPlayers/P1/Image.texture = load("res://assets/css/chonkgoon.png")
	gamestate.change_character_player(load("res://assets/player/chonkgoon_walk.png"))
	play_select_audio()
	
func _on_longoon_pressed() -> void:
	$CSSPlayers/P1/Image.texture = load("res://assets/css/longgoon.png")
	gamestate.change_character_player(load("res://assets/css/longgoon.png"))
	play_select_audio()
	
func _on_eggoon_pressed() -> void:
	$CSSPlayers/P1/Image.texture = load("res://assets/css/eggoon.png")
	gamestate.change_character_player(load("res://assets/css/eggoon.png"))
	play_select_audio()
	
func _on_tomato_pressed() -> void:
	$CSSPlayers/P1/Image.texture = load("res://assets/css/tomato.png")
	gamestate.change_character_player(load("res://assets/css/tomato.png"))
	play_select_audio()

func _on_secret_1_pressed() -> void:
	play_error_audio()

func _on_secret_2_pressed() -> void:
	play_error_audio()

func _on_secret_3_pressed() -> void:
	play_error_audio()

func _on_secret_4_pressed() -> void:
	play_error_audio()
