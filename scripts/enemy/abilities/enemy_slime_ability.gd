extends EnemyState
# Handles enemies without ability

@export var invulnerable_time: float = 7

func _enter() -> void:
	print("entered slime ability")
	self.enemy.invulnerable = true
	get_tree().create_timer(invulnerable_time - 1).timeout.connect(_end_ability, CONNECT_ONE_SHOT)
	self.enemy.stop_moving = true
	self.enemy.anim_player.play("slime/hide")

func _end_ability() -> void:
	self.enemy.anim_player.play("slime/show")
	await self.enemy.anim_player.animation_finished
	self.enemy.invulnerable = false 
	self.enemy.stop_moving = false
	state_changed.emit(self, "wander")
