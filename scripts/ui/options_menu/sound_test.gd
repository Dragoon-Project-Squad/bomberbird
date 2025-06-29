extends VBoxContainer
@onready var mus_dropdown: OptionButton = $MusContainer/MusDropdown
@onready var sfx_dropdown: OptionButton = $SFXContainer/SFXDropdown
@onready var mus_player: AkEvent2D = $MusPlayer
@onready var sfx_player: AkEvent2D = $SFXPlayer

var selected_mus = "st_doki_comes_home"
var selected_sfx = "snd_click"

@onready var options_menu = mus_player.get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent()

enum music_enum {DOKIDOKICOMESHOME, DRAGOONCAFE, BHJAM, RUSH, DADDRIVE, MINKI}
enum sfx_enum {CLICK, ERROR, EXPLODE, DEBRIS, PICKUP, DEFEATED, PLACE, THROW, LAND, SECRET}

var mus_dict = {
	"Doki Doki Comes Home" = "st_doki_comes_home",
	"Dragoon Cafe" = "st_dragoon_cafe",
	"BountyHunter Jam" = "st_bh_jam",
	"Rush (Game Mix)" = "st_rush",
	"D.A.D. Drive" = "st_dad",
	"Theme of Minki" = "st_minki"
	}

var sfx_dict = {
	"Click" = "snd_click",
	"Error" = "snd_error",
	"Explode" = "snd_bomb_explode",
	"Debris" = "snd_debris",
	"Pickup" = "snd_pickup_powerup",
	"Player Defeated" = "snd_player_hurt",
	"Place Bomb" = "snd_place_bomb",
	"Throw Bomb" = "snd_throw_bomb",
	"Bomb Landing" = "snd_thrown_bomb_land",
	"Secret" = "snd_secret"
	}
	
func _ready() -> void:
	for mus in mus_dict.keys():
		mus_dropdown.add_item(mus)
	for sfx in sfx_dict.keys():
		sfx_dropdown.add_item(sfx)
	print("Options menu = " + str(options_menu))

func _on_mus_dropdown_item_selected(index: int) -> void:
	selected_mus = mus_dict[mus_dict.keys()[index]]
	print(selected_mus)
	
func _on_mus_play_button_pressed() -> void:
	Wwise.post_event("st_stop_music", mus_player)
	Wwise.post_event("pause_music_dragoon_cafe", options_menu)# Pause options music
	Wwise.post_event(selected_mus, mus_player) #plays the selected song

func _on_mus_stop_button_pressed() -> void:
	Wwise.post_event("st_stop_music", mus_player)
	Wwise.post_event("unpause_music_dragoon_cafe", options_menu) #Replay options music

func _on_sfx_dropdown_item_selected(index: int) -> void:
	selected_sfx = sfx_dict[sfx_dict.keys()[index]]

func _on_sfx_play_button_pressed() -> void:
	Wwise.post_event(selected_sfx,sfx_player)
