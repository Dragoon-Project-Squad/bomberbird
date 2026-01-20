class_name Player extends CharacterBody2D
## Base class for the player

signal player_health_updated
signal player_hurt(player: Player)
signal player_died(player: Player)
signal player_revived(player: Player)
signal player_mounted(player: Player)

## Player Movement Speed
const TILE_SIZE: int = 32
const BASE_MOTION_SPEED: float = (TILE_SIZE * 3.5)
const MAX_MOTION_SPEED: int = TILE_SIZE * 8
const MIN_MOTION_SPEED: int = TILE_SIZE * 2
@warning_ignore("INTEGER_DIVISION") #Note this integer division is fine idk why godot feels like it needs to warn for int divisions anyway?
const MOTION_SPEED_INCREASE: int = TILE_SIZE / 2
@warning_ignore("INTEGER_DIVISION") #Note this integer division is fine idk why godot feels like it needs to warn for int divisions anyway?
const MOTION_SPEED_DECREASE: int = TILE_SIZE / 2

const MAX_HEALTH: int = 9

const BOMB_RATE: float = 0.5
const MAX_BOMBS_OWNABLE: int = 8
const MAX_EXPLOSION_BOOSTS_PERMITTED: int = 6
## NOTE: MISOBON_RESPAWN_TIME is additive to the animation time for both spawning and despawning the misobon player
const MISOBON_RESPAWN_TIME: float = 0.5 
const INVULNERABILITY_SPAWN_TIME: float = 2
const INVULNERABILITY_POWERUP_TIME: float = 16.0

@export var synced_position := Vector2()
@export var stunned: bool = false
@export var invulnerable: bool = false
@export var time_is_stopped: bool = false
@export var is_dead: bool = false
@export var stop_movement: bool = false

@onready var hurt_sfx_player := $HurtSoundPlayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var invul_player: AnimationPlayer = $InvulPlayer

@onready var mount_step_timer := $MountStepTimer

var current_anim: String = ""
var is_mounted: bool = false
var _died_barrier: bool = false
var outside_of_game: bool = false

var player_type: String
var hurry_up_started: bool = false 
var misobon_player: MisobonPlayer
var last_movement_vector: Vector2 = Vector2(1, 0):
	set(val):
		if val.length() == 0: return
		last_movement_vector = val

var game_ui

var invul_timer: SceneTreeTimer

var pickup_pool: PickupPool
var bomb_pool: BombPool
var last_bomb_time: float = BOMB_RATE
var bomb_total: int
var bomb_to_throw: BombRoot
var bomb_kicked: BombRoot
var mine_placed: bool
var remote_bombs: Array[int]
var spritepaths: Dictionary
var remote_bomb_id: int = 0

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
var bomb_total_reset: int
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
var pre_virus_speed = BASE_MOTION_SPEED
const AUTODROP_INTERVAL = 3

enum mount_ability {NONE = 0, BREAKABLEPUSH, JUMP, MOUNTKICK, RAPIDBOMB, CHARGE, PUNCH}
var current_mount_ability := 0
var jump_config: Dictionary[String, Variant] = {
	"direction": Vector2.ZERO,
	"origin": Vector2.ZERO,
	"target":Vector2.ZERO,
	"time": 0.0,
	"total_time": 0.75,
	"shadow_offset": Vector2.ZERO,
	"shadow_relpos": Vector2.ZERO,
}
var is_jumping := false

func _ready():
	player_died.connect(globals.player_manager._on_player_died)
	player_revived.connect(globals.player_manager._on_player_revived)

	position = synced_position
	bomb_total = bomb_count
	bomb_pool = globals.game.bomb_pool
	pickup_pool = globals.game.pickup_pool
	game_ui = globals.game.game_ui

	movement_speed_reset = movement_speed
	bomb_total_reset = bomb_total
	explosion_boost_count_reset = explosion_boost_count
	remote_bombs.resize(8)
	if globals.is_singleplayer():
		player_health_updated.connect(func (s: Player, health: int): game_ui.update_health(health, int(s.name)))
	match globals.current_gamemode:
		globals.gamemode.CAMPAIGN: lives = 3
		globals.gamemode.BOSSRUSH: lives = 3
		globals.gamemode.BATTLEMODE: lives = 1
		_: lives = 1
	lives_reset = lives
	pickups.reset()
	self.animation_player.play("RESET")
	init_pickups()
	if is_multiplayer_authority():
		do_invulnerabilty.rpc()

