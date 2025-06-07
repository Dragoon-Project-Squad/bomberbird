extends CanvasLayer

@onready var match_timer: Timer = %MatchTimer
@onready var score_panel_container: Container = %ScorePanelContainer
@onready var time_label: Label = %TimeLabel

const COLOR_ARR: Array[Color] = [Color8(255, 100, 100), Color8(100, 255, 255), Color8(255, 178, 100), Color8(163, 255, 156)]

var player_labels = {}
var players_left = -1
var someone_dead = false
var time

var player_score_panel: Array[ScorePanel]
var used_player_score_panel_len: int = 0

func _ready() -> void:
	globals.game.game_ui = self
	for child in score_panel_container.get_children():
		if child is ScorePanel:
			player_score_panel.append(child)

@rpc("call_local")
func add_player(id: int, _player_name: String, character: String):
	assert(used_player_score_panel_len <= 3, "attempted to add a 5th player but only 4 are supported")
	player_score_panel[used_player_score_panel_len].player_id = id
	player_score_panel[used_player_score_panel_len].show()
	player_score_panel[used_player_score_panel_len].update_icon(character)
	player_score_panel[used_player_score_panel_len].update_icon_color(COLOR_ARR[used_player_score_panel_len])
	player_labels[id] = used_player_score_panel_len
	used_player_score_panel_len += 1

func start_timer(gametime := SettingsContainer.get_match_time()):
	match_timer.start(gametime)
	
func stop_timer():
	match_timer.stop()
	
func _process(_delta: float) -> void:
	time_label.set_text(time_to_string(match_timer.get_time_left()))

func increase_score(playername : String):
	var score_panel_slot_num = player_labels[playername]
	score_panel_container[score_panel_slot_num].increment_score()
	
func decrease_score(playername : String):
	var score_panel_slot_num = player_labels[playername]
	score_panel_container[score_panel_slot_num].decrement_score()

func get_player_score(playername : String):
	var score_panel_slot_num = player_labels[playername]
	return score_panel_container[score_panel_slot_num].score

func time_to_string(time := 120.0) -> String:
	var seconds = fmod(time, 60)
	var minutes = time / 60
	var format_string = "%02d:%02d"
	var actual_time_string = format_string % [minutes, seconds]
	return actual_time_string

func _on_hurry_up_start() -> void:
	time_label.add_theme_color_override("font_color", Color(255, 0, 0)) # Replace with function body.
