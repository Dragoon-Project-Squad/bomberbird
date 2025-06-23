extends Game

signal score_updated(score: int)

const LEVEL_GRAPH_PATH: String = "res://resources/level_graph/saved_graphs"
const MATCH_TIME: int = 180

@onready var stage_announce_label: Label = get_node("StageAnnouncement")
@onready var pause_menu: CanvasLayer = $PauseMenu

var stage_handler: StageHandler

var score: int = 0:
	set(val):
		score = min(val, 999999)
		score_updated.emit(score)

var stage_data_arr: Array[StageNodeData]
var curr_stage_idx: int = 0
var _stage_lookahead: int = 3
var _exit_entered_barrier: bool = false
var _exit_spawned_barrier: bool = false
var first_start: bool = true

func _init():
	globals.game = self

@rpc("call_local")
func restart():
	stage_done = true
	fade.play("fade_out")
	reset_players()
	gamestate.current_save.current_score = 0
	await fade.animation_finished

	_exit_entered_barrier = false
	reset.call_deferred()
	stage.reset.call_deferred()
	start.call_deferred()
	

@rpc("call_local")
func restart_current_stage():
	stage_done = true
	fade.play("fade_out")
	await fade.animation_finished

	reset.call_deferred()
	stage.reset.call_deferred()

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
	stage_has_changed.emit.call_deferred()
	await fade.animation_finished
	get_tree().create_timer(0.5).timeout.connect(func (): stage_announce_label.hide())
	stage_done = false

@rpc("call_local")
## starts the complete reset for all stage related states and then loads the next stage given by
## [param id] int -1 if the game should terminate with a player win else the index of the next stage in the stage_data_arr
func next_stage(id: int, player: HumanPlayer):
	if _exit_entered_barrier: return
	_exit_entered_barrier = true
	stage_done = true
	# prevents two exits from triggering (Tho in general we proabily should not have 2 exits close enought next to each other to trigger that)

	await player.play_victory(true)

	if id == -1:
		save_on_finish(score, player)
		win_screen.won_game(score)
		reset()
		stage.reset() #deletes exits and stops hurry up

		_exit_entered_barrier = false
		_exit_spawned_barrier = false

		stage_has_changed.emit()
		stage_done = false 
		return

	update_save(id, curr_stage_idx, score, player)

	gamestate.current_level += 1
	
	fade.play("fade_out")
	await fade.animation_finished

	# disable the old stage
	reset()
	stage.reset()
	stage.disable()

	# Set and enable the next stage
	stage_handler.set_stage(stage_data_arr[id].selected_scene)
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
	stage_has_changed.emit.call_deferred()
	await fade.animation_finished
	get_tree().create_timer(0.5).timeout.connect(func (): stage_announce_label.hide())

	curr_stage_idx = id
	_exit_entered_barrier = false
	_exit_spawned_barrier = false
	stage_done = false 
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
	
	stage_done = false
	stage_announce_label.text = stage_data_arr[0].stage_node_title
	stage_announce_label.show()
	fade.get_node("FadeInOutRect").show()
	if gamestate.current_save.fresh_save:
		init_new_save()
	score = gamestate.current_save.current_score
	await get_tree().create_timer(0.1).timeout
	fade.play("fade_in")

	var init_stage_set: Dictionary = GraphHelper.bfs_get_values(
		stage_data_arr, 
		func (s: StageNodeData): return s.get_stage_path(),
		func (s: StageNodeData): return s.children,
		gamestate.current_save.last_stage,
		_stage_lookahead,
	)

	if first_start:
		# using the bfs fold function find the maximal number of every enemy type used per stage
		var max_enemy_dict: Dictionary = GraphHelper.bfs_fold(
			stage_data_arr,
			{},
			func (curr_dict: Dictionary, s: StageNodeData):
				var enemy_dict: Dictionary = s.enemy_resource.get_enemy_dictionary()
				for enemy_name in enemy_dict:
					var enemy_path: String = StageDataUI.ENEMY_SCENE_DIR + StageDataUI.ENEMY_DIR[enemy_name]
					if !curr_dict.has(enemy_path): curr_dict[enemy_path] = len(enemy_dict[enemy_name])
					else: curr_dict[enemy_path] = max(curr_dict[enemy_path], len(enemy_dict[enemy_name]))
				return curr_dict,
			func (s: StageNodeData): return s.children,
			gamestate.current_save.last_stage,
		)

		enemy_pool.initialize(max_enemy_dict)

	stage_handler.load_stages(init_stage_set)
	stage_handler.set_stage(stage_data_arr[gamestate.current_save.last_stage].selected_scene)
	stage = stage_handler.get_stage()

	activate_ui_and_music()

	stage.enable.call_deferred(
		stage_data_arr[gamestate.current_save.last_stage].exit_resource,
		stage_data_arr[gamestate.current_save.last_stage].enemy_resource,
		stage_data_arr[gamestate.current_save.last_stage].pickup_resource,
		stage_data_arr[gamestate.current_save.last_stage].spawnpoint_resource,
		stage_data_arr[gamestate.current_save.last_stage].unbreakable_resource,
		stage_data_arr[gamestate.current_save.last_stage].breakable_resource,
	)
	curr_stage_idx = gamestate.current_save.last_stage
	first_start = false
	stage_has_changed.emit.call_deferred()

	await fade.animation_finished
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

func init_new_save():
	var exit_sum: int = GraphHelper.bfs_fold(
		stage_data_arr,
		0,
		func (curr_sum: int, s: StageNodeData):
			var new_sum = curr_sum + s.children.reduce(func (sum: int, i: int):
				if i == -1: return sum
				else: return sum + 1,
				0,
				)
			return new_sum,
		func (s: StageNodeData): return s.children,
		0,
	)
	gamestate.current_save.exit_count = exit_sum
	gamestate.current_save.last_stage = 0
	gamestate.current_save.current_score = 0
	gamestate.current_save.has_finished = false
	gamestate.current_save.fresh_save = false

func save_on_finish(new_score: int, player: HumanPlayer):
	gamestate.current_save.last_stage = 0
	gamestate.current_save.current_score = new_score
	player.clear_save()

func update_save(next_stage_idx: int, this_stage_idx: int, new_score: int, player: HumanPlayer):
	gamestate.current_save.last_stage = next_stage_idx
	if !gamestate.current_save.visited_exits.has(this_stage_idx):
		gamestate.current_save.visited_exits[this_stage_idx] = {}
	gamestate.current_save.visited_exits[this_stage_idx][next_stage_idx] = null
	gamestate.current_save.current_score = new_score
	player.write_to_save()

func load_level_graph(file_name: String):
	var campaign_data: Dictionary = LevelGraph.load_json_file(file_name)
	stage_data_arr = LevelGraph.load_graph_to_stage_node_data_arr(campaign_data)

func _check_ending_condition(alive_enemies: int):
	if win_screen.visible: return
	var alive_players: Array[Player] = globals.player_manager.get_alive_players()
	if len(alive_players) == 0 && alive_enemies == -1:
		win_screen.lost_game(score)
	if len(alive_players) > 0 && alive_enemies == 0:
		stage.spawn_exits.call_deferred()

func _input(event):
	if event.is_action_pressed("pause"):
		if !get_tree().paused:
			pause_menu.open()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		gamestate.save_sp_game()
		get_tree().quit() # default behavior
