extends EnemyState
## Implements the special wander behavior for bosses

const ARRIVAL_TOLARANCE: float = 1

@export var recheck_distance: int = 4

var next_position: Vector2
var curr_path: Array[Vector2] = []:
	set(val):
		if !val.is_empty():
			self.enemy.get_node("DebugMarker").position = val[-1]
		curr_path = val
var distance: int = 0

func _enter():
	self.enemy.detection_handler.check_for_priority_target()
	assert(self.enemy.statemachine.target)
	self.distance = 0
	self.curr_path = get_chase_path()
	self.next_position = get_next_pos(self.curr_path)
	self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO

func _exit():
	curr_path = []
	self.distance = 0
	self.enemy.statemachine.target = null

func _physics_update(delta):
	_move(delta)

	if self.enemy.stunned: return
	var arrived: bool = check_arrival()
	if arrived && self.curr_path.is_empty():
		if detect(): return
		self.curr_path = get_chase_path()
		self.next_position = get_next_pos(self.curr_path)
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO
	elif arrived && self.distance >= self.recheck_distance:
		if detect(): return
		self.distance = 0
		self.curr_path = get_chase_path()
		self.next_position = get_next_pos(self.curr_path)
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO
	elif arrived:
		if detect(): return
		self.next_position = get_next_pos(self.curr_path)
		self.distance += 1
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO
	if !valid_tile(self.next_position):
		self.next_position = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO


func valid_tile(pos: Vector2) -> bool:
	if world_data.is_out_of_bounds(pos) != -1: return false
	var ret: bool = world_data.is_tile(world_data.tiles.EMPTY, pos) || world_data.is_tile(world_data.tiles.PICKUP, pos)
	ret = ret || world_data.is_tile(world_data.tiles.MINE, pos)
	ret = ret || self.enemy.wallthrought && world_data.is_tile(world_data.tiles.BREAKABLE, pos)
	ret = ret || self.enemy.bombthrought && world_data.is_tile(world_data.tiles.BOMB, pos)
	return ret

func get_chase_path() -> Array[Vector2]:
	var safe_tiles: Array[int] = [world_data.tiles.EMPTY, world_data.tiles.PICKUP]
	if self.enemy.wallthrought:
		safe_tiles.append(world_data.tiles.BREAKABLE)
	if self.enemy.bombthrought:
		safe_tiles.append(world_data.tiles.BOMB)
	var corrected_target_pos: Vector2 = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.statemachine.target.position))
	var path: Array[Vector2] = world_data.get_target_path(self.enemy.position, corrected_target_pos, false, safe_tiles)

	if !path.is_empty():
		path.pop_front()

	return path 

func get_next_pos(path: Array[Vector2]) -> Vector2:
	if !path.is_empty() && valid_tile(path[0]): 
		var pos: Vector2 = path.pop_front()
		return pos
	return world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))

func check_arrival() -> bool:
	if self.enemy.position.distance_to(self.next_position) <= ARRIVAL_TOLARANCE:
		self.enemy.position = self.next_position
		self.enemy.synced_position = self.next_position
		return 1
	return 0

func detect() -> bool:
	self.enemy.detection_handler.check_for_priority_target()
	return false
