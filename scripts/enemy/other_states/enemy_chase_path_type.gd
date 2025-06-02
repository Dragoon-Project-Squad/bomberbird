extends EnemyState
## Implements the wander behavior '1' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

const ARRIVAL_TOLARANCE: float = 1
const STARTING_CLOSENESS: int = 2

@export var chase_stop_distance: int = 3
@export var recheck_distance: int = 4

var next_position: Vector2
var curr_path: Array[Vector2] = []
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
	if arrived && !world_data.is_safe(self.enemy.position): #dodge again
		state_changed.emit(self, "dodge")
		return
	elif arrived && len(self.curr_path) <= self.chase_stop_distance: #change to wander
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
	var path: Array[Vector2] = world_data.get_target_path(self.enemy.position, self.enemy.curr_target.position, true, safe_tiles)
	print("chasing path for ", self.enemy.position, " -> ", self.enemy.curr_target.position, ": ", path)

	if !path.is_empty():
		self.enemy.get_node("DebugMarker").position = path[-1]
		path.pop_front()
	else:
		self.enemy.get_node("DebugMarker").position = self.enemy.position

	return path 

func get_next_pos(path: Array[Vector2]) -> Vector2:
	if !path.is_empty() && valid_tile(path[0]): 
		var pos: Vector2 = path.pop_front()
		self.enemy.get_node("DebugMarker2").position = pos
		return pos
	self.enemy.get_node("DebugMarker2").position = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))
	return world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))

func check_arrival() -> bool:
	if self.enemy.position.distance_to(self.next_position) <= ARRIVAL_TOLARANCE:
		self.enemy.position = self.next_position
		self.enemy.synced_position = self.next_position
		return 1
	return 0

func detect() -> bool:
	if(self.enemy.detection_handler.check_for_priority_target()):
		state_changed.emit(self, "ability")
		return true
	return false
