extends Node2D
# implements the detection of the player for Priority target 'B' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

@onready var enemy: Enemy = get_parent()

@export var range: int = 20

var enabled: bool = false

func check_for_priority_target():
	if !self.enabled: 
		self.enemy.statemachine.target = null
		return false

	for ray in get_children():
		if !(ray is RayCast2D): continue
		if !ray.is_colliding(): continue
		var target = ray.get_collider()
		if !(target is Player): continue
		if target.stop_movement: continue #if the player is in the hurt animation (or victory tho that should not happen)
		self.enemy.statemachine.target = target
		return true
	self.enemy.statemachine.target = null
	return false 

func recheck_priority_target(direction: Vector2):
	assert(self.enemy.statemachine.target, "rechecking priority target but there is no priority target")
	if !self.enabled:
		push_error("rechecking for priority target but detection handler is disabled")
		return false
	for ray in get_children():
		if direction.normalized() != ray.target_position.normalized(): continue
		if !ray.is_colliding(): 
			self.enemy.statemachine.target = null
			return false
		var target = ray.get_collider()
		if target is Player:
			self.enemy.statemachine.target = ray.get_collider()
			return true
		self.enemy.statemachine.target = null
		return false


func on():
	enabled = true
	for ray in get_children():
		if !(ray is RayCast2D): continue
		if self.enemy.bombthrought:
			ray.set_collision_mask_value(4, false)
		if self.enemy.wallthrought:
			ray.set_collision_mask_value(3, false)
		ray.target_position *= range * 32 
		ray.enabled = true

func off():
	enabled = false
	for ray in get_children():
		if !(ray is RayCast2D): continue
		ray.set_collision_mask_value(3, true)
		ray.set_collision_mask_value(4, true)
		ray.target_position = ray.target_position.normalized()
		ray.enabled = false
