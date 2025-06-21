extends EnemyState
# Handles Bomb Eater's ability

const ARRIVAL_TOLARANCE: float = 1

@export var speed_boost: float = 2

func _enter() -> void:
	assert(self.state_machine.target, "entered an ability state without a valid target. Enemy: " + self.enemy.name)
	self.enemy.movement_vector = world_data.tile_map.map_to_local(
		world_data.tile_map.local_to_map(self.enemy.position)
		).direction_to(world_data.tile_map.map_to_local(
			world_data.tile_map.local_to_map(self.state_machine.target.bomb_root.position)
			))


func _physics_update(delta: float) -> void:
	_move(delta, speed_boost)
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
	if globals.game.stage_done || self.enemy.health <= 0: return
	self.enemy.stop_moving = false
	state_changed.emit(self, "wander")

func change_bomb():
	assert(self.state_machine.target.has_method("crush"))
	if self.state_machine.target.is_exploded: return
	if globals.game.stage_done || self.enemy.disabled: return
	self.state_machine.target.crush()
