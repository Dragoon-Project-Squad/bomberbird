extends EnemyState
## Implements the wander behavior '2' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

const ARRIVAL_TOLARANCE: float = 1

var _rng = RandomNumberGenerator.new()
var next_position: Vector2

func _enter():
	match _rng.randi_range(0, 3):
		0: self.enemy.movement_vector = Vector2.RIGHT
		1: self.enemy.movement_vector = Vector2.DOWN
		2: self.enemy.movement_vector = Vector2.LEFT
		3: self.enemy.movement_vector = Vector2.UP
	self.next_position = get_next_pos()
	self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO

func _physics_update(_delta):
	#Update position
	if multiplayer.multiplayer_peer == null or self.enemy.is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		self.enemy.synced_position = self.enemy.position
	else:
		# The client simply updates the position to the last known one.
		self.enemy.position = self.enemy.synced_position
	
	# Also update the animation based on the last known player input state
	if self.enemy.stunned: return
	self.enemy.velocity = self.enemy.movement_vector.normalized() * self.enemy.movement_speed
	self.enemy.move_and_slide()
	if check_arrival():
		detect()
		self.next_position = get_next_pos()
		self.enemy.movement_vector = self.enemy.position.direction_to(self.next_position) if (self.next_position != self.enemy.position) else Vector2.ZERO

func get_next_pos() -> Vector2:

	var valid_pos_arr: Array[Vector2] = []
	var temp_movement_vector: Vector2 = self.enemy.movement_vector if self.enemy.movement_vector != Vector2.ZERO else Vector2.RIGHT
	for i in range(0, 4): #Try each direction
		var pos: Vector2 = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position) + Vector2i(temp_movement_vector))
		if(world_data.is_out_of_bounds(pos) == -1 && world_data.is_tile(world_data.tiles.EMPTY, pos)): 
			if i == 0: return pos
			if i == 2: return pos # this implements the main behaviour of type 3 always U-turn if possible
			valid_pos_arr.append(pos)
		temp_movement_vector = Vector2(-temp_movement_vector.y, temp_movement_vector.x) #rotate pi/2 CW

	if len(valid_pos_arr) == 0: return self.enemy.position
	# weigthed picking of random direction (weigthed in favor or the rightmost choice)
	var rand_val = _rng.randi_range(1, 2 ** len(valid_pos_arr))
	for i in range(len(valid_pos_arr)):
		if 2 ** (len(valid_pos_arr) - 1 - i) <= rand_val: 
			self.enemy.get_node("DebugMarker").position = valid_pos_arr[i]
			return valid_pos_arr[i]
	push_error("get_next_pos does not return a valid vector")
	return self.enemy.position


func check_arrival() -> bool:
	if self.enemy.position.distance_to(self.next_position) <= ARRIVAL_TOLARANCE:
		self.enemy.position = self.next_position
		self.enemy.synced_position = self.next_position
		return 1
	return 0

func detect():
	if(self.enemy.detection_handler.check_for_priority_target()):
		state_changed.emit(self, "ability")