func init_pickups():
	if !is_multiplayer_authority(): return
	for _speed_up in range(self.pickups.held_pickups[globals.pickups.SPEED_UP]):
		increase_speed.rpc()
	for _speed_down in range(self.pickups.held_pickups[globals.pickups.SPEED_DOWN]):
		decrease_speed.rpc()
	for _health_up in range(self.pickups.held_pickups[globals.pickups.HP_UP]):
		increase_live.rpc()
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
		do_invulnerabilty.rpc(INVULNERABILITY_POWERUP_TIME)
	if self.pickups.held_pickups[globals.pickups.VIRUS] > pickups.virus.DEFAULT:
		virus.rpc()
	if self.pickups.held_pickups[globals.pickups.MOUNTGOON]:
		mount_dragoon.rpc()

func _process(delta: float):
	if !is_autodrop:
		set_process(false)
		return
	if is_autodrop:
		drop_timer -= delta
		if drop_timer <= 0:
			drop_timer = AUTODROP_INTERVAL
			place_bomb()

func _physics_process(_delta: float):
	pass

@rpc("call_local")
func add_pickup(pickup_type: int):
	pickups.add(pickup_type)
	
	# plays the pickup sound event
	Wwise.post_event("snd_pickup_powerup", self)

func place(pos: Vector2):
	process_mode = PROCESS_MODE_INHERIT
	self.position = pos
	self.show()
	self.animation_player.play("RESET")
	await animation_player.animation_finished
	if is_multiplayer_authority():
		do_invulnerabilty.rpc()
	_died_barrier = false

#region all bomb functions

## executes the punch_bomb ability if the player has the appropiate pickup
func punch_bomb(direction: Vector2i):
	if !is_multiplayer_authority():
		return
	if(globals.game.stage_done): return
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
	if(globals.game.stage_done): return
	if not pickups.held_pickups[globals.pickups.POWER_GLOVE]:
		return 1
	if not is_multiplayer_authority(): return 5
	if bomb_to_throw != null: # this is really bad how'd this happen
		printerr("Player tried to carry a carried bomb.")
		bomb_to_throw.disable.rpc()
		bomb_pool.return_obj(bomb_to_throw)
		return 2

	bomb_to_throw = bomb_pool.request()
	bomb_to_throw.set_bomb_owner.rpc(self.name)
	bomb_to_throw.set_bomb_type.rpc(pickups.bomb_types.DEFAULT)
	bomb_to_throw.set_fuse_length.rpc(fuse_speed)
	bomb_to_throw.carry.rpc()
	carry_bomb_effect.rpc()
	return 0

@rpc("call_local")
func carry_bomb_effect():
	$BombSprite.visible = true

func throw_bomb(direction: Vector2i):
	if(globals.game.stage_done): return
	if bomb_to_throw == null: return
	bomb_to_throw.do_throw.rpc(direction, self.position)
	bomb_to_throw = null
	throw_bomb_effect.rpc()
	bomb_count -= 1
	return 0

@rpc("call_local")
func throw_bomb_effect():
	$BombSprite.visible = false

func kick_bomb(direction: Vector2i):
	if(globals.game.stage_done): return
	if pickups.held_pickups[globals.pickups.GENERIC_EXCLUSIVE] != pickups.exclusive.KICK and current_mount_ability != mount_ability.MOUNTKICK:
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

func call_remote_bomb():
	if !is_multiplayer_authority(): return
	if pickups.held_pickups[globals.pickups.GENERIC_BOMB] != pickups.bomb_types.REMOTE: return
	emit_remote_call_bomb.rpc()

@rpc("call_local")
func emit_remote_call_bomb():
	if remote_bombs.is_empty(): return
	globals.player_manager.remote_call_bomb.emit(str(self.name), remote_bombs.pop_front()) #removing the element here is fine since the return bomb func calls erase and erase will just do nothing if the element is not in the array

