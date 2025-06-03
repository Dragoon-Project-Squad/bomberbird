extends Zone

@export_group("Stage")

## Private Functions

func _spawn_unbreakables(unbreakable_table: UnbreakableTable):
	obstacles_layer.clear()
	for unbreakable_entry in unbreakable_table.unbreakables:
		if _rng.randf_range(0, 1) > unbreakable_entry.probability: continue
		_spawn_unbreakable.rpc(unbreakable_entry.coords + world_data.floor_origin)

@rpc("call_local")
func _spawn_unbreakable(pos: Vector2i):
	obstacles_layer.set_cell(pos, 3, _unbreakable_tile, 0)

func _generate_breakables(breakable_table: BreakableTable):
	for breakable_entry in breakable_table.breakables:
		var corrected_pos: Vector2i = breakable_entry.coords + world_data.floor_origin
		assert(spawnpoints.all(func (s: Vector2i): return s != corrected_pos), "spawnpoints and breakables position should be mutualy exclusive " + str(spawnpoints) + " : " + str(corrected_pos))
		assert(!enemy_table || enemy_table.get_coords().all(func (s: Vector2i): return s != corrected_pos), "enemy positions and breakables position should be mutualy exclusive")
		if !is_multiplayer_authority() || _rng.randf_range(0, 1) > breakable_entry.probability: continue
		_spawn_breakable(corrected_pos, breakable_entry.contained_pickup)
