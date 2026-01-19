extends Node2D
class_name World
## World contains the base functionallity of every stage
## World expects the following structure (child nodes) to work properly:
## - Floor: TileMapLayer (Layer just consists of floor tiles)
## - Bounds: TileMapLayer (Layer with just tiles blocking the player from exiting the main area)
## - Obstacles: TileMapLayer (Layer with Unbreakables and potentially Breakables)
## - Breakables: Node2D (Node that will contain all breakables generated)
## - Players: PlayerManager (Node that will contain all players)
## - MisobonPath: MisobonPath (Node that will contain all misobon players)
## - BombPool: BombPool (Node that spawns and contains all bombs used during the game
## - PickupPool: PickupPool (Node that spawns and contains all pickups used during the game
## - Camera2D: Camera2D (Main camera used during the game)
## - Timers: Node (Node that will contain all Timers)
## - Music: Node (responsable for playing the music in this stage)
## - BreakableSpawner
## - PlayerSpawner
## - MisobonPlayerSpawner

signal all_enemied_died

const EXIT_VISITED_COLOR: Color = Color8(187, 32, 144)

@export_group("World Settings")
## The Rectangle that covers the playable area where (x,y) are the top left corner and (w, h) the size of the rectangle all in tile coordinates
@export var _arena_rect: Rect2i
## The Rectangle that determans the world_edge hence outside of which items are wrapped around to the other side
@export var _world_edge_rect: Rect2i
## list of spawnpoints (if there are less players then spawnpoints they will be used in order)
## if there is more players then spawnpoints, more spawnpoints will be added randomly
@export var spawnpoints: Array[Vector2i]
@export var exit_table: ExitTable
@export var enemy_table: EnemyTable
@export var pickup_table: PickupTable

@onready var floor_layer: TileMapLayer = $Floor
@onready var bounds_layer: TileMapLayer = $Bounds
@onready var obstacles_layer: TileMapLayer = $Obstacles
@onready var hurry_up: TileMapLayer = $HurryUp

@onready var music = $Music

## The Atlas coordinate of the unbreakable tile in this stages tileset
var _unbreakable_tile: Vector2i
var _tileset_id: int
var _rng = RandomNumberGenerator.new()
var _exit_spawned_barrier: bool = false
var _breakable_texture_path: String
var alive_enemies: Array
var total_number_of_non_unbreakable_spaces: int = 0

# PRIVATE FUNCTIONS

func _ready() -> void:
	_asserting_world()
	disable()

## Spawn designated exits in exit_table
func spawn_exits():
	assert(exit_table, "exit table is null but trying to spawn exits")
	if _exit_spawned_barrier: return
	_exit_spawned_barrier = true
	var iter: int = 0 
	var children_ids: Array[int] = globals.game.stage_data_arr[globals.game.curr_stage_idx].children

	for exit_entry in exit_table.exits:
		var exit_pos: Vector2 = world_data.tile_map.map_to_local(exit_entry.coords)
		assert(world_data.is_out_of_bounds(exit_pos) == world_data.bounds.IN,
			"exit at position " + str(exit_entry.coords) + " is out of bounds for current stage")
		assert(!world_data.is_tile(world_data.tiles.UNBREAKABLE, exit_pos),
			"exit at position " + str(exit_entry.coords) + " is ontop of an unbreakable")

		var exit: Exit
		if gamestate.current_save.visited_exits.has(globals.game.curr_stage_idx) && gamestate.current_save.visited_exits[globals.game.curr_stage_idx].has(children_ids[iter]):
			exit = globals.game.exit_pool.request(EXIT_VISITED_COLOR)
		else:
			exit = globals.game.exit_pool.request(exit_entry.color)
		exit.place.call_deferred(exit_pos, children_ids[iter]) 
		iter += 1

func stop_hurry_up():
	if hurry_up and not globals.is_singleplayer():
		hurry_up.disable()

## Disabled this world so another may be enabled
func disable():
	hide()

	bounds_layer.collision_enabled = false
	obstacles_layer.collision_enabled = false


