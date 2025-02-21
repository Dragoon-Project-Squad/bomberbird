class_name MisobonPlayer extends PathFollow2D

const THROW_RANGE: int = 3
const MOVEMENT_SPEED: float = 200.0
const BOMB_RATE: float = 2
const MAX_BOMB_OWNABLE: int = 99
const TILESIZE: int = 32

@export var synced_progress: float = 0

var bomb_pool: ObjectPool
var player: Player
var last_bomb_time: float = BOMB_RATE
var current_anim: String = ""
var controlable: bool = false

func _ready() -> void:
	bomb_pool = get_node("/root/World/BombPool")
	set_player(str(self.name).to_int())
	disable()

func _process(_delta: float) -> void:
	if !controlable:
		return
	if multiplayer.multiplayer_peer == null || is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_progress = progress;
		# And increase the bomb cooldown spawning one if the client wants to.
		
	else:
		#The client updates their progess to the last know one
		progress = synced_progress

func set_player(player_id: int):
	self.player = get_node("../../Players/" + str(player_id))

@rpc("call_local")
func enable(starting_progress: float):
	process_mode = PROCESS_MODE_INHERIT
	progress = starting_progress
	synced_progress = progress
	last_bomb_time = BOMB_RATE
	

@rpc("call_local")
func disable():
	controlable = false
	hide()
	current_anim = ""
	process_mode = PROCESS_MODE_DISABLED
	
func throw_bomb():

	last_bomb_time = 0
	$BombSprite.hide()
	
	var seg_index: int = get_parent().get_segment_id(progress)
	var direction_array: Array[Vector2i] = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT]
	var throw_range = THROW_RANGE if direction_array[seg_index] != Vector2i.DOWN else THROW_RANGE + 2

	var bombPos = position + Vector2(direction_array[seg_index]) * TILESIZE * throw_range

	if !is_multiplayer_authority():
		return

	var bomb = bomb_pool.request(self)
	bomb.do_misobon_throw.rpc(
		position + $BombSprite.position,
		bombPos,
		direction_array[seg_index]
		)

@rpc("call_local")
func revive(pos: Vector2):
	if gamestate.misobon_mode != gamestate.misobon_states.SUPER:
		return
	play_despawn_animation()
	player.synced_position = pos
	player.position = pos
	await $AnimationPlayer.animation_finished
	player.process_mode = PROCESS_MODE_INHERIT
	player.exit_death_state()
	disable()

func update_animation(segment_index: int):
	var animations: Array[String] = ["look_down", "look_left", "look_up", "look_right"]
	if animations[segment_index] != current_anim && controlable:
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
	controlable = true

@rpc("call_local")
func play_despawn_animation():
	var seg_index: int = get_parent().get_segment_id(progress)
	var animations = ["despawn_top", "despawn_right", "despawn_bottom", "despawn_left"]
	current_anim = animations[seg_index]
	$AnimationPlayer.play("misobon_player_animation/" + current_anim)
	controlable = false

func set_player_name(new_name: String):
	$label.set_text(new_name)
