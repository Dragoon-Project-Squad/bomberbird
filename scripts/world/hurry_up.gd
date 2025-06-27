extends TileMapLayer

signal hurry_up_start

const SUDDEN_DEATH_SIZE: Vector2i = Vector2i(9, 7)

@onready var hurry_up_start_timer: Timer = get_node("Timers/HurryUpStartTimer")
@onready var hurry_up_step_timer: Timer = get_node("Timers/HurryUpStepTimer")
@onready var falling_unbreakable_holder: Node2D= get_node("FallingUnbreakableHolder")
@onready var falling_unbreakable_spawner: MultiplayerSpawner = get_node("FallingUnbreakableHolder/MultiplayerSpawner")

var falling_unbreakables: Array[FallingUnbreakable] = []
var target_tiles: Array[Vector2i]
var current_tile_index = 0
var current_falling_unbreakable_index = 0

func start() -> void:
	self.clear()
	hurry_up_step_timer.stop()

	hurry_up_start_timer.wait_time = max(5.0, SettingsContainer.get_match_time() - SettingsContainer.get_hurry_up_time())
	if SettingsContainer.get_hurry_up_state():
		hurry_up_start_timer.start()
	if falling_unbreakables.is_empty():
		hurry_up_start.connect(globals.player_manager._on_hurry_up_start)
		hurry_up_start.connect(globals.game.game_ui._on_hurry_up_start)

	current_tile_index = 0
	current_falling_unbreakable_index = 0
	target_tiles = []

	var hurry_up_time: float = SettingsContainer.get_hurry_up_time() + 1.5 #idk wy this +1.5 is needed but otherwise it does not stop at a nice 00:00
	var total_number_of_non_unbreakable_spaces: int
	if SettingsContainer.get_sudden_death_state():
		total_number_of_non_unbreakable_spaces = get_sudden_death_non_unbreakable_spaces()
	else:
		total_number_of_non_unbreakable_spaces = globals.current_world.total_number_of_non_unbreakable_spaces

	var falling_unbreakable_speed: float = hurry_up_time / total_number_of_non_unbreakable_spaces
	hurry_up_step_timer.wait_time = falling_unbreakable_speed
	assert(falling_unbreakable_speed != 0)
	var anim_time: float = 0.5
	var falling_unbreakables_needed: int = ceili(anim_time / falling_unbreakable_speed) + 1
	if is_multiplayer_authority():
		for i in range(falling_unbreakables_needed - len(falling_unbreakables)):
			falling_unbreakable_spawner.spawn(null)

func get_sudden_death_non_unbreakable_spaces():
	var count: int = 0
	@warning_ignore("INTEGER_DIVISION") # this is supposed to be an int div still don't now wy this is even a warning
	var top_left: Vector2i = Vector2i((world_data.world_width - SUDDEN_DEATH_SIZE.x) / 2, (world_data.world_height - SUDDEN_DEATH_SIZE.y) / 2)
	var bottom_right: Vector2i = Vector2i(world_data.world_width, world_data.world_height) - top_left
	for x in range(world_data.world_width):
		for y in range(world_data.world_height):
			if world_data._is_tile(world_data.tiles.UNBREAKABLE, Vector2i(x, y)): continue
			if x >= top_left.x && x < bottom_right.x && y >= top_left.y && y < bottom_right.y: continue
			count += 1
	return count

@rpc("call_local")
func populate_falling_unbreakables():
	falling_unbreakables = []
	for child in falling_unbreakable_holder.get_children():
		if !child is FallingUnbreakable: continue
		child.hurry_up_tilemap = self
		falling_unbreakables.append(child)
	assert(!falling_unbreakables.is_empty())

func pause_hurry_up(val: bool) -> void:
	if SettingsContainer.get_hurry_up_state():
		hurry_up_start_timer.paused = val
		hurry_up_step_timer.paused = val

func disable() -> void:
	current_tile_index = 0
	current_falling_unbreakable_index = 0
	target_tiles = []

	hurry_up_start_timer.stop()
	hurry_up_step_timer.stop()

func generate_spiral(width: int, height: int) -> Array[Vector2i]:
	var spiral: Array[Vector2i]
	if SettingsContainer.get_sudden_death_state():
		spiral.resize(width * height - SUDDEN_DEATH_SIZE.x * SUDDEN_DEATH_SIZE.y)
	else:
		spiral.resize(width * height)
	
	@warning_ignore("INTEGER_DIVISION") # this is supposed to be an int div still don't now wy this is even a warning
	var top_left: Vector2i = Vector2i((world_data.world_width - SUDDEN_DEATH_SIZE.x) / 2, (world_data.world_height - SUDDEN_DEATH_SIZE.y) / 2)
	var bottom_right: Vector2i = Vector2i(world_data.world_width, world_data.world_height) - top_left

	var left: int = 0
	var right: int = width - 1
	var top: int = 0
	var bottom: int = height - 1
	var index: int = 0
	
	while left <= right and top <= bottom:
		if SettingsContainer.get_sudden_death_state():
			if Vector2i(left, top) == top_left && Vector2i(right + 1, bottom + 1) == bottom_right: break

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
	if is_multiplayer_authority(): populate_falling_unbreakables.rpc()
	hurry_up_start.emit()
	target_tiles = generate_spiral(world_data.world_width, world_data.world_height)
	globals.game.game_ui.get_node("%TimeLabel").add_theme_color_override("font_color", Color(255, 0, 0))
	hurry_up_step_timer.start()


func _on_hurry_up_step_timer_timeout():
	if !is_multiplayer_authority():
		return
	var unbreakable_pos: Vector2 = spiral_to_world(current_tile_index)
	while(current_tile_index + 1 < target_tiles.size() && world_data.is_tile(world_data.tiles.UNBREAKABLE, unbreakable_pos)):
		current_tile_index += 1
		unbreakable_pos = spiral_to_world(current_tile_index)

	if !world_data.is_tile(world_data.tiles.UNBREAKABLE, unbreakable_pos):
		falling_unbreakables[current_falling_unbreakable_index].place.rpc(unbreakable_pos)
		current_falling_unbreakable_index = (current_falling_unbreakable_index + 1) % len(falling_unbreakables)
	
	current_tile_index += 1
	if current_tile_index < target_tiles.size(): return
	hurry_up_step_timer.stop()
