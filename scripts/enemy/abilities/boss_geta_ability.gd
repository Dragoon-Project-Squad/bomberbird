extends EnemyState
# Handles the tomato bosses ability

const BOMB_RATE: float = 0.5
const BOMB_COOLDOWN: float = 0.5

@export var throw_chance: float = 0.5
@export var throw_range: int = 2

var bomb_placed: int = 0
var mine_placed: int = 0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

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
	elif self.enemy.detection_handler.curr_ability == self.enemy.detection_handler.abiltiy.PICKUP:
		place_pickup()
		state_changed.emit(self, "wander")

	await get_tree().create_timer(0.05).timeout # Idk why this is needed but the collisions freak the frick out if its not here
	self.enemy.stop_moving = false
	get_tree().create_timer(BOMB_COOLDOWN).timeout.connect(func (): self.enemy.cooldown_done = true, CONNECT_ONE_SHOT)

func _reset():
	self.bomb_placed = 0
	self.mine_placed = 0

func place_pickup():
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.MINE, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.BREAKABLE, self.enemy.position)): return
	if !is_multiplayer_authority(): return

	var pickupPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))

	var do_throw: bool = _rng.randf() < throw_chance
	var pickup: Pickup = globals.game.pickup_pool.request(globals.pickups.SPEED_DOWN)

	get_tree().create_timer(BOMB_COOLDOWN).timeout.connect(func (): self.enemy.cooldown_done = true, CONNECT_ONE_SHOT)

	if !do_throw && !world_data.is_tile(world_data.tiles.PICKUP, pickupPos):
		pickup.place.rpc(pickupPos, false)
		return

	var temp_dir: Vector2 = self.enemy.statemachine.target.pick_random().position - self.enemy.position
	var dir: Vector2i
	if abs(temp_dir.x) >= abs(temp_dir.y):
		temp_dir.y = 0
		dir = Vector2i(temp_dir.normalized())
	else:
		temp_dir.x = 0
		dir = Vector2i(temp_dir.normalized())
	
	if dir == Vector2i.ZERO:
		dir = Vector2i.RIGHT

	pickup.throw.rpc(
		pickupPos,
		world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(pickupPos) + dir * throw_range),
		dir,
		)

## places a bomb if the current position is valid
func place_bomb():
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.MINE, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.PICKUP, self.enemy.position)): return
	
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
