extends EnemyState
## Implements the wander behavior '2' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

const DEFAULT_IDLE_TIME: float = 0.5
const ARRIVAL_TOLARANCE: float = 1

var _rng = RandomNumberGenerator.new()
var idle_time: float = DEFAULT_IDLE_TIME
var next_position: Vector2

func _enter():
	self.idle = true;
	match _rng.randi_range(0, 3):
		0: self.enemy.movement_vector = Vector2.RIGHT
		1: self.enemy.movement_vector = Vector2.DOWN
		2: self.enemy.movement_vector = Vector2.LEFT
		3: self.enemy.movement_vector = Vector2.UP
	get_next_pos()

func _exit():
	idle_time = DEFAULT_IDLE_TIME
	idle = false

func _physics_update(delta):
	if self.idle:
		# Wait in idle for a set time after moving
		if(self.idle_time > 0):
			self.idle_time -= delta
		else:
			self.idle_time = DEFAULT_IDLE_TIME
			if(!get_next_pos()): return
			self.idle = false
	else:
		#Update position
		if multiplayer.multiplayer_peer == null or self.enemy.is_multiplayer_authority():
			# The server updates the position that will be notified to the clients.
			self.enemy.synced_position = self.enemy.position
		else:
			# The client simply updates the position to the last known one.
			self.enemy.position = self.enemy.synced_position
		
		# Also update the animation based on the last known player input state
		self.enemy.velocity = self.enemy.movement_vector.normalized() * self.enemy.movement_speed
		self.enemy.move_and_slide()
		if check_arrival():
			detect()
			idle = true

func get_next_pos() -> bool:
	var old_movement_vector: Vector2 = self.enemy.movement_vector
	for i in range(0, 3): #Try each direction
		self.next_position = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position) + self.enemy.movement_vector)
		if(world_data.is_tile(world_data.tiles.EMPTY, self.next_position)): return true
		self.enemy.movement_vector = Vector2(-self.enemy.movement_vector.y, self.enemy.movement_vector.x) #rotate pi/2 CW
	self.enemy.movement_vector = old_movement_vector
	self.next_position = world_data.tile_map.local_to_map(self.enemy.position)
	return false

func check_arrival() -> bool:
	return self.enemy.position.distance_to(self.next_position) <= ARRIVAL_TOLARANCE

func detect():
	if(self.enemy.detection_handler.check_for_priority_target()):
		state_changed.emit(self, "target")
