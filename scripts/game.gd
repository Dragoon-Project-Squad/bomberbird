extends Node2D

const LEVEL_GRAPH_PATH: String = "res://resources/level_graph/saved_graphs"

@onready var stage_handler: StageHandler = $StageHandler
@onready var player_manager: PlayerManager = $Players
@onready var player_spawner: MultiplayerSpawner = player_manager.get_node("PlayerSpawner")
@onready var misobon_path: MisobonPath = $MisobonPath
@onready var misobon_player_spawner: MultiplayerSpawner = misobon_path.get_node("MisobonPlayerSpawner")
@onready var bomb_pool: BombPool = $BombPool
@onready var pickup_pool: PickupPool = $PickupPool
@onready var breakable_pool: BreakablePool = $BreakablePool
@onready var game_ui: CanvasLayer = $GameUI
@onready var stage: World

var stage_data_arr: Array[StageNodeData]

func _init():
	globals.game = self

func start():
	assert(stage_data_arr != [], "stage_data not loaded")
	var init_stage_set: Dictionary = GraphHelper.bfs_get_values(
		stage_data_arr, 
		func (s: StageNodeData): 
			return [s.selected_scene_path + "/" + s.selected_scene_file],
		func (s: StageNodeData): return s.children,
		0,
		3,
	)

	stage_handler.load_stages(
		stage_data_arr[0].selected_scene_path + "/" + stage_data_arr[0].selected_scene_file,
		init_stage_set
	)

	stage = stage_handler.get_stage()
	stage.make_active_world()

func load_level_graph(file_name: String):
	if ResourceLoader.exists(LEVEL_GRAPH_PATH + "/" + file_name):
		stage_data_arr = ResourceLoader.load(LEVEL_GRAPH_PATH + "/" + file_name).nodes
	else:
		print("No savedata loaded")
