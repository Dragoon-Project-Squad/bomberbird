extends Player
class_name AIPlayer

@onready var inputs = $Inputs
@onready var anim_player = $AnimationPlayer

# AI Player specific vars
var is_bombing = false #TODO: Setup condition for AI to bomb, and include is_bombing
var target_position: Vector2
var waiting_for_map_sync = true

# AI Pathing vars
var tile_offset = Vector2i(16,16)
# World node to obtain grid pathfinding
var world
# Floor node to use localtomap and maptolocal
var layer
var current_path : Array
var moving = false
var movement_vector = Vector2(0,0)
var next_point

func _ready():
	world = get_parent().get_parent()
	layer = world.get_node("Floor")
	next_point = global_position
	player_type = "ai"
	super()

func _physics_process(delta):
	#Update position
	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_position = position
		# And increase the bomb cooldown spawning one if the client wants to.
		last_bomb_time += delta
		if not stunned and is_multiplayer_authority() and is_bombing and last_bomb_time >= BOMB_RATE:
			place_bomb()
	else:
		# The client simply updates the position to the last known one.
		position = synced_position
	# Also update the animation based on the last known player input state
	if !is_dead && !stunned:
		velocity = movement_vector.normalized() * movement_speed
		move_and_slide()	
		update_animation(movement_vector.normalized())
		if(name == "2"):
			"""
			print("Global:"+str(global_position))
			print("Next:"+str(next_point))
			print(movement_vector.normalized())
			"""

func set_random_target():
	var size
	# Sets next roaming position within the roaming area
	"""
	target_position = Vector2(
		randf_range(roaming_area.position.x, roaming_area.position.x + roaming_area.size.x),
		randf_range(roaming_area.position.y, roaming_area.position.y + roaming_area.size.y),
	)
	"""

func get_next_position() -> Vector2:
	var current_path_local = layer.map_to_local(current_path[0])
	var next_position = Vector2i(current_path_local.x + tile_offset.x, current_path_local.y + tile_offset.y)
	return next_position

func set_new_path():
	var initial = layer.local_to_map(global_position)
	var end = layer.local_to_map(target_position)
	current_path = world.create_path(self, Vector2i(7, 7))

func _on_ai_action_timer_timeout():
	set_new_path()
	moving = false
