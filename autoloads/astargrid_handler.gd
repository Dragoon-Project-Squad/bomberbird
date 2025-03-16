extends Node
class_name AStarGridHandler

var astargrid: AStarGrid2D = AStarGrid2D.new()
var astargrid_no_breakables: AStarGrid2D = AStarGrid2D.new()

func setup_astargrid():
	astargrid.region = world_data.get_arena_rect()
	astargrid.cell_size = Vector2i(16, 16)
	astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astargrid.update()

	astargrid_no_breakables.region = world_data.get_arena_rect()
	astargrid_no_breakables.cell_size = Vector2i(16, 16)
	astargrid_no_breakables.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astargrid_no_breakables.update()

## sets unbeakables as solidpoints
func astargrid_set_initial_solidpoints() -> void:
	for unbreakable_cell in world_data.get_tiles(world_data.tiles.UNBREAKABLE, true):
		astargrid.set_point_solid(unbreakable_cell, true)
		astargrid_no_breakables.set_point_solid(unbreakable_cell, true)

## sets 'pos' as a solid in the astargrid (used for breakable mainly?)
@rpc("call_local")
func astargrid_set_point(pos: Vector2, solid: bool) -> void:
	astargrid.set_point_solid(
		world_data.tile_map.local_to_map(pos),
		solid,
		)

func create_path_no_breakables(player: Player, end_position: Vector2i) -> Array[Vector2i]:
	var player_pos = globals.player_manager.get_node(str(player.name)).global_position
	var map_player_pos = world_data.tile_map.local_to_map(player_pos)
	return astargrid_no_breakables.get_id_path(map_player_pos, end_position)

func create_path(player: Player, end_position: Vector2i) -> Array[Vector2i]:
	var player_pos = globals.player_manager.get_node(str(player.name)).global_position
	var map_player_pos = world_data.tile_map.local_to_map(player_pos)
	return astargrid.get_id_path(map_player_pos, end_position)