## places a bomb if the current position is valid
func place_bomb(line_direction := Vector2.ZERO):
	if(globals.game.stage_done): return
	if(world_data.is_tile(world_data.tiles.BOMB, self.global_position)): return
	var place_count := 0
	while bomb_count > 0:
		var bombPos = world_data.tile_map.local_to_map(synced_position)
		bomb_count -= 1
		last_bomb_time = 0
		if line_direction:
			bombPos += Vector2i(line_direction * place_count)
			place_count += 1
		bombPos = world_data.tile_map.map_to_local(bombPos)
		if (
				world_data.is_out_of_bounds(bombPos) != world_data.bounds.IN
				or not world_data.is_tile(world_data.tiles.EMPTY, bombPos)
		):
			bomb_count += 1
			break
		# Adding bomb to astargrid so bombs have collision inside the grid
		astargrid_handler.astargrid_set_point(bombPos, true)
		
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

			if pickups.held_pickups[globals.pickups.GENERIC_BOMB] == pickups.bomb_types.REMOTE:
				bomb.set_bomb_number.rpc(remote_bomb_id)
				register_remote_bomb.rpc()
			bomb.set_fuse_length.rpc(fuse_speed)
			bomb.do_place.rpc(bombPos, -1 if infected_explosion else explosion_boost_count)
		
		if not line_direction:
			break

@rpc("call_local")
func register_remote_bomb():
	remote_bombs.push_back(remote_bomb_id)
	remote_bomb_id += 1

#endregion

#region mount abilities
## kick a breakable
func kick_breakable(direction: Vector2i):
	if globals.game.stage_done: return
	if current_mount_ability != mount_ability.BREAKABLEPUSH: return
	
	var bodies: Array[Node2D] = $FrontArea.get_overlapping_bodies()
	var box_pushed: Breakable
	for body in bodies:
		if body is Breakable:
			box_pushed = body
			break
	if box_pushed == null:
		return 1
	box_pushed.push.rpc(direction)

## punch any enemy in front of the player
func punch_enemy():
	if globals.game.stage_done: return
	if current_mount_ability != mount_ability.PUNCH: return
	
	var bodies: Array[Node2D] = $FrontArea.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("do_stun"):
			body.do_stun.rpc()

## calculates and configs the jump parameters
func mounted_jump(direction: Vector2):
	if globals.game.stage_done: return
	if current_mount_ability != mount_ability.JUMP: return
	jump_config.direction = direction
	jump_config.origin = global_position
	var target = global_position + (direction * TILE_SIZE * 2)
	var landing_check := func checker(pos: Vector2) -> bool:
		return (
			world_data.is_out_of_bounds(pos) == world_data.bounds.IN
			and (
			world_data.is_tile(world_data.tiles.EMPTY, pos)
			or world_data.is_tile(world_data.tiles.PICKUP, pos)
			)
		)
		
	while not landing_check.call(target):
		target -= direction * 4
		if global_position.direction_to(target) != direction:
			target = global_position
			break
	if world_data.tile_map.map_to_local(global_position) == world_data.tile_map.map_to_local(target):
		target = global_position
	else:
		if not landing_check.call(target + direction * 16):
			target -= direction * 12
		if not landing_check.call(target - direction * 16):
			target += direction * 12

	jump_config.target = target
	jump_config.shadow_offset = $shadowsprite.global_position
	jump_config.shadow_relpos = $shadowsprite.position
	invulnerable = true
	is_jumping = true

## The actual jump animation function. Should be called in [param _physics_process]
func mounted_jump_process(delta: float) -> void:
	jump_config.time += delta
	var origin: Vector2 = jump_config.origin
	var target: Vector2 = jump_config.target
	var weight: float = jump_config.time / jump_config.total_time
	var curve := Vector2.ZERO
	var midpoint := Vector2.ZERO
	if jump_config.direction == Vector2.LEFT or jump_config.direction == Vector2.RIGHT:
		midpoint = Vector2((origin.x + target.x) / 2, origin.y - (TILE_SIZE * 0.9))
	else:
		midpoint = Vector2(origin.x, (origin.y + target.y) / 2 - (TILE_SIZE * 1.5))
	curve = (origin.lerp(midpoint, weight)).lerp(midpoint.lerp(target, weight), weight)
	var shadow: Sprite2D = $shadowsprite
	if jump_config.time <= jump_config.total_time:
		global_position = curve
		# show where the player is landing
		if jump_config.direction == Vector2.UP or jump_config.direction == Vector2.DOWN:
			shadow.global_position.x = jump_config.shadow_offset.x
		else:
			shadow.global_position.y = jump_config.shadow_offset.y
	else:
		position = jump_config.target
		shadow.position = jump_config.shadow_relpos
		jump_config.time = 0.0
		is_jumping = false
		invulnerable = false

