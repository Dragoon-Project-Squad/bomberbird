class_name Player extends CharacterBody2D
## Base class for the player

signal player_died
signal player_revived

const BASE_MOTION_SPEED: float = 100.0
const MOTION_SPEED_INCREASE: float = 20.0
const BOMB_RATE: float = 0.5
const MAX_BOMBS_OWNABLE: int = 8
const MAX_EXPLOSION_BOOSTS_PERMITTED: int = 6
## NOTE: MISOBON_RESPAWN_TIME is additive to the animation time for both spawning and despawning the misobon player
const MISOBON_RESPAWN_TIME: float = 0.5 
const INVULNERABILITY_TIME: float = 2
const INVULNERABILITY_FLASH_TIME: float = 0.125

@export var synced_position := Vector2()
@export var stunned: bool = false
@export var invulnerable: bool = false

@onready var hurt_sfx_player := $HurtSoundPlayer

var current_anim: String = ""
var is_dead: bool = false
var player_type: String
var hurry_up_started: bool = false 
var misobon_player: MisobonPlayer

var game_ui: CanvasLayer

var invulnerable_animation_time: float
var invulnerable_total_time: float = 2

var pickup_pool: PickupPool
var bomb_pool: BombPool
var last_bomb_time: float = BOMB_RATE
var bomb_total: int

@export_subgroup("player properties") #Set in inspector
@export var movement_speed: float = BASE_MOTION_SPEED
@export var bomb_count: int = 2
@export var lives: int = 1
@export var explosion_boost_count: int = 0
@export var pickups: HeldPickups

var movement_speed_reset: float
var bomb_count_reset: int
var lives_reset: int
var explosion_boost_count_reset: int


func _ready():
	player_died.connect(globals.player_manager._on_player_died)
	player_revived.connect(globals.player_manager._on_player_revived)

	position = synced_position
	bomb_total = bomb_count
	bomb_pool = globals.game.bomb_pool
	pickup_pool = globals.game.pickup_pool
	game_ui = globals.game.game_ui

	movement_speed_reset = movement_speed
	bomb_count_reset = bomb_count
	lives_reset = lives
	explosion_boost_count_reset = explosion_boost_count


func _process(delta: float):
	if !invulnerable:
		show()
		set_process(false)
		return
	invulnerable_total_time += delta
	invulnerable_animation_time += delta
	if invulnerable_total_time >= INVULNERABILITY_TIME:
		invulnerable = false
	elif invulnerable_animation_time >= INVULNERABILITY_FLASH_TIME:
		self.visible = !self.visible
		invulnerable_animation_time = 0
	

func _physics_process(_delta: float):
	pass

## executes the punch_bomb ability iff the player has the appropiate pickup
func punch_bomb(direction: Vector2i):
	if !is_multiplayer_authority():
		return
	if !pickups.held_pickups[globals.pickups.BOMB_PUNCH]:
		return
	
	var bodies: Array[Node2D] = $FrontArea.get_overlapping_bodies()
	var bomb: BombRoot
	for body in bodies:
		if !body is Bomb: continue
		bomb = body.get_parent()
		break
	
	if bomb == null: return

	bomb.do_punch.rpc(direction)

## places a bomb iff the current position is valid
func place_bomb():
	if(world_data.is_tile(world_data.tiles.BOMB, self.global_position)): return
	
	var bombPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(synced_position))
	bomb_count -= 1
	last_bomb_time = 0
	
	# Adding bomb to astargrid so bombs have collision inside the grid
	astargrid_handler.astargrid_set_point(synced_position, true)
	
	if is_multiplayer_authority():
		var bomb: BombRoot = bomb_pool.request([])
		bomb.set_bomb_owner.rpc(self.name)
		bomb.do_place.rpc(bombPos, explosion_boost_count)

## updates the animation depending on the movement direction
func update_animation(direction: Vector2):
	var new_anim: String = "standing"
	if direction.length() == 0:
		new_anim = "standing"
	elif direction.y < 0:
		new_anim = "walk_up"
	elif direction.y > 0:
		new_anim = "walk_down"
	elif direction.x < 0:
		new_anim = "walk_left"
	elif direction.x > 0:
		new_anim = "walk_right"
		
	if new_anim != current_anim:
		current_anim = new_anim
		$AnimationPlayer.play("player_animations/" + current_anim)

## Eneables this players correspoing misobon player iff misobon is atleast on
func enter_misobon():
	if gamestate.misobon_mode == gamestate.misobon_states.OFF || hurry_up_started:
		return
	
	
	await get_tree().create_timer(MISOBON_RESPAWN_TIME).timeout
	#Check if nothing changed in the meantime
	if gamestate.misobon_mode == gamestate.misobon_states.OFF || hurry_up_started:
		return
	
	if is_multiplayer_authority():
		if misobon_player == null:
			set_misobon.rpc()
		misobon_player.enable.rpc(
			misobon_player.get_parent().get_progress_from_vector(position) 
			)
		misobon_player.play_spawn_animation.rpc()

