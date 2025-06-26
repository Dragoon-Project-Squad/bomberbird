extends MisobonPlayer

@onready var state_machine: Node = $StateMachine

@export var move_direction: int = 0
var ai_throw_bomb: bool = false

func _process(delta: float) -> void:
	super(delta)
	
	if !controllable: return
	last_bomb_time += delta

	if last_bomb_time >= BOMB_RATE && !$BombSprite.visible:
		$BombSprite.show()

	if ai_throw_bomb && last_bomb_time >= BOMB_RATE:
		throw_bomb()

	update_animation(
		get_parent().get_segment_id(progress)
		)

@rpc("call_local")
func reset(pos: Vector2):
	super(pos)
	move_direction = 0
	ai_throw_bomb = false
	state_machine.reset()

