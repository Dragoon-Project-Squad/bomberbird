extends PathFollow2D

const MOVEMENT_SPEED: float = 200.0
const BOMB_RATE: float = 0.5
const MAX_BOMB_OWNABLE: int = 99
const GRACE: float = 20 #grace allows for inputs close to a corner to still work

@export var synced_progress: float = 0;

@onready var inputs = $Inputs

var last_bomb_time: float = BOMB_RATE
var current_anim: String = ""
var is_rejoining: bool = false

var path_len: float
#TODO figure out how the f to throw bomb

func _ready() -> void:
	progress = synced_progress
	if str(name).is_valid_int():
		get_node("Inputs/InputsSync").set_multiplayer_authority(str(name).to_int())
	path_len = get_node("..").curve.get_baked_length()

func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update(synced_progress, int(path_len / 4), GRACE) #This could become a problem is our path is ever not an integer, tho it should remain on.	

	if multiplayer.multiplayer_peer == null or is_multiplayer_authority():
		# The server updates the position that will be notified to the clients.
		synced_progress = progress;
		# And increase the bomb cooldown spawning one if the client wants to.
		last_bomb_time += delta
		if is_multiplayer_authority() and inputs.bombing and last_bomb_time >= BOMB_RATE:
			#TODO implement bomb throwing / spawning a thrown bomb	
			last_bomb_time = 0.0
	
	else:
		#The client updates their progess to the last know one
		progress = synced_progress

	progress += inputs.motion * MOVEMENT_SPEED * delta
	#TODO update animation

func set_player_name(new_name: String):
	$label.set_text(new_name)
