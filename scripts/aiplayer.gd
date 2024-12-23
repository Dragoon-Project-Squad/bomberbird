extends CharacterBody2D

const MOTION_SPEED = 130.0
const BOMB_RATE = 0.5

@export var synced_position := Vector2()
@export var stunned = false

@onready var inputs = $Inputs
@onready var hurt_sfx_player := $HurtSoundPlayer
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var navigation_region = $"../../NavigationRegion2D"
@onready var anim_player = $anim
@onready var timer = $Timer

var last_bomb_time = BOMB_RATE
var current_anim = ""
var is_dead = false
# AI Player specific vars
var is_bombing = false #TODO: Setup condition for AI to bomb, and include is_bombing
var roaming_area: Rect2
var target_position: Vector2

func _ready():
	await get_tree().create_timer(1).timeout
	set_roaming_area()
	set_random_target()
	stunned = false
	position = synced_position
	if str(name).is_valid_int():
		get_node("Inputs/InputsSync").set_multiplayer_authority(str(name).to_int())


func _physics_process(delta):
	# TODO: AI Controls Go Here
	var next_path_position = navigation_agent_2d.get_next_path_position()
	var new_velocity = (next_path_position - global_position).normalized() * MOTION_SPEED
	if navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.velocity = new_velocity
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
	
	#Update position
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = position
		# And increase the bomb cooldown spawning one if the client wants to.
		last_bomb_time += delta
		if not stunned and is_multiplayer_authority() and is_bombing and last_bomb_time >= BOMB_RATE:
			last_bomb_time = 0.0
			get_node("../../BombSpawner").spawn([position, str(name).to_int()])
	else:
		# The client simply updates the position to the last known one.
		position = synced_position

	if not stunned:
		# Everybody runs physics. I.e. clients tries to predict where they will be during the next frame.
		velocity = inputs.motion.normalized() * MOTION_SPEED
		move_and_slide()
	
	# Also update the animation based on the last known player input state
	update_animation(velocity)

func set_roaming_area():
	# Set the roaming area
	var navigation_polygon = navigation_region.get_navigation_polygon()
	if navigation_polygon.get_outline_count() > 0:
		var outline = navigation_polygon.get_outline(0)
		# Calculate the bounding rect
		var min_x = INF
		var min_y = INF
		var max_x = -INF
		var max_y = -INF
		for point in outline:
			min_x = min(min_x, point.x)
			min_y = min(min_y, point.y)
			max_x = max(max_x, point.x)
			max_y = max(max_y, point.y)
		roaming_area = Rect2(min_x, min_y, max_x - min_x, max_y - min_y)
	else:
		print("No outlines found within the navigational polygon")

func update_animation(newvelocity: Vector2):
	var new_anim = "standing"
	if newvelocity.length() == 0:
		new_anim = "standing"
	elif newvelocity.y < 0:
		new_anim = "walk_up"
	elif newvelocity.y > 0:
		new_anim = "walk_down"
	elif newvelocity.x < 0:
		new_anim = "walk_left"
	elif newvelocity.x > 0:
		new_anim = "walk_right"
		
	if new_anim != current_anim:
		current_anim = new_anim
		anim_player.play(current_anim)
		
func set_random_target():
	# Sets next roaming position within the roaming area
	target_position = Vector2(
		randf_range(roaming_area.position.x, roaming_area.position.x + roaming_area.size.x),
		randf_range(roaming_area.position.y, roaming_area.position.y + roaming_area.size.y),
	)
	navigation_agent_2d.set_target_position(target_position)
	
func set_player_name(value):
	get_node("label").text = value


@rpc("call_local")
func exploded(_by_who):
	if stunned:
		return
	stunned = true
	hurt_sfx_player.play()
	anim_player.play("stunned")


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	# Move AI Player
	velocity = safe_velocity


func _on_navigation_agent_2d_navigation_finished() -> void:
	# When path reached, redirect NPC
	velocity = Vector2.ZERO
	current_anim = "standing"
	timer.start()

func _on_timer_timeout() -> void:
	# Move AI Player
	set_random_target()
