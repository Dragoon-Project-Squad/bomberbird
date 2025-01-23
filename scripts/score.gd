extends HBoxContainer

var player_labels = {}
var player_count = gamestate.total_player_count

func _process(_delta):
	#Declare a winner
	var players_left = player_count
	for player in $"../Players".get_children():
		if player.is_dead:
			players_left -= 1
	if players_left <= 1:
		await get_tree().create_timer(1.0).timeout
		call_deferred("decide_game", players_left)
		process_mode = PROCESS_MODE_DISABLED

func decide_game(final_players: int):
	# First check if zero players are alive. If so, this is a draw game.
	if final_players == 0:
		$"../Winner".set_text("DRAW GAME")
		$"../Winner".show()
	# Second check if only one player is alive. If so, they win.
	if final_players == 1:
		for player in $"../Players".get_children():
			if !player.is_dead:
				$"../Winner".set_text("THE WINNER IS:\n" + 	player.get_player_name())
				$"../Winner".show()
				return
	# If this somehow doesn't work, then decide via score.
	if final_players == 1:
		var winner_name = ""
		var winner_score = 0
		for p in player_labels:
			if player_labels[p].score > winner_score:
				winner_score = player_labels[p].score
				winner_name = player_labels[p].name
		$"../Winner".set_text("THE WINNER IS:\n" + winner_name)
		$"../Winner".show()

func increase_score(for_who):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score += 1
	pl.label.set_text(pl.name + "\n" + str(pl.score))
	
func decrease_score(for_who):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score -= 1
	pl.label.set_text(pl.name + "\n" + str(pl.score))


func add_player(id, new_player_name):
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_text(new_player_name + "\n" + "0")
	l.set_h_size_flags(SIZE_EXPAND_FILL)
	var font = preload("res://montserrat.otf")
	l.set("custom_fonts/font", font)
	l.set("custom_font_size/font_size", 18)
	add_child(l)

	player_labels[id] = { name = new_player_name, label = l, score = 0 }


func _ready():
	$"../Winner".hide()
	set_process(true)


func _on_exit_game_pressed():
	gamestate.end_game()
