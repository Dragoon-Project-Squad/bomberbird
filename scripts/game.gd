class_name Game extends Node2D
## Represents a currently running game (of some game mode) handles the stage and all objects it contains

signal stage_has_changed

@onready var fade: AnimationPlayer = get_node("FadeInOut")

var player_manager: PlayerManager
var player_spawner: MultiplayerSpawner
var misobon_path: MisobonPath
var misobon_player_spawner: MultiplayerSpawner
var enemy_pool: EnemyPool
var bomb_pool: BombPool
var pickup_pool: PickupPool
var breakable_pool: BreakablePool
var game_ui: CanvasLayer
var win_screen: Control
var stage: World

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
	for player in player_manager.get_alive_players():
		player.reset_pickups()

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

## loaded the level_graph given as a path 
## [param path] String the path to the choosen level_graph
func load_level_graph(_path: String):
	pass

## checks whenever the current stage has ended
## [param alive_enemies] The number of alive NPC enemies
func _check_ending_condition(_alive_enemies: int):
	pass
	
