class_name Player extends CharacterBody2D
## Base class for the player

signal player_health_updated
signal player_hurt
signal player_died
signal player_revived

## Player Movement Speed
const TILE_SIZE: int = 32
const BASE_MOTION_SPEED: float = (TILE_SIZE * 3.5)
const MAX_MOTION_SPEED: int = TILE_SIZE * 8
const MIN_MOTION_SPEED: int = TILE_SIZE * 2
@warning_ignore("INTEGER_DIVISION") #Note this integer division is fine idk why godot feels like it needs to warn for int divisions anyway?
const MOTION_SPEED_INCREASE: int = TILE_SIZE / 2
@warning_ignore("INTEGER_DIVISION") #Note this integer division is fine idk why godot feels like it needs to warn for int divisions anyway?
const MOTION_SPEED_DECREASE: int = TILE_SIZE / 2

const BOMB_RATE: float = 0.5
const MAX_BOMBS_OWNABLE: int = 8
const MAX_EXPLOSION_BOOSTS_PERMITTED: int = 6
## NOTE: MISOBON_RESPAWN_TIME is additive to the animation time for both spawning and despawning the misobon player
const MISOBON_RESPAWN_TIME: float = 0.5 
const INVULNERABILITY_SPAWN_TIME: float = 2
const INVULNERABILITY_FLASH_TIME: float = 0.125
const INVULNERABILITY_POWERUP_TIME: float = 16.0

@export var synced_position := Vector2()
@export var stunned: bool = false
@export var invulnerable: bool = false

@onready var hurt_sfx_player := $HurtSoundPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_anim: String = ""
var is_dead: bool = false
var stop_movement: bool = false
var time_is_stopped: bool = false
var player_type: String
var hurry_up_started: bool = false 
var misobon_player: MisobonPlayer

var game_ui

var invulnerable_animation_time: float
var invulnerable_remaining_time: float = 2

var pickup_pool: PickupPool
var bomb_pool: BombPool
var last_bomb_time: float = BOMB_RATE
var bomb_total: int
var bomb_to_throw: BombRoot
var bomb_kicked: BombRoot
var mine_placed: bool

@export_subgroup("player properties") #Set in inspector
@export var movement_speed: float = BASE_MOTION_SPEED
@export var bomb_count: int = 2
@export var lives: int = 1:
	set(val):
		lives = val
		if is_dead: return
		player_health_updated.emit(self, lives)

@export var explosion_boost_count: int = 0
@export var pickups: HeldPickups

var movement_speed_reset: float
var bomb_count_reset: int
var lives_reset: int
var explosion_boost_count_reset: int

var is_virus = false
@export var fire_range = 3
@export var fuse_speed := BombRoot.FUSES.NORMAL
var infected_explosion := false
var is_autodrop = false
var is_reverse = false
var is_nonstop = false
var is_unbomb = false
var drop_timer = 0
const AUTODROP_INTERVAL = 3

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
	explosion_boost_count_reset = explosion_boost_count
	if globals.current_gamemode == globals.gamemode.CAMPAIGN:
		player_health_updated.connect(func (s: Player, health: int): game_ui.update_health(health, int(s.name)))
	match globals.current_gamemode:
		globals.gamemode.CAMPAIGN: lives = 3
		globals.gamemode.BATTLEMODE: lives = 1
		_: lives = 1
	lives_reset = lives
	pickups.reset()
	self.animation_player.play("RESET")
	init_pickups()
	do_invulnerabilty()

func init_pickups():
	if !is_multiplayer_authority(): return
	for _speed_up in range(self.pickups.held_pickups[globals.pickups.SPEED_UP]):
		increase_speed.rpc()
	for _speed_down in range(self.pickups.held_pickups[globals.pickups.SPEED_DOWN]):
		decrease_speed.rpc()
	for _bomb_level_up in range(self.pickups.held_pickups[globals.pickups.FIRE_UP]):
		increase_bomb_level.rpc()
	for _bomb_count_up in range(self.pickups.held_pickups[globals.pickups.BOMB_UP]):
		increment_bomb_count.rpc()
	if self.pickups.held_pickups[globals.pickups.FULL_FIRE]:
		maximize_bomb_level.rpc()
	if self.pickups.held_pickups[globals.pickups.WALLTHROUGH]:
		enable_wallclip.rpc()
	if self.pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] == HeldPickups.exclusive.BOMBTHROUGH:
		enable_bombclip.rpc()
	if self.pickups.held_pickups[globals.pickups.INVINCIBILITY_VEST]:
		start_invul.rpc()
	if self.pickups.held_pickups[globals.pickups.VIRUS] > pickups.virus.DEFAULT:
		virus.rpc()

