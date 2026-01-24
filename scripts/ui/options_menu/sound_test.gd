extends Control
@onready var mus_dropdown: OptionButton = $MusContainer/MusDropdown
@onready var sfx_dropdown: OptionButton = $SFXContainer/SFXDropdown
@onready var mus_player: AkEvent2D = $MusPlayer
@onready var sfx_player: AkEvent2D = $SFXPlayer

var selected_mus = "st_doki_comes_home"
var selected_sfx = "snd_click"

var options_menu

enum music_enum {DOKIDOKICOMESHOME, DRAGOONCAFE, BHJAM, RUSH, DADDRIVE, MINKI}
enum sfx_enum {CLICK, ERROR, EXPLODE, DEBRIS, PICKUP, DEFEATED, PLACE, THROW, LAND, SECRET, MNTSUMMON, MNTSTEP, MNTDIE}

var mus_dict = {
	"Doki Doki Comes Home" = "st_doki_comes_home",
	"Menu Theme Actually" = "st_menu",
	"Dragoon Cafe" = "st_dragoon_cafe",
	"BountyHunter Blitz" = "st_bh_blitz",
	"BountyHunter Jam" = "st_bh_jam",
	"Rush (Game Mix)" = "st_rush",
	"D.A.D. Drive" = "st_dad",
	"Theme of Minki" = "st_minki",
	"Scott Joplin's New Rag" = "st_vintage"
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
	"Secret" = "snd_secret",
	"Mount Summon" = "snd_cockobo_summon",
	"Mount Step" = "snd_cockobo_footstep",
	"Mount Death" = "snd_cockobo_die"
	}
	
func _ready() -> void:
	for mus in mus_dict.keys():
		mus_dropdown.add_item(mus)
	for sfx in sfx_dict.keys():
		sfx_dropdown.add_item(sfx)

func _on_mus_dropdown_item_selected(index: int) -> void:
	selected_mus = mus_dict[mus_dict.keys()[index]]
	
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

func _on_settings_tab_container_options_menu_exited() -> void:
	Wwise.post_event("st_stop_music", mus_player)
