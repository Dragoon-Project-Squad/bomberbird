class_name WorldData extends Node
## A datastructure for tracking the state of the current stage ensures each tile only contains one object and also gives easy and fast access to the contends of each tile

signal world_data_changed 

enum tiles {EMPTY, UNBREAKABLE, BREAKABLE, BOMB, MINE, PICKUP}
enum danger_level {SAFE, UNSAFE}
enum bounds {IN = -1, OUT_TOP = 0, OUT_RIGHT = 1, OUT_DOWN = 2, OUT_LEFT = 3}

#private members
var _world_matrix: Array[int]
var _world_empty_cells: Dictionary
var _is_initialized: bool = false
var _signal_dict: Dictionary

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

## returns the index of a vector corresponding the the _world_matrix entry of this vector
## [param vec]
func _vec_to_index(vec: Vector2i) -> int:
	assert(0 <= vec.x && vec.x < world_width && 0 <= vec.y && vec.y < world_height, "index " + str(vec) + " out of bounds for world_data")
	var indx: int = (vec.x + vec.y * self.world_width) * 2
	assert(indx < self._world_matrix.size(), "index" + str(vec) + " <-> " + str(indx) + " out of bounds for world_data")
	return indx

## returns the index of a vector corresponding the the _world_matrix entry of this vector
## [param vec]
func _vec_to_danger_index(vec: Vector2i) -> int:
	assert(0 <= vec.x && vec.x < world_width && 0 <= vec.y && vec.y < world_height, "index " + str(vec) + " out of bounds for world_data")
	var indx: int = (vec.x + vec.y * self.world_width) * 2 + 1
	assert(indx < self._world_matrix.size(), "index" + str(vec) + " <-> " + str(indx) + " out of bounds for world_data")
	return indx

## adds a tile to a position ensuring that that tile is valid
## [param tile] ENUM corresponding to the tile that should be placed
## [param pos] Vector2i
func _add_tile(tile: int, pos: Vector2i, danger_range: int = 0, pierce: bool = false):
	var index = _vec_to_index(pos)
	var danger_index = _vec_to_danger_index(pos)
	assert(self._world_matrix[index] != tile, "attempted to place " + _int_to_enum_name(tile)	+ " on a cell already occupied by that cell")
	self._world_matrix[index] = tile
	if tile == tiles.BOMB:
		self._world_matrix[danger_index] = danger_range if !pierce else -danger_range
	elif tile == tiles.MINE:
		self._world_matrix[danger_index] = 0

	if !self._is_initialized: return
	if self._world_matrix[index] == tiles.EMPTY:
		self._world_empty_cells[pos] = true
		return
	self._world_empty_cells.erase(pos)

## removes a tile to a position
## [param pos] Vector2i
func _remove_tile(pos: Vector2i):
	var index = _vec_to_index(pos)
	var danger_index = _vec_to_danger_index(pos)
	self._world_matrix[index] = tiles.EMPTY
	self._world_matrix[danger_index] = 0

	if !self._is_initialized: return
	self._world_empty_cells[pos] = true


## Testing and debug functions
func _debug_print_matrix():
	print("World Matrix:")
	for y in range(0, world_height):
		print(_world_matrix.slice(y * world_width * 2, (y + 1) * world_width * 2))
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

## returns a name string of the tile enum
## [param tile]
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

	self._world_matrix.resize(world_height * world_width * 2)

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
func set_tile(tile: int, global_pos: Vector2, danger_range: int = 0, pierce: bool = false):
	var matrix_pos: Vector2i = tile_map.local_to_map(global_pos) - floor_origin
	world_data_changed.emit(tile, matrix_pos + floor_origin)
	if tile == tiles.EMPTY:
		_remove_tile(matrix_pos)
	else:
		_add_tile(tile, matrix_pos, danger_range, pierce)

## checks if the tile at 'global_pos' is 'tile'
func is_tile(tile: int, global_pos: Vector2):
	var matrix_pos: Vector2i = tile_map.local_to_map(global_pos) - floor_origin
	return tile == _world_matrix[_vec_to_index(matrix_pos)]

## checks if the tile at 'global_pos' is 'tile'
func _is_tile(tile: int, pos: Vector2i):
	return tile == _world_matrix[_vec_to_index(pos)]

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
	var temp: Array = _world_empty_cells.keys()
	temp.filter(func(key): return _world_empty_cells[key])

	var res = temp.pick_random()
	if res == null: return null
	_world_empty_cells[res] = false
	res += floor_origin
	if !in_cells:
		res = tile_map.map_to_local(res)
	return res

## gets an Array of size count (or less if less are awailable) of randomly choosen empty cells set all chooses to handed out
func get_random_empty_tiles(count: int, in_cells: bool = false) -> Array:
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
	return res

func reset_empty_cells(cells: Array[Vector2]) -> void:
	for cell in cells:
		if _world_empty_cells.has(cell):
			_world_empty_cells[cell] = true

func get_empty_tiles(in_cells: bool = false) -> Array:
	if in_cells:
		return _world_empty_cells.keys().filter(
			func (key): return _world_empty_cells[key]
			).map(
				func (key): return key + floor_origin
				)
	else:
		return _world_empty_cells.keys().filter(
			func (key): return _world_empty_cells[key]
			).map(
				func (key): return tile_map.map_to_local(key + floor_origin)
				)

func _is_walkable(pos: Vector2i, walkable_tiles: Array[int]):
	if !(0 <= pos.x && pos.x < world_width && 0 <= pos.y && pos.y < world_height): return false
	return self._world_matrix[_vec_to_index(pos)] in walkable_tiles

func _to_real_path(path: Array):
	var res: Array[Vector2]
	for i in range(len(path)):
		res.append(tile_map.map_to_local(path[i] + floor_origin))
	return res