func _process(delta: float):
	if !invulnerable and !is_autodrop:
		show()
		set_process(false)
		return
	if invulnerable:
		invulnerable_remaining_time -= delta
		invulnerable_animation_time += delta
		if invulnerable_remaining_time <= 0:
			invulnerable = false
			pickups.held_pickups[globals.pickups.INVINCIBILITY_VEST] = false
		elif invulnerable_animation_time <= INVULNERABILITY_FLASH_TIME:
			self.visible = !self.visible
			invulnerable_animation_time = 0	
	if is_autodrop:
		drop_timer -= delta
		if drop_timer <= 0:
			drop_timer = AUTODROP_INTERVAL
			place_bomb()

func _physics_process(_delta: float):
	pass

func place(pos: Vector2):
	self.position = pos
	self.show()
	self.animation_player.play("RESET")
	do_invulnerabilty()

## executes the punch_bomb ability if the player has the appropiate pickup
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

func carry_bomb():
	if !pickups.held_pickups[globals.pickups.POWER_GLOVE]:
		return 1
	
	var bodies: Array[Node2D] = $FrontArea.get_overlapping_bodies()
	for body in bodies:
		if body is Bomb:
			bomb_to_throw = body.get_parent()
			break
	
	if bomb_to_throw == null or bomb_to_throw.type == pickups.bomb_types.MINE:
		bomb_to_throw = null
		return 2
	carry_bomb_effect.rpc()
	bomb_to_throw.carry.rpc()
	return 0

@rpc("call_local")
func carry_bomb_effect():
	$BombSprite.visible = true

func throw_bomb(direction: Vector2i):
	bomb_to_throw.do_throw.rpc(direction, self.position)
	bomb_to_throw = null
	throw_bomb_effect.rpc()
	return 0

@rpc("call_local")
func throw_bomb_effect():
	$BombSprite.visible = false

func kick_bomb(direction: Vector2i):
	if pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] != pickups.exclusive.KICK:
		return 1
	
	var bodies: Array[Node2D] = $FrontArea.get_overlapping_bodies()
	for body in bodies:
		if body is Bomb:
			var bomb_coords_fixed = (
				world_data.tile_map.map_to_local(
					world_data.tile_map.local_to_map(body.global_position)
				)
			)
			var player_coords_fixed = (
				world_data.tile_map.map_to_local(
					world_data.tile_map.local_to_map(self.global_position)
				)
			)
			# make sure the player and the bomb aren't in the same tile
			if player_coords_fixed == bomb_coords_fixed:
				return 1 
			bomb_kicked = body.get_parent()
			break
	if bomb_kicked == null or (bodies.is_empty() and bomb_kicked.state != bomb_kicked.SLIDING):
		return 1
	
	if bomb_kicked.bomb_owner != null and bomb_kicked.state == bomb_kicked.STATIONARY:
		bomb_kicked.do_kick.rpc(direction)
	elif bomb_kicked.state == bomb_kicked.SLIDING:
		bomb_kicked.stop_kick.rpc()
		bomb_kicked = null
	else:
		bomb_kicked = null

## places a bomb if the current position is valid
func place_bomb():
	if(world_data.is_tile(world_data.tiles.BOMB, self.global_position)): return
	
	var bombPos = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(synced_position))
	bomb_count -= 1
	last_bomb_time = 0
	
	# Adding bomb to astargrid so bombs have collision inside the grid
	astargrid_handler.astargrid_set_point(synced_position, true)
	
	if is_multiplayer_authority():
		var bomb: BombRoot = bomb_pool.request()
		bomb.set_bomb_owner.rpc(self.name)
		if pickups.held_pickups[globals.pickups.GENERIC_BOMB] == HeldPickups.bomb_types.MINE:
			if not mine_placed:
				bomb.set_bomb_type.rpc(HeldPickups.bomb_types.MINE)
				mine_placed = not mine_placed
			else:
				bomb.set_bomb_type.rpc(HeldPickups.bomb_types.DEFAULT)
		else:
			bomb.set_bomb_type.rpc(pickups.held_pickups[globals.pickups.GENERIC_BOMB])
		bomb.set_fuse_length.rpc(fuse_speed)
		bomb.do_place.rpc(bombPos, -1 if infected_explosion else explosion_boost_count)

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
		animation_player.play("player_animations/" + current_anim)

