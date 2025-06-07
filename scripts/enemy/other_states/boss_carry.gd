extends EnemyState

func _enter() -> void:
	if !is_multiplayer_authority(): return
	assert(self.enemy is Boss)
	if !self.enemy.pickups.held_pickups[globals.pickups.POWER_GLOVE]:
		done()
		return
	var bomb: BombRoot = self.enemy.curr_bomb
	if world_data.tile_map.local_to_map(bomb.position) == world_data.tile_map.local_to_map(self.enemy.position): 
		done()
		return

	self.enemy.movement_vector = self.enemy.position.direction_to(bomb.position)
	self.enemy.update_animation(self.enemy.movement_vector)
	await get_tree().create_timer(0.2).timeout
	if self.enemy.health != 0 && !bomb.state_map[1].is_exploded:
		self.enemy.bomb_carry_sprite.show()
		bomb.carry.rpc()
		self.enemy.bomb_to_throw = bomb
	await get_tree().create_timer(0.01).timeout

	done()
	return


func done():
	if !world_data.is_safe(self.enemy.position):
		state_changed.emit(self, "dodge")
	else:
		state_changed.emit(self, "wander")
