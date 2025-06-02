class_name Pickup extends Area2D
@onready var pickup_sfx: AudioStreamWAV = load("res://sound/fx/powerup.wav")
@onready var explosion_sfx: AudioStreamWAV = load("res://sound/fx/explosion.wav")
@onready var pickup_sfx_player: AudioStreamPlayer = $PickupSoundPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
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
	hide()
	self.position = Vector2.ZERO
	pass

@rpc("call_local")
func disable_collison_and_hide():
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
	in_use = false

func enable():
	in_use = true
	process_mode = PROCESS_MODE_INHERIT
	_pickup_pick_up_barrier = false
	enable_collison()
	show()

@rpc("call_local")
func place(pos: Vector2):
	assert(self.position == Vector2.ZERO && self.visible == false, str(name) + " wasn't properly disabled or is still on the field but its attempted to re-place it")
	self.position = pos
	world_data.set_tile(world_data.tiles.PICKUP, self.global_position)
	enable()

## applies the power up to the player handed to it
func apply_power_up(_pickup_owner: Player):
	pass #default pickup has no effect

## if the body is a player proceed to cause the effect this pickup causes
func _on_body_entered(body: Node2D) -> void:
	if !is_multiplayer_authority(): return # Activate only on authority.
	if !(body is Player) && !(body is Boss): return
	if _pickup_pick_up_barrier: return
	_pickup_pick_up_barrier = true
	#Prevent anyone else from colliding with this pickup
	pickup_sfx_player.stream = pickup_sfx
	pickup_sfx_player.play()
	disable_collison_and_hide.rpc()
	
	var pickup_owner = body
	pickup_owner.pickups.add(pickup_type)
	if body is Player:
		apply_power_up(pickup_owner)
	
	# Ensure powerup has time to play before pickup is destroyed
	await pickup_sfx_player.finished
	disable_collison_and_hide.rpc()
	disable.rpc()
	globals.game.pickup_pool.return_obj.call_deferred(self) #Pickup returns itself to the pool

@rpc("call_local")
## called when this pickup is destroyed by an explosion players the corresponding animation and sound
func exploded(_from_player):
	disable_collison_and_hide()
	if $anim:
		$anim.play("pickup/explode_pickup")
		pickup_sfx_player.stream = explosion_sfx
		pickup_sfx_player.play()
		await $anim.animation_finished
		if pickup_sfx_player.playing:
			await pickup_sfx_player.finished
	disable()
	globals.game.pickup_pool.return_obj(self) #Pickup returns itself to the pool

@rpc("call_local")
## called when a pickup is destroyed by something that is not an explosion
func crush():
	disable_collison_and_hide()
	disable()
	globals.game.pickup_pool.return_obj(self) #Pickup returns itself to the pool
