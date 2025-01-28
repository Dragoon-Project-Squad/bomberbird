extends CharacterBody2D

const BASE_MOTION_SPEED = 100.0
const BOMB_RATE = 0.5
const MAX_BOMBS_OWNABLE = 99

@export var synced_position := Vector2()
@export var stunned = false

@onready var hurt_sfx_player := $HurtSoundPlayer
@onready var inputs = $Inputs

var last_bomb_time = BOMB_RATE
var current_anim = ""
var is_dead = false
var lives = 1
# Powerup Vars
var movement_speed = BASE_MOTION_SPEED
var explosion_boost_count := 0
var max_explosion_boosts_permitted := 2
var bomb_count := 3
var can_punch := false
# Tracking Vars
var tileMap : TileMapLayer
var bombPos := Vector2()

func _ready():
	stunned = false
	position = synced_position
	if str(name).is_valid_int():
		get_node("Inputs/InputsSync").set_multiplayer_authority(str(name).to_int())
	tileMap = get_parent().get_parent().get_node("Floor")


func _physics_process(delta):
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update()

	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = position
		# And increase the bomb cooldown spawning one if the client wants to.
		last_bomb_time += delta
		if not stunned and is_multiplayer_authority() and inputs.bombing and last_bomb_time >= BOMB_RATE:
			if tileMap != null:
				bombPos = tileMap.map_to_local(tileMap.local_to_map(synced_position))
				
			last_bomb_time = 0.0
			get_node("../../BombSpawner").spawn([bombPos, str(name).to_int(), explosion_boost_count])
	else:
		# The client simply updates the position to the last known one.
		position = synced_position

	if not stunned:
		# Everybody runs physics. I.e. clients tries to predict where they will be during the next frame.
		velocity = inputs.motion.normalized() * movement_speed
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
	

func enter_death_state():
	self.visible = false #Invisible
	process_mode = PROCESS_MODE_DISABLED
	
func exit_death_state():
	self.visible = true #Visible
	process_mode = PROCESS_MODE_INHERIT

func set_player_name(value):
	$label.set_text(value)

func get_player_name() -> String:
	return $label.get_text()
	
@rpc("call_local")
func increase_bomb_level():
	explosion_boost_count = min(explosion_boost_count + 1, max_explosion_boosts_permitted)
	
@rpc("call_local")
func maximize_bomb_level():
	explosion_boost_count = min(explosion_boost_count + 99, max_explosion_boosts_permitted)
	
@rpc("call_local")
func increase_speed():
	movement_speed = movement_speed + 20

@rpc("call_local")
func increment_bomb_count():
	#TODO: Add code that makes bomb count matter.
	bomb_count = min(bomb_count+1, MAX_BOMBS_OWNABLE)
	
@rpc("call_local")
func enable_punch():
	can_punch = true

@rpc("call_local")
func exploded(by_who):
	if stunned:
		return
	stunned = true
	lives -= 1
	hurt_sfx_player.play()
	if str(by_who) == get_player_name():
		$"../../GameUI".decrease_score(by_who) # Take away a point for blowing yourself up
	else:
		$"../../GameUI".increase_score(by_who) # Award a point to the person who blew you up
	get_node("anim").play("stunned")
	if lives <= 0:
		is_dead = true
		#TODO: Knockout Player
		enter_death_state()
