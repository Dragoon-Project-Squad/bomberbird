extends EnemyState
# Handles knight's ability

var ability_duration: float = 4

func _enter() -> void:
	self.enemy.invulnerable = true
	self.enemy.stop_moving = true
	var ectoplasm: Node2D = self.enemy.get_node("Ectoplasm")
	var ectoplasm_direction: Vector2

	ectoplasm_direction = world_data.tile_map.map_to_local(
		world_data.tile_map.local_to_map(self.enemy.position)
		).direction_to(world_data.tile_map.map_to_local(
			world_data.tile_map.local_to_map(self.state_machine.target.position)
			)).normalized()
	match ectoplasm_direction:	
		Vector2.RIGHT:
			self.enemy.sprite.frame = 20
		Vector2.DOWN:
			self.enemy.sprite.frame = 0
		Vector2.LEFT:
			self.enemy.sprite.frame = 12
		Vector2.UP:
			self.enemy.sprite.frame = 6
	self.enemy.sprite.frame_changed.emit()

	self.enemy.anim_player.play("wisp/shake")
	self.enemy.current_anim = ""
	ectoplasm.start(ectoplasm_direction)

	await get_tree().create_timer(ability_duration).timeout
	ectoplasm.disable()
	if globals.game.stage_done || self.enemy.disabled: return

	state_changed.emit(self, "wander")

func _reset() -> void:
	self.enemy.stop_moving = false
	self.enemy.invulnerable = false

func _exit() -> void:
	self.enemy.anim_player.play(self.enemy.animation_sub + "/" + self.enemy.current_anim)
	self.enemy.current_anim = ""
	self.enemy.stop_moving = false
	self.enemy.invulnerable = false
