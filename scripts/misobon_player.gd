extends PathFollow2D

const MOVEMENT_SPEED: float = 200.0
const BOMB_RATE: float = 0.5
const MAX_BOMB_OWNABLE: int = 99
const TILESIZE = 32

@export var synced_progress: float = 0;
@export var is_rejoining: bool = true

@onready var inputs = $Inputs

var bomb_pool: ObjectPool
var last_bomb_time: float = BOMB_RATE
var current_anim: String = ""

#TODO figure out how the f to throw bomb

func _ready() -> void:
	progress = synced_progress
	if str(name).is_valid_int():
		get_node("Inputs/InputsSync").set_multiplayer_authority(str(name).to_int())
	bomb_pool = get_node("/root/World/BombPool")

func _process(delta: float) -> void:
	if is_rejoining:
		return
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update(
			get_parent().get_segment_with_grace(synced_progress)
			)

	if multiplayer.multiplayer_peer == null || is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_progress = progress;
		# And increase the bomb cooldown spawning one if the client wants to.
		last_bomb_time += delta
		
		if last_bomb_time >= BOMB_RATE:
			$BombSprite.visible = true
			
	else:
		#The client updates their progess to the last know one
		progress = synced_progress

	if inputs.bombing && last_bomb_time >= BOMB_RATE:
		#TODO implement bomb throwing / spawning a thrown bomb	
		last_bomb_time = 0
		$BombSprite.visible = false
		
		var seg_index: int = get_parent().get_segment_id(synced_progress)
		var direction_array: Array[Vector2i] = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT]
		var bombPos = position + Vector2(direction_array[seg_index]) * TILESIZE * (3 if direction_array[seg_index] != Vector2i.DOWN else 5)

		if is_multiplayer_authority():
			var bomb = bomb_pool.request(self)
			bomb.do_misobon_throw.rpc(
				position + $BombSprite.position,
				bombPos,
				direction_array[seg_index]
				)



	progress += inputs.motion * MOVEMENT_SPEED * delta
	update_animation(
		get_parent().get_segment_id(synced_progress)
		)

func update_animation(segment_index: int):
	var animations: Array[String] = ["look_down", "look_left", "look_up", "look_right"]
	if animations[segment_index] != current_anim && !is_rejoining:
		current_anim = animations[segment_index]
		$AnimationPlayer.play(current_anim)

func play_spawn_animation():
	var seg_index: int = get_parent().get_segment_id(synced_progress)
	assert(!seg_index == 0 && !seg_index == 2)
	if seg_index == 1:
		current_anim = "spawn_right"
	else:
		current_anim = "spawn_left"
	$AnimationPlayer.play(current_anim)
	await $AnimationPlayer.animation_finished
	is_rejoining = false
func set_player_name(new_name: String):
	$label.set_text(new_name)
