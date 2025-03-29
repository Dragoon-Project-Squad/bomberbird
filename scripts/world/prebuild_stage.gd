extends Zone

@export_group("Stage")
@export var breakable_tile_atlas_coordinates: Vector2i
## if set to false will use the corners as a spawnpoint

var rng = RandomNumberGenerator.new()

## Private Functions

func _generate_breakables():
	for current_cell in obstacles_layer.get_used_cells():	
		if breakable_tile_atlas_coordinates == obstacles_layer.get_cell_atlas_coords(current_cell):
			if is_multiplayer_authority():
				_spawn_breakable(current_cell)
			obstacles_layer.erase_cell(current_cell)

func _spawn_breakable(cell: Vector2i):
	world_data.init_breakable(cell)
	var spawn_coords = world_data.tile_map.map_to_local(cell)
	astargrid_handler.astargrid_set_point(spawn_coords, true)
	breakable_spawner.spawn(spawn_coords)

func _set_spawnpoints():
	var remaining_spawnpoints: int = gamestate.total_player_count - spawnpoints.size()
	while remaining_spawnpoints > 0:	
		var new_spawnpoint: Vector2i = Vector2i(
			rng.randi_range(0, world_data.world_width - 1),
			rng.randi_range(0, world_data.world_height - 1),
		)
		if new_spawnpoint in spawnpoints:
			continue
		spawnpoints.append(new_spawnpoint)
		remaining_spawnpoints -= 1
