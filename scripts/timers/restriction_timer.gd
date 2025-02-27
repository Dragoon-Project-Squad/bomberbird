extends Timer

var target_tiles = null
var current_tile_index = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timeout.connect(_on_timeout)
	var world = get_tree().get_root().get_node("World")
	target_tiles = generate_spiral(Vector2(world.map_width - world.map_offset, world.map_height - world.map_offset))

func generate_spiral(grid_size: Vector2) -> Array:
	var width = grid_size.x
	var height = grid_size.y
	var spiral = []
	
	var left = 0
	var right = width - 1
	var top = 0
	var bottom = height - 1
	
	while left <= right and top <= bottom:
		# Move Right
		for x in range(left, right + 1):
			spiral.append(Vector2(x, top))
		top += 1
		
		# Move Down
		for y in range(top, bottom + 1):
			spiral.append(Vector2(right, y))
		right -= 1
		
		# Move Left (if still valid)
		if top <= bottom:
			for x in range(right, left - 1, -1):
				spiral.append(Vector2(x, bottom))
			bottom -= 1
		
		# Move Up (if still valid)
		if left <= right:
			for y in range(bottom, top - 1, -1):
				spiral.append(Vector2(left, y))
			left += 1

	return spiral
	
func spiral_to_world(index: int, world: World) -> Vector2:
	return Vector2(
		target_tiles[index].x + 1,
		target_tiles[index].y + world.map_offset + 1
	)


func _on_timeout() -> void:
	var world = get_tree().get_root().get_node("World")
	var unbreakable_spawner = world.get_node("UnbreakableSpawner")

	var unbreakable_pos: Vector2 = world_data.tile_map.map_to_local(spiral_to_world(current_tile_index, world))
	while(current_tile_index < target_tiles.size() && world_data.is_tile(world_data.tiles.UNBREAKABLE, unbreakable_pos)):
		world_data._debug_print_matrix()
		current_tile_index += 1
		unbreakable_pos = world_data.tile_map.map_to_local(spiral_to_world(current_tile_index, world))

	unbreakable_spawner.spawn(unbreakable_pos)
	current_tile_index += 1

	world_data.set_tile(world_data.tiles.UNBREAKABLE, unbreakable_pos)
	
	if current_tile_index >= target_tiles.size():
		stop()
