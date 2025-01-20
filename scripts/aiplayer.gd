extends CharacterBody2D

const BASE_MOTION_SPEED = 130.0
const BOMB_RATE = 0.5

@export var synced_position := Vector2()
@export var stunned = false

@onready var inputs = $Inputs
@onready var hurt_sfx_player := $HurtSoundPlayer
@onready var navigation_agent_2d = $NavigationAgent2D
@onready var navigation_region = $"../../NavigationRegion2D"
@onready var anim_player = $anim
@onready var timer = $NavigationAgent2D/Timer

var last_bomb_time = BOMB_RATE
var current_anim = ""
var is_dead = false
# Powerup Vars
var movement_speed = BASE_MOTION_SPEED
var explosion_boost_count = 0
var max_explosion_boosts_permitted = 2
# AI Player specific vars
var is_bombing = false #TODO: Setup condition for AI to bomb, and include is_bombing
var roaming_area: Rect2
var target_position: Vector2
var waiting_for_map_sync = true
func _ready():
	NavigationServer2D.map_changed.connect(navigation_map_sync_wait)
	set_roaming_area()
	set_random_target()
	stunned = false
	position = synced_position
func _physics_process(delta):
	if !waiting_for_map_sync:
		var next_path_position = navigation_agent_2d.get_next_path_position()
		var new_velocity = (next_path_position - global_position).normalized() * BASE_MOTION_SPEED
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
		move_and_slide()
	
	# Also update the animation based on the last known player input state
	update_animation(velocity)

func navigation_map_sync_wait(map: RID):
	while NavigationServer2D.map_get_iteration_id(map) == 0:
		await get_tree().create_timer(0.1).timeout
	if NavigationServer2D.map_get_iteration_id(map) != 0:
		#print("NavigationServer2D Map Iterated!")
		waiting_for_map_sync = false
	
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
	get_node("label").set_text(value)


func increase_bomb_level():
	explosion_boost_count = min(explosion_boost_count + 1, max_explosion_boosts_permitted)

func maximize_bomb_level():
	explosion_boost_count = min(explosion_boost_count + 99, max_explosion_boosts_permitted)
		
func increase_speed():
	movement_speed = movement_speed + 200

@rpc("call_local")
func exploded(by_who):
	if stunned:
		return
	stunned = true
	hurt_sfx_player.play()
	$"../../Score".increase_score(by_who) # Award a point to the person who blew you up
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
