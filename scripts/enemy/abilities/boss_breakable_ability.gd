extends EnemyState
# Handles the tomato bosses ability

const BOMB_RATE: float = 0.5
const BOMB_COOLDOWN: float = 0.5

var bomb_placed: int = 0
var mine_placed: int = 0

func _enter() -> void:
	if bomb_placed >= self.enemy.get_current_bomb_count() - mine_placed: 
		state_changed.emit(self, "wander")
		return
	self.enemy.stop_moving = true
	self.enemy.cooldown_done = false
	if self.enemy.detection_handler.curr_ability == self.enemy.detection_handler.abiltiy.BOMB:
		if bomb_placed < self.enemy.get_current_bomb_count() - mine_placed:
			place_bomb()
			state_changed.emit(self, "dodge")
	elif self.enemy.detection_handler.curr_ability == self.enemy.detection_handler.abiltiy.BREAKABLE:
		place_breakable()
		state_changed.emit(self, "wander")

	await get_tree().create_timer(0.05).timeout # Idk why this is needed but the collisions freak the frick out if its not here
	self.enemy.stop_moving = false
	get_tree().create_timer(BOMB_COOLDOWN).timeout.connect(func (): self.enemy.cooldown_done = true, CONNECT_ONE_SHOT)

func _reset():
	self.bomb_placed = 0
	self.mine_placed = 0

func place_breakable():
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.MINE, self.enemy.position)): return

	var breakablePos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))

	# Adding bomb to astargrid so bombs have collision inside the grid
	astargrid_handler.astargrid_set_point(self.enemy.position, true)

	if is_multiplayer_authority():
		var breakable: Breakable = globals.game.breakable_pool.request()
		breakable.add_collision_exception_with(self.enemy)
		breakable.breakable_destroyed.connect(func (): breakable.remove_collision_exception_with(self.enemy))
		world_data.set_tile(world_data.tiles.BREAKABLE, breakablePos)
		breakable.place.rpc(breakablePos, globals.pickups.NONE, globals.current_world._breakable_texture_path)

## places a bomb if the current position is valid
func place_bomb():
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.MINE, self.enemy.position)): return
	
	var bombPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))
	
	# Adding bomb to astargrid so bombs have collision inside the grid
	astargrid_handler.astargrid_set_point(self.enemy.position, true)
	
	if is_multiplayer_authority():
		var bomb: BombRoot = globals.game.bomb_pool.request()
		if self.enemy.pickups.held_pickups[globals.pickups.GENERIC_BOMB] == HeldPickups.bomb_types.MINE && mine_placed < 1:
			self.mine_placed += 1
			bomb.set_bomb_type.rpc(self.enemy.pickups.held_pickups[globals.pickups.GENERIC_BOMB])
			bomb.bomb_finished.connect(func (): self.mine_placed -= 1, CONNECT_ONE_SHOT)
		else:
			bomb_placed += 1
			if self.enemy.pickups.held_pickups[globals.pickups.GENERIC_BOMB] == HeldPickups.bomb_types.MINE:
				bomb.set_bomb_type.rpc(HeldPickups.bomb_types.DEFAULT)
			else:
				bomb.set_bomb_type.rpc(self.enemy.pickups.held_pickups[globals.pickups.GENERIC_BOMB])
			bomb.bomb_finished.connect(func (): self.bomb_placed -= 1, CONNECT_ONE_SHOT)
		bomb.do_place.rpc(bombPos, self.enemy.get_current_bomb_boost())
