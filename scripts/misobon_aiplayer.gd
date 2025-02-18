extends PathFollow2D

const MOVEMENT_SPEED: float = 200.0
const BOMB_RATE: float = 0.5
const MAX_BOMB_OWNABLE: int = 99

@export var synced_progress: float = 0;
@export var is_rejoining: bool = true
@onready var inputs = $Inputs

var last_bomb_time: float = BOMB_RATE
var current_anim: String = ""

#TODO figure out how the f to throw bomb

func _ready() -> void:
	progress = synced_progress
	if str(name).is_valid_int():
		get_node("Inputs/InputsSync").set_multiplayer_authority(str(name).to_int())

func _process(delta: float) -> void:
	if is_rejoining:
		return
	#TODO AI
	if multiplayer.multiplayer_peer == null || is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_progress = progress;
		# And increase the bomb cooldown spawning one if the client wants to.
		last_bomb_time += delta
		if is_multiplayer_authority() && inputs.bombing && last_bomb_time >= BOMB_RATE:
			#TODO implement bomb throwing / spawning a thrown bomb	
			last_bomb_time = 0.0
	else:
		#The client updates their progess to the last know one
		progress = synced_progress

	#TODO AI	

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
