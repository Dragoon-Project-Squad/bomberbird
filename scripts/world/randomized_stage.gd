extends Zone

@export_group("Stage")
@export_range(0, 1) var base_breakable_chance: float = 0.5
@export_range(0, 1) var level_chance_multiplier: float = 0.01
var breakable_spawn_chance = base_breakable_chance
## Private Functions

## spawns breakables randomly with a change depending on (gamestate.current_level)
	
func get_final_breakable_rate() -> float:
	if SettingsContainer.get_breakable_spawn_rule() == SettingsContainer.breakable_spawn_rule_setting_states.STAGE: # Custom Mode, use the Global Percent
		return base_breakable_chance # Use the value decided by the STAGE
	if SettingsContainer.get_breakable_spawn_rule() == SettingsContainer.breakable_spawn_rule_setting_states.CUSTOM: # Custom Mode, use the Global Percent
		return SettingsContainer.get_breakable_chance()/100
	return base_breakable_chance # Failsafe
	
func _generate_breakables_with_weights(_breakable_table: BreakableTable = null):
	if not is_multiplayer_authority():
		return
	for x in range(0, world_data.world_width):	
		for y in range(0, world_data.world_height):
			breakable_spawn_chance = get_final_breakable_rate()
			breakable_spawn_chance = min(breakable_spawn_chance, 1)
			var current_cell = Vector2i(x, y) + world_data.floor_origin
			if world_data.is_tile(world_data.tiles.UNBREAKABLE, world_data.tile_map.map_to_local(current_cell)):
				continue # Skip cells where solid tiles are placed
			self.total_number_of_non_unbreakable_spaces += 1
			var skip_checker: Callable = _is_in_spawn_area.bind(1, current_cell)
			if spawnpoints.any(skip_checker): continue
			if enemy_table && enemy_table.get_coords().any(skip_checker): continue

			if _rng.randf() < breakable_spawn_chance:
				_spawn_breakable(current_cell, globals.pickups.RANDOM)
				
func _generate_breakables_with_amounts(breakable_table: BreakableTable, pickup_table: PickupTable):
	if not is_multiplayer_authority(): return
	var rand_breakable_spawn_dict: Dictionary
	var rand_breakable_arr: Array[Vector2i]
	for x in range(0, world_data.world_width):	
		for y in range(0, world_data.world_height):
			breakable_spawn_chance = get_final_breakable_rate()
			breakable_spawn_chance = min(breakable_spawn_chance, 1)
			var current_cell = Vector2i(x, y) + world_data.floor_origin
			if world_data.is_tile(world_data.tiles.UNBREAKABLE, world_data.tile_map.map_to_local(current_cell)):
				continue # Skip cells where solid tiles are placed
			self.total_number_of_non_unbreakable_spaces += 1
			var skip_checker: Callable = _is_in_spawn_area.bind(1, current_cell)
			if spawnpoints.any(skip_checker): continue
			if enemy_table && enemy_table.get_coords().any(skip_checker): continue
			
			rand_breakable_arr.append(current_cell)
	rand_breakable_arr.shuffle()
	
	var br_counter: int = 0
	for pickup_type in pickup_table.pickup_weights.keys():
		if rand_breakable_arr.size() <= br_counter: break
		for _i in range (pickup_table.pickup_weights[pickup_type]):
			if rand_breakable_arr.size() <= br_counter: break
			rand_breakable_spawn_dict[rand_breakable_arr[br_counter]] = pickup_type
			br_counter += 1
	
	var rand_count: int = 0
	for i in range(rand_breakable_arr.size()):
		if _rng.randf() < breakable_spawn_chance: rand_count += 1

	for i in range(max(br_counter, rand_count)):
		if rand_breakable_spawn_dict.has(rand_breakable_arr[i]):
			_spawn_breakable(rand_breakable_arr[i], rand_breakable_spawn_dict[rand_breakable_arr[i]])
		else:
			_spawn_breakable(rand_breakable_arr[i], globals.pickups.NONE)

## returns true iff [param pos] is in a designated area around [param spawn] of size [param size] [br]
## [param size] Size of the area [br]
## [param spawn] Vector2i declaring the position of the area [br]
## [param pos] the position to check against [br]
func _is_in_spawn_area(pos: Vector2i, size: int, spawn: Vector2i) -> bool: 
	return (spawn.y - size <= pos.y && pos.y <= spawn.y + size && spawn.x - size <= pos.x && pos.x <= spawn.x + size)
