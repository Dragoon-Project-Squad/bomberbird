extends EnemyState

func _enter() -> void:
	if !is_multiplayer_authority(): return
	assert(self.enemy is Boss)
	if self.enemy.pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] != HeldPickups.exclusive.KICK: 
		done()
		return
	var bomb: BombRoot = self.enemy.curr_bomb
	if world_data.tile_map.local_to_map(bomb.position) == world_data.tile_map.local_to_map(self.enemy.position): 
		done()
		return

	self.enemy.movement_vector = self.enemy.position.direction_to(bomb.position)
	var direction = self.enemy.movement_vector

	self.enemy.update_animation(self.enemy.movement_vector)
	await get_tree().create_timer(0.2).timeout
	if self.enemy.health != 0 && !bomb.state_map[1].is_exploded:
		bomb.do_kick.rpc(direction)
		self.enemy.kicked_bomb = bomb
	await get_tree().create_timer(0.01).timeout

	done()
	return


func done():
	if !world_data.is_safe(self.enemy.position):
		state_changed.emit(self, "dodge")
	else:
		state_changed.emit(self, "wander")
