extends EnemyState
## Implements the wander behavior '1' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

const DEFAULT_PATH_FINDING_TIMEOUT: float = 0.5
const ARRIVAL_TOLARANCE: float = 1
const STARTING_CLOSENESS: int = 2

var next_position: Vector2
var curr_path: Array[Vector2] = []
var path_finding_timeout: float = 0
var closeness = STARTING_CLOSENESS

func _enter():
	if curr_path == []:
		curr_path = get_next_path()
	self.next_position = get_next_pos(curr_path)
	self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO

func _physics_update(delta):
	#Update position
	if multiplayer.multiplayer_peer == null or self.enemy.is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		self.enemy.synced_position = self.enemy.position
	else:
		# The client simply updates the position to the last known one.
		self.enemy.position = self.enemy.synced_position
	
	path_finding_timeout += delta

	# Also update the animation based on the last known player input state
	if self.enemy.stunned: return
	self.enemy.velocity = self.enemy.movement_vector.normalized() * self.enemy.movement_speed
	self.enemy.move_and_slide()
	if check_arrival() && len(curr_path) == 0 && path_finding_timeout >= DEFAULT_PATH_FINDING_TIMEOUT:
		if detect(): return
		curr_path = get_next_path()
		path_finding_timeout = 0
		self.next_position = get_next_pos(curr_path)
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO
	elif check_arrival():
		self.next_position = get_next_pos(curr_path)
		if !world_data.is_safe(self.enemy.position, false):
			curr_path = get_dodge_path()
			path_finding_timeout = 0
			self.next_position = get_next_pos(curr_path)
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO

func valid_tile(pos: Vector2) -> bool:
	if world_data.is_out_of_bounds(pos) != -1: return false
	var ret: bool = world_data.is_tile(world_data.tiles.EMPTY, pos) || world_data.is_tile(world_data.tiles.PICKUP, pos)
	ret = ret || world_data.is_tile(world_data.tiles.MINE, pos)
	ret = ret || (self.enemy.wallthrought || self.enemy.pickups.held_pickups[globals.pickups.WALLTHROUGH]) && world_data.is_tile(world_data.tiles.BREAKABLE, pos)
	ret = ret || (self.enemy.bombthrought || self.enemy.pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] == HeldPickups.exclusive.BOMBTHROUGH) && world_data.is_tile(world_data.tiles.BOMB, pos)
	return ret

func get_next_path() -> Array[Vector2]:
	var path: Array[Vector2] = world_data.get_random_path(self.enemy.position, 10)

	if !path.is_empty():
		self.enemy.get_node("DebugMarker").position = path[-1]
		path.pop_front()
	else:
		self.enemy.get_node("DebugMarker").position = self.enemy.position

	print("choosen path ", path)

	return path 

func get_dodge_path() -> Array[Vector2]:
	var path: Array[Vector2] = world_data.get_path_to_safe(self.enemy.position)

	if !path.is_empty():
		self.enemy.get_node("DebugMarker").position = path[-1]
		path.pop_front()
	else:
		self.enemy.get_node("DebugMarker").position = self.enemy.position

	print("choosen path ", path)

	return path 

func get_next_pos(path: Array[Vector2]) -> Vector2:
	if len(path) != 0 && valid_tile(path[0]): 
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
