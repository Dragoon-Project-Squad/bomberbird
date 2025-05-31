extends Node2D
# implements the detection of the player for Priority target 'A' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

@onready var enemy: Enemy = get_parent()
@export var trigger_chance: float = 0.05
var _rand: RandomNumberGenerator = RandomNumberGenerator.new()
var is_on: bool = false

func check_for_priority_target():
	enemy.statemachine.target = null
	return on && _rand.randf() < trigger_chance

func on():
	is_on = true

func off():
	is_on = false