#endregion

## updates the animation depending on the movement direction
func update_animation(direction: Vector2, old_direction: Vector2):
	var new_anim: String = "standing_down"
	if direction.length() == 0:
		assert(old_direction.length() != 0)
		if old_direction.y < 0:
			new_anim = "standing_up"
		elif old_direction.y > 0:
			new_anim = "standing_down"
		elif old_direction.x < 0:
			new_anim = "standing_left"
		elif old_direction.x > 0:
			new_anim = "standing_right"
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
		print_debug("Player can't misobon! The rules won't let it happen!")
		return
	
	print_debug("Waiting " + str(MISOBON_RESPAWN_TIME) + " to respawn player...")
	await get_tree().create_timer(MISOBON_RESPAWN_TIME).timeout
	#Check if nothing changed in the meantime
	if SettingsContainer.misobon_setting == SettingsContainer.misobon_setting_states.OFF || hurry_up_started:
		print_debug("Player can't misobon! The rules won't let it happen!")
		return
	
	if is_multiplayer_authority():
		if misobon_player == null:
			set_misobon.rpc()
		misobon_player.enable.rpc(
			misobon_player.get_parent().get_progress_from_vector(position) 
			)
		misobon_player.play_spawn_animation.rpc()
		print_debug("Spawning Misobon!")

## Do crushed specific things to player
func do_crushed_state():
	is_dead = true
	hide()
	animation_player.play("player_animations/crush")
	$Hitbox.set_deferred("disabled", 1)
	await animation_player.animation_finished
	player_died.emit(self)
	process_mode = PROCESS_MODE_DISABLED


func enter_death_state():
	is_dead = true
	animation_player.play("player_animations/death")
	$Hitbox.set_deferred("disabled", 1)
	if globals.is_battle_mode():
		spread_items()
		reset_pickups()
	await animation_player.animation_finished
	player_died.emit(self)
	hide()
	process_mode = PROCESS_MODE_DISABLED

@rpc("call_local")
func exit_death_state():
	process_mode = PROCESS_MODE_INHERIT
	player_revived.emit(self)
	await get_tree().create_timer(MISOBON_RESPAWN_TIME).timeout
	animation_player.play("player_animations/revive")
	$Hitbox.set_deferred("disabled", 0)
	await animation_player.animation_finished
	show()
	stunned = false
	is_dead = false
	if is_multiplayer_authority():
		do_invulnerabilty.rpc()

@rpc("call_local")
func reset():
	animation_player.play("RESET")
	if self.invul_timer: self.invul_timer.timeout.disconnect(stop_invulnerability)
	stop_invulnerability()
	process_mode = PROCESS_MODE_DISABLED
	self.remote_bombs.clear()
	self.remote_bomb_id = 0
	self.bomb_to_throw = null
	self.current_anim = ""
	self.bomb_kicked = null
	$BombSprite.visible = false
	$Hitbox.set_deferred("disabled", 0)
	await animation_player.animation_finished
	self.stunned = false
	self.is_dead = false
	self._died_barrier = false
	self.bomb_count = self.bomb_total
	self.time_is_stopped = false
	self.invulnerable = false
	# This variable is set TRUE once and only once per round by a signal that fires when hurry up begins.
	self.hurry_up_started = false
	unvirus()
	self.is_mounted = false
	set_sprite_to_walk()
	reset_graphic_positions()
	show()

