extends EnemyState
# Handles warp ability

@export var warp_time: float = 1.5
@export var after_warp_time: float = 0.5

func _enter() -> void:
	self.enemy.invulnerable = true
	self.enemy.stop_moving = true
	var target_pos = world_data.get_random_empty_tile(false, false)

	if target_pos == null:
		state_changed.emit(self, "wander")
		return
	if target_pos in globals.player_manager.get_alive_players().map(func(p): return p.position):
		state_changed.emit(self, "wander")
		return
	self.enemy.anim_player.play("wisp/shake")
	await get_tree().create_timer(warp_time).timeout
	if globals.game.stage_done || self.enemy.disabled: return

	self.enemy.position = target_pos
	self.enemy.synced_position = target_pos

	await get_tree().create_timer(after_warp_time).timeout
	if globals.game.stage_done || self.enemy.disabled: return
	self.enemy.anim_player.play(self.enemy.animation_sub + "/" + self.enemy.current_anim)

	state_changed.emit(self, "wander")
	return


func _exit() -> void:
	self.enemy.invulnerable = false
	self.enemy.stop_moving = false
