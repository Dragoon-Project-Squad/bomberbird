extends EnemyState
# Handles knight's ability

const ARRIVAL_TOLARANCE: float = 1

@export var speed_boost: float = 2

func _enter() -> void:
	assert(self.state_machine.target, "entered an ability state without a valid target. Enemy: " + self.enemy.name)
	self.enemy.movement_vector = world_data.tile_map.map_to_local(
		world_data.tile_map.local_to_map(self.enemy.position)
		).direction_to(world_data.tile_map.map_to_local(
			world_data.tile_map.local_to_map(self.state_machine.target.bomb_root.position)
			))


func _physics_update(_delta: float) -> void:
	#Update position
	if self.enemy.stop_moving: return
	if multiplayer.multiplayer_peer == null or self.enemy.is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		self.enemy.synced_position = self.enemy.position
	else:
		# The client simply updates the position to the last known one.
		self.enemy.position = self.enemy.synced_position
	
	# Also update the animation based on the last known player input state
	if self.enemy.stunned: return
	self.enemy.velocity = self.enemy.movement_vector.normalized() * self.enemy.movement_speed * speed_boost
	self.enemy.move_and_slide()
	if _check_if_on_tile() && check_arrival():
		do_crush()
	elif _check_if_on_tile() && !self.enemy.detection_handler.recheck_priority_target(self.enemy.movement_vector):
		state_changed.emit(self, "wander")

func _check_if_on_tile() -> bool:
	return self.enemy.position.distance_to(world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))) <= ARRIVAL_TOLARANCE

func check_arrival():
	return self.enemy.position.distance_to(world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.state_machine.target.bomb_root.position))) <= ARRIVAL_TOLARANCE

func do_crush():
	self.enemy.stop_moving = true
	self.enemy.anim_player.play("hammer/punch")
	await self.enemy.anim_player.animation_finished
	self.enemy.stop_moving = false
	state_changed.emit(self, "wander")

func change_bomb():
	assert(self.state_machine.target.has_method("crush"))
	self.state_machine.target.crush()
