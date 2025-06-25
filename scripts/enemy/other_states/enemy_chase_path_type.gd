extends EnemyState
## Implements the special wander behavior for bosses

const ARRIVAL_TOLARANCE: float = 1

@export var chase_min_dist: int = 3
@export var chase_max_dist: int = 3
@export var recheck_distance: int = 4

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var next_position: Vector2:
	set(val):
		self.enemy.get_node("DebugMarker2").position = val
		next_position = val
var curr_path: Array[Vector2] = []:
	set(val):
		if !val.is_empty():
			self.enemy.get_node("DebugMarker").position = val[-1]
		curr_path = val
var distance: int = 0

func _enter():
	assert(self.enemy is Boss)
	assert(self.enemy.curr_target)
	self.distance = 0
	self.curr_path = get_chase_path()
	self.next_position = get_next_pos(self.curr_path)
	self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO

func _exit():
	curr_path = []
	self.distance = 0
	self.enemy.curr_target = null


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
			self.enemy.bomb_to_throw.do_throw(Vector2.DOWN, self.enemy.position)
		self.enemy.bomb_to_throw = null

	if arrived && self.enemy.kicked_bomb && self.enemy.ability_detector.check_stop_kick():
		if self.enemy.kicked_bomb.state == BombRoot.SLIDING:
			self.enemy.kicked_bomb.stop_kick()

	if arrived && !world_data.is_safe(self.enemy.position):
		state_changed.emit(self, "dodge")
		return
	elif arrived && self.curr_path.is_empty(): #change to wander or ability
		if detect(): return
		state_changed.emit(self, "wander")
		return
	elif arrived && self.distance >= self.recheck_distance:
		self.distance = 0
		self.curr_path = get_chase_path()
		self.next_position = get_next_pos(self.curr_path)
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO
	elif arrived:
		self.next_position = get_next_pos(self.curr_path)
		if !world_data.is_safe(self.next_position, false):
			self.curr_path = get_chase_path()
			self.distance = 0
			self.next_position = get_next_pos(self.curr_path)
		else:
			self.distance += 1
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

func get_chase_path() -> Array[Vector2]:
	var safe_tiles: Array[int] = [world_data.tiles.EMPTY, world_data.tiles.PICKUP]
	if self.enemy.wallthrought || self.enemy.pickups.held_pickups[globals.pickups.WALLTHROUGH]:
		safe_tiles.append(world_data.tiles.BREAKABLE)
	if self.enemy.bombthrought || self.enemy.pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] == HeldPickups.exclusive.BOMBTHROUGH:
		safe_tiles.append(world_data.tiles.BOMB)
	var corrected_target_pos: Vector2i = world_data.tile_map.local_to_map(self.enemy.curr_target.position)
	var goal_pos_arr: Array[Vector2] = []
	for dir in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.DOWN]:
		var goal_pos: Vector2 = world_data.tile_map.map_to_local(corrected_target_pos + dir * (_rng.randi_range(chase_min_dist, chase_max_dist)))
		if valid_tile(goal_pos): goal_pos_arr.append(goal_pos)

	var path: Array[Vector2]
	for goal_pos in goal_pos_arr:
		path = world_data.get_target_path(self.enemy.position, goal_pos, true, safe_tiles)

		if !path.is_empty():
			path.pop_front()
			break

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

func detect() -> bool:
	if(self.enemy.detection_handler.check_for_priority_target(true)):
		state_changed.emit(self, "ability")
		return true
	return false
