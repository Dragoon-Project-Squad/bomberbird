class_name WorldData extends Node

enum tiles {EMPTY, UNBREAKABLE, BREAKABLE, BOMB, PICKUP}

#private members
var _world_matrix: Array[int]
var _world_empty_cells: Dictionary
var _is_initialized: bool = false
var _get_rand_lock: Mutex = Mutex.new()
var _get_set_lock: Mutex = Mutex.new()

#public members
#origin of the play area (Top left most tile)
var floor_origin: Vector2i
#width and height of the player area in tiles
var world_width: int
var world_height: int
#The TileMapLayer
var tile_map: TileMapLayer

#private functions
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

func _init_unbreakables():
	for x in range(1, world_width, 2):
		for y in range(1, world_height, 2):
			_add_tile(tiles.UNBREAKABLE, Vector2i(x, y))

# testing and debug functions
func _debug_print_matrix():
	print("World Matrix:")
	for y in range(0, world_height):
		print(_world_matrix.slice(y * world_width, (y + 1) * world_width))
	print("[" + "+++".repeat(world_width) + "]")
	print("Empty cells: ", _world_empty_cells.keys())
	print("[" + "+++".repeat(world_width) + "]")

# tests whenever empty cells and world matrix are still in sync
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

#public functions
@warning_ignore("SHADOWED_VARIABLE")
func begin_init(floor_origin: Vector2, world_width: int, world_height: int, tile_map: TileMapLayer):
	self.floor_origin = floor_origin
	self.world_width = world_width
	self.world_height = world_height
	self.tile_map = tile_map

	self._world_matrix.resize(world_height * world_width)
	
	_init_unbreakables()

func init_breakable(cell: Vector2i):
	var matrix_pos: Vector2i = cell - floor_origin
	_add_tile(tiles.BREAKABLE, matrix_pos)

func finish_init():
	for x in range(0, world_width):
		for y in range(0, world_height):
			var matrix_pos: Vector2i = Vector2i(x, y)
			if _world_matrix[_vec_to_index(matrix_pos)] != tiles.EMPTY: continue
			_world_empty_cells[matrix_pos] = true
	self._is_initialized = true

@rpc("call_local")
func set_tile(tile: int, global_pos: Vector2):
	_get_set_lock.lock()
	var matrix_pos: Vector2i = tile_map.local_to_map(global_pos) - floor_origin
	if tile == tiles.EMPTY:
		_remove_tile(matrix_pos)
	else:
		_add_tile(tile, matrix_pos)
	_get_set_lock.unlock()

func is_tile(tile: int, global_pos: Vector2):
	var matrix_pos: Vector2i = tile_map.local_to_map(global_pos) - floor_origin
	return tile == _world_matrix[_vec_to_index(matrix_pos)]

func is_out_of_bounds(global_pos: Vector2) -> int:
	var matrix_pos: Vector2i = tile_map.local_to_map(global_pos) - floor_origin
	if matrix_pos.x < 0: return 3
	elif matrix_pos.x >= world_width: return 1
	elif matrix_pos.y < 0: return 0
	elif matrix_pos.y >= world_height: return 2
	return -1

func get_random_empty_tile(in_cells: bool = false) -> Variant:
	_get_rand_lock.lock() #Below this is clearly a critical section (if this ever causes performance issues a more fine grained locking may solve this)

	var temp: Array = _world_empty_cells.keys()
	temp.filter(func(key): return _world_empty_cells[key])

	var res = temp.pick_random()
	res += floor_origin
	if !in_cells:
		res = tile_map.map_to_local(res)

	_get_rand_lock.unlock()
	return res

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

func reset():
	_is_initialized = false
	_world_matrix.clear()
	_world_empty_cells.clear()
	world_width = 0
	world_height = 0
	floor_origin = Vector2i.ZERO	
	tile_map = null

