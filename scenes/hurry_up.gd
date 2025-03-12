extends TileMapLayer

signal hurry_up_start

@onready var hurry_up_start_timer: Timer = get_node("Timers/HurryUpStartTimer")
@onready var hurry_up_step_timer: Timer = get_node("Timers/HurryUpStepTimer")
@onready var falling_unbreakable: FallingUnbreakable = $FallingUnbreakable

var target_tiles: Array[Vector2i]
var current_tile_index = 0

func _ready() -> void:
	self.clear()
	# because of the animation taking 0.5 seconds the timer between the waittimes must be slighly higher then that.heightmap_shape_create
	# If this needs to be changed we need more then one FallingUnbreakable node and have logic to use them sequentially
	hurry_up_step_timer.wait_time = max(hurry_up_step_timer.wait_time, 0.55)

func generate_spiral(width: int, height: int) -> Array[Vector2i]:
	var spiral: Array[Vector2i]
	spiral.resize(width * height)
	
	var left: int = 0
	var right: int = width - 1
	var top: int = 0
	var bottom: int = height - 1
	var index: int = 0
	
	while left <= right and top <= bottom:
		# Move Right
		for x in range(left, right + 1):
			spiral[index] = Vector2i(x, top)
			index += 1
		top += 1
		
		# Move Down
		for y in range(top, bottom + 1):
			spiral[index] = Vector2i(right, y)
			index += 1
		right -= 1
		
		# Move Left (if still valid)
		if top <= bottom:
			for x in range(right, left - 1, -1):
				spiral[index] = Vector2i(x, bottom)
				index += 1
			bottom -= 1
		
		# Move Up (if still valid)
		if left <= right:
			for y in range(bottom, top - 1, -1):
				spiral[index] = Vector2i(left, y)
				index += 1
			left += 1
	
	return spiral

func spiral_to_world(index: int) -> Vector2:
	return world_data.tile_map.map_to_local(target_tiles[index] + world_data.floor_origin)

func place(pos: Vector2):
	var cell: Vector2i = local_to_map(pos)
	
	set_cell(cell, 3, Vector2i(6, 0))
	world_data.set_tile(world_data.tiles.UNBREAKABLE, pos)

func _on_hurry_up_start_timer_timeout():
	hurry_up_start.emit()
	target_tiles = generate_spiral(world_data.world_width, world_data.world_height)
	get_node("/root/World/%RemainingTime").add_theme_color_override("font_color", Color(255, 0, 0))
	hurry_up_step_timer.start()


func _on_hurry_up_step_timer_timeout():
	if !is_multiplayer_authority():
		return
	var unbreakable_pos: Vector2 = spiral_to_world(current_tile_index)
	while(current_tile_index < target_tiles.size() && world_data.is_tile(world_data.tiles.UNBREAKABLE, unbreakable_pos)):
		current_tile_index += 1
		unbreakable_pos = spiral_to_world(current_tile_index)
	
	falling_unbreakable.place.rpc(unbreakable_pos)
	
	current_tile_index += 1
	if current_tile_index >= target_tiles.size() - 1:
		hurry_up_step_timer.stop()
