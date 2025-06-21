extends EnemyState
# Handles enemies without ability

@export var invulnerable_time: float = 7

func _enter() -> void:
	self.enemy.invulnerable = true
	get_tree().create_timer(invulnerable_time - 1).timeout.connect(_end_ability, CONNECT_ONE_SHOT)
	self.enemy.stop_moving = true
	self.enemy.anim_player.play("slime/hide")

func _end_ability() -> void:
	if globals.game.stage_done || self.enemy.disabled: return
	self.enemy.anim_player.play("slime/show")
	await self.enemy.anim_player.animation_finished
	self.enemy.invulnerable = false 
	self.enemy.stop_moving = false
	if globals.game.stage_done: return
	if self.enemy.health == 0: return
	state_changed.emit(self, "wander")

func _reset() -> void:
	self.enemy.invulnerable = true
	self.enemy.stop_moving = true
