extends EnemyState
# Handles Hammer's ability


const ARRIVAL_TOLARANCE: float = 1
@onready var droppable_pickups: Array[int] = [
	globals.pickups.BOMB_UP,
	globals.pickups.FIRE_UP,
	globals.pickups.SPEED_UP,
	globals.pickups.INVINCIBILITY_VEST,
	#globals.pickup.HP_UP,
	]

@export var speed_boost: float = 2

var is_crushing: bool = false

func _enter() -> void:
	assert(self.state_machine.target, "entered an ability state without a valid target. Enemy: " + self.enemy.name)
	self.is_crushing = false
	self.enemy.movement_vector = world_data.tile_map.map_to_local(
		world_data.tile_map.local_to_map(self.enemy.position)
		).direction_to(world_data.tile_map.map_to_local(
			world_data.tile_map.local_to_map(self.state_machine.target.bomb_root.position)
			))


func _physics_update(delta: float) -> void:
	if self.is_crushing: return
	_move(delta, speed_boost)
	if _check_if_on_tile() && _check_arrival():
		do_crush()
	elif _check_if_on_tile() && !self.enemy.detection_handler.recheck_priority_target(self.enemy.movement_vector):
		state_changed.emit(self, "wander")

func _check_if_on_tile() -> bool:
	return self.enemy.position.distance_to(world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))) <= ARRIVAL_TOLARANCE

func _check_arrival():
	return self.enemy.position.distance_to(world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.state_machine.target.bomb_root.position))) <= ARRIVAL_TOLARANCE

func do_crush():
	self.is_crushing = true
	self.enemy.stop_moving = true
	self.enemy.anim_player.play("hammer/punch")
	self.enemy.current_anim = ""

	await self.enemy.anim_player.animation_finished
	if globals.game.stage_done || self.enemy.health <= 0: return
	if self.state_machine.target.is_exploded: return

	state_changed.emit(self, "wander")
	self.is_crushing = false
	self.enemy.stop_moving = false

func change_bomb():
	assert(self.state_machine.target.has_method("crush"))
	if self.state_machine.target.is_exploded: return
	if globals.game.stage_done || self.enemy.health <= 0: return
	self.state_machine.target.crush()

	var pickup: int = droppable_pickups.pick_random()
	var pickup_obj: Pickup = globals.game.pickup_pool.request(pickup)
	pickup_obj.place.rpc(self.enemy.position)