@warning_ignore("SHADOWED_VARIABLE")
## enables the stage s.t. it may be used
## [param exit_table] overwrite the exit_table preset defaults to null
## [param enemy_table] overwrite the enemy_table preset defaults to null
## [param pickup_table] overwrite the pickup_table preset defaults to just the preset
## [param spawnpoints_table] overwrite the spawnpoints preset appling the probability inside the table defaults to just the preset
func enable(
	exit_table: ExitTable = null,
	enemy_table: EnemyTable = null,
	pickup_table: PickupTable = self.pickup_table,
	spawnpoints_table: SpawnpointTable = null,
	unbreakable_table: UnbreakableTable = null,
	breakable_table: BreakableTable = null,
):
	show()
	globals.current_world = self
	all_enemied_died.connect(globals.game._check_ending_condition, CONNECT_ONE_SHOT)


	_exit_spawned_barrier = false
	bounds_layer.collision_enabled = true
	obstacles_layer.collision_enabled = true

	world_data.begin_init(_arena_rect, _world_edge_rect, floor_layer)
	_spawn_unbreakables(unbreakable_table)
	world_data.init_unbreakables(_unbreakable_tile, obstacles_layer)
	astargrid_handler.setup_astargrid()

	if enemy_table:
		self.enemy_table = EnemyTable.new()
		for enemy in enemy_table.enemies:
			if _rng.randf_range(0, 1) > enemy.probability: continue
			var new_enemy_coord = enemy.coords + world_data.floor_origin
			self.enemy_table.append(new_enemy_coord, enemy.name, enemy.probability)

	if exit_table:
		self.exit_table = ExitTable.new()
		for exit in exit_table.exits:
			var new_exit_coords = exit.coords + world_data.floor_origin
			self.exit_table.append(new_exit_coords, exit.color)

	self.pickup_table = pickup_table.duplicate()
	pickup_table.update()

	if spawnpoints_table:
		spawnpoints.clear()
		for spawnpoint in spawnpoints_table.spawnpoints:
			if _rng.randf_range(0, 1) > spawnpoint.probability: continue
			spawnpoints.append(spawnpoint.coords + world_data.floor_origin)
			
	if is_multiplayer_authority() && globals.is_multiplayer():
		randomize_spawnpoints()
		send_spawn_data.rpc(spawnpoints)

	_set_spawnpoints()

	if is_multiplayer_authority():
		if !globals.game.players_are_spawned: _spawn_player()
		else: _place_players.rpc()
		if enemy_table:
			_spawn_enemies.rpc()

	if pickup_table.are_amounts:
		_generate_breakables_with_amounts(breakable_table, pickup_table)
	else:
		_generate_breakables_with_weights(breakable_table)

	if hurry_up && globals.is_multiplayer():
		if is_multiplayer_authority():
			hurry_up.start.rpc()

	world_data.finish_init()
	astargrid_handler.astargrid_set_initial_solidpoints()

func start_music():
	music.play()
	
func stop_music():
	music.stop()
	
## resets a stage s.t. it may be reused later
func reset():
	self.total_number_of_non_unbreakable_spaces = 0
	if globals.game.exit_pool:
		for exit in globals.game.exit_pool.get_children().filter(func (e): return e is Exit && e.in_use):
			if is_multiplayer_authority():
				exit.disable.rpc()
				globals.game.exit_pool.return_obj(exit)
	if globals.game.enemy_pool:
		for enemy in alive_enemies:
			if is_multiplayer_authority():
				enemy.disable()
				globals.game.clock_pickup_time_paused.disconnect(enemy.stop_time)
				globals.game.clock_pickup_time_unpaused.disconnect(enemy.start_time)
				globals.game.enemy_pool.return_obj(enemy)
			
		alive_enemies = []
	for sig_arr in all_enemied_died.get_connections():
		sig_arr.signal.disconnect(sig_arr.callable)
	
	world_data.reset()
	astargrid_handler.reset_astargrid()

## spawns unbreakables from given table
## NOTE: Some children may completly ignore the table given if unbreakable are generated in a different way
func _spawn_unbreakables(_unbreakable_table: UnbreakableTable):
	pass
	
## used to spawn the enemies given in enemy_table
@rpc("call_local")
func _spawn_enemies():
	if(!is_multiplayer_authority()): return 1
	assert(self.enemy_table, "enemy table is null but trying to spawn enemies")
	var enemy_dict: Dictionary = {}
	# count enemies
	self.enemy_table.enemies.map(
		func (e: Dictionary):
			var whole_path: String = StageDataUI.ENEMY_SCENE_DIR + StageDataUI.ENEMY_DIR[e.name]
			if !enemy_dict.has(whole_path): enemy_dict[whole_path] = 1
			else: enemy_dict[whole_path] += 1
			return e
			)
	# place enemies
	var enemys: Dictionary = globals.game.enemy_pool.request_group(enemy_dict);
	self.enemy_table.enemies.map(
		func (e: Dictionary):
			var whole_path: String = StageDataUI.ENEMY_SCENE_DIR + StageDataUI.ENEMY_DIR[e.name]
			var enemy: Enemy = enemys[whole_path].pop_front()
			enemy.place.rpc(world_data.tile_map.map_to_local(e.coords), whole_path)
			globals.game.stage_has_changed.connect(enemy.enable, CONNECT_ONE_SHOT)
			globals.game.clock_pickup_time_paused.connect(enemy.stop_time)
			globals.game.clock_pickup_time_unpaused.connect(enemy.start_time)
			alive_enemies.append(enemy)
			enemy.enemy_died.connect(
				func () -> void:
					alive_enemies.erase(enemy)
					globals.game.score += enemy.score_points
					globals.game.clock_pickup_time_paused.disconnect(enemy.stop_time)
					globals.game.clock_pickup_time_unpaused.disconnect(enemy.start_time)
					if alive_enemies.is_empty():
						all_enemied_died.emit(0),
				CONNECT_ONE_SHOT
				)
			
			return e
			)
	