## resets the pickups back to the inital state
@rpc("call_local")
func reset_pickups():
	if self.invul_timer: self.invul_timer.timeout.disconnect(stop_invulnerability)
	stop_invulnerability()
	movement_speed = movement_speed_reset
	bomb_total = bomb_total_reset
	bomb_count = bomb_total
	lives = lives_reset
	player_health_updated.emit(self, lives)
	self.set_collision_mask_value(4, true)
	self.set_collision_mask_value(3, true)
	unvirus()
	explosion_boost_count = explosion_boost_count_reset
	pickups.reset()


## spreads all pickups the player held on the ground
func spread_items():
	if !is_multiplayer_authority(): return
	if globals.player_manager.get_alive_players().reduce(func (sum, p): return sum + 1 if p != self else sum, 0) <= 1: return
	
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

@rpc("call_local")
func do_stun():
	if stunned || invulnerable: return
	animation_player.play("player_animations/stunned") #Note this animation sets stunned automatically

@rpc("call_local")
func set_misobon():
	misobon_player = get_node("../../MisobonPath/" + str(self.name))

func set_player_name(value):
	$label.set_text(value)

func get_player_name() -> String:
	return $label.get_text()
	
@rpc("call_local")
func increase_live():
	if lives >= MAX_HEALTH:
		if globals.is_singleplayer(): globals.game.score += 100
	else:
		lives += 1

@rpc("call_local")
func increase_bomb_level():
	if explosion_boost_count >= MAX_EXPLOSION_BOOSTS_PERMITTED:
		if globals.is_singleplayer(): globals.game.score += 100
	else:
		explosion_boost_count += 1

@rpc("call_local")
func maximize_bomb_level():
	if explosion_boost_count >= MAX_EXPLOSION_BOOSTS_PERMITTED:
		if globals.is_singleplayer(): globals.game.score += 100
	else:
		explosion_boost_count = MAX_EXPLOSION_BOOSTS_PERMITTED

@rpc("call_local")
func increase_speed():
	if movement_speed < MAX_MOTION_SPEED:
		movement_speed += MOTION_SPEED_INCREASE
	if movement_speed >= MAX_MOTION_SPEED:
		if globals.is_singleplayer(): globals.game.score += 100
		movement_speed = MAX_MOTION_SPEED

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
func mount_dragoon():
	is_mounted = true
	invulnerable = true
	stunned = true
	assign_mount_ability()
	Wwise.post_event("snd_cockobo_summon", self)
	animation_player.play("player_animations/mount_summoned")
	await animation_player.animation_finished
	invulnerable = false
	stunned = false
	player_mounted.emit()
	
func assign_mount_ability() -> void:
	match pickups.held_pickups[globals.pickups.MOUNTGOON]:
			pickups.mounts.YELLOW:
				print("Block push!")
				current_mount_ability = mount_ability.BREAKABLEPUSH
			pickups.mounts.PINK:
				print("Jump!")
				current_mount_ability = mount_ability.JUMP
			pickups.mounts.CYAN:
				print("Bomb kick!")
				current_mount_ability = mount_ability.MOUNTKICK
			pickups.mounts.PURPLE:
				print("Rapid bomb!")
				current_mount_ability = mount_ability.RAPIDBOMB
			pickups.mounts.GREEN:
				print("Charge!")
				current_mount_ability = mount_ability.CHARGE
			pickups.mounts.RED:
				print("Punch!")
				current_mount_ability = mount_ability.PUNCH
			_:
				push_warning("Unknown mount!")

func remove_mount_ability() -> void:
	current_mount_ability = mount_ability.NONE
	
@rpc("call_local")
func mount_exploded() -> void:
	Wwise.post_event("snd_cockobo_die", self)
	is_mounted = false
	set_sprite_to_walk()
	reset_graphic_positions()
	remove_mount_ability()
	do_invulnerabilty.rpc()
	_died_barrier = false

func reset_graphic_positions() -> void:
	$sprite.position = Vector2(0.075,6.236)
	$label.position = Vector2(-82.0,-35.0)

@rpc("call_local")
func increment_bomb_count():
	if bomb_total >= MAX_BOMBS_OWNABLE:
		if globals.is_singleplayer(): globals.game.score += 100
	else:
		bomb_total += 1
	bomb_count = min(bomb_count+1, bomb_total)

