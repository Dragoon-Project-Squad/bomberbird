extends EnemyState
# Handles knight's ability

const ARRIVAL_TOLARANCE: float = 1

@export var speed_boost: float = 3

func _enter() -> void:
	assert(self.state_machine.target, "entered an ability state without a valid target. Enemy: " + self.enemy.name)
	self.enemy.movement_vector = world_data.tile_map.map_to_local(
		world_data.tile_map.local_to_map(self.enemy.position)
		).direction_to(world_data.tile_map.map_to_local(
			world_data.tile_map.local_to_map(self.state_machine.target.position)
			))


func _physics_update(delta: float) -> void:
	_move(delta, speed_boost)
	if _check_if_on_tile() && !self.enemy.detection_handler.recheck_priority_target(self.enemy.movement_vector):
		state_changed.emit(self, "wander")

func _check_if_on_tile() -> bool:
	return self.enemy.position.distance_to(world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))) <= ARRIVAL_TOLARANCE
