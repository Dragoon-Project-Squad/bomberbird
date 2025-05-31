extends Node2D
# implements the detection of the player for Priority target 'A' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

@onready var enemy: Enemy = get_parent()
var enabled: bool = false

func check_for_priority_target():
	if !enabled: 
		enemy.statemachine.target = null
		return false
	for ray in get_children():
		if !(ray is RayCast2D): continue
		if !ray.is_colliding(): continue
		var target = ray.get_collider()
		if !(target is Bomb): continue # Doing it this way may cause some problems if bomb changes state away from stationary which will need to be handled
		enemy.statemachine.target = target
		return true
	enemy.statemachine.target = null
	return false 

func recheck_priority_target(direction: Vector2):
	assert(self.enemy.statemachine.target, "rechecking priority target but there is no priority target")
	if !self.enabled:
		push_error("rechecking for priority target but detection handler is disabled")
		return false
	for ray in get_children():
		if direction.normalized() != ray.target_position.normalized(): continue
		ray.force_raycast_update()
		if !ray.is_colliding(): 
			self.enemy.statemachine.target = null
			return false
		var target = ray.get_collider()
		if target is Bomb:
			self.enemy.statemachine.target = target
			return true
		self.enemy.statemachine.target = null
		return false

func on():
	enabled = true
	for ray in get_children():
		if !(ray is RayCast2D): continue
		ray.enabled = true

func off():
	enabled = false
	for ray in get_children():
		if !(ray is RayCast2D): continue
		ray.enabled = false
