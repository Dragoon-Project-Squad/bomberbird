extends Zone

@export_group("Stage")
@export var breakable_tile_atlas_coordinates: Vector2i

var _obstacles_layer_copy: TileMapLayer

## Private Functions

## Generate breakable from the obstical layerr replacing each on that layer with an actual breakable
func _generate_breakables(_breakable_table: BreakableTable = null):
	for current_cell in obstacles_layer.get_used_cells():	
		if breakable_tile_atlas_coordinates != obstacles_layer.get_cell_atlas_coords(current_cell): continue
		obstacles_layer.erase_cell(current_cell)
		var skip_checker: Callable = _is_in_spawn_area.bind(1, current_cell)
		if spawnpoints.any(skip_checker): continue
		if enemy_table && enemy_table.get_coords().any(skip_checker): continue
		if is_multiplayer_authority():
			_spawn_breakable(current_cell, globals.pickups.RANDOM)

## returns true iff [param pos] is in a designated area around [param spawn] of size [param size] [br]
## [param size] Size of the area [br]
## [param spawn] Vector2i declaring the position of the area [br]
## [param pos] the position to check against [br]
func _is_in_spawn_area(pos: Vector2i, size: int, spawn: Vector2i) -> bool: 
	return (spawn.y - size <= pos.y && pos.y <= spawn.y + size && spawn.x - size <= pos.x && pos.x <= spawn.x + size)

## takes the copied obstacle layer and replaces the old one with it
func reset():
	super()
	remove_child(obstacles_layer)
	bounds_layer.add_sibling(_obstacles_layer_copy)

@warning_ignore("SHADOWED_VARIABLE_BASE_CLASS")
##copies the obstical layer to allow for reseting later
func enable(
	exit_table: ExitTable = null,
	enemy_table: EnemyTable = null,
	pickup_table: PickupTable = self.pickup_table,
	spawnpoints_table: SpawnpointTable = null,
	unbreakable_table: UnbreakableTable = null,
	breakable_table: BreakableTable = null,
):
	_obstacles_layer_copy = obstacles_layer.duplicate() # we want to store this layer with the breakable tiles on it to reset the modified one later
	super(exit_table, enemy_table, pickup_table, spawnpoints_table, unbreakable_table, breakable_table)