func enter_death_state():
	is_dead = true
	$AnimationPlayer.play("player_animations/death")
	$Hitbox.set_deferred("disabled", 1)
	spread_items() #TODO: Check if battlemode
	reset_pickups()
	await $AnimationPlayer.animation_finished
	player_died.emit()
	hide()
	process_mode = PROCESS_MODE_DISABLED
	
@rpc("call_local")
func exit_death_state():
	process_mode = PROCESS_MODE_INHERIT
	player_revived.emit()
	await get_tree().create_timer(MISOBON_RESPAWN_TIME).timeout
	$AnimationPlayer.play("player_animations/revive")
	$Hitbox.set_deferred("disabled", 0)
	await $AnimationPlayer.animation_finished
	stunned = false
	is_dead = false
	do_invulnerabilty()

## resets the pickups back to the inital state
func reset_pickups():
	movement_speed = movement_speed_reset
	bomb_count = bomb_count_reset
	lives = lives_reset
	explosion_boost_count = explosion_boost_count_reset
	pickups.reset()

## spreads all pickups the player held on the ground
func spread_items():
	if !is_multiplayer_authority():
		return
	
	var pickup_types: Array[int] = []
	var pickup_count: Array[int] = []
	
	for key in pickups.held_pickups:
		if key < globals.pickups.GENERIC_COUNT:
			var count: int = pickups.held_pickups[key]
			if count == 0: continue
			pickup_types.push_back(key)
			pickup_count.push_back(count)
	
		elif globals.pickups.GENERIC_COUNT < key && key < globals.pickups.GENERIC_BOOL:
			if !pickups.held_pickups[key]: continue
			pickup_types.push_back(key)
			pickup_count.push_back(1)
	
	#TODO: add pickups for exclusive pickups
	
	var to_place_pickups: Dictionary = pickup_pool.request_group(pickup_count, pickup_types)
	for i in range(pickup_types.size()):
		if pickup_count[i] == 1:
			var pos = world_data.get_random_empty_tile()
			if pos == null: return
			pos = pos as Vector2 #This is a hack and also the reason to burn anything pythonic
			to_place_pickups[pickup_types[i]][0].place.rpc(pos)
		else:
			var pos_array: Array = world_data.get_random_empty_tiles(pickup_count[i])
			for j in range(pos_array.size()):
				to_place_pickups[pickup_types[i]][j].place.rpc(pos_array[j])

## starts the invulnerability and its animation
func do_invulnerabilty():
	invulnerable_total_time = 0
	invulnerable = true
	set_process(true)
	
func do_stun():
	$AnimationPlayer.play("player_animations/stunned") #Note this animation sets stunned automatically

@rpc("call_local")
func set_misobon():
	misobon_player = get_node("../../MisobonPath/" + str(self.name))

func set_player_name(value):
	$label.set_text(value)

func get_player_name() -> String:
	return $label.get_text()
	
@rpc("call_local")
func increase_bomb_level():
	explosion_boost_count = min(explosion_boost_count + 1, MAX_EXPLOSION_BOOSTS_PERMITTED)
	
@rpc("call_local")
func maximize_bomb_level():
	explosion_boost_count = min(explosion_boost_count + 99, MAX_EXPLOSION_BOOSTS_PERMITTED)
	
@rpc("call_local")
func increase_speed():
	movement_speed = movement_speed + 20

@rpc("call_local")
func increment_bomb_count():
	bomb_total = min(bomb_total+1, MAX_BOMBS_OWNABLE)
	bomb_count = min(bomb_count+1, bomb_total)
	

@rpc("call_local")
func return_bomb():
	bomb_count = min(bomb_count+1, bomb_total)

@rpc("call_local")
## kills this player and awards whoever killed it
func exploded(by_who):
	if stunned || invulnerable:
		return
	lives -= 1
	hurt_sfx_player.play()
	if by_who != gamestate.ENVIRONMENTAL_KILL_PLAYER_ID && str(by_who) == name: 
		game_ui.decrease_score(by_who) # Take away a point for blowing yourself up
	elif by_who != gamestate.ENVIRONMENTAL_KILL_PLAYER_ID:
		game_ui.increase_score(by_who) # Award a point to the person who blew you up
	if lives <= 0:
		enter_death_state()
		enter_misobon()
	else:
		do_stun()

func set_selected_character(value_path : String):
	$sprite.texture = load(value_path)
