class_name WorldData extends Node

enum tiles {EMPTY, UNBREAKABLE, BREAKABLE, BOMB, PICKUP}
enum bounds {IN = -1, OUT_TOP = 0, OUT_RIGHT = 1, OUT_DOWN = 2, OUT_LEFT = 3}

#private members
var _world_matrix: Array[int]
var _world_empty_cells: Dictionary
var _is_initialized: bool = false
var _get_rand_lock: Mutex = Mutex.new()
var _get_set_lock: Mutex = Mutex.new()

## public members

## origin of the play area (Top left most tile)
var floor_origin: Vector2i
## width and height of the player area in tiles
var world_width: int
var world_height: int

## origin of the world edge (Top left most tile)
var world_edge_origin: Vector2i
## width and height ofthe world edge in tiles
var world_edge_width: int
var world_edge_height: int

## The TileMapLayer
var tile_map: TileMapLayer

## private functions

func _vec_to_index(vec: Vector2i) -> int:
	assert(0 <= vec.x && vec.x < world_width && 0 <= vec.y && vec.y <= world_height, "index " + str(vec) + " out of bounds for world_data")
	var indx: int = vec.x + vec.y * self.world_width
	assert(indx < self._world_matrix.size(), "index" + str(vec) + " <-> " + str(indx) + " out of bounds for world_data")
	return indx

func _add_tile(tile: int, pos: Vector2i):
	var index = _vec_to_index(pos)
	assert(self._world_matrix[index] != tile, "attempted to place " + _int_to_enum_name(tile)	+ " on a cell already occupied by that cell")
	self._world_matrix[index] = tile

	if !self._is_initialized: return
	if self._world_matrix[index] == tiles.EMPTY: return
	self._world_empty_cells.erase(pos)

func _remove_tile(pos: Vector2i):
	var index = _vec_to_index(pos)
	self._world_matrix[index] = tiles.EMPTY

	if !self._is_initialized: return
	self._world_empty_cells[pos] = true


## Testing and debug functions
func _debug_print_matrix():
	print("World Matrix:")
	for y in range(0, world_height):
		print(_world_matrix.slice(y * world_width, (y + 1) * world_width))
	print("[" + "+++".repeat(world_width) + "]")
	print("Empty cells: ", _world_empty_cells.keys())
	print("[" + "+++".repeat(world_width) + "]")

## Tests whenever empty cells and world matrix are still in sync
func _sync_test() -> bool:
	var res: bool = true
	for x in range(0, world_width):
		for y in range(0, world_height):
			var matrix_pos: Vector2i = Vector2i(x, y)
			if _world_matrix[_vec_to_index(matrix_pos)] != tiles.EMPTY: continue
			res = res && _world_empty_cells[matrix_pos]
	return res

func _int_to_enum_name(tile: int) -> String:
	match tile:
		0: return "EMPTY"
		1: return "UNBREAKABLE"
		2: return "BREAKABLE"
		3: return "BOMB"
		4: return "PICKUP"
		_: return "NOT_A_TILE"

## public functions
@warning_ignore("SHADOWED_VARIABLE")
## begins to initialize the world_data setting its position and size aswell as the time_map
func begin_init(floor_rect2i: Rect2i, world_edge_rect2i: Rect2i, tile_map: TileMapLayer):
	self.floor_origin = floor_rect2i.position
	self.world_width = floor_rect2i.size.x
	self.world_height = floor_rect2i.size.y

	self.world_edge_origin = world_edge_rect2i.position
	self.world_edge_width = world_edge_rect2i.size.x
	self.world_edge_height = world_edge_rect2i.size.y

	self.tile_map = tile_map

	self._world_matrix.resize(world_height * world_width)

## Initialiszes all unbreakable tiles from the tile_map containing them.
func init_unbreakables(unbreakable_atlas_coord: Vector2i, unbreakable_tile_map: TileMapLayer):
	for x in range(0, world_width):
		for y in range(0, world_height):
			var cell: Vector2i = Vector2i(x, y) + floor_origin
			if unbreakable_tile_map.get_cell_atlas_coords(cell) == unbreakable_atlas_coord:
				_add_tile(tiles.UNBREAKABLE, Vector2i(x, y))

## Initialises one breakable
func init_breakable(cell: Vector2i):
	var matrix_pos: Vector2i = cell - floor_origin
	_add_tile(tiles.BREAKABLE, matrix_pos)

