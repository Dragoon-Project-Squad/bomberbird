extends Game

@onready var stage_loader: Node = $StageLoader
@onready var game_anim_player: AnimationPlayer = $AnimPlayer
@onready var announcer: AudioStreamPlayer = $MatchAudio/Announcer
@onready var fade_in_out_rect: ColorRect = $FadeInOutRect

var game_ended: bool = false
func _ready():
	super()
	gamestate.game_error.connect(_on_game_error)
	
	#sets Wwise states for horizontally adaptive tracks to "a" and "game_on", aka the first track and the game's not over
	Wwise.set_state("game_state", "game_on")
	Wwise.set_state("battle_state", "a")
	
func start():
	if !stage:
		load_stage()
		stage.reset.call_deferred()
	stage.enable.call_deferred() #Set up the stage.
	freeze_players.call_deferred()
	
	#This makes sure the actual music plays after each round
	Wwise.set_state("game_state", "game_on")
	
	await remove_the_darkness()
	show_all_players()
	await start_stage_start_countdown() #
	game_ended = false
	stage_done = false
	

func load_stage() -> void:
	var stage_path := load_chosen_stage()
	stage = load(stage_path).instantiate()
	stage_loader.add_child(stage)
	
	#Start music here instead of at activateuiandmusic to have a more seamless music experience
	stage.start_music()	

func load_chosen_stage() -> String:
	var stage_path_to_load
	match SettingsContainer.get_stage_choice():
		SettingsContainer.multiplayer_stages_secret_enabled.SALOON:
			stage_path_to_load = globals.DESERT_RAND_STAGE_PATH
		SettingsContainer.multiplayer_stages_secret_enabled.BEACH:
			stage_path_to_load = globals.BEACH_RAND_STAGE_PATH
		SettingsContainer.multiplayer_stages_secret_enabled.DUNGEON:
			stage_path_to_load = globals.DUNGEON_RAND_STAGE_PATH
		SettingsContainer.multiplayer_stages_secret_enabled.LAB:
			stage_path_to_load = globals.LAB_RAND_STAGE_PATH
		SettingsContainer.multiplayer_stages_secret_enabled.SCHOOL:
			stage_path_to_load = globals.SCHOOL_RAND_STAGE_PATH
		SettingsContainer.multiplayer_stages_secret_enabled.SECRET:
			stage_path_to_load = globals.SECRET_RAND_STAGE_PATH
		SettingsContainer.multiplayer_stages_secret_enabled.VINTAGE:
			stage_path_to_load = globals.VINTAGE_RAND_STAGE_PATH
		_:
			stage_path_to_load = globals.DESERT_RAND_STAGE_PATH
	return stage_path_to_load
	
func remove_the_darkness():
	if fade_in_out_rect.visible:
		game_anim_player.play("fade_in")
		await game_anim_player.animation_finished
	
func wipe_stage():
	game_ui.reset()
	reset()
	stage.reset()
	stage.disable()

func start_stage_start_countdown() -> Signal:
	game_anim_player.play("countdown")
	return game_anim_player.animation_finished
	#Animation contains unfreeze_players()
	#Animation contains activate_ui_and_music()

func activate_ui_and_music():
	%MatchTimer.start()
	game_ui.start_timer()
	
func load_new_stage():
	stage_done = true
	start.call_deferred()
	
func show_all_players():
	var players: Array[Player] = globals.player_manager.get_players()
	for player in players:
		player.show()

func freeze_players():
	var players: Array[Player] = globals.player_manager.get_players()
	for player in players:
		player.outside_of_game = true

func unfreeze_players():
	var players: Array[Player] = globals.player_manager.get_players()
	for player in players:
		player.outside_of_game = false

func hide_all_players():
	var players: Array[Player] = globals.player_manager.get_players()
	for player in players:
		player.hide()
			
			
