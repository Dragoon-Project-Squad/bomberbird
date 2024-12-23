extends CharacterBody2D

const MOTION_SPEED = 130.0
const BOMB_RATE = 0.5

@export var synced_position := Vector2()
@export var stunned = false

@onready var inputs = $Inputs
@onready var hurt_sfx_player := $HurtSoundPlayer

var last_bomb_time = BOMB_RATE
var current_anim = ""
var is_bombing = false #TODO: Setup condition for AI to bomb, and include is_bombing

func _ready():
	stunned = false
	position = synced_position
	if str(name).is_valid_int():
		get_node("Inputs/InputsSync").set_multiplayer_authority(str(name).to_int())


func _physics_process(delta):
	# TODO: AI Controls Go Here

	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = position
		# And increase the bomb cooldown spawning one if the client wants to.
		last_bomb_time += delta
		if not stunned and is_multiplayer_authority() and is_bombing and last_bomb_time >= BOMB_RATE:
			last_bomb_time = 0.0
			get_node("../../BombSpawner").spawn([position, str(name).to_int()])
	else:
		# The client simply updates the position to the last known one.
		position = synced_position

	if not stunned:
		# Everybody runs physics. I.e. clients tries to predict where they will be during the next frame.
		velocity = inputs.motion.normalized() * MOTION_SPEED
		move_and_slide()

	# Also update the animation based on the last known player input state
	var new_anim = "standing"

	if inputs.motion.y < 0:
		new_anim = "walk_up"
	elif inputs.motion.y > 0:
		new_anim = "walk_down"
	elif inputs.motion.x < 0:
		new_anim = "walk_left"
	elif inputs.motion.x > 0:
		new_anim = "walk_right"

	if stunned:
		new_anim = "stunned"

	if new_anim != current_anim:
		current_anim = new_anim
		get_node("anim").play(current_anim)


func set_player_name(value):
	get_node("label").text = value


@rpc("call_local")
func exploded(_by_who):
	if stunned:
		return
	stunned = true
	hurt_sfx_player.play()
	get_node("anim").play("stunned")
