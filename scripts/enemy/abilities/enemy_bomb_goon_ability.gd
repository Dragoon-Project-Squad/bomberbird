extends EnemyState
# Handles enemies without ability

func _enter() -> void:
	if(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)): return
	self.enemy.stop_moving = true
	self.enemy.invulnerable = true

	if self.enemy.movement_vector.y < 0:
		self.enemy.anim_player.play("bomb_goon/close_up")
	elif self.enemy.movement_vector.x < 0:
		self.enemy.anim_player.play("bomb_goon/close_left")
	elif self.enemy.movement_vector.x > 0:
		self.enemy.anim_player.play("bomb_goon/close_right")
	else:
		self.enemy.anim_player.play("bomb_goon/close_down")

	self.enemy.current_anim = ""
	var bombPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(self.enemy.position))

	await self.enemy.anim_player.animation_finished
	if globals.game.stage_done || self.enemy.disabled: return
	if !(world_data.is_tile(world_data.tiles.BOMB, self.enemy.position)):

		astargrid_handler.astargrid_set_point(self.enemy.position, true)
		var bomb: BombRoot = globals.game.bomb_pool.request()
		bomb.set_bomb_owner("")
		bomb.set_bomb_type(HeldPickups.bomb_types.DEFAULT)
		bomb.do_place(bombPos, 0)

		self.enemy.sprite.hide()

		await bomb.bomb_finished
	else:
		await get_tree().create_timer(3).timeout
	if globals.game.stage_done || self.enemy.disabled: return

	self.enemy.sprite.show()

	if self.enemy.movement_vector.y < 0:
		self.enemy.anim_player.play_backwards("bomb_goon/close_up")
	elif self.enemy.movement_vector.x < 0:
		self.enemy.anim_player.play_backwards("bomb_goon/close_left")
	elif self.enemy.movement_vector.x > 0:
		self.enemy.anim_player.play_backwards("bomb_goon/close_right")
	else:
		self.enemy.anim_player.play_backwards("bomb_goon/close_down")

	await self.enemy.anim_player.animation_finished
	if globals.game.stage_done || self.enemy.disabled: return

	self.enemy.anim_player.play("bomb_goon/RESET")
	self.enemy.current_anim = ""

	await self.enemy.anim_player.animation_finished
	if globals.game.stage_done || self.enemy.disabled: return

	self.enemy.invulnerable = false
	self.enemy.stop_moving = false

	state_changed.emit(self, "wander")

func _reset() -> void:
	self.enemy.invulnerable = false
	self.enemy.stop_moving = false
