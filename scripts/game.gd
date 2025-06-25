class_name Game extends Node2D
## Represents a currently running game (of some game mode) handles the stage and all objects it contains

signal stage_has_changed
signal clock_pickup_time_paused(user: String, is_player: bool)
signal clock_pickup_time_unpaused()

@onready var fade: AnimationPlayer = get_node("AnimPlayer")

var player_manager: PlayerManager
var player_spawner: MultiplayerSpawner
var misobon_path: MisobonPath
var misobon_player_spawner: MultiplayerSpawner
var exit_pool: ExitPool
var enemy_pool: EnemyPool
var bomb_pool: BombPool
var pickup_pool: PickupPool
var breakable_pool: BreakablePool
var stage: World
var game_ui
var win_screen
var time_stopped_timer: SceneTreeTimer
var stage_done: bool = false
var players_are_spawned: bool = false

func _init():
	globals.game = self

func _ready():
	pass
	
## starts the game is only called once
func start():
	pass

## resets the game s.t. a new stage can be loaded
func reset():
	if time_stopped_timer && globals.current_gamemode == globals.gamemode.CAMPAIGN:
		for sig_dict in time_stopped_timer.timeout.get_connections():
			sig_dict.signal.disconnect(sig_dict.callable)
	clock_pickup_time_unpaused.emit()
	for bomb in bomb_pool.get_children().filter(func (b): return b is BombRoot && b.in_use):
		if is_multiplayer_authority():
			bomb.disable.rpc()
		bomb_pool.return_obj(bomb)

	for pickup in pickup_pool.get_children().filter(func (p): return p is Pickup && p.in_use):
		if is_multiplayer_authority():
			pickup.disable_collison_and_hide.rpc()
			pickup.disable.rpc()
		pickup_pool.return_obj(pickup)

	for breakable in breakable_pool.get_children().filter(func (b): return b is Breakable && b.in_use):
		if is_multiplayer_authority():
			breakable.disable_collison_and_hide.rpc()
			breakable.disable.rpc()
		breakable_pool.return_obj(breakable)

func pause_time(_user: String, _is_player: bool):
	time_stopped_timer = get_tree().create_timer(16)
	time_stopped_timer.timeout.connect(func(): clock_pickup_time_unpaused.emit())
	%MatchTimer.paused = true
	game_ui.pause_timer(true)
	if stage.hurry_up:
		stage.hurry_up.pause_hurry_up(true)

func unpause_time():
	%MatchTimer.paused = false
	game_ui.pause_timer(false)
	if stage.hurry_up:
		stage.hurry_up.pause_hurry_up(false)

## loaded the level_graph given as a path 
## [param path] String the path to the choosen level_graph
func load_level_graph(_path: String):
	pass

## checks whenever the current stage has ended
## [param alive_enemies] The number of alive NPC enemies
func _check_ending_condition(_alive_enemies: int):
	pass
	
func reset_players():
	var misoplayers: Array[MisobonPlayer] = Array($MisobonPath.get_children().filter(func (p): return (p is MisobonPlayer)), TYPE_OBJECT, "PathFollow2D", MisobonPlayer)
	var deadplayers: Array[Player] = globals.player_manager.get_dead_players()
	if is_multiplayer_authority():
		for misoplayer in misoplayers:
			misoplayer.reset(stage.spawnpoints[0])
		for deadplayer in deadplayers:
			deadplayer.reset()
			deadplayer.reset_pickups()
