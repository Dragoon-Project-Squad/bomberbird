extends Zone

@export_group("Stage")
@export_range(0, 1) var base_breakable_chance: float = 0.5
@export_range(0, 1) var level_chance_multiplier: float = 0.01

## Private Functions

## spawns breakables randomly with a change depending on (gamestate.current_level)

func _ready():
	determine_base_breakable_rate()	
	super()
	
func determine_base_breakable_rate():
	if SettingsContainer.get_breakable_spawn_rule() == 0:
		return # Use the value decided by the STAGE
	elif SettingsContainer.get_breakable_spawn_rule() == 1:
		base_breakable_chance = 0 # NONE
	elif SettingsContainer.get_breakable_spawn_rule() == 2:
		base_breakable_chance = 1 # NONE
	elif SettingsContainer.get_breakable_spawn_rule() == 3: # Custom Mode, use the Global Percent
		base_breakable_chance = SettingsContainer.get_breakable_chance()
	
func _generate_breakables(_breakable_table: BreakableTable = null):
	if not is_multiplayer_authority():
		return
	for x in range(0, world_data.world_width):	
		for y in range(0, world_data.world_height):
			var breakable_spawn_chance = base_breakable_chance + (gamestate.current_level - 1) * level_chance_multiplier
			breakable_spawn_chance = min(breakable_spawn_chance, 0.9)
			var current_cell = Vector2i(x, y) + world_data.floor_origin
			if world_data.is_tile(world_data.tiles.UNBREAKABLE, world_data.tile_map.map_to_local(current_cell)):
				continue # Skip cells where solid tiles are placed
			var skip_checker: Callable = _is_in_spawn_area.bind(1, current_cell)
			if spawnpoints.any(skip_checker): continue
			if enemy_table && enemy_table.get_coords().any(skip_checker): continue

			if _rng.randf() < breakable_spawn_chance:
				_spawn_breakable(current_cell, globals.pickups.RANDOM)

## returns true iff [param pos] is in a designated area around [param spawn] of size [param size] [br]
## [param size] Size of the area [br]
## [param spawn] Vector2i declaring the position of the area [br]
## [param pos] the position to check against [br]
func _is_in_spawn_area(pos: Vector2i, size: int, spawn: Vector2i) -> bool: 
	return (spawn.y - size <= pos.y && pos.y <= spawn.y + size && spawn.x - size <= pos.x && pos.x <= spawn.x + size)