## Asserts that properties of the world are set correctly
func _asserting_world():
	assert(_arena_rect.size != Vector2i.ZERO, "area_rect must be set properly and cannot have size ZERO")

## Generates all the breakables from the handed table
## NOTE: Some children may completly ignore the table given if breakable are generated in a different way
func _generate_breakables_with_weights(_breakable_table: BreakableTable):
	pass
	
## Generates all the breakables from the handed table
func _generate_breakables_with_amounts(_breakable_table: BreakableTable, pickup_table: PickupTable):
	pass

## Spawns a breakable 
## [param cell] Vector2i
func _spawn_breakable(cell: Vector2i, pickup_type: int):
	assert(globals.is_not_pickup_seperator(pickup_type))
	assert(!world_data.is_tile(world_data.tiles.UNBREAKABLE, world_data.tile_map.map_to_local(cell)), "attempted to spawn a breakable where there already was an unbreakable")
	var pickup: int = pickup_type
	if pickup_type == globals.pickups.RANDOM:
		if !pickup_table.decide_pickup_spawn(): pickup = globals.pickups.NONE
		else: pickup = pickup_table.decide_pickup_type()
	world_data.init_breakable(cell)
	var spawn_coords = world_data.tile_map.map_to_local(cell)
	astargrid_handler.astargrid_set_point.rpc(spawn_coords, true)
	globals.game.breakable_pool.request().place.rpc(spawn_coords, pickup, _breakable_texture_path)

#TODO: This way of randomly choosing spawnpoints is kinda dumb so we have to make a better one
## sets spawnpoints selecting random ones if the are less spawnpoints given then players
func _set_spawnpoints():
	var remaining_spawnpoints: int = gamestate.total_player_count - spawnpoints.size()
	while remaining_spawnpoints > 0:	
		var new_spawnpoint: Vector2i = Vector2i(
			_rng.randi_range(0, world_data.world_width - 1),
			_rng.randi_range(0, world_data.world_height - 1),
		) + world_data.floor_origin
		if world_data.is_tile(world_data.tiles.UNBREAKABLE, world_data.tile_map.map_to_local(new_spawnpoint)):
				continue # Skip cells where solid tiles are placed
		if new_spawnpoint in spawnpoints: continue
		if self.enemy_table && (new_spawnpoint in self.enemy_table.get_coords()): continue
		spawnpoints.append(new_spawnpoint)
		remaining_spawnpoints -= 1
			
func randomize_spawnpoints() -> void:
	spawnpoints.shuffle()

@rpc("call_remote")
func send_spawn_data(host_spawnpoints) -> void:
	spawnpoints = host_spawnpoints

@rpc("call_local")
## places players (assumes players already exist)
func _place_players():
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	var spawn_point_idx = 0

	for p in gamestate.player_data_master_dict:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
		
	for p_id in spawn_points:
		globals.player_manager.get_node(str(p_id)).place(world_data.tile_map.map_to_local(spawnpoints[spawn_points[p_id]]))

## spawns players (assums players do not yet exist)
func _spawn_player():
	globals.game.players_are_spawned = true
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	var spawn_point_idx = 0

	for p in gamestate.player_data_master_dict:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1

	var humans_loaded_in_game = 0
	var spawn_pos := Vector2.ZERO
	var playerspawner: MultiplayerSpawner = globals.game.player_spawner
	var misobonspawner: MultiplayerSpawner = globals.game.misobon_player_spawner
	var spawningdata = {}
	var misobondata = {}
	var player: Player
	var misobon_player = null
	for p_id in spawn_points:
		spawn_pos = world_data.tile_map.map_to_local(spawnpoints[spawn_points[p_id]])
		spawningdata = {"spawndata": spawn_pos, "pid": p_id, "defaultname": gamestate.player_name, "playerdict": gamestate.player_data_master_dict[p_id]}
		misobondata = {"spawn_here": 0.0, "pid": p_id}
		if humans_loaded_in_game < gamestate.human_player_count:
			spawningdata.playertype = "human"
			misobondata.player_type = "human"
			humans_loaded_in_game += 1
		else:
			spawningdata.playertype = "ai"
			misobondata.player_type = "ai"

		player = playerspawner.spawn(spawningdata)
		if globals.is_singleplayer():
			player.player_hurt.connect(globals.game.restart_current_stage)
		if SettingsContainer.misobon_setting != SettingsContainer.misobon_setting_states.OFF:
			misobondata.name = player.get_player_name()
			misobon_player = misobonspawner.spawn(misobondata)
			
	connect_player_to_time_stopped.rpc()

@rpc("call_local")
func connect_player_to_time_stopped():
	for player in globals.player_manager.get_children():
		if !(player is Player): continue
		globals.game.clock_pickup_time_paused.connect(player.stop_time)
		globals.game.clock_pickup_time_unpaused.connect(player.start_time)
	for misobon in globals.game.misobon_path.get_children():
		if !(misobon is MisobonPlayer): continue
		globals.game.clock_pickup_time_paused.connect(misobon.stop_time)
		globals.game.clock_pickup_time_unpaused.connect(misobon.start_time)
