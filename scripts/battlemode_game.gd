extends Game

@onready var stage_loader: Node = $StageLoader
@onready var game_anim_player: AnimationPlayer = $AnimPlayer
var stageMusic: AudioStreamPlayer2D
@onready var announcer: AudioStreamPlayer = $MatchAudio/Announcer
@onready var multiplayer_game_ui: CanvasLayer = $MultiplayerGameUI
@onready var game_end_state: Control = $GameEndState
var game_ended: bool = false
@onready var fade_in_out_rect: ColorRect = $FadeInOutRect

func _ready():
	super()
	
func start():
	load_stage()
	stage.enable() #Set up the stage.
	call_deferred("freeze_players") #Lock all players movement.
	await remove_the_darkness()
	show_all_players()
	await start_stage_start_countdown() #
	game_ended = false
	
func load_stage() -> void:
	var stage_path := globals.LAB_RAND_STAGE_PATH
	if SettingsContainer.get_breakable_spawn_rule() == 2:
		load_full_stage()
	else:
		load_custom_stage()
	stage = load(stage_path).instantiate()
	stage_loader.add_child(stage)
	stageMusic = stage.get_node("Music/MusicPlayer")

func load_custom_stage() -> String:
	var stage_path_to_load
	match SettingsContainer.get_stage_choice():
		0:
			stage_path_to_load = globals.DESERT_RAND_STAGE_PATH
		1:
			stage_path_to_load = globals.BEACH_RAND_STAGE_PATH
		2:
			stage_path_to_load = globals.DUNGEON_RAND_STAGE_PATH
		3:
			stage_path_to_load = globals.LAB_RAND_STAGE_PATH
		_:
			stage_path_to_load = globals.DESERT_FULL_STAGE_PATH
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
	stageMusic.play()
	%MatchTimer.start()
	multiplayer_game_ui.start_timer()
	
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
			
func reset_players():
	var misoplayers: Array[MisobonPlayer] = Array($MisobonPath.get_children().filter(func (p): return (p is MisobonPlayer)), TYPE_OBJECT, "PathFollow2D", MisobonPlayer)
	var deadplayers: Array[Player] = globals.player_manager.get_dead_players()
	if is_multiplayer_authority():
		for misoplayer in misoplayers:
			misoplayer.reset(stage.spawnpoints[0])
		for deadplayer in deadplayers:
			deadplayer.reset()
			
func load_new_stage():
	stage.queue_free()
	start()

func stop_the_match():
	game_ended = true
	stageMusic.stop()
	%MatchTimer.stop()
	multiplayer_game_ui.stop_timer()
	lock_misobon()
	defuse_all_bombs()
	
func play_fade_out():
	game_anim_player.play("fade_out")
	await game_anim_player.animation_finished
	hide_all_players()
	
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
			multiplayer_game_ui.increase_score(alive_players[0].name)
			await alive_players[0].play_victory(true)
		await play_fade_out()
		await get_tree().create_timer(2).timeout
		#DO WIN SCREEN STUFF
		if multiplayer_game_ui.get_player_score(alive_players[0].name) >= SettingsContainer.get_points_to_win():
			game_end_state.declare_winner(alive_players[0])
		else:
			#RESET GAME STATE
			wipe_stage()
			reset_players()
			freeze_players()
			#LOAD NEW STAGE
			load_new_stage()
		return
