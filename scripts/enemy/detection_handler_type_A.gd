class_name DetectionHandler extends Node2D
# implements the detection of the player for Priority target 'A' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

func check_for_priority_target():
	return false #Type A is no target hence we always just return false

func on():
	pass # Type A doesn't do anything anyway

func off():
	pass # Type A doesn't do anything anyway
