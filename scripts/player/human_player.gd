class_name HumanPlayer extends Player

@onready var inputs: Node = $Inputs

var set_bomb_pressed_once := false
var punch_pressed_once := false
var is_carrying_bomb := false
var bomb_hold_timer := 0.0

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

	
	if time_is_stopped:
		update_animation(Vector2.ZERO, last_movement_vector)
		return
	if stop_movement || outside_of_game: return
	last_movement_vector = inputs.motion.normalized()
	
	var direction: Vector2 = (
		inputs.motion.normalized() if inputs.motion != Vector2.ZERO 
		else last_movement_vector
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

	if !is_dead && !stunned:
		# Everybody runs physics. I.e. clients tries to predict where they will be during the next frame.
		velocity = inputs.motion.normalized() * movement_speed
		move_and_slide()
		# Also update the animation based on the last known player input state
		update_animation(inputs.motion, self.last_movement_vector)
	
	if inputs.remote_ability:
		call_remote_bomb()
@rpc("call_local")
func reset():
	set_bomb_pressed_once = false
	punch_pressed_once = false
	is_carrying_bomb = false
	bomb_hold_timer = 0.0
	super()

func write_to_save():
	gamestate.current_save.health = self.lives
	gamestate.current_save.player_pickups = self.pickups.held_pickups.duplicate()

func load_from_save():
	self.lives = gamestate.current_save.health
	self.pickups.held_pickups = gamestate.current_save.player_pickups.duplicate()

func clear_save():
	gamestate.current_save.health = lives_reset
	gamestate.current_save.player_pickups = {}
