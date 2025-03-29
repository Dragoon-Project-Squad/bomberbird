class_name HumanPlayer extends Player

@onready var inputs = $Inputs

var set_bomb_pressed_once := false
var punch_pressed_once := false

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

	if not stunned and inputs.punch_ability and not punch_pressed_once:
		punch_pressed_once = true
		var direction: Vector2i = Vector2i(inputs.motion.normalized()) if inputs.motion != Vector2.ZERO else Vector2i.DOWN
		punch_bomb(direction)
	elif !inputs.punch_ability and punch_pressed_once:
		punch_pressed_once = false

	if not stunned and inputs.bombing and bomb_count > 0 and not set_bomb_pressed_once:
		set_bomb_pressed_once = true
		place_bomb()
	elif !inputs.bombing and set_bomb_pressed_once:
		set_bomb_pressed_once = false

	if !is_dead && !stunned:
		# Everybody runs physics. I.e. clients tries to predict where they will be during the next frame.
		velocity = inputs.motion.normalized() * movement_speed
		move_and_slide()
		# Also update the animation based on the last known player input state
		update_animation(inputs.motion)