## checks if there is only 1 alive player if so makes that player win, if there is no player is draws the game and for any other state this function does nothing
func _check_ending_condition(_alive_enemies: int = 0):
	if game_ended: 
		return
	var alive_players: Array[Player] = globals.player_manager.get_alive_players()
	if len(alive_players) < 2:
		game_ended = true
		await get_tree().create_timer(0.5).timeout
		# Give the last player 0.5s to somehow fumble into a Draw
		alive_players = globals.player_manager.get_alive_players()
	if len(alive_players) > 1: 
		game_ended = false # False alarm.
		return
	else:
		stop_the_match()
		if len(alive_players) == 1:
			# SHOW EM WHAT THEY'VE WON
			game_ui.increase_score(alive_players[0].name.to_int())
			await alive_players[0].play_victory(false)
		
		var points_to_win = SettingsContainer.get_points_to_win()
		
		#horizontal adaptive music stuff
		if !alive_players.is_empty():
			var top_score = game_ui.get_player_score(alive_players[0].name.to_int())
			if  top_score >= points_to_win - 1:
				Wwise.set_state("battle_state", "e")
			elif float(top_score) >= float(points_to_win) * 3 / 4:
				Wwise.set_state("battle_state", "d")
			elif float(top_score) >= float(points_to_win) * 2 / 4:
				Wwise.set_state("battle_state", "c")
			elif float(top_score) >= float(points_to_win) * 1 / 4:
				Wwise.set_state ("battle_state", "b")
		
		await play_fade_out()
		await get_tree().create_timer(2).timeout
		#DO WIN SCREEN STUFF
		if !alive_players.is_empty() && game_ui.get_player_score(alive_players[0].name.to_int()) >= points_to_win:
			if is_multiplayer_authority():
				
				#plays the victory track for the vintage stage (and other horizontally adaptive tracks)
				Wwise.set_state("game_state", "game_over")
				
				gamestate.set_player_scores(globals.game.game_ui.get_all_scores())
				show_victory_screen.rpc(gamestate.player_data_master_dict.duplicate())
		else:
			#RESET GAME STATE
			reset_players() 
			wipe_stage() #Must occur after players reset to avoid AI pathing error.
			#LOAD NEW STAGE
			load_new_stage()
		return

func stop_the_match():
	game_ended = true
	
	#stage.stop_music()
	#Set wwise state to the transition track which will depend on music track state
	Wwise.set_state("game_state", "game_transitioning")
	
	stage.stop_hurry_up()
	if not %MatchTimer.is_stopped():
		%MatchTimer.stop()
		game_ui.stop_timer()
	disable_misobon()
	defuse_all_bombs()
	
func disable_misobon():
	var misoplayers: Array[MisobonPlayer] = Array($MisobonPath.get_children().filter(func (p): return (p is MisobonPlayer)), TYPE_OBJECT, "PathFollow2D", MisobonPlayer)
	if is_multiplayer_authority():
		for misoplayer in misoplayers:
			misoplayer.disable_at_end_of_round.rpc()

func defuse_all_bombs():
	var bombs: Array[BombRoot] = Array($BombPool.get_children().filter(func (p): return (p is BombRoot)), TYPE_OBJECT, "Node2D", BombRoot)
	if is_multiplayer_authority():
		for bomb in bombs:
			bomb.disable.rpc()

func play_fade_out():
	game_anim_player.play("fade_out")
	await game_anim_player.animation_finished
	hide_all_players()

@rpc("call_local")
func show_victory_screen(player_data):
	gamestate.player_data_master_dict = player_data.duplicate()
	get_tree().call_deferred("change_scene_to_file","res://scenes/victory_screen.tscn")

func _on_game_error(errtxt):
	if is_inside_tree():
		$ErrorDialog.dialog_text = errtxt
		$ErrorDialog.popup_centered()
		
func _on_error_dialog_confirmed() -> void:
	gamestate.end_game()
	if gamestate.peer:
		gamestate.peer.close()
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_multiplayer_game_ui_matchtimer_timeout() -> void:
	#DRAW GAME DUE TO TIME
	stop_the_match()
	freeze_players()
	await play_fade_out()
	await get_tree().create_timer(2).timeout
	#RESET GAME STATE
	reset_players() 
	wipe_stage() #Must occur after players reset to avoid AI pathing error.
	#LOAD NEW STAGE
	load_new_stage()
