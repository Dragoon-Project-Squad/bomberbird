class_name Game extends Node2D

const LEVEL_GRAPH_PATH: String = "res://resources/level_graph/saved_graphs"
enum game_type {CAMPAIGN, BATTLE_MODE, SIZE}

var stage_handler: StageHandler
var player_manager: PlayerManager
var player_spawner: MultiplayerSpawner
var misobon_path: MisobonPath
var misobon_player_spawner: MultiplayerSpawner
var bomb_pool: BombPool
var pickup_pool: PickupPool
var breakable_pool: BreakablePool
var game_ui: CanvasLayer
var win_screen: Control
var stage: World

var stage_data_arr: Array[StageNodeData]
var players_are_spawned: bool = false
var current_game_type: int

func _init():
	globals.game = self

func start():
	assert(stage_data_arr != [], "stage_data not loaded")
	var init_stage_set: Dictionary = GraphHelper.bfs_get_values(
		stage_data_arr, 
		func (s: StageNodeData): 
			return s.selected_scene_path + "/" + s.selected_scene_file,
		func (s: StageNodeData): return s.children,
		0,
		3,
	)
	stage_handler.init_load_stages(
		stage_data_arr[0].selected_scene_path + "/" + stage_data_arr[0].selected_scene_file,
		init_stage_set
	)

	stage = stage_handler.get_stage()
	stage.enable(
		stage_data_arr[0].exit_resource,
		stage_data_arr[0].enemy_resource,
		stage_data_arr[0].pickup_resource,
		stage_data_arr[0].spawn_point_arr,
	)

func load_level_graph(file_name: String):
	if ResourceLoader.exists(LEVEL_GRAPH_PATH + "/" + file_name):
		stage_data_arr = ResourceLoader.load(LEVEL_GRAPH_PATH + "/" + file_name).nodes
	else:
		print("No savedata loaded")

func _check_ending_condition(alive_enemies: int):
	if win_screen.visible: return
	var alive_players: Array[Player] = globals.player_manager.get_alive_players()
	assert(0 <= current_game_type && current_game_type < game_type.SIZE)
	match current_game_type:
		game_type.CAMPAIGN: _check_campaign_ending_condition(alive_players, alive_enemies)
		game_type.BATTLE_MODE: _check_battlemode_ending_condition(alive_players)
		
func _check_campaign_ending_condition(_alive_players: Array[Player], _alive_enemies: int):
	assert(false, "NOT YET IMPLEMENTED")
	pass

func _check_battlemode_ending_condition(alive_players: Array[Player]):
	print(alive_players)
	if len(alive_players) == 0:
		win_screen.draw_game()
	if len(alive_players) == 1:
		win_screen.declare_winner(alive_players[0])
	return
