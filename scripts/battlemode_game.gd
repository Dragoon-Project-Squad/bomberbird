extends Game

@onready var stage_loader: Node = $StageLoader
@onready var fade_in_out: AnimationPlayer = $FadeInOut
var stageMusic: AudioStreamPlayer2D

func _ready():
	super()
	
func start():
	load_stage()
	stage.enable()

func load_stage() -> void:
	stage = load(globals.LAB_RAND_STAGE_PATH).instantiate()
	stage_loader.add_child(stage)
	stageMusic = stage.get_node("Music/MusicPlayer")

func wipe_stage():
	reset()
	stage.disable()
	
func lock_misobon():
	var misoplayers: Array[MisobonPlayer] = Array($MisobonPath.get_children().filter(func (p): return (p is MisobonPlayer)), TYPE_OBJECT, "PathFollow2D", MisobonPlayer)
	if is_multiplayer_authority():
		for misoplayer in misoplayers:
			misoplayer.disable_at_end_of_round.rpc()

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
			
## checks if there is only 1 alive player if so makes that player win, if there is no player is draws the game and for any other state this function does nothing
func _check_ending_condition(_alive_enemies: int = 0):
	if win_screen.visible: return
	var alive_players: Array[Player] = globals.player_manager.get_alive_players()
	if len(alive_players) < 2:
		await get_tree().create_timer(1).timeout
	if len(alive_players) < 2:
		# If we can still confirm only 1 or 0 players are alive after one second...
		stageMusic.stop()
		%MatchTimer.stop()
		lock_misobon()
	if len(alive_players) == 0:
		#fade_in_out.play("fade_out")
		#await fade_in_out.animation_finished
		#DO WIN SCREEN STUFF
		#RESET GAME STATE
		wipe_stage()
		reset_players()
		#LOAD NEW STAGE
		load_new_stage()
		fade_in_out.play("fade_in")
		await fade_in_out.animation_finished
		
	if len(alive_players) == 1:
		await alive_players[0].play_victory(true)
		#fade_in_out.play("fade_out")
		#await fade_in_out.animation_finished
		#DO WIN SCREEN STUFF
		#RESET GAME STATE
		wipe_stage()
		reset_players()
		#LOAD NEW STAGE
		load_new_stage()
		fade_in_out.play("fade_in")
		await fade_in_out.animation_finished
