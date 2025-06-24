extends EnemyState
# Handles the mint bosses ability

const BOMB_RATE: float = 0.5
const BOMB_COOLDOWN: float = 0.5

@export var summon_path: String = "res://scenes/enemies/wisp_enemy_type1.tscn"
@export var max_summons: int = 3

var bomb_placed: int = 0
var mine_placed: int = 0
var summons_placed: int = 0

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
		else:
			state_changed.emit(self, "wander")
	elif summons_placed < max_summons && self.enemy.detection_handler.curr_ability == self.enemy.detection_handler.abiltiy.SUMMON:
		place_summon()
		state_changed.emit(self, "wander")
	else:
		state_changed.emit(self, "wander")

func _exit() -> void:
	await get_tree().create_timer(0.05).timeout # Idk why this is needed but the collisions freak the frick out if its not here
	self.enemy.stop_moving = false
	get_tree().create_timer(BOMB_COOLDOWN).timeout.connect(func (): self.enemy.cooldown_done = true, CONNECT_ONE_SHOT)

func _reset():
	self.bomb_placed = 0
	self.mine_placed = 0
	self.summons_placed = 0

func place_summon():
	var summonPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))

	if !is_multiplayer_authority(): return
	var summon: Enemy = globals.game.enemy_pool.request(summon_path)
	summon.place(summonPos, summon_path)
	summons_placed += 1
	summon.enable()
	globals.current_world.alive_enemies.append(summon)
	globals.game.clock_pickup_time_paused.connect(summon.stop_time)
	globals.game.clock_pickup_time_unpaused.connect(summon.start_time)
	
	summon.enemy_died.connect(func ():
		summons_placed -= 1
		globals.current_world.alive_enemies.erase(summon)
		globals.game.clock_pickup_time_paused.disconnect(summon.stop_time)
		globals.game.clock_pickup_time_unpaused.disconnect(summon.start_time)
		if globals.current_world.alive_enemies.is_empty():
			globals.current_world.all_enemied_died.emit(0),
		CONNECT_ONE_SHOT
		)
	return

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