@rpc("call_local")
func return_bomb(is_mine := false):
	if pickups.held_pickups[globals.pickups.GENERIC_BOMB] == HeldPickups.bomb_types.MINE and is_mine:
		mine_placed = false
	bomb_count = min(bomb_count+1, bomb_total)
	remote_bombs.erase(remote_bomb_id)

@rpc("call_local")
## plays the victory animation and stops the player from moving
func play_victory(reenable: bool) -> Signal:
	self.outside_of_game = true

	if self.invul_timer: self.invul_timer.timeout.disconnect(stop_invulnerability)
	stop_invulnerability()
	
	$sprite.self_modulate = Color8(255, 255, 255)
	$sprite.rotation = 0
	$sprite.frame = 0
	animation_player.play("player_animations/victory")
	if reenable: animation_player.animation_finished.connect(func (_x): self.outside_of_game = false, CONNECT_ONE_SHOT)
	return animation_player.animation_finished

func do_hurt() -> void:
	self.stop_movement = true
	animation_player.play("player_animations/death")
	await animation_player.animation_finished
	player_hurt.emit(self)
	stop_movement = false

@rpc("call_local")
## kills this player and awards whoever killed it
func exploded(_by_who):
	if stunned || invulnerable || stop_movement || _died_barrier: return
	_died_barrier = true
	if is_mounted:
		mount_exploded()
		return
	lives -= 1
	hurt_sfx_player.post_event()
	if lives <= 0:
		enter_death_state()
		enter_misobon()
	else:
		match globals.current_gamemode:
			globals.gamemode.CAMPAIGN: do_hurt()
			globals.gamemode.BATTLEMODE: do_stun()
			globals.gamemode.BOSSRUSH: do_hurt()
			_: push_error("A player was exploded while no gamemode was active")
	_died_barrier = false
	

@rpc("call_local")
func crush():
	if _died_barrier: return
	_died_barrier = true
	do_crushed_state()
	_died_barrier = false

func set_active_sprite(value_path : String):
	$sprite.texture = load(value_path)
	
func set_selected_spritepaths(newspritepaths : Dictionary):
	spritepaths = newspritepaths.duplicate()
	set_active_sprite(spritepaths.walk)

func set_sprite_to_mounted() -> void:
	set_active_sprite(spritepaths.mount)

func set_sprite_to_walk() -> void:
	set_active_sprite(spritepaths.walk)
	
## starts the invulnerability and its animation
@rpc("call_local")
func do_invulnerabilty(time: float = INVULNERABILITY_SPAWN_TIME):
	# if there is already a longer invulnerability just leave that be
	if self.invul_timer && self.invul_timer.time_left >= time: return
	# if there is already a shorter invulnerability overwrite it
	elif self.invul_timer: self.invul_timer.timeout.disconnect(stop_invulnerability)
	#if there is no (or a shorter) on write a new invulnerability
	self.invul_timer = get_tree().create_timer(time)
	self.invul_player.play("Invul")
	self.invulnerable = true
	self.invul_timer.timeout.connect(stop_invulnerability)

func stop_invulnerability():
	self.invul_player.stop()
	if self.invul_timer && self.invul_timer.timeout.is_connected(stop_invulnerability):
		self.invul_timer.timeout.disconnect(stop_invulnerability)
	self.invulnerable = false
	self.invul_timer = null
	self.pickups.held_pickups[globals.pickups.INVINCIBILITY_VEST] = false

@rpc("call_local")
func virus():
	is_virus = true
	pre_virus_speed = movement_speed
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
	if !is_virus: return
	is_virus = false
	infected_explosion = false
	fuse_speed = BombRoot.FUSES.NORMAL
	movement_speed = pre_virus_speed
	is_autodrop = false
	is_reverse = false
	is_nonstop = false
	is_unbomb = false

func stop_time(user: String, is_player: bool):
	if is_player && user == self.name:
		self.pickups.held_pickups[globals.pickups.FREEZE] = false
		return
	self.time_is_stopped = true
	
func start_time():
	self.time_is_stopped = false

func _cur_anim_changed(_anim_name: String):
	#print(self.name, " plays ", _anim_name)
	pass
