extends Game

@onready var stage_loader: Node = $StageLoader
@onready var game_anim_player: AnimationPlayer = $AnimPlayer
@onready var announcer: AudioStreamPlayer = $MatchAudio/Announcer
@onready var fade_in_out_rect: ColorRect = $FadeInOutRect

var game_ended: bool = false
func _ready():
	super()
	
func start():
	load_stage()
	stage.reset.call_deferred()
	stage.enable.call_deferred() #Set up the stage.
	call_deferred("freeze_players") #Lock all players movement.
	await remove_the_darkness()
	show_all_players()
	await start_stage_start_countdown() #
	game_ended = false
	stage_done = false

func load_stage() -> void:
	var stage_path := globals.LAB_RAND_STAGE_PATH
	if SettingsContainer.get_breakable_spawn_rule() == 2:
		stage_path = load_full_stage()
	else:
		stage_path = load_custom_stage()
	stage = load(stage_path).instantiate()
	stage_loader.add_child(stage)

func load_custom_stage() -> String:
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
		SettingsContainer.multiplayer_stages_secret_enabled.SECRET:
			stage_path_to_load = globals.SECRET_RAND_STAGE_PATH
		_:
			stage_path_to_load = globals.DESERT_RAND_STAGE_PATH
	return stage_path_to_load
		
func load_full_stage() -> String:
	var stage_path_to_load
	match SettingsContainer.get_stage_choice():
		0:
			stage_path_to_load = globals.DESERT_FULL_STAGE_PATH
		1:
			stage_path_to_load = globals.BEACH_FULL_STAGE_PATH
		2:
			stage_path_to_load = globals.DUNGEON_FULL_STAGE_PATH
		3:
			stage_path_to_load = globals.LAB_FULL_STAGE_PATH
		_:
			stage_path_to_load = globals.DESERT_FULL_STAGE_PATH
	return stage_path_to_load
	
func remove_the_darkness():
	if fade_in_out_rect.visible:
		game_anim_player.play("fade_in")
		await game_anim_player.animation_finished
	
func wipe_stage():
	reset()
	stage.disable()
	
func defuse_all_bombs():
	var bombs: Array[BombRoot] = Array($BombPool.get_children().filter(func (p): return (p is BombRoot)), TYPE_OBJECT, "Node2D", BombRoot)
	if is_multiplayer_authority():
		for bomb in bombs:
			bomb.disable.rpc()
			
func lock_misobon():
	var misoplayers: Array[MisobonPlayer] = Array($MisobonPath.get_children().filter(func (p): return (p is MisobonPlayer)), TYPE_OBJECT, "PathFollow2D", MisobonPlayer)
	if is_multiplayer_authority():
		for misoplayer in misoplayers:
			misoplayer.disable_at_end_of_round.rpc()

func start_stage_start_countdown():
	game_anim_player.play("countdown")
	await game_anim_player.animation_finished

func activate_ui_and_music():
	stage.start_music()
	%MatchTimer.start()
	game_ui.start_timer()
	
func freeze_players():
	var players: Array[Player] = globals.player_manager.get_players()
	if is_multiplayer_authority():
		for player in players:
			player.stunned = true

func unfreeze_players():
	var players: Array[Player] = globals.player_manager.get_players()
	if is_multiplayer_authority():
		for player in players:
			player.stunned = false

func hide_all_players():
	var players: Array[Player] = globals.player_manager.get_players()
	if is_multiplayer_authority():
		for player in players:
			player.hide()
			
func show_all_players():
	var players: Array[Player] = globals.player_manager.get_players()
	if is_multiplayer_authority():
		for player in players:
			player.show()
			

			
func load_new_stage():
	stage_done = true
	stage.queue_free()
	start()


func stop_the_match():
	game_ended = true
	stage.stop_music()
	%MatchTimer.stop()
	game_ui.stop_timer()
	lock_misobon()
	defuse_all_bombs()
	# Halt Hurry Up
	
func play_fade_out():
	game_anim_player.play("fade_out")
	await game_anim_player.animation_finished
	hide_all_players()

@rpc("call_local")
func show_victory_screen(player_data):
	gamestate.player_data_master_dict = player_data.duplicate()
	get_tree().call_deferred("change_scene_to_file","res://scenes/victory_screen.tscn")
	
## checks if there is only 1 alive player if so makes that player win, if there is no player is draws the game and for any other state this function does nothing
func _check_ending_condition(_alive_enemies: int = 0):
	if game_ended: 
		return
	var alive_players: Array[Player] = globals.player_manager.get_alive_players()
	if len(alive_players) > 1: 
		return
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
		await play_fade_out()
		await get_tree().create_timer(2).timeout
		#DO WIN SCREEN STUFF
		if game_ui.get_player_score(alive_players[0].name.to_int()) >= SettingsContainer.get_points_to_win():
			if is_multiplayer_authority():
				gamestate.set_player_scores(globals.game.game_ui.get_all_scores())
				show_victory_screen.rpc(gamestate.player_data_master_dict.duplicate())
		else:
			#RESET GAME STATE
			wipe_stage()
			reset_players()
			freeze_players()
			#LOAD NEW STAGE
			load_new_stage()
		return
