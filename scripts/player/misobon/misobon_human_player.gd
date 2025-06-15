extends MisobonPlayer

@onready var inputs = $Inputs

func _ready() -> void:
	progress = synced_progress
	if str(name).is_valid_int():
		get_node("Inputs/InputsSync").set_multiplayer_authority(str(name).to_int())
	super()

func _process(delta: float) -> void:
	super(delta)
	if !controllable: return
	if multiplayer.multiplayer_peer == null or str(multiplayer.get_unique_id()) == str(name):
		# The client which this player represent will update the controls state, and notify it to everyone.
		inputs.update(
			get_parent().get_segment_with_grace(synced_progress)
			)
	
	last_bomb_time += delta

	if last_bomb_time >= BOMB_RATE && !$BombSprite.visible:
		$BombSprite.show()

	if inputs.bombing && last_bomb_time >= BOMB_RATE:
		throw_bomb()

	progress += inputs.motion * MOVEMENT_SPEED * delta
	update_animation(
		get_parent().get_segment_id(progress)
		)
