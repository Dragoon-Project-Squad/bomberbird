extends EnemyState
# Handles knight's ability

const ABILITY_LENGTH: float = 5
const TILESIZE: int = 32

@export var magnet_strength: float = 164
@export var ability_time: float = 0

func _enter() -> void:
	assert(self.state_machine.target, "entered an ability state without a valid target. Enemy: " + self.enemy.name)
	ability_time = 0
	self.enemy.stop_moving = true
	self.enemy.anim_player.play("magnet/spin")

func _physics_update(delta: float) -> void:
	var pull_dir: Vector2 = -world_data.tile_map.map_to_local(
		world_data.tile_map.local_to_map(self.enemy.position)
		).direction_to(world_data.tile_map.map_to_local(
			world_data.tile_map.local_to_map(self.state_machine.target.position)
			))
	var pull_dist: float = world_data.tile_map.local_to_map(self.enemy.position).distance_to(
		world_data.tile_map.local_to_map(self.state_machine.target.position)
		)
	self.enemy.statemachine.target.velocity = pull_dir.normalized() * magnet_strength * 1 / (pull_dist + 1)
	self.enemy.statemachine.target.move_and_slide()
	if ability_time >= ABILITY_LENGTH || !self.enemy.detection_handler.recheck_priority_target(-pull_dir):
		state_changed.emit(self, "wander")
	else:
		ability_time += delta

func _reset() -> void:
	ability_time = 0
	self.enemy.stop_moving = false

func _exit() -> void:
	ability_time = 0
	self.enemy.stop_moving = false
	self.enemy.anim_player.play(self.enemy.animation_sub + "/" + self.enemy.current_anim)
