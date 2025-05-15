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
