extends Zone

@export_group("Stage")
@export var breakable_tile_atlas_coordinates: Vector2i
## if set to false will use the corners as a spawnpoint

## Private Functions

func _generate_breakables():
	for current_cell in obstacles_layer.get_used_cells():	
		if breakable_tile_atlas_coordinates == obstacles_layer.get_cell_atlas_coords(current_cell):
			if is_multiplayer_authority():
				_spawn_breakable(current_cell)
			obstacles_layer.erase_cell(current_cell)
