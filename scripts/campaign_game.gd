extends Game

const LEVEL_GRAPH_PATH: String = "res://resources/level_graph/saved_graphs"
const MATCH_TIME: int = 180

@onready var stage_announce_label: Label = get_node("StageAnnouncement")

var stage_handler: StageHandler

var score: int = 0:
	set(val):
		score = min(val, 999999)
		self.game_ui.update_score(score)

var stage_data_arr: Array[StageNodeData]
var curr_stage_idx: int = 0
var _stage_lookahead: int = 3
var _exit_entered_barrier: bool = false
var _exit_spawned_barrier: bool = false

func _init():
	globals.game = self
	
@rpc("call_local")
func restart_current_stage():
	fade.play("fade_out")
	await fade.animation_finished

	reset()
	stage.reset()

	await get_tree().create_timer(1).timeout

	stage.enable.call_deferred(
		stage_data_arr[curr_stage_idx].exit_resource,
		stage_data_arr[curr_stage_idx].enemy_resource,
		stage_data_arr[curr_stage_idx].pickup_resource,
		stage_data_arr[curr_stage_idx].spawnpoint_resource,
		stage_data_arr[curr_stage_idx].unbreakable_resource,
		stage_data_arr[curr_stage_idx].breakable_resource,
	)
	stage_announce_label.text = stage_data_arr[curr_stage_idx].stage_node_title
	stage_announce_label.show()

	activate_ui_and_music()
	fade.play("fade_in")
	await fade.animation_finished
	get_tree().create_timer(0.5).timeout.connect(func (): stage_announce_label.hide())
	stage_has_changed.emit()

@rpc("call_local")
## starts the complete reset for all stage related states and then loads the next stage given by
## [param id] int -1 if the game should terminate with a player win else the index of the next stage in the stage_data_arr
func next_stage(id: int, player: HumanPlayer):
	if _exit_entered_barrier: return
	_exit_entered_barrier = true
	# prevents two exits from triggering (Tho in general we proabily should not have 2 exits close enought next to each other to trigger that)

	await player.play_victory(true)

	if id == -1:
		#TODO: proper won game screen
		win_screen.won_game()
		reset()
		stage.reset() #deletes exits and stops hurry up
		return
	gamestate.current_level += 1
	
	fade.play("fade_out")
	await fade.animation_finished

	# disable the old stage
	reset()
	stage.reset()
	stage.disable()

	# Set and enable the next stage
	stage_handler.set_stage(stage_data_arr[id].get_stage_path())
	stage = stage_handler.get_stage()

	await get_tree().create_timer(1).timeout

	stage.enable.call_deferred(
		stage_data_arr[id].exit_resource,
		stage_data_arr[id].enemy_resource,
		stage_data_arr[id].pickup_resource,
		stage_data_arr[id].spawnpoint_resource,
		stage_data_arr[id].unbreakable_resource,
		stage_data_arr[id].breakable_resource,
	)
	stage_announce_label.text = stage_data_arr[id].stage_node_title
	stage_announce_label.show()
	activate_ui_and_music()
	fade.play("fade_in")
	await fade.animation_finished
	get_tree().create_timer(0.5).timeout.connect(func (): stage_announce_label.hide())

	curr_stage_idx = id
	_exit_entered_barrier = false
	_exit_spawned_barrier = false
	stage_has_changed.emit()
	load_next_stage_set(id)

## for a given stage loads the next stages into the tree with a lookahead in a BDS approach
## [param id] int index of the choosen stage in the stage_data_arr
func load_next_stage_set(id: int):
	# delete stages we will never use again
	var unreachable_stages: Dictionary = GraphHelper.bfs_are_unreachable(
		stage_data_arr,
		func (s: StageNodeData): return s.get_stage_path(),
		func (s: StageNodeData): return s.children,
		id,
		stage_handler.loaded_stage_path_map,
	)
	stage_handler.free_stages(unreachable_stages)

	# Load the next stages
	var next_stage_set: Dictionary = GraphHelper.bfs_get_values(
		stage_data_arr, 
		func (s: StageNodeData): return s.get_stage_path(),
		func (s: StageNodeData): return s.children,
		id,
		_stage_lookahead,
	)
	stage_handler.load_stages(next_stage_set)

func start():
	assert(stage_data_arr != [], "stage_data not loaded")
	
	stage_announce_label.text = stage_data_arr[0].stage_node_title
	stage_announce_label.show()
	fade.get_node("FadeInOutRect").show()
	await get_tree().create_timer(0.1).timeout
	fade.play("fade_in")

	var init_stage_set: Dictionary = GraphHelper.bfs_get_values(
		stage_data_arr, 
		func (s: StageNodeData): return s.get_stage_path(),
		func (s: StageNodeData): return s.children,
		0,
		_stage_lookahead,
	)
	# using the bfs fold function find the maximal number of every enemy type used per stage
	var max_enemy_dict: Dictionary = GraphHelper.bfs_fold(
		stage_data_arr,
		{},
		func (curr_dict: Dictionary, s: StageNodeData):
			var enemy_dict: Dictionary = s.enemy_resource.get_enemy_dictionary()
			for enemy_path in enemy_dict:
				if !curr_dict.has(enemy_path): curr_dict[enemy_path] = len(enemy_dict[enemy_path])
				else: curr_dict[enemy_path] = max(curr_dict[enemy_path], len(enemy_dict[enemy_path]))
			return curr_dict,
		func (s: StageNodeData): return s.children,
		0,
	)

	enemy_pool.initialize(max_enemy_dict)
	stage_handler.load_stages(init_stage_set)
	stage_handler.set_stage(stage_data_arr[0].selected_scene_path + "/" + stage_data_arr[0].selected_scene_file)
	stage = stage_handler.get_stage()

	activate_ui_and_music()
	globals.game.game_ui.start_timer()
	%MatchTimer.start()

	stage.enable.call_deferred(
		stage_data_arr[0].exit_resource,
		stage_data_arr[0].enemy_resource,
		stage_data_arr[0].pickup_resource,
		stage_data_arr[0].spawnpoint_resource,
		stage_data_arr[0].unbreakable_resource,
		stage_data_arr[0].breakable_resource,
	)
	await fade.animation_finished
	stage_has_changed.emit.call_deferred()
	get_tree().create_timer(0.5).timeout.connect(func (): stage_announce_label.hide())


func activate_ui_and_music():
	stage.start_music()

	# clean up the connections in Matchtimer
	for sig_arr in %MatchTimer.timeout.get_connections():
		sig_arr.signal.disconnect(sig_arr.callable)

	%MatchTimer.start(MATCH_TIME)
	# kill players when time is up
	%MatchTimer.timeout.connect(
		func ():
			for player in player_manager.get_players():
				player.exploded(gamestate.ENVIRONMENTAL_KILL_PLAYER_ID),
		CONNECT_ONE_SHOT
		)

	game_ui.start_timer(MATCH_TIME)

func load_level_graph(file_name: String):
	var campaign_data: Dictionary = LevelGraph.load_json_file(file_name)
	stage_data_arr = LevelGraph.load_graph_to_stage_node_data_arr(campaign_data)

func _check_ending_condition(alive_enemies: int):
	if win_screen.visible: return
	var alive_players: Array[Player] = globals.player_manager.get_alive_players()
	print(len(alive_players), ", ", alive_enemies)
	if len(alive_players) == 0 && alive_enemies == -1:
		#TODO: proper lost game screen (with restart option)
		win_screen.lost_game()
	if len(alive_players) > 0 && alive_enemies == 0:
		stage.spawn_exits()
