extends Zone

@export_group("Stage")
@export_range(0, 1) var base_breakable_chance: float = 0.5
@export_range(0, 1) var level_chance_multiplier: float = 0.01
## if set to false will use the corners as a spawnpoint

## Private Functions

func _generate_breakables():
	if not is_multiplayer_authority():
		return
	for x in range(0, world_data.world_width):	
		for y in range(0, world_data.world_height):
			var breakable_spawn_chance = base_breakable_chance + (gamestate.current_level - 1) * level_chance_multiplier
			breakable_spawn_chance = min(breakable_spawn_chance, 0.9)
			var current_cell = Vector2i(x, y) + world_data.floor_origin
			if world_data.is_tile(world_data.tiles.UNBREAKABLE, world_data.tile_map.map_to_local(current_cell)):
				continue # Skip cells where solid tiles are placed
			var skip: bool = false
			for spawnpoint in spawnpoints:
				if is_in_cross(1, spawnpoint, current_cell):
					skip = true
					break
			if skip: continue
			for enemy_entry in enemy_table.get_coords():
				if is_in_cross(1, enemy_entry, current_cell):
					skip = true
					break
			if skip: continue

			if rng.randf() < breakable_spawn_chance:
				_spawn_breakable(current_cell)

func is_in_cross(size: int, center: Vector2i, point: Vector2i) -> bool: 
	return (point.x == center.x && center.y - size <= point.y && point.y <= center.y + size) || (point.y == center.y && center.x - size <= point.x && point.x <= center.x + size)
