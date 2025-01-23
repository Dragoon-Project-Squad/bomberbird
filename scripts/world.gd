extends Node2D

var music_dir_path : String = "res://sound/mus/"
@onready var mus_player := $MusicPlayer
@onready var background_layer = $Background
@onready var unbreakable_layer = $Unbreakable
@onready var breakable_spawner = $BreakableSpawner

# Randomizer & Dimension values ( make sure width & height is uneven)
const initial_width = 15
const initial_height = 13
var map_width = initial_width
var map_height = initial_height
var map_offset = 0 #Shifts map four rows down for UI, only used if map is randomly created
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	dir_contents(music_dir_path)
	mus_player.play()
	generate_breakables()
	
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
	
func find_empty_cells (mapwidth = map_width, mapheight = map_height, mapoffset = map_offset, background_tiles = background_layer, unbreakable_tiles = unbreakable_layer):
	# Array of empty tiles
	var empty_cells = []
	# Append empty tiles to array
	for x in range(1, mapwidth - 1):
		for y in range(1, mapheight - 1):
			var current_cell = Vector2i(x, y + mapoffset)
			# Checks if cells are empty but only on breakable & unbreakable layers
			if is_cell_empty(background_tiles, current_cell) and is_cell_empty(unbreakable_tiles, current_cell):
				empty_cells.append(current_cell)
	return empty_cells

func generate_breakables():
	# Define an array for the spawn zones in the corners
	var spawn_zones = [
		# Top Left
		[Vector2i(1, 1 + map_offset), 
		Vector2i(1, 2 + map_offset),
		Vector2i(1, 3 + map_offset)],
		# Top Right
		[Vector2i(map_width - 2, 1 + map_offset), 
		Vector2i(map_width - 2, 2 + map_offset),
		Vector2i(map_width - 2, 3 + map_offset)],
		# Bottom Left
		[Vector2i(1, map_height - 2 + map_offset), 
		Vector2i(1, map_height - 3 + map_offset),
		Vector2i(1, map_height - 4 + map_offset)],
		# Bottom Right
		[Vector2i(map_width - 2, map_height - 2 + map_offset), 
		Vector2i(map_width - 2, map_height - 3 + map_offset),
		Vector2i(map_width - 2, map_height - 4 + map_offset)]
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
			if skip_current_cell:
				continue
			if is_cell_empty(unbreakable_layer, current_cell):
				if rng.randf() < breakable_spawn_chance:
					#place_breakable(current_cell.x, current_cell.y)
					var tilespawncoords = Vector2(current_cell.x,current_cell.y)
					var mapspawncoords = unbreakable_layer.map_to_local(tilespawncoords)
					breakable_spawner.spawn(mapspawncoords)

func is_cell_empty(layer: TileMapLayer, coords):
	var data = layer.get_cell_tile_data(coords)
	return data == null
