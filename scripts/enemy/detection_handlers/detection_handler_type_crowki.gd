extends Node2D
# implements the detection of the player for Priority target 'A' described in https://gamefaqs.gamespot.com/snes/562899-super-bomberman-5/faqs/79457

enum abiltiy { NONE, BOMB, PICKUP }

@onready var enemy: Enemy = get_parent()
@export var trigger_chance_bomb: float = 0.05
@export var trigger_chance_pickup: float = 0.05

var _rand: RandomNumberGenerator = RandomNumberGenerator.new()
var is_on: bool = false
var curr_ability: int

func make_ready() -> void:
	enemy.statemachine.target = globals.player_manager.get_children().filter(func (c): return c is Player)

func check_for_priority_target(force: bool = false) -> int:
	assert(self.enemy is Boss)
	if world_data.is_tile(world_data.tiles.BOMB, self.enemy.position): return abiltiy.NONE
	if world_data.is_tile(world_data.tiles.MINE, self.enemy.position): return abiltiy.NONE 

	var rand_val = _rand.randf()
	var safe_tiles: Array[int] = [world_data.tiles.EMPTY, world_data.tiles.PICKUP]
	if self.enemy.wallthrought || self.enemy.pickups.held_pickups[globals.pickups.WALLTHROUGH]:
		safe_tiles.append(world_data.tiles.BREAKABLE)
	if self.enemy.bombthrought || self.enemy.pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] == HeldPickups.exclusive.BOMBTHROUGH:
		safe_tiles.append(world_data.tiles.BOMB)
	var is_safe_to: bool = world_data.is_safe_placement(self.enemy.position, 3, safe_tiles)
	if is_on && self.enemy.cooldown_done && is_safe_to && (force || rand_val < trigger_chance_bomb + trigger_chance_pickup):
		if (force && rand_val < 1 / (trigger_chance_bomb + trigger_chance_pickup) * trigger_chance_bomb) || rand_val < trigger_chance_bomb:
			curr_ability = abiltiy.BOMB
			return abiltiy.BOMB
		else:
			curr_ability = abiltiy.PICKUP
			return abiltiy.PICKUP
	curr_ability = abiltiy.NONE	
	return abiltiy.NONE

func on():
	is_on = true

func off():
	is_on = false