## finishes up the initialisation of world_data by setting up the _world_empty_cell array
func finish_init():
	for x in range(0, world_width):
		for y in range(0, world_height):
			var matrix_pos: Vector2i = Vector2i(x, y)
			if _world_matrix[_vec_to_index(matrix_pos)] != tiles.EMPTY: continue
			_world_empty_cells[matrix_pos] = true
	self._is_initialized = true

@rpc("call_local")
## Set a tile at global_po in world_data to 'tile' throwing an error if that tile is already occupied
func set_tile(tile: int, global_pos: Vector2):
	_get_set_lock.lock()
	var matrix_pos: Vector2i = tile_map.local_to_map(global_pos) - floor_origin
	if tile == tiles.EMPTY:
		_remove_tile(matrix_pos)
	else:
		_add_tile(tile, matrix_pos)
	_get_set_lock.unlock()

## checks if the tile at 'global_pos' is 'tile'
func is_tile(tile: int, global_pos: Vector2):
	var matrix_pos: Vector2i = tile_map.local_to_map(global_pos) - floor_origin
	return tile == _world_matrix[_vec_to_index(matrix_pos)]

## returns bounds.IN = -1 iff global_pos is not out of bounds else returns the corresponding enum
func is_out_of_bounds(global_pos: Vector2) -> int:
	var matrix_pos: Vector2i = tile_map.local_to_map(global_pos) - floor_origin
	if matrix_pos.x < 0: return bounds.OUT_LEFT
	elif matrix_pos.x >= world_width: return bounds.OUT_RIGHT
	elif matrix_pos.y < 0: return bounds.OUT_TOP
	elif matrix_pos.y >= world_height: return bounds.OUT_DOWN
	return -1

## returns an array of all tiles of type 'tile'
func get_tiles(tile: int, in_cells: bool = false) -> Array:
	if tile != tiles.UNBREAKABLE && !_is_initialized:
		push_warning("get_tiles in accessing world_data despite it not being completly initialized")
	var tile_arr: Array = []
	for x in range(0, world_width):
		for y in range(0, world_height):
			var matrix_pos: Vector2i = Vector2i(x, y)
			if tile != _world_matrix[_vec_to_index(matrix_pos)]:
				continue
			if in_cells:
				tile_arr.append(matrix_pos + floor_origin)
			else:
				tile_arr.append(tile_map.map_to_local(matrix_pos + floor_origin))
	return tile_arr

## returns a rect2i spanning the arena
func get_arena_rect():
	return Rect2i(floor_origin, Vector2i(world_width, world_height))

## returns true iff global_pos is outside of the world_edge
func is_out_of_world_edge(global_pos: Vector2) -> bool:
	var matrix_pos: Vector2i = tile_map.local_to_map(global_pos) - world_edge_origin
	return !(matrix_pos.x >= 0 && matrix_pos.x < world_edge_width
		&& matrix_pos.y >= 0 && matrix_pos.y < world_edge_height)

## returns a singular randomly choosen empty tile or null if non are awailable
func get_random_empty_tile(in_cells: bool = false) -> Variant:
	_get_rand_lock.lock() #Below this is clearly a critical section (if this ever causes performance issues a more fine grained locking may solve this)

	var temp: Array = _world_empty_cells.keys()
	temp.filter(func(key): return _world_empty_cells[key])

	var res = temp.pick_random()
	if res == null: return null
	res += floor_origin
	if !in_cells:
		res = tile_map.map_to_local(res)

	_get_rand_lock.unlock()
	return res

## gets an Array of size count (or less if less are awailable) of randomly choosen empty cells
func get_random_empty_tiles(count: int, in_cells: bool = false) -> Array:
	_get_rand_lock.lock() #Below this is clearly a critical section (if this ever causes performance issues a more fine grained locking may solve this)

	#There is probably a more efficient way to do this
	var temp: Array = _world_empty_cells.keys()
	temp.filter(func(key): return _world_empty_cells[key])
	temp.shuffle()

	var res: Array = []
	res.resize(count)

	for i in range(0, min(count, temp.size())):
		_world_empty_cells[temp[i]] = false
		temp[i] += floor_origin
		if !in_cells:
			res[i] = tile_map.map_to_local(temp[i])
		else:
			res[i] = temp[i]

	_get_rand_lock.unlock()

	return res

## resets world_data to before initialisation
func reset():
	_is_initialized = false
	_world_matrix.clear()
	_world_empty_cells.clear()
	world_width = 0
	world_height = 0
	floor_origin = Vector2i.ZERO	
	tile_map = null
