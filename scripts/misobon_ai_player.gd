extends MisobonPlayer


@export var move_direction: int = 0
var ai_throw_bomb: bool = false

func _ready() -> void:
	super()
	get_node("StateMachine/Wander").player = self
	get_node("StateMachine/Bombing").player = self
	get_node("StateMachine/Wander").raycasts = $Raycasts

func _process(delta: float) -> void:
	super(delta)
	#TODO AI

	last_bomb_time += delta

	if last_bomb_time >= BOMB_RATE && !$BombSprite.visible:
		$BombSprite.show()

	if ai_throw_bomb && last_bomb_time >= BOMB_RATE:
		throw_bomb()

	update_animation(
		get_parent().get_segment_id(progress)
		)