## Enables this players correspoing misobon player if misobon is atleast on
func enter_misobon():
	if SettingsContainer.misobon_setting == SettingsContainer.misobon_setting_states.OFF || hurry_up_started:
		return
	
	await get_tree().create_timer(MISOBON_RESPAWN_TIME).timeout
	#Check if nothing changed in the meantime
	if SettingsContainer.misobon_setting == SettingsContainer.misobon_setting_states.OFF || hurry_up_started:
		return
	
	if is_multiplayer_authority():
		if misobon_player == null:
			set_misobon.rpc()
		misobon_player.enable.rpc(
			misobon_player.get_parent().get_progress_from_vector(position) 
			)
		misobon_player.play_spawn_animation.rpc()

## Do crushed specific things to player
func do_crushed_state():
	is_dead = true
	hide()
	animation_player.play("player_animations/crush")
	$Hitbox.set_deferred("disabled", 1)
	await animation_player.animation_finished
	player_died.emit()
	process_mode = PROCESS_MODE_DISABLED


func enter_death_state():
	is_dead = true
	animation_player.play("player_animations/death")
	$Hitbox.set_deferred("disabled", 1)
	if globals.current_gamemode == globals.gamemode.BATTLEMODE:
		spread_items()
		reset_pickups()
	await animation_player.animation_finished
	player_died.emit()
	hide()
	process_mode = PROCESS_MODE_DISABLED

@rpc("call_local")
func exit_death_state():
	process_mode = PROCESS_MODE_INHERIT
	player_revived.emit()
	await get_tree().create_timer(MISOBON_RESPAWN_TIME).timeout
	animation_player.play("player_animations/revive")
	$Hitbox.set_deferred("disabled", 0)
	await animation_player.animation_finished
	stunned = false
	is_dead = false
	do_invulnerabilty()

@rpc("call_local")
func reset():
	process_mode = PROCESS_MODE_INHERIT
	player_revived.emit()
	animation_player.play("player_animations/revive")
	$Hitbox.set_deferred("disabled", 0)
	await animation_player.animation_finished
	stunned = false
	is_dead = false
	self.stop_movement = false
	self.time_is_stopped = false
	show()

## resets the pickups back to the inital state
func reset_pickups():
	movement_speed = movement_speed_reset
	bomb_count = bomb_count_reset
	lives = lives_reset
	player_health_updated.emit(self, lives)
	self.set_collision_mask_value(4, true)
	self.set_collision_mask_value(3, true)
	unvirus()
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
		
		if key == globals.pickups.GENERIC_BOMB:
			var pickup_type: int
			match pickups.held_pickups[key]:
				pickups.bomb_types.DEFAULT: continue
				pickups.bomb_types.PIERCING: pickup_type = globals.pickups.PIERCING
				pickups.bomb_types.MINE: pickup_type = globals.pickups.MINE
				#pickups.bomb_types.REMOTE: pickup_type = globals.pickups.REMOTE
				#pickups.bomb_types.SEEKER: pickup_type = globals.pickups.SEEKER
				_: 	push_error("invalid bomb_type on item spread") # this will crash the game so this bad
			pickup_types.push_back(pickup_type)
			pickup_count.push_back(1)
		
		if key == globals.pickups.GENERIC_EXCLUSIVE:
			var pickup_type: int
			match pickups.held_pickups[key]:
				pickups.exclusive.DEFAULT: continue
				pickups.exclusive.KICK: pickup_type = globals.pickups.KICK
				pickups.exclusive.BOMBTHROUGH: pickup_type = globals.pickups.BOMBTHROUGH
				_: push_error("invalid exclusive on item spread")
			pickup_types.push_back(pickup_type)
			pickup_count.push_back(1)
	
	var to_place_pickups: Dictionary = pickup_pool.request_group(pickup_count, pickup_types)
	for i in range(pickup_types.size()):
		if pickup_count[i] == 1:
			var pos = world_data.get_random_empty_tile()
			if pos == null: return
			pos = pos as Vector2 #This is a hack and also the reason to burn anything pythonic
			to_place_pickups[pickup_types[i]][0].place.rpc(pos)
			var temp: Array[Vector2] = [pos]
			world_data.reset_empty_cells.call_deferred(temp)
		else:
			var pos_array: Array = world_data.get_random_empty_tiles(pickup_count[i])
			var temp: Array[Vector2] = []
			for j in range(pos_array.size()):
				to_place_pickups[pickup_types[i]][j].place.rpc(pos_array[j])
				temp.append(pos_array[j])
			world_data.reset_empty_cells.call_deferred(temp)

## starts the invulnerability and its animation
func do_invulnerabilty():
	invulnerable_remaining_time = INVULNERABILITY_SPAWN_TIME
	invulnerable = true
	set_process(true)

