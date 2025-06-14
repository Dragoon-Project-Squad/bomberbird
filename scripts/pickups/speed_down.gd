extends Pickup

func _ready():
	super()
	animated_sprite.play("idle")

func apply_power_up(pickup_owner: Node2D):
	if pickup_owner is HumanPlayer: #If this is a human
		pickup_owner.decrease_speed.rpc()
	elif pickup_owner is AIPlayer: #This is an AI
		pickup_owner.decrease_speed()
	elif pickup_owner is Boss:
		pickup_owner.decrease_speed()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("pickup_debuff_immunity"): return
	super(body)
