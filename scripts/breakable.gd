extends CharacterBody2D
class_name Breakable

signal breakable_destroyed

var in_use: bool = false
var contained_pickup: int
var _exploded_barrier: bool = false

@rpc("call_local")
func disable_collison_and_hide():
	in_use = false
	self.hide()
	$Shape.set_deferred("disabled", 1)

@rpc("call_local")
func disable():
	self.hide()
	self.position = Vector2.ZERO

@rpc("call_local")
func place(pos: Vector2, pickup: int):
	assert(globals.is_not_pickup_seperator(pickup))
	assert(pickup != globals.pickups.RANDOM)
	$AnimationPlayer.play("RESET")
	contained_pickup = pickup
	in_use = true
	_exploded_barrier = false
	$Shape.set_deferred("disabled", 0)
	self.position = pos
	self.show()
	
@rpc("call_local")
func exploded(by_who):
	if _exploded_barrier: return #prevents a racecondition of the game attempting to spawn a pickup twice
	_exploded_barrier = true
	
	# I don't like the breakable sound. Will add a new one if I'm told to do so.
	# -Monsto
	#breakable_sfx_player.play()
	
	$AnimationPlayer.play("explode")
	await $AnimationPlayer.animation_finished #Wait for the animation to finish
	if globals.game.stage_done: return # if in the meantime the stage has finished the stage will have already reset this breakable hence stop this now

	# Spawn a powerup where this rock used to be.
	if is_multiplayer_authority():
		if contained_pickup != globals.pickups.NONE && by_who != gamestate.ENVIRONMENTAL_KILL_PLAYER_ID:
			var pickup: Pickup = globals.game.pickup_pool.request(contained_pickup)
			pickup.place.rpc(self.position)
		else:
			world_data.set_tile.rpc(world_data.tiles.EMPTY, global_position) #We only wanne delete this cell if no pickup is spawned on it
			
	breakable_destroyed.emit()
	if is_multiplayer_authority():
		disable_collison_and_hide.rpc()
	astargrid_handler.astargrid_set_point(global_position, false)
	if is_multiplayer_authority():
		disable.rpc()
		globals.game.breakable_pool.return_obj(self)

@rpc("call_local")
func crush():
	
	# may or may not re add this sound
	#crushed_sfx_player.play()
	
	$AnimationPlayer.play("crush")
	if is_multiplayer_authority():
		disable_collison_and_hide.rpc()
		world_data.set_tile.rpc(world_data.tiles.EMPTY, global_position)
	astargrid_handler.astargrid_set_point(global_position, false)
	await $AnimationPlayer.animation_finished #Wait for the animation to finish
	if globals.game.stage_done: return
	if is_multiplayer_authority():
		disable.rpc()
		globals.game.breakable_pool.return_obj(self)
	
func set_selected_sprite(new_path : String):
	$Sprite.texture = load(new_path)
