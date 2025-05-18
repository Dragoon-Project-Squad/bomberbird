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
var _rng = RandomNumberGenerator.new()
var _exit_spawned_barrier: bool = false
var alive_enemies: int

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
		globals.game.exit_pool.request(exit_entry.color).place(exit_pos, children_ids[iter])
		iter += 1

## Disabled this world so another may be enabled
func disable():
	hide()
	music.stop()

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
	music.play()
	globals.current_world = self
	all_enemied_died.connect(globals.game._check_ending_condition, CONNECT_ONE_SHOT)


	if hurry_up && globals.current_gamemode != globals.gamemode.CAMPAIGN:
		hurry_up.start()

	_exit_spawned_barrier = false
	bounds_layer.collision_enabled = true
	obstacles_layer.collision_enabled = true

	world_data.reset()
	astargrid_handler.reset_astargrid()
	world_data.begin_init(_arena_rect, _world_edge_rect, floor_layer)
	_spawn_unbreakables(unbreakable_table)
	world_data.init_unbreakables(_unbreakable_tile, obstacles_layer)
	astargrid_handler.setup_astargrid()

	if enemy_table:
		self.enemy_table = enemy_table.duplicate()
		for enemy in enemy_table.enemies:
			if _rng.randf_range(0, 1) > enemy.probability: continue
			enemy.coords += world_data.floor_origin

	if exit_table:
		self.exit_table = exit_table.duplicate()
		for exit in self.exit_table.exits:
			exit.coords += world_data.floor_origin

	self.pickup_table = pickup_table.duplicate()
	pickup_table.update()

	if spawnpoints_table:
		spawnpoints.clear()
		for spawnpoint in spawnpoints_table.spawnpoints:
			if _rng.randf_range(0, 1) > spawnpoint.probability: continue
			spawnpoints.append(spawnpoint.coords + world_data.floor_origin)

	_set_spawnpoints()
	if is_multiplayer_authority():
		if !globals.game.players_are_spawned: _spawn_player()
		else: _place_players.rpc()
		if enemy_table:
			_spawn_enemies.rpc()
	_generate_breakables(breakable_table)

	world_data.finish_init()
	astargrid_handler.astargrid_set_initial_solidpoints()


## resets a stage s.t. it may be reused later
func reset():
	if hurry_up: hurry_up.disable()
	for exit in globals.game.exit_pool.get_children().filter(func (e): return e is Exit && e.in_use):
		if is_multiplayer_authority():
			exit.disable.rpc()
		globals.game.exit_pool.return_obj(exit)

## spawns unbreakables from given table
## NOTE: Some children may completly ignore the table given if unbreakable are generated in a different way
func _spawn_unbreakables(_unbreakable_table: UnbreakableTable):
	pass
	
## used to spawn the enemies given in enemy_table
@rpc("call_local")
func _spawn_enemies():
	if(!is_multiplayer_authority()): return 1
	assert(enemy_table, "enemy table is null but trying to spawn enemies")
	var enemy_dict: Dictionary = {}
	# count enemies
	enemy_table.enemies.map(
		func (e: Dictionary):
			var whole_path: String = e.path + "/" + e.file
			if !enemy_dict.has(whole_path): enemy_dict[whole_path] = 1
			else: enemy_dict[whole_path] += 1
			)
	# place enemies
	var enemys: Dictionary = globals.game.enemy_pool.request_group(enemy_dict);
	alive_enemies = len(enemy_table.enemies)
	enemy_table.enemies.map(
		func (e: Dictionary):
			var whole_path: String = e.path + "/" + e.file
			var enemy: Enemy = enemys[whole_path].pop_front()
			enemy.place.rpc(world_data.tile_map.map_to_local(e.coords), whole_path)
			globals.game.stage_has_changed.connect(enemy.enable, CONNECT_ONE_SHOT)
			enemy.enemy_died.connect(
				func () -> void:
					alive_enemies -= 1
					if alive_enemies == 0:
						all_enemied_died.emit(0),
				CONNECT_ONE_SHOT
				)
			)

## Asserts that properties of the world are set correctly
func _asserting_world():
	assert(_arena_rect.size != Vector2i.ZERO, "area_rect must be set properly and cannot have size ZERO")

## Generates all the breakables from the handed table
## NOTE: Some children may completly ignore the table given if breakable are generated in a different way
func _generate_breakables(_breakable_table: BreakableTable):
	pass

## Spawns a breakable at
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
	globals.game.breakable_pool.request().place.rpc(spawn_coords, pickup)

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
		if enemy_table && (new_spawnpoint in enemy_table.get_coords()): continue
		spawnpoints.append(new_spawnpoint)
		remaining_spawnpoints -= 1

@rpc("call_local")
## places players (assumes players already exist)
func _place_players():
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	var spawn_point_idx = 0
	spawn_points[1] = spawn_point_idx # Server in spawn point 0.

	for p in gamestate.players:
		spawn_point_idx += 1
		spawn_points[p] = spawn_point_idx

	for p_id in spawn_points:
		globals.player_manager.get_node(str(p_id)).position = world_data.tile_map.map_to_local(spawnpoints[spawn_points[p_id]])	

## spawns players (assums players do not yet exist)
func _spawn_player():
	globals.game.players_are_spawned = true
	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing.
	var spawn_points = {}
	var spawn_point_idx = 0
	spawn_points[1] = spawn_point_idx # Server in spawn point 0.

	for p in gamestate.players:
		spawn_point_idx += 1
		spawn_points[p] = spawn_point_idx

	var humans_loaded_in_game = 0

	for p_id in spawn_points:
		var spawn_pos: Vector2 = world_data.tile_map.map_to_local(spawnpoints[spawn_points[p_id]])
		var playerspawner: MultiplayerSpawner = globals.game.player_spawner
		var misobonspawner: MultiplayerSpawner = globals.game.misobon_player_spawner
		var spawningdata = {"spawndata": spawn_pos, "pid": p_id, "defaultname": gamestate.player_name, "playerdictionary": gamestate.players, "characterdictionary": gamestate.characters}
		var misobondata = {"spawn_here": 0.0, "pid": p_id}
		var player: Player 

		if humans_loaded_in_game < gamestate.human_player_count:
			spawningdata.playertype = "human"
			misobondata.player_type = "human"
			humans_loaded_in_game += 1
		else:
			spawningdata.playertype = "ai"
			misobondata.player_type = "ai"

		player = playerspawner.spawn(spawningdata)
		if SettingsContainer.misobon_setting != SettingsContainer.misobon_setting_states.OFF:
			misobondata.name = player.get_player_name()
			misobonspawner.spawn(misobondata)