func do_stun():
	animation_player.play("player_animations/stunned") #Note this animation sets stunned automatically

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
	movement_speed += MOTION_SPEED_INCREASE
	movement_speed = clamp(movement_speed, MIN_MOTION_SPEED, MAX_MOTION_SPEED)

@rpc("call_local")
func decrease_speed():
	movement_speed -= MOTION_SPEED_DECREASE
	movement_speed = clamp(movement_speed, MIN_MOTION_SPEED, MAX_MOTION_SPEED)

@rpc("call_local")
func enable_wallclip():
	self.set_collision_mask_value(3, false)

@rpc("call_local")
func enable_bombclip():
	self.set_collision_mask_value(4, false)

@rpc("call_local")
func disable_bombclip():
	self.set_collision_mask_value(4, true)

@rpc("call_local")
func increment_bomb_count():
	bomb_total = min(bomb_total+1, MAX_BOMBS_OWNABLE)
	bomb_count = min(bomb_count+1, bomb_total)

@rpc("call_local")
func return_bomb(is_mine := false):
	if pickups.held_pickups[globals.pickups.GENERIC_BOMB] == HeldPickups.bomb_types.MINE and is_mine:
		mine_placed = false
	bomb_count = min(bomb_count+1, bomb_total)

@rpc("call_local")
## plays the victory animation and stops the player from moving
func play_victory(reenable: bool) -> Signal:
	stunned = true
	animation_player.play("player_animations/victory")
	if reenable: animation_player.animation_finished.connect(func (_x): stunned = false, CONNECT_ONE_SHOT)
	return animation_player.animation_finished

func do_hurt() -> void:
	stop_movement = true
	animation_player.play("player_animations/death")
	await animation_player.animation_finished
	player_hurt.emit()
	stop_movement = false

@rpc("call_local")
## kills this player and awards whoever killed it
func exploded(_by_who):
	if stunned || invulnerable || stop_movement:
		return
	lives -= 1
	hurt_sfx_player.play()
	if lives <= 0:
		enter_death_state()
		enter_misobon()
	else:
		match globals.current_gamemode:
			globals.gamemode.BATTLEMODE: do_stun()
			globals.gamemode.CAMPAIGN: do_hurt()
			_: push_error("A player died while no gamemode was active")

@rpc("call_local")
func crush():
	do_crushed_state()

func set_selected_character(value_path : String):
	$sprite.texture = load(value_path)

@rpc("call_local")
func start_invul():
	invulnerable_remaining_time = INVULNERABILITY_POWERUP_TIME
	invulnerable = true
	set_process(true)

@rpc("call_local")
func virus():
	is_virus = true
	match pickups.held_pickups[globals.pickups.VIRUS]:
		pickups.virus.SPEEDDOWN:
			print("Slow movement!")
			movement_speed = max(BASE_MOTION_SPEED / 2, MIN_MOTION_SPEED) # Set MIN?
		pickups.virus.SPEEDUP:
			print("Fast movement!")
			movement_speed = min(BASE_MOTION_SPEED * 5, MAX_MOTION_SPEED)	# Set MAX?
		pickups.virus.FIREDOWN:
			print("Ultra-weak bombs!")
			infected_explosion = true
		pickups.virus.FASTFUSE:
			print("Fast fuse speed!")
			fuse_speed = BombRoot.FUSES.FAST
		pickups.virus.SLOWFUSE_A:
			print("Slow fuse speed!")
			fuse_speed = BombRoot.FUSES.SLOW_A
		pickups.virus.SLOWFUSE_B:
			print("Slow fuse speed!")
			fuse_speed = BombRoot.FUSES.SLOW_B
		pickups.virus.AUTOBOMB:
			print("Autodrop!")
			is_autodrop = true
			drop_timer = AUTODROP_INTERVAL
			set_process(true)
		pickups.virus.INVERSE_CONTROL:
			print("Reverse controls!")
			is_reverse = true
		pickups.virus.NON_STOP_MOTION:
			print("Can't stop moving!")
			is_nonstop = true
		pickups.virus.NOBOMBS:
			print("Bombs disabled!")
			is_unbomb = true
		_:
			print("unknown infection")

@rpc("call_local")	
func unvirus():
	is_virus = false
	infected_explosion = false
	fuse_speed = BombRoot.FUSES.NORMAL
	movement_speed = BASE_MOTION_SPEED
	is_autodrop = false
	is_reverse = false
	is_nonstop = false
	is_unbomb = false
	set_process(false)

func stop_time(user: String, is_player: bool):
	if is_player && user == self.name:
		self.pickups.held_pickups[globals.pickups.FREEZE] = false
		return
	self.time_is_stopped = true
	
func start_time():
	self.time_is_stopped = false
