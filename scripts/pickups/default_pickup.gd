class_name Pickup extends Area2D
@onready var pickup_sfx: AudioStreamWAV = load("res://sound/fx/powerup.wav")
@onready var pickup_sfx_player = $PickupSoundPlayer
@onready var animated_sprite = $AnimatedSprite2D
@onready var collisionbox: CollisionShape2D = $CollisionShape2D

var _pickup_pick_up_barrier: bool = false
var in_use: bool = false
var pickup_type: int = globals.pickups.NONE:
	set(type): #i don't like setters but it only enforces something here so its okey
		assert(globals.is_valid_pickup(type))
		if pickup_type != globals.pickups.NONE:
			push_error("private member pickup_type should only be overwritten once")
		pickup_type = type

func _ready():
	pass

@rpc("call_local")
func disable_collison_and_hide():
	in_use = false
	hide()
	world_data.set_tile(world_data.tiles.EMPTY, self.global_position)
	collisionbox.set_deferred("disabled", 1)

@rpc("call_local")
func enable_collison():
	collisionbox.set_deferred("disabled", 0)

@rpc("call_local")
func disable():
	hide()
	self.position = Vector2.ZERO
	process_mode = PROCESS_MODE_DISABLED

func enable():
	in_use = true
	process_mode = PROCESS_MODE_INHERIT
	_pickup_pick_up_barrier = false
	enable_collison()
	show()

@rpc("call_local")
func place(pos: Vector2):
	self.position = pos
	world_data.set_tile(world_data.tiles.PICKUP, self.global_position)
	enable()

## applies the power up to the player handed to it
func apply_power_up(_pickup_owner: Player):
	pass #default pickup has no effect

## if the body is a player proceed to cause the effect this pickup causes
func _on_body_entered(body: Node2D) -> void:
	if !is_multiplayer_authority(): return # Activate only on authority.
	if _pickup_pick_up_barrier: return
	_pickup_pick_up_barrier = true
	if !body.is_in_group("player") && !body.is_in_group("ai_player"): return
	#Prevent anyone else from colliding with this pickup
	pickup_sfx_player.play()
	disable_collison_and_hide.rpc()
	
	var pickup_owner: Player = body as Player
	pickup_owner.pickups.add(pickup_type)
	apply_power_up(pickup_owner)
	
	# Ensure powerup has time to play before pickup is destroyed
	await pickup_sfx_player.finished
	globals.game.pickup_pool.return_obj(self) #Pickup returns itself to the pool
	disable_collison_and_hide.rpc()
	disable.rpc()

@rpc("call_local")
## called when this pickup is destroyed by an explosion players the corresponding animation and sound
func exploded(_from_player):
	globals.game.pickup_pool.return_obj(self) #Pickup returns itself to the pool
	disable_collison_and_hide()
	if $anim:
		$anim.play("pickup/explode_pickup")
		await $anim.animation_finished
	disable()

@rpc("call_local")
## called when a pickup is destroyed by something that is not an explosion
func crush():
	disable_collison_and_hide()
	globals.game.pickup_pool.return_obj(self) #Pickup returns itself to the pool
	disable()
