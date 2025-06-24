class_name HumanPlayer extends Player

@onready var inputs = $Inputs

var set_bomb_pressed_once := false
var punch_pressed_once := false
var throw_pressed_once := false

func _ready():
	player_type = "human"
	if str(name).is_valid_int():
		get_node("Inputs/InputsSync").set_multiplayer_authority(str(name).to_int())

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
	if globals.current_gamemode == globals.gamemode.CAMPAIGN:
		player_health_updated.connect(func (s: Player, health: int): game_ui.update_health(health, int(s.name)))
	match globals.current_gamemode:
		globals.gamemode.CAMPAIGN: lives = 3
		globals.gamemode.BATTLEMODE: lives = 1
		_: lives = 1
	lives_reset = lives
	pickups.reset()

	if globals.current_gamemode == globals.gamemode.CAMPAIGN:
		if gamestate.current_save.player_pickups.is_empty():
			write_to_save()
		else:
			load_from_save()
			
	self.animation_player.play("RESET")
	init_pickups()
	do_invulnerabilty()


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
	
	if stop_movement || time_is_stopped: return
	
	var direction: Vector2 = (
		inputs.motion.normalized() if inputs.motion != Vector2.ZERO 
		else Vector2.DOWN
	).sign()
	if direction.x != 0 and direction.y != 0:
		direction = [Vector2(direction.x, 0), Vector2(0, direction.y)][randi() % 2]
	
	if not stunned and inputs.punch_ability and not punch_pressed_once:
		punch_pressed_once = true
		punch_bomb(direction)
	elif !inputs.punch_ability and punch_pressed_once:
		punch_pressed_once = false
	
	if not stunned and inputs.secondary_ability:
		kick_bomb(direction)

	if not stunned and inputs.bombing and bomb_count > 0 and not is_unbomb:
		if not set_bomb_pressed_once:
			set_bomb_pressed_once = true
			place_bomb()
		if not throw_pressed_once and set_bomb_pressed_once:
			throw_pressed_once = true
			if carry_bomb() != 0:
				throw_pressed_once = false
	elif !inputs.bombing and set_bomb_pressed_once:
		set_bomb_pressed_once = false
		if throw_pressed_once:
			throw_pressed_once = false
			if throw_bomb(direction) == 1:
				push_error("something went wrong with bomb throwing")
				throw_pressed_once = false

	if !is_dead && !stunned:
		# Everybody runs physics. I.e. clients tries to predict where they will be during the next frame.
		velocity = inputs.motion.normalized() * movement_speed
		move_and_slide()
		# Also update the animation based on the last known player input state
		update_animation(inputs.motion)

func write_to_save():
	gamestate.current_save.health = self.lives
	gamestate.current_save.player_pickups = self.pickups.held_pickups.duplicate()

func load_from_save():
	self.lives = gamestate.current_save.health
	self.pickups.held_pickups = gamestate.current_save.player_pickups.duplicate()

func clear_save():
	gamestate.current_save.health = lives_reset
	gamestate.current_save.player_pickups = {}
