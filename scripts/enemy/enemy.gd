class_name Enemy extends CharacterBody2D


@onready var anim_player = $AnimationPlayer
@onready var detection_handler = $DetectionHandler
@onready var statemachine = $StateMachine

@export_group("Enemy Settings")
@export var movement_speed: float = 100.0
@export_group("Multiplayer Variables")
@export var movement_vector = Vector2(0,0)
@export var synced_position := Vector2()

var current_anim: String = ""


func _physics_process(_delta):
	#Update position
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = position
	else:
		# The client simply updates the position to the last known one.
		position = synced_position
	
	# Also update the animation based on the last known player input state
	velocity = movement_vector.normalized() * movement_speed
	move_and_slide()
	# Also update the animation based on the last known player input state
	update_animation(movement_vector.normalized())

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
