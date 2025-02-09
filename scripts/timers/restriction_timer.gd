extends Timer

var targetTiles = null
var currentTileIndex = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timeout.connect(_on_timeout)
	var world = get_tree().get_root().get_node("World")
	targetTiles = generate_spiral(Vector2(world.map_width - world.map_offset, world.map_height - world.map_offset))

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_timeout() -> void:
	var world = get_tree().get_root().get_node("World")
	var unbreakable_spawner = world.get_node("UnbreakableSpawner")
	var floor = world.get_node("Floor")
	unbreakable_spawner.spawn(floor.map_to_local(Vector2(targetTiles[currentTileIndex].x + 1, targetTiles[currentTileIndex].y + world.map_offset + 1)))
	currentTileIndex += 1
