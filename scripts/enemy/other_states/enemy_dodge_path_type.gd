extends EnemyState
## Implements the custom dodge pathing for bosses

const ARRIVAL_TOLARANCE: float = 1

var next_position: Vector2:
	set(val):
		self.enemy.get_node("DebugMarker2").position = val
		next_position = val
var curr_path: Array[Vector2] = []:
	set(val):
		if !val.is_empty():
			self.enemy.get_node("DebugMarker").position = val[-1]
		curr_path = val

func _enter():
	assert(self.enemy is Boss)
	self.curr_path = get_dodge_path()
	self.next_position = get_next_pos(self.curr_path)
	self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO

func _exit():
	curr_path = []

func _physics_update(delta):
	_move(delta)

	if self.enemy.stunned: return
	var arrived: bool = check_arrival()

	if arrived:
		var ability: int = self.enemy.ability_detector.check_ability_usage()
		match ability:
			enemy.ability_detector.ability.PUNCH:
				state_changed.emit(self, "punch")
				return
			enemy.ability_detector.ability.KICK:
				state_changed.emit(self, "kick")
				return
			enemy.ability_detector.ability.THROW:
				state_changed.emit(self, "carry")
				return

	if arrived && self.enemy.kicked_bomb && self.enemy.ability_detector.check_stop_kick():
		if self.enemy.kicked_bomb.state == BombRoot.SLIDING:
			self.enemy.kicked_bomb.stop_kick()
			self.enemy.kicked_bomb = null

	if arrived && self.enemy.bomb_to_throw && self.enemy.ability_detector.check_throw():
		self.enemy.bomb_carry_sprite.hide()
		if self.enemy.movement_vector != Vector2.ZERO:
			self.enemy.bomb_to_throw.do_throw(self.enemy.movement_vector, self.enemy.position)
		else:
			self.enemy.bomb_to_throw.do_throw(self.enemy.last_movement_vector, self.enemy.position)
		self.enemy.bomb_to_throw = null

	if arrived && !world_data.is_safe(self.enemy.position): #dodge again
		self.curr_path = get_dodge_path()
		self.next_position = get_next_pos(self.curr_path)
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO

	elif arrived && self.curr_path.is_empty(): #change to wander
		state_changed.emit(self, "wander")
		return

	elif arrived:
		self.next_position = get_next_pos(self.curr_path)
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO

	if !valid_tile(self.next_position):
		self.next_position = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO


func valid_tile(pos: Vector2) -> bool:
	if world_data.is_out_of_bounds(pos) != -1: return false
	var ret: bool = world_data.is_tile(world_data.tiles.EMPTY, pos) || world_data.is_tile(world_data.tiles.PICKUP, pos)
	ret = ret || world_data.is_tile(world_data.tiles.MINE, pos)
	ret = ret || (self.enemy.wallthrought || self.enemy.pickups.held_pickups[globals.pickups.WALLTHROUGH]) && world_data.is_tile(world_data.tiles.BREAKABLE, pos)
	ret = ret || (self.enemy.bombthrought || self.enemy.pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] == HeldPickups.exclusive.BOMBTHROUGH) && world_data.is_tile(world_data.tiles.BOMB, pos)
	return ret

func get_dodge_path() -> Array[Vector2]:
	var safe_tiles: Array[int] = [world_data.tiles.EMPTY, world_data.tiles.PICKUP]
	if self.enemy.wallthrought || self.enemy.pickups.held_pickups[globals.pickups.WALLTHROUGH]:
		safe_tiles.append(world_data.tiles.BREAKABLE)
	if self.enemy.bombthrought || self.enemy.pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] == HeldPickups.exclusive.BOMBTHROUGH:
		safe_tiles.append(world_data.tiles.BOMB)
	var paths: Array[Array] = world_data.get_paths_to_safe(self.enemy.position, safe_tiles)
	if paths.is_empty(): return []
	
	paths.sort_custom(
		func (v1, v2):
			if len(v1) < 2: return false
			if len(v2) < 2: return true
			return self.enemy.statemachine.target[0].position.distance_to(v1[1]) > self.enemy.statemachine.target[0].position.distance_to(v2[1])
	)
	var path: Array[Vector2]
	for pos in paths[0]:
		path.append(pos)


	if !path.is_empty(): path.pop_front()

	return path 

func get_next_pos(path: Array[Vector2]) -> Vector2:
	if !path.is_empty() && valid_tile(path[0]): 
		var pos: Vector2 = path.pop_front()
		return pos
	return world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))

func check_arrival() -> bool:
	if self.enemy.position.distance_to(self.next_position) <= ARRIVAL_TOLARANCE * (1 + self.enemy.pickups.held_pickups[globals.pickups.SPEED_UP]):
		self.enemy.position = self.next_position
		self.enemy.synced_position = self.next_position
		return 1
	return 0