func get_random_path(start_pos: Vector2, max_range: int, safe: bool = true, valid_tiles: Array[int] = [tiles.EMPTY, tiles.PICKUP]) -> Array[Vector2]:
	var start_matrix_pos: Vector2i = tile_map.local_to_map(start_pos) - floor_origin

	var path_queue: Array[Array] = [[start_matrix_pos]]
	while !path_queue.is_empty():
		var path = path_queue.pop_front()
		if len(path) == max_range:
			path_queue.append(path)
			break
		for dir in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var next_pos: Vector2i = path[-1] + dir
			if len(path) > 1 && next_pos == path[-2]: continue
			if !_is_walkable(next_pos, valid_tiles): continue
			if !safe || !_is_safe_cell(next_pos): continue
			var new_path = path.duplicate() 
			new_path.append(next_pos)
			path_queue.append(new_path)
		if path_queue.is_empty():
			return _to_real_path(path)

	if path_queue.is_empty():
		return []
	var choosen_path: Array = path_queue.pick_random()
	return _to_real_path(choosen_path)

func get_path_to_safe(start_pos: Vector2, valid_tiles: Array[int] = [tiles.EMPTY, tiles.PICKUP]) -> Array[Vector2]:
	var start_matrix_pos: Vector2i = tile_map.local_to_map(start_pos) - floor_origin

	var found_safe: bool = false
	var safe_paths: Array[Array]
	var path_queue: Array[Array] = [[start_matrix_pos]]
	while !path_queue.is_empty():
		var path = path_queue.pop_front()
		for dir in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var next_pos: Vector2i = path[-1] + dir
			if next_pos in path: continue
			if !_is_walkable(next_pos, valid_tiles): continue
			if _is_safe_cell(next_pos): 
				found_safe = true
				path.append(next_pos)
				safe_paths.append(_to_real_path(path))
			var new_path = path.duplicate() 
			new_path.append(next_pos)
			path_queue.append(new_path)
		if found_safe:
			return safe_paths.pick_random()

	return []

func get_target_path(start_pos: Vector2, end_pos: Vector2, safe: bool = true, valid_tiles: Array[int] = [tiles.EMPTY, tiles.PICKUP]) -> Array[Vector2]:
	var start_matrix_pos: Vector2i = tile_map.local_to_map(start_pos) - floor_origin
	var end_matrix_pos: Vector2i = tile_map.local_to_map(end_pos) - floor_origin

	var path_queue: Array = [[start_matrix_pos]]
	var visisted: Dictionary = {}
	while !path_queue.is_empty():
		var path = path_queue.pop_front()
		var node: Vector2i = path[-1]
		visisted[node] = null
		for dir in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var next_pos: Vector2i = node + dir
			if !_is_walkable(next_pos, valid_tiles): continue
			if !safe || !_is_safe_cell(next_pos): continue
			if visisted.has(next_pos): continue
			var new_path = path.duplicate() 
			new_path.append(next_pos)
			if next_pos == end_matrix_pos: return _to_real_path(new_path)
			path_queue.push_back(new_path)
	return []

func get_shortest_path_to(start_pos: Vector2, end_pos: Vector2, safe: bool = true, valid_tiles: Array[int] = [tiles.EMPTY, tiles.PICKUP]) -> int:
	var start_matrix_pos: Vector2i = tile_map.local_to_map(start_pos) - floor_origin
	var end_matrix_pos: Vector2i = tile_map.local_to_map(end_pos) - floor_origin

	var path_queue: Array = [start_matrix_pos]
	var visisted: Dictionary = {}
	var distances: Dictionary = {start_matrix_pos: 0}
	while !path_queue.is_empty():
		var node = path_queue.pop_front()
		visisted[node] = null
		for dir in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
			var next_pos: Vector2i = node + dir
			if !_is_walkable(next_pos, valid_tiles): continue
			if !safe || !_is_safe_cell(next_pos): continue
			if visisted.has(next_pos): continue
			distances[next_pos] = distances[node] + 1
			if next_pos == end_matrix_pos: return distances[next_pos]
			path_queue.push_back(next_pos)
	return -1

func _is_safe_cell(pos: Vector2i, do_mine: bool = true) -> bool:
	for dir in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var curr_pos: Vector2i = pos
		var distance: int = 0
		var is_pierce: bool = false
		var seen_breakable: bool = false
		while (
			0 <= curr_pos.x &&
			curr_pos.x < world_width &&
			0 <= curr_pos.y &&
			curr_pos.y < world_height &&
			self._world_matrix[_vec_to_index(curr_pos)] != tiles.UNBREAKABLE
		):
			var tile: int = self._world_matrix[_vec_to_index(curr_pos)]
			if tile == tiles.BREAKABLE:
				seen_breakable = true
			var curr_danger: int = self._world_matrix[_vec_to_danger_index(curr_pos)]
			if curr_danger != 0:
				if curr_danger < 0: 
					curr_danger = -curr_danger
					is_pierce = true
				if distance <= curr_danger && (is_pierce || !seen_breakable) && (do_mine || tile == tiles.BOMB):
					return false
			distance += 1
			curr_pos += dir
	return true

func is_safe(pos: Vector2, do_mine: bool = true) -> bool:
	var matrix_pos: Vector2i = tile_map.local_to_map(pos) - floor_origin
	return _is_safe_cell(matrix_pos, do_mine)

## resets world_data to before initialisation
func reset():
	_is_initialized = false
	_world_matrix.clear()
	_world_empty_cells.clear()
	world_width = 0
	world_height = 0
	floor_origin = Vector2i.ZERO	
	tile_map = null
	for conn in world_data_changed.get_connections():
		world_data_changed.disconnect(conn.callable)
