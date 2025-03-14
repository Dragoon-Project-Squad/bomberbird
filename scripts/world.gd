extends Node2D
class_name World

var music_dir_path : String = "res://sound/mus/"

@onready var mus_player := $MusicPlayer
@onready var floor_layer = $Floor
@onready var unbreakable_layer = $Unbreakable
@onready var breakable_spawner = get_node("Breakables/BreakableSpawner")
@onready var breakables = $Breakables
@onready var bomb_pool = $BombPool
@onready var pickup_pool = $PickupPool
@onready var game_ui= $GameUI

# Randomizer & Dimension values ( make sure width & height is uneven)
const initial_width = 15
const initial_height = 13
var map_width = initial_width
var map_height = initial_height
var map_offset = 2 #Shifts map four rows down for UI, only used if map is randomly created
var rng = RandomNumberGenerator.new()

# AI pathing
var astargrid = AStarGrid2D.new()
var astargrid_no_breakables = AStarGrid2D.new()

# we use the init to pass ourselfs to globals as this will be called on instanciation while ready is only called after all children are also ready (which may lead to some of the children trying to access world already in there ready functions)
func _init():
	globals.current_world = self

func _ready() -> void:
	setup_astargrid()
	dir_contents(music_dir_path)
	mus_player.play()

	world_data.begin_init(Vector2i(1, 3), map_width - 2, map_height - 2, floor_layer)	
	generate_breakables()
	world_data.finish_init()		
	astargrid_set_initial_solidpoints()
	
func dir_contents(path):
	var dir = DirAccess.open(path)
	var index = 0
	var file_name
	if dir:
		dir.list_dir_begin()
		file_name = dir.get_next()
		while file_name != "":
			if file_name.get_extension() == "import":
				# This is the WACKEST hack I have done in a while
				file_name = file_name.split(".import")
				loadstream(index, load(path+file_name[0]))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the music path.")

func loadstream(index: int,  this_stream: AudioStreamOggVorbis):
	if this_stream == null:
		return
	if mus_player.playing:
		mus_player.stop()
	mus_player.stream.add_stream(index, this_stream)
	this_stream.loop = true
	index = index + 1
	
func unique_cell_identifier(coord):
	return coord.x + coord.y * 10000
	
func get_arena_bounds() -> Array[Vector2]:
	var tile_size = unbreakable_layer.tile_set.tile_size.x
	return [
		to_global(unbreakable_layer.map_to_local(Vector2i(1, 1 + map_offset)) - Vector2(tile_size / 2, tile_size / 2)),
		to_global(unbreakable_layer.map_to_local(Vector2i(map_width - 2, map_height - 2 + map_offset)) + Vector2(tile_size / 2, tile_size / 2)),
	]

func get_world_bounds() -> Array[Vector2]:
	var tile_size = unbreakable_layer.tile_set.tile_size.x
	return [
		to_global(unbreakable_layer.map_to_local(Vector2i(-2, -4 + map_offset)) + Vector2(tile_size / 2, tile_size / 2)),
		to_global(unbreakable_layer.map_to_local(Vector2i(map_width + 1, map_height + 1 + map_offset))),
	]	

func get_world_size() -> Vector2:
	var tile_size = unbreakable_layer.tile_set.tile_size.x
	return Vector2((map_width + 2) * tile_size, (map_height + 4) * tile_size)

func find_empty_cells (mapwidth = map_width, mapheight = map_height, mapoffset = map_offset, floor_tiles = floor_layer, unbreakable_tiles = unbreakable_layer):
	# Array of empty tiles
	var empty_cells = []
	# Append empty tiles to array
	for x in range(1, mapwidth - 1):
		for y in range(1, mapheight - 1):
			var current_cell = Vector2i(x, y + mapoffset)
			# Checks if cells are empty but only on breakable & unbreakable layers
			if is_cell_empty(floor_tiles, current_cell) and is_cell_empty(unbreakable_tiles, current_cell):
				empty_cells.append(current_cell)
	return empty_cells

