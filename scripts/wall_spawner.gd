extends MultiplayerSpawner
const EXPLOSION_SCENE_PATH : String = "res://scenes/explosion.tscn"

func _init():
	spawn_function = place_void
	
func place_void(spawn_position: Vector2):
	# TODO: Temp. Using explosion for placeholder
	var wall = preload(EXPLOSION_SCENE_PATH).instantiate()
	var world = get_tree().get_root().get_node("World")
	var unbreakable_layer: TileMapLayer = world.get_node("Unbreakable")
	var floor_layer: TileMapLayer = world.get_node("Floor")
	
	# TODO: This is not great, an attempt at clearing the position before placing the wall
	if unbreakable_layer.get_cell_tile_data(spawn_position) != null:
		unbreakable_layer.erase_cell(spawn_position)
	if floor_layer.get_cell_tile_data(spawn_position) != null:
		floor_layer.erase_cell(spawn_position)
	
	wall.position = spawn_position
	
	unbreakable_layer.erase_cell(unbreakable_layer.map_to_local(wall.position))
	return wall
