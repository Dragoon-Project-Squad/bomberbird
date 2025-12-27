class_name AIPlayer extends Player

@onready var inputs: Node = $Inputs
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var statemachine: Node = $StateMachine

var bombs_near : Array[Bomb]
var players_near : Array[Player]

# World node to obtain grid pathfinding
@export var movement_vector = Vector2.ZERO

func _ready():
	player_type = "ai"
	super()

func _physics_process(delta):
	#Update position
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
	if outside_of_game || stop_movement: return
	last_movement_vector = movement_vector.normalized()
	
	# Also update the animation based on the last known player input state
	if !is_dead && !stunned:
		velocity = movement_vector.normalized() * movement_speed
		move_and_slide()
		# Also update the animation based on the last known player input state
		update_animation(inputs.motion, self.last_movement_vector)
	
	#moiunt movement sounds
	if velocity.x != 0 or velocity.y != 0:
		if is_mounted:
			if mount_step_timer.time_left == 0:
				mount_step_timer.start()
				Wwise.post_event("snd_cockobo_footstep", self)	

func _on_object_detection_area_entered(area):
	var body = area.get_parent()
	if body is Bomb:
		if body in bombs_near:
			return
		bombs_near.append(body)
	if body is Player:
		if body.name == self.name:
			return
		players_near.append(body)

func _on_object_detection_area_exited(area):
	var body = area.get_parent()
	if body is Bomb and body in bombs_near:
		bombs_near.remove_at(bombs_near.find(body))
	if body is Player and body in players_near:
		players_near.remove_at(players_near.find(body))

func reset():
	super()
	bombs_near = []
	players_near = []
	movement_vector = Vector2.ZERO
	statemachine.reset()