func generate_breakables():
	if not is_multiplayer_authority():
		# Do not generate.
		return
	# Define an array for the spawn zones in the corners
	var spawn_zones = [
		# Top Left
		[Vector2i(1, 1 + map_offset), 
		Vector2i(1, 2 + map_offset),
		Vector2i(2, 1 + map_offset)],
		# Top eight
		[Vector2i(map_width - 2, 1 + map_offset), 
		Vector2i(map_width - 2, 2 + map_offset),
		Vector2i(map_width - 3, 1 + map_offset)],
		# Bottom Left
		[Vector2i(1, map_height - 2 + map_offset), 
		Vector2i(1, map_height - 3 + map_offset),
		Vector2i(2, map_height - 2 + map_offset)],
		# Bottom Right
		[Vector2i(map_width - 2, map_height - 2 + map_offset), 
		Vector2i(map_width - 2, map_height - 3 + map_offset),
		Vector2i(map_width - 3, map_height - 2 + map_offset)]
	]
	
	# Randomly place breakable walls on Layer 1
	rng.randomize()
	for x in range(1, map_width - 1):
		for y in range(1, map_height - 1):
			var base_breakable_chance = 0.5 # Default 50% Chance
			var level_chance_multiplier = 0.01 # Increase by 1% per level
			var breakable_spawn_chance = base_breakable_chance + (gamestate.current_level - 1) * level_chance_multiplier
			breakable_spawn_chance = min(breakable_spawn_chance, 0.5) #Max of 90%
			var current_cell = Vector2i(x, y + map_offset)
			var skip_current_cell = false
			#Skip cells where solid tiles are placed
			if x % 2 == 0 and y % 2 == 0:
				skip_current_cell = true
			#Skip cells in the spawn_zones
			for corner in spawn_zones:
				if current_cell in corner:
					skip_current_cell = true
					break
			#Skip cells adjacent to spawn zones
			if skip_current_cell:
				continue
			if is_cell_empty(unbreakable_layer, current_cell):
				if rng.randf() < breakable_spawn_chance:
					#place_breakable(current_cell.x, current_cell.y)
					world_data.init_breakable(current_cell)
					var mapspawncoords = floor_layer.map_to_local(current_cell)
					breakable_spawner.spawn(mapspawncoords)

func is_cell_empty(layer: TileMapLayer, coords):
	var data = layer.get_cell_tile_data(coords)
	return data == null

func setup_astargrid():
	astargrid.region = floor_layer.get_used_rect()
	astargrid.cell_size = Vector2i(16, 16)
	astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astargrid.update()
	astargrid_no_breakables.region = floor_layer.get_used_rect()
	astargrid_no_breakables.cell_size = Vector2i(16, 16)
	astargrid_no_breakables.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astargrid_no_breakables.update()

func astargrid_set_initial_solidpoints() -> void:
	# Set unbreakables as solidpoints
	var floor_rect = floor_layer.get_used_rect()
	var floor_end = floor_rect.end
	var offset = floor_rect.position
	var cell
	for pointx in range (offset.x+1, floor_end.x, 2):
		for pointy in range(offset.y+1, floor_end.y, 2):
			cell = Vector2i(pointx, pointy)
			astargrid.set_point_solid(cell, true)
			astargrid_no_breakables.set_point_solid(cell, true)

func astargrid_set_point(position : Vector2, solid : bool) -> void:
	# Set unbreakables as solidpoints
	var cell_position = floor_layer.local_to_map(position)
	astargrid.set_point_solid(cell_position, solid)

func create_path_no_breakables(player: CharacterBody2D, end_position: Vector2i) -> Array[Vector2i]:
	var player_pos = get_node("Players/"+player.name).global_position
	var map_player_pos = floor_layer.local_to_map(player_pos)
	var path = astargrid_no_breakables.get_id_path(map_player_pos, end_position)
	return path

func create_path(player: CharacterBody2D, end_position: Vector2i) -> Array[Vector2i]:
	var player_pos = get_node("Players/"+player.name).global_position
	var map_player_pos = floor_layer.local_to_map(player_pos)
	var path = astargrid.get_id_path(map_player_pos, end_position)
	return path

func is_breakable(cell : Vector2i) -> bool:
	for node in breakables.get_children():
		if node is Breakable:
			if floor_layer.local_to_map(node.global_position) == cell:
				return true
	return false

func is_unbreakable(cell : Vector2i) -> bool:
	if not astargrid.region.has_point(cell):
		return true
	return astargrid.is_point_solid(cell)
