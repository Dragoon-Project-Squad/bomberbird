extends CanvasLayer

var player_labels = {}
var players_left = -1
var someone_dead = false
var time

@onready var match_timer: Timer = %MatchTimer
@onready var remaining_time: Label = %RemainingTime
@onready var player_container: HBoxContainer = $Border/Container/Players

func _ready() -> void:
	globals.game.game_ui = self
	

func start_timer(gametime := SettingsContainer.get_match_time()):
	match_timer.start(gametime)
	$Border/Container/Players/Timer/RemainingTime.visible = true
	
func stop_timer():
	match_timer.stop()
	$Border/Container/Players/Timer/RemainingTime.visible = false
	
func _process(_delta: float) -> void:
	time = match_timer.get_time_left()
	remaining_time.set_text(time_to_string())

func increase_score(playername : String):
	assert(playername.to_int())
	var pid : int = playername.to_int()
	assert(pid in player_labels)
	var pl = player_labels[pid]
	pl.score += 1
	pl.scorelabel.set_text(str(pl.score))
	
func decrease_score(playername : String):
	assert(playername.to_int())
	var pid : int = playername.to_int()
	assert(pid in player_labels)
	var pl = player_labels[pid]
	pl.score -= 1
	pl.scorelabel.set_text(str(pl.score))

func get_player_score(playername : String):
	assert(playername.to_int())
	var pid : int = playername.to_int()
	assert(pid in player_labels)
	var pl = player_labels[pid]
	return pl.score

@rpc("call_local")
func add_player(id: int, new_player_name: String):
	var order: int = player_labels.size() + 1

	player_labels[id] = {
		namelabel = player_container.get_node("P" + str(order) + "/P" + str(order) + "Name"),
		scorelabel = player_container.get_node("P" + str(order) + "/P" + str(order) + "Score"),
		score = 0
	}

	player_labels[id].namelabel.set_text(new_player_name)

	if order == 1: return
	player_container.get_node("P" + str(order)).visible = true
	player_container.get_node("SeparatorP" + str(order - 1) + str(order)).visible = true

func time_to_string() -> String:
	var seconds = fmod(time, 60)
	var minutes = time / 60
	var format_string = "%02d:%02d"
	var actual_time_string = format_string % [minutes, seconds]
	return actual_time_string

func _on_exit_game_pressed() -> void:
	gamestate.end_game()


func _on_hurry_up_start() -> void:
	remaining_time.add_theme_color_override("font_color", Color(255, 0, 0)) # Replace with function body.
