class_name WorldData

enum tiles {EMPTY, UNBREAKABLE, BREAKABLE, BOMB, PICKUP}

#private members
var _world_matrix: Array[int]
var _world_empty_cells: Dictionary
var _is_initialized: bool = false

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
	var indx: int = vec.x + vec.y * self.world_width
	assert(indx < self._world_matrix.size(), "index out of bounds for world_data")
	return indx

func _add_tile(tile: int, pos: Vector2i):
	var index = _vec_to_index(pos)
	assert(self._world_matrix[index] != tile, "attempted to place " + str(tile)	+ " on a cell already occupied by that cell")
	self._world_matrix[index] = tile

	if !self._is_initialized: return
	if self._world_matrix[index] != tiles.EMPTY: return
	self._world_empty_cell.erase(pos)


func _remove_tile(pos: Vector2i):
	var index = _vec_to_index(pos)
	self._world_matrix[index] = tiles.EMPTY

	if !self._is_initialized: return
	self._world_empty_cell[pos] = true

@warning_ignore("SHADOWED_VARIABLE")
func begin_init(origin: Vector2, world_width: int, world_height: int):
	self.origin = origin
	self.world_width = world_width
	self.world_height = world_height

	self._world_matrix.resize(world_height * world_width)

func init_unbreakables():
	for x in range(1, world_width, 2):
		for y in range(1, world_height, 2):
			_add_tile(tiles.UNBREAKABLE, Vector2i(x, y))

func init_breakable(cell: Vector2i):
	var matrix_pos: Vector2i = cell - floor_origin
	_add_tile(tiles.BREAKABLE, matrix_pos)


func finish_init():
	self._is_initialized = true

func set_tile(tile: int, global_pos: Vector2):
	var matrix_pos: Vector2i = tile_map.local_to_map(global_pos) - floor_origin
	if tile == tiles.EMPTY:
		return _remove_tile(matrix_pos)
	_add_tile(tile, global_pos)
