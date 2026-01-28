class_name HumanPlayer extends Player

@onready var inputs: Node = $Inputs

var set_bomb_pressed_once := false
var punch_pressed_once := false
var is_carrying_bomb := false
var bomb_hold_timer := 0.0
var jump_cooldown := 0.0
var roll_duration := 0.0

func set_authority_during_spawn():
	if str(name).is_valid_int():
		#get_node("Inputs/InputsSync").set_multiplayer_authority(str(name).to_int())
		set_multiplayer_authority(str(name).to_int()) #Set the entire player to be owned by this person.
		
func _ready():
	player_type = "human"

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
	if globals.is_singleplayer():
		player_health_updated.connect(func (s: Player, health: int): game_ui.update_health(health, int(s.name)))

	match globals.current_gamemode:
		globals.gamemode.CAMPAIGN: lives = 3
		globals.gamemode.BOSSRUSH: lives = 3
		globals.gamemode.BATTLEMODE: lives = 1
		_: assert(false, "not a valid gamemode")
	pickups.reset()

	if globals.is_campaign_mode() || globals.is_boss_rush_mode():
		if gamestate.current_save.player_pickups.is_empty() && gamestate.current_save.player_health == 3:
			write_to_save()
		else:
			load_from_save()
			
	self.animation_player.play("RESET")
	init_pickups()
	if is_multiplayer_authority():
		do_invulnerability.rpc()
	await get_tree().process_frame

func _physics_process(delta: float):
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update()

	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		physics_as_authority(delta)
	else:
		physics_as_others()
	
	if time_is_stopped:
		update_animation(Vector2.ZERO, last_movement_vector)
		return
	if stop_movement || outside_of_game: return
	if is_jumping: 
		mounted_jump_process(delta)
		return
	last_movement_vector = inputs.motion.normalized()
	
	var direction: Vector2 = (
		inputs.motion.normalized() if inputs.motion != Vector2.ZERO 
		else last_movement_vector
	).sign()
	if direction.x != 0 and direction.y != 0:
		direction = [Vector2(direction.x, 0), Vector2(0, direction.y)][randi() % 2]
	
	if not stunned and inputs.punch_ability:
		if is_mounted:
			punch_enemy()
		if not punch_pressed_once:
			punch_pressed_once = true
			punch_bomb(direction)
	elif !inputs.punch_ability and punch_pressed_once:
		punch_pressed_once = false
	
	jump_cooldown += delta
	if is_rolling and roll_duration <= 2.0:
		roll_duration += delta
		mount_roller_process(delta, direction)
	else:
		roll_duration = 0.0
		mount_roller(false)
	if not stunned and inputs.secondary_ability:
		kick_bomb(direction)
		if is_mounted:
			kick_breakable(direction)
			if jump_cooldown >= 5.0:
				mounted_jump(direction)
				jump_cooldown = 0.0
			mount_roller(true)

	if not is_unbomb and not stunned and bomb_count > 0:
		if inputs.bombing:
			set_bomb_pressed_once = true
			bomb_hold_timer += delta
			if bomb_hold_timer > 0.5 and not is_carrying_bomb:
				if carry_bomb() == 0:
					is_carrying_bomb = true
		elif not inputs.bombing and set_bomb_pressed_once:
			if bomb_hold_timer > 0.5 and is_carrying_bomb:
				is_carrying_bomb = false
				throw_bomb(direction)
			else:
				place_bomb()
			bomb_hold_timer = 0.0
			set_bomb_pressed_once = false
		elif inputs.secondary_ability and current_mount_ability == mount_ability.RAPIDBOMB:
			place_bomb(direction)

	if !is_dead && !stunned:
		# Everybody runs physics. I.e. clients tries to predict where they will be during the next frame.
		velocity = inputs.motion.normalized() * movement_speed
		move_and_slide()
		# Also update the animation based on the last known player input state
		update_animation(inputs.motion, self.last_movement_vector)
	
	if inputs.remote_ability:
		call_remote_bomb()
	
	#mount movement sounds
	if velocity.x != 0 or velocity.y != 0:
		if is_mounted:
			if mount_step_timer.time_left == 0:
				mount_step_timer.start()
				Wwise.post_event("snd_cockobo_footstep", self)

func physics_as_authority(deltaTime):
	# The server updates the position that will be notified to the clients.
	synced_position = position
	# And increase the bomb cooldown spawning one if the client wants to.
	last_bomb_time += deltaTime
	
func physics_as_others():
	position = synced_position

@rpc("call_local")
func exploded(by_who):
	super(by_who)
	if globals.is_campaign_mode() || globals.is_boss_rush_mode():
		write_to_save()

@rpc("call_local")
func reset():
	set_bomb_pressed_once = false
	punch_pressed_once = false
	is_carrying_bomb = false
	bomb_hold_timer = 0.0
	super()

func write_to_save():
	gamestate.current_save.player_health = self.lives
	gamestate.current_save.player_pickups = self.pickups.held_pickups.duplicate()

func load_from_save():
	self.lives = gamestate.current_save.player_health
	self.pickups.held_pickups = gamestate.current_save.player_pickups.duplicate()

func clear_save():
	lives = 3
	gamestate.current_save.player_health = 3
	game_ui.update_health(lives, int(self.name))
	write_to_save()
