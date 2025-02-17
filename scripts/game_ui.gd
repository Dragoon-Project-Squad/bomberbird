extends CanvasLayer

var player_labels = {}
var players_left = 5
var someone_dead = false
var time
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"../Winner".hide()
	set_process(true)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	time = %MatchTimer.get_time_left()
	#Declare a winner
	players_left = $"../Players".get_child_count()
	# Only begin counting score if all human players have been loaded
	for player in $"../Players".get_children():
		if player.is_dead:
			players_left -= 1
			someone_dead = true
	if players_left <= 1 && someone_dead:
		await get_tree().create_timer(1.0).timeout
		call_deferred("decide_game", players_left)
		process_mode = PROCESS_MODE_DISABLED
	%RemainingTime.set_text(time_to_string())


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
	pl.scorelabel.set_text(str(pl.score))
	
func decrease_score(for_who):
	assert(for_who in player_labels)
	var pl = player_labels[for_who]
	pl.score -= 1
	pl.scorelabel.set_text(str(pl.score))


func add_player(id, new_player_name):
	# Use size of current array to figure out which player to assign
	match player_labels.size():
		0:	set_player_one(id, new_player_name)
		1:	set_player_two(id, new_player_name)
		2:	set_player_three(id, new_player_name)
		3:	set_player_four(id, new_player_name)
		_:	set_player_four(id, new_player_name)
	#var l = Label.new()
	#l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#l.set_text(new_player_name + "\n" + "0")
	#l.set_h_size_flags(SIZE_EXPAND_FILL)
	#var font = preload("res://montserrat.otf")
	#l.set("custom_fonts/font", font)
	#l.set("custom_font_size/font_size", 18)
	#add_child(l)
	#player_labels[id] = { name = new_player_name, label = l, score = 0 }

func set_player_one(id, new_player_name):
	$Border/Container/Players/P1/P1Name.set_text(new_player_name)
	player_labels[id] = { namelabel = $Border/Container/Players/P1/P1Name, scorelabel = $Border/Container/Players/P1/P1Score, score = 0 }

func set_player_two(id, new_player_name):
	$Border/Container/Players/P2/P2Name.set_text(new_player_name)
	player_labels[id] = { namelabel = $Border/Container/Players/P2/P2Name, scorelabel = $Border/Container/Players/P2/P2Score, score = 0 }
	$Border/Container/Players/P2.visible = true
	$Border/Container/Players/SeparatorP12.visible = true

func set_player_three(id, new_player_name):
	$Border/Container/Players/P3/P3Name.set_text(new_player_name)
	player_labels[id] = { namelabel = $Border/Container/Players/P3/P3Name, scorelabel = $Border/Container/Players/P3/P3Score, score = 0 }
	$Border/Container/Players/P3.visible = true
	$Border/Container/Players/SeparatorP23.visible = true
	
func set_player_four(id, new_player_name):
	$Border/Container/Players/P4/P4Name.set_text(new_player_name)
	player_labels[id] = { namelabel = $Border/Container/Players/P4/P4Name, scorelabel = $Border/Container/Players/P4/P4Score, score = 0 }
	$Border/Container/Players/P4.visible = true
	$Border/Container/Players/SeparatorP34.visible = true
	
func time_to_string() -> String:
	var seconds = fmod(time, 60)
	var minutes = time / 60
	var format_string = "%02d:%02d"
	var actual_time_string = format_string % [minutes, seconds]
	return actual_time_string

func _on_exit_game_pressed() -> void:
	gamestate.end_game()
