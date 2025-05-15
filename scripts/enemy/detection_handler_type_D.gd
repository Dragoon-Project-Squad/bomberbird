extends Area2D
# implements the detection of the player for Priority target 'D' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

@onready var enemy: Enemy = get_parent()
@onready var coll_shape: CollisionShape2D = get_node("CollisionShape2D")

var enabled: bool = false

func check_for_priority_target():
	if !enabled: 
		enemy.statemachine.target = null
		return false

	print("WYHWYWYWYHW")
	for body in self.get_overlapping_bodies():
		if !(body is Player): continue
		self.enemy.statemachine.target = body
		return true
	enemy.statemachine.target = null
	return false 

func on():
	enabled = true

func off():
	enabled = false
