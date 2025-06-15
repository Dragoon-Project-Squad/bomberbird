class_name MisobonPlayer extends PathFollow2D

const THROW_RANGE: int = 3
const MOVEMENT_SPEED: float = 150.0
const BOMB_RATE: float = 2
const MAX_BOMB_OWNABLE: int = 99
const TILESIZE: int = 32

@export var synced_progress: float = 0

var bomb_pool: BombPool
var player: Player
var last_bomb_time: float = BOMB_RATE
var current_anim: String = ""
var controllable: bool = false
var time_is_stopped: bool = false

func _ready() -> void:
	bomb_pool = globals.game.bomb_pool
	set_player(str(self.name).to_int())
	disable()

func _process(_delta: float) -> void:
	if multiplayer.multiplayer_peer == null || is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_progress = progress;
		# And increase the bomb cooldown spawning one if the client wants to.
		
	else:
		#The client updates their progess to the last know one
		progress = synced_progress

## set the given player to the owner of this misobon player
func set_player(player_id: int):
	self.player = get_node("../../Players/" + str(player_id))

@rpc("call_local")
func enable(starting_progress: float):
	process_mode = PROCESS_MODE_INHERIT
	progress = starting_progress
	synced_progress = progress
	last_bomb_time = BOMB_RATE
	

@rpc("call_local")
func disable(do_wait: bool = false):
	if do_wait: await $AnimationPlayer.animation_finished
	controllable = false
	hide()
	current_anim = ""
	process_mode = PROCESS_MODE_DISABLED
	
@rpc("call_local")
func disable_at_end_of_round():
	controllable = false
	hide()
	current_anim = ""
	process_mode = PROCESS_MODE_DISABLED
	
## called to spawn and throw a bomb
func throw_bomb():
	last_bomb_time = 0
	$BombSprite.hide()
	
	var look_direction: Vector2i = get_parent().get_direction(progress)
	var throw_range = THROW_RANGE if look_direction != Vector2i.DOWN else THROW_RANGE + 2

	var bombPos = position + Vector2(look_direction) * TILESIZE * throw_range

	if !is_multiplayer_authority():
		return

	var bomb = bomb_pool.request()
	bomb.set_bomb_owner.rpc(self.name)
	bomb.do_misobon_throw.rpc(
		position + $BombSprite.position,
		bombPos,
		look_direction,
	)

@rpc("call_local")
func revive(pos: Vector2):
	if SettingsContainer.misobon_setting != SettingsContainer.misobon_setting_states.SUPER || !player.is_dead:
		return
	play_despawn_animation()
	var corrected_pos: Vector2 = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(pos))
	player.synced_position = corrected_pos
	player.position = corrected_pos
	await $AnimationPlayer.animation_finished
	if player.is_multiplayer_authority():
		player.exit_death_state.rpc()
		disable.rpc()
		
func reset(pos: Vector2):
	if SettingsContainer.misobon_setting != SettingsContainer.misobon_setting_states.SUPER || !player.is_dead:
		return
	var corrected_pos: Vector2 = world_data.tile_map.map_to_local(world_data.tile_map.local_to_map(pos))
	player.synced_position = corrected_pos
	player.position = corrected_pos
	self.time_is_stopped = false
	if player.is_multiplayer_authority():
		player.reset.rpc()
		disable.rpc()

## updates the looking direction animation
func update_animation(segment_index: int):
	var animations: Array[String] = ["look_down", "look_left", "look_up", "look_right"]
	if animations[segment_index] != current_anim && controllable:
		current_anim = animations[segment_index]
		$AnimationPlayer.play("misobon_player_animation/" + current_anim)

@rpc("call_local")
func play_spawn_animation():
	var seg_index: int = get_parent().get_segment_id(progress)
	assert(!seg_index == 0 && !seg_index == 2)
	if seg_index == 1:
		current_anim = "spawn_right"
	else:
		current_anim = "spawn_left"
	$AnimationPlayer.play("misobon_player_animation/" + current_anim)
	await $AnimationPlayer.animation_finished
	controllable = true

@rpc("call_local")
func play_despawn_animation():
	controllable = false
	var seg_index: int = get_parent().get_segment_id(progress)
	var animations = ["despawn_top", "despawn_right", "despawn_bottom", "despawn_left"]
	current_anim = animations[seg_index]
	$AnimationPlayer.play("misobon_player_animation/" + current_anim)

func set_player_name(new_name: String):
	$label.set_text(new_name)

func stop_time(user: String, is_player: bool):
	if is_player && user == player.name: return
	self.time_is_stopped = false
	
func start_time():
		self.time_is_stopped = true
