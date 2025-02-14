extends Player

@onready var inputs = $Inputs

var pressed_once := false
# Tracking Vars

func _ready():
	player_type = "human"
	if str(name).is_valid_int():
		get_node("Inputs/InputsSync").set_multiplayer_authority(str(name).to_int())
	super()

func _physics_process(delta: float):
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update()

	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = position
		# And increase the bomb cooldown spawning one if the client wants to.
		last_bomb_time += delta
	else:
		# The client simply updates the position to the last known one.
		position = synced_position

	if not stunned and inputs.bombing and bomb_count > 0 and !pressed_once:
		var bombPos = tile_map.map_to_local(tile_map.local_to_map(synced_position))
		pressed_once = true
		bomb_count -= 1
		if is_multiplayer_authority():
			var bomb = bomb_pool.request(self)
			bomb.do_place.rpc(bombPos, explosion_boost_count)
	elif !inputs.bombing and pressed_once:
		pressed_once = false

	if not stunned:
		# Everybody runs physics. I.e. clients tries to predict where they will be during the next frame.
		velocity = inputs.motion.normalized() * movement_speed
		move_and_slide()

	# Also update the animation based on the last known player input state
	if !is_dead:
		update_animation(inputs.motion)
