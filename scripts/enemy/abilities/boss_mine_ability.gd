extends EnemyState
# Handles the tomato bosses ability

const MINE_COUNT: int = 4
const BOMB_RATE: float = 0.5
const BOMB_COOLDOWN: float = 0.5

var bomb_placed: int = 0
var mine_placed: int = 0

func _enter() -> void:
	#TODO play burry animation
	if self.bomb_placed >= self.enemy.get_current_bomb_count(): 
		state_changed.emit(self, "wander")
		return
	self.enemy.stop_moving = true
	self.enemy.anim_player.play("TomatoBoss/burry")
	self.enemy.current_anim = ""
	await self.enemy.anim_player.animation_finished
	if globals.game.stage_done: return
	self.enemy.cooldown_done = false
	if self.mine_placed < MINE_COUNT + self.enemy.get_curr_mine_count():
		place_mine()
	elif self.bomb_placed < self.enemy.get_current_bomb_count():
		place_bomb()

	self.enemy.stop_moving = false
	await get_tree().create_timer(0.05).timeout # Idk why this is needed but the collisions freak the frick out if its not here
	get_tree().create_timer(BOMB_COOLDOWN).timeout.connect(func (): self.enemy.cooldown_done = true, CONNECT_ONE_SHOT)
	state_changed.emit(self, "dodge")

func _reset():
	bomb_placed = 0
	mine_placed = 0

## places a bomb if the current position is valid
func place_mine():
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.MINE, self.enemy.position)): return
	
	var bombPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))
	self.mine_placed += 1
	
	# Adding bomb to astargrid so bombs have collision inside the grid
	astargrid_handler.astargrid_set_point(self.enemy.position, true)
	
	if is_multiplayer_authority():
		var bomb: BombRoot = globals.game.bomb_pool.request()
		bomb.set_bomb_type.rpc(HeldPickups.bomb_types.MINE)
		bomb.bomb_finished.connect(func (): self.mine_placed -= 1, CONNECT_ONE_SHOT)
		bomb.do_place.rpc(bombPos, self.enemy.get_current_bomb_boost())

## places a bomb if the current position is valid
func place_bomb():
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.MINE, self.enemy.position)): return
	
	var bombPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))
	self.bomb_placed += 1
	
	# Adding bomb to astargrid so bombs have collision inside the grid
	astargrid_handler.astargrid_set_point(self.enemy.position, true)
	
	if is_multiplayer_authority():
		var bomb: BombRoot = globals.game.bomb_pool.request()
		if self.enemy.pickups.held_pickups[globals.pickups.GENERIC_BOMB] == HeldPickups.bomb_types.MINE:
			bomb.set_bomb_type.rpc(HeldPickups.bomb_types.DEFAULT)
		else:
			bomb.set_bomb_type.rpc(self.enemy.pickups.held_pickups[globals.pickups.GENERIC_BOMB])
		bomb.bomb_finished.connect(func (): self.bomb_placed -= 1, CONNECT_ONE_SHOT)
		bomb.do_place.rpc(bombPos, self.enemy.get_current_bomb_boost())
