extends CharacterBody2D

const BASE_MOTION_SPEED = 100.0
const BOMB_RATE = 0.5
const MAX_BOMBS_OWNABLE = 99
const MISOBON_RESPAWN_TIME: float = 0.5

@export var synced_position := Vector2()
@export var stunned = false

@onready var hurt_sfx_player := $HurtSoundPlayer
@onready var inputs = $Inputs
var bomb_pool: Node2D

var last_bomb_time = BOMB_RATE
var current_anim = ""
var is_dead = false
var lives = 1
# Powerup Vars
var movement_speed = BASE_MOTION_SPEED
var explosion_boost_count := 0
var max_explosion_boosts_permitted := 3
var bomb_count := 3
var bomb_queue: Array[Node2D] = [] #note these are used as a Queue hence new items are always pushed to the back and items are always taken from the back
var bomb_active: Array[Node2D] = []
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
	bomb_pool = get_node("../../BombPool")
	if is_multiplayer_authority():
		bomb_queue = bomb_pool.request_bomb_array(self, bomb_count)
	#$sprite.texture = load("res://assets/player/dragoon_walk.png")


func _physics_process(delta):
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

	if not stunned and inputs.bombing and last_bomb_time >= BOMB_RATE:
		if tileMap != null:
			bombPos = tileMap.map_to_local(tileMap.local_to_map(synced_position))
					
		last_bomb_time = 0.0
		#take an unused bomb place it and put it into the active bomb bucket
		print(bomb_queue)
		var bomb = bomb_queue.pop_front()
		if bomb != null && is_multiplayer_authority():
			bomb.do_place.rpc(bombPos, explosion_boost_count)


	if not stunned:
		# Everybody runs physics. I.e. clients tries to predict where they will be during the next frame.
		velocity = inputs.motion.normalized() * movement_speed
		move_and_slide()

	# Also update the animation based on the last known player input state
	if !is_dead:
		update_animation(inputs.motion)
	

func update_animation(input_motion: Vector2):
	var new_anim = "standing"
	if input_motion.y < 0:
		new_anim = "walk_up"
	elif input_motion.y > 0:
		new_anim = "walk_down"
	elif input_motion.x < 0:
		new_anim = "walk_left"
	elif input_motion.x > 0:
		new_anim = "walk_right"
		
	if new_anim != current_anim:
		current_anim = new_anim
		$anim.play(current_anim)

func bomb_done(bomb: Node2D):
	if is_dead:
		bomb_pool.return_bomb(self, bomb)
		return

	bomb_queue.push_back(bomb)

func enter_death_state():
	$anim.play("death")
	if is_multiplayer_authority():
		bomb_pool.return_bomb_array(self, bomb_queue) #on death return all bombs that are not activly deployed
	await $anim.animation_finished
	process_mode = PROCESS_MODE_DISABLED
	
func exit_death_state():
	self.visible = true #Visible
	process_mode = PROCESS_MODE_INHERIT
	
func enter_misobon():
	if(!has_node("/root/MainMenu") && get_node("/root/Lobby").curr_misobon_state == 0):
			#in singlayer always just have it on SUPER for now (until we have options in sp) and in multiplayer spawn misobon iff its not off
		return

	await get_tree().create_timer(MISOBON_RESPAWN_TIME).timeout
	if is_multiplayer_authority():
		get_node("../../MisobonPlayerSpawner").spawn({
		"player_type": "human",
		"spawn_here": get_node("../../MisobonPath").get_progress_from_vector(synced_position),
		"pid": str(name).to_int(),
		"name": get_player_name()
		}).play_spawn_animation()


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
	if bomb_count < MAX_BOMBS_OWNABLE:
		bomb_count = bomb_count + 1
		if is_multiplayer_authority():
			bomb_queue.push_back(bomb_pool.request_bomb(self)) # bomb count is increased hence we request a new bomb from the pool as our own
	
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
	if by_who != gamestate.ENVIRONMENTAL_KILL_PLAYER_ID && str(by_who) == name: 
		$"../../GameUI".decrease_score(by_who) # Take away a point for blowing yourself up
	elif by_who != gamestate.ENVIRONMENTAL_KILL_PLAYER_ID:
		$"../../GameUI".increase_score(by_who) # Award a point to the person who blew you up
		#TODO notify other player of kill
	if lives <= 0:
		is_dead = true
		#TODO: Knockout Player
		enter_death_state()
		enter_misobon()
	else:
		get_node("anim").play("stunned")

func set_selected_character(value: Texture2D):
	$sprite.texture = value
