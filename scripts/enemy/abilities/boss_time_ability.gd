extends EnemyState
## Handles the alt doki bosses ability

const BOMB_RATE: float = 0.5
const BOMB_COOLDOWN: float = 0.5
const PREP_TIME: float = 0.5
const TIME_TILL_DROP: float = 1
const TIME_TILL_STOP: float = 0.05
const TIME_AFTER: float = 0.75
const MAX_PICKUP_PLACED: int = 1

@export var throw_range: int = 3

signal dance_done

var bomb_placed: int = 0
var mine_placed: int = 0
var time_pickup_placed: int = 0
var _rng = RandomNumberGenerator.new()

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
	elif self.enemy.detection_handler.curr_ability == self.enemy.detection_handler.abiltiy.DANCE:
		if time_pickup_placed < MAX_PICKUP_PLACED:
			do_dance()
			await dance_done
			if globals.game.stage_done || self.enemy.disabled: return
			state_changed.emit(self, "wander")
		else:
			state_changed.emit(self, "wander")

	await get_tree().create_timer(0.05).timeout # Idk why this is needed but the collisions freak the frick out if its not here
	if globals.game.stage_done || self.enemy.disabled: return
	self.enemy.stop_moving = false
	get_tree().create_timer(BOMB_COOLDOWN).timeout.connect(func (): self.enemy.cooldown_done = true, CONNECT_ONE_SHOT)

func _reset():
	self.bomb_placed = 0
	self.mine_placed = 0
	self.time_pickup_placed = 0
	var timezone: StaticBody2D = self.enemy.get_node("timezone")
	timezone.hide()
	timezone.stop()
	timezone.disable()

func do_dance():
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return
	if(world_data.is_tile(world_data.tiles.MINE, self.enemy.position)): return
	self.enemy.current_anim = ""
	self.enemy.stop_moving = true
	var timezone: StaticBody2D = self.enemy.get_node("timezone")

	self.enemy.anim_player.play("alt_doki/spin")
	self.enemy.current_anim = ""
	await get_tree().create_timer(PREP_TIME).timeout
	# This is kinda stupit but basically is ensures state after the await checks if the boss is in time_stopped state if so awaits that and then ensures state again
	if globals.game.stage_done || self.enemy.disabled: return
	if self.enemy.time_is_stopped:
		self.enemy.anim_player.stop()
		await globals.game.clock_pickup_time_unpaused
		self.enemy.anim_player.play("alt_doki/spin")
	if globals.game.stage_done || self.enemy.disabled: return

	await timezone.start()
	if globals.game.stage_done || self.enemy.disabled: return
	if self.enemy.time_is_stopped:
		self.enemy.anim_player.stop()
		await globals.game.clock_pickup_time_unpaused
		self.enemy.anim_player.play("alt_doki/spin")
	if globals.game.stage_done || self.enemy.disabled: return
	timezone.enable()

	await get_tree().create_timer(TIME_TILL_DROP).timeout
	if globals.game.stage_done || self.enemy.disabled: return
	if self.enemy.time_is_stopped:
		self.enemy.anim_player.stop()
		await globals.game.clock_pickup_time_unpaused
		self.enemy.anim_player.play("alt_doki/spin")
	if globals.game.stage_done || self.enemy.disabled: return
	throw_clock()

	await get_tree().create_timer(TIME_TILL_STOP).timeout
	if globals.game.stage_done || self.enemy.disabled: return
	if self.enemy.time_is_stopped:
		self.enemy.anim_player.stop()
		await globals.game.clock_pickup_time_unpaused
		self.enemy.anim_player.play("alt_doki/spin")
	if globals.game.stage_done || self.enemy.disabled: return
	timezone.stop()

	await get_tree().create_timer(TIME_AFTER).timeout
	timezone.disable()
	self.enemy.stop_moving = false
	dance_done.emit()
	return

func throw_clock():
	if !is_multiplayer_authority(): return
	var pickupPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))
	var pickup: Pickup = globals.game.pickup_pool.request(globals.pickups.FREEZE)

	var dir: Vector2i
	match _rng.randi_range(0, 3):
		0: dir = Vector2.RIGHT
		1: dir = Vector2.DOWN
		2: dir = Vector2.LEFT
		3: dir = Vector2.UP

	self.time_pickup_placed += 1
	pickup.pickup_destroyed.connect(func (): self.time_pickup_placed -= 1, CONNECT_ONE_SHOT)
	pickup.throw.rpc(
		pickupPos,
		world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(pickupPos) + dir * throw_range),
		dir,
		)

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
