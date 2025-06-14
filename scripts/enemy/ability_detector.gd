extends Area2D

enum ability { KICK, PUNCH, THROW, NONE }

@export_group("usage_probability")
@export var use_ability: float = 0.1
@export var stop_kick: float = 0.1
@export var do_throw: float = 0.1

@onready var enemy = get_parent()

var _rand: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	assert(enemy is Boss)

func check_ability_usage() -> int:
	self.enemy.curr_bomb = get_bomb()
	if self.enemy.curr_bomb == null: return ability.NONE
	if self.enemy.curr_bomb.type == HeldPickups.bomb_types.MINE: return ability.NONE
	var probability: float = _rand.randf()
	if use_ability <= probability: return ability.NONE
	var abilities: Array[int] = []
	if enemy.pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] == HeldPickups.exclusive.KICK:
		abilities.append(ability.KICK)
	if enemy.pickups.held_pickups[globals.pickups.BOMB_PUNCH]:
		abilities.append(ability.PUNCH)
	if enemy.pickups.held_pickups[globals.pickups.POWER_GLOVE]:
		if self.enemy.bomb_to_throw == null:
			abilities.append(ability.THROW)
	if abilities.is_empty(): return ability.NONE
	return abilities.pick_random()

func get_bomb() -> BombRoot:
	var bodies: Array[Node2D] = get_overlapping_bodies()
	bodies.filter(func (body): return (body is Bomb) && !body.mine)
	if bodies.is_empty(): return null
	return bodies.pick_random().get_parent()

func check_throw() -> bool:
	if self.enemy.bomb_to_throw == null: return false
	return do_throw >= _rand.randf()

func check_stop_kick() -> bool:
	if self.enemy.kicked_bomb == null: return false
	return stop_kick >= _rand.randf()
