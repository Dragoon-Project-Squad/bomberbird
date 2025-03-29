extends CanvasLayer

var player_labels = {}
var players_left = -1
var someone_dead = false
var time
signal game_decided(winningplayer)

@onready var match_timer: Timer = %MatchTimer
@onready var remaining_time: Label = %RemainingTime
@onready var player_container: HBoxContainer = $Border/Container/Players

func _process(_delta: float) -> void:
	time = match_timer.get_time_left()
	# Only begin counting score if all human players have been loaded
	if players_left <= 1 && someone_dead:
		await get_tree().create_timer(2.0).timeout
		#In SUPER mode this timer is needed as otherwise the game end prematurly. This is bad... 
		#TODO make a better system that keeps track of alive players and accounts for timedelay in respawning
		if players_left <= 1:
			#Declare a winner
			call_deferred("decide_game", players_left)
			process_mode = PROCESS_MODE_DISABLED
	remaining_time.set_text(time_to_string())

func player_died():
	if players_left == -1:
		players_left = $"../Players".get_child_count()
		someone_dead = true

	players_left -= 1

func player_revived():
	players_left += 1

func decide_game(final_players: int):
	# First check if zero players are alive. If so, this is a draw game.
	if final_players == 0:
		game_decided.emit(null)
	# Second check if only one player is alive. If so, they win.
	if final_players == 1:
		for player in $"../Players".get_children():
			if !player.is_dead:
				game_decided.emit(player)
				return
	# If this somehow doesn't work, then decide via score.
	if final_players == 1:
		var winner_name = ""
		var winner_score = 0
		for p in player_labels:
			if player_labels[p].score > winner_score:
				winner_score = player_labels[p].score
				winner_name = player_labels[p].name
				game_decided.emit(p)

func increase_score(for_who):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score += 1
	pl.scorelabel.set_text(str(pl.score))
	
func decrease_score(for_who):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score -= 1
	pl.scorelabel.set_text(str(pl.score))

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


func _on_hurry_up_hurry_up_start() -> void:
	remaining_time.add_theme_color_override("font_color", Color(255, 0, 0)) # Replace with function body.
