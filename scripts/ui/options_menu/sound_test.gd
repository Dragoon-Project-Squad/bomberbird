extends VBoxContainer
@onready var mus_dropdown: OptionButton = $MusContainer/MusDropdown
@onready var sfx_dropdown: OptionButton = $SFXContainer/SFXDropdown
@onready var mus_player: AkEvent2D = $MusPlayer
@onready var sfx_player: AkEvent2D = $SFXPlayer

var selected_mus = "play_music_dragoon_cafe"
var selected_sfx = "snd_click"

enum music_enum {DOKIDOKICOMESHOME, DRAGOONCAFE, BHJAM, RUSH, DADDRIVE, MINKI}
enum sfx_enum {CLICK, ERROR, EXPLODE, DEBRIS, PICKUP, DEFEATED, PLACE, THROW, LAND, SECRET}

var mus_dict = {
	"Doki Doki Comes Home" = "play_music_dragoon_cafe",
	"Dragoon Cafe" = "play_music_main_menu",
	"BountyHunter Jam" = "play_music_battle",
	"Rush (Game Mix)" = "play_music_battle",
	"D.A.D. Drive" = "play_music_battle",
	"Theme of Minki" = "play_music_battle"
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
	

func _on_mus_dropdown_item_selected(index: int) -> void:
	selected_mus = mus_dict[mus_dict.keys()[index]]
	
func _on_mus_play_button_pressed() -> void:
	Wwise.post_event("pause_music_dragoon_cafe", mus_player)# Pause options music
	Wwise.post_event("play_music_battle", mus_player) #Need finer grain control for playing songs.

func _on_mus_stop_button_pressed() -> void:
	Wwise.post_event("unpause_music_dragoon_cafe",mus_player) #Replay options music

func _on_sfx_dropdown_item_selected(index: int) -> void:
	selected_sfx = sfx_dict[sfx_dict.keys()[index]]

func _on_sfx_play_button_pressed() -> void:
	Wwise.post_event(selected_sfx,sfx_player)

func _on_settings_tab_container_options_menu_exited() -> void:
	#Call stop on the mus event HERE
	pass # Replace with function body.
