extends Node2D
# implements the detection of the player for Priority target 'E' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

@onready var enemy: Enemy = get_parent()

func check_for_priority_target():
	var target = globals.player_manager.get_children().filter(func (x): return x is Player).pick_random()
	enemy.statemachine.target = target
	return true

func on():
	pass

func off():
	pass
