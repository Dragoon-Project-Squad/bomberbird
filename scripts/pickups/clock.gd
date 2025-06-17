extends Pickup

const TIME: float = 4

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner):
	super(pickup_owner)
	if !is_multiplayer_authority(): return
	if pickup_owner is Player:
		emit_time_signal.rpc(pickup_owner.name, true)
	elif pickup_owner is Boss:
		emit_time_signal.rpc(pickup_owner.name, false)
	

@rpc("call_local")
func emit_time_signal(pickup_owner: String, is_player: bool):
	globals.game.clock_pickup_time_paused.emit(pickup_owner, is_player)
	get_tree().create_timer(TIME).timeout.connect(func(): globals.game.clock_pickup_time_unpaused.emit())
