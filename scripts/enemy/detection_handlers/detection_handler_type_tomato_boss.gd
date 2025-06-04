extends Node2D
# implements the detection of the player for Priority target 'A' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

@onready var enemy: Enemy = get_parent()
@export var trigger_chance: float = 0.05
var _rand: RandomNumberGenerator = RandomNumberGenerator.new()
var is_on: bool = false

func make_ready() -> void:
	enemy.statemachine.target = globals.player_manager.get_children().filter(func (c): return c is Player)

func check_for_priority_target(force: bool = false):
	assert(self.enemy is Boss)
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return false
	if(world_data.is_tile(world_data.tiles.MINE, self.enemy.position)): return false
	var rand_val = _rand.randf()
	return on && self.enemy.cooldown_done && (force || rand_val < trigger_chance)

func on():
	is_on = true

func off():
	is_on = false
