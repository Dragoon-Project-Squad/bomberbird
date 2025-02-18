class_name MisobonPlayer extends PathFollow2D

const THROW_RANGE: int = 3
const MOVEMENT_SPEED: float = 200.0
const BOMB_RATE: float = 0.5
const MAX_BOMB_OWNABLE: int = 99
const TILESIZE: int = 32

@export var is_alive: bool = false

var bomb_pool: ObjectPool
var player: Player
var last_bomb_time: float = BOMB_RATE
var current_anim: String = ""

func _ready() -> void:
	bomb_pool = get_node("/root/World/BombPool")

func _process(_delta: float) -> void:
	return	

func enable():
	process_mode = PROCESS_MODE_INHERIT
	last_bomb_time = BOMB_RATE
	show()
	play_spawn_animation()
	is_alive = false

func disable():
	is_alive = true
	$AnimationPlayer.stop()
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

func revive(pos: Vector2):
	#TODO check if game is on SUPER
	player.synced_position = pos
	player.position = pos
	player.exit_death_state()

func update_animation(segment_index: int):
	var animations: Array[String] = ["look_down", "look_left", "look_up", "look_right"]
	if animations[segment_index] != current_anim && !is_alive:
		current_anim = animations[segment_index]
		$AnimationPlayer.play(current_anim)

func play_spawn_animation():
	var seg_index: int = get_parent().get_segment_id(progress)
	assert(!seg_index == 0 && !seg_index == 2)
	if seg_index == 1:
		current_anim = "spawn_right"
	else:
		current_anim = "spawn_left"
	$AnimationPlayer.play(current_anim)
	await $AnimationPlayer.animation_finished

func set_player_name(new_name: String):
	$label.set_text(new_name)
