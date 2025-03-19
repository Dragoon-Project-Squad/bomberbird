extends Zone

@export_group("Stage")
@export_range(0, 1) var base_breakable_chance: float = 0.5
@export_range(0, 1) var level_chance_multiplier: float = 0.01
## if set to false will use the corners as a spawnpoint

var rng = RandomNumberGenerator.new()

## Private Functions

func _generate_breakables():
	if not is_multiplayer_authority():
		return
	for x in range(0, world_data.world_width):	
		for y in range(0, world_data.world_height):
			print(gamestate.current_level)
			var breakable_spawn_chance = base_breakable_chance + (gamestate.current_level - 1) * level_chance_multiplier
			breakable_spawn_chance = min(breakable_spawn_chance, 0.9)
			var current_cell = Vector2i(x, y) + world_data.floor_origin
			if world_data.is_tile(world_data.tiles.UNBREAKABLE, world_data.tile_map.map_to_local(current_cell)):
				continue # Skip cells where solid tiles are placed
			var skip: bool = false
			for spawnpoint in spawnpoints: # Skip cells that are adjecent to a spawnpoint
				if current_cell == spawnpoint:
					skip = true
					break
				if current_cell == spawnpoint + Vector2i.LEFT:
					skip = true
					break
				if current_cell == spawnpoint + Vector2i.DOWN:
					skip = true
					break
				if current_cell == spawnpoint + Vector2i.RIGHT:
					skip = true
					break
				if current_cell == spawnpoint + Vector2i.UP:
					skip = true
					break
			if skip: continue
			if rng.randf() < breakable_spawn_chance:
				_spawn_breakable(current_cell)

func _spawn_breakable(cell: Vector2i):
	world_data.init_breakable(cell)
	var spawn_coords = world_data.tile_map.map_to_local(cell)
	astargrid_handler.astargrid_set_point.rpc(spawn_coords, true)
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
