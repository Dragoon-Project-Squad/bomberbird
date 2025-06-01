extends EnemyState
# Handles the tomato bosses ability

const MINE_COUNT: int = 4
const BOMB_RATE: float = 0.5

var bomb_placed: int = 0
var mine_placed: int = 0

func _enter() -> void:
	#TODO play burry animation
	if mine_placed < MINE_COUNT:
		place_mine()
	elif bomb_placed < self.enemy.get_current_bomb_count():
		place_bomb()

	await get_tree().create_timer(0.5).timeout #change this to animation_finished
	state_changed.emit(self, "wander")


## places a bomb if the current position is valid
func place_mine():
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.MINE, self.enemy.position)): return
	
	var bombPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))
	mine_placed += 1
	
	# Adding bomb to astargrid so bombs have collision inside the grid
	astargrid_handler.astargrid_set_point(self.enemy.position, true)
	
	if is_multiplayer_authority():
		var bomb: BombRoot = globals.game.bomb_pool.request()
		bomb.set_bomb_type.rpc(HeldPickups.bomb_types.MINE)
		bomb.bomb_finished.connect(func (): mine_placed -= 1, CONNECT_ONE_SHOT)
		bomb.do_place.rpc(bombPos, self.enemy.get_current_bomb_boost())

## places a bomb if the current position is valid
func place_bomb():
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.MINE, self.enemy.position)): return
	
	var bombPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))
	bomb_placed += 1
	
	# Adding bomb to astargrid so bombs have collision inside the grid
	astargrid_handler.astargrid_set_point(self.enemy.position, true)
	
	if is_multiplayer_authority():
		var bomb: BombRoot = globals.game.bomb_pool.request()
		bomb.set_bomb_type.rpc(self.enemy.pickups.held_pickups[globals.pickups.GENERIC_BOMB])
		bomb.bomb_finished.connect(func (): bomb_placed -= 1, CONNECT_ONE_SHOT)
		bomb.do_place.rpc(bombPos, self.enemy.get_current_bomb_boost())
