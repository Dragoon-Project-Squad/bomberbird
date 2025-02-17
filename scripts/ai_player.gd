extends Player
@onready var timer = $AIActionTimer
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
	timer.autostart
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
			last_bomb_time = 0.0
			get_node("../../BombSpawner").spawn([position, str(name).to_int()])
	else:
		# The client simply updates the position to the last known one.
		position = synced_position
	if not stunned:
		velocity = movement_vector.normalized() * movement_speed
		move_and_slide()	
	# Also update the animation based on the last known player input state
	if !is_dead:
		if(name == "2"):
			"""
			print("Global:"+str(global_position))
			print("Next:"+str(next_point))
			print(movement_vector.normalized())
			"""
		update_animation(movement_vector.normalized())

func navigation_map_sync_wait(map: RID):
	while NavigationServer2D.map_get_iteration_id(map) == 0:
		await get_tree().create_timer(0.1).timeout
	if NavigationServer2D.map_get_iteration_id(map) != 0:
		#print("NavigationServer2D Map Iterated!")
		waiting_for_map_sync = false
    
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
