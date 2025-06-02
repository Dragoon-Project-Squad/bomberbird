extends Node2D
# implements the detection of the player for Priority target 'A' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

@onready var enemy: Enemy = get_parent()
@export var trigger_chance: float = 0.05
var _rand: RandomNumberGenerator = RandomNumberGenerator.new()
var is_on: bool = false

func make_ready() -> void:
	enemy.statemachine.target = []
	for child in globals.player_manager.get_children():
		if !(child is Player): continue
		enemy.statemachine.target.append(child)

func check_for_priority_target():
	assert(self.enemy is Boss)
	var verify_path: Array[Vector2] = world_data.get_random_path(self.enemy.position, 6)
	var rand_val = _rand.randf()
	return on && self.enemy.cooldown_done && rand_val < trigger_chance && len(verify_path) == 6

func on():
	is_on = true

func off():
	is_on = false
