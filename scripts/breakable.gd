extends CharacterBody2D
class_name Breakable

signal breakable_destroyed
@onready var breakable_sfx_player: AkEvent2D = $BreakableSound

const TILESIZE := 32
const KNOWN_VINTAGE_PATH := "res://assets/tilesetimages/vintage_obstacles.png"
var collisions_array := []

var in_use: bool = false
var contained_pickup: int
var _exploded_barrier: bool = false
var pushed: bool = false
var direction: Vector2
var new_position := Vector2.ZERO

func _physics_process(delta: float) -> void:
	if pushed:
		velocity = direction * TILESIZE * 5
		var collide = move_and_collide(velocity * delta)
		if new_position and (global_position - new_position).dot(direction) >= 0:
			global_position = new_position
			remove_collision_exception_with(self)
			if collisions_array.size() > 0:
				collisions_array.map(func(body): remove_collision_exception_with(body))
				collisions_array.clear()
			pushed = false
			new_position = Vector2.ZERO
		elif collide:
			var hit_obj := collide.get_collider()
			new_position = world_data.tile_map.local_to_map(collide.get_position())
			if hit_obj is Player or hit_obj is Enemy:
				if not hit_obj.stunned:
					hit_obj.do_stun()
					add_collision_exception_with(hit_obj)
					collisions_array.append(hit_obj)
			elif hit_obj is Breakable:
				hit_obj.push(direction)
				new_position -= direction
			if hit_obj is TileMapLayer:
				new_position = world_data.tile_map.local_to_map(global_position)
			new_position = world_data.tile_map.map_to_local(new_position)

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
func place(pos: Vector2, pickup: int, texture_path: String):
	assert(globals.is_not_pickup_seperator(pickup))
	assert(pickup != globals.pickups.RANDOM)

	# Turns the obstacles in the vintage stage black and white using the vintage shader.
	# IDK why it's loading only the saloon obstacles when the stage is set to vintage, but whatever.
	if texture_path == KNOWN_VINTAGE_PATH:
		apply_vintage_shader()
	$Sprite.texture = load(texture_path)
	
	$AnimationPlayer.play("RESET")
	contained_pickup = pickup
	in_use = true
	_exploded_barrier = false
	$Shape.set_deferred("disabled", 0)
	self.position = pos
	self.show()

func apply_vintage_shader() -> void:
	$Sprite.set_material(load("res://scenes/stages/vintage_stages/vintage.tres"))

@rpc("call_local")
func exploded(by_who):
	if _exploded_barrier: return #prevents a racecondition of the game attempting to spawn a pickup twice
	_exploded_barrier = true
	
	#posts the breakable sound event.
	breakable_sfx_player.post_event()
	
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
		astargrid_handler.astargrid_set_point.rpc(global_position, false)
		disable.rpc()
		globals.game.breakable_pool.return_obj(self)

@rpc("call_local")
func crush():
	
	# may or may not re add this sound
	#crushed_sfx_player.play()
	breakable_sfx_player.post_event()
	
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

@rpc("call_local")
func push(direction: Vector2i):
	if !is_multiplayer_authority(): return
	self.direction = direction
	pushed = true
	add_collision_exception_with(self)
